-- ReArkitekt/gui/widgets/colorblocks.lua
-- Reusable grid widget with selection, drag & drop, spawn/destroy animations
-- Now with generic rendering helpers for tiles

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local LayoutGrid = require('ReArkitekt.gui.systems.layout_grid')
local Motion     = require('ReArkitekt.gui.systems.motion')
local Selection  = require('ReArkitekt.gui.systems.selection')
local Reorder    = require('ReArkitekt.gui.systems.reorder')
local SelRect    = require('ReArkitekt.gui.widgets.selection_rectangle')
local Draw       = require('ReArkitekt.gui.draw')
local Colors     = require('ReArkitekt.gui.colors')
local Effects    = require('ReArkitekt.gui.effects')
local GhostTiles = require('ReArkitekt.gui.widgets.tiles.ghost_tiles')
local DropIndicator = require('ReArkitekt.gui.widgets.tiles.drop_indicator')
local SpawnAnim  = require('ReArkitekt.gui.systems.spawn_animation')
local DestroyAnim = require('ReArkitekt.gui.systems.destroy_animation')

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

M.TileHelpers = {}

function M.TileHelpers.render_hover_shadow(dl, x1, y1, x2, y2, hover_factor, rounding, config)
  config = config or DEFAULTS.tile_helpers.hover_shadow
  if not config.enabled or hover_factor < 0.01 then return end
  
  local shadow_alpha = math.floor(hover_factor * (config.max_alpha or 20))
  local shadow_col = (0x000000 << 8) | shadow_alpha
  
  for i = (config.max_offset or 2), 1, -1 do
    Draw.rect_filled(dl, x1 - i, y1 - i + 2, x2 + i, y2 + i + 2, shadow_col, rounding)
  end
end

function M.TileHelpers.render_border(dl, x1, y1, x2, y2, is_selected, base_color, border_color, thickness, rounding, config)
  config = config or DEFAULTS.tile_helpers.selection
  
  if is_selected then
    local ant_color = Colors.generate_marching_ants_color(
      base_color,
      config.brightness_factor or 1.5,
      config.saturation_factor or 0.5
    )
    
    Effects.marching_ants_rounded(
      dl, x1 + 0.5, y1 + 0.5, x2 - 0.5, y2 - 0.5,
      ant_color, thickness, rounding,
      config.ant_dash or 8, config.ant_gap or 6, config.ant_speed or 20
    )
  else
    Draw.rect(dl, x1, y1, x2, y2, border_color, rounding, thickness)
  end
end

function M.TileHelpers.compute_border_color(base_color, is_hovered, is_active, hover_factor, hover_lerp)
  local r, g, b, a = Colors.rgba_to_components(base_color)
  local max_channel = math.max(r, g, b)
  local boost = 255 / (max_channel > 0 and max_channel or 1)
  
  local border_r = math.min(255, math.floor(r * boost * 0.95))
  local border_g = math.min(255, math.floor(g * boost * 0.95))
  local border_b = math.min(255, math.floor(b * boost * 0.95))
  local flashy_border = Colors.components_to_rgba(border_r, border_g, border_b, 0xFF)
  
  if is_hovered and hover_factor and hover_lerp then
    local selection_color = Colors.generate_selection_color(base_color)
    return Colors.lerp(flashy_border, selection_color, hover_factor * hover_lerp)
  end
  
  return flashy_border
end

function M.TileHelpers.compute_fill_color(base_color, hover_factor, hover_config)
  local desat_amount = hover_config and hover_config.base_fill_desaturation or 0.5
  local bright_amount = hover_config and hover_config.base_fill_brightness or 0.45
  local fill_alpha = hover_config and hover_config.base_fill_alpha or 0xCC
  
  local desat = Colors.desaturate(base_color, desat_amount)
  local darkened = Colors.adjust_brightness(desat, bright_amount)
  local base_fill = Colors.with_alpha(darkened, fill_alpha)
  
  if hover_factor and hover_factor > 0 then
    local hover_brightness = hover_config and hover_config.hover_brightness_factor or 0.65
    local hover_fill = Colors.adjust_brightness(base_fill, hover_brightness)
    return Colors.lerp(base_fill, hover_fill, hover_factor)
  end
  
  return base_fill
