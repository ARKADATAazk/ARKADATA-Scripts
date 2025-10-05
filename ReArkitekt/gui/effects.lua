-- ReArkitekt/gui/effects.lua
-- Visual effects: marching ants, drop shadows, hover effects, etc.

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local M = {}

-- Draw marching ants selection (rounded rectangle, animated dashes)
-- dl: draw list
-- x1, y1, x2, y2: rectangle bounds
-- color: ant color
-- thickness: line thickness
-- radius: corner radius
-- dash: dash length
-- gap: gap length
-- speed_px: pixels per second animation speed
function M.marching_ants_rounded(dl, x1, y1, x2, y2, color, thickness, radius, dash, gap, speed_px)
  if x2 <= x1 or y2 <= y1 then return end
  
  thickness = thickness or 1
  radius = radius or 6
  dash = dash or 8
  gap = gap or 6
  speed_px = speed_px or 20
  
  local w, h = x2 - x1, y2 - y1
  local r = math.max(0, math.min(radius, math.floor(math.min(w, h) * 0.5)))
  
  -- Calculate perimeter segments
  local straight_w = math.max(0, w - 2*r)
  local straight_h = math.max(0, h - 2*r)
  local arc_len = (math.pi * r) / 2
  
  -- Total perimeter
  local L1 = straight_w  -- top
  local L2 = arc_len     -- top-right arc
  local L3 = straight_h  -- right
  local L4 = arc_len     -- bottom-right arc
  local L5 = straight_w  -- bottom
  local L6 = arc_len     -- bottom-left arc
  local L7 = straight_h  -- left
  local L8 = arc_len     -- top-left arc
  local L = L1 + L2 + L3 + L4 + L5 + L6 + L7 + L8
  
  if L <= 0 then return end
  
  -- Helper to draw line segment
  local function draw_line_subseg(ax, ay, bx, by, u0, u1)
    local seg_len = math.max(1e-6, math.sqrt((bx-ax)^2 + (by-ay)^2))
    local t0, t1 = u0/seg_len, u1/seg_len
    local sx = ax + (bx-ax)*t0
    local sy = ay + (by-ay)*t0
    local ex = ax + (bx-ax)*t1
    local ey = ay + (by-ay)*t1
    ImGui.DrawList_AddLine(dl, sx, sy, ex, ey, color, thickness)
  end
  
  -- Helper to draw arc segment
  local function draw_arc_subseg(cx, cy, rr, a0, a1, u0, u1)
    local seg_len = math.max(1e-6, rr * math.abs(a1 - a0))
    local aa0 = a0 + (a1 - a0) * (u0 / seg_len)
    local aa1 = a0 + (a1 - a0) * (u1 / seg_len)
    local steps = math.max(1, math.floor((rr * math.abs(aa1 - aa0)) / 3))
    local prevx = cx + rr * math.cos(aa0)
    local prevy = cy + rr * math.sin(aa0)
    for i = 1, steps do
      local t = i / steps
      local ang = aa0 + (aa1 - aa0) * t
      local nx = cx + rr * math.cos(ang)
      local ny = cy + rr * math.sin(ang)
      ImGui.DrawList_AddLine(dl, prevx, prevy, nx, ny, color, thickness)
      prevx, prevy = nx, ny
    end
  end
  
  -- Draw subpath along perimeter
  local function draw_subpath(s, e)
    if e <= s then return end
    local pos = 0
    
    -- Top edge
    if e > pos and s < pos + straight_w and straight_w > 0 then
      local u0 = math.max(0, s - pos)
      local u1 = math.min(straight_w, e - pos)
      draw_line_subseg(x1+r, y1, x2-r, y1, u0, u1)
    end
    pos = pos + straight_w
    
    -- Top-right arc
    if e > pos and s < pos + arc_len and arc_len > 0 then
      local u0 = math.max(0, s - pos)
      local u1 = math.min(arc_len, e - pos)
      draw_arc_subseg(x2 - r, y1 + r, r, -math.pi/2, 0, u0, u1)
    end
    pos = pos + arc_len
    
    -- Right edge
    if e > pos and s < pos + straight_h and straight_h > 0 then
      local u0 = math.max(0, s - pos)
      local u1 = math.min(straight_h, e - pos)
      draw_line_subseg(x2, y1+r, x2, y2-r, u0, u1)
    end
    pos = pos + straight_h
    
    -- Bottom-right arc
    if e > pos and s < pos + arc_len and arc_len > 0 then
      local u0 = math.max(0, s - pos)
      local u1 = math.min(arc_len, e - pos)
      draw_arc_subseg(x2 - r, y2 - r, r, 0, math.pi/2, u0, u1)
    end
    pos = pos + arc_len
    
    -- Bottom edge
    if e > pos and s < pos + straight_w and straight_w > 0 then
      local u0 = math.max(0, s - pos)
      local u1 = math.min(straight_w, e - pos)
      draw_line_subseg(x2-r, y2, x1+r, y2, u0, u1)
    end
    pos = pos + straight_w
    
    -- Bottom-left arc
    if e > pos and s < pos + arc_len and arc_len > 0 then
      local u0 = math.max(0, s - pos)
      local u1 = math.min(arc_len, e - pos)
      draw_arc_subseg(x1 + r, y2 - r, r, math.pi/2, math.pi, u0, u1)
    end
    pos = pos + arc_len
    
    -- Left edge
    if e > pos and s < pos + straight_h and straight_h > 0 then
      local u0 = math.max(0, s - pos)
      local u1 = math.min(straight_h, e - pos)
      draw_line_subseg(x1, y2-r, x1, y1+r, u0, u1)
    end
    pos = pos + straight_h
    
    -- Top-left arc
    if e > pos and s < pos + arc_len and arc_len > 0 then
      local u0 = math.max(0, s - pos)
      local u1 = math.min(arc_len, e - pos)
      draw_arc_subseg(x1 + r, y1 + r, r, math.pi, 3*math.pi/2, u0, u1)
    end
  end
  
  -- Animate dashes
  local dash_len = math.max(2, dash)
  local gap_len = math.max(2, gap)
  local period = dash_len + gap_len
  local phase_px = (reaper.time_precise() * speed_px) % period
  
  local s = -phase_px
  while s < L do
    local e = s + dash_len
    local cs = math.max(0, s)
    local ce = math.min(L, e)
    if ce > cs then
      draw_subpath(cs, ce)
    end
    s = s + period
  end
