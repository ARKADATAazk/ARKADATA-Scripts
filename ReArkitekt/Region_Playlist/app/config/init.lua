-- Region_Playlist/app/config/init.lua
-- Central config export

local M = {}

-- Import all config modules
M.Constants = require('Region_Playlist.app.config.constants')
M.Panel = require('Region_Playlist.app.config.panel')
M.Layout = require('Region_Playlist.app.config.layout')
M.Transport = require('Region_Playlist.app.config.transport')
M.RegionTiles = require('Region_Playlist.app.config.region_tiles')

-- Convenience accessors for backwards compatibility
M.COLORS = M.Constants.COLORS
M.GRID = M.Constants.GRID
M.ANIMATION = M.Constants.ANIMATION
M.QUANTIZE = M.Constants.QUANTIZE

M.LAYOUT_BUTTON = M.Layout.LAYOUT_BUTTON
M.SEPARATOR = M.Layout.SEPARATOR

M.TRANSPORT = M.Transport.TRANSPORT

-- Main config functions
M.get_active_container_config = M.Panel.get_active_container_config
M.get_pool_container_config = M.Panel.get_pool_container_config
M.get_region_tiles_config = M.RegionTiles.get_config

return M