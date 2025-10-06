-- ReArkitekt/gui/fx/tile_fx_config.lua
-- Granular tile visual configuration

local M = {}

M.DEFAULT = {
  -- Fill layer
  fill_opacity = 0.4,
  fill_saturation = 0.4,
  fill_brightness = 0.5,
  
  -- Border
  border_opacity = 1.0,
  border_saturation = 1,
  border_brightness = 1.6,
  border_thickness = 1.0,
  
  -- Index number (#1, #2, etc.) - region-colored
  index_saturation = 1,
  index_brightness = 1.6,
  
  -- Separator bullet (•) - region-colored
  separator_saturation = 1,
  separator_brightness = 1.6,
  separator_alpha = 0x99,
  
  -- Region name text - neutral white/gray (brightness adjusts the base neutral color)
  name_brightness = 1.0,
  name_base_color = 0xDDE3E9FF,
  
  -- Duration/bars text - region-colored
  duration_saturation = 0.3,
  duration_brightness = 1,
  duration_alpha = 0x88,
  
  -- Gradient
  gradient_intensity = 0.16,
  gradient_opacity = 0.03,
  
  -- Specular
  specular_strength = 0.06,
  specular_coverage = 0.25,
  
  -- Inner shadow
  inner_shadow_strength = 0.20,
  
  -- Marching ants (uses border_saturation and border_brightness for color)
  ants_enabled = true,
  ants_replace_border = true,
  ants_thickness = 1.5,
  ants_dash = 8,
  ants_gap = 6,
  ants_speed = 20,
  ants_inset = 0.5,
  ants_alpha = 0xFF,
  
  -- Selection glow
  glow_strength = 0.4,
  glow_layers = 3,
  
  -- Hover
  hover_fill_boost = 0.06,
  hover_specular_boost = 0.5,
}

function M.get()
  return M.DEFAULT
end

function M.override(overrides)
  local config = {}
  for k, v in pairs(M.DEFAULT) do
    config[k] = overrides[k] or v
  end
  return config
end

return M