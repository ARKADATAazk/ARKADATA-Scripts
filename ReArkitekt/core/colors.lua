-- ReArkitekt/core/colors.lua
-- Color manipulation and adaptive palette generation

local M = {}

-- ============================================================================
-- SECTION 1: Basic Color Operations
-- ============================================================================

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

function M.auto_text_color(bg_color)
  local lum = M.luminance(bg_color)
  return lum > 0.5 and 0x000000FF or 0xFFFFFFFF
end

-- ============================================================================
-- SECTION 1.5: Color Space Conversions
-- ============================================================================

function M.rgb_to_hsl(color)
  local r, g, b, a = M.rgba_to_components(color)
  r, g, b = r / 255, g / 255, b / 255
  
  local max_c = math.max(r, g, b)
  local min_c = math.min(r, g, b)
  local delta = max_c - min_c
  
  local h = 0
  local s = 0
  local l = (max_c + min_c) / 2
  
  if delta ~= 0 then
    s = (l > 0.5) and (delta / (2 - max_c - min_c)) or (delta / (max_c + min_c))
    
    if max_c == r then
      h = ((g - b) / delta + (g < b and 6 or 0)) / 6
    elseif max_c == g then
      h = ((b - r) / delta + 2) / 6
    else
      h = ((r - g) / delta + 4) / 6
    end
  end
  
  return h, s, l
end

function M.hsl_to_rgb(h, s, l)
  local function hue_to_rgb(p, q, t)
    if t < 0 then t = t + 1 end
    if t > 1 then t = t - 1 end
    if t < 1/6 then return p + (q - p) * 6 * t end
    if t < 1/2 then return q end
    if t < 2/3 then return p + (q - p) * (2/3 - t) * 6 end
    return p
  end
  
  local r, g, b
  
  if s == 0 then
    r, g, b = l, l, l
  else
    local q = l < 0.5 and l * (1 + s) or l + s - l * s
    local p = 2 * l - q
    r = hue_to_rgb(p, q, h + 1/3)
    g = hue_to_rgb(p, q, h)
    b = hue_to_rgb(p, q, h - 1/3)
  end
  
  return math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5)
end

local function _rgb_to_hsv(r, g, b)
  r, g, b = r / 255, g / 255, b / 255
  local maxv, minv = math.max(r, g, b), math.min(r, g, b)
  local d = maxv - minv
  local h = 0
  if d ~= 0 then
    if maxv == r then h = ((g - b) / d) % 6
    elseif maxv == g then h = (b - r) / d + 2
    else h = (r - g) / d + 4 end
    h = h / 6
  end
  local s = (maxv == 0) and 0 or (d / maxv)
  return h, s, maxv
end

local function _hsv_to_rgb(h, s, v)
  local i = math.floor(h * 6)
  local f = h * 6 - i
  local p = v * (1 - s)
  local q = v * (1 - f * s)
  local t = v * (1 - (1 - f) * s)
  local r, g, b =
    (i % 6 == 0 and v) or (i % 6 == 1 and q) or (i % 6 == 2 and p) or (i % 6 == 3 and p) or (i % 6 == 4 and t) or v,
    (i % 6 == 0 and t) or (i % 6 == 1 and v) or (i % 6 == 2 and v) or (i % 6 == 3 and q) or (i % 6 == 4 and p) or p,
    (i % 6 == 0 and p) or (i % 6 == 1 and p) or (i % 6 == 2 and t) or (i % 6 == 3 and v) or (i % 6 == 4 and v) or q
  return math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5)
end

-- ============================================================================
-- SECTION 1.6: Color Sorting Utilities
-- ============================================================================

function M.get_color_sort_key(color)
  if not color or color == 0 then
    return -1, 0, 0
  end
  
  local h, s, l = M.rgb_to_hsl(color)
  
  if s < 0.08 then
    return 999, l, s
  end
  
  local hue_degrees = h * 360
  
  return hue_degrees, s, l
end

function M.compare_colors(color_a, color_b)
  local h_a, s_a, l_a = M.get_color_sort_key(color_a)
  local h_b, s_b, l_b = M.get_color_sort_key(color_b)
  
  if math.abs(h_a - h_b) > 0.01 then
    return h_a < h_b
  end
  
  if math.abs(s_a - s_b) > 0.01 then
    return s_a > s_b
  end
  
  return l_a > l_b
end

-- ============================================================================
-- SECTION 2: Color Characteristics (for adaptive palettes)
-- ============================================================================

function M.analyze_color(color)
  local r, g, b, a = M.rgba_to_components(color)
  local max_ch = math.max(r, g, b)
  local min_ch = math.min(r, g, b)
  local lum = M.luminance(color)
  local saturation = (max_ch > 0) and ((max_ch - min_ch) / max_ch) or 0
  
  return {
    luminance = lum,
    saturation = saturation,
    max_channel = max_ch,
    min_channel = min_ch,
    is_bright = lum > 0.65,
    is_dark = lum < 0.3,
    is_gray = saturation < 0.15,
    is_vivid = saturation > 0.6,
  }
