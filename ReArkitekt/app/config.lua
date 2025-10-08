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
    default        = 13,
    title          = 14,
    family_regular = "Inter_18pt-Regular.ttf",
    family_bold    = "Inter_18pt-SemiBold.ttf",
  },

  titlebar = {
    height          = 26,
    pad_h           = 12,
    pad_v           = 0,
    button_width    = 44,
    button_spacing  = 0,
    button_style    = "minimal",
    separator       = true,
    bg_color        = nil,
    bg_color_active = nil,
    text_color      = nil,
    icon_size       = 18,
    icon_spacing    = 8,
    show_icon       = true,
    enable_maximize = true,
    
    -- Button colors (minimal style)
    button_maximize_normal  = 0x00000000,  -- Transparent
    button_maximize_hovered = 0x57C290FF,  -- Subtle white
    button_maximize_active  = 0x60FFFFFF,
    button_close_normal     = 0x00000000,  -- Transparent
    button_close_hovered    = 0xCC3333FF,  -- Red
    button_close_active     = 0xFF1111FF,  -- Bright red
    
    -- Button colors (filled style)
    button_maximize_filled_normal  = 0x808080FF,  -- Gray
    button_maximize_filled_hovered = 0x999999FF,
    button_maximize_filled_active  = 0x666666FF,
    button_close_filled_normal     = 0xCC3333FF,  -- Red
    button_close_filled_hovered    = 0xFF4444FF,
    button_close_filled_active     = 0xFF1111FF,
  },

  status_bar = {
    height = 34,
  },
}

function M.get_defaults()
  return M.defaults
end

return M