end

local Grid = {}
Grid.__index = Grid

function M.new(opts)
  opts = opts or {}

  local spawn_cfg = opts.config and opts.config.spawn or DEFAULTS.spawn
  local destroy_cfg = opts.config and opts.config.destroy or DEFAULTS.destroy
  
  local grid = setmetatable({
    id               = opts.id or "grid",
    gap              = opts.gap or 12,
    min_col_w_fn     = type(opts.min_col_w) == "function" and opts.min_col_w or function() return opts.min_col_w or 160 end,
    fixed_tile_h     = opts.fixed_tile_h,
    get_items        = opts.get_items or function() return {} end,
    key              = opts.key or function(item) return tostring(item) end,
    get_exclusion_zones = opts.get_exclusion_zones,

    on_reorder       = opts.on_reorder,
    render_tile      = opts.render_tile or function() end,
    on_select        = opts.on_select,
    on_right_click   = opts.on_right_click,
    on_double_click  = opts.on_double_click,
    on_click_empty   = opts.on_click_empty,
    on_wheel_adjust  = opts.on_wheel_adjust,
    on_delete        = opts.on_delete,
    render_overlays  = opts.render_overlays,

    external_drag_check = opts.external_drag_check,
    is_copy_mode_check = opts.is_copy_mode_check,
    on_drag_start    = opts.on_drag_start,
    on_external_drop = opts.on_external_drop,
    on_destroy_complete = opts.on_destroy_complete,
    accept_external_drops = opts.accept_external_drops or false,
    render_drop_zones = opts.render_drop_zones or true,

    config           = opts.config or DEFAULTS,

    selection        = Selection.new(),
    rect_track       = Motion.RectTrack(
      opts.layout_speed or DEFAULTS.layout.speed, 
      opts.layout_snap or DEFAULTS.layout.snap_epsilon
    ),
    sel_rect         = SelRect.new(),
    spawn_anim       = SpawnAnim.new({
      duration = spawn_cfg.duration or DEFAULTS.spawn.duration,
    }),
    destroy_anim     = DestroyAnim.new({
      duration = destroy_cfg.duration or DEFAULTS.destroy.duration,
      on_complete = opts.on_destroy_complete,
    }),

    hover_id         = nil,
    current_rects    = {},
    drag = {
      pressed_id           = nil,
      pressed_was_selected = false,
      press_pos            = nil,
      active               = false,
      ids                  = nil,
      target_index         = nil,
      pending_selection    = nil,
    },
    external_drop_target = nil,
    last_window_pos  = nil,
    previous_item_keys = {},
    allow_spawn_on_new = false,
    delete_key_pressed_last_frame = false,
    
    last_layout_cols = 1,
  }, Grid)

  return grid
end

local function build_rect_map(rects, items, key_fn)
  local map = {}
  for i, item in ipairs(items) do
    local key = key_fn(item)
    if rects[i] then map[key] = rects[i] end
  end
  return map
end

function Grid:_is_external_drag_active()
  if not self.external_drag_check then return false end
  return self.external_drag_check() == true
end

function Grid:_is_mouse_in_exclusion(ctx, item, rect)
  if not self.get_exclusion_zones then return false end

  local zones = self.get_exclusion_zones(item, rect)
  if not zones or #zones == 0 then return false end

  local mx, my = ImGui.GetMousePos(ctx)
  for _, z in ipairs(zones) do
    if Draw.point_in_rect(mx, my, z[1], z[2], z[3], z[4]) then
      return true
    end
  end
  return false
end

function Grid:_find_hovered_item(ctx, items)
  local mx, my = ImGui.GetMousePos(ctx)
  for _, item in ipairs(items) do
    local key = self.key(item)
    local rect = self.rect_track:get(key)
    if rect and Draw.point_in_rect(mx, my, rect[1], rect[2], rect[3], rect[4]) then
      if not self:_is_mouse_in_exclusion(ctx, item, rect) then
        return item, key, self.selection:is_selected(key)
      end
    end
  end
  return nil, nil, false
end

