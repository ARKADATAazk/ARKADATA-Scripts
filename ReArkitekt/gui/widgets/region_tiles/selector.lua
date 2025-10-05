-- ReArkitekt/gui/widgets/region_tiles/selector.lua
-- Playlist selector widget with animated chips

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.10'

local Draw = require('ReArkitekt.gui.draw')
local Colors = require('ReArkitekt.core.colors')
local TileAnim = require('ReArkitekt.gui.fx.tile_motion')

local M = {}

M.CONFIG = {
  chip_width = 110,
  chip_height = 30,
  gap = 10,
  bg_inactive = 0x1A2A3AFF,
  bg_active = 0x2A4A6AFF,
  bg_hover = 0x3A5A7AFF,
  border_inactive = 0x2A3A4AFF,
  border_active = 0x4A90E2FF,
  border_thickness = 1.5,
  rounding = 4,
  text_color = 0xFFFFFFFF,
  animation_speed = 10.0,
}

local Selector = {}
Selector.__index = Selector

function M.new(config)
  config = config or M.CONFIG
  
  return setmetatable({
    config = config,
    animator = TileAnim.new(config.animation_speed or M.CONFIG.animation_speed),
  }, Selector)
end

function Selector:update(dt)
  self.animator:update(dt)
end

function Selector:draw(ctx, playlists, active_id, height, on_playlist_changed)
  local cfg = self.config
  local dl = ImGui.GetWindowDrawList(ctx)
  local cursor_x, cursor_y = ImGui.GetCursorScreenPos(ctx)
  
  local total_width = #playlists * (cfg.chip_width + cfg.gap) - cfg.gap
  local x = cursor_x
  local y = cursor_y
  
  ImGui.InvisibleButton(ctx, "##selector_area", total_width, height)
  
  for i, pl in ipairs(playlists) do
    local chip_x = x + (i - 1) * (cfg.chip_width + cfg.gap)
    local chip_y = y + (height - cfg.chip_height) / 2
    local chip_x2 = chip_x + cfg.chip_width
    local chip_y2 = chip_y + cfg.chip_height
    
    local mx, my = ImGui.GetMousePos(ctx)
    local is_hovered = mx >= chip_x and mx < chip_x2 and my >= chip_y and my < chip_y2
    local is_active = pl.id == active_id
    
    self.animator:track(pl.id, 'hover', is_hovered and 1.0 or 0.0, cfg.animation_speed)
    self.animator:track(pl.id, 'active', is_active and 1.0 or 0.0, cfg.animation_speed)
    
    local hover_factor = self.animator:get(pl.id, 'hover')
    local active_factor = self.animator:get(pl.id, 'active')
    
    local bg_base = Colors.lerp(cfg.bg_inactive, cfg.bg_active, active_factor)
    local bg_final = Colors.lerp(bg_base, cfg.bg_hover, hover_factor * 0.5)
    
    local border_base = Colors.lerp(cfg.border_inactive, cfg.border_active, active_factor)
    local border_final = Colors.lerp(border_base, cfg.border_active, hover_factor)
    
    ImGui.DrawList_AddRectFilled(dl, chip_x, chip_y, chip_x2, chip_y2, bg_final, cfg.rounding)
    ImGui.DrawList_AddRect(dl, chip_x + 0.5, chip_y + 0.5, chip_x2 - 0.5, chip_y2 - 0.5,
                          border_final, cfg.rounding, 0, cfg.border_thickness)
    
    local label = "#" .. i .. " " .. pl.name
    Draw.centered_text(ctx, label, chip_x, chip_y, chip_x2, chip_y2, cfg.text_color)
    
    ImGui.SetCursorScreenPos(ctx, chip_x, chip_y)
    ImGui.InvisibleButton(ctx, "##selector_" .. pl.id, cfg.chip_width, cfg.chip_height)
    
    if ImGui.IsItemClicked(ctx, 0) and on_playlist_changed then
      on_playlist_changed(pl.id)
    end
  end
end

function Selector:clear()
  self.animator:clear()
end

return M