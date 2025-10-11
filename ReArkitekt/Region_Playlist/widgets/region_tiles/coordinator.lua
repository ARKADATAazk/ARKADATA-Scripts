-- ReArkitekt/gui/widgets/region_tiles/coordinator.lua

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.10'

local Config = require('Region_Playlist.app.config')
local Render = require('Region_Playlist.widgets.region_tiles.coordinator_render')
local Draw = require('ReArkitekt.gui.draw')
local Colors = require('ReArkitekt.core.colors')
local TileAnim = require('ReArkitekt.gui.fx.tile_motion')
local HeightStabilizer = require('ReArkitekt.gui.systems.height_stabilizer')
local Selector = require('Region_Playlist.widgets.region_tiles.selector')
local ActiveGridFactory = require('Region_Playlist.widgets.region_tiles.active_grid_factory')
local PoolGridFactory = require('Region_Playlist.widgets.region_tiles.pool_grid_factory')
local GridBridge = require('ReArkitekt.gui.widgets.grid.grid_bridge')
local TilesContainer = require('ReArkitekt.gui.widgets.panel')
local State = require("Region_Playlist.app.state")

local M = {}

local RegionTiles = {}
RegionTiles.__index = RegionTiles

local playlist_cache = {}
local cache_frame_time = 0

local function cached_get_playlist_by_id(get_fn, playlist_id)
  local current_time = reaper.time_precise()
  
  if current_time ~= cache_frame_time then
    playlist_cache = {}
    cache_frame_time = current_time
  end
  
  if not playlist_cache[playlist_id] then
    playlist_cache[playlist_id] = get_fn(playlist_id)
  end
  
  return playlist_cache[playlist_id]
end

