-- ReArkitekt/gui/widgets/sliders/hue.lua
-- Enhanced color sliders with proper rounded gradients

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.10'

local palette
local Colors
do
  local ok, Style = pcall(require, "ReArkitekt.gui.style")
  if ok and type(Style) == "table" and type(Style.palette) == "table" then
    palette = Style.palette
  end
  
  local ok2, C = pcall(require, "ReArkitekt.core.colors")
  if ok2 and type(C) == "table" then
    Colors = C
  end
end

local M = {}
local _locks = {}

local function clamp(v, lo, hi)
  if v < lo then return lo elseif v > hi then return hi else return v end
end

local function hsv_rgba_u32(h, s, v, a)
  local i = math.floor(h * 6)
  local f = h * 6 - i
  local p = v * (1 - s)
  local q = v * (1 - f * s)
  local t = v * (1 - (1 - f) * s)
  local r, g, b
  i = i % 6
  if     i == 0 then r, g, b = v, t, p
  elseif i == 1 then r, g, b = q, v, p
  elseif i == 2 then r, g, b = p, v, t
  elseif i == 3 then r, g, b = p, q, v
  elseif i == 4 then r, g, b = t, p, v
  else               r, g, b = v, p, q
  end
  local R = math.floor(r * 255 + 0.5)
  local G = math.floor(g * 255 + 0.5)
  local B = math.floor(b * 255 + 0.5)
  local A = math.floor((a or 1) * 255 + 0.5)
  return (R << 24) | (G << 16) | (B << 8) | A
end

-- Render slider background (ROUNDED)
local function render_slider(dl, x0, y0, x1, y1, gradient_fn, opt)
  local rounding = 4.0
  local border_thickness = 1.0
  local inset = border_thickness
  
  -- Dark base
  ImGui.DrawList_AddRectFilled(dl, x0, y0, x1, y1, 0x1A1A1AFF, rounding)
  
  -- Gradient (drawn inset to not interfere with rounded corners)
  gradient_fn(dl, x0 + inset, y0 + inset, x1 - inset, y1 - inset, opt)
  
  -- Border
  ImGui.DrawList_AddRect(dl, x0, y0, x1, y1, 0x000000FF, rounding, 0, border_thickness)
end

-- Render grab handle (ROUNDED, DARKER)
local function render_grab(dl, gx, y0, y1, GRAB_W, active, hovered)
  local x_left = gx - GRAB_W / 2
  local x_right = gx + GRAB_W / 2
  local rounding = 3.0
  
  -- Shadow (rounded)
  ImGui.DrawList_AddRectFilled(dl, x_left + 1, y0 + 1, x_right + 1, y1 + 1, 
    0x00000050, rounding)
  
  -- Base (darker bluish-greys, rounded)
  local grab_col = active and 0x585C65FF or (hovered and 0x484C55FF or 0x383C45FF)
  ImGui.DrawList_AddRectFilled(dl, x_left, y0, x_right, y1, grab_col, rounding)
  
  -- Border (rounded)
  ImGui.DrawList_AddRect(dl, x_left, y0, x_right, y1, 0x000000FF, rounding, 0, 1.0)
end

-- Core slider
local function draw_slider_base(ctx, id, value, min_val, max_val, default_val, gradient_fn, tooltip_fn, opt)
  opt = opt or {}
  
  local W = opt.w or 200
  local H = opt.h or 20
  local GRAB_W = opt.grab_w or 13
  
  value = clamp(value or default_val, min_val, max_val)
  
  local x, y = ImGui.GetCursorScreenPos(ctx)
  ImGui.InvisibleButton(ctx, id, W, H)
  
  local hovered = ImGui.IsItemHovered(ctx)
  local active = ImGui.IsItemActive(ctx)
  local dl = ImGui.GetWindowDrawList(ctx)
  
  local x0, y0 = x, y
  local x1, y1 = x0 + W, y0 + H
  
  local now = ImGui.GetTime(ctx)
  local locked = (_locks[id] or 0) > now
  
  local changed = false
  local double_clicked = false -- Define a flag for the double-click event
  
  -- Double-click to reset
  if hovered and not locked and ImGui.IsMouseDoubleClicked(ctx, 0) then
    value = default_val
    changed = true
    double_clicked = true -- Set the flag to true
    _locks[id] = now + 0.3
  end
  
  -- Drag to adjust (now checks the double_clicked flag)
  if not double_clicked and not locked and active then
    local mx = select(1, ImGui.GetMousePos(ctx))
    local t = clamp((mx - x0) / W, 0, 1)
    local nv = min_val + t * (max_val - min_val)
    if math.abs(nv - value) > 1e-3 then
      value = nv
      changed = true
    end
  end
  
  -- Keyboard
  if ImGui.IsItemFocused(ctx) or active then
    local step = (max_val - min_val) / 100
    if ImGui.IsKeyPressed(ctx, ImGui.Key_LeftArrow, false) then
      value = value - step
      changed = true
    end
    if ImGui.IsKeyPressed(ctx, ImGui.Key_RightArrow, false) then
      value = value + step
      changed = true
    end
  end
  
  value = clamp(value, min_val, max_val)
  
  -- Render slider background
  render_slider(dl, x0, y0, x1, y1, gradient_fn, opt)
  
  -- Render grab
  local t = (value - min_val) / (max_val - min_val)
  local gx = clamp(x0 + t * W, x0 + GRAB_W / 2, x1 - GRAB_W / 2)
  render_grab(dl, gx, y0, y1, GRAB_W, active, hovered)
  
  -- Tooltip
  if hovered then
    if ImGui.BeginTooltip(ctx) then
      ImGui.Text(ctx, tooltip_fn(value))
      ImGui.EndTooltip(ctx)
    end
  end
  
  return changed, value
