-- ReArkitekt/gui/widgets/grid/core.lua
-- Main grid orchestrator - composes rendering, animation, and input modules
-- REFACTORED: Now uses dnd_state and drop_zones modules

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local LayoutGrid = require('ReArkitekt.gui.widgets.grid.layout')
local RectTrack = require('ReArkitekt.gui.fx.animation.rect_track')
local Colors = require('ReArkitekt.core.colors')
local Selection  = require('ReArkitekt.gui.systems.selection')
local SelRect    = require('ReArkitekt.gui.widgets.selection_rectangle')
local Draw       = require('ReArkitekt.gui.draw')
local DragIndicator = require('ReArkitekt.gui.fx.dnd.drag_indicator')
local DropIndicator = require('ReArkitekt.gui.fx.dnd.drop_indicator')
local Rendering  = require('ReArkitekt.gui.widgets.grid.rendering')
local Animation  = require('ReArkitekt.gui.widgets.grid.animation')
local Input      = require('ReArkitekt.gui.widgets.grid.input')
local DnDState   = require('ReArkitekt.gui.widgets.grid.dnd_state')
local DropZones  = require('ReArkitekt.gui.widgets.grid.drop_zones')

local M = {}

local DEFAULTS = {
  layout = { speed = 14.0, snap_epsilon = 0.5 },
  drag = { threshold = 6 },
  
  spawn = {
    enabled = true,
    duration = 0.28,
  },
  
  destroy = {
    enabled = true,
  },
  
  marquee = {
    drag_threshold = 3,
    fill_color = 0xFFFFFF22,
    fill_color_add = 0xFFFFFF33,
    stroke_color = 0xFFFFFFFF,
    stroke_thickness = 1,
    rounding = 0,
  },

  dim = {
    fill_color = 0x00000088,
    stroke_color = 0xFFFFFF33,
    stroke_thickness = 1.5,
    rounding = 6,
  },
  
  drop = {
    line = {
      width = 2,
      color = 0x42E896FF,
      glow_width = 12,
      glow_color = 0x42E89633,
    },
    caps = {
      width = 8,
      height = 3,
      color = 0x42E896FF,
      rounding = 0,
      glow_size = 3,
      glow_color = 0x42E89644,
    },
    pulse_speed = 2.5,
  },
  
  wheel = {
    step = 1,
  },
  
  tile_helpers = {
    hover_shadow = {
      enabled = true,
      max_offset = 2,
      max_alpha = 20,
    },
    selection = {
      ant_speed = 20,
      ant_dash = 8,
      ant_gap = 6,
      brightness_factor = 1.5,
      saturation_factor = 0.5,
    },
  },
}

M.TileHelpers = Rendering.TileHelpers

local Grid = {}
Grid.__index = Grid

function M.new(opts)
  opts = opts or {}

  local grid = setmetatable({
    id               = opts.id or "grid",
    gap              = opts.gap or 12,
    min_col_w_fn     = type(opts.min_col_w) == "function" and opts.min_col_w or function() return opts.min_col_w or 160 end,
    fixed_tile_h     = opts.fixed_tile_h,
    get_items        = opts.get_items or function() return {} end,
    key              = opts.key or function(item) return tostring(item) end,
    get_exclusion_zones = opts.get_exclusion_zones,

    behaviors        = opts.behaviors or {},
    render_tile      = opts.render_tile or function() end,
    render_overlays  = opts.render_overlays,

    external_drag_check = opts.external_drag_check,
    is_copy_mode_check = opts.is_copy_mode_check,
    accept_external_drops = opts.accept_external_drops or false,
    render_drop_zones = opts.render_drop_zones or true,
    on_external_drop = opts.on_external_drop,
    on_destroy_complete = opts.on_destroy_complete,
    on_click_empty   = opts.on_click_empty,

    config           = opts.config or DEFAULTS,

    selection        = Selection.new(),
    rect_track       = RectTrack.new(
      opts.layout_speed or DEFAULTS.layout.speed, 
      opts.layout_snap or DEFAULTS.layout.snap_epsilon
    ),
    sel_rect         = SelRect.new(),
    animator         = Animation.new({
      spawn = opts.config and opts.config.spawn or DEFAULTS.spawn,
      destroy = opts.config and opts.config.destroy or DEFAULTS.destroy,
      on_destroy_complete = opts.on_destroy_complete,
    }),

    hover_id         = nil,
    current_rects    = {},
    drag             = DnDState.new({
      threshold = (opts.config and opts.config.drag and opts.config.drag.threshold) or DEFAULTS.drag.threshold
    }),
    external_drop_target = nil,
    last_window_pos  = nil,
    previous_item_keys = {},
    
    last_layout_cols = 1,
  }, Grid)

  grid.animator:set_rect_track(grid.rect_track)

  return grid
