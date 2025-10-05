-- ReArkitekt/gui/widgets/grid/rendering.lua
-- Generic tile rendering helpers for grid widgets

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local Draw = require('ReArkitekt.gui.draw')
local Colors = require('ReArkitekt.gui.colors')
local Effects = require('ReArkitekt.gui.effects')

local M = {}

M.TileHelpers = {}

local DEFAULTS = {
  hover_shadow = {
    enabled = true,
    max_offset = 2,
    max_alpha = 20,
  },
  selection = {
    ant_speed = 20,
    ant_dash = 8,
    ant_gap = 6,
    brightness_factor = 1.5,
    saturation_factor = 0.5,
  },
}

function M.TileHelpers.render_hover_shadow(dl, x1, y1, x2, y2, hover_factor, rounding, config)
  config = config or DEFAULTS.hover_shadow
  if not config.enabled or hover_factor < 0.01 then return end
  
  local shadow_alpha = math.floor(hover_factor * (config.max_alpha or 20))
  local shadow_col = (0x000000 << 8) | shadow_alpha
  
  for i = (config.max_offset or 2), 1, -1 do
    Draw.rect_filled(dl, x1 - i, y1 - i + 2, x2 + i, y2 + i + 2, shadow_col, rounding)
  end
end

function M.TileHelpers.render_border(dl, x1, y1, x2, y2, is_selected, base_color, border_color, thickness, rounding, config)
  config = config or DEFAULTS.selection
  
  if is_selected then
    local ant_color = Colors.generate_marching_ants_color(
      base_color,
      config.brightness_factor or 1.5,
      config.saturation_factor or 0.5
    )
    
    Effects.marching_ants_rounded(
      dl, x1 + 0.5, y1 + 0.5, x2 - 0.5, y2 - 0.5,
      ant_color, thickness, rounding,
      config.ant_dash or 8, config.ant_gap or 6, config.ant_speed or 20
    )
  else
    Draw.rect(dl, x1, y1, x2, y2, border_color, rounding, thickness)
  end
end

function M.TileHelpers.compute_border_color(base_color, is_hovered, is_active, hover_factor, hover_lerp)
  local r, g, b, a = Colors.rgba_to_components(base_color)
  local max_channel = math.max(r, g, b)
  local boost = 255 / (max_channel > 0 and max_channel or 1)
  
  local border_r = math.min(255, math.floor(r * boost * 0.95))
  local border_g = math.min(255, math.floor(g * boost * 0.95))
  local border_b = math.min(255, math.floor(b * boost * 0.95))
  local flashy_border = Colors.components_to_rgba(border_r, border_g, border_b, 0xFF)
  
  if is_hovered and hover_factor and hover_lerp then
    local selection_color = Colors.generate_selection_color(base_color)
    return Colors.lerp(flashy_border, selection_color, hover_factor * hover_lerp)
  end
  
  return flashy_border
end

function M.TileHelpers.compute_fill_color(base_color, hover_factor, hover_config)
  local desat_amount = hover_config and hover_config.base_fill_desaturation or 0.5
  local bright_amount = hover_config and hover_config.base_fill_brightness or 0.45
  local fill_alpha = hover_config and hover_config.base_fill_alpha or 0xCC
  
  local desat = Colors.desaturate(base_color, desat_amount)
  local darkened = Colors.adjust_brightness(desat, bright_amount)
  local base_fill = Colors.with_alpha(darkened, fill_alpha)
  
  if hover_factor and hover_factor > 0 then
    local hover_brightness = hover_config and hover_config.hover_brightness_factor or 0.65
    local hover_fill = Colors.adjust_brightness(base_fill, hover_brightness)
    return Colors.lerp(base_fill, hover_fill, hover_factor)
  end
  
  return base_fill
end

return M