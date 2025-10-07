-- ReArkitekt/gui/widgets/region_tiles/renderers/active.lua

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.10'

local Draw = require('ReArkitekt.gui.draw')
local Colors = require('ReArkitekt.core.colors')
local TileFX = require('ReArkitekt.gui.fx.tile_fx')
local TileFXConfig = require('ReArkitekt.gui.fx.tile_fx_config')
local MarchingAnts = require('ReArkitekt.gui.fx.marching_ants')
local TileUtil = require('ReArkitekt.gui.systems.tile_utilities')

local M = {}

M.CONFIG = {
  tile_width = 110,
  tile_height = 72,
  gap = 12,
  bg_base = 0x1A1A1AFF,
  rounding = 6,
  text_color_neutral = 0xDDE3E9FF,
  badge_rounding = 4,
  badge_padding_x = 6,
  badge_padding_y = 3,
  badge_margin = 6,
  badge_bg = 0x14181CFF,
  badge_border_alpha = 0x33,
  badge_font_scale = 0.88,
  length_margin = 6,
  length_padding_x = 4,
  length_padding_y = 2,
  length_font_size = 0.82,
  length_offset_x = 3,
  spawn = {
    enabled = true,
    duration = 0.28,
  },
  disabled = {
    desaturate = 0.8,
    brightness = 0.4,
    min_alpha = 0x33,
    fade_speed = 20.0,
  },
  responsive = {
    hide_length_below = 35,
    hide_badge_below = 25,
    hide_text_below = 20,
  },
}

