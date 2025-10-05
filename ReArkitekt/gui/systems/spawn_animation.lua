-- ReArkitekt/gui/systems/spawn_animation.lua
-- Spawn animation that affects layout - tiles push each other as they expand

local M = {}

local function smoothstep(t)
  return t * t * (3.0 - 2.0 * t)
end

local function ease_out_sine(t)
  return math.sin((t * math.pi) / 2.0)
end

local SpawnTracker = {}
SpawnTracker.__index = SpawnTracker

function M.new(config)
  config = config or {}
  
  return setmetatable({
    spawning = {},
    duration = config.duration or 0.28,
  }, SpawnTracker)
end

function SpawnTracker:spawn(id, target_rect)
  self.spawning[id] = {
    start_time = reaper.time_precise(),
    target = {target_rect[1], target_rect[2], target_rect[3], target_rect[4]},
  }
end

function SpawnTracker:is_spawning(id)
  return self.spawning[id] ~= nil
end

function SpawnTracker:get_width_factor(id)
  local spawn = self.spawning[id]
  if not spawn then return 1.0 end
  
  local now = reaper.time_precise()
  local elapsed = now - spawn.start_time
  local t = math.min(1.0, elapsed / self.duration)
  
  t = smoothstep(t)
  
  if t >= 1.0 then
    self.spawning[id] = nil
    return 1.0
  end
  
  return t
end

function SpawnTracker:clear()
  self.spawning = {}
end

function SpawnTracker:remove(id)
  self.spawning[id] = nil
end

return M