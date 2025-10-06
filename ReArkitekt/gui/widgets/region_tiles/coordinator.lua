-- ReArkitekt/gui/widgets/region_tiles/coordinator.lua
-- Region Playlist coordinator - manages active sequence + pool grids with responsive heights
-- FIXED: Drop indicators now respect grid boundaries and only show in appropriate grids

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.10'

local Draw = require('ReArkitekt.gui.draw')
local Colors = require('ReArkitekt.core.colors')
local PlaybackManager = require('ReArkitekt.gui.systems.playback_manager')
local TileAnim = require('ReArkitekt.gui.fx.tile_motion')
local DragIndicator = require('ReArkitekt.gui.fx.dnd.drag_indicator')
local ActiveTile = require('ReArkitekt.gui.widgets.region_tiles.renderers.active')
local PoolTile = require('ReArkitekt.gui.widgets.region_tiles.renderers.pool')
local HeightStabilizer = require('ReArkitekt.gui.systems.height_stabilizer')
local Selector = require('ReArkitekt.gui.widgets.region_tiles.selector')
local ActiveGridFactory = require('ReArkitekt.gui.widgets.region_tiles.active_grid_factory')
local PoolGridFactory = require('ReArkitekt.gui.widgets.region_tiles.pool_grid_factory')
local GridBridge = require('ReArkitekt.gui.widgets.grid.grid_bridge')
local ResponsiveGrid = require('ReArkitekt.gui.systems.responsive_grid')
local TilesContainer = require('ReArkitekt.gui.widgets.tiles_container')

local M = {}

