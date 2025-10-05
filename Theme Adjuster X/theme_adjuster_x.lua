-- Enhanced_Migrate/main.lua
-- Entry point to run Enhanced tabs inside ReArk shell.
-- Copy this file next to your Enhanced/ and ReArkitekt/ folders.
-- In REAPER: run this script; it will mount package.path for both trees.

local info = debug.getinfo(1,'S').source:match("^@(.+)$") or ''
local DIR  = info:gsub("[^/\\]+$","")
package.path = table.concat({
  DIR .. "?.lua",
  DIR .. "?/init.lua",
  DIR .. "Enhanced/?.lua",
  DIR .. "Enhanced/?/init.lua",
  DIR .. "Enhanced/?/?.lua",
  DIR .. "ReArkitekt/?.lua",
  DIR .. "ReArkitekt/?/init.lua",
  DIR .. "ReArkitekt/?/?.lua",
  package.path
}, ';')

local Shell     = require('ReArkitekt.app.shell')
local Tabs      = require('ReArkitekt.gui.widgets.tabs')
local Style     = require('ReArkitekt.gui.style')
local Adapter   = require('Enhanced_Migrate.compat.enhanced_adapter')

-- Bring in your existing Enhanced tab as-is
local AssemblerTab = require('tabs.assembler_tab')     -- from Enhanced tree
local SettingsMod  = require('core.settings')          -- Enhanced
local ThemeMod     = require('style')                  -- Enhanced theme module if it returns palette

-- Build the panel instances
local settings = SettingsMod.new and SettingsMod.new() or {}
local assembler_panel = AssemblerTab.create(ThemeMod, settings)  -- returns a per-frame callable

local tabs = Tabs.new('enhanced_tabs', {
  items = {
    { id='assembler', label='Assembler' },
    { id='about',     label='About' },
  },
  initial = 'assembler',
  on_change = function(id) end,
  style = { height = 34, round = 8, underline = true },
})

local function draw_about(ctx, app)
  local w = select(1, reaper.ImGui.GetContentRegionAvail(ctx))
  reaper.ImGui.PushTextWrapPos(ctx, reaper.ImGui.GetCursorPosX(ctx) + math.max(320, w - 40))
  reaper.ImGui.Text(ctx, "Enhanced 6.0 running inside ReArk shell.\nThis panel is a stub – migrate other tabs incrementally.")
  reaper.ImGui.PopTextWrapPos(ctx)
end

Shell.run({
  title = 'Enhanced 6.0 (ReArk Shell)',
  init = function(ctx, app)
    Style.apply_dark(ctx)   -- or your custom preset
  end,
  frame = function(ctx, app)
    local active = tabs:draw(ctx, app)
    if active == 'assembler' then
      assembler_panel(ctx)            -- call old panel per frame
    elseif active == 'about' then
      draw_about(ctx, app)
    end
  end,
})