end

function Grid:_find_drop_target(ctx, mx, my, dragged_set, items)
  return DropZones.find_drop_target(mx, my, items, self.key, dragged_set, self.rect_track, self.last_layout_cols == 1)
end

function Grid:_update_external_drop_target(ctx)
  if not self.accept_external_drops or not Input.is_external_drag_active(self) then
    self.external_drop_target = nil
    return
  end

  local mx, my = ImGui.GetMousePos(ctx)
  local items = self.get_items()
  
  local target_index, coord, alt1, alt2, orientation = self:_find_drop_target(ctx, mx, my, {}, items)
  
  if target_index and coord then
    self.external_drop_target = {
      index = target_index,
      coord = coord,
      alt1 = alt1,
      alt2 = alt2,
      orientation = orientation,
    }
  else
    self.external_drop_target = nil
  end
end

function Grid:_draw_drag_visuals(ctx, dl)
  local mx, my = ImGui.GetMousePos(ctx)
  local dragged_set = DropZones.build_dragged_set(self.drag:get_dragged_ids())

  local items = self.get_items()
  local target_index, coord, alt1, alt2, orientation = self:_find_drop_target(ctx, mx, my, dragged_set, items)
  self.drag:set_target(target_index)

  local cfg = self.config
  
  for _, id in ipairs(self.drag:get_dragged_ids()) do
    local r = self.rect_track:get(id)
    if r then
      local dim_fill = (cfg.dim and cfg.dim.fill_color) or DEFAULTS.dim.fill_color
      local dim_stroke = (cfg.dim and cfg.dim.stroke_color) or DEFAULTS.dim.stroke_color
      local dim_thickness = (cfg.dim and cfg.dim.stroke_thickness) or DEFAULTS.dim.stroke_thickness
      local dim_rounding = (cfg.dim and cfg.dim.rounding) or DEFAULTS.dim.rounding
      
      ImGui.DrawList_AddRectFilled(dl, r[1], r[2], r[3], r[4], dim_fill, dim_rounding)
      ImGui.DrawList_AddRect(dl, r[1]+0.5, r[2]+0.5, r[3]-0.5, r[4]-0.5, dim_stroke, dim_rounding, 0, dim_thickness)
    end
  end

  if target_index and coord and alt1 and alt2 and orientation and self.render_drop_zones then
    local is_copy_mode = self.is_copy_mode_check and self.is_copy_mode_check() or false
    DropIndicator.draw(ctx, dl, cfg.drop or DEFAULTS.drop, is_copy_mode, orientation, coord, alt1, alt2)
  end

  if #self.drag:get_dragged_ids() > 0 then
    local fg_dl = ImGui.GetForegroundDrawList(ctx)
    DragIndicator.draw(ctx, fg_dl, mx, my, #self.drag:get_dragged_ids(), cfg.ghost or DEFAULTS.ghost)
  end
end

function Grid:_draw_external_drop_visuals(ctx, dl)
  if not self.external_drop_target or not self.render_drop_zones then return end
  
  local cfg = self.config
  local is_copy_mode = self.is_copy_mode_check and self.is_copy_mode_check() or false
  DropIndicator.draw(
    ctx, dl,
    cfg.drop or DEFAULTS.drop,
    is_copy_mode,
    self.external_drop_target.orientation,
    self.external_drop_target.coord,
    self.external_drop_target.alt1,
    self.external_drop_target.alt2
  )
end

function Grid:_draw_marquee(ctx, dl)
  if not self.sel_rect:is_active() or not self.sel_rect.start_pos then return end
  
  local x1, y1, x2, y2 = self.sel_rect:aabb()
  if not x1 then return end
  
  if not self.sel_rect:did_drag() then return end
  
  local cfg = self.config.marquee or DEFAULTS.marquee
  local fill = (self.sel_rect.mode == "add") and 
              (cfg.fill_color_add or DEFAULTS.marquee.fill_color_add) or
              (cfg.fill_color or DEFAULTS.marquee.fill_color)
  local stroke = cfg.stroke_color or DEFAULTS.marquee.stroke_color
  local thickness = cfg.stroke_thickness or DEFAULTS.marquee.stroke_thickness
  local rounding = cfg.rounding or DEFAULTS.marquee.rounding
  
  ImGui.DrawList_AddRectFilled(dl, x1, y1, x2, y2, fill, rounding)
  ImGui.DrawList_AddRect(dl, x1, y1, x2, y2, stroke, rounding, 0, thickness)
end

function Grid:get_drop_target_index()
  if self.external_drop_target then
    return self.external_drop_target.index
  end
  return nil
end

function Grid:mark_spawned(keys)
  self.animator:mark_spawned(keys)
end

function Grid:mark_destroyed(keys)
  self.animator:mark_destroyed(keys)
end

function Grid:draw(ctx)
  local items = self.get_items()
  if #items == 0 then
    ImGui.Text(ctx, "No items")
    return
  end

  local keyboard_consumed = Input.handle_shortcuts(self, ctx)
  local wheel_consumed = Input.handle_wheel_input(self, ctx, items)
  
  if wheel_consumed then
    local current_scroll_y = ImGui.GetScrollY(ctx)
    ImGui.SetScrollY(ctx, current_scroll_y)
  end

  self.current_rects = {}

  local avail_w, avail_h = ImGui.GetContentRegionAvail(ctx)
  local origin_x, origin_y = ImGui.GetCursorScreenPos(ctx)

  local min_col_w = self.min_col_w_fn()
  local cols, rows, rects = LayoutGrid.calculate(avail_w, min_col_w, self.gap, #items, origin_x, origin_y, self.fixed_tile_h)
  
  self.last_layout_cols = cols

  local current_keys = {}
  for i, item in ipairs(items) do
    local key = self.key(item)
    current_keys[key] = true
    self.rect_track:to(key, rects[i])
  end

  local new_keys = {}
  for key, _ in pairs(current_keys) do
    if not self.previous_item_keys[key] then
      new_keys[#new_keys + 1] = key
    end
  end
  
  self.animator:handle_spawn(new_keys, self.rect_track)
  self.previous_item_keys = current_keys

  local wx, wy = ImGui.GetWindowPos(ctx)
  local window_moved = false
  if self.last_window_pos then
    if wx ~= self.last_window_pos[1] or wy ~= self.last_window_pos[2] then
      window_moved = true
    end
  end
  self.last_window_pos = {wx, wy}

  if window_moved then
    local rect_map = {}
    for i, item in ipairs(items) do rect_map[self.key(item)] = rects[i] end
    self.rect_track:teleport_all(rect_map)
  else
    self.rect_track:update()
  end
  
  self.animator:update(0.016)

  local tile_h = rects[1] and (rects[1][4] - rects[1][2]) or 100
  local grid_height = rows * (tile_h + self.gap) + self.gap

  local bg_height = math.max(grid_height, avail_h)
  
  ImGui.InvisibleButton(ctx, "##grid_bg_" .. self.id, avail_w, bg_height)
  local bg_clicked = ImGui.IsItemClicked(ctx, 0)

  local function mouse_over_any_tile()
    local mx, my = ImGui.GetMousePos(ctx)
    for _, item in ipairs(items) do
      local r = self.rect_track:get(self.key(item))
      if r and Draw.point_in_rect(mx, my, r[1], r[2], r[3], r[4]) then
        return true
      end
    end
    return false
  end

  if bg_clicked and not mouse_over_any_tile() and not Input.is_external_drag_active(self) then
    local mx, my = ImGui.GetMousePos(ctx)
    local ctrl = ImGui.IsKeyDown(ctx, ImGui.Key_LeftCtrl) or ImGui.IsKeyDown(ctx, ImGui.Key_RightCtrl)
    local shift = ImGui.IsKeyDown(ctx, ImGui.Key_LeftShift) or ImGui.IsKeyDown(ctx, ImGui.Key_RightShift)
    local mode = (ctrl or shift) and "add" or "replace"
    
    self.sel_rect:begin(mx, my, mode)
    if self.on_click_empty then self.on_click_empty() end
  end

  local marquee_threshold = (self.config.marquee and self.config.marquee.drag_threshold) or DEFAULTS.marquee.drag_threshold
  
  if self.sel_rect:is_active() and ImGui.IsMouseDragging(ctx, 0, marquee_threshold) and not Input.is_external_drag_active(self) then
    local mx, my = ImGui.GetMousePos(ctx)
    self.sel_rect:update(mx, my)

    local x1, y1, x2, y2 = self.sel_rect:aabb()
    if x1 then
      local rect_map = {}
      for i, item in ipairs(items) do
        rect_map[self.key(item)] = rects[i]
      end
      self.selection:apply_rect({x1, y1, x2, y2}, rect_map, self.sel_rect.mode)
      if self.behaviors and self.behaviors.on_select then 
        self.behaviors.on_select(self.selection:selected_keys()) 
      end
    end
  end

  if self.sel_rect:is_active() and ImGui.IsMouseReleased(ctx, 0) then
    if not self.sel_rect:did_drag() then
      self.selection:clear()
      if self.behaviors and self.behaviors.on_select then 
        self.behaviors.on_select(self.selection:selected_keys()) 
      end
    end
    self.sel_rect:clear()
  end

  ImGui.SetCursorScreenPos(ctx, origin_x, origin_y)

  self.hover_id = nil
  local dl = ImGui.GetWindowDrawList(ctx)

  for i, item in ipairs(items) do
    local key = self.key(item)
    local rect = self.rect_track:get(key)
    
    if rect then
      rect = self.animator:apply_spawn_to_rect(key, rect)
      
      self.current_rects[key] = {rect[1], rect[2], rect[3], rect[4], item}

      local state = {
        hover    = false,
        selected = self.selection:is_selected(key),
        index    = i,
      }

      local is_hovered = Input.handle_tile_input(self, ctx, item, rect)
      state.hover = is_hovered

      self.render_tile(ctx, rect, item, state)
    end
  end
  
  self.animator:render_destroy_effects(ctx, dl)

  Input.check_start_drag(self, ctx)

  if self.drag:is_active() then
    self:_draw_drag_visuals(ctx, dl)
  end

  self:_update_external_drop_target(ctx)

  if Input.is_external_drag_active(self) then
    self:_draw_external_drop_visuals(ctx, dl)
    
    if self.accept_external_drops and ImGui.IsMouseReleased(ctx, 0) then
      if self.external_drop_target and self.on_external_drop then
        self.on_external_drop(self.external_drop_target.index)
      end
      self.external_drop_target = nil
    end
  end

  if self.drag:is_active() and ImGui.IsMouseReleased(ctx, 0) then
    if self.drag:get_target_index() and self.behaviors and self.behaviors.reorder then
      local order = {}
      for _, item in ipairs(items) do order[#order+1] = self.key(item) end
      
      local dragged_set = DropZones.build_dragged_set(self.drag:get_dragged_ids())
      
      local filtered_order = {}
      for _, id in ipairs(order) do
        if not dragged_set[id] then
          filtered_order[#filtered_order + 1] = id
        end
      end
      
      local new_order = {}
      local insert_pos = math.min(self.drag:get_target_index(), #filtered_order + 1)
      
      for i = 1, insert_pos - 1 do
        new_order[#new_order + 1] = filtered_order[i]
      end
      
      for _, id in ipairs(self.drag:get_dragged_ids()) do
        new_order[#new_order + 1] = id
      end
      
      for i = insert_pos, #filtered_order do
        new_order[#new_order + 1] = filtered_order[i]
      end
      
      self.behaviors.reorder(new_order)
    end
    
    local pending = self.drag:release()
    if pending and not Input.is_external_drag_active(self) then
      self.selection:single(pending)
      if self.behaviors and self.behaviors.on_select then 
        self.behaviors.on_select(self.selection:selected_keys()) 
      end
    end
  end

  if not self.drag:is_active() and ImGui.IsMouseReleased(ctx, 0) and not Input.is_external_drag_active(self) then
    if self.drag:has_pending_selection() then
      self.selection:single(self.drag:get_pending_selection())
      if self.behaviors and self.behaviors.on_select then 
        self.behaviors.on_select(self.selection:selected_keys()) 
      end
    end
    
    self.drag:release()
  end

  self:_draw_marquee(ctx, dl)

  if self.render_overlays then
    self.render_overlays(ctx, self.current_rects)
  end
end

function Grid:clear()
  self.selection:clear()
  self.rect_track:clear()
  self.sel_rect:clear()
  self.animator:clear()
  self.hover_id = nil
  self.current_rects = {}
  self.drag:clear()
  self.external_drop_target = nil
  self.last_window_pos = nil
  self.previous_item_keys = {}
  self.last_layout_cols = 1
end

return M