local DEFAULTS = {
  layout_mode = 'horizontal',
  
  tile_config = {
    border_thickness = 0.5,
    rounding = 6,
  },
  
  container = {
    bg_color = 0x0F0F0FFF,
    border_color = 0x000000DD,
    border_thickness = 1,
    rounding = 8,
    padding = 8,
    
    scroll = {
      flags = 0,
      custom_scrollbar = false,
      bg_color = 0x00000000,
    },
    
    anti_jitter = {
      enabled = true,
      track_scrollbar = true,
      height_threshold = 5,
    },
    
    background_pattern = {
      enabled = false,
      
      primary = {
        type = 'grid',
        spacing = 100,
        color = 0x40404060,
        dot_size = 2.5,
        line_thickness = 1.5,
      },
      
      secondary = {
        enabled = true,
        type = 'grid',
        spacing = 20,
        color = 0x30303040,
        dot_size = 1.5,
        line_thickness = 0.5,
      },
    },
    
    header = {
      enabled = false,
      height = 36,
      bg_color = 0x252525FF,
      border_color = 0x00000066,
      padding_x = 12,
      padding_y = 8,
      spacing = 8,
      
      search = {
        enabled = true,
        placeholder = "Search...",
        width_ratio = 0.5,
        min_width = 150,
        bg_color = 0x1A1A1AFF,
        bg_hover_color = 0x202020FF,
        bg_active_color = 0x242424FF,
        text_color = 0xCCCCCCFF,
        placeholder_color = 0x666666FF,
        border_color = 0x404040FF,
        border_active_color = 0x5A5A5AFF,
        rounding = 4,
        fade_speed = 8.0,
      },
      
      sort_buttons = {
        enabled = true,
        size = 24,
        spacing = 4,
        bg_color = 0x2A2A2AFF,
        bg_hover_color = 0x333333FF,
        bg_active_color = 0x3A3A3AFF,
        text_color = 0xAAAAAAFF,
        text_hover_color = 0xEEEEEEFF,
        border_color = 0x404040FF,
        rounding = 3,
        
        buttons = {
          { id = "color", label = "C", tooltip = "Sort by Color" },
          { id = "index", label = "#", tooltip = "Sort by Index" },
          { id = "alpha", label = "A", tooltip = "Sort Alphabetically" },
        },
      },
    },
  },
  
  responsive_config = {
    enabled = true,
    min_tile_height = 20,
    base_tile_height_active = 72,
    base_tile_height_pool = 72,
    scrollbar_buffer = 24,
    height_hysteresis = 12,
    stable_frames_required = 2,
    round_to_multiple = 2,
    gap_scaling = {
      enabled = true,
      min_gap = 2,
      max_gap = 12,
    },
  },
  
  hover_config = {
    animation_speed_hover = 12.0,
    hover_brightness_factor = 1.5,
    hover_border_lerp = 0.5,
    base_fill_desaturation = 0.4,
    base_fill_brightness = 0.4,
    base_fill_alpha = 0x66,
  },
  
  dim_config = {
    fill_color = 0x00000088,
    stroke_color = 0xFFFFFF33,
    stroke_thickness = 1.5,
    rounding = 6,
  },
  
  drop_config = {
    move_mode = {
      line = { width = 2, color = 0x42E896FF, glow_width = 12, glow_color = 0x42E89633 },
      caps = { width = 8, height = 3, color = 0x42E896FF, rounding = 0, glow_size = 3, glow_color = 0x42E89644 },
    },
    copy_mode = {
      line = { width = 2, color = 0x9C87E8FF, glow_width = 12, glow_color = 0x9C87E833 },
      caps = { width = 8, height = 3, color = 0x9C87E8FF, rounding = 0, glow_size = 3, glow_color = 0x9C87E844 },
    },
    pulse_speed = 2.5,
  },
  
  ghost_config = {
    tile = {
      width = 60,
      height = 40,
      base_fill = 0x1A1A1AFF,
      base_stroke = 0x42E896FF,
      stroke_thickness = 1.5,
      rounding = 4,
      global_opacity = 0.70,
    },
    stack = {
      max_visible = 3,
      offset_x = 3,
      offset_y = 3,
      scale_factor = 0.94,
      opacity_falloff = 0.70,
    },
    badge = {
      bg = 0x1A1A1AEE,
      text = 0xFFFFFFFF,
      border_color = 0x00000099,
      border_thickness = 1,
      rounding = 6,
      padding_x = 6,
      padding_y = 3,
      offset_x = 35,
      offset_y = -35,
      min_width = 20,
      min_height = 18,
      shadow = {
        enabled = true,
        color = 0x00000099,
        offset = 2,
      },
    },
    copy_mode = {
      stroke_color = 0x9C87E8FF,
      glow_color = 0x9C87E833,
      badge_accent = 0x9C87E8FF,
      indicator_text = "+",
      indicator_color = 0x9C87E8FF,
    },
    move_mode = {
      stroke_color = 0x42E896FF,
      glow_color = 0x42E89633,
      badge_accent = 0x42E896FF,
    },
    delete_mode = {
      stroke_color = 0xE84A4AFF,
      glow_color = 0xE84A4A33,
      badge_accent = 0xE84A4AFF,
      indicator_text = "-",
      indicator_color = 0xE84A4AFF,
    },
  },
  
  wheel_config = {
    step = 1,
  },
}

local function merge_config(defaults, custom)
  if not custom then return defaults end
  local result = {}
  for k, v in pairs(defaults) do
    if custom[k] ~= nil then
      if type(v) == "table" and type(custom[k]) == "table" then
        result[k] = merge_config(v, custom[k])
      else
        result[k] = custom[k]
      end
    else
      result[k] = v
    end
  end
  return result
end

local RegionTiles = {}
RegionTiles.__index = RegionTiles

