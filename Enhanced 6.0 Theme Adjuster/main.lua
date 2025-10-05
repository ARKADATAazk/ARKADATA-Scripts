-- main.lua

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

-- Expand package.path for subfolders
do
  local sep = package.config:sub(1,1)
  local src = debug.getinfo(1, 'S').source:sub(2)
  local dir = src:match("(.*"..sep..")") or ("."..sep)
  package.path = table.concat({
    dir .. "?.lua",
    dir .. "core" .. sep .. "?.lua",
    dir .. "tabs" .. sep .. "?.lua",
    package.path
  }, ";")
end

local app    = require('app')          -- keep (core/app.lua)
local style  = require('style')        -- keep
local theme  = require('theme')        -- keep
local dbgmod = require('debug_tab')    -- keep
local assembler_tab = require('assembler_tab')
local settings

-- Open debounced settings store under /cache/
do
  local sep2 = package.config:sub(1,1)
  local src2 = debug.getinfo(1, 'S').source:sub(2)
  local dir2 = src2:match("(.*"..sep2..")") or ("."..sep2)
  settings = require('settings').open(dir2 .. "cache", "settings.json")
end

  -- keep

-- instantiate tabs that expose lifecycle hooks
local asm = assembler_tab.create(theme, settings and settings:sub('tabs.ASSEMBLER'))
local dbg = dbgmod.create(theme, settings and settings:sub('tabs.DEBUG'))

local tabs = {
  { id = 'GLOBAL',    draw = function(ctx, s) end },

  { id = 'ASSEMBLER',
    draw        = asm.draw,
    on_hide     = asm.on_hide,
    begin_frame = asm.begin_frame,
  },

  { id = 'TCP',       draw = function(ctx, s) end },
  { id = 'MCP',       draw = function(ctx, s) end },
  { id = 'COLORS',    draw = function(ctx, s) end },
  { id = 'ENVELOPES', draw = function(ctx, s) end },
  { id = 'TRANSPORT', draw = function(ctx, s) end },

  { id = 'DEBUG',
    draw        = dbg.draw,
    on_hide     = dbg.on_hide,
    begin_frame = dbg.begin_frame,
  },
}

app.run({
  settings_store = settings,
  title      = 'Enhanced 6.0 Theme Adjuster — Demo',
  theme      = theme,            -- ← add this
  tabs       = tabs,
  style      = style,
  brandColor = 0x00B88FCC,
  brandHover = 0x33CCB8CC,
  brandDown  = 0x00A07ACC,
})

