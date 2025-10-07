-- ReArkitekt/features/region_playlist/playback.lua
-- Runtime playback loop - integrates with ReArkitekt runtime

local M = {}
local Playback = {}
Playback.__index = Playback

function M.new(engine, opts)
  opts = opts or {}
  local self = setmetatable({}, Playback)
  
  self.engine = engine
  self.enabled = true
  self.callbacks = {
    on_region_change = opts.on_region_change,
    on_playback_start = opts.on_playback_start,
    on_playback_stop = opts.on_playback_stop,
    on_transition_scheduled = opts.on_transition_scheduled,
  }
  
  self.prev_rid = nil
  self.prev_playing = false
  
  return self
end

function Playback:set_enabled(enabled)
  self.enabled = enabled
end

function Playback:update()
  if not self.enabled then return end
  
  self.engine:update()
  
  local state = self.engine:get_state()
  local current_rid = self.engine:get_current_rid()
  
  if current_rid ~= self.prev_rid then
    if self.callbacks.on_region_change then
      local region = self.engine:get_region_by_rid(current_rid)
      self.callbacks.on_region_change(current_rid, region, state.playlist_pointer)
    end
    self.prev_rid = current_rid
  end
  
  if state.is_playing ~= self.prev_playing then
    if state.is_playing and self.callbacks.on_playback_start then
      self.callbacks.on_playback_start(current_rid)
    elseif not state.is_playing and self.callbacks.on_playback_stop then
      self.callbacks.on_playback_stop()
    end
    self.prev_playing = state.is_playing
  end
  
  if state.scheduled_jump and self.callbacks.on_transition_scheduled then
    local region = self.engine:get_region_by_rid(current_rid)
    if region then
      self.callbacks.on_transition_scheduled(current_rid, region["end"], state.scheduled_jump)
    end
  end
end

function Playback:get_progress()
  if not self.engine.is_playing then
    return nil
  end
  
  local rid = self.engine:get_current_rid()
  if not rid then return nil end
  
  local region = self.engine:get_region_by_rid(rid)
  if not region then return nil end
  
  local Transport = require('ReArkitekt.reaper.transport')
  local playpos = Transport.get_play_position(self.engine.proj)
  
  local duration = region["end"] - region.start
  if duration <= 0 then return 0 end
  
  local elapsed = playpos - region.start
  return math.max(0, math.min(1, elapsed / duration))
end

function Playback:get_time_remaining()
  if not self.engine.is_playing then
    return nil
  end
  
  local rid = self.engine:get_current_rid()
  if not rid then return nil end
  
  local region = self.engine:get_region_by_rid(rid)
  if not region then return nil end
  
  local Transport = require('ReArkitekt.reaper.transport')
  local playpos = Transport.get_play_position(self.engine.proj)
  
  return math.max(0, region["end"] - playpos)
end

return M