end

-- HUE SLIDER
function M.draw_hue(ctx, id, hue, opt)
  opt = opt or {}
  local SAT = clamp(opt.saturation or 75, 0, 100) / 100.0
  local VAL = clamp(opt.brightness or 80, 0, 100) / 100.0
  local SEG = 120
  
  local gradient_fn = function(dl, x0, y0, x1, y1, opt)
    local W = x1 - x0
    local segw = W / SEG
    for i = 0, SEG - 1 do
      local t0 = i / SEG
      local t1 = (i + 1) / SEG
      local c0 = hsv_rgba_u32(t0, SAT, VAL, 1)
      local c1 = hsv_rgba_u32(t1, SAT, VAL, 1)
      
      if Colors then
        c0 = Colors.desaturate(c0, 0.10)
        c1 = Colors.desaturate(c1, 0.10)
        c0 = Colors.adjust_brightness(c0, 0.88)
        c1 = Colors.adjust_brightness(c1, 0.88)
      end
      
      local sx0 = x0 + i * segw
      local sx1 = x0 + (i + 1) * segw
      ImGui.DrawList_AddRectFilledMultiColor(dl, sx0, y0, sx1, y1, c0, c1, c1, c0)
    end
  end
  
  local tooltip_fn = function(v)
    return string.format("Hue: %.1f°", v)
  end
  
  return draw_slider_base(ctx, id, hue, 0, 359.999, opt.default or 180.0, gradient_fn, tooltip_fn, opt)
end

-- SATURATION SLIDER
function M.draw_saturation(ctx, id, saturation, base_hue, opt)
  opt = opt or {}
  base_hue = base_hue or 210
  local VAL = clamp(opt.brightness or 80, 0, 100) / 100.0
  local SEG = 120
  
  local gradient_fn = function(dl, x0, y0, x1, y1, opt)
    local W = x1 - x0
    local h = (base_hue % 360) / 360.0
    local segw = W / SEG
    for i = 0, SEG - 1 do
      local t0 = i / SEG
      local t1 = (i + 1) / SEG
      local c0 = hsv_rgba_u32(h, t0, VAL, 1)
      local c1 = hsv_rgba_u32(h, t1, VAL, 1)
      
      if Colors then
        c0 = Colors.adjust_brightness(c0, 0.88)
        c1 = Colors.adjust_brightness(c1, 0.88)
      end
      
      local sx0 = x0 + i * segw
      local sx1 = x0 + (i + 1) * segw
      ImGui.DrawList_AddRectFilledMultiColor(dl, sx0, y0, sx1, y1, c0, c1, c1, c0)
    end
  end
  
  local tooltip_fn = function(v)
    return string.format("Saturation: %.0f%%", v)
  end
  
  return draw_slider_base(ctx, id, saturation, 0, 100, opt.default or 50, gradient_fn, tooltip_fn, opt)
end

-- BRIGHTNESS SLIDER
function M.draw_gamma(ctx, id, gamma, opt)
  opt = opt or {}
  local SEG = 120
  
  local gradient_fn = function(dl, x0, y0, x1, y1, opt)
    local W = x1 - x0
    local segw = W / SEG
    for i = 0, SEG - 1 do
      local t0 = i / SEG
      local t1 = (i + 1) / SEG
      
      local gray0 = math.floor(t0 * 255 + 0.5)
      local gray1 = math.floor(t1 * 255 + 0.5)
      
      local c0 = (gray0 << 24) | (gray0 << 16) | (gray0 << 8) | 0xFF
      local c1 = (gray1 << 24) | (gray1 << 16) | (gray1 << 8) | 0xFF
      
      if Colors then
        c0 = Colors.adjust_brightness(c0, 0.88)
        c1 = Colors.adjust_brightness(c1, 0.88)
      end
      
      local sx0 = x0 + i * segw
      local sx1 = x0 + (i + 1) * segw
      ImGui.DrawList_AddRectFilledMultiColor(dl, sx0, y0, sx1, y1, c0, c1, c1, c0)
    end
  end
  
  local tooltip_fn = function(v)
    return string.format("Brightness: %.0f%%", v)
  end
  
  return draw_slider_base(ctx, id, gamma, 0, 100, opt.default or 50, gradient_fn, tooltip_fn, opt)
end

-- Legacy
function M.draw(ctx, id, hue, opt)
  return M.draw_hue(ctx, id, hue, opt)
end

return M