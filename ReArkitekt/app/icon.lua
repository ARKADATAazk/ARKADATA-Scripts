-- ReArkitekt/app/icon.lua
-- App icon drawing functions (DPI-aware vector graphics)

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local M = {}

-- ReArkitekt logo v1: Original (smaller circles, simpler)
function M.draw_rearkitekt(ctx, x, y, size, color)
  local draw_list = ImGui.GetWindowDrawList(ctx)
  local dpi = ImGui.GetWindowDpiScale(ctx)
  
  -- Scale dimensions
  local s = size * dpi
  local half_s = s * 0.5
  local cx, cy = x + half_s, y + half_s
  
  -- Circle radius
  local r = s * 0.12
  
  -- Define positions (normalized to icon size)
  local top_x, top_y = cx, cy - s * 0.35
  local left_bot_x, left_bot_y = cx - s * 0.35, cy + s * 0.35
  local right_bot_x, right_bot_y = cx + s * 0.35, cy + s * 0.35
  local left_mid_x, left_mid_y = cx - s * 0.45, cy - s * 0.05
  local right_mid_x, right_mid_y = cx + s * 0.45, cy - s * 0.05
  
  -- Draw connecting lines (triangle "A")
  local thickness = math.max(1.5 * dpi, 1.0)
  ImGui.DrawList_AddLine(draw_list, top_x, top_y, left_bot_x, left_bot_y, color, thickness)
  ImGui.DrawList_AddLine(draw_list, top_x, top_y, right_bot_x, right_bot_y, color, thickness)
  ImGui.DrawList_AddLine(draw_list, left_bot_x, left_bot_y, right_bot_x, right_bot_y, color, thickness)
  
  -- Draw circles at vertices and sides (audio node controls)
  ImGui.DrawList_AddCircleFilled(draw_list, top_x, top_y, r, color)
  ImGui.DrawList_AddCircleFilled(draw_list, left_bot_x, left_bot_y, r, color)
  ImGui.DrawList_AddCircleFilled(draw_list, right_bot_x, right_bot_y, r, color)
  ImGui.DrawList_AddCircleFilled(draw_list, left_mid_x, left_mid_y, r * 0.7, color)
  ImGui.DrawList_AddCircleFilled(draw_list, right_mid_x, right_mid_y, r * 0.7, color)
end

-- ReArkitekt logo v2: Refined (larger bulbs, fader-style side controls)
function M.draw_rearkitekt_v2(ctx, x, y, size, color)
  local draw_list = ImGui.GetWindowDrawList(ctx)
  local dpi = ImGui.GetWindowDpiScale(ctx)
  
  local s = size * dpi
  local cx, cy = x + s * 0.5, y + s * 0.5
  
  -- Circle sizes
  local r_vertex = s * 0.20   -- Triangle vertex circles
  local r_side = s * 0.18     -- Side fader circles
  
  -- Triangle vertices (tighter triangle)
  local top_x, top_y = cx, cy - s * 0.28
  local left_bot_x, left_bot_y = cx - s * 0.28, cy + s * 0.32
  local right_bot_x, right_bot_y = cx + s * 0.28, cy + s * 0.32
  
  -- Draw thick triangle lines
  local thickness = math.max(3.0 * dpi, 2.5)
  ImGui.DrawList_AddLine(draw_list, top_x, top_y, left_bot_x, left_bot_y, color, thickness)
  ImGui.DrawList_AddLine(draw_list, top_x, top_y, right_bot_x, right_bot_y, color, thickness)
  ImGui.DrawList_AddLine(draw_list, left_bot_x, left_bot_y, right_bot_x, right_bot_y, color, thickness)
  
  -- Main circles at triangle vertices
  ImGui.DrawList_AddCircleFilled(draw_list, top_x, top_y, r_vertex, color)
  ImGui.DrawList_AddCircleFilled(draw_list, left_bot_x, left_bot_y, r_vertex, color)
  ImGui.DrawList_AddCircleFilled(draw_list, right_bot_x, right_bot_y, r_vertex, color)
  
  -- Side fader controls (outside triangle)
  local side_offset = s * 0.50
  local left_fader_x, left_fader_y = cx - side_offset, cy + s * 0.02
  local right_fader_x, right_fader_y = cx + side_offset, cy + s * 0.02
  
  ImGui.DrawList_AddCircleFilled(draw_list, left_fader_x, left_fader_y, r_side, color)
  ImGui.DrawList_AddCircleFilled(draw_list, right_fader_x, right_fader_y, r_side, color)
  
  -- Small squares above side faders
  local sq_size = s * 0.10
  local sq_y = cy - s * 0.25
  ImGui.DrawList_AddRectFilled(draw_list, 
    left_fader_x - sq_size/2, sq_y - sq_size/2,
    left_fader_x + sq_size/2, sq_y + sq_size/2,
    color, sq_size * 0.15)
  ImGui.DrawList_AddRectFilled(draw_list, 
    right_fader_x - sq_size/2, sq_y - sq_size/2,
    right_fader_x + sq_size/2, sq_y + sq_size/2,
    color, sq_size * 0.15)
  
  -- Center horizontal bar (crossfader)
  local bar_w = s * 0.18
  local bar_h = s * 0.08
  local bar_y = cy + s * 0.02
  ImGui.DrawList_AddRectFilled(draw_list,
    cx - bar_w/2, bar_y - bar_h/2,
    cx + bar_w/2, bar_y + bar_h/2,
    color, bar_h * 0.2)
end

-- Alternative: Simple "A" monogram
function M.draw_simple_a(ctx, x, y, size, color)
  local draw_list = ImGui.GetWindowDrawList(ctx)
  local dpi = ImGui.GetWindowDpiScale(ctx)
  
  local s = size * dpi
  local cx, cy = x + s * 0.5, y + s * 0.5
  
  -- Triangle "A"
  local top_x, top_y = cx, cy - s * 0.4
  local left_x, left_y = cx - s * 0.35, cy + s * 0.4
  local right_x, right_y = cx + s * 0.35, cy + s * 0.4
  
  local thickness = math.max(2.0 * dpi, 1.5)
  ImGui.DrawList_AddLine(draw_list, top_x, top_y, left_x, left_y, color, thickness)
  ImGui.DrawList_AddLine(draw_list, top_x, top_y, right_x, right_y, color, thickness)
  
  -- Crossbar
  local bar_y = cy + s * 0.1
  ImGui.DrawList_AddLine(draw_list, cx - s * 0.25, bar_y, cx + s * 0.25, bar_y, color, thickness)
end

return M