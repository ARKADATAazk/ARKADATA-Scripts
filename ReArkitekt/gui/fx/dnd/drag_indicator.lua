-- ReArkitekt/gui/fx/dnd/drag_indicator.lua
-- Modular drag ghost visualization system (uses your existing colors.lua)

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'
local Draw = require('ReArkitekt.gui.draw')
local Colors = require('ReArkitekt.core.colors')
local DndConfig = require('ReArkitekt.gui.fx.dnd.config')

local M = {}

local function apply_alpha_factor(color, factor)
  local current_alpha = color & 0xFF
  local new_alpha = math.floor(current_alpha * factor)
  return Colors.with_alpha(color, math.min(255, math.max(0, new_alpha)))
end

local function draw_shadow(dl, x1, y1, x2, y2, rounding, config)
  if not config or not config.enabled then return end
  
  local shadow_cfg = config or DndConfig.SHADOW_DEFAULTS
  local layers = shadow_cfg.layers or DndConfig.SHADOW_DEFAULTS.layers
  local base_color = shadow_cfg.base_color or DndConfig.SHADOW_DEFAULTS.base_color
  local offset = shadow_cfg.offset or DndConfig.SHADOW_DEFAULTS.offset
  local blur_spread = shadow_cfg.blur_spread or DndConfig.SHADOW_DEFAULTS.blur_spread
  
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
    local glow_color = inner_glow_cfg.color or DndConfig.INNER_GLOW_DEFAULTS.color
    local glow_thick = inner_glow_cfg.thickness or DndConfig.INNER_GLOW_DEFAULTS.thickness
    
    for i = 1, glow_thick do
      local inset = i
      ImGui.DrawList_AddRect(dl, x + inset, y + inset, x + w - inset, y + h - inset, 
                            glow_color, rounding - inset, 0, 1)
    end
  end
  
  ImGui.DrawList_AddRect(dl, x, y, x + w, y + h, stroke, rounding, 0, thickness)
end

local function draw_copy_indicator(ctx, dl, mx, my, config)
  local copy_cfg = (config and config.copy_mode) or DndConfig.MODES.copy
  local indicator_text = copy_cfg.indicator_text or DndConfig.MODES.copy.indicator_text
  local indicator_color = copy_cfg.indicator_color or DndConfig.MODES.copy.indicator_color
  
  local size = 24
  local ix = mx - size - 20
  local iy = my - size / 2
  
  ImGui.DrawList_AddCircleFilled(dl, ix + size/2, iy + size/2, size/2, 0x1A1A1AEE)
  ImGui.DrawList_AddCircle(dl, ix + size/2, iy + size/2, size/2, indicator_color, 0, 2)
  
  local tw, th = ImGui.CalcTextSize(ctx, indicator_text)
  Draw.text(dl, ix + (size - tw)/2, iy + (size - th)/2, indicator_color, indicator_text)
end

