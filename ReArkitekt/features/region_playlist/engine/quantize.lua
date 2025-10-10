-- ReArkitekt/features/region_playlist/engine/quantize.lua
-- Quantized transitions using trigger region hack

local M = {}
local Quantize = {}
Quantize.__index = Quantize

local TRIGGER_REGION_NAME = "__TRANSITION_TRIGGER"

local function _is_playing(proj)
  proj = proj or 0
  local st = reaper.GetPlayStateEx(proj)
  return (st & 1) == 1
end

local function _get_play_pos(proj)
  return reaper.GetPlayPositionEx(proj or 0)
end

function M.new(opts)
  opts = opts or {}
  local self = setmetatable({}, Quantize)
  
  self.proj = opts.proj or 0
  self.state = opts.state
  self.transport = opts.transport
  
  -- Quantize settings
  self.quantize_mode = "measure"  -- "measure" or grid division (0.25, 0.5, 1.0, etc)
  self.min_lookahead = 0.25  -- 10ms
  self.max_lookahead = 3.0   -- 200ms
  
  self.trigger_region = {
    rid = nil,
    marker_idx = nil,
    idle_position = 9999,
    is_active = false,
    target_rid = nil,
    fire_position = nil,
    last_playpos = nil,
  }
  
  return self
end

function Quantize:_ensure_trigger_region()
  local idx, num_markers = 0, reaper.CountProjectMarkers(self.proj)
  
  while idx < num_markers do
    local retval, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers(idx)
    if retval > 0 then
      if isrgn and name == TRIGGER_REGION_NAME then
        self.trigger_region.rid = markrgnindexnumber
        self.trigger_region.marker_idx = idx
        return true
      end
    end
    idx = idx + 1
  end
  
  local color = 0
  local new_idx = reaper.AddProjectMarker2(
    self.proj,
    true,
    self.trigger_region.idle_position,
    self.trigger_region.idle_position + 1,
    TRIGGER_REGION_NAME,
    -1,
    color
  )
  
  if new_idx >= 0 then
    local retval, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers(new_idx)
    if retval > 0 then
      self.trigger_region.rid = markrgnindexnumber
      self.trigger_region.marker_idx = new_idx
      return true
    end
  end
  
  return false
end

function Quantize:_reposition_trigger_region(start_pos, end_pos)
  self:_ensure_trigger_region()
  
  if not self.trigger_region.marker_idx then
    return false
  end
  
  local retval = reaper.SetProjectMarkerByIndex2(
    self.proj,
    self.trigger_region.marker_idx,
    true,
    start_pos,
    end_pos,
    self.trigger_region.rid,
    TRIGGER_REGION_NAME,
    0,
    0
  )
  
  reaper.ShowConsoleMsg(string.format("[QUANTIZE] Moved trigger: [%.3f - %.3f] retval=%s\n", 
    start_pos, end_pos, tostring(retval)))
  
  return retval
end

