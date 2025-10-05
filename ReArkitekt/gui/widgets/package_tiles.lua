-- ReArkitekt/gui/widgets/package_tiles.lua
-- Package tiles - backward compatibility wrapper
-- Main implementation is in package_tiles/grid.lua

local PackageGrid = require('ReArkitekt.gui.widgets.package_tiles.grid')
local Micromanage = require('ReArkitekt.gui.widgets.package_tiles.micromanage')

local M = {}

-- Re-export main create function
M.create = PackageGrid.create

-- Convenience function to draw micromanage window
function M.draw_micromanage_window(ctx, pkg, settings)
  Micromanage.draw_window(ctx, pkg, settings)
end

return M