-- ReArkitekt/app/chrome/status_bar/config.lua
-- Default configuration for status bar appearance and behavior

local Chip = require('ReArkitekt.gui.widgets.component.chip')

local M = {}

M.defaults = {
  -- Bar dimensions
  height = 28,
  left_pad = 10,
  text_pad = 8,
  chip_size = 10,
  right_pad = 10,

  -- Resize handle configuration
  show_resize_handle = true,
  resize_square_size = 3,
  resize_spacing = 1,

  -- Chip appearance
  chip = {
    shape = Chip.SHAPE.CIRCLE,   -- CIRCLE or SQUARE
    rounding = 2,                -- Corner rounding for squares (0 = sharp)
    show_glow = true,            -- Enable glow effect
    glow_layers = 5,             -- Glow smoothness (more = smoother)
    shadow = true,               -- Enable drop shadow
    shadow_offset_x = 0,         -- Shadow horizontal offset
    shadow_offset_y = 1,         -- Shadow vertical offset
    shadow_blur = 1,             -- Shadow blur radius
    shadow_alpha = 80,           -- Shadow transparency (0-255)
    border = false,              -- Enable border
    border_color = 0x000000FF,   -- Border color (RGBA)
    border_thickness = 1.0,      -- Border line thickness
  },
}

-- Preset configurations for different visual styles
M.presets = {
  -- Modern, clean look with circular indicators
  modern = {
    chip = {
      shape = Chip.SHAPE.CIRCLE,
      show_glow = true,
      glow_layers = 6,
      shadow = true,
      shadow_offset_y = 1,
      shadow_blur = 1,
      shadow_alpha = 80,
      border = false,
    }
  },

  -- Sharp, technical look with square indicators
  technical = {
    chip = {
      shape = Chip.SHAPE.SQUARE,
      rounding = 0,
      show_glow = false,
      shadow = true,
      shadow_offset_x = 1,
      shadow_offset_y = 1,
      shadow_blur = 0,
      shadow_alpha = 120,
      border = true,
      border_color = 0x000000FF,
      border_thickness = 1.0,
    }
  },

  -- Soft, rounded look with glowing squares
  soft = {
    chip = {
      shape = Chip.SHAPE.SQUARE,
      rounding = 3,
      show_glow = true,
      glow_layers = 8,
      shadow = true,
      shadow_offset_y = 1,
      shadow_blur = 2,
      shadow_alpha = 60,
      border = false,
    }
  },

  -- Minimal, flat design
  minimal = {
    chip = {
      shape = Chip.SHAPE.CIRCLE,
      show_glow = false,
      shadow = false,
      border = false,
    }
  },

  -- High contrast with borders
  high_contrast = {
    chip = {
      shape = Chip.SHAPE.CIRCLE,
      show_glow = true,
      glow_layers = 4,
      shadow = true,
      shadow_offset_y = 1,
      shadow_blur = 1,
      shadow_alpha = 100,
      border = true,
      border_color = 0x000000FF,
      border_thickness = 1.5,
    }
  },
}

-- Deep merge helper
function M.deep_merge(base, override)
  local result = {}
  for k, v in pairs(base) do
    result[k] = v
  end
  for k, v in pairs(override) do
    if type(v) == "table" and type(result[k]) == "table" then
      result[k] = M.deep_merge(result[k], v)
    else
      result[k] = v
    end
  end
  return result
end

-- Merge user config with defaults + optional preset
function M.merge(user_config, preset_name)
  local base = M.defaults
  if preset_name and M.presets[preset_name] then
    base = M.deep_merge(base, M.presets[preset_name])
  end
  return M.deep_merge(base, user_config or {})
end

return M
