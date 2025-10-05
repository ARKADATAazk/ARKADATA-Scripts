-- ReArkitekt/gui/widgets/region_tiles/coordinator.lua
-- Region Playlist coordinator - manages active sequence + pool grids with responsive heights

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.10'

local Draw = require('ReArkitekt.gui.draw')
local Colors = require('ReArkitekt.core.colors')
local TileAnim = require('ReArkitekt.gui.fx.tile_motion')
local DragIndicator = require('ReArkitekt.gui.fx.dnd.drag_indicator')
local ActiveTile = require('ReArkitekt.gui.widgets.region_tiles.renderers.active')
local PoolTile = require('ReArkitekt.gui.widgets.region_tiles.renderers.pool')
local HeightStabilizer = require('ReArkitekt.gui.systems.height_stabilizer')
local Selector = require('ReArkitekt.gui.widgets.region_tiles.selector')
local ActiveGrid = require('ReArkitekt.gui.widgets.region_tiles.active_grid')
local PoolGrid = require('ReArkitekt.gui.widgets.region_tiles.pool_grid')

local M = {}

local DEFAULTS = {
  layout_mode = 'horizontal',
  
  tile_config = {
    border_thickness = 0.5,
    rounding = 6,
  },
  
  container_config = {
    bg_color = 0x0F0F0FFF,
    border_color = 0x000000DD,
    border_thickness = 1,
    rounding = 8,
    padding = 8,
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

local function calculate_scaled_gap(tile_height, base_gap, base_height, min_height, responsive_config)
  local gap_config = responsive_config.gap_scaling
  if not gap_config or not gap_config.enabled then
    return base_gap
  end
  
  local min_gap = gap_config.min_gap or 2
  local max_gap = gap_config.max_gap or base_gap
  
  local height_range = base_height - min_height
  if height_range <= 0 then return base_gap end
  
  local height_factor = (tile_height - min_height) / height_range
  height_factor = math.min(1.0, math.max(0.0, height_factor))
  
  local scaled_gap = min_gap + (max_gap - min_gap) * height_factor
  return math.max(min_gap, math.floor(scaled_gap))
end

local function calculate_responsive_tile_height(item_count, avail_width, avail_height, base_gap, min_col_w, base_height, min_height, responsive_config)
  if not responsive_config.enabled or item_count == 0 then 
    return base_height, base_gap
  end
  
  local scrollbar_buffer = responsive_config.scrollbar_buffer or 24
  local safe_width = avail_width - scrollbar_buffer
  
  local cols = math.max(1, math.floor((safe_width + base_gap) / (min_col_w + base_gap)))
  local rows = math.ceil(item_count / cols)
  
  local total_gap_height = (rows + 1) * base_gap
  local available_for_tiles = avail_height - total_gap_height
  
  if available_for_tiles <= 0 then return base_height, base_gap end
  
  local needed_height = rows * base_height
  
  if needed_height <= available_for_tiles then
    return base_height, base_gap
  end
  
  local scaled_height = math.floor(available_for_tiles / rows)
  local final_height = math.max(min_height, scaled_height)
  
  local round_to = responsive_config.round_to_multiple or 2
  final_height = math.floor((final_height + round_to - 1) / round_to) * round_to
  
  local final_gap = calculate_scaled_gap(final_height, base_gap, base_height, min_height, responsive_config)
  
  return final_height, final_gap
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
    settings = opts.settings,
    
    allow_pool_reorder = opts.allow_pool_reorder ~= false,
    
    config = config,
    layout_mode = config.layout_mode,
    hover_config = config.hover_config,
    responsive_config = config.responsive_config,
    container_config = config.container_config,
    wheel_config = config.wheel_config,
    
    selector = Selector.new(),
    active_animator = TileAnim.new(config.hover_config.animation_speed_hover),
    pool_animator = TileAnim.new(config.hover_config.animation_speed_hover),
    
    drag_state = {
      source = nil,
      data = nil,
      ctrl_held = false,
      is_copy_mode = false,
    },
    
    active_bounds = nil,
    pool_bounds = nil,
    
    active_grid = nil,
    pool_grid = nil,
    
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
  }, RegionTiles)
  
  local grid_config = {
    base_tile_height_active = config.responsive_config.base_tile_height_active,
    tile_config = config.tile_config,
    dim_config = config.dim_config,
    drop_config = config.drop_config,
    ghost_config = config.ghost_config,
  }
  
  rt.active_grid = ActiveGrid.create_active_grid(rt, grid_config)
  rt._original_active_min_col_w = rt.active_grid.min_col_w_fn
  
  local pool_config = {
    base_tile_height_pool = config.responsive_config.base_tile_height_pool,
    tile_config = config.tile_config,
    dim_config = config.dim_config,
    drop_config = config.drop_config,
    ghost_config = config.ghost_config,
  }
  
  rt.pool_grid = PoolGrid.create_pool_grid(rt, pool_config)
  
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
  
  if self.drag_state.source == 'active' then
    local data = self.drag_state.data
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
  elseif self.drag_state.source == 'pool' then
    local rids = self.drag_state.data
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
  local cursor_x, cursor_y = ImGui.GetCursorScreenPos(ctx)
  local avail_w, _ = ImGui.GetContentRegionAvail(ctx)
  
  self.active_bounds = {cursor_x, cursor_y, cursor_x + avail_w, cursor_y + height}
  
  local container_x1 = cursor_x
  local container_y1 = cursor_y
  local container_x2 = cursor_x + avail_w
  local container_y2 = cursor_y + height
  
  local dl = ImGui.GetWindowDrawList(ctx)
  local cc = self.container_config
  
  ImGui.DrawList_AddRectFilled(dl, container_x1, container_y1, container_x2, container_y2,
                                cc.bg_color, cc.rounding)
  ImGui.DrawList_AddRect(dl, container_x1 + 0.5, container_y1 + 0.5, container_x2 - 0.5, container_y2 - 0.5,
                        cc.border_color, cc.rounding, 0, cc.border_thickness)
  
  ImGui.SetCursorScreenPos(ctx, cursor_x + cc.padding, cursor_y + cc.padding)
  
  local child_w = avail_w - (cc.padding * 2)
  local child_h = height - (cc.padding * 2)
  
  self.active_grid.get_items = function() return playlist.items end
  
  local raw_height, raw_gap = calculate_responsive_tile_height(
    #playlist.items,
    child_w,
    child_h,
    ActiveTile.CONFIG.gap,
    ActiveTile.CONFIG.tile_width,
    self.responsive_config.base_tile_height_active,
    self.responsive_config.min_tile_height,
    self.responsive_config
  )
  
  local responsive_height = self.active_height_stabilizer:update(raw_height)
  
  self.current_active_tile_height = responsive_height
  self.active_grid.fixed_tile_h = responsive_height
  
  local final_gap = calculate_scaled_gap(
    responsive_height,
    ActiveTile.CONFIG.gap,
    self.responsive_config.base_tile_height_active,
    self.responsive_config.min_tile_height,
    self.responsive_config
  )
  self.active_grid.gap = final_gap
  
  local child_flags = ImGui.ChildFlags_None
  local window_flags = ImGui.WindowFlags_NoScrollWithMouse
  
  if ImGui.BeginChild(ctx, "##active_container", child_w, child_h, child_flags, window_flags) then
    local ctrl_held = ImGui.IsKeyDown(ctx, ImGui.Key_LeftCtrl) or ImGui.IsKeyDown(ctx, ImGui.Key_RightCtrl)
    self.drag_state.ctrl_held = ctrl_held and self.drag_state.source == 'active'
    
    local mx, my = ImGui.GetMousePos(ctx)
    local is_over_active = mx >= self.active_bounds[1] and mx < self.active_bounds[3] and
                           my >= self.active_bounds[2] and my < self.active_bounds[4]
    
    if self.drag_state.source == 'pool' then
      self.drag_state.is_copy_mode = is_over_active
    elseif self.drag_state.source == 'active' then
      self.drag_state.is_copy_mode = self.drag_state.ctrl_held
    else
      self.drag_state.is_copy_mode = false
    end
    
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
      else
        local current_scroll = ImGui.GetScrollY(ctx)
        local scroll_delta = wheel_y * -20
        ImGui.SetScrollY(ctx, current_scroll + scroll_delta)
      end
    end
    
    self.active_grid:draw(ctx)
  end
  ImGui.EndChild(ctx)
  
  if self.drag_state.source == 'active' and ImGui.IsMouseReleased(ctx, 0) then
    local mx, my = ImGui.GetMousePos(ctx)
    local in_active = mx >= self.active_bounds[1] and mx < self.active_bounds[3] and
                      my >= self.active_bounds[2] and my < self.active_bounds[4]
    
    if not in_active and not self.drag_state.ctrl_held and self.on_active_remove then
      for _, key in ipairs(self.drag_state.data) do
        self.on_active_remove(key)
      end
    end
    
    self.drag_state.source = nil
    self.drag_state.data = nil
    self.drag_state.ctrl_held = false
    self.drag_state.is_copy_mode = false
  end
