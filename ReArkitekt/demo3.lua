-- demo3.lua – Status Pads Widget Demo (Improved)
package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

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

local Shell = require("ReArkitekt.app.shell")
local StatusPad = require("ReArkitekt.gui.widgets.displays.status_pad")
local StatusBar = require("ReArkitekt.gui.widgets.status_bar")

local style_ok, Style = pcall(require, "ReArkitekt.gui.style")

local transport_override = true
local follow_playhead = false
local quantize_enabled = true
local timeline_mode = "Timeline"
local recording_armed = false
local metronome_enabled = true

local function get_status()
  return {
    color = 0x41E0A3FF,
    text  = "Status Pads Demo  •  Interactive Toggle Tiles",
    buttons = nil,
    right_buttons = nil
  }
end

local status_bar = StatusBar.new({
  height = 28,
  get_status = get_status,
  style = style_ok and Style and { palette = Style.palette } or nil
})

local pads = {}

local function init_pads()
  pads.transport = StatusPad.new({
    id = "transport_pad",
    width = 220,
    height = 65,
    color = 0x5B8DFFFF,
    primary_text = "Transport Override",
    state = transport_override,
    icon_type = "check",
    on_click = function(new_state)
      transport_override = new_state
      pads.transport:set_state(new_state)
    end,
  })
  
  pads.follow = StatusPad.new({
    id = "follow_pad",
    width = 220,
    height = 65,
    color = 0x9D7BE8FF,
    primary_text = "Follow Playhead",
    state = follow_playhead,
    icon_type = "check",
    on_click = function(new_state)
      follow_playhead = new_state
      pads.follow:set_state(new_state)
    end,
  })
  
  pads.quantize = StatusPad.new({
    id = "quantize_pad",
    width = 220,
    height = 65,
    color = 0xFFA94DFF,
    primary_text = "Quantize",
    secondary_text = quantize_enabled and "Quantized" or "Off",
    state = quantize_enabled,
    icon_type = "minus",
    on_click = function(new_state)
      quantize_enabled = new_state
      pads.quantize:set_state(new_state)
      pads.quantize:set_secondary_text(new_state and "Quantized" or "Off")
    end,
  })
  
  pads.timeline = StatusPad.new({
    id = "timeline_pad",
    width = 220,
    height = 65,
    color = 0x4ECDC4FF,
    primary_text = timeline_mode,
    secondary_text = "Mode",
    state = true,
    icon_type = "dot",
    badge_text = "4/4",
  })
  
  pads.recording = StatusPad.new({
    id = "recording_pad",
    width = 220,
    height = 65,
    color = 0xE74856FF,
    primary_text = "Recording",
    secondary_text = recording_armed and "Armed" or "Ready",
    state = recording_armed,
    icon_type = "dot",
    badge_text = "REC",
    on_click = function(new_state)
      recording_armed = new_state
      pads.recording:set_state(new_state)
      pads.recording:set_secondary_text(new_state and "Armed" or "Ready")
    end,
  })
  
  pads.metronome = StatusPad.new({
    id = "metronome_pad",
    width = 220,
    height = 65,
    color = 0x4CAF50FF,
    primary_text = "Metronome",
    state = metronome_enabled,
    icon_type = "check",
    badge_text = "120",
    on_click = function(new_state)
      metronome_enabled = new_state
      pads.metronome:set_state(new_state)
    end,
  })
end

init_pads()

