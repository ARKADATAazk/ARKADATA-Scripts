-- ReArkitekt/gui/effects.lua
-- Simple inline visual effects (hover shadows, glows, etc.)
-- Complex effects live in fx/ folder and should be imported directly

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local M = {}

-- Hover Shadow (simple inline effect)
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

return M