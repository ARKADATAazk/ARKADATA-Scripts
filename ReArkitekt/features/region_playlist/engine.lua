-- ReArkitekt/features/region_playlist/engine.lua
-- FULLY LOGGED VERSION - trace all execution paths

local Regions = require('ReArkitekt.reaper.regions')
local Transport = require('ReArkitekt.reaper.transport')

local M = {}
local Engine = {}
Engine.__index = Engine

-- Logging to file
local log_file = nil

local log_path = reaper.GetResourcePath() .. "/engine_debug.log"

local function log_init()
  log_file = io.open(log_path, "w")
  if log_file then
    log_file:write(string.format("=== Engine Debug Log ===\nStarted: %s\n\n", os.date()))
    log_file:flush()
  end
end

local function log_write(msg)
  if log_file then
    log_file:write(string.format("[%.3f] %s", reaper.time_precise(), msg))
    log_file:flush()
  end
  reaper.ShowConsoleMsg(msg)
end

local function log_close()
  if log_file then
    log_file:close()
    log_file = nil
  end
end

log_init()

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
  
  log_write(string.format("[ENGINE] Created: %d regions cached\n", 
    self:_count_regions()))
  
  return self
end

function Engine:_count_regions()
  local count = 0
  for _ in pairs(self.region_cache) do count = count + 1 end
  return count
end

