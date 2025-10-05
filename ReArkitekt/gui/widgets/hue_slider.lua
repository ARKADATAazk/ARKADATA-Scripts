-- ReArkitekt/gui/widgets/hue_slider.lua
-- Color sliders: Hue, Saturation, and Gamma (Brightness)
-- Usage: 
--   changed, new_hue = M.draw_hue(ctx, id, hue, opt)
--   changed, new_sat = M.draw_saturation(ctx, id, saturation, base_hue, opt)
--   changed, new_gamma = M.draw_gamma(ctx, id, gamma, opt)

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local palette
local Colors
do
  local ok, Style = pcall(require, "ReArkitekt.gui.style")
  if ok and type(Style) == "table" and type(Style.palette) == "table" then
    palette = Style.palette
  end
  
  local ok2, C = pcall(require, "ReArkitekt.gui.colors")
  if ok2 and type(C) == "table" then
    Colors = C
  end
end

local M = {}

-- Shared state
local _locks = {}

-- Utility functions
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
  local col = (R << 24) | (G << 16) | (B << 8) | A
  
  if Colors then
    col = Colors.desaturate(col, 0.15)
    col = Colors.adjust_brightness(col, 0.85)
  end
  
  return col
end

-- Core slider drawing function (used by all slider types)
local function draw_slider_base(ctx, id, value, min_val, max_val, default_val, gradient_fn, tooltip_fn, opt)
  opt = opt or {}
  
  local W = opt.w or 240
  local H = opt.h or 20
  local GRAB_W = opt.grab_w or 12
  
  local BORDER = (opt.border ~= nil) and opt.border or (palette and palette.border_soft) or 0x000000DD
  local GRAB_COL = (opt.grab_color ~= nil) and opt.grab_color or 0x00FFA7FF
  local GRAB_ACTIVE_COL = (opt.grab_active_color ~= nil) and opt.grab_active_color or (palette and palette.red) or 0xE04141FF
  local FRAME_BG_ALPHA = opt.frame_bg_alpha or 0x00
  
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
  local double_clicked = false
  
  if hovered and not locked and ImGui.IsMouseDoubleClicked(ctx, 0) then
    value = default_val
    changed = true
    double_clicked = true
    _locks[id] = now + 0.3
  end
  
  if not double_clicked and not locked and active then
    local mx = select(1, ImGui.GetMousePos(ctx))
    local t = (mx - x0) / W
    t = clamp(t, 0, 1)
    local nv = min_val + t * (max_val - min_val)
    if math.abs(nv - value) > 1e-3 then
      value = nv
      changed = true
    end
  end
  
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
  
  if FRAME_BG_ALPHA and FRAME_BG_ALPHA > 0 then
    local frame_bg_col = (palette and palette.grey_06) or 0x0F0F0FFF
    frame_bg_col = (frame_bg_col & 0xFFFFFF00) | (FRAME_BG_ALPHA & 0xFF)
    ImGui.DrawList_AddRectFilled(dl, x0, y0, x1, y1, frame_bg_col, 0)
  end
  
  gradient_fn(dl, x0, y0, x1, y1, W, opt)
  
  if BORDER and BORDER ~= 0 then
    ImGui.DrawList_AddRect(dl, x0, y0, x1, y1, BORDER, 0, 0, 1)
  end
  
  local t = (value - min_val) / (max_val - min_val)
  local gx = clamp(x0 + t * W, x0 + GRAB_W / 2, x1 - GRAB_W / 2)
  local grab_col = active and GRAB_ACTIVE_COL or GRAB_COL
  
  ImGui.DrawList_AddRectFilled(dl, gx - GRAB_W / 2, y0, gx + GRAB_W / 2, y1, grab_col, 0)
  
  if BORDER and BORDER ~= 0 then
    ImGui.DrawList_AddRect(dl, gx - GRAB_W / 2, y0, gx + GRAB_W / 2, y1, BORDER, 0, 0, 1)
  end
  
  if hovered then
    if ImGui.BeginTooltip(ctx) then
      ImGui.Text(ctx, tooltip_fn(value))
      ImGui.EndTooltip(ctx)
    end
  end
  
  return changed, value
end