function Quantize:_calculate_next_quantize_point(playpos, skip_count)
  skip_count = skip_count or 0
  
  if self.quantize_mode == "measure" then
    -- Next measure (original working code)
    local retval, measures, cml, fullbeats, cdenom = reaper.TimeMap2_timeToBeats(self.proj, playpos)
    local next_measure_num = math.floor(measures) + 1 + skip_count
    local next_time = reaper.TimeMap2_beatsToTime(self.proj, 0, next_measure_num)
    
    reaper.ShowConsoleMsg(string.format("[QUANTIZE] Mode=measure, skip=%d -> measure=%d (%.3fs)\n", 
      skip_count, next_measure_num, next_time))
    
    return next_time
  else
    -- Grid division (in quarter notes) - calculate relative to measure
    local grid_div = tonumber(self.quantize_mode)
    if not grid_div or grid_div <= 0 then
      return nil
    end
    
    -- Get current position in beats relative to measure
    local retval, measures, cml, fullbeats, cdenom = reaper.TimeMap2_timeToBeats(self.proj, playpos)
    local beat_in_measure = fullbeats - (math.floor(measures) * cml)
    
    -- Find next grid point within or after current measure
    local next_beat_in_measure = math.ceil(beat_in_measure / grid_div) * grid_div
    
    -- If we're past the last grid point in this measure, go to first grid point of next measure
    local target_measure = math.floor(measures)
    if next_beat_in_measure >= cml then
      target_measure = target_measure + 1
      next_beat_in_measure = 0
    end
    
    -- Apply skip count
    local total_skip = skip_count
    while total_skip > 0 do
      next_beat_in_measure = next_beat_in_measure + grid_div
      if next_beat_in_measure >= cml then
        target_measure = target_measure + 1
        next_beat_in_measure = next_beat_in_measure - cml
      end
      total_skip = total_skip - 1
    end
    
    -- Convert to QN and then to time
    local target_qn = (target_measure * cml) + next_beat_in_measure
    local next_time = reaper.TimeMap2_QNToTime(self.proj, target_qn)
    
    reaper.ShowConsoleMsg(string.format("[QUANTIZE] Mode=grid(%.4f), skip=%d -> m=%d b=%.3f qn=%.3f (%.3fs)\n", 
      grid_div, skip_count, target_measure, next_beat_in_measure, target_qn, next_time))
    
    return next_time
  end
end

function Quantize:set_quantize_mode(mode)
  self.quantize_mode = mode
end

function Quantize:get_quantize_mode()
  return self.quantize_mode
end

