-- ReArkitekt/gui/widgets/region_tiles/renderers/pool.lua

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.10'

local Colors = require('ReArkitekt.core.colors')
local Draw = require('ReArkitekt.gui.draw')
local TileFXConfig = require('ReArkitekt.gui.fx.tile_fx_config')
local TileUtil = require('ReArkitekt.gui.systems.tile_utilities')
local BaseRenderer = require('Region_Playlist.widgets.region_tiles.renderers.base')

local M = {}

M.CONFIG = {
  bg_base = 0x1A1A1AFF,
  disabled = { desaturate = 0.9, brightness = 0.5, alpha_multiplier = 0.6 },
  responsive = { hide_length_below = 35, hide_text_below = 20 },
  playlist_tile = { base_color = 0x3A3A3AFF, chip_offset_x = 8, name_color = 0xCCCCCCFF, badge_color = 0x999999FF },
  text_margin_right = 6,
  badge_margin_right = 12,
}

function M.render(ctx, rect, item, state, animator, hover_config, tile_height, border_thickness)
  if item.id and item.items then
    M.render_playlist(ctx, rect, item, state, animator, hover_config, tile_height, border_thickness)
  else
    M.render_region(ctx, rect, item, state, animator, hover_config, tile_height, border_thickness)
  end
end

function M.render_region(ctx, rect, region, state, animator, hover_config, tile_height, border_thickness)
  local dl = ImGui.GetWindowDrawList(ctx)
  local x1, y1, x2, y2 = rect[1], rect[2], rect[3], rect[4]
  local key = "pool_" .. tostring(region.rid)
  
  animator:track(key, 'hover', state.hover and 1.0 or 0.0, hover_config and hover_config.animation_speed_hover or 12.0)
  local hover_factor = animator:get(key, 'hover')
  local base_color = region.color or M.CONFIG.bg_base
  local fx_config = TileFXConfig.get()
  
  BaseRenderer.draw_base_tile(dl, rect, base_color, fx_config, state, hover_factor)
  if state.selected and fx_config.ants_enabled then BaseRenderer.draw_marching_ants(dl, rect, base_color, fx_config) end
  
  local actual_height = tile_height or (y2 - y1)
  local show_text = actual_height >= M.CONFIG.responsive.hide_text_below
  local show_length = actual_height >= M.CONFIG.responsive.hide_length_below
  
  -- For pool regions, length display is at BOTTOM-RIGHT (different Y position)
  -- so it doesn't affect horizontal text space - right_elements stays empty
  local right_elements = {}
  
  if show_text then
    local right_bound_x = BaseRenderer.calculate_text_right_bound(ctx, x2, M.CONFIG.text_margin_right, right_elements)
    local text_pos = { x = x1 + 6, y = y1 + 6 }
    BaseRenderer.draw_region_text(ctx, dl, text_pos, region, base_color, 0xFF, right_bound_x)
  end
  
  if show_length then BaseRenderer.draw_length_display(ctx, dl, rect, region, base_color, 0xFF) end
end