end

function RegionTiles:draw_pool(ctx, regions, height)
  local cursor_x, cursor_y = ImGui.GetCursorScreenPos(ctx)
  local avail_w, _ = ImGui.GetContentRegionAvail(ctx)
  
  self.pool_bounds = {cursor_x, cursor_y, cursor_x + avail_w, cursor_y + height}
  
  local container_x1 = cursor_x
  local container_y1 = cursor_y
  local container_x2 = cursor_x + avail_w
  local container_y2 = cursor_y + height
  
  local dl = ImGui.GetWindowDrawList(ctx)
  local cc = self.container_config
  
  ImGui.DrawList_AddRectFilled(dl, container_x1, container_y1, container_x2, container_y2,
                                cc.bg_color, cc.rounding)
  ImGui.DrawList_AddRect(dl, container_x1 + 0.5, container_y1 + 0.5, container_x2 - 0.5, container_y2 - 0.5,
                        cc.border_color, cc.rounding, 0, cc.border_thickness)
  
  ImGui.SetCursorScreenPos(ctx, cursor_x + cc.padding, cursor_y + cc.padding)
  
  local child_w = avail_w - (cc.padding * 2)
  local child_h = height - (cc.padding * 2)
  
  self.pool_grid.get_items = function() return regions end
  
  local raw_height, raw_gap = calculate_responsive_tile_height(
    #regions,
    child_w,
    child_h,
    PoolTile.CONFIG.gap,
    PoolTile.CONFIG.tile_width,
    self.responsive_config.base_tile_height_pool,
    self.responsive_config.min_tile_height,
    self.responsive_config
  )
  
  local responsive_height = self.pool_height_stabilizer:update(raw_height)
  
  self.current_pool_tile_height = responsive_height
  self.pool_grid.fixed_tile_h = responsive_height
  
  local final_gap = calculate_scaled_gap(
    responsive_height,
    PoolTile.CONFIG.gap,
    self.responsive_config.base_tile_height_pool,
    self.responsive_config.min_tile_height,
    self.responsive_config
  )
  self.pool_grid.gap = final_gap
  
  if ImGui.BeginChild(ctx, "##pool_container", child_w, child_h, ImGui.ChildFlags_None, 0) then
    self.pool_grid:draw(ctx)
  end
  ImGui.EndChild(ctx)
  
  if self.drag_state.source == 'pool' and ImGui.IsMouseReleased(ctx, 0) then
    local mx, my = ImGui.GetMousePos(ctx)
    local in_active = false
    
    if self.active_bounds then
      in_active = mx >= self.active_bounds[1] and mx < self.active_bounds[3] and
                  my >= self.active_bounds[2] and my < self.active_bounds[4]
    end
    
    if not in_active then
      self.drag_state.source = nil
      self.drag_state.data = nil
      self.drag_state.ctrl_held = false
      self.drag_state.is_copy_mode = false
    end
  end
end

function RegionTiles:draw_ghosts(ctx)
  if self.drag_state.source == nil then return end
  
  local mx, my = ImGui.GetMousePos(ctx)
  local count = 1
  if type(self.drag_state.data) == 'table' then
    count = #self.drag_state.data
  end
  
  local colors = self:_get_drag_colors()
  local fg_dl = ImGui.GetForegroundDrawList(ctx)
  
  local is_over_active = false
  if self.active_bounds then
    is_over_active = mx >= self.active_bounds[1] and mx < self.active_bounds[3] and
                     my >= self.active_bounds[2] and my < self.active_bounds[4]
  end
  
  local is_copy_mode = false
  local is_delete_mode = false
  
  if self.drag_state.source == 'pool' then
    is_copy_mode = is_over_active
  elseif self.drag_state.source == 'active' then
    if self.drag_state.ctrl_held then
      is_copy_mode = true
    elseif not is_over_active then
      is_delete_mode = true
    end
  end
  
  self.drag_state.is_copy_mode = is_copy_mode
  
  DragIndicator.draw(ctx, fg_dl, mx, my, count, self.config.ghost_config, colors, is_copy_mode, is_delete_mode)
end

return M