function Quantize:jump_to_next_quantized(lookahead)
  lookahead = lookahead or 0.05
  
  reaper.ShowConsoleMsg("[QUANTIZE] jump_to_next_quantized called\n")
  
  if not self.transport.is_playing then
    reaper.ShowConsoleMsg("[QUANTIZE] Not playing, fallback to next()\n")
    return self.transport:next()
  end
  
  if not self:_ensure_trigger_region() then
    reaper.ShowConsoleMsg("[QUANTIZE] Failed to ensure trigger region\n")
    return self.transport:next()
  end
  
  local playpos = _get_play_pos(self.proj)
  
  -- Calculate next quantize point
  local next_quantize = self:_calculate_next_quantize_point(playpos, 0)
  
  if not next_quantize then
    reaper.ShowConsoleMsg("[QUANTIZE] Failed to calculate quantize point\n")
    return self.transport:next()
  end
  
  reaper.ShowConsoleMsg(string.format("[QUANTIZE] playpos=%.3f next_quantize=%.3f lookahead=%.3f\n", 
    playpos, next_quantize, lookahead))
  
  -- Keep skipping until we're beyond the lookahead window
  local skip_count = 0
  while next_quantize - playpos < lookahead do
    skip_count = skip_count + 1
    next_quantize = self:_calculate_next_quantize_point(playpos, skip_count)
    
    if not next_quantize then
      reaper.ShowConsoleMsg("[QUANTIZE] Failed to calculate next quantize point\n")
      return self.transport:next()
    end
    
    -- Safety: prevent infinite loop (shouldn't happen, but just in case)
    if skip_count > 100 then
      reaper.ShowConsoleMsg("[QUANTIZE] Too many skips, fallback to next()\n")
      return self.transport:next()
    end
  end
  
  if skip_count > 0 then
    reaper.ShowConsoleMsg(string.format("[QUANTIZE] Skipped %d grid points to: %.3f (safety margin: %.3fs)\n", 
      skip_count, next_quantize, next_quantize - playpos))
  end
  
  -- Check if too close to region end - if so, let natural transition happen
  if self.state.current_bounds.end_pos > 0 and 
     next_quantize >= self.state.current_bounds.end_pos - 0.6 then
    reaper.ShowConsoleMsg("[QUANTIZE] Too close to region end, natural transition will happen\n")
    return
  end
  
  if self.state.next_idx < 1 or self.state.next_idx > #self.state.playlist_order then
    reaper.ShowConsoleMsg("[QUANTIZE] No valid next_idx\n")
    return false
  end
  
  -- Move dummy region to overlap current with end at next quantize point
  local trigger_start = self.state.current_bounds.start_pos - 0.1
  local trigger_end = next_quantize
  
  if not self:_reposition_trigger_region(trigger_start, trigger_end) then
    reaper.ShowConsoleMsg("[QUANTIZE] Failed to reposition\n")
    return false
  end
  
  -- Save cursor position before any operations
  local cursor_pos = reaper.GetCursorPositionEx(self.proj)
  
  -- UpdateTimeline to make Reaper re-evaluate regions
  reaper.ShowConsoleMsg("[QUANTIZE] Calling UpdateTimeline\n")
  reaper.UpdateTimeline()
  
  -- Queue the target region (this is necessary!)
  local target_region = self.state:get_region_by_rid(self.state.playlist_order[self.state.next_idx])
  if target_region then
    reaper.ShowConsoleMsg(string.format("[QUANTIZE] Queuing GoToRegion(%d)\n", target_region.rid))
    reaper.GoToRegion(self.proj, target_region.rid, false)
  end
  
  -- Restore cursor position
  reaper.SetEditCurPos2(self.proj, cursor_pos, false, false)
  
  self.trigger_region.is_active = true
  self.trigger_region.target_rid = self.state.playlist_order[self.state.next_idx]
  self.trigger_region.fire_position = next_quantize
  self.trigger_region.last_playpos = playpos
  
  return true
end

function Quantize:update()
  if not self.trigger_region.is_active then
    return
  end
  
  if not self.transport.is_playing then
    reaper.ShowConsoleMsg("[QUANTIZE] update: Playback stopped, cleanup\n")
    self:_cleanup_trigger()
    return
  end
  
  local playpos = _get_play_pos(self.proj)
  
  -- Detect if user seeked backward (more than 0.2s jump back)
  if self.trigger_region.last_playpos and playpos < self.trigger_region.last_playpos - 0.2 then
    reaper.ShowConsoleMsg("[QUANTIZE] Backward seek detected, cleanup\n")
    self:_cleanup_trigger()
    return
  end
  
  self.trigger_region.last_playpos = playpos
  
  -- Check if we entered the target region (before the fire position)
  if self.trigger_region.target_rid then
    local target_region = self.state:get_region_by_rid(self.trigger_region.target_rid)
    if target_region then
      if playpos >= target_region.start and playpos < target_region["end"] then
        reaper.ShowConsoleMsg(string.format("[QUANTIZE] Entered target region rid=%d, cleanup\n", 
          self.trigger_region.target_rid))
        self:_cleanup_trigger()
        return
      end
    end
  end
  
  -- Check if we crossed the trigger position
  if playpos >= self.trigger_region.fire_position and playpos < self.trigger_region.fire_position + 0.1 then
    reaper.ShowConsoleMsg(string.format("[QUANTIZE] FIRING NOW: playpos=%.3f fire_pos=%.3f\n",
      playpos, self.trigger_region.fire_position))
    
    if self.trigger_region.target_rid then
      self.transport:_seek_to_region(self.trigger_region.target_rid)
    end
    
    self:_cleanup_trigger()
  elseif playpos >= self.trigger_region.fire_position + 0.1 then
    reaper.ShowConsoleMsg("[QUANTIZE] Missed trigger window, cleanup\n")
    self:_cleanup_trigger()
  end
end

function Quantize:_cleanup_trigger()
  if self.trigger_region.marker_idx then
    self:_reposition_trigger_region(
      self.trigger_region.idle_position,
      self.trigger_region.idle_position + 1
    )
  end
  
  self.trigger_region.is_active = false
  self.trigger_region.target_rid = nil
  self.trigger_region.fire_position = nil
  self.trigger_region.last_playpos = nil
end

M.Quantize = Quantize
return M