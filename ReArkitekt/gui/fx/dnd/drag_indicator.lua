-- ReArkitekt/gui/widgets/tiles/ghost_tiles.lua
-- Modular drag ghost visualization system with color support
-- Now supports copy vs move mode distinction

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'
local Draw = require('ReArkitekt.gui.draw')

local M = {}

local DEFAULTS = {
  tile = {
    width = 60,
    height = 40,
    base_fill = 0x1A1A1AFF,
    base_stroke = 0x42E896FF,
    stroke_thickness = 1.5,
    rounding = 4,
    inner_glow = {
      enabled = false,
      color = 0x42E89622,
      thickness = 2,
    },
    global_opacity = 0.70,
  },
  stack = {
    max_visible = 3,
    offset_x = 3,
    offset_y = 3,
    scale_factor = 0.94,
    opacity_falloff = 0.70,
  },
  shadow = {
    enabled = false,
    layers = 2,
    base_color = 0x00000044,
    offset = 2,
    blur_spread = 1.0,
  },
  badge = {
    bg = 0x1A1A1AEE,
    text = 0xFFFFFFFF,
    border_color = 0x00000099,
    border_thickness = 1,
    rounding = 6,
    padding_x = 6,
    padding_y = 3,
    offset_x = 35,
    offset_y = -35,
    min_width = 20,
    min_height = 18,
    shadow = {
      enabled = true,
      color = 0x00000099,
      offset = 2,
    },
  },
  copy_mode = {
    stroke_color = 0x9C87E8FF,
    glow_color = 0x9C87E833,
    badge_accent = 0x9C87E8FF,
    indicator_text = "+",
    indicator_color = 0x9C87E8FF,
  },
  move_mode = {
    stroke_color = 0x42E896FF,
    glow_color = 0x42E89633,
    badge_accent = 0x42E896FF,
  },
  delete_mode = {
    stroke_color = 0xE84A4AFF,
    glow_color = 0xE84A4A33,
    badge_accent = 0xE84A4AFF,
    indicator_text = "-",
    indicator_color = 0xE84A4AFF,
  },
}

local function apply_alpha_to_color(color, alpha_factor)
  local current_alpha = color & 0xFF
  local new_alpha = math.floor(current_alpha * alpha_factor)
  new_alpha = math.min(255, math.max(0, new_alpha))
  return (color & 0xFFFFFF00) | new_alpha
end

local function brighten_color(color, factor)
  factor = math.min(2.0, math.max(0.0, factor))
  
  local r = (color >> 24) & 0xFF
  local g = (color >> 16) & 0xFF
  local b = (color >> 8) & 0xFF
  local a = color & 0xFF
  
  r = math.min(255, math.floor(r * factor))
  g = math.min(255, math.floor(g * factor))
  b = math.min(255, math.floor(b * factor))
  
  return (r << 24) | (g << 16) | (b << 8) | a
end

local function draw_shadow(dl, x1, y1, x2, y2, rounding, config)
  if not config or not config.enabled then return end
  
  local shadow_cfg = config or DEFAULTS.shadow
  local layers = shadow_cfg.layers or DEFAULTS.shadow.layers
  local base_color = shadow_cfg.base_color or DEFAULTS.shadow.base_color
  local offset = shadow_cfg.offset or DEFAULTS.shadow.offset
  local blur_spread = shadow_cfg.blur_spread or DEFAULTS.shadow.blur_spread
  
  local base_alpha = base_color & 0xFF
  
  for i = layers, 1, -1 do
    local t = i / layers
    local o = offset * t
    local spread = blur_spread * t
    local alpha = math.floor(base_alpha * (1 - t * 0.5))
    local color = (base_color & 0xFFFFFF00) | alpha
    
    ImGui.DrawList_AddRectFilled(dl, 
      x1 + o - spread, y1 + o - spread, 
      x2 + o + spread, y2 + o + spread, 
      color, rounding)
  end
end

local function draw_tile(dl, x, y, w, h, fill, stroke, thickness, rounding, inner_glow_cfg)
  ImGui.DrawList_AddRectFilled(dl, x, y, x + w, y + h, fill, rounding)
  
  if inner_glow_cfg and inner_glow_cfg.enabled then
    local glow_color = inner_glow_cfg.color or DEFAULTS.tile.inner_glow.color
    local glow_thick = inner_glow_cfg.thickness or DEFAULTS.tile.inner_glow.thickness
    
    for i = 1, glow_thick do
      local inset = i
      ImGui.DrawList_AddRect(dl, x + inset, y + inset, x + w - inset, y + h - inset, 
                            glow_color, rounding - inset, 0, 1)
    end
  end
  
  ImGui.DrawList_AddRect(dl, x, y, x + w, y + h, stroke, rounding, 0, thickness)
