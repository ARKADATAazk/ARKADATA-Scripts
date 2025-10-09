-- ReArkitekt/features/region_playlist/engine.lua
-- Region Playlist Engine with FULL recursive playlist-in-playlist support

local Regions = require('ReArkitekt.reaper.regions')
local Transport = require('ReArkitekt.reaper.transport')

local M = {}
local Engine = {}
Engine.__index = Engine

local function _has_sws()
  return (reaper.SNM_GetIntConfigVar ~= nil) and (reaper.SNM_SetIntConfigVar ~= nil)
end

local function _is_playing(proj)
  proj = proj or 0
  local st = reaper.GetPlayStateEx(proj)
  return (st & 1) == 1
end

local function _get_play_pos(proj)
  return reaper.GetPlayPositionEx(proj or 0)
end

local function _clamp(i, lo, hi)
  if i < lo then return lo end
  if i > hi then return hi end
  return i
end

function M.new(opts)
  opts = opts or {}
  local self = setmetatable({}, Engine)

  self.proj = opts.proj or 0
  self.region_cache = {}
  self.playlist_order = {}
  self.playlist_metadata = {}
  self.playlist_pointer = 1
  self.follow_playhead = (opts.follow_playhead ~= false)
  self.transport_override = (opts.transport_override == true)
  self.loop_playlist = (opts.loop_playlist == true)
  self.on_repeat_cycle = opts.on_repeat_cycle
  self.playlist_lookup = opts.playlist_lookup
  
  self.context_stack = {}
  
  self.state_change_count = 0
  self.is_playing = false
  
  self.current_idx = -1
  self.next_idx = -1
  self.current_bounds = {start_pos = 0, end_pos = -1}
  self.next_bounds = {start_pos = 0, end_pos = -1}
  self.last_seek_time = 0
  self.seek_throttle = 0.06
  self.boundary_epsilon = 0.01
  self.last_play_pos = -1
  
  self._playlist_mode = false
  self._old_smoothseek = nil
  self._old_repeat = nil

  self:rescan()
  
  return self
end

function Engine:rescan()
  local regions = Regions.scan_project_regions(self.proj)
  
  self.region_cache = {}
  for _, rgn in ipairs(regions) do
    self.region_cache[rgn.rid] = rgn
  end
  
  self.state_change_count = Transport.get_project_state_change_count(self.proj)
end

function Engine:check_for_changes()
  local current_state = Transport.get_project_state_change_count(self.proj)
  if current_state ~= self.state_change_count then
    self:rescan()
    return true
  end
  return false
end

function Engine:_enter_playlist_mode_if_needed()
  if self._playlist_mode then return end
  if _has_sws() then
    self._old_smoothseek = reaper.SNM_GetIntConfigVar("smoothseek", -1)
    reaper.SNM_SetIntConfigVar("smoothseek", 3)

    self._old_repeat = reaper.GetSetRepeat(-1)
    if self._old_repeat == 1 then
      reaper.GetSetRepeat(0)
    end
  end
  self._playlist_mode = true
end

function Engine:_leave_playlist_mode_if_needed()
  if not self._playlist_mode then return end
  if _has_sws() then
    if self._old_smoothseek ~= nil then
      reaper.SNM_SetIntConfigVar("smoothseek", self._old_smoothseek)
      self._old_smoothseek = nil
    end
    if self._old_repeat == 1 then
      reaper.GetSetRepeat(1)
    end
    self._old_repeat = nil
  end
  self._playlist_mode = false
end