local function draw_delete_indicator(ctx, dl, mx, my, config)
  local delete_cfg = (config and config.delete_mode) or DndConfig.MODES.delete
  local indicator_text = delete_cfg.indicator_text or DndConfig.MODES.delete.indicator_text
  local indicator_color = delete_cfg.indicator_color or DndConfig.MODES.delete.indicator_color
  
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
  
  local cfg = config or DndConfig.BADGE_DEFAULTS
  local mode_cfg = DndConfig.get_mode_config(config, is_copy_mode, is_delete_mode)
  
  local label = tostring(count)
  local tw, th = ImGui.CalcTextSize(ctx, label)
  
  local pad_x = cfg.padding_x or DndConfig.BADGE_DEFAULTS.padding_x
  local pad_y = cfg.padding_y or DndConfig.BADGE_DEFAULTS.padding_y
  local min_w = cfg.min_width or DndConfig.BADGE_DEFAULTS.min_width
  local min_h = cfg.min_height or DndConfig.BADGE_DEFAULTS.min_height
  local offset_x = cfg.offset_x or DndConfig.BADGE_DEFAULTS.offset_x
  local offset_y = cfg.offset_y or DndConfig.BADGE_DEFAULTS.offset_y
  
  local badge_w = math.max(min_w, tw + pad_x * 2)
  local badge_h = math.max(min_h, th + pad_y * 2)
  
  local bx = mx + offset_x
  local by = my + offset_y
  
  local rounding = cfg.rounding or DndConfig.BADGE_DEFAULTS.rounding
  
  if cfg.shadow and cfg.shadow.enabled then
    local shadow_offset = cfg.shadow.offset or 2
    local shadow_color = cfg.shadow.color or 0x00000099
    ImGui.DrawList_AddRectFilled(dl, 
      bx + shadow_offset, by + shadow_offset, 
      bx + badge_w + shadow_offset, by + badge_h + shadow_offset, 
      shadow_color, rounding)
  end
  
  local bg = cfg.bg or DndConfig.BADGE_DEFAULTS.bg
  ImGui.DrawList_AddRectFilled(dl, bx, by, bx + badge_w, by + badge_h, bg, rounding)
  
  local border_color = cfg.border_color or DndConfig.BADGE_DEFAULTS.border_color
  local border_thickness = cfg.border_thickness or DndConfig.BADGE_DEFAULTS.border_thickness
  ImGui.DrawList_AddRect(dl, bx + 0.5, by + 0.5, bx + badge_w - 0.5, by + badge_h - 0.5, 
                        border_color, rounding, 0, border_thickness)
  
  local accent_color = mode_cfg.badge_accent or DndConfig.MODES.move.badge_accent
  local accent_thickness = 2
  ImGui.DrawList_AddRect(dl, bx + 1, by + 1, bx + badge_w - 1, by + badge_h - 1, 
                        accent_color, rounding - 1, 0, accent_thickness)
  
  local text_x = bx + (badge_w - tw) / 2
  local text_y = by + (badge_h - th) / 2
  ImGui.DrawList_AddText(dl, text_x, text_y, accent_color, label)
end

function M.draw(ctx, dl, mx, my, count, config, colors, is_copy_mode, is_delete_mode)
  local tile_cfg = (config and config.tile) or DndConfig.TILE_DEFAULTS
  local stack_cfg = (config and config.stack) or DndConfig.STACK_DEFAULTS
  local shadow_cfg = (config and config.shadow) or DndConfig.SHADOW_DEFAULTS
  
  local mode_cfg = DndConfig.get_mode_config(config, is_copy_mode, is_delete_mode)
  
  local base_w = tile_cfg.width or DndConfig.TILE_DEFAULTS.width
  local base_h = tile_cfg.height or DndConfig.TILE_DEFAULTS.height
  local base_fill = tile_cfg.base_fill or DndConfig.TILE_DEFAULTS.base_fill
  local base_stroke = mode_cfg.stroke_color or DndConfig.MODES.move.stroke_color
  local thickness = tile_cfg.stroke_thickness or DndConfig.TILE_DEFAULTS.stroke_thickness
  local rounding = tile_cfg.rounding or DndConfig.TILE_DEFAULTS.rounding
  local inner_glow = tile_cfg.inner_glow or DndConfig.INNER_GLOW_DEFAULTS
  local global_opacity = tile_cfg.global_opacity or DndConfig.TILE_DEFAULTS.global_opacity
  
  local max_visible = stack_cfg.max_visible or DndConfig.STACK_DEFAULTS.max_visible
  local offset_x = stack_cfg.offset_x or DndConfig.STACK_DEFAULTS.offset_x
  local offset_y = stack_cfg.offset_y or DndConfig.STACK_DEFAULTS.offset_y
  local scale_factor = stack_cfg.scale_factor or DndConfig.STACK_DEFAULTS.scale_factor
  local opacity_falloff = stack_cfg.opacity_falloff or DndConfig.STACK_DEFAULTS.opacity_falloff
  
  local visible_count = math.min(count, max_visible)
  
  if count == 1 then
    local x = mx - base_w / 2
    local y = my - base_h / 2
    
    local fill_color = (colors and colors[1]) or base_fill
    local stroke_color = base_stroke
    
    fill_color = apply_alpha_factor(fill_color, global_opacity)
    stroke_color = apply_alpha_factor(stroke_color, global_opacity)
    
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
      
      local tile_fill = apply_alpha_factor(item_fill, opacity_factor)
      local tile_stroke = apply_alpha_factor(item_stroke, opacity_factor)
      
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