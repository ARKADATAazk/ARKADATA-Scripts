-- Region_Playlist/app/config/transport.lua
-- Transport bar configurations

local Constants = require('Region_Playlist.app.config.constants')

local M = {}

M.TRANSPORT = {
  height = 120,
  bg_color = Constants.COLORS.BG_PRIMARY,
  padding = 12,
  spacing = 12,
}

M.QUANTIZE = {
  default_lookahead = Constants.QUANTIZE.default_lookahead,
  min_lookahead = Constants.QUANTIZE.min_lookahead,
  max_lookahead = Constants.QUANTIZE.max_lookahead,
  
  grid_options = {
    { label = "Measure", value = "measure" },
    { label = "1 Bar (4/4)", value = "4.0" },
    { label = "1/2 Note", value = "2.0" },
    { label = "1/4 Note", value = "1.0" },
    { label = "1/8 Note", value = "0.5" },
    { label = "1/16 Note", value = "0.25" },
    { label = "1/32 Note", value = "0.125" },
    { label = "1/64 Note", value = "0.0625" },
  },
}

return M