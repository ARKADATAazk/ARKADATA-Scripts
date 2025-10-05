-- ReArkitekt/gui/draw.lua
-- Drawing primitives and helpers
-- Crisp pixel-aligned rendering utilities

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local M = {}

-- Snap to pixel boundary for crisp rendering
function M.snap(x)
  return math.floor(x + 0.5)
end

-- Draw centered text within a rectangle
function M.centered_text(ctx, text, x1, y1, x2, y2, color)
  local dl = ImGui.GetWindowDrawList(ctx)
  local tw, th = ImGui.CalcTextSize(ctx, text)
  local cx = x1 + math.floor((x2 - x1 - tw) * 0.5)
  local cy = y1 + math.floor((y2 - y1 - th) * 0.5)
  ImGui.DrawList_AddText(dl, cx, cy, color or 0xFFFFFFFF, text)
end

-- Draw a crisp rectangle (pixel-aligned)
function M.rect(dl, x1, y1, x2, y2, color, rounding, thickness)
  x1 = M.snap(x1)
  y1 = M.snap(y1) 
  x2 = M.snap(x2)
  y2 = M.snap(y2)
  thickness = thickness or 1
  rounding = rounding or 0
  
  -- Offset by 0.5 for crisp 1px lines
  if thickness == 1 then
    ImGui.DrawList_AddRect(dl, x1 + 0.5, y1 + 0.5, x2 - 0.5, y2 - 0.5, 
                                  color, rounding, 0, thickness)
  else
    ImGui.DrawList_AddRect(dl, x1, y1, x2, y2, color, rounding, 0, thickness)
  end
end

-- Draw a filled rectangle (pixel-aligned)
function M.rect_filled(dl, x1, y1, x2, y2, color, rounding)
  x1 = M.snap(x1)
  y1 = M.snap(y1)
  x2 = M.snap(x2)
  y2 = M.snap(y2)
  ImGui.DrawList_AddRectFilled(dl, x1, y1, x2, y2, color, rounding or 0)
end

-- Draw a crisp line (pixel-aligned)
function M.line(dl, x1, y1, x2, y2, color, thickness)
  x1 = M.snap(x1)
  y1 = M.snap(y1)
  x2 = M.snap(x2)
  y2 = M.snap(y2)
  thickness = thickness or 1
  ImGui.DrawList_AddLine(dl, x1, y1, x2, y2, color, thickness)
end

-- Draw left-aligned text
function M.text(dl, x, y, color, text)
  ImGui.DrawList_AddText(dl, M.snap(x), M.snap(y), color, text or "")
end

-- Draw right-aligned text
function M.text_right(ctx, x, y, color, text)
  local dl = ImGui.GetWindowDrawList(ctx)
  local tw = select(1, ImGui.CalcTextSize(ctx, text))
  ImGui.DrawList_AddText(dl, M.snap(x - tw), M.snap(y), color, text or "")
end

-- Check if point is in rectangle
function M.point_in_rect(x, y, x1, y1, x2, y2)
  return x >= math.min(x1, x2) and x <= math.max(x1, x2)
     and y >= math.min(y1, y2) and y <= math.max(y1, y2)
end

-- Check if rectangles intersect
function M.rects_intersect(ax1, ay1, ax2, ay2, bx1, by1, bx2, by2)
  local a_left = math.min(ax1, ax2)
  local a_right = math.max(ax1, ax2)
  local a_top = math.min(ay1, ay2)
  local a_bottom = math.max(ay1, ay2)
  
  local b_left = math.min(bx1, bx2)
  local b_right = math.max(bx1, bx2)
  local b_top = math.min(by1, by2)
  local b_bottom = math.max(by1, by2)
  
  return not (a_left > b_right or a_right < b_left or 
              a_top > b_bottom or a_bottom < b_top)
end

-- Create a clipped text helper (for tab labels etc)
function M.text_clipped(ctx, text, x, y, max_width, color)
  local dl = ImGui.GetWindowDrawList(ctx)
  local tw, th = ImGui.CalcTextSize(ctx, text)
  
  if tw <= max_width then
    -- Text fits, no clipping needed
    ImGui.DrawList_AddText(dl, M.snap(x), M.snap(y), color, text)
  else
    -- Clip text
    local clip_x1 = M.snap(x)
    local clip_x2 = M.snap(x + max_width)
    ImGui.DrawList_PushClipRect(dl, clip_x1, y - 2, clip_x2, y + th + 2, true)
    ImGui.DrawList_AddText(dl, M.snap(x), M.snap(y), color, text)
    ImGui.DrawList_PopClipRect(dl)
  end
end

return M