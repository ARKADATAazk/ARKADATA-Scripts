-- Enhanced_Migrate/compat/enhanced_adapter.lua
-- Minimal compatibility shims that Enhanced code can call,
-- delegating to ReArk systems. Expand as you migrate more panels.

local A = {}

-- Palette: you can map Enhanced hex colors here if required.
-- For now, expose ReArk style palette.
A.palette = require('ReArkitekt.gui.style').palette

-- Selection model
A.selection = {}
function A.selection.new()
  return require('ReArkitekt.gui.systems.selection').new()
end

-- Layout grid math
A.layout = require('ReArkitekt.gui.systems.layout_grid')

-- Reorder helper
A.reorder = require('ReArkitekt.gui.systems.reorder')

-- Effects
A.effects = {
  ants       = require('ReArkitekt.gui.effects.marching_ants'),
  ghost_drag = require('ReArkitekt.gui.effects.ghost_drag'),
  drop_line  = require('ReArkitekt.gui.effects.drop_line'),
}

return A
