-- ReArkitekt/core/math.lua
-- Math utility functions

local M = {}

function M.lerp(a, b, t)
  return a + (b - a) * math.min(1.0, t)
end

function M.clamp(value, min, max)
  return math.max(min, math.min(max, value))
end

function M.remap(value, in_min, in_max, out_min, out_max)
  return out_min + (value - in_min) * (out_max - out_min) / (in_max - in_min)
end

function M.snap(value, step)
  return math.floor(value / step + 0.5) * step
end

function M.smoothdamp(current, target, velocity, smoothtime, maxspeed, dt)
  smoothtime = math.max(0.0001, smoothtime)
  local omega = 2.0 / smoothtime
  local x = omega * dt
  local exp = 1.0 / (1.0 + x + 0.48 * x * x + 0.235 * x * x * x)
  local change = current - target
  local original_to = target
  
  local maxChange = maxspeed * smoothtime
  change = M.clamp(change, -maxChange, maxChange)
  target = current - change
  
  local temp = (velocity + omega * change) * dt
  velocity = (velocity - omega * temp) * exp
  local output = target + (change + temp) * exp
  
  if (original_to - current > 0.0) == (output > original_to) then
    output = original_to
    velocity = (output - original_to) / dt
  end
  
  return output, velocity
end

function M.approximately(a, b, epsilon)
  epsilon = epsilon or 0.0001
  return math.abs(a - b) < epsilon
end

return M