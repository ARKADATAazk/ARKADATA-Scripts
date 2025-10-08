-- ReArkitekt/features/region_playlist/engine.lua
-- Simplified Region Playlist Engine with SnM-style smooth transitions

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
    local rid = type(entry) == "table" and entry.rid or entry
    if self.region_cache[rid] then
      self.playlist_order[#self.playlist_order + 1] = rid
      self.playlist_metadata[#self.playlist_metadata + 1] = {
        key = type(entry) == "table" and entry.key or nil,
        reps = type(entry) == "table" and entry.reps or 1,
        current_loop = 1,
      }
    end
  end
  
  self.playlist_pointer = _clamp(self.playlist_pointer, 1, math.max(1, #self.playlist_order))
  self.current_idx = -1
  self.next_idx = -1
end

function Engine:get_current_rid()
  if self.playlist_pointer < 1 or self.playlist_pointer > #self.playlist_order then
    return nil
  end
  return self.playlist_order[self.playlist_pointer]
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

function Engine:_update_bounds()
  if self.current_idx >= 1 and self.current_idx <= #self.playlist_order then
    local rid = self.playlist_order[self.current_idx]
    local region = self:get_region_by_rid(rid)
    if region then
      self.current_bounds.start_pos = region.start
      self.current_bounds.end_pos = region["end"]
    end
  else
    self.current_bounds.start_pos = 0
    self.current_bounds.end_pos = -1
  end
  
  if self.next_idx >= 1 and self.next_idx <= #self.playlist_order then
    local rid = self.playlist_order[self.next_idx]
    local region = self:get_region_by_rid(rid)
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
    local rid = self.playlist_order[i]
    local region = self:get_region_by_rid(rid)
    if region and pos >= region.start and pos < region["end"] - 1e-9 then
      return i
    end
  end
  return -1
end

function Engine:play()
  local rid = self:get_current_rid()
  if not rid then return false end

  local region = self:get_region_by_rid(rid)
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
  self.current_idx = -1
  self.next_idx = self.playlist_pointer
  self:_update_bounds()
  
  return true
end

function Engine:stop()
  reaper.OnStopButton()
  self.is_playing = false
  self.current_idx = -1
  self.next_idx = -1
  self:_leave_playlist_mode_if_needed()
end

function Engine:next()
  if #self.playlist_order == 0 then return false end
  if self.playlist_pointer >= #self.playlist_order then return false end
  self.playlist_pointer = self.playlist_pointer + 1

  if _is_playing(self.proj) then
    local rid = self:get_current_rid()
    local region = self:get_region_by_rid(rid)
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
  if self.playlist_pointer <= 1 then return false end
  self.playlist_pointer = self.playlist_pointer - 1

  if _is_playing(self.proj) then
    local rid = self:get_current_rid()
    local region = self:get_region_by_rid(rid)
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
  self.playlist_pointer = idx

  if _is_playing(self.proj) then
    local rid = self:get_current_rid()
    local region = self:get_region_by_rid(rid)
    if region then
      return self:_seek_to_region(region.rid)
    end
  else
    return self:play()
  end
  
  return false
end

function Engine:jump_to_rid(rid)
  if #self.playlist_order == 0 or not rid then return false end
  
  local found = nil
  for i, r in ipairs(self.playlist_order) do
    if r == rid then 
      found = i 
      break 
    end
  end
  if not found then return false end
  
  self.playlist_pointer = found

  if _is_playing(self.proj) then
    local region = self:get_region_by_rid(rid)
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
  
  for i, rid in ipairs(self.playlist_order) do
    local region = self:get_region_by_rid(rid)
    if region then
      if playpos >= region.start and playpos < region["end"] then
        self.playlist_pointer = i
        self.is_playing = true
        self.current_idx = i
        
        local meta = self.playlist_metadata[i]
        local should_loop = meta and meta.current_loop < meta.reps
        
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
  
  if self.next_idx >= 1 and 
     playpos >= self.next_bounds.start_pos and 
     playpos < self.next_bounds.end_pos + self.boundary_epsilon then
    
    local entering_different_region = (self.current_idx ~= self.next_idx)
    local playhead_went_backward = (playpos < self.last_play_pos - 0.1)
    
    if entering_different_region or playhead_went_backward then
      reaper.ShowConsoleMsg(string.format("[LOOP] Transition: different=%s backward=%s\n", 
        tostring(entering_different_region), tostring(playhead_went_backward)))
      
      self.current_idx = self.next_idx
      self.playlist_pointer = self.current_idx
      local rid = self.playlist_order[self.current_idx]
      local region = self:get_region_by_rid(rid)
      if region then
        self.current_bounds.start_pos = region.start
        self.current_bounds.end_pos = region["end"]
      end
      
      local meta = self.playlist_metadata[self.current_idx]
      
      if meta then
        reaper.ShowConsoleMsg(string.format("[LOOP] idx=%d loop=%d/%d\n", 
          self.current_idx, meta.current_loop, meta.reps))
      end
      
      if meta and meta.current_loop < meta.reps then
        meta.current_loop = meta.current_loop + 1
        reaper.ShowConsoleMsg(string.format("[LOOP] LOOPING! new loop=%d/%d\n", 
          meta.current_loop, meta.reps))
        
        if self.on_repeat_cycle and meta.key then
          self.on_repeat_cycle(meta.key, meta.current_loop, meta.reps)
        end
        
        self.next_idx = self.current_idx
        local rid = self.playlist_order[self.current_idx]
        local region = self:get_region_by_rid(rid)
        if region then
          self.next_bounds.start_pos = region.start
          self.next_bounds.end_pos = region["end"]
          self:_seek_to_region(region.rid)
        end
      else
        if meta then
          meta.current_loop = 1
          reaper.ShowConsoleMsg("[LOOP] ADVANCING to next region\n")
        end
        
        local next_candidate
        if self.current_idx < #self.playlist_order then
          next_candidate = self.current_idx + 1
        elseif self.loop_playlist and #self.playlist_order > 0 then
          next_candidate = 1
          reaper.ShowConsoleMsg("[LOOP] WRAPPING to start\n")
        else
          next_candidate = -1
        end
        
        if next_candidate >= 1 then
          self.next_idx = next_candidate
          local rid = self.playlist_order[self.next_idx]
          local region = self:get_region_by_rid(rid)
          if region then
            self.next_bounds.start_pos = region.start
            self.next_bounds.end_pos = region["end"]
            self:_seek_to_region(region.rid)
          end
        else
          self.next_idx = -1
        end
      end
    end
    
  elseif self.current_bounds.end_pos > self.current_bounds.start_pos and
         playpos >= self.current_bounds.start_pos and 
         playpos < self.current_bounds.end_pos + self.boundary_epsilon then
    
  else
    local found_idx = self:_find_index_at_position(playpos)
    if found_idx >= 1 then
      local was_uninitialized = (self.current_idx == -1)
      
      reaper.ShowConsoleMsg(string.format("[LOOP] Init at idx=%d\n", found_idx))
      
      self.current_idx = found_idx
      self.playlist_pointer = found_idx
      local rid = self.playlist_order[found_idx]
      local region = self:get_region_by_rid(rid)
      if region then
        self.current_bounds.start_pos = region.start
        self.current_bounds.end_pos = region["end"]
      end
      
      local meta = self.playlist_metadata[found_idx]
      local should_advance = not meta or meta.current_loop >= meta.reps
      
      if meta then
        reaper.ShowConsoleMsg(string.format("[LOOP] Init metadata: loop=%d/%d should_advance=%s\n", 
          meta.current_loop, meta.reps, tostring(should_advance)))
      end
      
      if should_advance then
        local next_candidate
        if found_idx < #self.playlist_order then
          next_candidate = found_idx + 1
        elseif self.loop_playlist and #self.playlist_order > 0 then
          next_candidate = 1
        else
          next_candidate = -1
        end
        
        if next_candidate >= 1 then
          self.next_idx = next_candidate
          local rid_next = self.playlist_order[self.next_idx]
          local region_next = self:get_region_by_rid(rid_next)
          if region_next then
            self.next_bounds.start_pos = region_next.start
            self.next_bounds.end_pos = region_next["end"]
            
            if was_uninitialized then
              self:_seek_to_region(region_next.rid)
            end
          end
        end
      else
        self.next_idx = found_idx
        self.next_bounds.start_pos = region.start
        self.next_bounds.end_pos = region["end"]
        if was_uninitialized then
          self:_seek_to_region(region.rid)
        end
      end
    elseif #self.playlist_order > 0 then
      local first_region = self:get_region_by_rid(self.playlist_order[1])
      if first_region and playpos < first_region.start then
        self.current_idx = -1
        self.next_idx = 1
        self.next_bounds.start_pos = first_region.start
        self.next_bounds.end_pos = first_region["end"]
      end
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
  }
end

M.Engine = Engine
return M