function M.create(opts)
  opts = opts or {}
  
  local config = opts.config or {}
  
  local raw_get_playlist = opts.get_playlist_by_id
  local cached_get_playlist = function(id)
    return cached_get_playlist_by_id(raw_get_playlist, id)
  end
  
  local rt = setmetatable({
    controller = opts.controller,
    get_region_by_rid = opts.get_region_by_rid,
    get_playlist_by_id = cached_get_playlist,
    detect_circular_ref = opts.detect_circular_ref,
    on_playlist_changed = opts.on_playlist_changed,
    on_active_reorder = opts.on_active_reorder,
    on_active_remove = opts.on_active_remove,
    on_active_copy = opts.on_active_copy,
    on_active_toggle_enabled = opts.on_active_toggle_enabled,
    on_active_delete = opts.on_active_delete,
    on_destroy_complete = opts.on_destroy_complete,
    on_pool_to_active = opts.on_pool_to_active,
    on_pool_playlist_to_active = opts.on_pool_playlist_to_active,
    on_pool_reorder = opts.on_pool_reorder,
    on_repeat_cycle = opts.on_repeat_cycle,
    on_repeat_adjust = opts.on_repeat_adjust,
    on_repeat_sync = opts.on_repeat_sync,
    on_pool_double_click = opts.on_pool_double_click,
    on_pool_playlist_double_click = opts.on_pool_playlist_double_click,
    on_pool_search = opts.on_pool_search,
    on_pool_sort = opts.on_pool_sort,
    on_pool_sort_direction = opts.on_pool_sort_direction,
    on_pool_mode_changed = opts.on_pool_mode_changed,
    settings = opts.settings,
    
    allow_pool_reorder = opts.allow_pool_reorder ~= false,
    
    config = config,
    layout_mode = config.layout_mode,
    hover_config = config.hover_config,
    responsive_config = config.responsive_config,
    container_config = config.container,
    wheel_config = config.wheel_config,
    
    selector = Selector.new(),
    active_animator = TileAnim.new(config.hover_config.animation_speed_hover),
    pool_animator = TileAnim.new(config.hover_config.animation_speed_hover),
    
    active_bounds = nil,
    pool_bounds = nil,
    
    active_grid = nil,
    pool_grid = nil,
    bridge = nil,
    app_bridge = nil,
    
    wheel_consumed_this_frame = false,
    
    active_height_stabilizer = HeightStabilizer.new({
      stable_frames_required = config.responsive_config.stable_frames_required,
      height_hysteresis = config.responsive_config.height_hysteresis,
    }),
    pool_height_stabilizer = HeightStabilizer.new({
      stable_frames_required = config.responsive_config.stable_frames_required,
      height_hysteresis = config.responsive_config.height_hysteresis,
    }),
    
    current_active_tile_height = config.responsive_config.base_tile_height_active,
    current_pool_tile_height = config.responsive_config.base_tile_height_pool,
    
    _original_active_min_col_w = nil,
    _imgui_ctx = nil,
  }, RegionTiles)
  
  rt.active_grid = ActiveGridFactory.create(rt, config)
  rt._original_active_min_col_w = rt.active_grid.min_col_w_fn
  
  rt.pool_grid = PoolGridFactory.create(rt, config)
  
  -- Create active container with proper Panel config structure
  rt.active_container = TilesContainer.new({
    id = "active_tiles_container",
    config = Config.get_active_container_config({
      on_tab_create = function()
        if rt.controller then
          rt.controller:create_playlist()
          rt.active_container:set_tabs(State.get_tabs(), State.state.active_playlist)
        end
      end,
      
      on_tab_change = function(id)
        State.set_active_playlist(id)
        rt.active_container:set_active_tab_id(id)
      end,
      
on_tab_reorder = function(source_index, target_index)
  -- Just persist the reorder to State, don't refresh the tabs array
  if rt.controller then
    rt.controller:reorder_playlists(source_index, target_index)
  end
end,
      
      on_tab_delete = function(id)
        if rt.controller and rt.controller:delete_playlist(id) then
          rt.active_container:set_tabs(State.get_tabs(), State.state.active_playlist)
        end
      end,
      
      on_overflow_clicked = function()
        rt.active_container._overflow_visible = true
      end,
    })
  })

  -- Initialize tabs using Panel's public API
  rt.active_container:set_tabs(opts.tabs or {}, opts.active_tab_id)
  
  -- Create pool container with proper Panel config structure
  rt.pool_container = TilesContainer.new({
    id = "pool_tiles_container",
    config = Config.get_pool_container_config({
      on_mode_toggle = function()
        local new_mode = rt.pool_container.current_mode == "regions" and "playlists" or "regions"
        rt.pool_container.current_mode = new_mode
        if rt.on_pool_mode_changed then
          rt.on_pool_mode_changed(new_mode)
        end
      end,
      
      on_search_changed = function(text)
        if rt.on_pool_search then
          rt.on_pool_search(text)
        end
      end,
      
      on_sort_changed = function(mode)
        if rt.on_pool_sort then
          rt.on_pool_sort(mode)
        end
      end,
      
      on_sort_direction_changed = function(direction)
        if rt.on_pool_sort_direction then
          rt.on_pool_sort_direction(direction)
        end
      end,
    })
  })
  
  -- Initialize pool state
  rt.pool_container.current_mode = opts.pool_mode or "regions"
  
  rt.bridge = GridBridge.new({
    copy_mode_detector = function(source, target, payload)
      if source == 'pool' and target == 'active' then
        return true
      end
      
      if source == 'active' and target == 'active' then
        if rt._imgui_ctx then
          local ctrl = ImGui.IsKeyDown(rt._imgui_ctx, ImGui.Key_LeftCtrl) or 
                      ImGui.IsKeyDown(rt._imgui_ctx, ImGui.Key_RightCtrl)
          return ctrl
        end
      end
      
      return false
    end,
    
    delete_mode_detector = function(ctx, source, target, payload)
      if source == 'active' and target ~= 'active' then
        return not rt.bridge:is_mouse_over_grid(ctx, 'active')
      end
      return false
    end,
    
    on_cross_grid_drop = function(drop_info)
      if drop_info.source_grid == 'pool' and drop_info.target_grid == 'active' then
        local spawned_keys = {}
        local insert_index = drop_info.insert_index
        
        for _, item_data in ipairs(drop_info.payload) do
          local new_key = nil
          
          if type(item_data) == "number" then
            if rt.on_pool_to_active then
              new_key = rt.on_pool_to_active(item_data, insert_index)
            end
          elseif type(item_data) == "table" and item_data.type == "playlist" then
            local active_playlist_id = rt.active_container:get_active_tab_id()
            
            if rt.detect_circular_ref then
              local circular, path = rt.detect_circular_ref(active_playlist_id, item_data.id)
              if circular then
                local path_str = table.concat(path, " → ")
                reaper.ShowConsoleMsg(string.format("Circular reference detected: %s\n", path_str))
                reaper.MB("Cannot add playlist: circular reference detected.\n\nPath: " .. path_str, "Circular Reference", 0)
                goto continue_loop
              end
            end
            
            if rt.on_pool_playlist_to_active then
              new_key = rt.on_pool_playlist_to_active(item_data.id, insert_index)
            end
          end
          
          if new_key then
            spawned_keys[#spawned_keys + 1] = new_key
          end
          
          insert_index = insert_index + 1
          
          ::continue_loop::
        end
        
        if #spawned_keys > 0 then
          if rt.pool_grid and rt.pool_grid.selection then
            rt.pool_grid.selection:clear()
          end
          if rt.active_grid and rt.active_grid.selection then
            rt.active_grid.selection:clear()
          end
          
          rt.active_grid:mark_spawned(spawned_keys)
          
          for _, key in ipairs(spawned_keys) do
            if rt.active_grid.selection then
              rt.active_grid.selection.selected[key] = true
            end
          end
          
          if rt.active_grid.selection then
            rt.active_grid.selection.last_clicked = spawned_keys[#spawned_keys]
          end
          
          if rt.active_grid.behaviors and rt.active_grid.behaviors.on_select and rt.active_grid.selection then
            rt.active_grid.behaviors.on_select(rt.active_grid.selection:selected_keys())
          end
        end
      end
    end,
    
    on_drag_canceled = function(cancel_info)
      if cancel_info.source_grid == 'active' and rt.active_grid and rt.active_grid.behaviors and rt.active_grid.behaviors.delete then
        rt.active_grid.behaviors.delete(cancel_info.payload or {})
      end
    end,
  })
  
  rt.bridge:register_grid('active', rt.active_grid, {
    accepts_drops_from = {'pool'},
    on_drag_start = function(item_keys)
      rt.bridge:start_drag('active', item_keys)
    end,
  })
  
  rt.bridge:register_grid('pool', rt.pool_grid, {
    accepts_drops_from = {},
    on_drag_start = function(item_keys)
      local pool_mode = rt.pool_container.current_mode
      local payload = {}
      
      if pool_mode == "playlists" then
        for _, key in ipairs(item_keys) do
          local playlist_id = key:match("pool_playlist_(.+)")
          if playlist_id and rt.get_playlist_by_id then
            local playlist = rt.get_playlist_by_id(playlist_id)
            if playlist then
              payload[#payload + 1] = {
                type = "playlist",
                id = playlist.id,
                name = playlist.name,
                chip_color = playlist.chip_color,
                item_count = #playlist.items,
              }
            end
          end
        end
      else
        for _, key in ipairs(item_keys) do
          local rid = tonumber(key:match("pool_(%d+)"))
          if rid then
            payload[#payload + 1] = rid
          end
        end
      end
      
      rt.bridge:start_drag('pool', payload)
    end,
  })
  
  rt:set_layout_mode(rt.layout_mode)
  
  return rt
end

function RegionTiles:set_layout_mode(mode)
  self.layout_mode = mode
  if mode == 'vertical' then
    self.active_grid.min_col_w_fn = function() return 9999 end
  else
    self.active_grid.min_col_w_fn = self._original_active_min_col_w
  end
end

function RegionTiles:set_app_bridge(bridge)
  self.app_bridge = bridge
end

function RegionTiles:set_pool_mode(mode)
  if self.pool_container then
    self.pool_container.current_mode = mode
  end
end

function RegionTiles:_find_hovered_tile(ctx, items)
  local mx, my = ImGui.GetMousePos(ctx)
  
  for _, item in ipairs(items) do
    local key = item.key
    local rect = self.active_grid.rect_track:get(key)
    if rect then
      if mx >= rect[1] and mx < rect[3] and my >= rect[2] and my < rect[4] then
        local is_selected = self.active_grid.selection:is_selected(key)
        return item, key, is_selected
      end
    end
  end
  
  return nil, nil, false
end

function RegionTiles:is_mouse_over_active_tile(ctx, playlist)
  if not self.active_bounds then return false end
  
  local mx, my = ImGui.GetMousePos(ctx)
  
  if not (mx >= self.active_bounds[1] and mx < self.active_bounds[3] and
          my >= self.active_bounds[2] and my < self.active_bounds[4]) then
    return false
  end
  
  local item, key, _ = self:_find_hovered_tile(ctx, playlist.items)
  return item ~= nil and key ~= nil
end

function RegionTiles:should_consume_wheel(ctx, playlist)
  self.wheel_consumed_this_frame = false
  
  if not self.on_repeat_adjust then return false end
  
  local wheel_y = ImGui.GetMouseWheel(ctx)
  if wheel_y == 0 then return false end
  
  return self:is_mouse_over_active_tile(ctx, playlist)
end

function RegionTiles:_get_drag_colors()
  local colors = {}
  
  if not self.bridge:is_drag_active() then return nil end
  
  local source = self.bridge:get_source_grid()
  local payload = self.bridge:get_drag_payload()
  
  if source == 'active' then
    local data = payload and payload.data or {}
    if type(data) == 'table' then
      local playlist_items = self.active_grid.get_items()
      for _, key in ipairs(data) do
        for _, item in ipairs(playlist_items) do
          if item.key == key then
            if item.type == "playlist" then
              if self.get_playlist_by_id then
                local playlist = self.get_playlist_by_id(item.playlist_id)
                if playlist and playlist.chip_color then
                  colors[#colors + 1] = playlist.chip_color
                end
              end
            else
              local region = self.get_region_by_rid(item.rid)
              if region and region.color then
                colors[#colors + 1] = region.color
              end
            end
            break
          end
        end
      end
    end
  elseif source == 'pool' then
    local data = payload and payload.data or {}
    if type(data) == 'table' then
      for _, item in ipairs(data) do
        if type(item) == "number" then
          local region = self.get_region_by_rid(item)
          if region and region.color then
            colors[#colors + 1] = region.color
          end
        elseif type(item) == "table" and item.type == "playlist" then
          if item.chip_color then
            colors[#colors + 1] = item.chip_color
          end
        end
      end
    end
  end
  
  return #colors > 0 and colors or nil
end

function RegionTiles:update_animations(dt)
  self.selector:update(dt)
  self.active_animator:update(dt)
  self.pool_animator:update(dt)
end

function RegionTiles:set_tabs(tabs, active_id)
  if self.active_container then
    self.active_container:set_tabs(tabs, active_id)
  end
end

function RegionTiles:get_active_tab_id()
  if self.active_container then
    return self.active_container:get_active_tab_id()
  end
  return nil
end

function RegionTiles:get_pool_search_text()
  return self.pool_container:get_search_text()
end

function RegionTiles:set_pool_search_text(text)
  self.pool_container:set_search_text(text)
end

function RegionTiles:get_pool_sort_mode()
  return self.pool_container:get_sort_mode()
end

function RegionTiles:set_pool_sort_mode(mode)
  self.pool_container:set_sort_mode(mode)
end

function RegionTiles:set_pool_sort_direction(direction)
  self.pool_container:set_sort_direction(direction)
end

RegionTiles.draw_selector = Render.draw_selector
RegionTiles.draw_active = Render.draw_active
RegionTiles.draw_pool = Render.draw_pool
RegionTiles.draw_ghosts = Render.draw_ghosts

return M