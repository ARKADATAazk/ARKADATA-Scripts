-- Region_Playlist/app/gui.lua

local ImGui = require 'imgui' '0.10'
local RegionTiles = require("Region_Playlist.widgets.region_tiles.coordinator")
local Colors = require("ReArkitekt.core.colors")
local Shortcuts = require("Region_Playlist.app.shortcuts")
local PlaylistController = require("Region_Playlist.app.controller")
local TransportContainer = require("ReArkitekt.gui.widgets.transport.transport_container")
local Sheet = require("ReArkitekt.gui.widgets.overlay.sheet")
local ChipList = require("ReArkitekt.gui.widgets.chip_list.list")
local Config = require('Region_Playlist.app.config')

local M = {}
local GUI = {}
GUI.__index = GUI

function M.create(State, AppConfig, settings)
  local self = setmetatable({
    State = State,
    Config = Config,
    settings = settings,
    region_tiles = nil,
    layout_button_animator = nil,
    controller = nil,
    transport_container = nil,
    separator_drag_state = {
      is_dragging = false,
      drag_offset = 0
    },
    quantize_lookahead = Config.QUANTIZE.default_lookahead,
    overflow_modal_search = "",
  }, GUI)
  
  self.layout_button_animator = require('ReArkitekt.gui.fx.tile_motion').new(Config.ANIMATION.HOVER_SPEED)
  self.controller = PlaylistController.new(State, settings, State.state.undo_manager)
  
  self.transport_container = TransportContainer.new({
    id = "region_playlist_transport",
    height = Config.TRANSPORT.height,
  })
  
  State.state.bridge:set_controller(self.controller)
  State.state.bridge:set_playlist_lookup(State.get_playlist_by_id)
  
  if not State.state.separator_position_horizontal then
    State.state.separator_position_horizontal = Config.SEPARATOR.horizontal.default_position
  end
  if not State.state.separator_position_vertical then
    State.state.separator_position_vertical = Config.SEPARATOR.vertical.default_position
  end
  
  State.state.on_state_restored = function()
    self:refresh_tabs()
    if self.region_tiles.active_grid and self.region_tiles.active_grid.selection then
      self.region_tiles.active_grid.selection:clear()
    end
    if self.region_tiles.pool_grid and self.region_tiles.pool_grid.selection then
      self.region_tiles.pool_grid.selection:clear()
    end
  end
  
  State.state.on_repeat_cycle = function(key, current_loop, total_reps)
    reaper.ShowConsoleMsg(string.format("[GUI] Repeat cycle: %s (%d/%d)\n", key, current_loop, total_reps))
  end
  
  self.region_tiles = RegionTiles.create({
    controller = self.controller,
    
    get_region_by_rid = function(rid)
      return State.state.region_index[rid]
    end,
    
    get_playlist_by_id = function(playlist_id)
      return State.get_playlist_by_id(playlist_id)
    end,
    
    detect_circular_ref = function(target_playlist_id, source_playlist_id)
      return State.detect_circular_reference(target_playlist_id, source_playlist_id)
    end,
    
    allow_pool_reorder = true,
    enable_active_tabs = true,
    tabs = State.get_tabs(),
    active_tab_id = State.state.active_playlist,
    pool_mode = State.state.pool_mode,
    config = AppConfig.get_region_tiles_config(State.state.layout_mode),
    
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
    
    on_pool_mode_changed = function(mode)
      State.state.pool_mode = mode
      self.region_tiles:set_pool_mode(mode)
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
    
    on_pool_playlist_to_active = function(playlist_id, insert_index)
      local success, key = self.controller:add_playlist_item(State.state.active_playlist, playlist_id, insert_index)
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
    
    on_pool_playlist_double_click = function(playlist_id)
      local active_playlist_id = State.state.active_playlist
      
      if State.detect_circular_reference then
        local circular, path = State.detect_circular_reference(active_playlist_id, playlist_id)
        if circular then
          local path_str = table.concat(path, " → ")
          reaper.ShowConsoleMsg(string.format("Circular reference detected: %s\n", path_str))
          reaper.MB("Cannot add playlist: circular reference detected.\n\nPath: " .. path_str, "Circular Reference", 0)
          return
        end
      end
      
      local success, key = self.controller:add_playlist_item(State.state.active_playlist, playlist_id)
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
  self.region_tiles:set_pool_mode(State.state.pool_mode)
  
  State.state.active_search_filter = ""
  
  return self
end

function GUI:refresh_tabs()
  self.region_tiles:set_tabs(self.State.get_tabs(), self.State.state.active_playlist)
end

function GUI:draw_overflow_modal(ctx, window)
  if not self.region_tiles.active_container or not self.region_tiles.active_container:is_overflow_visible() then 
    return 
  end
  
  local all_tabs = self.State.get_tabs()
  
  local tab_items = {}
  for _, tab in ipairs(all_tabs) do
    table.insert(tab_items, {
      id = tab.id,
      label = tab.label,
      color = tab.chip_color or 0x888888FF,
    })
  end
  
  local active_id = self.State.state.active_playlist
  local selected_ids = {}
  selected_ids[active_id] = true
  
  -- Fallback: Use simple popup if no overlay system
  if not window or not window.overlay then
    ImGui.OpenPopup(ctx, "##overflow_tabs_popup")
    
    ImGui.SetNextWindowSize(ctx, 600, 500, ImGui.Cond_FirstUseEver)
    
    if ImGui.BeginPopupModal(ctx, "##overflow_tabs_popup", true, ImGui.WindowFlags_NoTitleBar) then
      ImGui.Text(ctx, "All Playlists:")
      ImGui.Separator(ctx)
      ImGui.Dummy(ctx, 0, 8)
      
      ImGui.SetNextItemWidth(ctx, -1)
      local changed, text = ImGui.InputTextWithHint(ctx, "##tab_search", "Search playlists...", self.overflow_modal_search)
      if changed then 
        self.overflow_modal_search = text 
      end
      
      ImGui.Dummy(ctx, 0, 8)
      
      if ImGui.BeginChild(ctx, "##tab_list", 0, -40) then
        local clicked_tab = ChipList.draw_columns(ctx, tab_items, {
          selected_ids = selected_ids,
          search_text = self.overflow_modal_search,
          use_dot_style = true,
          bg_color = 0x252530FF,
          dot_size = 7,
          dot_spacing = 7,
          rounding = 5,
          padding_h = 12,
          column_width = 200,
          column_spacing = 16,
          item_spacing = 4,
        })
        
        if clicked_tab then
          self.State.set_active_playlist(clicked_tab)
          ImGui.CloseCurrentPopup(ctx)
          self.region_tiles.active_container:close_overflow_modal()
        end
      end
      ImGui.EndChild(ctx)
      
      ImGui.Separator(ctx)
      ImGui.Dummy(ctx, 0, 4)
      
      local button_w = 100
      local avail_w = ImGui.GetContentRegionAvail(ctx)
      ImGui.SetCursorPosX(ctx, (avail_w - button_w) * 0.5)
      
      if ImGui.Button(ctx, "Close", button_w, 0) then
        ImGui.CloseCurrentPopup(ctx)
        self.region_tiles.active_container:close_overflow_modal()
      end
      
      ImGui.EndPopup(ctx)
    else
      self.region_tiles.active_container:close_overflow_modal()
    end
    
    return
  end
  
  -- Original overlay system path
  window.overlay:push({
    id = 'overflow-tabs',
    close_on_scrim = true,
    esc_to_close = true,
    render = function(ctx, alpha, bounds)
      Sheet.render(ctx, alpha, bounds, function(ctx, w, h, a)
        local padding_h = 16
        
        ImGui.SetCursorPos(ctx, padding_h, 16)
        ImGui.Text(ctx, "All Playlists:")
        ImGui.SetCursorPosX(ctx, padding_h)
        ImGui.SetNextItemWidth(ctx, w - padding_h * 2)
        local changed, text = ImGui.InputTextWithHint(ctx, "##tab_search", "Search playlists...", self.overflow_modal_search)
        if changed then 
          self.overflow_modal_search = text 
        end
        
        ImGui.Dummy(ctx, 0, 12)
        ImGui.SetCursorPosX(ctx, padding_h)
        ImGui.Separator(ctx)
        ImGui.Dummy(ctx, 0, 12)
        
        ImGui.SetCursorPosX(ctx, padding_h)
        
        local clicked_tab = ChipList.draw_columns(ctx, tab_items, {
          selected_ids = selected_ids,
          search_text = self.overflow_modal_search,
          use_dot_style = true,
          bg_color = 0x252530FF,
          dot_size = 7,
          dot_spacing = 7,
          rounding = 5,
          padding_h = 12,
          column_width = 200,
          column_spacing = 16,
          item_spacing = 4,
        })
        
        if clicked_tab then
          self.State.set_active_playlist(clicked_tab)
          window.overlay:pop('overflow-tabs')
          self.region_tiles.active_container:close_overflow_modal()
        end
        
        ImGui.Dummy(ctx, 0, 20)
        ImGui.SetCursorPosX(ctx, padding_h)
        ImGui.Separator(ctx)
        ImGui.Dummy(ctx, 0, 12)
        
        local button_w = 100
        local start_x = (w - button_w) * 0.5
        
        ImGui.SetCursorPosX(ctx, start_x)
        if ImGui.Button(ctx, "Close", button_w, 32) then
          window.overlay:pop('overflow-tabs')
          self.region_tiles.active_container:close_overflow_modal()
        end
      end, { 
        title = "Select Playlist", 
        width = 0.6, 
        height = 0.7 
      })
    end
  })
end

function GUI:draw_transport_section(ctx)
  local content_w, content_h = self.transport_container:begin_draw(ctx)
  
  local spacing = 12
  local current_x = 0
  
  ImGui.SetCursorPosX(ctx, current_x)
  self:draw_layout_toggle_button(ctx)
  current_x = ImGui.GetCursorPosX(ctx)
  
  ImGui.SetCursorPosX(ctx, current_x)
  self:draw_transport_override_checkbox(ctx)
  current_x = ImGui.GetCursorPosX(ctx)
  
  ImGui.SetCursorPosX(ctx, current_x)
  self:draw_loop_playlist_checkbox(ctx)
  current_x = ImGui.GetCursorPosX(ctx)
  
  ImGui.Dummy(ctx, 1, 10)
  
  local engine = self.State.state.bridge.engine
  if engine and engine.quantize then
    local current_mode = engine.quantize:get_quantize_mode()
    
    local grid_options = self.Config.QUANTIZE.grid_options
    
    local current_idx = 1
    for i, opt in ipairs(grid_options) do
      if opt.value == current_mode then
        current_idx = i
        break
      end
    end
    
    ImGui.Text(ctx, "Jump Mode:")
    ImGui.SameLine(ctx, 0, 8)
    ImGui.SetNextItemWidth(ctx, 140)
    
    if ImGui.BeginCombo(ctx, "##quantize_mode", grid_options[current_idx].label) then
      for i, opt in ipairs(grid_options) do
        local is_selected = (i == current_idx)
        if ImGui.Selectable(ctx, opt.label, is_selected) then
          engine.quantize:set_quantize_mode(opt.value)
        end
        if is_selected then
          ImGui.SetItemDefaultFocus(ctx)
        end
      end
      ImGui.EndCombo(ctx)
    end
    
    ImGui.SameLine(ctx, 0, 12)
  end
  
  local min_lookahead = 10
  local max_lookahead = 200
  
  if engine and engine.quantize then
    min_lookahead = engine.quantize.min_lookahead * 1000
    max_lookahead = engine.quantize.max_lookahead * 1000
  end
  
  ImGui.Text(ctx, "Lookahead (ms):")
  ImGui.SameLine(ctx, 0, 8)
  ImGui.SetNextItemWidth(ctx, 120)
  local changed, new_val = ImGui.SliderDouble(
    ctx, 
    "##lookahead", 
    self.quantize_lookahead * 1000, 
    min_lookahead,
    max_lookahead,
    "%.0f"
  )
  if changed then
    self.quantize_lookahead = new_val / 1000
  end
  
  ImGui.SameLine(ctx, 0, 12)
  
  local bridge_state = self.State.state.bridge:get_state()
  local is_disabled = not bridge_state.is_playing
  
  if is_disabled then
    ImGui.BeginDisabled(ctx)
  end
  
  local button_label = "Jump to Next"
  if engine and engine.quantize then
    local mode = engine.quantize:get_quantize_mode()
    if mode == "measure" then
      button_label = "Jump on Next Measure"
    else
      local grid_val = tonumber(mode)
      if grid_val == 4.0 then
        button_label = "Jump on Next Bar"
      elseif grid_val == 2.0 then
        button_label = "Jump on Next 1/2"
      elseif grid_val == 1.0 then
        button_label = "Jump on Next 1/4"
      elseif grid_val == 0.5 then
        button_label = "Jump on Next 1/8"
      elseif grid_val == 0.25 then
        button_label = "Jump on Next 1/16"
      elseif grid_val == 0.125 then
        button_label = "Jump on Next 1/32"
      elseif grid_val == 0.0625 then
        button_label = "Jump on Next 1/64"
      else
        button_label = "Jump on Next Grid"
      end
    end
  end
  
  if ImGui.Button(ctx, button_label) then
    self.State.state.bridge:jump_to_next_quantized(self.quantize_lookahead)
  end
  
  if is_disabled then
    ImGui.EndDisabled(ctx)
  end
  
  if ImGui.IsItemHovered(ctx, ImGui.HoveredFlags_AllowWhenDisabled) then
    if is_disabled then
      ImGui.SetTooltip(ctx, "Start playback to enable")
    else
      ImGui.SetTooltip(ctx, "Jump to next quantize point")
    end
  end
  
  self.transport_container:end_draw(ctx)
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

function GUI:draw_loop_playlist_checkbox(ctx)
  local bridge = self.State.state.bridge
  if not bridge then return end
  
  local loop_playlist = bridge:get_loop_playlist()
  local changed, new_value = ImGui.Checkbox(ctx, "Loop Playlist", loop_playlist)
  
  if ImGui.IsItemHovered(ctx) then
    ImGui.SetTooltip(ctx, "Wrap to start when reaching\nthe end of the playlist")
  end
  
  if changed then
    bridge:set_loop_playlist(new_value)
  end
  
  ImGui.SameLine(ctx, 0, 12)
end

function GUI:draw_horizontal_separator(ctx, x, y, width, height)
  local separator_config = self.Config.SEPARATOR.horizontal
  local separator_thickness = separator_config.thickness
  
  local mx, my = ImGui.GetMousePos(ctx)
  local is_hovered = mx >= x and mx < x + width and 
                     my >= y - separator_thickness/2 and my < y + separator_thickness/2
  
  if is_hovered or self.separator_drag_state.is_dragging then
    ImGui.SetMouseCursor(ctx, ImGui.MouseCursor_ResizeNS)
  end
  
  ImGui.SetCursorScreenPos(ctx, x, y - separator_thickness/2)
  ImGui.InvisibleButton(ctx, "##hseparator", width, separator_thickness)
  
  if ImGui.IsItemHovered(ctx) and ImGui.IsMouseDoubleClicked(ctx, 0) then
    return "reset", 0
  end
  
  if ImGui.IsItemActive(ctx) then
    if not self.separator_drag_state.is_dragging then
      self.separator_drag_state.is_dragging = true
      self.separator_drag_state.drag_offset = my - y
    end
    
    local new_pos = my - self.separator_drag_state.drag_offset
    return "drag", new_pos
  elseif self.separator_drag_state.is_dragging and not ImGui.IsMouseDown(ctx, 0) then
    self.separator_drag_state.is_dragging = false
  end
  
  return "none", y
end

function GUI:draw_vertical_separator(ctx, x, y, width, height)
  local separator_config = self.Config.SEPARATOR.vertical
  local separator_thickness = separator_config.thickness
  
  local mx, my = ImGui.GetMousePos(ctx)
  local is_hovered = mx >= x - separator_thickness/2 and mx < x + separator_thickness/2 and 
                     my >= y and my < y + height
  
  if is_hovered or self.separator_drag_state.is_dragging then
    ImGui.SetMouseCursor(ctx, ImGui.MouseCursor_ResizeEW)
  end
  
  ImGui.SetCursorScreenPos(ctx, x - separator_thickness/2, y)
  ImGui.InvisibleButton(ctx, "##vseparator", separator_thickness, height)
  
  if ImGui.IsItemHovered(ctx) and ImGui.IsMouseDoubleClicked(ctx, 0) then
    return "reset", 0
  end
  
  if ImGui.IsItemActive(ctx) then
    if not self.separator_drag_state.is_dragging then
      self.separator_drag_state.is_dragging = true
      self.separator_drag_state.drag_offset = mx - x
    end
    
    local new_pos = mx - self.separator_drag_state.drag_offset
    return "drag", new_pos
  elseif self.separator_drag_state.is_dragging and not ImGui.IsMouseDown(ctx, 0) then
    self.separator_drag_state.is_dragging = false
  end
  
  return "none", x
end

function GUI:get_filtered_active_items(playlist)
  local filter = self.State.state.active_search_filter or ""
  
  if filter == "" then
    return playlist.items
  end
  
  local filtered = {}
  local filter_lower = filter:lower()
  
  for _, item in ipairs(playlist.items) do
    if item.type == "playlist" then
      local playlist_data = self.State.get_playlist_by_id(item.playlist_id)
      local name_lower = playlist_data and playlist_data.name:lower() or ""
      if name_lower:find(filter_lower, 1, true) then
        filtered[#filtered + 1] = item
      end
    else
      local region = self.State.state.region_index[item.rid]
      if region then
        local name_lower = region.name:lower()
        if name_lower:find(filter_lower, 1, true) then
          filtered[#filtered + 1] = item
        end
      end
    end
  end
  
  return filtered
end

function GUI:draw(ctx, window)
  if self.region_tiles.active_container and self.region_tiles.active_container:is_overflow_visible() then
    self:draw_overflow_modal(ctx, window)
  end
  
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
  
  self:draw_transport_section(ctx)
  
  ImGui.Dummy(ctx, 1, 8)
  
  local pl = self.State.get_active_playlist()
  local filtered_active_items = self:get_filtered_active_items(pl)
  local display_playlist = {
    id = pl.id,
    name = pl.name,
    items = filtered_active_items,
  }
  
  local pool_data
  if self.State.state.pool_mode == "playlists" then
    pool_data = self.State.get_playlists_for_pool()
  else
    pool_data = self.State.get_filtered_pool_regions()
  end
  
  if self.State.state.layout_mode == 'horizontal' then
    local content_w, content_h = ImGui.GetContentRegionAvail(ctx)
    
    local separator_config = self.Config.SEPARATOR.horizontal
    local min_active_height = separator_config.min_active_height
    local min_pool_height = separator_config.min_pool_height
    local separator_gap = separator_config.gap
    
    local min_total_height = min_active_height + min_pool_height + separator_gap
    
    local active_height, pool_height
    
    if content_h < min_total_height then
      local ratio = content_h / min_total_height
      active_height = math.floor(min_active_height * ratio)
      pool_height = content_h - active_height - separator_gap
      
      if active_height < 50 then active_height = 50 end
      if pool_height < 50 then pool_height = 50 end
      
      pool_height = math.max(1, content_h - active_height - separator_gap)
    else
      active_height = self.State.state.separator_position_horizontal
      active_height = math.max(min_active_height, math.min(active_height, content_h - min_pool_height - separator_gap))
      pool_height = content_h - active_height - separator_gap
    end
    
    active_height = math.max(1, active_height)
    pool_height = math.max(1, pool_height)
    
    local start_x, start_y = ImGui.GetCursorScreenPos(ctx)
    
    self.region_tiles:draw_active(ctx, display_playlist, active_height)
    
    local separator_y = start_y + active_height + separator_gap/2
    local action, value = self:draw_horizontal_separator(ctx, start_x, separator_y, content_w, content_h)
    
    if action == "reset" then
      self.State.state.separator_position_horizontal = separator_config.default_position
      self.State.persist_ui_prefs()
    elseif action == "drag" and content_h >= min_total_height then
      local new_active_height = value - start_y - separator_gap/2
      new_active_height = math.max(min_active_height, math.min(new_active_height, content_h - min_pool_height - separator_gap))
      self.State.state.separator_position_horizontal = new_active_height
      self.State.persist_ui_prefs()
    end
    
    ImGui.SetCursorScreenPos(ctx, start_x, start_y + active_height + separator_gap)
    
    self.region_tiles:draw_pool(ctx, pool_data, pool_height)
  else
    local content_w, content_h = ImGui.GetContentRegionAvail(ctx)
    
    local separator_config = self.Config.SEPARATOR.vertical
    local min_active_width = separator_config.min_active_width
    local min_pool_width = separator_config.min_pool_width
    local separator_gap = separator_config.gap
    
    local min_total_width = min_active_width + min_pool_width + separator_gap
    
    local active_width, pool_width
    
    if content_w < min_total_width then
      local ratio = content_w / min_total_width
      active_width = math.floor(min_active_width * ratio)
      pool_width = content_w - active_width - separator_gap
      
      if active_width < 50 then active_width = 50 end
      if pool_width < 50 then pool_width = 50 end
      
      pool_width = math.max(1, content_w - active_width - separator_gap)
    else
      active_width = self.State.state.separator_position_vertical
      active_width = math.max(min_active_width, math.min(active_width, content_w - min_pool_width - separator_gap))
      pool_width = content_w - active_width - separator_gap
    end
    
    active_width = math.max(1, active_width)
    pool_width = math.max(1, pool_width)
    
    local start_cursor_x, start_cursor_y = ImGui.GetCursorScreenPos(ctx)
    
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing, 0, 0)
    
    if ImGui.BeginChild(ctx, "##left_column", active_width, content_h, ImGui.ChildFlags_None, 0) then
      self.region_tiles:draw_active(ctx, display_playlist, content_h)
    end
    ImGui.EndChild(ctx)
    
    ImGui.PopStyleVar(ctx)
    
    local separator_x = start_cursor_x + active_width + separator_gap/2
    local action, value = self:draw_vertical_separator(ctx, separator_x, start_cursor_y, content_w, content_h)
    
    if action == "reset" then
      self.State.state.separator_position_vertical = separator_config.default_position
      self.State.persist_ui_prefs()
    elseif action == "drag" and content_w >= min_total_width then
      local new_active_width = value - start_cursor_x - separator_gap/2
      new_active_width = math.max(min_active_width, math.min(new_active_width, content_w - min_pool_width - separator_gap))
      self.State.state.separator_position_vertical = new_active_width
      self.State.persist_ui_prefs()
    end
    
    ImGui.SetCursorScreenPos(ctx, start_cursor_x + active_width + separator_gap, start_cursor_y)
    
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing, 0, 0)
    
    if ImGui.BeginChild(ctx, "##right_column", pool_width, content_h, ImGui.ChildFlags_None, 0) then
      self.region_tiles:draw_pool(ctx, pool_data, content_h)
    end
    ImGui.EndChild(ctx)
    
    ImGui.PopStyleVar(ctx)
  end
  
  self.region_tiles:draw_ghosts(ctx)
end

return M