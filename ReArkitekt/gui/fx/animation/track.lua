-- ReArkitekt/gui/fx/animation/track.lua
-- Single-value animation track with smooth interpolation
-- Usage:
--   local track = Track.new(0, 14.0)  -- initial value, speed
--   track:to(100)                     -- set target
--   track:update(dt)                  -- update in frame loop
--   local val = track:get()           -- get current value

local Math = require('ReArkitekt.core.math')

local M = {}

local Track = {}
Track.__index = Track

function M.new(initial_value, speed)
  return setmetatable({
    current = initial_value or 0,
    target = initial_value or 0,
    speed = speed or 14.0,
  }, Track)
end

function Track:to(target)
  self.target = target
end

function Track:update(dt)
  dt = dt or 0.016
  self.current = Math.lerp(self.current, self.target, self.speed * dt)
  return self.current
end

function Track:get()
  return self.current
end

function Track:teleport(value)
  self.current = value
  self.target = value
end

function Track:is_animating(epsilon)
  epsilon = epsilon or 0.01
  return math.abs(self.current - self.target) > epsilon
end

function Track:set_speed(speed)
  self.speed = speed
end

return M