end

-- ============================================================================
-- SECTION 3: Derivation Strategies (how to transform colors)
-- ============================================================================

-- Normalize: Scale brightest channel to 255, maintaining color relationships
function M.derive_normalized(color, pullback)
  pullback = pullback or 0.95
  local r, g, b, a = M.rgba_to_components(color)
  local max_ch = math.max(r, g, b)
  
  if max_ch == 0 then return color end
  
  local boost = (255 / max_ch) * pullback
  return M.components_to_rgba(
    math.min(255, math.floor(r * boost)),
    math.min(255, math.floor(g * boost)),
    math.min(255, math.floor(b * boost)),
    a
  )
end

-- Brighten: Simple brightness multiplication
function M.derive_brightened(color, factor)
  return M.adjust_brightness(color, factor)
end

-- Saturate + Brighten: Increase color intensity
function M.derive_intensified(color, sat_boost, bright_boost)
  sat_boost = sat_boost or 0.3
  bright_boost = bright_boost or 1.2
  local saturated = M.saturate(color, sat_boost)
  return M.adjust_brightness(saturated, bright_boost)
end

-- Darken + Desaturate: Create muted background
function M.derive_muted(color, desat_amt, dark_amt)
  desat_amt = desat_amt or 0.5
  dark_amt = dark_amt or 0.45
  local desat = M.desaturate(color, desat_amt)
  return M.adjust_brightness(desat, dark_amt)
end

-- ============================================================================
-- SECTION 4: Role-Based Derivation (UI purposes)
-- ============================================================================

-- Derive fill color (tile background)
function M.derive_fill(base_color, opts)
  opts = opts or {}
  local desat = opts.desaturate or 0.5
  local bright = opts.brightness or 0.45
  local alpha = opts.alpha or 0xCC
  
  local color = M.desaturate(base_color, desat)
  color = M.adjust_brightness(color, bright)
  return M.with_alpha(color, alpha)
end

-- Derive border color (tile outline)
function M.derive_border(base_color, opts)
  opts = opts or {}
  local mode = opts.mode or 'normalize'
  
  if mode == 'normalize' then
    local pullback = opts.pullback or 0.95
    return M.derive_normalized(base_color, pullback)
    
  elseif mode == 'brighten' then
    local factor = opts.factor or 1.3
    return M.derive_brightened(base_color, factor)
    
  elseif mode == 'intensify' then
    local sat = opts.saturation or 0.3
    local bright = opts.brightness or 1.2
    return M.derive_intensified(base_color, sat, bright)
    
  elseif mode == 'muted' then
    local desat = opts.desaturate or 0.3
    local dark = opts.brightness or 0.6
    local color = M.desaturate(base_color, desat)
    return M.adjust_brightness(color, dark)
  end
  
  return base_color
end

-- Derive hover state color
function M.derive_hover(base_color, opts)
  opts = opts or {}
  local brightness = opts.brightness or 1.15
  return M.adjust_brightness(base_color, brightness)
end

-- Derive selection color (brightest, most prominent)
function M.derive_selection(base_color, opts)
  opts = opts or {}
  local brightness = opts.brightness or 1.6
  local saturation = opts.saturation or 0.5
  
  local r, g, b, a = M.rgba_to_components(base_color)
  local max_ch = math.max(r, g, b)
  local boost = (max_ch > 0) and (255 / max_ch) or 1
  
  r = math.min(255, math.floor(r * boost * brightness))
  g = math.min(255, math.floor(g * boost * brightness))
  b = math.min(255, math.floor(b * boost * brightness))
  
  local result = M.components_to_rgba(r, g, b, a)
  
  if saturation > 0 then
    result = M.saturate(result, saturation)
  end
  
  return result
end

-- Derive marching ants color (animated selection border)
function M.derive_marching_ants(base_color, opts)
  if not base_color or base_color == 0 then
    return 0x42E896FF
  end
  
  opts = opts or {}
  local brightness = opts.brightness or 1.5
  local saturation = opts.saturation or 0.5
  
  local r, g, b, a = M.rgba_to_components(base_color)
  local max_ch = math.max(r, g, b)
  
  if max_ch == 0 then
    return 0x42E896FF
  end
  
  local boost = 255 / max_ch
  r = math.min(255, math.floor(r * boost * brightness))
  g = math.min(255, math.floor(g * boost * brightness))
  b = math.min(255, math.floor(b * boost * brightness))
  
  if saturation > 0 then
    local gray = r * 0.299 + g * 0.587 + b * 0.114
    r = math.min(255, math.max(0, math.floor(r + (r - gray) * saturation)))
    g = math.min(255, math.max(0, math.floor(g + (g - gray) * saturation)))
    b = math.min(255, math.max(0, math.floor(b + (b - gray) * saturation)))
  end
  
  return M.components_to_rgba(r, g, b, 0xFF)
end

-- ============================================================================
-- SECTION 5: Palette Generation
-- ============================================================================