end

local function draw_copy_indicator(ctx, dl, mx, my, config)
  local copy_cfg = (config and config.copy_mode) or DEFAULTS.copy_mode
  local indicator_text = copy_cfg.indicator_text or DEFAULTS.copy_mode.indicator_text
  local indicator_color = copy_cfg.indicator_color or DEFAULTS.copy_mode.indicator_color
  
  local size = 24
  local ix = mx - size - 20
  local iy = my - size / 2
  
  ImGui.DrawList_AddCircleFilled(dl, ix + size/2, iy + size/2, size/2, 0x1A1A1AEE)
  
  ImGui.DrawList_AddCircle(dl, ix + size/2, iy + size/2, size/2, indicator_color, 0, 2)
  
  local tw, th = ImGui.CalcTextSize(ctx, indicator_text)
  Draw.text(dl, ix + (size - tw)/2, iy + (size - th)/2, indicator_color, indicator_text)
end

local function draw_delete_indicator(ctx, dl, mx, my, config)
  local delete_cfg = (config and config.delete_mode) or DEFAULTS.delete_mode
  local indicator_text = delete_cfg.indicator_text or DEFAULTS.delete_mode.indicator_text
  local indicator_color = delete_cfg.indicator_color or DEFAULTS.delete_mode.indicator_color
  
  local size = 24
  local ix = mx - size - 20
  local iy = my - size / 2
  
  ImGui.DrawList_AddCircleFilled(dl, ix + size/2, iy + size/2, size/2, 0x1A1A1AEE)
  
  ImGui.DrawList_AddCircle(dl, ix + size/2, iy + size/2, size/2, indicator_color, 0, 2)
  
  local tw, th = ImGui.CalcTextSize(ctx, indicator_text)
  Draw.text(dl, ix + (size - tw)/2, iy + (size - th)/2, indicator_color, indicator_text)
end

function M.draw_badge(ctx, dl, mx, my, count, config, is_copy_mode, is_delete_mode)
  if count <= 1 then return end
  
  local cfg = config or DEFAULTS.badge
  local mode_cfg
  if is_delete_mode then
    mode_cfg = (config and config.delete_mode) or DEFAULTS.delete_mode
  elseif is_copy_mode then
    mode_cfg = (config and config.copy_mode) or DEFAULTS.copy_mode
  else
    mode_cfg = (config and config.move_mode) or DEFAULTS.move_mode
  end
  
  local label = tostring(count)
  local tw, th = ImGui.CalcTextSize(ctx, label)
  
  local pad_x = cfg.padding_x or DEFAULTS.badge.padding_x
  local pad_y = cfg.padding_y or DEFAULTS.badge.padding_y
  local min_w = cfg.min_width or DEFAULTS.badge.min_width
  local min_h = cfg.min_height or DEFAULTS.badge.min_height
  local offset_x = cfg.offset_x or DEFAULTS.badge.offset_x
  local offset_y = cfg.offset_y or DEFAULTS.badge.offset_y
  
  local badge_w = math.max(min_w, tw + pad_x * 2)
  local badge_h = math.max(min_h, th + pad_y * 2)
  
  local bx = mx + offset_x
  local by = my + offset_y
  
  local rounding = cfg.rounding or DEFAULTS.badge.rounding
  
  if cfg.shadow and cfg.shadow.enabled then
    local shadow_offset = cfg.shadow.offset or DEFAULTS.badge.shadow.offset
    local shadow_color = cfg.shadow.color or DEFAULTS.badge.shadow.color
    ImGui.DrawList_AddRectFilled(dl, 
      bx + shadow_offset, by + shadow_offset, 
      bx + badge_w + shadow_offset, by + badge_h + shadow_offset, 
      shadow_color, rounding)
  end
  
  local bg = cfg.bg or DEFAULTS.badge.bg
  ImGui.DrawList_AddRectFilled(dl, bx, by, bx + badge_w, by + badge_h, bg, rounding)
  
  local border_color = cfg.border_color or DEFAULTS.badge.border_color
  local border_thickness = cfg.border_thickness or DEFAULTS.badge.border_thickness
  ImGui.DrawList_AddRect(dl, bx + 0.5, by + 0.5, bx + badge_w - 0.5, by + badge_h - 0.5, 
                        border_color, rounding, 0, border_thickness)
  
  local accent_color = mode_cfg.badge_accent or DEFAULTS.move_mode.badge_accent
  local accent_thickness = 2
  ImGui.DrawList_AddRect(dl, bx + 1, by + 1, bx + badge_w - 1, by + badge_h - 1, 
                        accent_color, rounding - 1, 0, accent_thickness)
  
  local text_x = bx + (badge_w - tw) / 2
  local text_y = by + (badge_h - th) / 2
  ImGui.DrawList_AddText(dl, text_x, text_y, accent_color, label)
