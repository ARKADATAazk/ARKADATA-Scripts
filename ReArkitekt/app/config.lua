-- ReArkitekt/app/config.lua
-- Single source of truth for all application defaults

local M = {}

M.defaults = {
  window = {
    title           = "Arkitekt App",
    content_padding = 12,
    min_size        = { w = 400, h = 300 },
    initial_size    = { w = 900, h = 600 },
    initial_pos     = { x = 100, y = 100 },
    
    -- Background colors
    bg_color_floating = nil,  -- nil = use ImGui default
    bg_color_docked   = 0x282828FF,  -- Slightly lighter for docked mode
  },

  fonts = {
    default        = 13,
    title          = 13,
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
    button_maximize_normal  = 0x00000000,
    button_maximize_hovered = 0x57C290FF,
    button_maximize_active  = 0x60FFFFFF,
    button_close_normal     = 0x00000000,
    button_close_hovered    = 0xCC3333FF,
    button_close_active     = 0xFF1111FF,
    
    -- Button colors (filled style)
    button_maximize_filled_normal  = 0x808080FF,
    button_maximize_filled_hovered = 0x999999FF,
    button_maximize_filled_active  = 0x666666FF,
    button_close_filled_normal     = 0xCC3333FF,
    button_close_filled_hovered    = 0xFF4444FF,
    button_close_filled_active     = 0xFF1111FF,
  },

  status_bar = {
    height = 20,
  },
}

function M.get_defaults()
  return M.defaults
end

function M.get(path)
  local keys = {}
  for key in path:gmatch("[^.]+") do
    table.insert(keys, key)
  end
  
  local value = M.defaults
  for _, key in ipairs(keys) do
    if type(value) ~= "table" then
      return nil
    end
    value = value[key]
  end
  
  return value
end

return M