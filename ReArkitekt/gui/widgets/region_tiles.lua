-- ReArkitekt/gui/widgets/region_tiles.lua
-- Region Playlist coordinator - manages active sequence + pool grids with responsive heights
-- Now with gap responsiveness and scrollbar overlap prevention

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.10'

local Draw = require('ReArkitekt.gui.draw')
local Colors = require('ReArkitekt.gui.colors')
local Grid = require('ReArkitekt.gui.widgets.colorblocks')
local TileAnim = require('ReArkitekt.gui.systems.tile_animation')
local GhostTiles = require('ReArkitekt.gui.widgets.tiles.ghost_tiles')
local ActiveTile = require('ReArkitekt.gui.widgets.tiles.active_tile')
local PoolTile = require('ReArkitekt.gui.widgets.tiles.pool_tile')
local HeightStabilizer = require('ReArkitekt.gui.systems.height_stabilizer')

local M = {}

local TILE_CONFIG = {
  border_thickness = 0.5,
  rounding = 6,
}

local RESPONSIVE_CONFIG = {
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
}

local SELECTOR_CONFIG = {
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

local TILE_HOVER_CONFIG = {
  animation_speed_hover = 12.0,
  hover_brightness_factor = 1.5,
  hover_border_lerp = 0.5,
  base_fill_desaturation = 0.4,
  base_fill_brightness = 0.4,
  base_fill_alpha = 0x66,
}

local DIM_CONFIG = {
  fill_color = 0x00000088,
  stroke_color = 0xFFFFFF33,
  stroke_thickness = 1.5,
  rounding = 6,
}

local DROP_CONFIG = {
  move_mode = {
    line = { width = 2, color = 0x42E896FF, glow_width = 12, glow_color = 0x42E89633 },
    caps = { width = 8, height = 3, color = 0x42E896FF, rounding = 0, glow_size = 3, glow_color = 0x42E89644 },
  },
  copy_mode = {
    line = { width = 2, color = 0x9C87E8FF, glow_width = 12, glow_color = 0x9C87E833 },
    caps = { width = 8, height = 3, color = 0x9C87E8FF, rounding = 0, glow_size = 3, glow_color = 0x9C87E844 },
  },
  pulse_speed = 2.5,
}

local GHOST_CONFIG = {
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
}

local WHEEL_CONFIG = {
  step = 1,
}

local function calculate_scaled_gap(tile_height, base_gap, base_height, min_height)
  local gap_config = RESPONSIVE_CONFIG.gap_scaling
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

local function calculate_responsive_tile_height(item_count, avail_width, avail_height, base_gap, min_col_w, base_height, min_height)
  if not RESPONSIVE_CONFIG.enabled or item_count == 0 then 
    return base_height, base_gap
  end
  
  local scrollbar_buffer = RESPONSIVE_CONFIG.scrollbar_buffer or 24
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
  
  local round_to = RESPONSIVE_CONFIG.round_to_multiple or 2
  final_height = math.floor((final_height + round_to - 1) / round_to) * round_to
  
  local final_gap = calculate_scaled_gap(final_height, base_gap, base_height, min_height)
  
  return final_height, final_gap
end

local RegionTiles = {}
RegionTiles.__index = RegionTiles

function M.create(opts)
  opts = opts or {}
  
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
    
    hover_config = TILE_HOVER_CONFIG,
    
    selector_animator = TileAnim.new(SELECTOR_CONFIG.animation_speed),
    active_animator = TileAnim.new(TILE_HOVER_CONFIG.animation_speed_hover),
    pool_animator = TileAnim.new(TILE_HOVER_CONFIG.animation_speed_hover),
    
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
      stable_frames_required = RESPONSIVE_CONFIG.stable_frames_required,
      height_hysteresis = RESPONSIVE_CONFIG.height_hysteresis,
    }),
    pool_height_stabilizer = HeightStabilizer.new({
      stable_frames_required = RESPONSIVE_CONFIG.stable_frames_required,
      height_hysteresis = RESPONSIVE_CONFIG.height_hysteresis,
    }),
    
    current_active_tile_height = RESPONSIVE_CONFIG.base_tile_height_active,
    current_pool_tile_height = RESPONSIVE_CONFIG.base_tile_height_pool,
  }, RegionTiles)
  
  rt.active_grid = Grid.new({
    id = "active_grid",
    gap = ActiveTile.CONFIG.gap,
    min_col_w = function() return ActiveTile.CONFIG.tile_width end,
    fixed_tile_h = RESPONSIVE_CONFIG.base_tile_height_active,
    get_items = function() return {} end,
    key = function(item) return item.key end,
    
    external_drag_check = function()
      return rt.drag_state.source == 'pool'
    end,
    
    is_copy_mode_check = function()
      return rt.drag_state.is_copy_mode
    end,
    
    on_drag_start = function(item_keys)
      rt.drag_state.source = 'active'
      rt.drag_state.data = item_keys
      rt.drag_state.ctrl_held = false
    end,
    
    accept_external_drops = true,
    
    on_external_drop = function(insert_index)
      if rt.drag_state.source == 'pool' and rt.on_pool_to_active then
        local rids = rt.drag_state.data
        local spawned_keys = {}
        
        if type(rids) == 'table' then
          for _, rid in ipairs(rids) do
            local new_key = rt.on_pool_to_active(rid, insert_index)
            if new_key then
              spawned_keys[#spawned_keys + 1] = new_key
            end
            insert_index = insert_index + 1
          end
        else
          local new_key = rt.on_pool_to_active(rids, insert_index)
          if new_key then
            spawned_keys[#spawned_keys + 1] = new_key
          end
        end
        
        if #spawned_keys > 0 then
          rt.pool_grid.selection:clear()
          rt.active_grid.selection:clear()
          
          for _, key in ipairs(spawned_keys) do
            local rect = rt.active_grid.rect_track:get(key)
            if rect then
              rt.active_grid.spawn_anim:spawn(key, rect)
            end
            
            rt.active_grid.selection.selected[key] = true
          end
          
          rt.active_grid.selection.last_clicked = spawned_keys[#spawned_keys]
          
          if rt.active_grid.on_select then
            rt.active_grid.on_select(rt.active_grid.selection:selected_keys())
          end
        end
      end
      rt.drag_state.source = nil
      rt.drag_state.data = nil
      rt.drag_state.ctrl_held = false
      rt.drag_state.is_copy_mode = false
    end,
    
    on_reorder = function(new_order)
      if rt.drag_state.ctrl_held and rt.on_active_copy then
        local playlist_items = rt.active_grid.get_items()
        local items_by_key = {}
        for _, item in ipairs(playlist_items) do
          items_by_key[item.key] = item
        end
        
        local dragged_items = {}
        for _, key in ipairs(rt.drag_state.data or {}) do
          if items_by_key[key] then
            dragged_items[#dragged_items + 1] = items_by_key[key]
          end
        end
        
        rt.on_active_copy(dragged_items, rt.active_grid.drag.target_index)
      elseif rt.on_active_reorder then
        local playlist_items = rt.active_grid.get_items()
        local items_by_key = {}
        for _, item in ipairs(playlist_items) do
          items_by_key[item.key] = item
        end
        
        local new_items = {}
        for _, key in ipairs(new_order) do
          if items_by_key[key] then
            new_items[#new_items + 1] = items_by_key[key]
          end
        end
        
        rt.on_active_reorder(new_items)
      end
    end,
    
    on_right_click = function(key, selected_keys)
      if rt.on_active_toggle_enabled then
        if #selected_keys > 1 then
          local playlist_items = rt.active_grid.get_items()
          local item_map = {}
          for _, item in ipairs(playlist_items) do
            item_map[item.key] = item
          end
          
          local clicked_item = item_map[key]
          if clicked_item then
            local new_state = not (clicked_item.enabled ~= false)
            for _, sel_key in ipairs(selected_keys) do
              rt.on_active_toggle_enabled(sel_key, new_state)
            end
          end
        else
          local playlist_items = rt.active_grid.get_items()
          for _, item in ipairs(playlist_items) do
            if item.key == key then
              local new_state = not (item.enabled ~= false)
              rt.on_active_toggle_enabled(key, new_state)
              break
            end
          end
        end
      end
    end,
    
    on_delete = function(item_keys)
      if rt.on_active_delete then
        rt.on_active_delete(item_keys)
      end
    end,
    
    on_destroy_complete = function(key)
      if rt.on_destroy_complete then
        rt.on_destroy_complete(key)
      end
    end,
    
    on_click_empty = function(key)
      if rt.on_repeat_cycle then
        rt.on_repeat_cycle(key)
      end
    end,

    render_tile = function(ctx, rect, item, state)
      local tile_height = rect[4] - rect[2]
      ActiveTile.render(ctx, rect, item, state, rt.get_region_by_rid, rt.active_animator, 
                      rt.on_repeat_cycle, rt.hover_config, tile_height, TILE_CONFIG.border_thickness)
    end,
    
    config = {
      spawn = ActiveTile.CONFIG.spawn,
      destroy = { enabled = true },
      ghost = GHOST_CONFIG,
      dim = DIM_CONFIG,
      drop = DROP_CONFIG,
      drag = { threshold = 6 },
    },
  })
  
  rt.pool_grid = Grid.new({
    id = "pool_grid",
    gap = PoolTile.CONFIG.gap,
    min_col_w = function() return PoolTile.CONFIG.tile_width end,
    fixed_tile_h = RESPONSIVE_CONFIG.base_tile_height_pool,
    get_items = function() return {} end,
    key = function(region) return "pool_" .. tostring(region.rid) end,
    
    external_drag_check = function()
      return rt.drag_state.source == 'active'
    end,
    
    is_copy_mode_check = function()
      return rt.drag_state.is_copy_mode
    end,
    
    on_drag_start = function(item_keys)
      local rids = {}
      for _, key in ipairs(item_keys) do
        local rid = tonumber(key:match("pool_(%d+)"))
        if rid then
          rids[#rids + 1] = rid
        end
      end
      rt.drag_state.source = 'pool'
      rt.drag_state.data = rids
      rt.drag_state.ctrl_held = false
    end,
    
    on_reorder = function(new_order)
      if not rt.allow_pool_reorder or not rt.on_pool_reorder then return end
      
      local rids = {}
      for _, key in ipairs(new_order) do
        local rid = tonumber(key:match("pool_(%d+)"))
        if rid then
          rids[#rids + 1] = rid
        end
      end
      
      rt.on_pool_reorder(rids)
    end,
    
    accept_external_drops = false,
    
    on_double_click = function(key)
      local rid = tonumber(key:match("pool_(%d+)"))
      if rid and rt.on_pool_double_click then
        rt.on_pool_double_click(rid)
      end
    end,
    
    render_tile = function(ctx, rect, region, state)
      local tile_height = rect[4] - rect[2]
      PoolTile.render(ctx, rect, region, state, rt.pool_animator, rt.hover_config, 
                      tile_height, TILE_CONFIG.border_thickness)
    end,
    
    config = {
      spawn = PoolTile.CONFIG.spawn,
      ghost = GHOST_CONFIG,
      dim = DIM_CONFIG,
      drop = DROP_CONFIG,
      drag = { threshold = 6 },
    },
  })
  
  return rt
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
  self.selector_animator:update(dt)
  self.active_animator:update(dt)
  self.pool_animator:update(dt)
end

function RegionTiles:draw_selector(ctx, playlists, active_id, height)
  local dl = ImGui.GetWindowDrawList(ctx)
  local cursor_x, cursor_y = ImGui.GetCursorScreenPos(ctx)
  
  local total_width = #playlists * (SELECTOR_CONFIG.chip_width + SELECTOR_CONFIG.gap) - SELECTOR_CONFIG.gap
  local x = cursor_x
  local y = cursor_y
  
  ImGui.InvisibleButton(ctx, "##selector_area", total_width, height)
  
  for i, pl in ipairs(playlists) do
    local chip_x = x + (i - 1) * (SELECTOR_CONFIG.chip_width + SELECTOR_CONFIG.gap)
    local chip_y = y + (height - SELECTOR_CONFIG.chip_height) / 2
    local chip_x2 = chip_x + SELECTOR_CONFIG.chip_width
    local chip_y2 = chip_y + SELECTOR_CONFIG.chip_height
    
    local mx, my = ImGui.GetMousePos(ctx)
    local is_hovered = mx >= chip_x and mx < chip_x2 and my >= chip_y and my < chip_y2
    local is_active = pl.id == active_id
    
    self.selector_animator:track(pl.id, 'hover', is_hovered and 1.0 or 0.0, SELECTOR_CONFIG.animation_speed)
    self.selector_animator:track(pl.id, 'active', is_active and 1.0 or 0.0, SELECTOR_CONFIG.animation_speed)
    
    local hover_factor = self.selector_animator:get(pl.id, 'hover')
    local active_factor = self.selector_animator:get(pl.id, 'active')
    
    local bg_base = Colors.lerp(SELECTOR_CONFIG.bg_inactive, SELECTOR_CONFIG.bg_active, active_factor)
    local bg_final = Colors.lerp(bg_base, SELECTOR_CONFIG.bg_hover, hover_factor * 0.5)
    
    local border_base = Colors.lerp(SELECTOR_CONFIG.border_inactive, SELECTOR_CONFIG.border_active, active_factor)
    local border_final = Colors.lerp(border_base, SELECTOR_CONFIG.border_active, hover_factor)
    
    ImGui.DrawList_AddRectFilled(dl, chip_x, chip_y, chip_x2, chip_y2, bg_final, SELECTOR_CONFIG.rounding)
    ImGui.DrawList_AddRect(dl, chip_x + 0.5, chip_y + 0.5, chip_x2 - 0.5, chip_y2 - 0.5,
                          border_final, SELECTOR_CONFIG.rounding, 0, SELECTOR_CONFIG.border_thickness)
    
    local label = "#" .. i .. " " .. pl.name
    Draw.centered_text(ctx, label, chip_x, chip_y, chip_x2, chip_y2, SELECTOR_CONFIG.text_color)
    
    ImGui.SetCursorScreenPos(ctx, chip_x, chip_y)
    ImGui.InvisibleButton(ctx, "##selector_" .. pl.id, SELECTOR_CONFIG.chip_width, SELECTOR_CONFIG.chip_height)
    
    if ImGui.IsItemClicked(ctx, 0) and self.on_playlist_changed then
      self.on_playlist_changed(pl.id)
    end
  end
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
  
  ImGui.DrawList_AddRectFilled(dl, container_x1, container_y1, container_x2, container_y2,
                                0x0F0F0FFF, ActiveTile.CONFIG.rounding)
  ImGui.DrawList_AddRect(dl, container_x1 + 0.5, container_y1 + 0.5, container_x2 - 0.5, container_y2 - 0.5,
                        0x000000DD, ActiveTile.CONFIG.rounding, 0, 1)
  
  ImGui.SetCursorScreenPos(ctx, cursor_x + 8, cursor_y + 8)
  
  local child_w = avail_w - 16
  local child_h = height - 16
  
  self.active_grid.get_items = function() return playlist.items end
  
  local raw_height, raw_gap = calculate_responsive_tile_height(
    #playlist.items,
    child_w,
    child_h,
    ActiveTile.CONFIG.gap,
    ActiveTile.CONFIG.tile_width,
    RESPONSIVE_CONFIG.base_tile_height_active,
    RESPONSIVE_CONFIG.min_tile_height
  )
  
  local responsive_height = self.active_height_stabilizer:update(raw_height)
  
  self.current_active_tile_height = responsive_height
  self.active_grid.fixed_tile_h = responsive_height
  
  local final_gap = calculate_scaled_gap(
    responsive_height,
    ActiveTile.CONFIG.gap,
    RESPONSIVE_CONFIG.base_tile_height_active,
    RESPONSIVE_CONFIG.min_tile_height
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
        local delta = (wheel_y > 0) and WHEEL_CONFIG.step or -WHEEL_CONFIG.step
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
  
  ImGui.DrawList_AddRectFilled(dl, container_x1, container_y1, container_x2, container_y2,
                                0x1C1C1CFF, 8)
  ImGui.DrawList_AddRect(dl, container_x1 + 0.5, container_y1 + 0.5, container_x2 - 0.5, container_y2 - 0.5,
                        0x000000DD, 8, 0, 1)
  
  ImGui.SetCursorScreenPos(ctx, cursor_x + 8, cursor_y + 8)
  
  local child_w = avail_w - 16
  local child_h = height - 16
  
  self.pool_grid.get_items = function() return regions end
  
  local raw_height, raw_gap = calculate_responsive_tile_height(
    #regions,
    child_w,
    child_h,
    PoolTile.CONFIG.gap,
    PoolTile.CONFIG.tile_width,
    RESPONSIVE_CONFIG.base_tile_height_pool,
    RESPONSIVE_CONFIG.min_tile_height
  )
  
  local responsive_height = self.pool_height_stabilizer:update(raw_height)
  
  self.current_pool_tile_height = responsive_height
  self.pool_grid.fixed_tile_h = responsive_height
  
  local final_gap = calculate_scaled_gap(
    responsive_height,
    PoolTile.CONFIG.gap,
    RESPONSIVE_CONFIG.base_tile_height_pool,
    RESPONSIVE_CONFIG.min_tile_height
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
  
  GhostTiles.draw(ctx, fg_dl, mx, my, count, GHOST_CONFIG, colors, is_copy_mode, is_delete_mode)
end

return M