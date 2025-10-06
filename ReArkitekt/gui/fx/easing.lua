-- ReArkitekt/gui/fx/easing.lua
-- Easing functions for animations
-- All functions take t in [0,1] and return eased value in [0,1]

local M = {}

function M.linear(t)
  return t
end

function M.ease_in_quad(t)
  return t * t
end

function M.ease_out_quad(t)
  return 1 - (1 - t) * (1 - t)
end

function M.ease_in_out_quad(t)
  if t < 0.5 then
    return 2 * t * t
  else
    return 1 - (-2 * t + 2) * (-2 * t + 2) / 2
  end
end

function M.ease_in_cubic(t)
  return t * t * t
end

function M.ease_out_cubic(t)
  return 1 - (1 - t) * (1 - t) * (1 - t)
end

function M.ease_in_out_cubic(t)
  if t < 0.5 then
    return 4 * t * t * t
  else
    return 1 - (-2 * t + 2) * (-2 * t + 2) * (-2 * t + 2) / 2
  end
end

function M.ease_in_sine(t)
  return 1 - math.cos((t * math.pi) / 2)
end

function M.ease_out_sine(t)
  return math.sin((t * math.pi) / 2)
end

function M.ease_in_out_sine(t)
  return -(math.cos(math.pi * t) - 1) / 2
end

function M.smoothstep(t)
  return t * t * (3.0 - 2.0 * t)
end

function M.smootherstep(t)
  return t * t * t * (t * (t * 6 - 15) + 10)
end

function M.ease_in_expo(t)
  return t == 0 and 0 or 2 ^ (10 * t - 10)
end

function M.ease_out_expo(t)
  return t == 1 and 1 or 1 - 2 ^ (-10 * t)
end

function M.ease_in_out_expo(t)
  if t == 0 then return 0 end
  if t == 1 then return 1 end
  if t < 0.5 then
    return 2 ^ (20 * t - 10) / 2
  else
    return (2 - 2 ^ (-20 * t + 10)) / 2
  end
end

function M.ease_in_back(t)
  local c1 = 1.70158
  local c3 = c1 + 1
  return c3 * t * t * t - c1 * t * t
end

function M.ease_out_back(t)
  local c1 = 1.70158
  local c3 = c1 + 1
  return 1 + c3 * (t - 1) ^ 3 + c1 * (t - 1) ^ 2
end

return M