function Engine:rescan()
  log_write("[ENGINE] Rescan: scanning project regions\n")
  local regions = Regions.scan_project_regions(self.proj)
  
  self.region_cache = {}
  for _, rgn in ipairs(regions) do
    self.region_cache[rgn.rid] = rgn
  end
  
  self.state_change_count = Transport.get_project_state_change_count(self.proj)
  log_write(string.format("[ENGINE] Rescan: found %d regions, state_count=%d\n", 
    #regions, self.state_change_count))
end

function Engine:check_for_changes()
  local current_state = Transport.get_project_state_change_count(self.proj)
  if current_state ~= self.state_change_count then
    log_write(string.format("[ENGINE] Project changed: %d -> %d\n", 
      self.state_change_count, current_state))
    self:rescan()
    return true
  end
  return false
end

function Engine:_enter_playlist_mode_if_needed()
  if self._playlist_mode then 
    log_write("[ENGINE] Already in playlist mode\n")
    return 
  end
  log_write("[ENGINE] Entering playlist mode\n")
  if _has_sws() then
    self._old_smoothseek = reaper.SNM_GetIntConfigVar("smoothseek", -1)
    reaper.SNM_SetIntConfigVar("smoothseek", 3)
    log_write(string.format("[ENGINE] Set smoothseek: %d -> 3\n", self._old_smoothseek))

    self._old_repeat = reaper.GetSetRepeat(-1)
    if self._old_repeat == 1 then
      reaper.GetSetRepeat(0)
      log_write("[ENGINE] Disabled repeat mode\n")
    end
  end
  self._playlist_mode = true
end

function Engine:_leave_playlist_mode_if_needed()
  if not self._playlist_mode then 
    log_write("[ENGINE] Not in playlist mode\n")
    return 
  end
  log_write("[ENGINE] Leaving playlist mode\n")
  if _has_sws() then
    if self._old_smoothseek ~= nil then
      reaper.SNM_SetIntConfigVar("smoothseek", self._old_smoothseek)
      log_write(string.format("[ENGINE] Restored smoothseek: %d\n", self._old_smoothseek))
      self._old_smoothseek = nil
    end
    if self._old_repeat == 1 then
      reaper.GetSetRepeat(1)
      log_write("[ENGINE] Restored repeat mode\n")
    end
    self._old_repeat = nil
  end
  self._playlist_mode = false
end

function Engine:set_order(new_order)
  log_write(string.format("[ENGINE] set_order: %d items\n", #new_order))
  self.playlist_order = {}
  self.playlist_metadata = {}
  
  for i, entry in ipairs(new_order) do
    local rid = type(entry) == "table" and entry.rid or entry
    if self.region_cache[rid] then
      self.playlist_order[#self.playlist_order + 1] = rid
      self.playlist_metadata[#self.playlist_metadata + 1] = {
        key = type(entry) == "table" and entry.key or nil,
        reps = type(entry) == "table" and entry.reps or 1,
        current_loop = 1,
      }
      log_write(string.format("[ENGINE] Added: idx=%d rid=%d reps=%d key=%s\n", 
        #self.playlist_order, rid, 
        self.playlist_metadata[#self.playlist_metadata].reps,
        tostring(self.playlist_metadata[#self.playlist_metadata].key)))
    else
      log_write(string.format("[ENGINE] Skipped: entry %d, rid=%s not in cache\n", 
        i, tostring(rid)))
    end
  end
  
  self.playlist_pointer = _clamp(self.playlist_pointer, 1, math.max(1, #self.playlist_order))
  self.current_idx = -1
  self.next_idx = -1
  log_write(string.format("[ENGINE] Final order: %d items, pointer=%d\n", 
    #self.playlist_order, self.playlist_pointer))
end

function Engine:get_current_rid()
  log_write(string.format("[ENGINE] get_current_rid: pointer=%d/%d\n", 
    self.playlist_pointer, #self.playlist_order))
  if self.playlist_pointer < 1 or self.playlist_pointer > #self.playlist_order then
    log_write("[ENGINE] get_current_rid: OUT OF BOUNDS -> nil\n")
    return nil
  end
  local rid = self.playlist_order[self.playlist_pointer]
  log_write(string.format("[ENGINE] get_current_rid: -> %d\n", rid))
  return rid
end

function Engine:get_region_by_rid(rid)
  return self.region_cache[rid]
end

function Engine:_seek_to_region(region_num)
  local now = reaper.time_precise()
  if now - self.last_seek_time < self.seek_throttle then
    log_write(string.format("[ENGINE] _seek_to_region: THROTTLED (%.3fs since last)\n", 
      now - self.last_seek_time))
    return false
  end
  
  log_write(string.format("[ENGINE] _seek_to_region: region_num=%d\n", region_num))
  
  local cursor_pos = reaper.GetCursorPositionEx(self.proj)
  
  reaper.PreventUIRefresh(1)
  reaper.GoToRegion(self.proj, region_num, false)
  
  if not _is_playing(self.proj) then
    log_write("[ENGINE] _seek_to_region: Starting playback\n")
    reaper.OnPlayButton()
  end
  
  reaper.SetEditCurPos2(self.proj, cursor_pos, false, false)
  reaper.PreventUIRefresh(-1)
  
  self.last_seek_time = now
  log_write("[ENGINE] _seek_to_region: SUCCESS\n")
  return true
end

function Engine:_update_bounds()
  log_write(string.format("[ENGINE] _update_bounds: current_idx=%d next_idx=%d\n", 
    self.current_idx, self.next_idx))
  
  if self.current_idx >= 1 and self.current_idx <= #self.playlist_order then
    local rid = self.playlist_order[self.current_idx]
    local region = self:get_region_by_rid(rid)
    if region then
      self.current_bounds.start_pos = region.start
      self.current_bounds.end_pos = region["end"]
      log_write(string.format("[ENGINE] current_bounds: [%.3f - %.3f] (rid=%d)\n", 
        region.start, region["end"], rid))
    end
  else
    self.current_bounds.start_pos = 0
    self.current_bounds.end_pos = -1
    log_write("[ENGINE] current_bounds: INVALID\n")
  end
  
  if self.next_idx >= 1 and self.next_idx <= #self.playlist_order then
    local rid = self.playlist_order[self.next_idx]
    local region = self:get_region_by_rid(rid)
    if region then
      self.next_bounds.start_pos = region.start
      self.next_bounds.end_pos = region["end"]
      log_write(string.format("[ENGINE] next_bounds: [%.3f - %.3f] (rid=%d)\n", 
        region.start, region["end"], rid))
    end
  else
    self.next_bounds.start_pos = 0
    self.next_bounds.end_pos = -1
    log_write("[ENGINE] next_bounds: INVALID\n")
  end
end

function Engine:_find_index_at_position(pos)
  log_write(string.format("[ENGINE] _find_index_at_position: pos=%.3f\n", pos))
  for i = 1, #self.playlist_order do
    local rid = self.playlist_order[i]
    local region = self:get_region_by_rid(rid)
    if region and pos >= region.start and pos < region["end"] - 1e-9 then
      log_write(string.format("[ENGINE] Found: idx=%d rid=%d [%.3f-%.3f]\n", 
        i, rid, region.start, region["end"]))
      return i
    end
  end
  log_write("[ENGINE] NOT FOUND\n")
  return -1
end

function Engine:play()
  log_write("\n[ENGINE] ========== PLAY ==========\n")
  local rid = self:get_current_rid()
  if not rid then 
    log_write("[ENGINE] play: no current rid -> FAIL\n")
    return false 
  end

  local region = self:get_region_by_rid(rid)
  if not region then 
    log_write(string.format("[ENGINE] play: region %d not found -> FAIL\n", rid))
    return false 
  end

  self:_enter_playlist_mode_if_needed()

  if _is_playing(self.proj) then
    log_write("[ENGINE] play: Already playing, seeking\n")
    local region_num = region.rid
    self:_seek_to_region(region_num)
  else
    log_write(string.format("[ENGINE] play: Starting from %.3f\n", region.start))
    reaper.SetEditCurPos2(self.proj, region.start, false, false)
    reaper.OnPlayButton()
  end

  self.is_playing = true
  self.current_idx = -1
  self.next_idx = self.playlist_pointer
  log_write(string.format("[ENGINE] play: Set next_idx=%d\n", self.next_idx))
  self:_update_bounds()
  
  log_write("[ENGINE] play: SUCCESS\n")
  return true
end

function Engine:stop()
  log_write("\n[ENGINE] ========== STOP ==========\n")
  reaper.OnStopButton()
  self.is_playing = false
  self.current_idx = -1
  self.next_idx = -1
  self:_leave_playlist_mode_if_needed()
end

function Engine:next()
  log_write("\n[ENGINE] ========== NEXT ==========\n")
  if #self.playlist_order == 0 then 
    log_write("[ENGINE] next: Empty playlist\n")
    return false 
  end
  if self.playlist_pointer >= #self.playlist_order then 
    log_write("[ENGINE] next: At end of playlist\n")
    return false 
  end
  self.playlist_pointer = self.playlist_pointer + 1
  log_write(string.format("[ENGINE] next: pointer -> %d\n", self.playlist_pointer))

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
  log_write("\n[ENGINE] ========== PREV ==========\n")
  if #self.playlist_order == 0 then 
    log_write("[ENGINE] prev: Empty playlist\n")
    return false 
  end
  if self.playlist_pointer <= 1 then 
    log_write("[ENGINE] prev: At start of playlist\n")
    return false 
  end
  self.playlist_pointer = self.playlist_pointer - 1
  log_write(string.format("[ENGINE] prev: pointer -> %d\n", self.playlist_pointer))

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

function Engine:poll_transport_sync()
  if not self.transport_override then return end
  if self.is_playing then return end
  
  if not _is_playing(self.proj) then return end
  
  log_write("[ENGINE] poll_transport_sync: Checking position\n")
  local playpos = _get_play_pos(self.proj)
  
  for i, rid in ipairs(self.playlist_order) do
    local region = self:get_region_by_rid(rid)
    if region then
      if playpos >= region.start and playpos < region["end"] then
        log_write(string.format("[ENGINE] poll_transport_sync: SYNCED to idx=%d\n", i))
        self.playlist_pointer = i
        self.is_playing = true
        self.current_idx = i
        
        local meta = self.playlist_metadata[i]
        local should_loop = meta and meta.current_loop < meta.reps
        
        if should_loop then
          self.next_idx = i
          log_write("[ENGINE] poll_transport_sync: Should loop current\n")
        else
          if i < #self.playlist_order then
            self.next_idx = i + 1
          elseif self.loop_playlist and #self.playlist_order > 0 then
            self.next_idx = 1
            log_write("[ENGINE] poll_transport_sync: Wrapping to start\n")
          else
            self.next_idx = -1
          end
          log_write(string.format("[ENGINE] poll_transport_sync: next_idx=%d\n", self.next_idx))
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
  
  -- Branch 1: In next_bounds region
  if self.next_idx >= 1 and 
     playpos >= self.next_bounds.start_pos and 
     playpos < self.next_bounds.end_pos + self.boundary_epsilon then
    
    local entering_different_region = (self.current_idx ~= self.next_idx)
    local playhead_went_backward = (playpos < self.last_play_pos - 0.1)
    
    log_write(string.format("[TRANS] In next_bounds: enter_diff=%s backward=%s\n", 
      tostring(entering_different_region), tostring(playhead_went_backward)))
    
    if entering_different_region or playhead_went_backward then
      log_write(string.format("[TRANS] TRANSITION: current %d -> %d\n", 
        self.current_idx, self.next_idx))
      
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
        log_write(string.format("[TRANS] Meta: loop=%d/%d key=%s\n", 
          meta.current_loop, meta.reps, tostring(meta.key)))
      end
      
      -- Check if should loop current item
      if meta and meta.current_loop < meta.reps then
        meta.current_loop = meta.current_loop + 1
        log_write(string.format("[TRANS] LOOPING item: %d/%d\n", 
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
        -- Advance to next item
        if meta then
          meta.current_loop = 1
        end
        log_write("[TRANS] ADVANCING to next\n")
        
        local next_candidate
        if self.current_idx < #self.playlist_order then
          next_candidate = self.current_idx + 1
        elseif self.loop_playlist and #self.playlist_order > 0 then
          next_candidate = 1
          log_write("[TRANS] Wrapping to playlist start\n")
        else
          next_candidate = -1
        end
        
        log_write(string.format("[TRANS] next_candidate=%d\n", next_candidate))
        
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
          log_write("[TRANS] No next item, stopping\n")
        end
      end
    end
    
  -- Branch 2: In current_bounds region
  elseif self.current_bounds.end_pos > self.current_bounds.start_pos and
         playpos >= self.current_bounds.start_pos and 
         playpos < self.current_bounds.end_pos + self.boundary_epsilon then
    -- Inside current region, no action needed
    
  -- Branch 3: Neither - need to sync
  else
    log_write(string.format("[TRANS] OUT OF BOUNDS: pos=%.3f\n", playpos))
    local found_idx = self:_find_index_at_position(playpos)
    if found_idx >= 1 then
      local was_uninitialized = (self.current_idx == -1)
      
      log_write(string.format("[TRANS] INIT/SYNC: idx=%d uninit=%s\n", 
        found_idx, tostring(was_uninitialized)))
      
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
        log_write(string.format("[TRANS] Init meta: loop=%d/%d advance=%s\n", 
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
              log_write("[TRANS] Seeking to next (init)\n")
              self:_seek_to_region(region_next.rid)
            end
          end
        end
      else
        self.next_idx = found_idx
        self.next_bounds.start_pos = region.start
        self.next_bounds.end_pos = region["end"]
        if was_uninitialized then
          log_write("[TRANS] Seeking to current (init, needs loop)\n")
          self:_seek_to_region(region.rid)
        end
      end
    elseif #self.playlist_order > 0 then
      local first_region = self:get_region_by_rid(self.playlist_order[1])
      if first_region and playpos < first_region.start then
        log_write("[TRANS] Before playlist start, prepping first\n")
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
      log_write("[ENGINE] update: Playback stopped\n")
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