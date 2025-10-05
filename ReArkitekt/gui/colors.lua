-- ReArkitekt/gui/colors.lua
-- Color manipulation and palette generation helpers

local M = {}

function M.rgba_to_components(color)
  local r = (color >> 24) & 0xFF
  local g = (color >> 16) & 0xFF
  local b = (color >> 8) & 0xFF
  local a = color & 0xFF
  return r, g, b, a
end

function M.components_to_rgba(r, g, b, a)
  return (r << 24) | (g << 16) | (b << 8) | a
end

function M.with_alpha(color, alpha)
  return (color & 0xFFFFFF00) | (alpha & 0xFF)
end

function M.adjust_brightness(color, factor)
  local r, g, b, a = M.rgba_to_components(color)
  r = math.min(255, math.max(0, math.floor(r * factor)))
  g = math.min(255, math.max(0, math.floor(g * factor)))
  b = math.min(255, math.max(0, math.floor(b * factor)))
  return M.components_to_rgba(r, g, b, a)
end

function M.desaturate(color, amount)
  local r, g, b, a = M.rgba_to_components(color)
  local gray = r * 0.299 + g * 0.587 + b * 0.114
  r = math.floor(r + (gray - r) * amount)
  g = math.floor(g + (gray - g) * amount)
  b = math.floor(b + (gray - b) * amount)
  return M.components_to_rgba(r, g, b, a)
end

function M.saturate(color, amount)
  return M.desaturate(color, -amount)
end

function M.luminance(color)
  local r, g, b, _ = M.rgba_to_components(color)
  return (0.299 * r + 0.587 * g + 0.114 * b) / 255
end

function M.generate_border(base_color, desaturate_amt, brightness_factor)
  desaturate_amt = desaturate_amt or 0.3
  brightness_factor = brightness_factor or 0.6
  local desat = M.desaturate(base_color, desaturate_amt)
  return M.adjust_brightness(desat, brightness_factor)
end

function M.generate_hover(base_color, brightness_factor)
  brightness_factor = brightness_factor or 1.3
  return M.adjust_brightness(base_color, brightness_factor)
end

function M.generate_active_border(base_color, saturation_boost, brightness_boost)
  saturation_boost = saturation_boost or 0.8
  brightness_boost = brightness_boost or 1.4
  local desat = M.desaturate(base_color, -saturation_boost)
  return M.adjust_brightness(desat, brightness_boost)
end

function M.generate_selection_color(base_color, brightness_boost, saturation_boost)
  brightness_boost = brightness_boost or 1.6
  saturation_boost = saturation_boost or 0.5
  
  local r, g, b, a = M.rgba_to_components(base_color)
  
  local max_channel = math.max(r, g, b)
  local boost = 255 / (max_channel > 0 and max_channel or 1)
  
  local bright_r = math.min(255, math.floor(r * boost * brightness_boost))
  local bright_g = math.min(255, math.floor(g * boost * brightness_boost))
  local bright_b = math.min(255, math.floor(b * boost * brightness_boost))
  
  local result = M.components_to_rgba(bright_r, bright_g, bright_b, a)
  
  if saturation_boost > 0 then
    result = M.saturate(result, saturation_boost)
  end
  
  return result
end

function M.generate_marching_ants_color(base_color, brightness_factor, saturation_factor)
  if not base_color or base_color == 0 then
    return 0x42E896FF
  end
  
  brightness_factor = brightness_factor or 1.5
  saturation_factor = saturation_factor or 0.5
  
  local r, g, b, a = M.rgba_to_components(base_color)
  
  local max_channel = math.max(r, g, b)
  if max_channel == 0 then
    return 0x42E896FF
  end
  
  local boost = 255 / max_channel
  
  r = math.min(255, math.floor(r * boost))
  g = math.min(255, math.floor(g * boost))
  b = math.min(255, math.floor(b * boost))
  
  r = math.min(255, math.floor(r * brightness_factor))
  g = math.min(255, math.floor(g * brightness_factor))
  b = math.min(255, math.floor(b * brightness_factor))
  
  if saturation_factor > 0 then
    local gray = r * 0.299 + g * 0.587 + b * 0.114
    r = math.min(255, math.max(0, math.floor(r + (r - gray) * saturation_factor)))
    g = math.min(255, math.max(0, math.floor(g + (g - gray) * saturation_factor)))
    b = math.min(255, math.max(0, math.floor(b + (b - gray) * saturation_factor)))
  end
  
  return M.components_to_rgba(r, g, b, 0xFF)
end

function M.auto_text_color(bg_color)
  local lum = M.luminance(bg_color)
  return lum > 0.5 and 0x000000FF or 0xFFFFFFFF
end

function M.lerp_component(a, b, t)
  return math.floor(a + (b - a) * t + 0.5)
end

function M.lerp(color_a, color_b, t)
  local r1, g1, b1, a1 = M.rgba_to_components(color_a)
  local r2, g2, b2, a2 = M.rgba_to_components(color_b)
  
  local r = M.lerp_component(r1, r2, t)
  local g = M.lerp_component(g1, g2, t)
  local b = M.lerp_component(b1, b2, t)
  local a = M.lerp_component(a1, a2, t)
  
  return M.components_to_rgba(r, g, b, a)
end

function M.auto_palette(base_color)
  return {
    base = base_color,
    border = M.generate_border(base_color),
    hover = M.generate_hover(base_color),
    active_border = M.generate_active_border(base_color),
    selection = M.generate_selection_color(base_color),
    marching_ants = M.generate_marching_ants_color(base_color),
    text = M.auto_text_color(base_color),
    dim = M.with_alpha(base_color, 0x88),
  }
end

function M.flashy_palette(base_color)
  local r, g, b, a = M.rgba_to_components(base_color)
  
  local max_channel = math.max(r, g, b)
  local boost = 255 / (max_channel > 0 and max_channel or 1)
  
  local border_r = math.min(255, math.floor(r * boost * 0.95))
  local border_g = math.min(255, math.floor(g * boost * 0.95))
  local border_b = math.min(255, math.floor(b * boost * 0.95))
  local flashy_border = M.components_to_rgba(border_r, border_g, border_b, 0xFF)
  
  local desat = M.desaturate(base_color, 0.5)
  local darkened = M.adjust_brightness(desat, 0.45)
  local fill = M.with_alpha(darkened, 0xCC)
  
  return {
    base = fill,
    border = flashy_border,
    hover = M.adjust_brightness(fill, 1.2),
    selection = M.generate_selection_color(base_color),
    marching_ants = M.generate_marching_ants_color(base_color),
    text = flashy_border,
    dim = M.with_alpha(fill, 0x66),
  }
end

return M