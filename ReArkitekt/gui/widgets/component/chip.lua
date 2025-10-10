-- ReArkitekt/gui/widgets/component/chip.lua
-- Unified chip component: pills, dots, indicators

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local Draw = require('ReArkitekt.gui.draw')
local Colors = require('ReArkitekt.core.colors')
local TileFX = require('ReArkitekt.gui.fx.tile_fx')
local TileFXConfig = require('ReArkitekt.gui.fx.tile_fx_config')

local M = {}

local STYLE = {
  PILL = "pill",
  DOT = "dot",
  INDICATOR = "indicator",
}

M.STYLE = STYLE

-- [[ REWRITTEN GLOW LOGIC START ]]
-- Renders a soft, multi-layered glow for circles.
local function _render_glow(dl, center_x, center_y, radius, color, layers)
  layers = layers or 8       -- Increased layers for a smoother gradient
  local max_alpha = 90       -- Controls the overall intensity of the glow
  local spread = 5           -- How many pixels the glow extends outwards
  local base_color_rgb = color & 0xFFFFFF00 -- Isolate RGB channels, ignore original alpha

  -- We draw from the outside in (largest, most transparent layer first)
  -- to ensure correct blending.
  for i = layers, 1, -1 do
    local t = i / layers -- Normalized step, from 1 (outermost) to near 0 (innermost)
    
    -- A quadratic curve creates a smooth, natural-looking falloff for the alpha.
    local alpha_multiplier = (1.0 - t) * (1.0 - t)
    local current_alpha = math.floor(max_alpha * alpha_multiplier)
    
    -- Radius increases linearly for each layer.
    local current_radius = radius + (t * spread)
    
    if current_alpha > 0 then
      local glow_color = base_color_rgb | current_alpha
      -- CRITICAL: Use AddCircleFilled for a solid glow, not just an outline.
      ImGui.DrawList_AddCircleFilled(dl, center_x, center_y, current_radius, glow_color)
    end
  end
end

-- Renders a soft, multi-layered glow for rounded rectangles.
local function _render_border_glow(dl, x1, y1, x2, y2, color, rounding, layers)
  layers = layers or 6      -- More layers for a smoother effect
  local max_alpha = 70      -- Controls the glow intensity
  local spread = 4          -- How many pixels the glow expands outwards
  local base_color_rgb = color & 0xFFFFFF00 -- Isolate RGB channels

  -- Draw from the largest, most transparent layer first.
  for i = layers, 1, -1 do
    local t = i / layers -- Normalized step from 1 to near 0
    
    -- Use the same smooth quadratic falloff for alpha.
    local alpha_multiplier = (1.0 - t) * (1.0 - t)
    local current_alpha = math.floor(max_alpha * alpha_multiplier)
    
    -- The glow expands outwards for each layer.
    local expand = t * spread
    
    if current_alpha > 0 then
      local glow_color = base_color_rgb | current_alpha
      -- Use a filled rectangle for the glow effect.
      Draw.rect_filled(dl, x1 - expand, y1 - expand, x2 + expand, y2 + expand, 
        glow_color, rounding + expand)
    end
  end
end
-- [[ REWRITTEN GLOW LOGIC END ]]

local function _apply_state(color, is_active, is_hovered, is_selected)
  if is_active then return Colors.adjust_brightness(color, 1.4) end
  if is_hovered then return Colors.adjust_brightness(color, 1.2) end
  if is_selected then return Colors.adjust_brightness(color, 1.15) end
  return color
end

function M.calculate_width(ctx, label, opts)
  opts = opts or {}
  local style = opts.style or STYLE.PILL
  
  if style == STYLE.INDICATOR then return 0 end
  
  local padding_h = opts.padding_h or (style == STYLE.DOT and 12 or 14)
  local text_w = ImGui.CalcTextSize(ctx, label or "")
  local base = text_w + (padding_h * 2)
  
  if style == STYLE.DOT then
    base = base + (opts.dot_size or 8) + (opts.dot_spacing or 10)
  end
  
  return base
end

