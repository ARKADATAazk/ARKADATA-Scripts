-- ReArkitekt/gui/widgets/grid/input.lua
-- Input handling for grid widgets - keyboard, mouse, drag detection

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local Draw = require('ReArkitekt.gui.draw')

local M = {}

function M.is_external_drag_active(grid)
  if not grid.external_drag_check then return false end
  return grid.external_drag_check() == true
end

function M.is_mouse_in_exclusion(grid, ctx, item, rect)
  if not grid.get_exclusion_zones then return false end

  local zones = grid.get_exclusion_zones(item, rect)
  if not zones or #zones == 0 then return false end

  local mx, my = ImGui.GetMousePos(ctx)
  for _, z in ipairs(zones) do
    if Draw.point_in_rect(mx, my, z[1], z[2], z[3], z[4]) then
      return true
    end
  end
  return false
end

function M.find_hovered_item(grid, ctx, items)
  local mx, my = ImGui.GetMousePos(ctx)
  for _, item in ipairs(items) do
    local key = grid.key(item)
    local rect = grid.rect_track:get(key)
    if rect and Draw.point_in_rect(mx, my, rect[1], rect[2], rect[3], rect[4]) then
      if not M.is_mouse_in_exclusion(grid, ctx, item, rect) then
        return item, key, grid.selection:is_selected(key)
      end
    end
  end
  return nil, nil, false
end

function M.handle_keyboard_input(grid, ctx)
  if not grid.on_delete then return false end
  
  local delete_pressed = ImGui.IsKeyPressed(ctx, ImGui.Key_Delete)
  
  if delete_pressed and not grid.delete_key_pressed_last_frame then
    grid.delete_key_pressed_last_frame = true
    
    if grid.selection:count() > 0 then
      local keys_to_delete = grid.selection:selected_keys()
      grid.on_delete(keys_to_delete)
      grid.selection:clear()
      if grid.on_select then grid.on_select(grid.selection:selected_keys()) end
      return true
    end
  elseif not delete_pressed then
    grid.delete_key_pressed_last_frame = false
  end
  
  return false
end

function M.handle_wheel_input(grid, ctx, items, defaults)
  if not grid.on_wheel_adjust then return false end
  
  local wheel_y = ImGui.GetMouseWheel(ctx)
  if wheel_y == 0 then return false end
  
  local item, key, is_selected = M.find_hovered_item(grid, ctx, items)
  if not item or not key then return false end
  
  local wheel_step = (grid.config.wheel and grid.config.wheel.step) or defaults.wheel.step
  local delta = (wheel_y > 0) and wheel_step or -wheel_step
  
  local keys_to_adjust = {}
  if is_selected and grid.selection:count() > 0 then
    keys_to_adjust = grid.selection:selected_keys()
  else
    keys_to_adjust = {key}
  end
  
  grid.on_wheel_adjust(keys_to_adjust, delta)
  return true
end

function M.handle_tile_input(grid, ctx, item, rect)
  local key = grid.key(item)
  
  if M.is_mouse_in_exclusion(grid, ctx, item, rect) then
    return false
  end

  local mx, my = ImGui.GetMousePos(ctx)
  local is_hovered = Draw.point_in_rect(mx, my, rect[1], rect[2], rect[3], rect[4])
  if is_hovered then grid.hover_id = key end

  if is_hovered and not grid.sel_rect:is_active() and not grid.drag.active and not M.is_external_drag_active(grid) then
    if ImGui.IsMouseClicked(ctx, 0) then
      local alt = ImGui.IsKeyDown(ctx, ImGui.Key_LeftAlt) or ImGui.IsKeyDown(ctx, ImGui.Key_RightAlt)
      
      if alt then
        if grid.on_delete then
          local was_selected = grid.selection:is_selected(key)
          if was_selected and grid.selection:count() > 1 then
            local keys_to_delete = grid.selection:selected_keys()
            grid.on_delete(keys_to_delete)
          else
            grid.on_delete({key})
          end
        end
        return is_hovered
      end
      
      local shift = ImGui.IsKeyDown(ctx, ImGui.Key_LeftShift) or ImGui.IsKeyDown(ctx, ImGui.Key_RightShift)
      local ctrl  = ImGui.IsKeyDown(ctx, ImGui.Key_LeftCtrl)  or ImGui.IsKeyDown(ctx, ImGui.Key_RightCtrl)
      local was_selected = grid.selection:is_selected(key)

      if ctrl then
        grid.selection:toggle(key)
        if grid.on_select then grid.on_select(grid.selection:selected_keys()) end
      elseif shift and grid.selection.last_clicked then
        local items = grid.get_items()
        local order = {}
        for _, it in ipairs(items) do order[#order+1] = grid.key(it) end
        grid.selection:range(order, grid.selection.last_clicked, key)
        if grid.on_select then grid.on_select(grid.selection:selected_keys()) end
      else
        if not was_selected then
          grid.drag.pending_selection = key
        end
      end

      grid.drag.pressed_id = key
      grid.drag.pressed_was_selected = was_selected
      grid.drag.press_pos = {mx, my}
    end

    if ImGui.IsMouseClicked(ctx, 1) and grid.on_right_click then
      grid.on_right_click(key, grid.selection:selected_keys())
    end

    if ImGui.IsMouseDoubleClicked(ctx, 0) and grid.on_double_click then
      grid.on_double_click(key)
    end
  end

  return is_hovered
end

function M.check_start_drag(grid, ctx, defaults)
  if not grid.drag.pressed_id or grid.drag.active or M.is_external_drag_active(grid) then return end

  local threshold = (grid.config.drag and grid.config.drag.threshold) or defaults.drag.threshold
  if ImGui.IsMouseDragging(ctx, 0, threshold) then
    grid.drag.pending_selection = nil
    grid.drag.active = true

    if grid.selection:count() > 0 and grid.selection:is_selected(grid.drag.pressed_id) then
      local items = grid.get_items()
      local order = {}
      for _, item in ipairs(items) do order[#order+1] = grid.key(item) end
      grid.drag.ids = grid.selection:selected_keys_in(order)
    else
      grid.drag.ids = { grid.drag.pressed_id }
      grid.selection:single(grid.drag.pressed_id)
      if grid.on_select then grid.on_select(grid.selection:selected_keys()) end
    end

    if grid.on_drag_start then
      grid.on_drag_start(grid.drag.ids)
    end
  end
end

return M