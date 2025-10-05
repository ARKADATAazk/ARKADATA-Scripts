-- ReArkitekt/gui/widgets/region_tiles/renderers/pool.lua
-- Pool tile rendering with responsive element hiding (using new color system)

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.10'

local Draw = require('ReArkitekt.gui.draw')
local Colors = require('ReArkitekt.core.colors')
local Grid = require('ReArkitekt.gui.widgets.grid.core')
local TileUtil = require('ReArkitekt.gui.systems.tile_utilities')

local M = {}

M.CONFIG = {
  tile_width = 110,
  tile_height = 72,
  gap = 12,
  bg_base = 0x1A1A1AFF,
  rounding = 6,
  text_color = 0xFFFFFFFF,
  length_margin = 6,
  length_padding_x = 4,
  length_padding_y = 2,
  length_font_size = 0.85,
  spawn = {
    enabled = true,
    spawn_duration = 0.28,
    stagger_delay = 0.05,
    easing = 'out_cubic',
    spawn_from = 'left',
  },
  responsive = {
    hide_length_below = 35,
    hide_text_below = 20,
  },
}

function M.render(ctx, rect, region, state, animator, hover_config, tile_height, border_thickness)
  local dl = ImGui.GetWindowDrawList(ctx)
  local x1, y1, x2, y2 = rect[1], rect[2], rect[3], rect[4]
  
  local actual_height = tile_height or (y2 - y1)
  local thickness = border_thickness or 0.5
  
  local key = "pool_" .. tostring(region.rid)
  
  local animation_speed = hover_config and hover_config.animation_speed_hover or 12.0
  animator:track(key, 'hover', state.hover and 1.0 or 0.0, animation_speed)
  local hover_factor = animator:get(key, 'hover')
  
  local base_color = region.color or M.CONFIG.bg_base
  
  local palette = Colors.derive_palette_adaptive(base_color, 'auto')
  
  local bg_color = Grid.TileHelpers.compute_fill_color(base_color, hover_factor, hover_config)
  local border_color = Grid.TileHelpers.compute_border_color(
    base_color, state.hover, false, hover_factor,
    hover_config and hover_config.hover_border_lerp or 0.5
  )
  
  Grid.TileHelpers.render_hover_shadow(dl, x1, y1, x2, y2, state.selected and 0 or hover_factor, M.CONFIG.rounding)
  
  ImGui.DrawList_AddRectFilled(dl, x1, y1, x2, y2, bg_color, M.CONFIG.rounding)
  Grid.TileHelpers.render_border(dl, x1, y1, x2, y2, state.selected, base_color, border_color, thickness, M.CONFIG.rounding)
  
  local show_text = actual_height >= M.CONFIG.responsive.hide_text_below
  local show_length = actual_height >= M.CONFIG.responsive.hide_length_below
  
  local height_factor = math.min(1.0, math.max(0.0, (actual_height - 20) / (72 - 20)))
  
  if show_text then
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
    
    Draw.text(dl, text_x, text_y, palette.border, display_name)
  end
  
  if show_length then
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
    
    Draw.text(dl, length_text_x, length_text_y, Colors.with_alpha(palette.border, 0x99), length_str)
  end
end

return M