end

-- Draw drop shadow for hover effects
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

-- Draw drop line indicator for drag & drop
function M.drop_line(dl, x, y1, y2, color, thickness, cap_radius)
  color = color or 0x42E896E0
  thickness = thickness or 4
  cap_radius = cap_radius or 8
  
  -- Main line
  ImGui.DrawList_AddLine(dl, x, y1, x, y2, color, thickness)
  
  -- End caps
  ImGui.DrawList_AddRectFilled(dl, x - thickness/2, y1 - 4, x + thickness/2, y1, color, cap_radius)
  ImGui.DrawList_AddRectFilled(dl, x - thickness/2, y2, x + thickness/2, y2 + 4, color, cap_radius)
end

-- Draw selection overlay (filled rect with border)
function M.selection_overlay(dl, x1, y1, x2, y2, fill_color, stroke_color, rounding, stroke_width)
  fill_color = fill_color or 0xFFFFFF22
  stroke_color = stroke_color or 0xFFFFFFFF
  rounding = rounding or 6
  stroke_width = stroke_width or 1
  
  ImGui.DrawList_AddRectFilled(dl, 
    math.min(x1, x2), math.min(y1, y2),
    math.max(x1, x2), math.max(y1, y2), 
    fill_color, rounding)
    
  ImGui.DrawList_AddRect(dl,
    math.min(x1, x2), math.min(y1, y2),
    math.max(x1, x2), math.max(y1, y2),
    stroke_color, rounding, 0, stroke_width)
end

-- Draw ghost preview (for dragging)
function M.ghost_rect(dl, x1, y1, x2, y2, fill_color, stroke_color, rounding, stroke_width)
  fill_color = fill_color or 0xFFFFFF22
  stroke_color = stroke_color or 0xFFFFFFFF
  rounding = rounding or 8
  stroke_width = stroke_width or 2
  
  ImGui.DrawList_AddRectFilled(dl, x1, y1, x2, y2, fill_color, rounding)
  ImGui.DrawList_AddRect(dl, x1+0.5, y1+0.5, x2-0.5, y2-0.5, stroke_color, rounding, 0, stroke_width)
end

-- Draw dim overlay (for original positions during drag)
function M.dim_rect(dl, x1, y1, x2, y2, fill_color, stroke_color, rounding, stroke_width)
  fill_color = fill_color or 0x00000088
  stroke_color = stroke_color or 0xFFFFFF55
  rounding = rounding or 6
  stroke_width = stroke_width or 2
  
  ImGui.DrawList_AddRectFilled(dl, x1, y1, x2, y2, fill_color, rounding)
  ImGui.DrawList_AddRect(dl, x1+0.5, y1+0.5, x2-0.5, y2-0.5, stroke_color, rounding, 0, stroke_width)
end

return M