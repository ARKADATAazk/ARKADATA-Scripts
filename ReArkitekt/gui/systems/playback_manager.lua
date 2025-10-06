-- ReArkitekt/gui/systems/playback_manager.lua
-- Manages playback state and progress for region tiles

local M = {}

local PlaybackManager = {}
PlaybackManager.__index = PlaybackManager

function M.new(config)
  config = config or {}
  
  return setmetatable({
    playing_key = nil,
    play_start_time = nil,
    duration = config.default_duration or 15.0,
    fade_in_duration = config.fade_in_duration or 0.2,
    fade_out_duration = config.fade_out_duration or 0.5,
    on_play_start = config.on_play_start,
    on_play_stop = config.on_play_stop,
    on_play_complete = config.on_play_complete,
    get_duration = config.get_duration,
  }, PlaybackManager)
end

function PlaybackManager:is_playing(key)
  return self.playing_key == key
end

function PlaybackManager:get_progress(key)
  if self.playing_key ~= key or not self.play_start_time then
    return 0
  end
  
  local elapsed = reaper.time_precise() - self.play_start_time
  local progress = math.min(1.0, elapsed / self.duration)
  
  if progress >= 1.0 then
    self:stop()
    if self.on_play_complete then
      self.on_play_complete(key)
    end
  end
  
  return progress
end

function PlaybackManager:get_fade_alpha(key)
  if self.playing_key ~= key or not self.play_start_time then
    return 0
  end
  
  local elapsed = reaper.time_precise() - self.play_start_time
  local progress = math.min(1.0, elapsed / self.duration)
  
  local fade_in_t = math.min(1.0, elapsed / self.fade_in_duration)
  
  local time_remaining = self.duration - elapsed
  local fade_out_t = 1.0
  if time_remaining < self.fade_out_duration then
    fade_out_t = time_remaining / self.fade_out_duration
  end
  
  return math.min(fade_in_t, fade_out_t)
end

function PlaybackManager:play(key, duration)
  if self.playing_key then
    self:stop()
  end
  
  if not duration and self.get_duration then
    duration = self.get_duration(key)
  end
  
  self.playing_key = key
  self.play_start_time = reaper.time_precise()
  self.duration = duration or self.duration
  
  if self.on_play_start then
    self.on_play_start(key)
  end
end

function PlaybackManager:stop()
  if not self.playing_key then return end
  
  local stopped_key = self.playing_key
  self.playing_key = nil
  self.play_start_time = nil
  
  if self.on_play_stop then
    self.on_play_stop(stopped_key)
  end
end

function PlaybackManager:toggle(key, duration)
  if self.playing_key == key then
    self:stop()
  else
    self:play(key, duration)
  end
end

function PlaybackManager:clear()
  self.playing_key = nil
  self.play_start_time = nil
end

return M