function M.draw(ctx, opts)
  opts = opts or {}
  local style = opts.style or STYLE.PILL
  local label = opts.label or ""
  local color = opts.color or 0xFF5733FF
  local height = opts.height or (style == STYLE.DOT and 28 or 24)
  local is_selected = opts.is_selected or false
  local is_hovered = opts.is_hovered or false
  local is_active = opts.is_active or false
  
  if style == STYLE.INDICATOR then
    local dl = opts.draw_list or ImGui.GetWindowDrawList(ctx)
    local x = opts.x or 0
    local y = opts.y or 0
    local radius = opts.radius or 5
    local show_glow = opts.show_glow
    local glow_layers = opts.glow_layers or 5 -- Using rewritten function's default is fine
    local shadow = opts.shadow ~= false
    local alpha_factor = opts.alpha_factor or 1.0
    
    local draw_color = _apply_state(color, is_active, is_hovered, is_selected)
    if alpha_factor < 1.0 then
      local current_alpha = draw_color & 0xFF
      draw_color = (draw_color & 0xFFFFFF00) | math.floor(current_alpha * alpha_factor)
    end
    
    if shadow then
      local shadow_alpha = math.floor(80 * alpha_factor)
      ImGui.DrawList_AddCircleFilled(dl, x, y, radius + 1, Colors.with_alpha(0x000000FF, shadow_alpha))
    end
    
    if show_glow then
      -- Pass the base radius and let the new function handle the spread.
      _render_glow(dl, x, y, radius, draw_color, glow_layers)
    end
    
    ImGui.DrawList_AddCircleFilled(dl, x, y, radius, draw_color)
    
    return false, 0, 0
  end
  
  local rounding = opts.rounding or (style == STYLE.PILL and height * 0.5 or 6)
  local padding_h = opts.padding_h or (style == STYLE.DOT and 12 or 14)
  local explicit_width = opts.explicit_width
  local text_align = opts.text_align or "center"
  local interactive = opts.interactive ~= false
  
  local text_w, text_h = ImGui.CalcTextSize(ctx, label)
  local chip_w = explicit_width or M.calculate_width(ctx, label, opts)
  local chip_h = height
  
  local start_x, start_y = ImGui.GetCursorScreenPos(ctx)
  
  if interactive then
    local button_id = opts.id or ("##chip_" .. style .. "_" .. label)
    ImGui.InvisibleButton(ctx, button_id, chip_w, chip_h)
    is_hovered = ImGui.IsItemHovered(ctx)
    is_active = ImGui.IsItemActive(ctx)
  end
  
  local is_clicked = interactive and ImGui.IsItemClicked(ctx) or false
  local dl = ImGui.GetWindowDrawList(ctx)
  
  if style == STYLE.DOT then
    local bg_color = opts.bg_color or 0x1E1E1EFF
    local dot_size = opts.dot_size or 8
    local dot_spacing = opts.dot_spacing or 10
    
    local draw_bg = _apply_state(bg_color, is_active, is_hovered, is_selected)
    Draw.rect_filled(dl, start_x, start_y, start_x + chip_w, start_y + chip_h, draw_bg, rounding)
    
    if is_hovered or is_selected then
      local inner_shadow = Colors.with_alpha(0x000000FF, 40)
      Draw.rect_filled(dl, start_x, start_y, start_x + chip_w, start_y + 2, inner_shadow, 0)
    end
    
    if is_selected then
      local border_color = Colors.with_alpha(Colors.adjust_brightness(color, 1.8), 255)
      _render_border_glow(dl, start_x, start_y, start_x + chip_w, start_y + chip_h, color, rounding, 4)
      Draw.rect(dl, start_x, start_y, start_x + chip_w, start_y + chip_h, border_color, rounding, 2.5)
    end
    
    local dot_x = start_x + padding_h + (dot_size * 0.5)
    local dot_y = start_y + chip_h * 0.5
    local dot_color = _apply_state(color, false, is_hovered, is_selected)
    
    ImGui.DrawList_AddCircleFilled(dl, dot_x, dot_y, (dot_size * 0.5) + 1, Colors.with_alpha(0x000000FF, 80))
    
    if is_selected or is_hovered then
      _render_glow(dl, dot_x, dot_y, dot_size * 0.5, dot_color, 4)
    end
    
    ImGui.DrawList_AddCircleFilled(dl, dot_x, dot_y, dot_size * 0.5, dot_color)
    
    local text_color = (is_hovered or is_selected) and 0xFFFFFFFF or Colors.with_alpha(0xFFFFFFFF, 200)
    local content_x = start_x + padding_h + dot_size + dot_spacing
    local available_w = chip_w - (content_x - start_x) - padding_h
    
    local text_x = content_x + (text_align == "right" and (available_w - text_w) or 
                                 text_align == "center" and ((available_w - text_w) * 0.5) or 0)
    local text_y = start_y + (chip_h - text_h) * 0.5
    Draw.text(dl, text_x, text_y, text_color, label)
  else
    local hover_factor = is_active and 1.3 or (is_hovered and 1.0 or 0.0)
    
    local fx_config = TileFXConfig.override({
      fill = { opacity = 0.85, saturation = 1.2, brightness = 1.0 },
      gradient = { intensity = 0.3, opacity = 0.7 },
      specular = { strength = is_hovered and 0.4 or 0.2, coverage = 0.3 },
      inner_shadow = { strength = 0.3 },
      border = {
        saturation = 1.4,
        brightness = 1.3,
        opacity = is_selected and 1.0 or 0.6,
        thickness = is_selected and 2.5 or 1.5,
        glow_strength = is_selected and 0.6 or 0.3,
        glow_layers = is_selected and 3 or 2,
      }
    })
    
    TileFX.render_complete(dl, start_x, start_y, start_x + chip_w, start_y + chip_h, 
      color, fx_config, is_selected, hover_factor, nil, nil)
    
    local text_color = Colors.auto_text_color(color)
    if is_selected or is_hovered then
      text_color = Colors.adjust_brightness(text_color, 1.2)
    end
    
    local text_x = start_x + (text_align == "right" and (chip_w - text_w - padding_h) or 
                              text_align == "center" and ((chip_w - text_w) * 0.5) or padding_h)
    local text_y = start_y + (chip_h - text_h) * 0.5
    Draw.text(dl, text_x, text_y, text_color, label)
  end
  
  if not interactive then
    ImGui.SetCursorScreenPos(ctx, start_x, start_y + chip_h)
  end
  
  return is_clicked, chip_w, chip_h
end

return M