function M.render_playlist(ctx, rect, playlist, state, animator, hover_config, tile_height, border_thickness)
  local dl = ImGui.GetWindowDrawList(ctx)
  local x1, y1, x2, y2 = rect[1], rect[2], rect[3], rect[4]
  local key = "pool_playlist_" .. tostring(playlist.id)
  local is_disabled = playlist.is_disabled or false
  
  animator:track(key, 'hover', (state.hover and not is_disabled) and 1.0 or 0.0, hover_config and hover_config.animation_speed_hover or 12.0)
  animator:track(key, 'disabled', is_disabled and 1.0 or 0.0, 12.0)
  local hover_factor = animator:get(key, 'hover')
  local disabled_factor = animator:get(key, 'disabled')
  
  local base_color = M.CONFIG.playlist_tile.base_color
  local playlist_data = {
    name = playlist.name or "Unnamed Playlist",
    chip_color = playlist.chip_color or 0xFF5733FF
  }

  if disabled_factor > 0 then
    base_color = Colors.desaturate(base_color, M.CONFIG.disabled.desaturate * disabled_factor)
    base_color = Colors.adjust_brightness(base_color, 1.0 - ((1.0 - M.CONFIG.disabled.brightness) * disabled_factor))
    playlist_data.chip_color = Colors.desaturate(playlist_data.chip_color, M.CONFIG.disabled.desaturate * disabled_factor)
    playlist_data.chip_color = Colors.adjust_brightness(playlist_data.chip_color, 1.0 - ((1.0 - M.CONFIG.disabled.brightness) * disabled_factor))
  end
  
  local fx_config = TileFXConfig.get()
  BaseRenderer.draw_base_tile(dl, rect, base_color, fx_config, state, hover_factor)
  
  if is_disabled and disabled_factor > 0.5 then
    ImGui.DrawList_AddRectFilled(dl, x1, y1, x2, y2, 0x00000000 | math.floor(120 * disabled_factor), BaseRenderer.CONFIG.rounding)
  end
  
  if state.selected and fx_config.ants_enabled then BaseRenderer.draw_marching_ants(dl, rect, playlist_data.chip_color, fx_config) end
  
  local actual_height = tile_height or (y2 - y1)
  local show_text = actual_height >= M.CONFIG.responsive.hide_text_below
  local text_alpha_factor = 1.0 - (disabled_factor * (1.0 - M.CONFIG.disabled.alpha_multiplier))
  local text_alpha = math.floor(0xFF * text_alpha_factor)
  
  local item_count = #playlist.items
  
  -- Automated calculation: define all right-side elements
  local right_elements = {}
  
  local badge_text = string.format("[%d]", item_count)
  local badge_w = ImGui.CalcTextSize(ctx, badge_text)
  table.insert(right_elements, BaseRenderer.create_element(
    show_text,
    badge_w,
    M.CONFIG.badge_margin_right
  ))
  
  if show_text then
    local right_bound_x = BaseRenderer.calculate_text_right_bound(ctx, x2, M.CONFIG.text_margin_right, right_elements)
    local text_pos = { x = x1 + M.CONFIG.playlist_tile.chip_offset_x, y = y1 + (actual_height - ImGui.CalcTextSize(ctx, "Tg")) / 2 }
    
    local name_color = M.CONFIG.playlist_tile.name_color
    if disabled_factor > 0 then
      name_color = Colors.adjust_brightness(name_color, 1.0 - ((1.0 - M.CONFIG.disabled.brightness) * disabled_factor))
    end
    if (state.hover or state.selected) and not is_disabled then
      name_color = 0xFFFFFFFF
    end

    BaseRenderer.draw_playlist_text(ctx, dl, text_pos, playlist_data, state, text_alpha, right_bound_x, name_color)
    
    local badge_color = M.CONFIG.playlist_tile.badge_color
    if disabled_factor > 0 then
      badge_color = Colors.adjust_brightness(badge_color, 1.0 - ((1.0 - M.CONFIG.disabled.brightness) * disabled_factor))
    end
    if (state.hover or state.selected) and not is_disabled then
      badge_color = 0xAAAAAAFF
    end
    Draw.text(dl, x2 - badge_w - M.CONFIG.badge_margin_right, text_pos.y, Colors.with_alpha(badge_color, math.floor(200 * text_alpha_factor)), badge_text)

    ImGui.SetCursorScreenPos(ctx, x1, y1)
    ImGui.InvisibleButton(ctx, key .. "_tooltip", x2 - x1, y2 - y1)
    if ImGui.IsItemHovered(ctx) then
      if is_disabled then
        ImGui.SetTooltip(ctx, "Cannot drag: would create circular reference")
      else
        ImGui.SetTooltip(ctx, string.format("Playlist • %d items", item_count))
      end
    end
  end
end

return M