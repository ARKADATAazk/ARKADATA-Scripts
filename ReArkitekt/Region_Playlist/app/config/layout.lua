-- Region_Playlist/app/config/layout.lua
-- Layout-specific configurations (buttons, separators)

local Constants = require('Region_Playlist.app.config.constants')

local M = {}

M.LAYOUT_BUTTON = {
  width = 32,
  height = 32,
  bg_color = 0x2A2A2AFF,
  bg_hover = 0x3A3A3AFF,
  bg_active = 0x4A4A4AFF,
  border_color = 0x404040FF,
  border_hover = 0x606060FF,
  icon_color = 0xAAAAAAFF,
  icon_hover = 0xFFFFFFFF,
  rounding = 4,
  animation_speed = Constants.ANIMATION.HOVER_SPEED,
}

M.SEPARATOR = {
  horizontal = {
    default_position = 180,
    min_active_height = 100,
    min_pool_height = 100,
    gap = 8,
    thickness = 6,
  },
  vertical = {
    default_position = 280,
    min_active_width = 200,
    min_pool_width = 200,
    gap = 8,
    thickness = 6,
  },
}

return M