function Grid:_handle_keyboard_input(ctx)
  if not self.on_delete then return false end
  
  local delete_pressed = ImGui.IsKeyPressed(ctx, ImGui.Key_Delete)
  
  if delete_pressed and not self.delete_key_pressed_last_frame then
    self.delete_key_pressed_last_frame = true
    
    if self.selection:count() > 0 then
      local keys_to_delete = self.selection:selected_keys()
      self.on_delete(keys_to_delete)
      self.selection:clear()
      if self.on_select then self.on_select(self.selection:selected_keys()) end
      return true
    end
  elseif not delete_pressed then
    self.delete_key_pressed_last_frame = false
  end
  
  return false
end

function Grid:_handle_wheel_input(ctx, items)
  if not self.on_wheel_adjust then return false end
  
  local wheel_y = ImGui.GetMouseWheel(ctx)
  if wheel_y == 0 then return false end
  
  local item, key, is_selected = self:_find_hovered_item(ctx, items)
  if not item or not key then return false end
  
  local wheel_step = (self.config.wheel and self.config.wheel.step) or DEFAULTS.wheel.step
  local delta = (wheel_y > 0) and wheel_step or -wheel_step
  
  local keys_to_adjust = {}
  if is_selected and self.selection:count() > 0 then
    keys_to_adjust = self.selection:selected_keys()
  else
    keys_to_adjust = {key}
  end
  
  self.on_wheel_adjust(keys_to_adjust, delta)
  return true
end

