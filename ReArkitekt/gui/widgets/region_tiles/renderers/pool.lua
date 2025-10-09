-- ReArkitekt/gui/widgets/region_tiles/renderers/pool.lua

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
  length_margin = 6,
  length_padding_x = 4,
  length_padding_y = 2,
  length_font_size = 0.82,
  length_offset_x = 3,
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

function M.render(ctx, rect, item, state, animator, hover_config, tile_height, border_thickness)
  if item.id and item.items then
    return M.render_playlist(ctx, rect, item, state, animator, hover_config, tile_height, border_thickness)
  else
    return M.render_region(ctx, rect, item, state, animator, hover_config, tile_height, border_thickness)
  end
end

function M.render_region(ctx, rect, region, state, animator, hover_config, tile_height, border_thickness)
  local dl = ImGui.GetWindowDrawList(ctx)
  local x1, y1, x2, y2 = rect[1], rect[2], rect[3], rect[4]
  
  local actual_height = tile_height or (y2 - y1)
  
  local key = "pool_" .. tostring(region.rid)
  
  local animation_speed = hover_config and hover_config.animation_speed_hover or 12.0
  animator:track(key, 'hover', state.hover and 1.0 or 0.0, animation_speed)
  local hover_factor = animator:get(key, 'hover')
  
  local base_color = region.color or M.CONFIG.bg_base
  
  local fx_config = TileFXConfig.get()
  
  TileFX.render_complete(dl, x1, y1, x2, y2, base_color, fx_config, state.selected, hover_factor)
  
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
  local show_length = actual_height >= M.CONFIG.responsive.hide_length_below
  
  local height_factor = math.min(1.0, math.max(0.0, (actual_height - 20) / (72 - 20)))
  
  if show_text then
    local accent_color = Colors.same_hue_variant(base_color, fx_config.index_saturation, fx_config.index_brightness, 0xFF)
    local name_color = Colors.adjust_brightness(fx_config.name_base_color, fx_config.name_brightness)
    
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
      Draw.text(dl, text_x + index_w, text_y, separator_color, separator)
      
      Draw.text(dl, text_x + index_w + sep_w, text_y, name_color, name_str)
    else
      Draw.text(dl, text_x, text_y, name_color, name_str)
    end
  end
  
  if show_length then
    if not region["end"] then
      reaper.ShowConsoleMsg(string.format("Region missing 'end': rid=%s, keys=%s\n", 
        tostring(region.rid), 
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
    
    Draw.text(dl, length_text_x, length_text_y, length_color, length_str)
  end
end

function M.render_playlist(ctx, rect, playlist, state, animator, hover_config, tile_height, border_thickness)
  local dl = ImGui.GetWindowDrawList(ctx)
  local x1, y1, x2, y2 = rect[1], rect[2], rect[3], rect[4]
  
  local actual_height = tile_height or (y2 - y1)
  local key = "pool_playlist_" .. tostring(playlist.id)
  
  local animation_speed = hover_config and hover_config.animation_speed_hover or 12.0
  animator:track(key, 'hover', state.hover and 1.0 or 0.0, animation_speed)
  local hover_factor = animator:get(key, 'hover')
  
  local base_color = 0x3A3A3AFF
  
  local fx_config = TileFXConfig.get()
  TileFX.render_complete(dl, x1, y1, x2, y2, base_color, fx_config, state.selected, hover_factor)
  
  if state.selected and fx_config.ants_enabled then
    local ants_color = Colors.same_hue_variant(playlist.chip_color or base_color, 
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
  local height_factor = math.min(1.0, math.max(0.0, (actual_height - 20) / (72 - 20)))
  
  if show_text then
    local chip_x = x1 + 8
    local chip_y = y1 + (actual_height - 10) * 0.5
    local chip_radius = 5
    
    local chip_color = playlist.chip_color or 0xFF5733FF
    if state.hover or state.selected then
      chip_color = Colors.adjust_brightness(chip_color, 1.3)
    end
    
    ImGui.DrawList_AddCircleFilled(dl, chip_x, chip_y, chip_radius + 1, Colors.with_alpha(0x000000FF, 80))
    ImGui.DrawList_AddCircleFilled(dl, chip_x, chip_y, chip_radius, chip_color)
    
    if state.selected or state.hover then
      for i = 1, 2 do
        local glow_alpha = math.floor(100 / (i * 1.5))
        local glow_radius = chip_radius + (i * 2)
        local glow_color = Colors.with_alpha(chip_color, glow_alpha)
        ImGui.DrawList_AddCircle(dl, chip_x, chip_y, glow_radius, glow_color, 0, 1.5)
      end
    end
    
    local name_str = playlist.name or "Unnamed Playlist"
    local name_color = 0xCCCCCCFF
    if state.hover or state.selected then
      name_color = 0xFFFFFFFF
    end
    
    local text_x = chip_x + chip_radius + 12
    local text_y = y1 + (actual_height - ImGui.CalcTextSize(ctx, name_str)) / 2
    Draw.text(dl, text_x, text_y, name_color, name_str)
    
    local item_count = #playlist.items
    local badge_text = string.format("[%d]", item_count)
    local badge_w = ImGui.CalcTextSize(ctx, badge_text)
    local badge_x = x2 - badge_w - 12
    local badge_y = text_y
    
    local badge_color = Colors.with_alpha(0x999999FF, 200)
    if state.hover or state.selected then
      badge_color = 0xAAAAAAFF
    end
    
    Draw.text(dl, badge_x, badge_y, badge_color, badge_text)
  end
end

return M