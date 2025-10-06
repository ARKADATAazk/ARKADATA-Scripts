-- ReArkitekt/gui/fx/tile_fx.lua
-- Multi-layer tile rendering with granular controls

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.10'

local Colors = require('ReArkitekt.core.colors')

local M = {}

function M.render_base_fill(dl, x1, y1, x2, y2, rounding)
  local base_neutral = 0x0F0F0FFF
  ImGui.DrawList_AddRectFilled(dl, x1, y1, x2, y2, base_neutral, rounding)
end

function M.render_color_fill(dl, x1, y1, x2, y2, base_color, opacity, saturation, brightness, rounding)
  local r, g, b, _ = Colors.rgba_to_components(base_color)
  
  if saturation ~= 1.0 then
    local gray = r * 0.299 + g * 0.587 + b * 0.114
    r = math.floor(r + (gray - r) * (1 - saturation))
    g = math.floor(g + (gray - g) * (1 - saturation))
    b = math.floor(b + (gray - b) * (1 - saturation))
  end
  
  if brightness ~= 1.0 then
    r = math.min(255, math.max(0, math.floor(r * brightness)))
    g = math.min(255, math.max(0, math.floor(g * brightness)))
    b = math.min(255, math.max(0, math.floor(b * brightness)))
  end
  
  local alpha = math.floor(255 * opacity)
  local fill_color = Colors.components_to_rgba(r, g, b, alpha)
  ImGui.DrawList_AddRectFilled(dl, x1, y1, x2, y2, fill_color, rounding)
end

function M.render_gradient(dl, x1, y1, x2, y2, base_color, intensity, opacity, rounding)
  local r, g, b, _ = Colors.rgba_to_components(base_color)
  
  local boost_top = 1.0 + intensity
  local boost_bottom = 1.0 - (intensity * 0.4)
  
  local r_top = math.min(255, math.floor(r * boost_top))
  local g_top = math.min(255, math.floor(g * boost_top))
  local b_top = math.min(255, math.floor(b * boost_top))
  
  local r_bottom = math.max(0, math.floor(r * boost_bottom))
  local g_bottom = math.max(0, math.floor(g * boost_bottom))
  local b_bottom = math.max(0, math.floor(b * boost_bottom))
  
  local alpha = math.floor(255 * opacity)
  local color_top = Colors.components_to_rgba(r_top, g_top, b_top, alpha)
  local color_bottom = Colors.components_to_rgba(r_bottom, g_bottom, b_bottom, alpha)
  
  ImGui.DrawList_AddRectFilledMultiColor(dl, x1, y1, x2, y2, 
    color_top, color_top, color_bottom, color_bottom)
end

function M.render_specular(dl, x1, y1, x2, y2, base_color, strength, coverage, rounding)
  local height = y2 - y1
  local band_height = height * coverage
  local band_y2 = y1 + band_height
  
  local r, g, b, _ = Colors.rgba_to_components(base_color)
  
  local boost = 1.3
  local r_spec = math.min(255, math.floor(r * boost + 20))
  local g_spec = math.min(255, math.floor(g * boost + 20))
  local b_spec = math.min(255, math.floor(b * boost + 20))
  
  local alpha_top = math.floor(255 * strength * 0.6)
  local alpha_bottom = 0
  
  local color_top = Colors.components_to_rgba(r_spec, g_spec, b_spec, alpha_top)
  local color_bottom = Colors.components_to_rgba(r_spec, g_spec, b_spec, alpha_bottom)
  
  ImGui.DrawList_AddRectFilledMultiColor(dl, x1, y1, x2, band_y2,
    color_top, color_top, color_bottom, color_bottom)
end

function M.render_inner_shadow(dl, x1, y1, x2, y2, strength, rounding)
  local shadow_size = 2
  local shadow_alpha = math.floor(255 * strength * 0.4)
  local shadow_color = Colors.components_to_rgba(0, 0, 0, shadow_alpha)
  
  ImGui.DrawList_AddRectFilledMultiColor(dl, 
    x1, y1, x2, y1 + shadow_size,
    shadow_color, shadow_color,
    Colors.components_to_rgba(0, 0, 0, 0), Colors.components_to_rgba(0, 0, 0, 0))
  
  ImGui.DrawList_AddRectFilledMultiColor(dl,
    x1, y1, x1 + shadow_size, y2,
    shadow_color, Colors.components_to_rgba(0, 0, 0, 0),
    Colors.components_to_rgba(0, 0, 0, 0), shadow_color)