local function draw(ctx)
  ImGui.PushStyleColor(ctx, ImGui.Col_Text, 0xEEEEEEFF)
  
  ImGui.Dummy(ctx, 1, 8)
  ImGui.Text(ctx, "Interactive Status Pads")
  ImGui.Separator(ctx)
  ImGui.Dummy(ctx, 1, 10)
  
  ImGui.PushStyleColor(ctx, ImGui.Col_Text, 0x999999FF)
  ImGui.TextWrapped(ctx, "Click to toggle states  •  Hover for visual feedback  •  Active states show enhanced visuals")
  ImGui.PopStyleColor(ctx)
  
  ImGui.Dummy(ctx, 1, 18)
  
  local start_x, start_y = ImGui.GetCursorScreenPos(ctx)
  local gap = 16
  
  local row1_y = start_y
  pads.transport:draw(ctx, start_x, row1_y)
  pads.follow:draw(ctx, start_x + 220 + gap, row1_y)
  pads.quantize:draw(ctx, start_x + (220 + gap) * 2, row1_y)
  
  ImGui.Dummy(ctx, 1, 65 + 16)
  
  local row2_y = row1_y + 65 + 16
  ImGui.SetCursorScreenPos(ctx, start_x, row2_y)
  
  pads.timeline:draw(ctx, start_x, row2_y)
  pads.recording:draw(ctx, start_x + 220 + gap, row2_y)
  pads.metronome:draw(ctx, start_x + (220 + gap) * 2, row2_y)
  
  ImGui.Dummy(ctx, 1, 65 + 22)
  
  ImGui.Separator(ctx)
  ImGui.Dummy(ctx, 1, 10)
  
  ImGui.PushStyleColor(ctx, ImGui.Col_Text, 0xAAAAAAFF)
  ImGui.Text(ctx, "Features:")
  ImGui.PopStyleColor(ctx)
  
  ImGui.Dummy(ctx, 1, 4)
  
  ImGui.PushStyleColor(ctx, ImGui.Col_Text, 0x999999FF)
  ImGui.BulletText(ctx, "Enhanced tile FX rendering with refined gradients, specular highlights, and subtle shadows")
  ImGui.BulletText(ctx, "Smooth hover animations with frame-interpolated transitions")
  ImGui.BulletText(ctx, "Dynamic icon states (check, minus, dot) with glow effects when active")
  ImGui.BulletText(ctx, "Primary and secondary text with intelligent color derivation")
  ImGui.BulletText(ctx, "Optional badge overlays with hover-responsive styling")
  ImGui.BulletText(ctx, "Adaptive text colors based on tile luminance for optimal readability")
  ImGui.BulletText(ctx, "State-dependent border and glow intensity for clear visual feedback")
  ImGui.PopStyleColor(ctx)
  
  ImGui.Dummy(ctx, 1, 10)
  ImGui.Separator(ctx)
  ImGui.Dummy(ctx, 1, 10)
  
  ImGui.PushStyleColor(ctx, ImGui.Col_Text, 0xAAAAAAFF)
  ImGui.Text(ctx, "Current States:")
  ImGui.PopStyleColor(ctx)
  
  ImGui.Dummy(ctx, 1, 4)
  
  local function state_text(label, value)
    ImGui.PushStyleColor(ctx, ImGui.Col_Text, 0x888888FF)
    ImGui.Text(ctx, label .. ":")
    ImGui.PopStyleColor(ctx)
    ImGui.SameLine(ctx, 200)
    if value then
      ImGui.PushStyleColor(ctx, ImGui.Col_Text, 0x4CAF50FF)
      ImGui.Text(ctx, "ON")
    else
      ImGui.PushStyleColor(ctx, ImGui.Col_Text, 0x666666FF)
      ImGui.Text(ctx, "OFF")
    end
    ImGui.PopStyleColor(ctx)
  end
  
  state_text("  Transport Override", transport_override)
  state_text("  Follow Playhead", follow_playhead)
  state_text("  Quantize", quantize_enabled)
  state_text("  Recording Armed", recording_armed)
  state_text("  Metronome", metronome_enabled)
  
  ImGui.PopStyleColor(ctx)
end

Shell.run({
  title        = "ReArkitekt – Status Pads Demo",
  draw         = draw,
  style        = style_ok and Style or nil,
  initial_pos  = { x = 140, y = 140 },
  initial_size = { w = 750, h = 680 },
  min_size     = { w = 700, h = 600 },
  content_padding = 12,
  status_bar   = status_bar
})