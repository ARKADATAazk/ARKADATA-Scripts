-- ReArkitekt/gui/widgets/tiles/active_tile.lua
-- Active sequence tile rendering with responsive element hiding

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.10'

local Draw = require('ReArkitekt.gui.draw')
local Colors = require('ReArkitekt.gui.colors')
local Grid = require('ReArkitekt.gui.widgets.colorblocks')
local TileUtil = require('ReArkitekt.gui.systems.tile_utilities')

local M = {}

M.CONFIG = {
  tile_width = 110,
  tile_height = 72,
  gap = 12,
  bg_base = 0x1A1A1AFF,
  rounding = 6,
  text_color = 0xFFFFFFFF,
  badge_rounding = 4,
  badge_padding_x = 6,
  badge_padding_y = 3,
  badge_margin = 6,
  badge_bg_color = 0x000000CC,
  length_margin = 6,
  length_padding_x = 4,
  length_padding_y = 2,
  length_font_size = 0.85,
  spawn = {
    enabled = true,
    duration = 0.28,
  },
  disabled = {
    desaturate = 0.8,
    brightness = 0.4,
    text_alpha = 0x66,
  },
  responsive = {
    hide_length_below = 35,
    hide_badge_below = 25,
    hide_text_below = 20,
  },
}

function M.render(ctx, rect, item, state, get_region_by_rid, animator, on_repeat_cycle, hover_config, tile_height, border_thickness)
  local dl = ImGui.GetWindowDrawList(ctx)
  local x1, y1, x2, y2 = rect[1], rect[2], rect[3], rect[4]
  
  local actual_height = tile_height or (y2 - y1)
  local thickness = border_thickness or 0.5
  
  local region = get_region_by_rid(item.rid)
  if not region then return end
  
  local is_enabled = item.enabled ~= false
  
  local animation_speed = hover_config and hover_config.animation_speed_hover or 12.0
  animator:track(item.key, 'hover', state.hover and 1.0 or 0.0, animation_speed)
  local hover_factor = animator:get(item.key, 'hover')
  
  local base_color = region.color or M.CONFIG.bg_base
  
  if not is_enabled then
    base_color = Colors.desaturate(base_color, M.CONFIG.disabled.desaturate)
    base_color = Colors.adjust_brightness(base_color, M.CONFIG.disabled.brightness)
  end
  
  local bg_color = Grid.TileHelpers.compute_fill_color(base_color, hover_factor, hover_config)
  local border_color = Grid.TileHelpers.compute_border_color(
    base_color, state.hover, false, hover_factor, 
    hover_config and hover_config.hover_border_lerp or 0.5
  )
  
  Grid.TileHelpers.render_hover_shadow(dl, x1, y1, x2, y2, state.selected and 0 or hover_factor, M.CONFIG.rounding)
  
  ImGui.DrawList_AddRectFilled(dl, x1, y1, x2, y2, bg_color, M.CONFIG.rounding)
  Grid.TileHelpers.render_border(dl, x1, y1, x2, y2, state.selected, base_color, border_color, thickness, M.CONFIG.rounding)
  
  local show_text = actual_height >= M.CONFIG.responsive.hide_text_below
  local show_badge = actual_height >= M.CONFIG.responsive.hide_badge_below
  local show_length = actual_height >= M.CONFIG.responsive.hide_length_below
  
  local height_factor = math.min(1.0, math.max(0.0, (actual_height - 20) / (72 - 20)))
  
  if show_text then
    local r, g, b, a = Colors.rgba_to_components(base_color)
    local max_channel = math.max(r, g, b)
    local boost = 255 / (max_channel > 0 and max_channel or 1)
    local border_r = math.min(255, math.floor(r * boost * 0.95))
    local border_g = math.min(255, math.floor(g * boost * 0.95))
    local border_b = math.min(255, math.floor(b * boost * 0.95))
    local flashy_border = Colors.components_to_rgba(border_r, border_g, border_b, 0xFF)
    
    local text_color = is_enabled and flashy_border or Colors.with_alpha(flashy_border, M.CONFIG.disabled.text_alpha)
    
    local display_name = region.name
    if state.index then
      display_name = string.format("#%d - %s", state.index, region.name)
    end
    
    local text_w, text_h = ImGui.CalcTextSize(ctx, display_name)
    
    local text_x, text_y
    if actual_height <= 25 then
      local scaled_padding_x = 2 + (4 * height_factor)
      text_x = x1 + scaled_padding_x + 2
      text_y = y1 + (actual_height - text_h) / 2 - 1
    else
      text_x = x1 + 6
      text_y = y1 + 6
    end
    
    Draw.text(dl, text_x, text_y, text_color, display_name)
  end
  
  if show_badge then
    local reps = item.reps or 1
    local badge_text = (reps == 0) and "∞" or ("×" .. reps)
    local bw, bh = ImGui.CalcTextSize(ctx, badge_text)
    
    local scaled_badge_padding_x = M.CONFIG.badge_padding_x * (0.5 + 0.5 * height_factor)
    local scaled_badge_padding_y = M.CONFIG.badge_padding_y * (0.5 + 0.5 * height_factor)
    local scaled_badge_margin = M.CONFIG.badge_margin * (0.3 + 0.7 * height_factor)
    
    local badge_x = x2 - bw - scaled_badge_padding_x * 2 - scaled_badge_margin
    local badge_y = y1 + scaled_badge_margin
    local badge_x2 = badge_x + bw + scaled_badge_padding_x * 2
    local badge_y2 = badge_y + bh + scaled_badge_padding_y * 2
    
    local badge_bg = M.CONFIG.badge_bg_color
    local badge_text_color = is_enabled and base_color or Colors.with_alpha(base_color, M.CONFIG.disabled.text_alpha)
    
    ImGui.DrawList_AddRectFilled(dl, badge_x, badge_y, badge_x2, badge_y2,
                                  badge_bg, M.CONFIG.badge_rounding)
    Draw.centered_text(ctx, badge_text, badge_x, badge_y, badge_x2, badge_y2, badge_text_color)
    
    ImGui.SetCursorScreenPos(ctx, badge_x, badge_y)
    ImGui.InvisibleButton(ctx, "##badge_" .. item.key, badge_x2 - badge_x, badge_y2 - badge_y)
    
    if ImGui.IsItemClicked(ctx, 0) and on_repeat_cycle then
      on_repeat_cycle(item.key)
    end
  end
  
  if show_length then
    local r, g, b, a = Colors.rgba_to_components(base_color)
    local max_channel = math.max(r, g, b)
    local boost = 255 / (max_channel > 0 and max_channel or 1)
    local border_r = math.min(255, math.floor(r * boost * 0.95))
    local border_g = math.min(255, math.floor(g * boost * 0.95))
    local border_b = math.min(255, math.floor(b * boost * 0.95))
    local flashy_border = Colors.components_to_rgba(border_r, border_g, border_b, 0xFF)
    
    local length_seconds = (region["end"] or 0) - (region.start or 0)
    local length_str = TileUtil.format_bar_length(length_seconds)
    
    local scale = M.CONFIG.length_font_size
    
    local length_w, length_h = ImGui.CalcTextSize(ctx, length_str)
    length_w = length_w * scale
    length_h = length_h * scale
    
    local scaled_length_padding_x = M.CONFIG.length_padding_x * (0.5 + 0.5 * height_factor)
    local scaled_length_padding_y = M.CONFIG.length_padding_y * (0.5 + 0.5 * height_factor)
    local scaled_length_margin = M.CONFIG.length_margin * (0.3 + 0.7 * height_factor)
    
    local length_x = x2 - length_w - scaled_length_padding_x * 2 - scaled_length_margin
    local length_y = y2 - length_h - scaled_length_padding_y * 2 - scaled_length_margin
    
    local length_text_x = length_x + scaled_length_padding_x
    local length_text_y = length_y + scaled_length_padding_y
    
    local length_text_color = is_enabled and Colors.with_alpha(flashy_border, 0x99) or Colors.with_alpha(flashy_border, 0x44)
    Draw.text(dl, length_text_x, length_text_y, length_text_color, length_str)
  end
end

return M