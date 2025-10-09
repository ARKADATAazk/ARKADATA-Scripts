-- ReArkitekt/gui/widgets/region_tiles/coordinator_render.lua
-- Rendering methods for region tiles coordinator

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.10'

local DragIndicator = require('ReArkitekt.gui.fx.dnd.drag_indicator')
local ActiveTile = require('ReArkitekt.gui.widgets.region_tiles.renderers.active')
local PoolTile = require('ReArkitekt.gui.widgets.region_tiles.renderers.pool')
local ResponsiveGrid = require('ReArkitekt.gui.systems.responsive_grid')

local M = {}

function M.draw_selector(self, ctx, playlists, active_id, height)
  self.selector:draw(ctx, playlists, active_id, height, self.on_playlist_changed)
end

function M.draw_active(self, ctx, playlist, height)
  self._imgui_ctx = ctx
  
  local cursor_x, cursor_y = ImGui.GetCursorScreenPos(ctx)
  local avail_w, _ = ImGui.GetContentRegionAvail(ctx)
  
  self.active_bounds = {cursor_x, cursor_y, cursor_x + avail_w, cursor_y + height}
  self.bridge:update_bounds('active', cursor_x, cursor_y, cursor_x + avail_w, cursor_y + height)
  
  self.active_container.width = avail_w
  self.active_container.height = height
  
  if not self.active_container:begin_draw(ctx) then
    return
  end
  
  local header_height = 0
  if self.active_container.config.header and self.active_container.config.header.enabled then
    header_height = self.active_container.config.header.height or 36
  end
  
  local child_w = avail_w - (self.container_config.padding * 2)
  local child_h = (height - header_height) - (self.container_config.padding * 2)
  
  self.active_grid.get_items = function() return playlist.items end
  
  local raw_height, raw_gap = ResponsiveGrid.calculate_responsive_tile_height({
    item_count = #playlist.items,
    avail_width = child_w,
    avail_height = child_h,
    base_gap = ActiveTile.CONFIG.gap,
    min_col_width = ActiveTile.CONFIG.tile_width,
    base_tile_height = self.responsive_config.base_tile_height_active,
    min_tile_height = self.responsive_config.min_tile_height,
    responsive_config = self.responsive_config,
  })
  
  local responsive_height = self.active_height_stabilizer:update(raw_height)
  
  self.current_active_tile_height = responsive_height
  self.active_grid.fixed_tile_h = responsive_height
  self.active_grid.gap = raw_gap
  
  local wheel_y = ImGui.GetMouseWheel(ctx)
  
  if wheel_y ~= 0 then
    local item, key, is_selected = self:_find_hovered_tile(ctx, playlist.items)
    
    if item and key and self.on_repeat_adjust then
      local delta = (wheel_y > 0) and self.wheel_config.step or -self.wheel_config.step
      local shift_held = ImGui.IsKeyDown(ctx, ImGui.Key_LeftShift) or ImGui.IsKeyDown(ctx, ImGui.Key_RightShift)
      
      local keys_to_adjust = {}
      if is_selected and self.active_grid.selection:count() > 0 then
        keys_to_adjust = self.active_grid.selection:selected_keys()
      else
        keys_to_adjust = {key}
      end
      
      if shift_held and self.on_repeat_sync then
        local target_reps = item.reps or 1
        self.on_repeat_sync(keys_to_adjust, target_reps)
      end
      
      self.on_repeat_adjust(keys_to_adjust, delta)
      self.wheel_consumed_this_frame = true
    end
  end
  
  self.active_grid:draw(ctx)
  
  self.active_container:end_draw(ctx)
  
  if self.bridge:is_drag_active() and self.bridge:get_source_grid() == 'active' and ImGui.IsMouseReleased(ctx, 0) then
    if not self.bridge:is_mouse_over_grid(ctx, 'active') then
      self.bridge:cancel_drag()
    else
      self.bridge:clear_drag()
    end
  end
end

function M.draw_pool(self, ctx, regions, height)
  self._imgui_ctx = ctx
  
  local cursor_x, cursor_y = ImGui.GetCursorScreenPos(ctx)
  local avail_w, _ = ImGui.GetContentRegionAvail(ctx)
  
  self.pool_bounds = {cursor_x, cursor_y, cursor_x + avail_w, cursor_y + height}
  self.bridge:update_bounds('pool', cursor_x, cursor_y, cursor_x + avail_w, cursor_y + height)
  
  self.pool_container.width = avail_w
  self.pool_container.height = height
  
  if not self.pool_container:begin_draw(ctx) then
    return
  end
  
  local header_height = 0
  if self.container_config.header and self.container_config.header.enabled then
    header_height = self.container_config.header.height or 36
  end
  
  local child_w = avail_w - (self.container_config.padding * 2)
  local child_h = (height - header_height) - (self.container_config.padding * 2)
  
  self.pool_grid.get_items = function() return regions end
  
  local raw_height, raw_gap = ResponsiveGrid.calculate_responsive_tile_height({
    item_count = #regions,
    avail_width = child_w,
    avail_height = child_h,
    base_gap = PoolTile.CONFIG.gap,
    min_col_width = PoolTile.CONFIG.tile_width,
    base_tile_height = self.responsive_config.base_tile_height_pool,
    min_tile_height = self.responsive_config.min_tile_height,
    responsive_config = self.responsive_config,
  })
  
  local responsive_height = self.pool_height_stabilizer:update(raw_height)
  
  self.current_pool_tile_height = responsive_height
  self.pool_grid.fixed_tile_h = responsive_height
  self.pool_grid.gap = raw_gap
  
  self.pool_grid:draw(ctx)
  
  self.pool_container:end_draw(ctx)
  
  if self.bridge:is_drag_active() and self.bridge:get_source_grid() == 'pool' and ImGui.IsMouseReleased(ctx, 0) then
    if not self.bridge:is_mouse_over_grid(ctx, 'active') then
      self.bridge:clear_drag()
    end
  end
end

function M.draw_ghosts(self, ctx)
  if not self.bridge:is_drag_active() then return nil end
  
  local mx, my = ImGui.GetMousePos(ctx)
  local count = self.bridge:get_drag_count()
  
  local colors = self:_get_drag_colors()
  local fg_dl = ImGui.GetForegroundDrawList(ctx)
  
  local is_over_active = self.bridge:is_mouse_over_grid(ctx, 'active')
  local is_over_pool = self.bridge:is_mouse_over_grid(ctx, 'pool')
  
  local target_grid = nil
  if is_over_active then
    target_grid = 'active'
  elseif is_over_pool then
    target_grid = 'pool'
  end
  
  local is_copy_mode = false
  local is_delete_mode = false
  
  if target_grid then
    is_copy_mode = self.bridge:compute_copy_mode(target_grid)
    is_delete_mode = self.bridge:compute_delete_mode(ctx, target_grid)
  else
    local source = self.bridge:get_source_grid()
    if source == 'active' then
      is_delete_mode = true
    end
  end
  
  DragIndicator.draw(ctx, fg_dl, mx, my, count, self.config.ghost_config, colors, is_copy_mode, is_delete_mode)
end

return M