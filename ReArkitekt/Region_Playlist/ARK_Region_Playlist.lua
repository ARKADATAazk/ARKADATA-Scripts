-- ARK_Region_Playlist.lua
-- Region Playlist - Entry Point

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path

local function dirname(p) return p:match("^(.*)[/\\]") end
local function join(a,b) local s=package.config:sub(1,1); return (a:sub(-1)==s) and (a..b) or (a..s..b) end
local function addpath(p) if p and p~="" and not package.path:find(p,1,true) then package.path = p .. ";" .. package.path end end

local SRC   = debug.getinfo(1,"S").source:sub(2)
local HERE  = dirname(SRC) or "."
local REARKITEKT_ROOT = dirname(HERE or ".") or "."
local SCRIPTS_ROOT = dirname(REARKITEKT_ROOT or ".") or "."

-- Add paths to resolve both ReArkitekt.* and Region_Playlist.* modules
addpath(join(SCRIPTS_ROOT, "?.lua"))
addpath(join(SCRIPTS_ROOT, "?/init.lua"))
addpath(join(REARKITEKT_ROOT, "?.lua"))
addpath(join(REARKITEKT_ROOT, "?/init.lua"))

local Shell = require("ReArkitekt.app.shell")
local Config = require("Region_Playlist.app.config")
local State = require("Region_Playlist.app.state")
local GUI = require("Region_Playlist.app.gui")
local StatusBarConfig = require("Region_Playlist.app.status")

local SettingsOK, Settings = pcall(require, "ReArkitekt.core.settings")
local StyleOK, Style = pcall(require, "ReArkitekt.gui.style")

local settings = nil
if SettingsOK and type(Settings.new) == "function" then
  local ok, inst = pcall(Settings.new, join(HERE, "cache"), "region_playlist.json")
  if ok then settings = inst end
end

State.initialize(settings)

---@type table
local status_bar = StatusBarConfig.create(State, StyleOK and Style)
local gui = GUI.create(State, Config, settings)

Shell.run({
  title        = "Region Playlist",
  draw         = function(ctx, shell_state) gui:draw(ctx) end,
  settings     = settings,
  style        = StyleOK and Style or nil,
  initial_pos  = { x = 120, y = 120 },
  initial_size = { w = 1000, h = 700 },
  icon_color = 0x41E0A3FF,  -- Optional: custom color
  icon_size = 18,           -- Optional: size
  min_size     = { w = 700, h = 500 },
  status_bar   = status_bar,
  content_padding = 12,
})