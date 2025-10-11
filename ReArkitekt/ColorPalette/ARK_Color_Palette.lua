-- ReArkitekt/ColorPalette/ARK_Color_Palette.lua
-- Entry point for Color Palette script
-- Run once to open, run again to toggle visibility
-- Add to REAPER startup actions for instant availability

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

-- Path setup
local function dirname(p) return p:match("^(.*)[/\\]") end
local function join(a,b) local s=package.config:sub(1,1); return (a:sub(-1)==s) and (a..b) or (a..s..b) end
local SRC = debug.getinfo(1,"S").source:sub(2)
local HERE = dirname(SRC) or "."
local PARENT = dirname(HERE or ".") or "."
local GRANDPARENT = dirname(PARENT or ".") or "."

local function addpath(p)
  if p and p~="" and not package.path:find(p,1,true) then
    package.path = p .. ";" .. package.path
  end
end

-- Add ReArkitekt parent (ARKADATA Scripts level)
addpath(join(GRANDPARENT,"?.lua"))
addpath(join(GRANDPARENT,"?/init.lua"))
-- Add ColorPalette folder
addpath(join(HERE,"?.lua"))
addpath(join(HERE,"?/init.lua"))

-- Load dependencies
local Shell = require("ReArkitekt.app.shell")
local State = require("ReArkitekt.ColorPalette.app.state")
local GUI = require("ReArkitekt.ColorPalette.app.gui")
local OverlayManager = require("ReArkitekt.gui.widgets.overlay.manager")

-- Load optional style
local style_ok, Style = pcall(require, "ReArkitekt.gui.style")

-- Initialize cache directory for settings
local SEP = package.config:sub(1,1)
local cache_dir = reaper.GetResourcePath() .. SEP .. "Scripts" .. SEP .. "ReArkitekt" .. SEP .. "cache" .. SEP .. "ColorPalette"

-- Initialize settings and state
local Settings = require('ReArkitekt.core.settings')
local settings = Settings.open(cache_dir, 'settings.json')

State.initialize(settings)

-- Create overlay manager
local overlay = OverlayManager.new()

-- Create GUI instance
local gui = GUI.create(State, settings, overlay)

-- Main draw function
local function draw(ctx, shell_state)
  return gui:draw(ctx)
end

-- Run application
-- ImGui in REAPER handles show/hide automatically:
-- - Running script while window is open toggles visibility
-- - Clicking X button hides (doesn't terminate)
-- - Script stays alive in background
Shell.run({
  title = "Color Palette",
  draw = draw,
  style = style_ok and Style or nil,
  settings = settings,
  initial_pos = { x = 140, y = 140 },
  initial_size = { w = 600, h = 320 },
  min_size = { w = 480, h = 240 },
  content_padding = 0,
  show_status_bar = false,
  show_titlebar = false,
  raw_content = true,
  
  -- Make window frameless
  flags = ImGui.WindowFlags_NoBackground,
  bg_color_floating = 0x00000000,
  bg_color_docked = 0x00000000,
  
  -- Pass overlay manager to window
  overlay = overlay,
  
  on_close = function()
    State.save()
  end,
})