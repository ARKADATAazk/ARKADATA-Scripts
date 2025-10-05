-- demo2.lua – Demo for tiles_container and Color Sliders
package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

-- Path helpers
local function dirname(p) return p:match("^(.*)[/\\]") end
local function join(a,b) local s=package.config:sub(1,1); return (a:sub(-1)==s) and (a..b) or (a..s..b) end
local SRC   = debug.getinfo(1,"S").source:sub(2)
local HERE  = dirname(SRC) or "."
local PARENT= dirname(HERE or ".") or "."
local function addpath(p) if p and p~="" and not package.path:find(p,1,true) then package.path = p .. ";" .. package.path end end
addpath(join(PARENT,"?.lua")); addpath(join(PARENT,"?/init.lua"))
addpath(join(HERE,  "?.lua")); addpath(join(HERE,  "?/init.lua"))
addpath(join(HERE,  "ReArkitekt/?.lua"))
addpath(join(HERE,  "ReArkitekt/?/init.lua"))
addpath(join(HERE,  "ReArkitekt/?/?.lua"))

-- Libs
local Shell         = require("ReArkitekt.app.shell")
local ColorSliders  = require("ReArkitekt.gui.widgets.sliders.hue")
local StatusBar     = require("ReArkitekt.gui.widgets.status_bar")
local TilesContainer = require("ReArkitekt.gui.widgets.tiles_container")

-- Fallback style
local style_ok, Style = pcall(require, "ReArkitekt.gui.style")

-- State variables - ALL AT THE TOP
local hue = 210.0
local saturation = 80.0
local brightness = 85.0

-- Simple status bar
local function get_status()
  return {
    color = 0x41E0A3FF,
    text  = string.format("H:%.0f° S:%.0f%% B:%.0f%% | Color Sliders Demo", hue, saturation, brightness),
    buttons = nil,
    right_buttons = nil
  }
end

local status_bar = StatusBar.new({
  height = 28,
  get_status = get_status,
  style = style_ok and Style and { palette = Style.palette } or nil
})

-- HSV->RGBA helper for preview
local function hsv_to_rgba_u32(hdeg, s, v, a)
  local h = (hdeg % 360) / 360.0
  s = s / 100.0
  v = v / 100.0
  local i = math.floor(h * 6)
  local f = h * 6 - i
  local p = v * (1 - s)
  local q = v * (1 - f * s)
  local t = v * (1 - (1 - f) * s)
  local r,g,b
  i = i % 6
  if     i == 0 then r,g,b = v,t,p
  elseif i == 1 then r,g,b = q,v,p
  elseif i == 2 then r,g,b = p,v,t
  elseif i == 3 then r,g,b = p,q,v
  elseif i == 4 then r,g,b = t,p,v
  else               r,g,b = v,p,q
  end
  local R = math.floor(r*255+0.5)
  local G = math.floor(g*255+0.5)
  local B = math.floor(b*255+0.5)
  local A = math.floor((a or 1)*255+0.5)
  return (R<<24)|(G<<16)|(B<<8)|A
end

-- Dummy tile renderer
local function draw_dummy_tile(ctx, dl, x, y, w, h, label, color)
  ImGui.DrawList_AddRectFilled(dl, x, y, x + w, y + h, color, 4)
  ImGui.DrawList_AddRect(dl, x + 0.5, y + 0.5, x + w - 0.5, y + h - 0.5, 0x00000088, 4, 0, 1)
  
  local tw, th = ImGui.CalcTextSize(ctx, label)
  local tx = x + (w - tw) / 2
  local ty = y + (h - th) / 2
  ImGui.DrawList_AddText(dl, tx, ty, 0xFFFFFFFF, label)
end

-- UI
local function draw(ctx)
  ImGui.Text(ctx, "Color Sliders & Tiles Container Demo")
  ImGui.Separator(ctx)
  ImGui.Dummy(ctx, 1, 8)

  -- HUE SLIDER (no longer affected by saturation/brightness changes)
  ImGui.Text(ctx, "Hue (0-360°):")
  local changed_h
  changed_h, hue = ColorSliders.draw_hue(ctx, "##hue_slider", hue, {
    w = 320,
    h = 20,
  })

  ImGui.Dummy(ctx, 1, 12)

  -- SATURATION SLIDER (updates when hue changes)
  ImGui.Text(ctx, "Saturation (0-100%):")
  local changed_s
  changed_s, saturation = ColorSliders.draw_saturation(ctx, "##sat_slider", saturation, hue, {
    w = 320,
    h = 20,
    brightness = brightness,
  })

  ImGui.Dummy(ctx, 1, 12)

  -- BRIGHTNESS/GAMMA SLIDER (independent)
  ImGui.Text(ctx, "Brightness (0-100%):")
  local changed_b
  changed_b, brightness = ColorSliders.draw_gamma(ctx, "##gamma_slider", brightness, {
    w = 320,
    h = 20,
  })

  ImGui.Dummy(ctx, 1, 12)

  -- Color Preview
  ImGui.Text(ctx, "Current Color:")
  local preview_color = hsv_to_rgba_u32(hue, saturation, brightness, 1.0)
  local dl = ImGui.GetWindowDrawList(ctx)
  local px, py = ImGui.GetCursorScreenPos(ctx)
  ImGui.DrawList_AddRectFilled(dl, px, py, px + 320, py + 40, preview_color, 4)
  ImGui.DrawList_AddRect(dl, px + 0.5, py + 0.5, px + 319.5, py + 39.5, 0x000000DD, 4, 0, 1)
  ImGui.Dummy(ctx, 320, 40)

  ImGui.Dummy(ctx, 1, 12)
  ImGui.Separator(ctx)
  ImGui.Dummy(ctx, 1, 8)

  -- Tiles Container with dummy content
  ImGui.Text(ctx, "Scrollable Tiles Container:")
  ImGui.Dummy(ctx, 1, 4)

  local container = TilesContainer.new({
    id = "demo_container",
    width = nil,
    height = 200,
  })

  if container:begin_draw(ctx) then
    local dl = ImGui.GetWindowDrawList(ctx)
    local cx, cy = ImGui.GetCursorScreenPos(ctx)
    
    local tile_w = 120
    local tile_h = 80
    local gap = 12
    local cols = 3
    
    for i = 0, 14 do
      local col = i % cols
      local row = math.floor(i / cols)
      
      local x = cx + col * (tile_w + gap)
      local y = cy + row * (tile_h + gap)
      
      local tile_hue = (hue + i * 20) % 360
      local tile_color = hsv_to_rgba_u32(tile_hue, saturation, brightness, 1.0)
      
      draw_dummy_tile(ctx, dl, x, y, tile_w, tile_h, "Tile " .. (i + 1), tile_color)
    end
    
    local total_rows = math.ceil(15 / cols)
    ImGui.Dummy(ctx, cols * (tile_w + gap), total_rows * (tile_h + gap))
  end
  container:end_draw(ctx)

  ImGui.Dummy(ctx, 1, 8)
  ImGui.TextDisabled(ctx, "Double-click sliders to reset • Scroll container to see more tiles")
end

-- Run
Shell.run({
  title        = "ReArkitekt – Color Sliders Demo",
  draw         = draw,
  style        = style_ok and Style or nil,
  initial_pos  = { x = 140, y = 140 },
  initial_size = { w = 520, h = 720 },
  min_size     = { w = 420, h = 500 },
  status_bar   = status_bar
})