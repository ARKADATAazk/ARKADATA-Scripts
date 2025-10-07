-- ReArkitekt/app/config.lua
-- Default application configuration for ReArkitekt shell + window

local M = {}

M.defaults = {
  window = {
    title           = "ReArkitekt App",
    content_padding = 12,
    min_size        = { w = 400, h = 300 },
    initial_size    = { w = 900, h = 600 },
    initial_pos     = { x = 100, y = 100 },
  },

  fonts = {
    default = 13,
    title   = 13,
    family  = "Inter_18pt-Regular.ttf",
    bold    = "Inter_18pt-SemiBold.ttf",
  },

  style = {
    status_bar_height = 34,
  },
}

function M.get_defaults()
  return M.defaults
end

return M