function M.create(opts)
  opts = opts or {}
  
  local config = merge_config(DEFAULTS, opts.config or {})
  
  local rt = setmetatable({
    get_region_by_rid = opts.get_region_by_rid,
    on_playlist_changed = opts.on_playlist_changed,
    on_active_reorder = opts.on_active_reorder,
    on_active_remove = opts.on_active_remove,
    on_active_copy = opts.on_active_copy,
    on_active_toggle_enabled = opts.on_active_toggle_enabled,
    on_active_delete = opts.on_active_delete,
    on_destroy_complete = opts.on_destroy_complete,
    on_pool_to_active = opts.on_pool_to_active,
    on_pool_reorder = opts.on_pool_reorder,
    on_repeat_cycle = opts.on_repeat_cycle,
    on_repeat_adjust = opts.on_repeat_adjust,
    on_repeat_sync = opts.on_repeat_sync,
    on_pool_double_click = opts.on_pool_double_click,
    on_pool_search = opts.on_pool_search,
    on_pool_sort = opts.on_pool_sort,
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

    playback_manager = PlaybackManager.new({
      default_duration = 15.0,
    }),
    
    active_bounds = nil,
    pool_bounds = nil,
    
    active_grid = nil,
    pool_grid = nil,
    bridge = nil,
    
    active_container = nil,
    pool_container = nil,
    
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
  
  local function shallow_copy_config(cfg)
    local copy = {}
    for k, v in pairs(cfg) do
      if type(v) == "table" then
        copy[k] = {}
        for k2, v2 in pairs(v) do
          copy[k][k2] = v2
        end
      else
        copy[k] = v
      end
    end
    return copy
  end
  
  local active_container_config = shallow_copy_config(config.container)
  if active_container_config.header then
    active_container_config.header = shallow_copy_config(active_container_config.header)
    active_container_config.header.enabled = false
  end
  
  rt.active_container = TilesContainer.new({
    id = "active_tiles_container",
    config = active_container_config,
  })
  
  rt.pool_container = TilesContainer.new({
    id = "pool_tiles_container",
    config = config.container,
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
  })
  
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
        if rt.on_pool_to_active then
          local spawned_keys = {}
          local insert_index = drop_info.insert_index
          
          for _, rid in ipairs(drop_info.payload) do
            local new_key = rt.on_pool_to_active(rid, insert_index)
            if new_key then
              spawned_keys[#spawned_keys + 1] = new_key
            end
            insert_index = insert_index + 1
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
      local rids = {}
      for _, key in ipairs(item_keys) do
        local rid = tonumber(key:match("pool_(%d+)"))
        if rid then
          rids[#rids + 1] = rid
        end
      end
      
      rt.bridge:start_drag('pool', rids)
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
            local region = self.get_region_by_rid(item.rid)
            if region and region.color then
              colors[#colors + 1] = region.color
            end
            break
          end
        end
      end
    end
  elseif source == 'pool' then
    local rids = payload and payload.data or {}
    if type(rids) == 'table' then
      for _, rid in ipairs(rids) do
        local region = self.get_region_by_rid(rid)
        if region and region.color then
          colors[#colors + 1] = region.color
        end
      end
    elseif type(rids) == 'number' then
      local region = self.get_region_by_rid(rids)
      if region and region.color then
        colors[#colors + 1] = region.color
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

function RegionTiles:draw_selector(ctx, playlists, active_id, height)
  self.selector:draw(ctx, playlists, active_id, height, self.on_playlist_changed)
end

function RegionTiles:draw_active(ctx, playlist, height)
  self._imgui_ctx = ctx
  
  local cursor_x, cursor_y = ImGui.GetCursorScreenPos(ctx)
  local avail_w, _ = ImGui.GetContentRegionAvail(ctx)
  
  self.active_bounds = {cursor_x, cursor_y, cursor_x + avail_w, cursor_y + height}
  self.bridge:update_bounds('active', cursor_x, cursor_y, cursor_x + avail_w, cursor_y + height)
  
  self.active_container.width = avail_w
  self.active_container.height = height
  
  if not self.active_container:begin_draw(ctx) then
    self.active_container:end_draw(ctx)
    return
  end
  
  local child_w = avail_w - (self.container_config.padding * 2)
  local child_h = height - (self.container_config.padding * 2)
  
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

function RegionTiles:draw_pool(ctx, regions, height)
  self._imgui_ctx = ctx
  
  local cursor_x, cursor_y = ImGui.GetCursorScreenPos(ctx)
  local avail_w, _ = ImGui.GetContentRegionAvail(ctx)
  
  self.pool_bounds = {cursor_x, cursor_y, cursor_x + avail_w, cursor_y + height}
  self.bridge:update_bounds('pool', cursor_x, cursor_y, cursor_x + avail_w, cursor_y + height)
  
  self.pool_container.width = avail_w
  self.pool_container.height = height
  
  if not self.pool_container:begin_draw(ctx) then
    self.pool_container:end_draw(ctx)
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

function RegionTiles:draw_ghosts(ctx)
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

return M