end

function M.render_playback_progress(dl, x1, y1, x2, y2, base_color, progress, fade_alpha, rounding)
  if progress <= 0 or fade_alpha <= 0 then return end
  
  local width = x2 - x1
  local progress_width = width * progress
  local progress_x = x1 + progress_width
  
  local r, g, b, _ = Colors.rgba_to_components(base_color)
  
  local brightness = 1.15
  r = math.min(255, math.floor(r * brightness))
  g = math.min(255, math.floor(g * brightness))
  b = math.min(255, math.floor(b * brightness))
  
  local base_alpha = 0x40
  local alpha = math.floor(base_alpha * fade_alpha)
  local progress_color = Colors.components_to_rgba(r, g, b, alpha)
  
  ImGui.DrawList_AddRectFilled(dl, x1, y1, progress_x, y2, progress_color, rounding)
  
  local base_bar_alpha = 0xAA
  local bar_alpha = math.floor(base_bar_alpha * fade_alpha)
  local bar_color = Colors.components_to_rgba(r, g, b, bar_alpha)
  local bar_thickness = 1
  
  local height = y2 - y1
  local inset = math.min(rounding * 0.5, 2)
  
  ImGui.DrawList_AddLine(dl, progress_x, y1 + inset, progress_x, y2 - inset, bar_color, bar_thickness)
end

function M.render_border(dl, x1, y1, x2, y2, base_color, saturation, brightness, opacity, thickness, rounding, is_selected, glow_strength, glow_layers)
  local alpha = math.floor(255 * opacity)
  local border_color = Colors.same_hue_variant(base_color, saturation, brightness, alpha)
  
  if is_selected and glow_layers > 0 then
    local r, g, b, _ = Colors.rgba_to_components(border_color)
    for i = glow_layers, 1, -1 do
      local glow_alpha = math.floor(glow_strength * 30 / i)
      local glow_color = Colors.components_to_rgba(r, g, b, glow_alpha)
      ImGui.DrawList_AddRect(dl, x1 - i, y1 - i, x2 + i, y2 + i, glow_color, rounding, 0, thickness)
    end
  end
  
  ImGui.DrawList_AddRect(dl, x1, y1, x2, y2, border_color, rounding, 0, thickness)
end

function M.render_complete(dl, x1, y1, x2, y2, base_color, config, is_selected, hover_factor, playback_progress, playback_fade)
  hover_factor = hover_factor or 0
  playback_progress = playback_progress or 0
  playback_fade = playback_fade or 0
  
  local fill_opacity = config.fill_opacity + (hover_factor * config.hover_fill_boost)
  local specular_strength = config.specular_strength * (1 + hover_factor * config.hover_specular_boost)
  
  M.render_base_fill(dl, x1, y1, x2, y2, config.rounding or 6)
  
  if playback_progress > 0 and playback_fade > 0 then
    M.render_playback_progress(dl, x1, y1, x2, y2, base_color, playback_progress, playback_fade, config.rounding or 6)
  end
  
  M.render_color_fill(dl, x1, y1, x2, y2, base_color, fill_opacity, config.fill_saturation, config.fill_brightness, config.rounding or 6)
  M.render_gradient(dl, x1, y1, x2, y2, base_color, config.gradient_intensity, config.gradient_opacity, config.rounding or 6)
  M.render_specular(dl, x1, y1, x2, y2, base_color, specular_strength, config.specular_coverage, config.rounding or 6)
  M.render_inner_shadow(dl, x1, y1, x2, y2, config.inner_shadow_strength, config.rounding or 6)
  
  if not (is_selected and config.ants_enabled and config.ants_replace_border) then
    M.render_border(dl, x1, y1, x2, y2, base_color, config.border_saturation, config.border_brightness, config.border_opacity, 
      config.border_thickness, config.rounding or 6, is_selected, config.glow_strength, config.glow_layers)
  end
end

return M