function Grid:_handle_tile_input(ctx, item, rect)
  local key = self.key(item)
  
  if self:_is_mouse_in_exclusion(ctx, item, rect) then
    return false
  end

  local mx, my = ImGui.GetMousePos(ctx)
  local is_hovered = Draw.point_in_rect(mx, my, rect[1], rect[2], rect[3], rect[4])
  if is_hovered then self.hover_id = key end

  if is_hovered and not self.sel_rect:is_active() and not self.drag.active and not self:_is_external_drag_active() then
    if ImGui.IsMouseClicked(ctx, 0) then
      local alt = ImGui.IsKeyDown(ctx, ImGui.Key_LeftAlt) or ImGui.IsKeyDown(ctx, ImGui.Key_RightAlt)
      
      if alt then
        if self.on_delete then
          local was_selected = self.selection:is_selected(key)
          if was_selected and self.selection:count() > 1 then
            local keys_to_delete = self.selection:selected_keys()
            self.on_delete(keys_to_delete)
          else
            self.on_delete({key})
          end
        end
        return is_hovered
      end
      
      local shift = ImGui.IsKeyDown(ctx, ImGui.Key_LeftShift) or ImGui.IsKeyDown(ctx, ImGui.Key_RightShift)
      local ctrl  = ImGui.IsKeyDown(ctx, ImGui.Key_LeftCtrl)  or ImGui.IsKeyDown(ctx, ImGui.Key_RightCtrl)
      local was_selected = self.selection:is_selected(key)

      if ctrl then
        self.selection:toggle(key)
        if self.on_select then self.on_select(self.selection:selected_keys()) end
      elseif shift and self.selection.last_clicked then
        local items = self.get_items()
        local order = {}
        for _, it in ipairs(items) do order[#order+1] = self.key(it) end
        self.selection:range(order, self.selection.last_clicked, key)
        if self.on_select then self.on_select(self.selection:selected_keys()) end
      else
        if not was_selected then
          self.drag.pending_selection = key
        end
      end

      self.drag.pressed_id = key
      self.drag.pressed_was_selected = was_selected
      self.drag.press_pos = {mx, my}
    end

    if ImGui.IsMouseClicked(ctx, 1) and self.on_right_click then
      self.on_right_click(key, self.selection:selected_keys())
    end

    if ImGui.IsMouseDoubleClicked(ctx, 0) and self.on_double_click then
      self.on_double_click(key)
    end
  end

  return is_hovered
end

function Grid:_check_start_drag(ctx)
  if not self.drag.pressed_id or self.drag.active or self:_is_external_drag_active() then return end

  local threshold = (self.config.drag and self.config.drag.threshold) or DEFAULTS.drag.threshold
  if ImGui.IsMouseDragging(ctx, 0, threshold) then
    self.drag.pending_selection = nil
    self.drag.active = true

    if self.selection:count() > 0 and self.selection:is_selected(self.drag.pressed_id) then
      local items = self.get_items()
      local order = {}
      for _, item in ipairs(items) do order[#order+1] = self.key(item) end
      self.drag.ids = self.selection:selected_keys_in(order)
    else
      self.drag.ids = { self.drag.pressed_id }
      self.selection:single(self.drag.pressed_id)
      if self.on_select then self.on_select(self.selection:selected_keys()) end
    end

    if self.on_drag_start then
      self.on_drag_start(self.drag.ids)
    end
  end
end

function Grid:_find_drop_target(ctx, mx, my, dragged_set, items)
  local non_dragged_items = {}
  for i, item in ipairs(items) do
    local key = self.key(item)
    if not dragged_set[key] then
      non_dragged_items[#non_dragged_items + 1] = {
        item = item,
        key = key,
        original_index = i
      }
    end
  end
  
  if #non_dragged_items == 0 then
    return 1, nil, nil, nil
  end
  
  local is_single_column = (self.last_layout_cols == 1)
  local drop_zones = {}
  
  if is_single_column then
    for i, entry in ipairs(non_dragged_items) do
      local rect = self.rect_track:get(entry.key)
      if rect then
        local midy = (rect[2] + rect[4]) * 0.5
        
        if i == 1 then
          drop_zones[#drop_zones + 1] = {
            x1 = rect[1],
            x2 = rect[3],
            y1 = rect[2] - 1000,
            y2 = midy,
            index = 1,
            between_y = rect[2],
            orientation = 'horizontal',
          }
        end
        
        local next_entry = non_dragged_items[i + 1]
        if next_entry then
          local next_rect = self.rect_track:get(next_entry.key)
          if next_rect then
            local between_y = (rect[4] + next_rect[2]) * 0.5
            drop_zones[#drop_zones + 1] = {
              x1 = math.min(rect[1], next_rect[1]),
              x2 = math.max(rect[3], next_rect[3]),
              y1 = midy,
              y2 = (next_rect[2] + next_rect[4]) * 0.5,
              index = i + 1,
              between_y = between_y,
              orientation = 'horizontal',
            }
          end
        else
          drop_zones[#drop_zones + 1] = {
            x1 = rect[1],
            x2 = rect[3],
            y1 = midy,
            y2 = rect[4] + 1000,
            index = i + 1,
            between_y = rect[4],
            orientation = 'horizontal',
          }
        end
      end
    end
  else
    for i, entry in ipairs(non_dragged_items) do
      local rect = self.rect_track:get(entry.key)
      if rect then
        local midx = (rect[1] + rect[3]) * 0.5
        
        if i == 1 then
          drop_zones[#drop_zones + 1] = {
            x1 = rect[1] - 1000,
            x2 = midx,
            y1 = rect[2],
            y2 = rect[4],
            index = 1,
            between_x = rect[1],
            orientation = 'vertical',
          }
        end
        
        local next_entry = non_dragged_items[i + 1]
        if next_entry then
          local next_rect = self.rect_track:get(next_entry.key)
          
          if next_rect then
            local next_midx = (next_rect[1] + next_rect[3]) * 0.5
            local between_x = (rect[3] + next_rect[1]) * 0.5
            
            local same_row = not (rect[4] < next_rect[2] or next_rect[4] < rect[2])
            
            if same_row then
              drop_zones[#drop_zones + 1] = {
                x1 = midx,
                x2 = next_midx,
                y1 = math.min(rect[2], next_rect[2]),
                y2 = math.max(rect[4], next_rect[4]),
                index = i + 1,
                between_x = between_x,
                orientation = 'vertical',
              }
            else
              drop_zones[#drop_zones + 1] = {
                x1 = midx,
                x2 = rect[3] + 1000,
                y1 = rect[2],
                y2 = rect[4],
                index = i + 1,
                between_x = rect[3],
                orientation = 'vertical',
              }
              
              drop_zones[#drop_zones + 1] = {
                x1 = next_rect[1] - 1000,
                x2 = next_midx,
                y1 = next_rect[2],
                y2 = next_rect[4],
                index = i + 1,
                between_x = next_rect[1],
                orientation = 'vertical',
              }
            end
          end
        else
          drop_zones[#drop_zones + 1] = {
            x1 = midx,
            x2 = rect[3] + 1000,
            y1 = rect[2],
            y2 = rect[4],
            index = i + 1,
            between_x = rect[3],
            orientation = 'vertical',
          }
        end
      end
    end
  end
  
  for _, zone in ipairs(drop_zones) do
    if mx >= zone.x1 and mx <= zone.x2 and my >= zone.y1 and my <= zone.y2 then
      if zone.orientation == 'horizontal' then
        return zone.index, zone.between_y, zone.x1, zone.x2, zone.orientation
      else
        return zone.index, zone.between_x, zone.y1, zone.y2, zone.orientation
      end
    end
  end
  
  return nil, nil, nil, nil, nil
end

function Grid:_update_external_drop_target(ctx)
  if not self.accept_external_drops or not self:_is_external_drag_active() then
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
  local dragged_set = {}
  for _, id in ipairs(self.drag.ids or {}) do dragged_set[id] = true end

  local items = self.get_items()
  local target_index, coord, alt1, alt2, orientation = self:_find_drop_target(ctx, mx, my, dragged_set, items)
  self.drag.target_index = target_index

  local cfg = self.config
  
  for _, id in ipairs(self.drag.ids or {}) do
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

  if self.drag.ids and #self.drag.ids > 0 then
    local fg_dl = ImGui.GetForegroundDrawList(ctx)
    GhostTiles.draw(ctx, fg_dl, mx, my, #self.drag.ids, cfg.ghost or DEFAULTS.ghost)
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
  local spawn_cfg = self.config.spawn or DEFAULTS.spawn
  if not spawn_cfg.enabled then return end
  
  self.allow_spawn_on_new = true
end

function Grid:mark_destroyed(keys)
  local destroy_cfg = self.config.destroy or DEFAULTS.destroy
  if not destroy_cfg.enabled then
    if self.on_destroy_complete then
      for _, key in ipairs(keys) do
        self.on_destroy_complete(key)
      end
    end
    return
  end
  
  for _, key in ipairs(keys) do
    local rect = self.rect_track:get(key)
    if rect then
      self.destroy_anim:destroy(key, rect)
    end
  end
end

function Grid:draw(ctx)
  local items = self.get_items()
  if #items == 0 then
    ImGui.Text(ctx, "No items")
    return
  end

  local keyboard_consumed = self:_handle_keyboard_input(ctx)
  local wheel_consumed = self:_handle_wheel_input(ctx, items)
  
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
  
  if #new_keys > 0 and self.allow_spawn_on_new then
    for _, key in ipairs(new_keys) do
      local rect = self.rect_track:get(key)
      if rect then
        self.spawn_anim:spawn(key, rect)
      end
    end
    self.allow_spawn_on_new = false
  end
  
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
  
  self.destroy_anim:update(0.016)

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

  if bg_clicked and not mouse_over_any_tile() and not self:_is_external_drag_active() then
    local mx, my = ImGui.GetMousePos(ctx)
    local ctrl = ImGui.IsKeyDown(ctx, ImGui.Key_LeftCtrl) or ImGui.IsKeyDown(ctx, ImGui.Key_RightCtrl)
    local shift = ImGui.IsKeyDown(ctx, ImGui.Key_LeftShift) or ImGui.IsKeyDown(ctx, ImGui.Key_RightShift)
    local mode = (ctrl or shift) and "add" or "replace"
    
    self.sel_rect:begin(mx, my, mode)
    if self.on_click_empty then self.on_click_empty() end
  end

  local marquee_threshold = (self.config.marquee and self.config.marquee.drag_threshold) or DEFAULTS.marquee.drag_threshold
  
  if self.sel_rect:is_active() and ImGui.IsMouseDragging(ctx, 0, marquee_threshold) and not self:_is_external_drag_active() then
    local mx, my = ImGui.GetMousePos(ctx)
    self.sel_rect:update(mx, my)

    local x1, y1, x2, y2 = self.sel_rect:aabb()
    if x1 then
      local rect_map = build_rect_map(rects, items, self.key)
      self.selection:apply_rect({x1, y1, x2, y2}, rect_map, self.sel_rect.mode)
      if self.on_select then self.on_select(self.selection:selected_keys()) end
    end
  end

  if self.sel_rect:is_active() and ImGui.IsMouseReleased(ctx, 0) then
    if not self.sel_rect:did_drag() then
      self.selection:clear()
      if self.on_select then self.on_select(self.selection:selected_keys()) end
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
      if self.spawn_anim:is_spawning(key) then
        local width_factor = self.spawn_anim:get_width_factor(key)
        local full_width = rect[3] - rect[1]
        local spawn_width = full_width * width_factor
        rect = {rect[1], rect[2], rect[1] + spawn_width, rect[4]}
      end
      
      self.current_rects[key] = {rect[1], rect[2], rect[3], rect[4], item}

      local state = {
        hover    = false,
        selected = self.selection:is_selected(key),
        index    = i,
      }

      local is_hovered = self:_handle_tile_input(ctx, item, rect)
      state.hover = is_hovered

      self.render_tile(ctx, rect, item, state)
    end
  end
  
  for key, anim_data in pairs(self.destroy_anim.destroying) do
    self.destroy_anim:render(ctx, dl, key, anim_data.rect, 0x1A1A1AFF, 6)
  end

  self:_check_start_drag(ctx)

  if self.drag.active then
    self:_draw_drag_visuals(ctx, dl)
  end

  self:_update_external_drop_target(ctx)

  if self:_is_external_drag_active() then
    self:_draw_external_drop_visuals(ctx, dl)
    
    if self.accept_external_drops and ImGui.IsMouseReleased(ctx, 0) then
      if self.external_drop_target and self.on_external_drop then
        self.on_external_drop(self.external_drop_target.index)
      end
      self.external_drop_target = nil
    end
  end

  if self.drag.active and ImGui.IsMouseReleased(ctx, 0) then
    if self.drag.target_index and self.on_reorder then
      local order = {}
      for _, item in ipairs(items) do order[#order+1] = self.key(item) end
      
      local dragged_set = {}
      for _, id in ipairs(self.drag.ids) do dragged_set[id] = true end
      
      local filtered_order = {}
      for _, id in ipairs(order) do
        if not dragged_set[id] then
          filtered_order[#filtered_order + 1] = id
        end
      end
      
      local new_order = {}
      local insert_pos = math.min(self.drag.target_index, #filtered_order + 1)
      
      for i = 1, insert_pos - 1 do
        new_order[#new_order + 1] = filtered_order[i]
      end
      
      for _, id in ipairs(self.drag.ids) do
        new_order[#new_order + 1] = id
      end
      
      for i = insert_pos, #filtered_order do
        new_order[#new_order + 1] = filtered_order[i]
      end
      
      self.on_reorder(new_order)
    end
    self.drag.active = false
    self.drag.ids = nil
    self.drag.target_index = nil
    self.drag.pending_selection = nil
  end

  if not self.drag.active and ImGui.IsMouseReleased(ctx, 0) and not self:_is_external_drag_active() then
    if self.drag.pending_selection then
      self.selection:single(self.drag.pending_selection)
      if self.on_select then self.on_select(self.selection:selected_keys()) end
    end
    
    self.drag.pressed_id = nil
    self.drag.pressed_was_selected = false
    self.drag.press_pos = nil
    self.drag.pending_selection = nil
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
  self.spawn_anim:clear()
  self.destroy_anim:clear()
  self.hover_id = nil
  self.current_rects = {}
  self.drag = {
    pressed_id           = nil,
    pressed_was_selected = false,
    press_pos            = nil,
    active               = false,
    ids                  = nil,
    target_index         = nil,
    pending_selection    = nil,
  }
  self.external_drop_target = nil
  self.last_window_pos = nil
  self.previous_item_keys = {}
  self.allow_spawn_on_new = false
  self.delete_key_pressed_last_frame = false
  self.last_layout_cols = 1
end

return M