end

function M.draw(ctx, dl, mx, my, count, config, colors, is_copy_mode, is_delete_mode)
  local tile_cfg = (config and config.tile) or DEFAULTS.tile
  local stack_cfg = (config and config.stack) or DEFAULTS.stack
  local shadow_cfg = (config and config.shadow) or DEFAULTS.shadow
  
  local mode_cfg
  if is_delete_mode then
    mode_cfg = (config and config.delete_mode) or DEFAULTS.delete_mode
  elseif is_copy_mode then
    mode_cfg = (config and config.copy_mode) or DEFAULTS.copy_mode
  else
    mode_cfg = (config and config.move_mode) or DEFAULTS.move_mode
  end
  
  local base_w = tile_cfg.width or DEFAULTS.tile.width
  local base_h = tile_cfg.height or DEFAULTS.tile.height
  local base_fill = tile_cfg.base_fill or DEFAULTS.tile.base_fill
  local base_stroke = mode_cfg.stroke_color or DEFAULTS.move_mode.stroke_color
  local thickness = tile_cfg.stroke_thickness or DEFAULTS.tile.stroke_thickness
  local rounding = tile_cfg.rounding or DEFAULTS.tile.rounding
  local inner_glow = tile_cfg.inner_glow or DEFAULTS.tile.inner_glow
  local global_opacity = tile_cfg.global_opacity or DEFAULTS.tile.global_opacity
  
  local max_visible = stack_cfg.max_visible or DEFAULTS.stack.max_visible
  local offset_x = stack_cfg.offset_x or DEFAULTS.stack.offset_x
  local offset_y = stack_cfg.offset_y or DEFAULTS.stack.offset_y
  local scale_factor = stack_cfg.scale_factor or DEFAULTS.stack.scale_factor
  local opacity_falloff = stack_cfg.opacity_falloff or DEFAULTS.stack.opacity_falloff
  
  local visible_count = math.min(count, max_visible)
  
  if count == 1 then
    local x = mx - base_w / 2
    local y = my - base_h / 2
    
    local fill_color = (colors and colors[1]) or base_fill
    local stroke_color = base_stroke
    
    fill_color = apply_alpha_to_color(fill_color, global_opacity)
    stroke_color = apply_alpha_to_color(stroke_color, global_opacity)
    
    draw_shadow(dl, x, y, x + base_w, y + base_h, rounding, shadow_cfg)
    draw_tile(dl, x, y, base_w, base_h, fill_color, stroke_color, thickness, rounding, inner_glow)
  else
    for i = visible_count, 1, -1 do
      local scale = scale_factor ^ (visible_count - i)
      local w = base_w * scale
      local h = base_h * scale
      
      local ox = (i - 1) * offset_x
      local oy = (i - 1) * offset_y
      
      local x = mx - w / 2 + ox
      local y = my - h / 2 + oy
      
      if i == visible_count then
        draw_shadow(dl, x, y, x + w, y + h, rounding * scale, shadow_cfg)
      end
      
      local color_index = math.min(i, colors and #colors or 0)
      local item_fill = (colors and colors[color_index]) or base_fill
      local item_stroke = base_stroke
      
      local opacity_factor = 1.0 - ((visible_count - i) / visible_count) * opacity_falloff
      opacity_factor = opacity_factor * global_opacity
      
      local tile_fill = apply_alpha_to_color(item_fill, opacity_factor)
      local tile_stroke = apply_alpha_to_color(item_stroke, opacity_factor)
      
      draw_tile(dl, x, y, w, h, tile_fill, tile_stroke, thickness, rounding * scale, inner_glow)
    end
    
    M.draw_badge(ctx, dl, mx, my, count, config and config.badge or nil, is_copy_mode, is_delete_mode)
  end
  
  if is_delete_mode then
    draw_delete_indicator(ctx, dl, mx, my, config)
  elseif is_copy_mode then
    draw_copy_indicator(ctx, dl, mx, my, config)
  end
end

return M