function Engine:set_order(new_order)
  self.playlist_order = {}
  self.playlist_metadata = {}
  
  for _, entry in ipairs(new_order) do
    self.playlist_order[#self.playlist_order + 1] = entry
    self.playlist_metadata[#self.playlist_metadata + 1] = {
      key = entry.key,
      current_loop = 1,
    }
  end
  
  self.playlist_pointer = _clamp(self.playlist_pointer, 1, math.max(1, #self.playlist_order))
  self.current_idx = -1
  self.next_idx = -1
  self.context_stack = {}
end

function Engine:_get_current_context()
  if #self.context_stack == 0 then
    return {
      items = self.playlist_order,
      index = self.current_idx,
      current_rep = self.current_idx > 0 and self.playlist_metadata[self.current_idx].current_loop or 1,
      total_reps = self.current_idx > 0 and (self.playlist_order[self.current_idx].reps or 1) or 1,
      parent_key = nil,
    }
  else
    return self.context_stack[#self.context_stack]
  end
end

function Engine:_get_current_item_from_context()
  local context = self:_get_current_context()
  if context.index >= 1 and context.index <= #context.items then
    return context.items[context.index]
  end
  return nil
end

function Engine:_push_context(playlist_item, playlist_data)
  local new_context = {
    items = playlist_data.items,
    index = 1,
    current_rep = 1,
    total_reps = playlist_item.reps or 1,
    parent_key = playlist_item.key,
    playlist_id = playlist_item.playlist_id,
  }
  self.context_stack[#self.context_stack + 1] = new_context
end

function Engine:_pop_context()
  if #self.context_stack > 0 then
    table.remove(self.context_stack)
    return true
  end
  return false
end

function Engine:_advance_in_context()
  if #self.context_stack == 0 then
    local meta = self.playlist_metadata[self.current_idx]
    if not meta then return false end
    
    local current_item = self.playlist_order[self.current_idx]
    if not current_item then return false end
    
    if meta.current_loop < (current_item.reps or 1) then
      meta.current_loop = meta.current_loop + 1
      
      if self.on_repeat_cycle and meta.key then
        self.on_repeat_cycle(meta.key, meta.current_loop, current_item.reps or 1)
      end
      
      return false
    else
      meta.current_loop = 1
      self.current_idx = self.current_idx + 1
      
      if self.current_idx > #self.playlist_order then
        if self.loop_playlist then
          self.current_idx = 1
        else
          return false
        end
      end
      
      return true
    end
  else
    local context = self.context_stack[#self.context_stack]
    context.index = context.index + 1
    
    if context.index > #context.items then
      if context.current_rep < context.total_reps then
        context.current_rep = context.current_rep + 1
        context.index = 1
        
        if self.on_repeat_cycle and context.parent_key then
          self.on_repeat_cycle(context.parent_key, context.current_rep, context.total_reps)
        end
        
        return false
      else
        self:_pop_context()
        return self:_advance_in_context()
      end
    end
    
    return true
  end
end

function Engine:_resolve_to_region_recursive()
  local max_depth = 100
  local depth = 0
  
  while depth < max_depth do
    local item = self:_get_current_item_from_context()
    
    if not item then
      return nil
    end
    
    if item.type == "region" then
      return self:get_region_by_rid(item.rid)
    end
    
    if item.type == "playlist" then
      if not self.playlist_lookup then
        return nil
      end
      
      local playlist = self.playlist_lookup(item.playlist_id)
      if not playlist or #playlist.items == 0 then
        if not self:_advance_in_context() then
          return nil
        end
        depth = depth + 1
      else
        self:_push_context(item, playlist)
        depth = depth + 1
      end
    else
      return nil
    end
  end
  
  return nil
end

function Engine:get_current_rid()
  local region = self:_resolve_to_region_recursive()
  return region and region.rid or nil
end

function Engine:get_region_by_rid(rid)
  return self.region_cache[rid]
end

function Engine:_seek_to_region(region_num)
  local now = reaper.time_precise()
  if now - self.last_seek_time < self.seek_throttle then
    return false
  end
  
  local cursor_pos = reaper.GetCursorPositionEx(self.proj)
  
  reaper.PreventUIRefresh(1)
  reaper.GoToRegion(self.proj, region_num, false)
  
  if not _is_playing(self.proj) then
    reaper.OnPlayButton()
  end
  
  reaper.SetEditCurPos2(self.proj, cursor_pos, false, false)
  reaper.PreventUIRefresh(-1)
  
  self.last_seek_time = now
  return true
end

function Engine:_resolve_to_region(item)
  if not item then return nil end
  
  if item.type == "region" then
    return self:get_region_by_rid(item.rid)
  end
  
  if item.type == "playlist" and self.playlist_lookup then
    local playlist = self.playlist_lookup(item.playlist_id)
    if playlist and #playlist.items > 0 then
      return self:_resolve_to_region(playlist.items[1])
    end
  end
  
  return nil
end

function Engine:_update_bounds()
  if self.current_idx >= 1 and self.current_idx <= #self.playlist_order then
    local item = self.playlist_order[self.current_idx]
    local region = self:_resolve_to_region(item)
    if region then
      self.current_bounds.start_pos = region.start
      self.current_bounds.end_pos = region["end"]
    end
  else
    self.current_bounds.start_pos = 0
    self.current_bounds.end_pos = -1
  end
  
  if self.next_idx >= 1 and self.next_idx <= #self.playlist_order then
    local item = self.playlist_order[self.next_idx]
    local region = self:_resolve_to_region(item)
    if region then
      self.next_bounds.start_pos = region.start
      self.next_bounds.end_pos = region["end"]
    end
  else
    self.next_bounds.start_pos = 0
    self.next_bounds.end_pos = -1
  end
end

function Engine:_find_index_at_position(pos)
  for i = 1, #self.playlist_order do
    local item = self.playlist_order[i]
    local region = self:_resolve_to_region(item)
    if region and pos >= region.start and pos < region["end"] - 1e-9 then
      return i
    end
  end
  return -1
end

function Engine:play()
  if #self.playlist_order == 0 then return false end
  
  self.current_idx = self.playlist_pointer
  self.context_stack = {}
  
  local region = self:_resolve_to_region_recursive()
  if not region then return false end

  self:_enter_playlist_mode_if_needed()

  if _is_playing(self.proj) then
    local region_num = region.rid
    self:_seek_to_region(region_num)
  else
    reaper.SetEditCurPos2(self.proj, region.start, false, false)
    reaper.OnPlayButton()
  end

  self.is_playing = true
  self.next_idx = self.playlist_pointer
  self:_update_bounds()
  
  return true
end

function Engine:stop()
  reaper.OnStopButton()
  self.is_playing = false
  self.current_idx = -1
  self.next_idx = -1
  self.context_stack = {}
  self:_leave_playlist_mode_if_needed()
end

function Engine:next()
  if #self.playlist_order == 0 then return false end
  
  local advanced = self:_advance_in_context()
  
  if not advanced and self.current_idx > #self.playlist_order then
    return false
  end
  
  self.playlist_pointer = self.current_idx
  
  if _is_playing(self.proj) then
    local region = self:_resolve_to_region_recursive()
    if region then
      return self:_seek_to_region(region.rid)
    end
  else
    return self:play()
  end
  
  return false
end

function Engine:prev()
  if #self.playlist_order == 0 then return false end
  
  if #self.context_stack > 0 then
    local context = self.context_stack[#self.context_stack]
    if context.index > 1 then
      context.index = context.index - 1
    else
      self:_pop_context()
      return self:prev()
    end
  else
    if self.current_idx > 1 then
      self.current_idx = self.current_idx - 1
      local meta = self.playlist_metadata[self.current_idx]
      if meta then
        meta.current_loop = 1
      end
    else
      return false
    end
  end
  
  self.playlist_pointer = self.current_idx
  
  if _is_playing(self.proj) then
    local region = self:_resolve_to_region_recursive()
    if region then
      return self:_seek_to_region(region.rid)
    end
  else
    return self:play()
  end
  
  return false
end

function Engine:jump_to_index(idx)
  if #self.playlist_order == 0 then return false end
  if idx < 1 or idx > #self.playlist_order then return false end
  
  self.current_idx = idx
  self.playlist_pointer = idx
  self.context_stack = {}
  
  local meta = self.playlist_metadata[idx]
  if meta then
    meta.current_loop = 1
  end

  if _is_playing(self.proj) then
    local region = self:_resolve_to_region_recursive()
    if region then
      return self:_seek_to_region(region.rid)
    end
  else
    return self:play()
  end
  
  return false
end

function Engine:poll_transport_sync()
  if not self.transport_override then return end
  if self.is_playing then return end
  
  if not _is_playing(self.proj) then return end
  
  local playpos = _get_play_pos(self.proj)
  
  for i = 1, #self.playlist_order do
    local item = self.playlist_order[i]
    local region = self:_resolve_to_region(item)
    if region then
      if playpos >= region.start and playpos < region["end"] then
        self.playlist_pointer = i
        self.is_playing = true
        self.current_idx = i
        self.context_stack = {}
        
        local meta = self.playlist_metadata[i]
        local should_loop = meta and meta.current_loop < (item.reps or 1)
        
        if should_loop then
          self.next_idx = i
        else
          if i < #self.playlist_order then
            self.next_idx = i + 1
          elseif self.loop_playlist and #self.playlist_order > 0 then
            self.next_idx = 1
          else
            self.next_idx = -1
          end
        end
        
        self:_update_bounds()
        self:_enter_playlist_mode_if_needed()
        return
      end
    end
  end
end

function Engine:_handle_smooth_transitions()
  if not _is_playing(self.proj) then return end
  if #self.playlist_order == 0 then return end
  
  local playpos = _get_play_pos(self.proj)
  local current_region = self:_resolve_to_region_recursive()
  
  if not current_region then
    self:_advance_in_context()
    current_region = self:_resolve_to_region_recursive()
    
    if current_region then
      self:_seek_to_region(current_region.rid)
    end
    return
  end
  
  if playpos >= current_region["end"] - self.boundary_epsilon then
    local context = self:_get_current_context()
    local current_item = self:_get_current_item_from_context()
    
    if current_item and self.on_repeat_cycle then
      if #self.context_stack > 0 then
        if context.index >= #context.items and context.current_rep < context.total_reps then
          self.on_repeat_cycle(context.parent_key, context.current_rep + 1, context.total_reps)
        end
      else
        local meta = self.playlist_metadata[self.current_idx]
        if meta and meta.current_loop < (current_item.reps or 1) then
          self.on_repeat_cycle(meta.key, meta.current_loop + 1, current_item.reps or 1)
        end
      end
    end
    
    self:_advance_in_context()
    
    local next_region = self:_resolve_to_region_recursive()
    if next_region then
      self:_seek_to_region(next_region.rid)
      self.playlist_pointer = self.current_idx
    else
      self:stop()
    end
  end
  
  self.last_play_pos = playpos
end

function Engine:update()
  self:check_for_changes()
  
  if not _is_playing(self.proj) then
    if self.is_playing then
      self.is_playing = false
      self.current_idx = -1
      self.next_idx = -1
      self.context_stack = {}
      self:_leave_playlist_mode_if_needed()
    end
    return
  end
  
  if not self.is_playing then
    self:poll_transport_sync()
    if not self.is_playing then
      return
    end
  end
  
  if #self.playlist_order == 0 then return end
  
  self:_handle_smooth_transitions()
end

function Engine:set_follow_playhead(enabled)
  self.follow_playhead = not not enabled
end

function Engine:set_transport_override(enabled)
  self.transport_override = not not enabled
end

function Engine:get_transport_override()
  return self.transport_override
end

function Engine:set_loop_playlist(enabled)
  self.loop_playlist = not not enabled
end

function Engine:get_loop_playlist()
  return self.loop_playlist
end

function Engine:get_state()
  return {
    proj = self.proj,
    region_cache = self.region_cache,
    playlist_order = self.playlist_order,
    playlist_pointer = self.playlist_pointer,
    follow_playhead = self.follow_playhead,
    transport_override = self.transport_override,
    loop_playlist = self.loop_playlist,
    is_playing = self.is_playing,
    has_sws = _has_sws(),
    _playlist_mode = self._playlist_mode,
    current_idx = self.current_idx,
    next_idx = self.next_idx,
    context_depth = #self.context_stack,
  }
end

M.Engine = Engine
return M