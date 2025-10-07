-- ReArkitekt/gui/widgets/tiles_container/background.lua
-- Background pattern rendering

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local M = {}

local function draw_grid_pattern(dl, x1, y1, x2, y2, spacing, color, thickness)
  local start_x = x1 + (spacing - (x1 % spacing))
  local start_y = y1 + (spacing - (y1 % spacing))
  
  for x = start_x, x2, spacing do
    ImGui.DrawList_AddLine(dl, x, y1, x, y2, color, thickness)
  end
  
  for y = start_y, y2, spacing do
    ImGui.DrawList_AddLine(dl, x1, y, x2, y, color, thickness)
  end
end

local function draw_dot_pattern(dl, x1, y1, x2, y2, spacing, color, dot_size)
  local half_size = dot_size * 0.5
  local start_x = x1 + (spacing - (x1 % spacing))
  local start_y = y1 + (spacing - (y1 % spacing))
  
  for x = start_x, x2, spacing do
    for y = start_y, y2, spacing do
      ImGui.DrawList_AddCircleFilled(dl, x, y, half_size, color)
    end
  end
end

function M.draw(dl, x1, y1, x2, y2, pattern_cfg)
  if not pattern_cfg or not pattern_cfg.enabled then return end
  
  ImGui.DrawList_PushClipRect(dl, x1, y1, x2, y2, true)
  
  if pattern_cfg.secondary and pattern_cfg.secondary.enabled then
    local sec = pattern_cfg.secondary
    if sec.type == 'grid' then
      draw_grid_pattern(dl, x1, y1, x2, y2, sec.spacing, sec.color, sec.line_thickness)
    elseif sec.type == 'dots' then
      draw_dot_pattern(dl, x1, y1, x2, y2, sec.spacing, sec.color, sec.dot_size)
    end
  end
  
  if pattern_cfg.primary then
    local pri = pattern_cfg.primary
    if pri.type == 'grid' then
      draw_grid_pattern(dl, x1, y1, x2, y2, pri.spacing, pri.color, pri.line_thickness)
    elseif pri.type == 'dots' then
      draw_dot_pattern(dl, x1, y1, x2, y2, pri.spacing, pri.color, pri.dot_size)
    end
  end
  
  ImGui.DrawList_PopClipRect(dl)
end

return M