-- ReArkitekt/gui/widgets/region_tiles/renderers/active.lua

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.10'

local Colors = require('ReArkitekt.core.colors')
local Draw = require('ReArkitekt.gui.draw')
local TileFXConfig = require('ReArkitekt.gui.fx.tile_fx_config')
local BaseRenderer = require('ReArkitekt.gui.widgets.region_tiles.renderers.base')

local M = {}

M.CONFIG = {
  bg_base = 0x1A1A1AFF,
  badge_rounding = 4,
  badge_padding_x = 6,
  badge_padding_y = 3,
  badge_margin = 6,
  badge_bg = 0x14181CFF,
  badge_border_alpha = 0x33,
  disabled = { desaturate = 0.8, brightness = 0.4, min_alpha = 0x33, fade_speed = 20.0 },
  responsive = { hide_length_below = 35, hide_badge_below = 25, hide_text_below = 20 },
  playlist_tile = { base_color = 0x3A3A3AFF, chip_offset_x = 8 },
  text_margin_right = 6,
}

function M.render(ctx, rect, item, state, get_region_by_rid, animator, on_repeat_cycle, hover_config, tile_height, border_thickness, bridge, get_playlist_by_id)
  if item.type == "playlist" then
    M.render_playlist(ctx, rect, item, state, animator, on_repeat_cycle, hover_config, tile_height, border_thickness, get_playlist_by_id)
  else
    M.render_region(ctx, rect, item, state, get_region_by_rid, animator, on_repeat_cycle, hover_config, tile_height, border_thickness, bridge)
  end
end