function M.render(ctx, rect, item, state, get_region_by_rid, animator, on_repeat_cycle, hover_config, tile_height, border_thickness, bridge)
  local dl = ImGui.GetWindowDrawList(ctx)
  local x1, y1, x2, y2 = rect[1], rect[2], rect[3], rect[4]
  
  local actual_height = tile_height or (y2 - y1)
  
  local region = get_region_by_rid(item.rid)
  if not region then return end
  
  local is_enabled = item.enabled ~= false
  
  local animation_speed = hover_config and hover_config.animation_speed_hover or 12.0
  animator:track(item.key, 'hover', state.hover and 1.0 or 0.0, animation_speed)
  animator:track(item.key, 'enabled', is_enabled and 1.0 or 0.0, M.CONFIG.disabled.fade_speed)
  
  local hover_factor = animator:get(item.key, 'hover')
  local enabled_factor = animator:get(item.key, 'enabled')
  
  local base_color = region.color or M.CONFIG.bg_base
  
  if enabled_factor < 1.0 then
    base_color = Colors.desaturate(base_color, M.CONFIG.disabled.desaturate * (1.0 - enabled_factor))
    base_color = Colors.adjust_brightness(base_color, 1.0 - (1.0 - M.CONFIG.disabled.brightness) * (1.0 - enabled_factor))
  end
  
  local fx_config = TileFXConfig.get()
  fx_config.rounding = M.CONFIG.rounding
  fx_config.border_thickness = border_thickness or 1.0
  
  
  local playback_progress = 0
  local playback_fade = 0
  
  if bridge then
    local bridge_state = bridge:get_state()
    local current_rid = bridge:get_current_rid()
    
    if bridge_state.is_playing and current_rid == item.rid then
      playback_progress = bridge:get_progress() or 0
      
      local PlaybackUtil = require('ReArkitekt.gui.systems.playback_manager')
      playback_fade = PlaybackUtil.compute_fade_alpha(playback_progress, 0.1, 0.2)
    end
  end
  
  TileFX.render_complete(dl, x1, y1, x2, y2, base_color, fx_config, state.selected, hover_factor, playback_progress, playback_fade) 

  if state.selected and fx_config.ants_enabled then
    local ants_color = Colors.same_hue_variant(base_color, 
      fx_config.border_saturation, 
      fx_config.border_brightness, 
      fx_config.ants_alpha or 0xFF)
    
    local inset = fx_config.ants_inset or 0.5
    MarchingAnts.draw(dl, x1 + inset, y1 + inset, x2 - inset, y2 - inset, ants_color, 
      fx_config.ants_thickness,
      M.CONFIG.rounding,
      fx_config.ants_dash,
      fx_config.ants_gap,
      fx_config.ants_speed)
  end
  
  local show_text = actual_height >= M.CONFIG.responsive.hide_text_below
  local show_badge = actual_height >= M.CONFIG.responsive.hide_badge_below
  local show_length = actual_height >= M.CONFIG.responsive.hide_length_below
  
  local height_factor = math.min(1.0, math.max(0.0, (actual_height - 20) / (72 - 20)))
  
  local text_alpha = math.floor(0xFF * enabled_factor + M.CONFIG.disabled.min_alpha * (1.0 - enabled_factor))
  
  if show_text then
    local accent_color = Colors.same_hue_variant(base_color, fx_config.index_saturation, fx_config.index_brightness, 0xFF)
    local name_color = Colors.adjust_brightness(fx_config.name_base_color, fx_config.name_brightness)
    
    accent_color = Colors.with_alpha(accent_color, text_alpha)
    name_color = Colors.with_alpha(name_color, text_alpha)
    
    local index_str = string.format("%d", region.rid)
    local name_str = region.name or "Unknown"
    
    local text_x, text_y
    if actual_height <= 25 then
      local scaled_padding_x = 2 + (4 * height_factor)
      text_x = x1 + scaled_padding_x + 2
      text_y = y1 + (actual_height - ImGui.CalcTextSize(ctx, index_str)) / 2 - 1
    else
      text_x = x1 + 6
      text_y = y1 + 6
    end
    
    if index_str ~= "" then
      Draw.text(dl, text_x, text_y, accent_color, index_str)
      local index_w = ImGui.CalcTextSize(ctx, index_str)
      
      local separator = " "
      local sep_w = ImGui.CalcTextSize(ctx, separator)
      local separator_color = Colors.same_hue_variant(base_color, 
        fx_config.separator_saturation, 
        fx_config.separator_brightness, 
        fx_config.separator_alpha)
      separator_color = Colors.with_alpha(separator_color, text_alpha)
      Draw.text(dl, text_x + index_w, text_y, separator_color, separator)
      
      Draw.text(dl, text_x + index_w + sep_w, text_y, name_color, name_str)
    else
      Draw.text(dl, text_x, text_y, name_color, name_str)
    end
  end
  
  if show_badge then
    local reps = item.reps or 1
    local badge_text = (reps == 0) and "∞" or ("×" .. reps)
    
    local bw, bh = ImGui.CalcTextSize(ctx, badge_text)
    bw = bw * M.CONFIG.badge_font_scale
    bh = bh * M.CONFIG.badge_font_scale
    
    local scaled_badge_padding_x = M.CONFIG.badge_padding_x * (0.5 + 0.5 * height_factor)
    local scaled_badge_padding_y = M.CONFIG.badge_padding_y * (0.5 + 0.5 * height_factor)
    local scaled_badge_margin = M.CONFIG.badge_margin * (0.3 + 0.7 * height_factor)
    
    local badge_x = x2 - bw - scaled_badge_padding_x * 2 - scaled_badge_margin
    local badge_y = y1 + scaled_badge_margin
    local badge_x2 = badge_x + bw + scaled_badge_padding_x * 2
    local badge_y2 = badge_y + bh + scaled_badge_padding_y * 2
    
    local badge_bg = M.CONFIG.badge_bg
    local badge_border_color = Colors.with_alpha(base_color, M.CONFIG.badge_border_alpha)
    
    local badge_bg_alpha = math.floor(((badge_bg & 0xFF) * enabled_factor) + (M.CONFIG.disabled.min_alpha * (1.0 - enabled_factor)))
    badge_bg = (badge_bg & 0xFFFFFF00) | badge_bg_alpha
    
    ImGui.DrawList_AddRectFilled(dl, badge_x, badge_y, badge_x2, badge_y2, badge_bg, M.CONFIG.badge_rounding)
    ImGui.DrawList_AddRect(dl, badge_x, badge_y, badge_x2, badge_y2, badge_border_color, M.CONFIG.badge_rounding, 0, 0.5)
    
    local badge_text_color = Colors.with_alpha(0xFFFFFFDD, text_alpha)
    
    local text_x = badge_x + scaled_badge_padding_x
    local text_y = badge_y + scaled_badge_padding_y
    Draw.text(dl, text_x, text_y, badge_text_color, badge_text)
    
    ImGui.SetCursorScreenPos(ctx, badge_x, badge_y)
    ImGui.InvisibleButton(ctx, "##badge_" .. item.key, badge_x2 - badge_x, badge_y2 - badge_y)
    
    if ImGui.IsItemClicked(ctx, 0) and on_repeat_cycle then
      on_repeat_cycle(item.key)
    end
  end
  
  if show_length then
    if not region["end"] then
      reaper.ShowConsoleMsg(string.format("Region missing 'end': rid=%s, keys=%s\n", 
        tostring(item.rid), 
        table.concat((function() local k={} for key in pairs(region) do k[#k+1]=key end return k end)(), ",")))
    end
    local length_str = TileUtil.format_bar_length(region.start, region["end"], 0)
    
    local scale = M.CONFIG.length_font_size
    
    local length_w, length_h = ImGui.CalcTextSize(ctx, length_str)
    length_w = length_w * scale
    length_h = length_h * scale
    
    local scaled_length_padding_x = M.CONFIG.length_padding_x * (0.5 + 0.5 * height_factor)
    local scaled_length_padding_y = M.CONFIG.length_padding_y * (0.5 + 0.5 * height_factor)
    local scaled_length_margin = M.CONFIG.length_margin * (0.3 + 0.7 * height_factor)
    
    local length_x = x2 - length_w - scaled_length_padding_x * 2 - scaled_length_margin - M.CONFIG.length_offset_x
    local length_y = y2 - length_h - scaled_length_padding_y * 2 - scaled_length_margin
    
    local length_text_x = length_x + scaled_length_padding_x
    local length_text_y = length_y + scaled_length_padding_y
    
    local length_color = Colors.same_hue_variant(base_color, 
      fx_config.duration_saturation, 
      fx_config.duration_brightness, 
      fx_config.duration_alpha)
    length_color = Colors.with_alpha(length_color, text_alpha)
    
    Draw.text(dl, length_text_x, length_text_y, length_color, length_str)
  end
end

return M