-- Generate complete palette from base color
function M.derive_palette(base_color, opts)
  opts = opts or {}
  
  return {
    base = base_color,
    fill = M.derive_fill(base_color, opts.fill),
    border = M.derive_border(base_color, opts.border),
    hover = M.derive_hover(base_color, opts.hover),
    selection = M.derive_selection(base_color, opts.selection),
    marching_ants = M.derive_marching_ants(base_color, opts.marching_ants),
    text = M.auto_text_color(base_color),
    dim = M.with_alpha(base_color, 0x88),
  }
end

-- Adaptive palette based on color characteristics
function M.derive_palette_adaptive(base_color, preset)
  preset = preset or 'auto'
  
  if preset == 'auto' then
    local info = M.analyze_color(base_color)
    
    if info.is_bright then
      preset = 'bright'
    elseif info.is_gray then
      preset = 'grayscale'
    elseif info.is_vivid then
      preset = 'vivid'
    else
      preset = 'normal'
    end
  end
  
  local presets = {
    bright = {
      fill = { desaturate = 0.7, brightness = 0.35, alpha = 0xCC },
      border = { mode = 'normalize', pullback = 0.85 },
      hover = { brightness = 1.1 },
      selection = { brightness = 1.4, saturation = 0.4 },
      marching_ants = { brightness = 1.3, saturation = 0.4 },
    },
    
    grayscale = {
      fill = { desaturate = 0.3, brightness = 0.5, alpha = 0xCC },
      border = { mode = 'brighten', factor = 1.4 },
      hover = { brightness = 1.2 },
      selection = { brightness = 1.8, saturation = 0.2 },
      marching_ants = { brightness = 1.6, saturation = 0.3 },
    },
    
    vivid = {
      fill = { desaturate = 0.6, brightness = 0.4, alpha = 0xCC },
      border = { mode = 'normalize', pullback = 0.95 },
      hover = { brightness = 1.15 },
      selection = { brightness = 1.6, saturation = 0.6 },
      marching_ants = { brightness = 1.5, saturation = 0.5 },
    },
    
    normal = {
      fill = { desaturate = 0.5, brightness = 0.45, alpha = 0xCC },
      border = { mode = 'normalize', pullback = 0.95 },
      hover = { brightness = 1.15 },
      selection = { brightness = 1.6, saturation = 0.5 },
      marching_ants = { brightness = 1.5, saturation = 0.5 },
    },
  }
  
  return M.derive_palette(base_color, presets[preset])
end

-- ============================================================================
-- SECTION 6: Legacy Compatibility Functions
-- ============================================================================

function M.generate_border(base_color, desaturate_amt, brightness_factor)
  return M.derive_border(base_color, {
    mode = 'muted',
    desaturate = desaturate_amt or 0.3,
    brightness = brightness_factor or 0.6,
  })
end

function M.generate_hover(base_color, brightness_factor)
  return M.derive_hover(base_color, { brightness = brightness_factor or 1.3 })
end

function M.generate_active_border(base_color, saturation_boost, brightness_boost)
  return M.derive_border(base_color, {
    mode = 'intensify',
    saturation = saturation_boost or 0.8,
    brightness = brightness_boost or 1.4,
  })
end

function M.generate_selection_color(base_color, brightness_boost, saturation_boost)
  return M.derive_selection(base_color, {
    brightness = brightness_boost or 1.6,
    saturation = saturation_boost or 0.5,
  })
end

function M.generate_marching_ants_color(base_color, brightness_factor, saturation_factor)
  return M.derive_marching_ants(base_color, {
    brightness = brightness_factor or 1.5,
    saturation = saturation_factor or 0.5,
  })
end

function M.auto_palette(base_color)
  return M.derive_palette(base_color)
end

function M.flashy_palette(base_color)
  return M.derive_palette(base_color, {
    fill = { desaturate = 0.5, brightness = 0.45, alpha = 0xCC },
    border = { mode = 'normalize', pullback = 0.95 },
  })
end

-- ============================================================================
-- SECTION 7: Hue-Preserving Helpers (for tile text)
-- ============================================================================

function M.same_hue_variant(col, s_mult, v_mult, new_a)
  local r = (col >> 24) & 0xFF
  local g = (col >> 16) & 0xFF
  local b = (col >> 8) & 0xFF
  local a = col & 0xFF
  local h, s, v = _rgb_to_hsv(r, g, b)
  s = math.max(0, math.min(1, s * (s_mult or 1)))
  v = math.max(0, math.min(1, v * (v_mult or 1)))
  local rr, gg, bb = _hsv_to_rgb(h, s, v)
  return (rr << 24) | (gg << 16) | (bb << 8) | (new_a or a)
end

function M.tile_text_colors(base_color)
  local accent = M.same_hue_variant(base_color, 1.25, 1.15, 0xFF)
  local name = 0xDDE3E9FF
  return accent, name
end

function M.tile_meta_color(name_color, alpha)
  alpha = alpha or 0xBB
  return M.with_alpha(name_color, alpha)
end

return M