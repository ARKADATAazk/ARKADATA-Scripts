-- ReArkitekt/gui/widgets/region_tiles.lua
-- Region tiles - backward compatibility wrapper
-- Main implementation is in region_tiles/coordinator.lua

local Coordinator = require('ReArkitekt.gui.widgets.region_tiles.coordinator')

local M = {}

-- Re-export main create function
M.create = Coordinator.create

return M