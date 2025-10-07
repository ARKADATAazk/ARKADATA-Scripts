-- Region_Playlist/app/gui.lua
-- GUI rendering - thin adapter to controller

local ImGui = require 'imgui' '0.10'
local RegionTiles = require("ReArkitekt.gui.widgets.region_tiles.coordinator")
local Colors = require("ReArkitekt.core.colors")
local Shortcuts = require("Region_Playlist.app.shortcuts")
local PlaylistController = require("ReArkitekt.features.region_playlist.playlist_controller")

local M = {}
local GUI = {}
GUI.__index = GUI

function M.create(State, Config, settings)
  local self = setmetatable({
    State = State,
    Config = Config,
    settings = settings,
    region_tiles = nil,
    layout_button_animator = nil,
    controller = nil,
  }, GUI)
  
  self.layout_button_animator = require('ReArkitekt.gui.fx.tile_motion').new(Config.LAYOUT_BUTTON.animation_speed)
  self.controller = PlaylistController.new(State, settings, State.state.undo_manager)
  
  State.state.bridge:set_controller(self.controller)
  
  State.state.on_state_restored = function()
    self:refresh_tabs()
    if self.region_tiles.active_grid and self.region_tiles.active_grid.selection then
      self.region_tiles.active_grid.selection:clear()
    end
    if self.region_tiles.pool_grid and self.region_tiles.pool_grid.selection then
      self.region_tiles.pool_grid.selection:clear()
    end
  end
  
  self.region_tiles = RegionTiles.create({
    get_region_by_rid = function(rid)
      return State.state.region_index[rid]
    end,
    
    allow_pool_reorder = true,
    enable_active_tabs = true,
    tabs = State.get_tabs(),
    active_tab_id = State.state.active_playlist,
    config = Config.get_region_tiles_config(State.state.layout_mode),
    
    on_tab_create = function()
      self.controller:create_playlist()
      self:refresh_tabs()
    end,
    
    on_tab_change = function(new_id)
      State.set_active_playlist(new_id)
    end,
    
    on_tab_delete = function(id)
      if self.controller:delete_playlist(id) then
        self:refresh_tabs()
      end
    end,
    
    on_tab_reorder = function(source_index, target_index)
      if self.controller:reorder_playlists(source_index, target_index) then
        self:refresh_tabs()
      end
    end,
    
    on_active_search = function(text)
      State.state.active_search_filter = text or ""
    end,
    
    on_playlist_changed = function(new_id)
      State.set_active_playlist(new_id)
    end,
    
    on_pool_search = function(text)
      State.state.search_filter = text
      State.persist_ui_prefs()
    end,
    
    on_pool_sort = function(mode)
      State.state.sort_mode = mode
      State.persist_ui_prefs()
    end,

    on_pool_sort_direction = function(direction)
      State.state.sort_direction = direction
      State.persist_ui_prefs()
    end,    
    
    on_active_reorder = function(new_order)
      self.controller:reorder_items(State.state.active_playlist, new_order)
    end,
    
    on_active_remove = function(item_key)
      self.controller:delete_items(State.state.active_playlist, {item_key})
    end,
    
    on_active_toggle_enabled = function(item_key, new_state)
      self.controller:toggle_item_enabled(State.state.active_playlist, item_key, new_state)
    end,
    
    on_active_delete = function(item_keys)
      self.controller:delete_items(State.state.active_playlist, item_keys)
      for _, key in ipairs(item_keys) do
        State.state.pending_destroy[#State.state.pending_destroy + 1] = key
      end
    end,
    
    on_destroy_complete = function(key)
    end,
    
    on_active_copy = function(dragged_items, target_index)
      local success, keys = self.controller:copy_items(State.state.active_playlist, dragged_items, target_index)
      if success and keys then
        for _, key in ipairs(keys) do
          State.state.pending_spawn[#State.state.pending_spawn + 1] = key
          State.state.pending_select[#State.state.pending_select + 1] = key
        end
      end
    end,
    
    on_pool_to_active = function(rid, insert_index)
      local success, key = self.controller:add_item(State.state.active_playlist, rid, insert_index)
      return success and key or nil
    end,
    
    on_pool_reorder = function(new_rids)
      State.state.pool_order = new_rids
      State.persist_ui_prefs()
    end,
    
    on_repeat_cycle = function(item_key)
      self.controller:cycle_repeats(State.state.active_playlist, item_key)
    end,
    
    on_repeat_adjust = function(keys, delta)
      self.controller:adjust_repeats(State.state.active_playlist, keys, delta)
    end,
    
    on_repeat_sync = function(keys, target_reps)
      self.controller:sync_repeats(State.state.active_playlist, keys, target_reps)
    end,
    
    on_pool_double_click = function(rid)
      local success, key = self.controller:add_item(State.state.active_playlist, rid)
      if success and key then
        State.state.pending_spawn[#State.state.pending_spawn + 1] = key
        State.state.pending_select[#State.state.pending_select + 1] = key
      end
    end,
    
    settings = settings,
  })
  
  self.region_tiles:set_pool_search_text(State.state.search_filter)
  self.region_tiles:set_pool_sort_mode(State.state.sort_mode)
  self.region_tiles:set_pool_sort_direction(State.state.sort_direction)
  self.region_tiles:set_app_bridge(State.state.bridge)
  
  State.state.active_search_filter = ""
  
  return self
end

function GUI:refresh_tabs()
  self.region_tiles:set_tabs(self.State.get_tabs(), self.State.state.active_playlist)
end

function GUI:draw_layout_toggle_button(ctx)
  local dl = ImGui.GetWindowDrawList(ctx)
  local cursor_x, cursor_y = ImGui.GetCursorScreenPos(ctx)
  
  local config = self.Config.LAYOUT_BUTTON
  local btn_w = config.width
  local btn_h = config.height
  
  local mx, my = ImGui.GetMousePos(ctx)
  local is_hovered = mx >= cursor_x and mx < cursor_x + btn_w and my >= cursor_y and my < cursor_y + btn_h
  
  self.layout_button_animator:track('btn', 'hover', is_hovered and 1.0 or 0.0, config.animation_speed)
  local hover_factor = self.layout_button_animator:get('btn', 'hover')
  
  local bg_color = Colors.lerp(config.bg_color, config.bg_hover, hover_factor)
  local border_color = Colors.lerp(config.border_color, config.border_hover, hover_factor)
  local icon_color = Colors.lerp(config.icon_color, config.icon_hover, hover_factor)
  
  ImGui.DrawList_AddRectFilled(dl, cursor_x, cursor_y, cursor_x + btn_w, cursor_y + btn_h, 
                                bg_color, config.rounding)
  ImGui.DrawList_AddRect(dl, cursor_x + 0.5, cursor_y + 0.5, cursor_x + btn_w - 0.5, cursor_y + btn_h - 0.5, 
                        border_color, config.rounding, 0, 1)
  
  local padding = 6
  local icon_x = cursor_x + padding
  local icon_y = cursor_y + padding
  local icon_w = btn_w - padding * 2
  local icon_h = btn_h - padding * 2
  
  if self.State.state.layout_mode == 'horizontal' then
    local bar_h = 3
    local gap = 2
    local bar_w = icon_w
    
    for i = 0, 2 do
      local bar_y = icon_y + i * (bar_h + gap)
      ImGui.DrawList_AddRectFilled(dl, icon_x, bar_y, icon_x + bar_w, bar_y + bar_h, 
                                    icon_color, 1)
    end
  else
    local bar_w = 3
    local gap = 2
    local bar_h = icon_h
    
    for i = 0, 2 do
      local bar_x = icon_x + i * (bar_w + gap)
      ImGui.DrawList_AddRectFilled(dl, bar_x, icon_y, bar_x + bar_w, icon_y + bar_h, 
                                    icon_color, 1)
    end
  end
  
  ImGui.SetCursorScreenPos(ctx, cursor_x, cursor_y)
  local _ = ImGui.InvisibleButton(ctx, "##layout_toggle", btn_w, btn_h)
  
  if ImGui.IsItemClicked(ctx, 0) then
    self.State.state.layout_mode = (self.State.state.layout_mode == 'horizontal') and 'vertical' or 'horizontal'
    self.region_tiles:set_layout_mode(self.State.state.layout_mode)
    self.State.persist_ui_prefs()
  end
  
  if ImGui.IsItemHovered(ctx) then
    local tooltip = self.State.state.layout_mode == 'horizontal' and "Switch to List Mode" or "Switch to Timeline Mode"
    ImGui.SetTooltip(ctx, tooltip)
  end
  
  ImGui.SameLine(ctx, 0, 12)
end

function GUI:draw_transport_override_checkbox(ctx)
  local engine = self.State.state.bridge.engine
  if not engine then return end
  
  local transport_override = engine:get_transport_override()
  local changed, new_value = ImGui.Checkbox(ctx, "Transport Override", transport_override)
  
  if ImGui.IsItemHovered(ctx) then
    ImGui.SetTooltip(ctx, "Sync playlist when REAPER playhead\nenters any active region")
  end
  
  if changed then
    engine:set_transport_override(new_value)
    if self.settings then 
      self.settings:set('transport_override', new_value) 
    end
  end
  
  ImGui.SameLine(ctx, 0, 12)
end

function GUI:get_filtered_active_items(playlist)
  local filter = self.State.state.active_search_filter or ""
  
  if filter == "" then
    return playlist.items
  end
  
  local filtered = {}
  local filter_lower = filter:lower()
  
  for _, item in ipairs(playlist.items) do
    local region = self.State.state.region_index[item.rid]
    if region then
      local name_lower = region.name:lower()
      if name_lower:find(filter_lower, 1, true) then
        filtered[#filtered + 1] = item
      end
    end
  end
  
  return filtered
end

function GUI:draw(ctx)
  self.State.state.bridge:update()
  self.State.update()
  
  if #self.State.state.pending_spawn > 0 then
    self.region_tiles.active_grid:mark_spawned(self.State.state.pending_spawn)
    self.State.state.pending_spawn = {}
  end
  
  if #self.State.state.pending_select > 0 then
    if self.region_tiles.pool_grid and self.region_tiles.pool_grid.selection then
      self.region_tiles.pool_grid.selection:clear()
    end
    if self.region_tiles.active_grid and self.region_tiles.active_grid.selection then
      self.region_tiles.active_grid.selection:clear()
    end
    
    for _, key in ipairs(self.State.state.pending_select) do
      if self.region_tiles.active_grid.selection then
        self.region_tiles.active_grid.selection.selected[key] = true
      end
    end
    
    if self.region_tiles.active_grid.selection then
      self.region_tiles.active_grid.selection.last_clicked = self.State.state.pending_select[#self.State.state.pending_select]
    end
    
    if self.region_tiles.active_grid.behaviors and self.region_tiles.active_grid.behaviors.on_select and self.region_tiles.active_grid.selection then
      self.region_tiles.active_grid.behaviors.on_select(self.region_tiles.active_grid.selection:selected_keys())
    end
    
    self.State.state.pending_select = {}
  end
  
  if #self.State.state.pending_destroy > 0 then
    self.region_tiles.active_grid:mark_destroyed(self.State.state.pending_destroy)
    self.State.state.pending_destroy = {}
  end
  
  self.region_tiles:update_animations(0.016)
  self.layout_button_animator:update(0.016)
  
  Shortcuts.handle_keyboard_shortcuts(ctx, self.State.state, self.region_tiles)
  
  local avail_w, avail_h = ImGui.GetContentRegionAvail(ctx)
  local status_bar_height = 34
  local content_h = math.floor(avail_h - status_bar_height + 0.5)
  
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding, 12, 12)
  
  local child_flags = ImGui.ChildFlags_AlwaysUseWindowPadding
  local window_flags = ImGui.WindowFlags_NoScrollbar
  local _ = ImGui.BeginChild(ctx, "##content", 0, content_h, child_flags, window_flags)
  
  self:draw_layout_toggle_button(ctx)
  self:draw_transport_override_checkbox(ctx)
  
  ImGui.Dummy(ctx, 1, 16)
  
  local pl = self.State.get_active_playlist()
  local filtered_active_items = self:get_filtered_active_items(pl)
  local display_playlist = {
    id = pl.id,
    name = pl.name,
    items = filtered_active_items,
  }
  local filtered_regions = self.State.get_filtered_pool_regions()
  
  if self.State.state.layout_mode == 'horizontal' then
    local active_height = 180
    local pool_height = 280
    
    ImGui.Text(ctx, "ACTIVE SEQUENCE")
    ImGui.Dummy(ctx, 1, 4)
    self.region_tiles:draw_active(ctx, display_playlist, active_height)
    
    ImGui.Dummy(ctx, 1, 16)
    
    ImGui.Text(ctx, "REGION POOL")
    ImGui.Dummy(ctx, 1, 4)
    self.region_tiles:draw_pool(ctx, filtered_regions, pool_height)
  else
    local content_w, content_h = ImGui.GetContentRegionAvail(ctx)
    
    local active_width = 280
    local gap = 16
    local pool_width = content_w - active_width - gap
    
    local start_cursor_x, start_cursor_y = ImGui.GetCursorScreenPos(ctx)
    
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing, 0, 0)
    
    if ImGui.BeginChild(ctx, "##left_column", active_width, content_h, ImGui.ChildFlags_None, 0) then
      ImGui.Text(ctx, "ACTIVE SEQUENCE")
      ImGui.Dummy(ctx, 1, 4)
      local label_consumed = ImGui.GetCursorPosY(ctx)
      self.region_tiles:draw_active(ctx, display_playlist, content_h - label_consumed)
    end
    ImGui.EndChild(ctx)
    
    ImGui.PopStyleVar(ctx)
    
    ImGui.SetCursorScreenPos(ctx, start_cursor_x + active_width + gap, start_cursor_y)
    
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing, 0, 0)
    
    if ImGui.BeginChild(ctx, "##right_column", pool_width, content_h, ImGui.ChildFlags_None, 0) then
      ImGui.Text(ctx, "REGION POOL")
      ImGui.Dummy(ctx, 1, 4)
      local label_consumed = ImGui.GetCursorPosY(ctx)
      self.region_tiles:draw_pool(ctx, filtered_regions, content_h - label_consumed)
    end
    ImGui.EndChild(ctx)
    
    ImGui.PopStyleVar(ctx)
  end
  
  ImGui.EndChild(ctx)
  ImGui.PopStyleVar(ctx)
  
  self.region_tiles:draw_ghosts(ctx)
end

return M