-- HUE SLIDER (0-360 degrees)
function M.draw_hue(ctx, id, hue, opt)
  opt = opt or {}
  local SATURATION = clamp(opt.saturation or 88, 0, 100)
  local BRIGHTNESS = clamp(opt.brightness or 92, 0, 100)
  local SEG = math.max(24, opt.segments or 72)
  
  local gradient_fn = function(dl, x0, y0, x1, y1, W, opt)
    local SAT = SATURATION / 100.0
    local VAL = BRIGHTNESS / 100.0
    local segw = W / SEG
    for i = 0, SEG - 1 do
      local t0 = i / SEG
      local t1 = (i + 1) / SEG
      local c0 = hsv_rgba_u32(t0, SAT, VAL, 1)
      local c1 = hsv_rgba_u32(t1, SAT, VAL, 1)
      local sx0 = x0 + i * segw
      local sx1 = x0 + (i + 1) * segw
      ImGui.DrawList_AddRectFilledMultiColor(dl, sx0, y0, sx1, y1, c0, c1, c1, c0)
    end
  end
  
  local tooltip_fn = function(v)
    return string.format("Hue: %.1f°", v)
  end
  
  local default_hue = opt.default or 180.0
  return draw_slider_base(ctx, id, hue, 0, 359.999, default_hue, gradient_fn, tooltip_fn, opt)
end

-- SATURATION SLIDER (0-100%)
function M.draw_saturation(ctx, id, saturation, base_hue, opt)
  opt = opt or {}
  base_hue = base_hue or 210
  local BRIGHTNESS = clamp(opt.brightness or 92, 0, 100)
  local SEG = math.max(24, opt.segments or 72)
  
  local gradient_fn = function(dl, x0, y0, x1, y1, W, opt)
    local VAL = BRIGHTNESS / 100.0
    local h = (base_hue % 360) / 360.0
    local segw = W / SEG
    for i = 0, SEG - 1 do
      local t0 = i / SEG
      local t1 = (i + 1) / SEG
      local c0 = hsv_rgba_u32(h, t0, VAL, 1)
      local c1 = hsv_rgba_u32(h, t1, VAL, 1)
      local sx0 = x0 + i * segw
      local sx1 = x0 + (i + 1) * segw
      ImGui.DrawList_AddRectFilledMultiColor(dl, sx0, y0, sx1, y1, c0, c1, c1, c0)
    end
  end
  
  local tooltip_fn = function(v)
    return string.format("Saturation: %.0f%%", v)
  end
  
  local default_sat = opt.default or 50
  return draw_slider_base(ctx, id, saturation, 0, 100, default_sat, gradient_fn, tooltip_fn, opt)
end

-- GAMMA/BRIGHTNESS SLIDER (0-100%)
function M.draw_gamma(ctx, id, gamma, opt)
  opt = opt or {}
  local SEG = math.max(24, opt.segments or 72)
  
  local gradient_fn = function(dl, x0, y0, x1, y1, W, opt)
    local segw = W / SEG
    for i = 0, SEG - 1 do
      local t0 = i / SEG
      local t1 = (i + 1) / SEG
      
      local gray0 = math.floor(t0 * 255 + 0.5)
      local gray1 = math.floor(t1 * 255 + 0.5)
      
      local c0 = (gray0 << 24) | (gray0 << 16) | (gray0 << 8) | 0xFF
      local c1 = (gray1 << 24) | (gray1 << 16) | (gray1 << 8) | 0xFF
      
      if Colors then
        c0 = Colors.adjust_brightness(c0, 0.85)
        c1 = Colors.adjust_brightness(c1, 0.85)
      end
      
      local sx0 = x0 + i * segw
      local sx1 = x0 + (i + 1) * segw
      ImGui.DrawList_AddRectFilledMultiColor(dl, sx0, y0, sx1, y1, c0, c1, c1, c0)
    end
  end
  
  local tooltip_fn = function(v)
    return string.format("Brightness: %.0f%%", v)
  end
  
  local default_gamma = opt.default or 50
  return draw_slider_base(ctx, id, gamma, 0, 100, default_gamma, gradient_fn, tooltip_fn, opt)
end

-- Legacy compatibility (calls draw_hue)
function M.draw(ctx, id, hue, opt)
  return M.draw_hue(ctx, id, hue, opt)
end

return M