function M.render_region(ctx, rect, item, state, get_region_by_rid, animator, on_repeat_cycle, hover_config, tile_height, border_thickness, bridge)
  local dl = ImGui.GetWindowDrawList(ctx)
  local x1, y1, x2, y2 = rect[1], rect[2], rect[3], rect[4]
  local region = get_region_by_rid(item.rid)
  if not region then return end
  
  local is_enabled = item.enabled ~= false
  animator:track(item.key, 'hover', state.hover and 1.0 or 0.0, hover_config and hover_config.animation_speed_hover or 12.0)
  animator:track(item.key, 'enabled', is_enabled and 1.0 or 0.0, M.CONFIG.disabled.fade_speed)
  local hover_factor = animator:get(item.key, 'hover')
  local enabled_factor = animator:get(item.key, 'enabled')
  
  local base_color = region.color or M.CONFIG.bg_base
  if enabled_factor < 1.0 then
    base_color = Colors.desaturate(base_color, M.CONFIG.disabled.desaturate * (1.0 - enabled_factor))
    base_color = Colors.adjust_brightness(base_color, 1.0 - (1.0 - M.CONFIG.disabled.brightness) * (1.0 - enabled_factor))
  end
  
  local fx_config = TileFXConfig.get()
  fx_config.border_thickness = border_thickness or 1.0
  
  local playback_progress, playback_fade = 0, 0
  if bridge and bridge:get_state().is_playing and bridge:get_current_rid() == item.rid then
      playback_progress = bridge:get_progress() or 0
      playback_fade = require('ReArkitekt.gui.systems.playback_manager').compute_fade_alpha(playback_progress, 0.1, 0.2)
  end
  
  BaseRenderer.draw_base_tile(dl, rect, base_color, fx_config, state, hover_factor, playback_progress, playback_fade)
  if state.selected and fx_config.ants_enabled then BaseRenderer.draw_marching_ants(dl, rect, base_color, fx_config) end
  
  local actual_height = tile_height or (y2 - y1)
  local show_text = actual_height >= M.CONFIG.responsive.hide_text_below
  local show_badge = actual_height >= M.CONFIG.responsive.hide_badge_below
  local show_length = actual_height >= M.CONFIG.responsive.hide_length_below
  local text_alpha = math.floor(0xFF * enabled_factor + M.CONFIG.disabled.min_alpha * (1.0 - enabled_factor))
  
  -- Automated calculation: define all right-side elements
  local right_elements = {}
  
  if show_badge then
    local badge_text = (item.reps == 0) and "∞" or ("×" .. (item.reps or 1))
    local bw, _ = ImGui.CalcTextSize(ctx, badge_text)
    table.insert(right_elements, BaseRenderer.create_element(
      true,
      (bw * BaseRenderer.CONFIG.badge_font_scale) + (M.CONFIG.badge_padding_x * 2),
      M.CONFIG.badge_margin
    ))
  end
  
  if show_text then
    local right_bound_x = BaseRenderer.calculate_text_right_bound(ctx, x2, M.CONFIG.text_margin_right, right_elements)
    local text_pos = { x = x1 + 6, y = y1 + 6 }
    BaseRenderer.draw_region_text(ctx, dl, text_pos, region, base_color, text_alpha, right_bound_x)
  end
  
  if show_badge then
    local reps = item.reps or 1
    local badge_text = (reps == 0) and "∞" or ("×" .. reps)
    local bw, bh = ImGui.CalcTextSize(ctx, badge_text)
    bw, bh = bw * BaseRenderer.CONFIG.badge_font_scale, bh * BaseRenderer.CONFIG.badge_font_scale
    local badge_x = x2 - bw - M.CONFIG.badge_padding_x * 2 - M.CONFIG.badge_margin
    local badge_y = y1 + M.CONFIG.badge_margin
    local badge_x2, badge_y2 = badge_x + bw + M.CONFIG.badge_padding_x * 2, badge_y + bh + M.CONFIG.badge_padding_y * 2
    local badge_bg = (M.CONFIG.badge_bg & 0xFFFFFF00) | (math.floor(((M.CONFIG.badge_bg & 0xFF) * enabled_factor) + (M.CONFIG.disabled.min_alpha * (1.0 - enabled_factor))))
    
    ImGui.DrawList_AddRectFilled(dl, badge_x, badge_y, badge_x2, badge_y2, badge_bg, M.CONFIG.badge_rounding)
    ImGui.DrawList_AddRect(dl, badge_x, badge_y, badge_x2, badge_y2, Colors.with_alpha(base_color, M.CONFIG.badge_border_alpha), M.CONFIG.badge_rounding, 0, 0.5)
    Draw.text(dl, badge_x + M.CONFIG.badge_padding_x, badge_y + M.CONFIG.badge_padding_y, Colors.with_alpha(0xFFFFFFDD, text_alpha), badge_text)
    
    ImGui.SetCursorScreenPos(ctx, badge_x, badge_y)
    ImGui.InvisibleButton(ctx, "##badge_" .. item.key, badge_x2 - badge_x, badge_y2 - badge_y)
    if ImGui.IsItemClicked(ctx, 0) and on_repeat_cycle then on_repeat_cycle(item.key) end
  end
  
  if show_length then BaseRenderer.draw_length_display(ctx, dl, rect, region, base_color, text_alpha) end
end

