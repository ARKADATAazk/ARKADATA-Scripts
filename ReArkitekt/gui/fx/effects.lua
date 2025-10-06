-- ReArkitekt/gui/fx/effects.lua
-- Simple inline visual effects (hover shadows, glows, etc.)
-- For advanced multi-layer tile rendering, see ReArkitekt/gui/fx/tile_fx.lua

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.10'

local M = {}

-- Hover Shadow (simple inline effect for basic widgets)
-- NOTE: For tile rendering, use TileFX.render_tile_complete() instead
function M.hover_shadow(dl, x1, y1, x2, y2, strength, radius)
  strength = math.max(0, math.min(1, strength or 1))
  radius = radius or 6
  
  if strength < 0.01 then return end
  
  local alpha = math.floor(strength * 20)
  local shadow_col = (0x000000 << 8) | alpha
  
  for i = 2, 1, -1 do
    ImGui.DrawList_AddRectFilled(dl, x1 - i, y1 - i + 2, x2 + i, y2 + i + 2, shadow_col, radius)
  end
end

-- Soft Glow Effect (outward radial glow)
function M.soft_glow(dl, x1, y1, x2, y2, color, intensity, radius)
  intensity = intensity or 0.5
  radius = radius or 6
  
  if intensity < 0.01 then return end
  
  local r = (color >> 24) & 0xFF
  local g = (color >> 16) & 0xFF
  local b = (color >> 8) & 0xFF
  
  for i = 4, 1, -1 do
    local alpha = math.floor(intensity * 30 / i)
    local glow_col = (r << 24) | (g << 16) | (b << 8) | alpha
    ImGui.DrawList_AddRect(dl, x1 - i, y1 - i, x2 + i, y2 + i, glow_col, radius, 0, 1.0)
  end
end

-- Pulse Glow (animated pulsing effect)
function M.pulse_glow(dl, x1, y1, x2, y2, color, time, speed, radius)
  speed = speed or 3.0
  radius = radius or 6
  
  local pulse = (math.sin(time * speed) * 0.5 + 0.5) * 0.6 + 0.4
  M.soft_glow(dl, x1, y1, x2, y2, color, pulse, radius)
end

return M