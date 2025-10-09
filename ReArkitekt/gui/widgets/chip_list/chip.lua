-- ReArkitekt/gui/widgets/chip_list/chip.lua
-- Individual colored chip/tag rendering with tile_fx integration

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local Draw    = require('ReArkitekt.gui.draw')
local Colors  = require('ReArkitekt.core.colors')
local TileFX  = require('ReArkitekt.gui.fx.tile_fx')
local TileFXConfig = require('ReArkitekt.gui.fx.tile_fx_config')

local M = {}

function M.calculate_min_width(ctx, label, opts)
  opts = opts or {}
  local padding_h = opts.padding_h or 14
  local dot_size = opts.dot_size or 8
  local dot_spacing = opts.dot_spacing or 10
  local use_dot_style = opts.use_dot_style or false
  
  local text_w = ImGui.CalcTextSize(ctx, label)
  local base_width = text_w + (padding_h * 2)
  
  if use_dot_style then
    base_width = base_width + dot_size + dot_spacing
  end
  
  return base_width
end

function M.draw(ctx, label, color, opts)
  opts = opts or {}
  local height = opts.height or 24
  local rounding = opts.rounding or height * 0.5
  local padding_h = opts.padding_h or 14
  local padding_v = opts.padding_v or 4
  local is_selected = opts.is_selected or false
  local is_hovered = opts.is_hovered or false
  local explicit_width = opts.explicit_width
  local text_align = opts.text_align or "center"
  
  local text_w, text_h = ImGui.CalcTextSize(ctx, label)
  local chip_w = explicit_width or (text_w + (padding_h * 2))
  local chip_h = height
  
  local start_x, start_y = ImGui.GetCursorScreenPos(ctx)
  
  ImGui.InvisibleButton(ctx, "##chip_" .. label, chip_w, chip_h)
  is_hovered = ImGui.IsItemHovered(ctx)
  local is_active = ImGui.IsItemActive(ctx)
  local is_clicked = ImGui.IsItemClicked(ctx)
  
  local dl = ImGui.GetWindowDrawList(ctx)
  
  local hover_factor = is_hovered and 1.0 or 0.0
  if is_active then hover_factor = 1.3 end
  
  local fx_config = TileFXConfig.get()
  fx_config = TileFXConfig.override({
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
  
  TileFX.render_complete(
    dl,
    start_x, start_y, start_x + chip_w, start_y + chip_h,
    color,
    fx_config,
    is_selected,
    hover_factor,
    nil,
    nil
  )
  
  local text_color = Colors.auto_text_color(color)
  if is_selected or is_hovered then
    text_color = Colors.adjust_brightness(text_color, 1.2)
  end
  
  local text_x
  if text_align == "left" then
    text_x = start_x + padding_h
  elseif text_align == "right" then
    text_x = start_x + chip_w - text_w - padding_h
  else
    text_x = start_x + (chip_w - text_w) * 0.5
  end
  local text_y = start_y + (chip_h - text_h) * 0.5
  Draw.text(dl, text_x, text_y, text_color, label)
  
  return is_clicked, chip_w, chip_h
end

function M.draw_with_dot(ctx, label, color, opts)
  opts = opts or {}
  local height = opts.height or 28
  local rounding = opts.rounding or 6
  local padding_h = opts.padding_h or 12
  local padding_v = opts.padding_v or 6
  local dot_size = opts.dot_size or 8
  local dot_spacing = opts.dot_spacing or 10
  local is_selected = opts.is_selected or false
  local bg_color = opts.bg_color or 0x1E1E1EFF
  local explicit_width = opts.explicit_width
  local text_align = opts.text_align or "center"
  
  local text_w, text_h = ImGui.CalcTextSize(ctx, label)
  local chip_w = explicit_width or (text_w + (padding_h * 2) + dot_size + dot_spacing)
  local chip_h = height
  
  local start_x, start_y = ImGui.GetCursorScreenPos(ctx)
  
  ImGui.InvisibleButton(ctx, "##chip_dot_" .. label, chip_w, chip_h)
  local is_hovered = ImGui.IsItemHovered(ctx)
  local is_active = ImGui.IsItemActive(ctx)
  local is_clicked = ImGui.IsItemClicked(ctx)
  
  local dl = ImGui.GetWindowDrawList(ctx)
  
  local draw_bg = bg_color
  if is_active then
    draw_bg = Colors.adjust_brightness(bg_color, 1.4)
  elseif is_hovered then
    draw_bg = Colors.adjust_brightness(bg_color, 1.2)
  elseif is_selected then
    draw_bg = Colors.adjust_brightness(bg_color, 1.15)
  end
  
  Draw.rect_filled(dl, start_x, start_y, start_x + chip_w, start_y + chip_h, draw_bg, rounding)
  
  if is_hovered or is_selected then
    local inner_shadow = Colors.with_alpha(0x000000FF, 40)
    Draw.rect_filled(dl, start_x, start_y, start_x + chip_w, start_y + 2, inner_shadow, 0)
  end
  
  if is_selected then
    local border_color = Colors.adjust_brightness(color, 1.8)
    border_color = Colors.with_alpha(border_color, 255)
    Draw.rect(dl, start_x, start_y, start_x + chip_w, start_y + chip_h, border_color, rounding, 2.5)
    
    for i = 1, 2 do
      local glow_alpha = math.floor(60 / i)
      local glow_expand = i * 2
      local glow_color = Colors.with_alpha(color, glow_alpha)
      Draw.rect(dl, 
        start_x - glow_expand, start_y - glow_expand, 
        start_x + chip_w + glow_expand, start_y + chip_h + glow_expand, 
        glow_color, rounding + glow_expand, 1.5)
    end
  end
  
  local dot_x = start_x + padding_h
  local dot_y = start_y + chip_h * 0.5
  local dot_radius = dot_size * 0.5
  
  local dot_color = color
  if is_hovered or is_selected then
    dot_color = Colors.adjust_brightness(color, 1.3)
  end
  
  ImGui.DrawList_AddCircleFilled(dl, dot_x + dot_radius, dot_y, dot_radius + 1, Colors.with_alpha(0x000000FF, 80))
  ImGui.DrawList_AddCircleFilled(dl, dot_x + dot_radius, dot_y, dot_radius, dot_color)
  
  if is_selected or is_hovered then
    for i = 1, 2 do
      local glow_alpha = math.floor(100 / (i * 1.5))
      local glow_radius = dot_radius + (i * 2)
      local glow_color = Colors.with_alpha(color, glow_alpha)
      ImGui.DrawList_AddCircle(dl, dot_x + dot_radius, dot_y, glow_radius, glow_color, 0, 1.5)
    end
  end
  
  local text_color = 0xFFFFFFFF
  if is_hovered or is_selected then
    text_color = 0xFFFFFFFF
  else
    text_color = Colors.with_alpha(0xFFFFFFFF, 200)
  end
  
  local content_x = dot_x + dot_size + dot_spacing
  local available_text_width = chip_w - (content_x - start_x) - padding_h
  
  local text_x
  if text_align == "left" then
    text_x = content_x
  elseif text_align == "right" then
    text_x = content_x + available_text_width - text_w
  else
    text_x = content_x + (available_text_width - text_w) * 0.5
  end
  local text_y = start_y + (chip_h - text_h) * 0.5
  Draw.text(dl, text_x, text_y, text_color, label)
  
  return is_clicked, chip_w, chip_h
end

return M