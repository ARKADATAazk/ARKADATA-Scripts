-- ReArkitekt/gui/fx/marching_ants.lua
-- Animated marching ants selection border (rounded rectangle with animated dashes)

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local M = {}

function M.draw(dl, x1, y1, x2, y2, color, thickness, radius, dash, gap, speed_px)
  if x2 <= x1 or y2 <= y1 then return end
  
  thickness = thickness or 1
  radius = radius or 6
  dash = dash or 8
  gap = gap or 6
  speed_px = speed_px or 20
  
  local w, h = x2 - x1, y2 - y1
  local r = math.max(0, math.min(radius, math.floor(math.min(w, h) * 0.5)))
  
  local straight_w = math.max(0, w - 2*r)
  local straight_h = math.max(0, h - 2*r)
  local arc_len = (math.pi * r) / 2
  
  local L1 = straight_w
  local L2 = arc_len
  local L3 = straight_h
  local L4 = arc_len
  local L5 = straight_w
  local L6 = arc_len
  local L7 = straight_h
  local L8 = arc_len
  local L = L1 + L2 + L3 + L4 + L5 + L6 + L7 + L8
  
  if L <= 0 then return end
  
  local function draw_line_subseg(ax, ay, bx, by, u0, u1)
    local seg_len = math.max(1e-6, math.sqrt((bx-ax)^2 + (by-ay)^2))
    local t0, t1 = u0/seg_len, u1/seg_len
    local sx = ax + (bx-ax)*t0
    local sy = ay + (by-ay)*t0
    local ex = ax + (bx-ax)*t1
    local ey = ay + (by-ay)*t1
    ImGui.DrawList_AddLine(dl, sx, sy, ex, ey, color, thickness)
  end
  
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
  
  local function draw_subpath(s, e)
    if e <= s then return end
    local pos = 0
    
    if e > pos and s < pos + straight_w and straight_w > 0 then
      local u0 = math.max(0, s - pos)
      local u1 = math.min(straight_w, e - pos)
      draw_line_subseg(x1+r, y1, x2-r, y1, u0, u1)
    end
    pos = pos + straight_w
    
    if e > pos and s < pos + arc_len and arc_len > 0 then
      local u0 = math.max(0, s - pos)
      local u1 = math.min(arc_len, e - pos)
      draw_arc_subseg(x2 - r, y1 + r, r, -math.pi/2, 0, u0, u1)
    end
    pos = pos + arc_len
    
    if e > pos and s < pos + straight_h and straight_h > 0 then
      local u0 = math.max(0, s - pos)
      local u1 = math.min(straight_h, e - pos)
      draw_line_subseg(x2, y1+r, x2, y2-r, u0, u1)
    end
    pos = pos + straight_h
    
    if e > pos and s < pos + arc_len and arc_len > 0 then
      local u0 = math.max(0, s - pos)
      local u1 = math.min(arc_len, e - pos)
      draw_arc_subseg(x2 - r, y2 - r, r, 0, math.pi/2, u0, u1)
    end
    pos = pos + arc_len
    
    if e > pos and s < pos + straight_w and straight_w > 0 then
      local u0 = math.max(0, s - pos)
      local u1 = math.min(straight_w, e - pos)
      draw_line_subseg(x2-r, y2, x1+r, y2, u0, u1)
    end
    pos = pos + straight_w
    
    if e > pos and s < pos + arc_len and arc_len > 0 then
      local u0 = math.max(0, s - pos)
      local u1 = math.min(arc_len, e - pos)
      draw_arc_subseg(x1 + r, y2 - r, r, math.pi/2, math.pi, u0, u1)
    end
    pos = pos + arc_len
    
    if e > pos and s < pos + straight_h and straight_h > 0 then
      local u0 = math.max(0, s - pos)
      local u1 = math.min(straight_h, e - pos)
      draw_line_subseg(x1, y2-r, x1, y1+r, u0, u1)
    end
    pos = pos + straight_h
    
    if e > pos and s < pos + arc_len and arc_len > 0 then
      local u0 = math.max(0, s - pos)
      local u1 = math.min(arc_len, e - pos)
      draw_arc_subseg(x1 + r, y1 + r, r, math.pi, 3*math.pi/2, u0, u1)
    end
  end
  
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

return M