function M.render_playlist(ctx, rect, item, state, animator, on_repeat_cycle, hover_config, tile_height, border_thickness, get_playlist_by_id)
  local dl = ImGui.GetWindowDrawList(ctx)
  local x1, y1, x2, y2 = rect[1], rect[2], rect[3], rect[4]
  local playlist = get_playlist_by_id and get_playlist_by_id(item.playlist_id) or {}
  local playlist_data = {
    name = playlist.name or item.playlist_name or "Unknown Playlist",
    item_count = playlist.items and #playlist.items or item.playlist_item_count or 0,
    chip_color = playlist.chip_color or item.chip_color or 0xFF5733FF
  }

  local is_enabled = item.enabled ~= false
  animator:track(item.key, 'hover', state.hover and is_enabled and 1.0 or 0.0, hover_config and hover_config.animation_speed_hover or 12.0)
  animator:track(item.key, 'enabled', is_enabled and 1.0 or 0.0, M.CONFIG.disabled.fade_speed)
  local hover_factor = animator:get(item.key, 'hover')
  local enabled_factor = animator:get(item.key, 'enabled')

  local base_color = M.CONFIG.playlist_tile.base_color
  if enabled_factor < 1.0 then
    base_color = Colors.desaturate(base_color, M.CONFIG.disabled.desaturate * (1.0 - enabled_factor))
    base_color = Colors.adjust_brightness(base_color, 1.0 - (1.0 - M.CONFIG.disabled.brightness) * (1.0 - enabled_factor))
  end

  local fx_config = TileFXConfig.get()
  fx_config.border_thickness = border_thickness or 1.0

  BaseRenderer.draw_base_tile(dl, rect, base_color, fx_config, state, hover_factor)
  if state.selected and fx_config.ants_enabled then BaseRenderer.draw_marching_ants(dl, rect, playlist_data.chip_color, fx_config) end

  local actual_height = tile_height or (y2 - y1)
  local show_text = actual_height >= M.CONFIG.responsive.hide_text_below
  local show_badge = actual_height >= M.CONFIG.responsive.hide_badge_below
  local text_alpha = math.floor(0xFF * enabled_factor + M.CONFIG.disabled.min_alpha * (1.0 - enabled_factor))

  -- Automated calculation: define all right-side elements
  local right_elements = {}
  
  if show_badge then
    local reps = item.reps or 1
    local badge_text = (reps == 0) and ("∞ [" .. playlist_data.item_count .. "]") or ("×" .. reps .. " [" .. playlist_data.item_count .. "]")
    local bw, _ = ImGui.CalcTextSize(ctx, badge_text)
    table.insert(right_elements, BaseRenderer.create_element(
      true,
      (bw * BaseRenderer.CONFIG.badge_font_scale) + (M.CONFIG.badge_padding_x * 2),
      M.CONFIG.badge_margin
    ))
  end
  
  if show_text then
    local right_bound_x = BaseRenderer.calculate_text_right_bound(ctx, x2, M.CONFIG.text_margin_right, right_elements)
    local text_pos = { x = x1 + M.CONFIG.playlist_tile.chip_offset_x, y = y1 + (actual_height - ImGui.CalcTextSize(ctx, "Tg")) / 2 }
    BaseRenderer.draw_playlist_text(ctx, dl, text_pos, playlist_data, state, text_alpha, right_bound_x)
  end

  if show_badge then
    local reps = item.reps or 1
    local badge_text = (reps == 0) and ("∞ [" .. playlist_data.item_count .. "]") or ("×" .. reps .. " [" .. playlist_data.item_count .. "]")
    local bw, bh = ImGui.CalcTextSize(ctx, badge_text)
    bw, bh = bw * BaseRenderer.CONFIG.badge_font_scale, bh * BaseRenderer.CONFIG.badge_font_scale
    local badge_x = x2 - bw - M.CONFIG.badge_padding_x * 2 - M.CONFIG.badge_margin
    local badge_y = y1 + M.CONFIG.badge_margin
    local badge_x2, badge_y2 = badge_x + bw + M.CONFIG.badge_padding_x * 2, badge_y + bh + M.CONFIG.badge_padding_y * 2
    local badge_bg = (M.CONFIG.badge_bg & 0xFFFFFF00) | (math.floor(((M.CONFIG.badge_bg & 0xFF) * enabled_factor) + (M.CONFIG.disabled.min_alpha * (1.0 - enabled_factor))))

    ImGui.DrawList_AddRectFilled(dl, badge_x, badge_y, badge_x2, badge_y2, badge_bg, M.CONFIG.badge_rounding)
    ImGui.DrawList_AddRect(dl, badge_x, badge_y, badge_x2, badge_y2, Colors.with_alpha(playlist_data.chip_color, M.CONFIG.badge_border_alpha), M.CONFIG.badge_rounding, 0, 0.5)
    Draw.text(dl, badge_x + M.CONFIG.badge_padding_x, badge_y + M.CONFIG.badge_padding_y, Colors.with_alpha(0xFFFFFFDD, text_alpha), badge_text)
    
    ImGui.SetCursorScreenPos(ctx, badge_x, badge_y)
    ImGui.InvisibleButton(ctx, "##badge_" .. item.key, badge_x2 - badge_x, badge_y2 - badge_y)
    if ImGui.IsItemClicked(ctx, 0) and on_repeat_cycle then on_repeat_cycle(item.key) end
    if ImGui.IsItemHovered(ctx) then ImGui.SetTooltip(ctx, string.format("Playlist • %d items", playlist_data.item_count)) end
  end
end

return M