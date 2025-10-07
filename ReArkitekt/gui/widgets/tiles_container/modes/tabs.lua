-- ReArkitekt/gui/widgets/tiles_container/modes/tabs.lua
-- Tab mode with drag & drop indicators and animations

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'
local ContextMenu = require('ReArkitekt.gui.widgets.controls.context_menu')
local DragIndicator = require('ReArkitekt.gui.fx.dnd.drag_indicator')
local DropIndicator = require('ReArkitekt.gui.fx.dnd.drop_indicator')

local M = {}

local function draw_plus_button(ctx, dl, x, y, state, cfg)
  local btn_cfg = cfg.tabs.plus_button
  local w = btn_cfg.width
  local h = btn_cfg.height

  local is_hovered = ImGui.IsMouseHoveringRect(ctx, x, y, x + w, y + h)
  local is_active = ImGui.IsMouseDown(ctx, 0) and is_hovered

  local bg_color = btn_cfg.bg_color
  if is_active then
    bg_color = btn_cfg.bg_active_color
  elseif is_hovered then
    bg_color = btn_cfg.bg_hover_color
  end

  local border_color = is_hovered and btn_cfg.border_hover_color or btn_cfg.border_color
  local text_color = is_hovered and btn_cfg.text_hover_color or btn_cfg.text_color

  ImGui.DrawList_AddRectFilled(dl, x, y, x + w, y + h, bg_color, btn_cfg.rounding)
  ImGui.DrawList_AddRect(dl, x, y, x + w, y + h, border_color, btn_cfg.rounding, 0, 1)

  local text_w, text_h = ImGui.CalcTextSize(ctx, btn_cfg.icon)
  local text_x = x + (w - text_w) * 0.5
  local text_y = y + (h - text_h) * 0.5
  ImGui.DrawList_AddText(dl, text_x, text_y, text_color, btn_cfg.icon)

  ImGui.SetCursorScreenPos(ctx, x, y)
  local clicked = ImGui.InvisibleButton(ctx, "##plus_" .. state.id, w, h)

  return clicked, x + w
end

local function get_tab_color(tab_data)
  return tab_data.color or 0x42E896FF
end

local function apply_spawn_animation(x, y, w, h, spawn_factor)
  local target_w = w * spawn_factor
  local offset_x = (w - target_w) * 0.5
  
  return x + offset_x, y, target_w, h
end

local function apply_destroy_animation(x, y, w, h, destroy_factor, tab_cfg)
  local scale = 1.0 - destroy_factor
  local new_w = w * scale
  local new_h = h * scale
  local offset_x = (w - new_w) * 0.5
  local offset_y = (h - new_h) * 0.5
  
  return x + offset_x, y + offset_y, new_w, new_h
end

local function draw_tab(ctx, dl, x, y, tab_data, is_active, tab_index, state, cfg)
  local tab_cfg = cfg.tabs.tab
  local label = tab_data.label or "Tab"
  local id = tab_data.id
  
  local animator = state.tab_animator
  local is_spawning = animator and animator:is_spawning(id)
  local is_destroying = animator and animator:is_destroying(id)

  local text_w, text_h = ImGui.CalcTextSize(ctx, label)
  local w = math.min(tab_cfg.max_width, math.max(tab_cfg.min_width, text_w + tab_cfg.padding_x * 2))
  local h = tab_cfg.height
  
  local render_x, render_y, render_w, render_h = x, y, w, h
  local alpha_factor = 1.0
  
  if is_spawning then
    local spawn_factor = animator:get_spawn_factor(id)
    render_x, render_y, render_w, render_h = apply_spawn_animation(x, y, w, h, spawn_factor)
    alpha_factor = spawn_factor
  elseif is_destroying then
    local destroy_factor = animator:get_destroy_factor(id)
    render_x, render_y, render_w, render_h = apply_destroy_animation(x, y, w, h, destroy_factor, tab_cfg)
    alpha_factor = 1.0 - destroy_factor
  end

  local is_hovered = ImGui.IsMouseHoveringRect(ctx, render_x, render_y, render_x + render_w, render_y + render_h)
  local is_pressed = ImGui.IsMouseDown(ctx, 0) and is_hovered

  local bg_color = tab_cfg.bg_color
  if is_active then
    bg_color = tab_cfg.bg_active_color
  elseif is_pressed then
    bg_color = tab_cfg.bg_active_color
  elseif is_hovered then
    bg_color = tab_cfg.bg_hover_color
  end

  local apply_alpha = function(color, factor)
    local a = color & 0xFF
    local new_a = math.floor(a * factor)
    return (color & 0xFFFFFF00) | new_a
  end
  
  bg_color = apply_alpha(bg_color, alpha_factor)

  local border_color = is_active and tab_cfg.border_active_color or tab_cfg.border_color
  border_color = apply_alpha(border_color, alpha_factor)
  
  local text_color = is_active and tab_cfg.text_active_color or (is_hovered and tab_cfg.text_hover_color or tab_cfg.text_color)
  text_color = apply_alpha(text_color, alpha_factor)

  ImGui.DrawList_AddRectFilled(dl, render_x, render_y, render_x + render_w, render_y + render_h, bg_color, tab_cfg.rounding)
  ImGui.DrawList_AddRect(dl, render_x, render_y, render_x + render_w, render_y + render_h, border_color, tab_cfg.rounding, 0, 1)

  local text_x = render_x + tab_cfg.padding_x * (render_w / w)
  local text_y = render_y + (render_h - text_h) * 0.5

  local text_max_w = render_w - tab_cfg.padding_x * 2 * (render_w / w)
  if text_w > text_max_w then
    ImGui.DrawList_PushClipRect(dl, render_x + tab_cfg.padding_x, render_y, render_x + render_w - tab_cfg.padding_x, render_y + render_h, true)
    ImGui.DrawList_AddText(dl, text_x, text_y, text_color, label)
    ImGui.DrawList_PopClipRect(dl)
  else
    ImGui.DrawList_AddText(dl, text_x, text_y, text_color, label)
  end

  ImGui.SetCursorScreenPos(ctx, render_x, render_y)
  ImGui.InvisibleButton(ctx, "##tab_" .. id .. "_" .. state.id, render_w, render_h)

  local clicked = ImGui.IsItemClicked(ctx, 0)
  local right_clicked = ImGui.IsItemClicked(ctx, 1)

  if ImGui.BeginDragDropSource(ctx) then
    state.dragging_tab = {
      index = tab_index,
      id = id,
      label = label,
      color = get_tab_color(tab_data),
    }
    ImGui.SetDragDropPayload(ctx, "TAB_REORDER", tostring(tab_index))
    ImGui.EndDragDropSource(ctx)
  end

  local drop_side = nil
  if ImGui.BeginDragDropTarget(ctx) then
    local payload = ImGui.AcceptDragDropPayload(ctx, "TAB_REORDER")
    if payload then
      local source_index = tonumber(payload)
      if source_index and source_index ~= tab_index then
        local mx = ImGui.GetMousePos(ctx)
        local center_x = render_x + render_w * 0.5
        drop_side = mx < center_x and "before" or "after"
        
        state.drop_target = {
          index = tab_index,
          side = drop_side,
          source_index = source_index,
        }
      end
    end
    ImGui.EndDragDropTarget(ctx)
  end

  local delete_requested = false
  if right_clicked then
    ImGui.OpenPopup(ctx, "##tab_context_" .. id)
  end

  if ContextMenu.begin(ctx, "##tab_context_" .. id, cfg.tabs.context_menu) then
    if ContextMenu.item(ctx, "Delete Playlist", cfg.tabs.context_menu) then
      delete_requested = true
    end
    ContextMenu.end_menu(ctx)
  end

  return clicked, x + w, delete_requested, drop_side
end

function M.draw(ctx, dl, x, y, width, height, state, cfg)
  local tabs_cfg = cfg.tabs
  if not tabs_cfg or not tabs_cfg.enabled then return height end

  if state.tab_animator then
    state.tab_animator:update()
  end

  local content_height = height - (cfg.padding_y * 2)
  local cursor_x = x + cfg.padding_x
  local cursor_y = y + (height - content_height) * 0.5

  cursor_x = cursor_x + 4

  local plus_clicked, new_x = draw_plus_button(ctx, dl, cursor_x, cursor_y, state, cfg)
  cursor_x = new_x + tabs_cfg.tab.spacing + 4

  if plus_clicked and state.on_tab_create then
    state.on_tab_create()
  end

  local available_width = width - (cursor_x - x) - tabs_cfg.reserved_right_space
  
  local id_to_delete = nil
  state.drop_target = nil

  for i, tab_data in ipairs(state.tabs) do
    local is_active = (tab_data.id == state.active_tab_id)
    local clicked, next_x, delete_requested, drop_side = draw_tab(ctx, dl, cursor_x, cursor_y, tab_data, is_active, i, state, cfg)

    if clicked and state.on_tab_change then
      state.on_tab_change(tab_data.id)
    end

    if delete_requested then
      id_to_delete = tab_data.id
    end

    cursor_x = next_x + tabs_cfg.tab.spacing

    if cursor_x - x > available_width then
      break
    end
  end

  if state.dragging_tab and not ImGui.IsMouseDown(ctx, 0) then
    if state.drop_target and state.on_tab_reorder then
      local source_idx = state.drop_target.source_index
      local target_idx = state.drop_target.index
      
      if state.drop_target.side == "after" then
        target_idx = target_idx + 1
      end
      
      state.on_tab_reorder(source_idx, target_idx)
    end
    state.dragging_tab = nil
    state.drop_target = nil
  end

  if state.dragging_tab and ImGui.IsMouseDragging(ctx, 0) then
    local mx, my = ImGui.GetMousePos(ctx)
    local tab_color = state.dragging_tab.color or 0x42E896FF
    
    DragIndicator.draw(ctx, dl, mx, my, 1, cfg.tabs.drag_config, {tab_color}, false, false)
  end

  if state.drop_target then
    local target_tab = state.tabs[state.drop_target.index]
    if target_tab then
      local text_w = ImGui.CalcTextSize(ctx, target_tab.label or "Tab")
      local tab_w = math.min(tabs_cfg.tab.max_width, math.max(tabs_cfg.tab.min_width, text_w + tabs_cfg.tab.padding_x * 2))
      
      local drop_x = x + cfg.padding_x + 4 + tabs_cfg.plus_button.width + tabs_cfg.tab.spacing + 4
      
      for idx = 1, state.drop_target.index - 1 do
        local tab = state.tabs[idx]
        local tw = ImGui.CalcTextSize(ctx, tab.label or "Tab")
        local w = math.min(tabs_cfg.tab.max_width, math.max(tabs_cfg.tab.min_width, tw + tabs_cfg.tab.padding_x * 2))
        drop_x = drop_x + w + tabs_cfg.tab.spacing
      end
      
      if state.drop_target.side == "before" then
        DropIndicator.draw_vertical(ctx, dl, drop_x, cursor_y, cursor_y + content_height, cfg.tabs.drop_config, false)
      else
        DropIndicator.draw_vertical(ctx, dl, drop_x + tab_w, cursor_y, cursor_y + content_height, cfg.tabs.drop_config, false)
      end
    end
  end

  if id_to_delete and #state.tabs > 1 then
    if state.tab_animator then
      state.tab_animator:destroy(id_to_delete)
      state.pending_delete_id = id_to_delete
    elseif state.on_tab_delete then
      state.on_tab_delete(id_to_delete)
    end
  end

  if state.pending_delete_id and state.tab_animator then
    if not state.tab_animator:is_destroying(state.pending_delete_id) then
      if state.on_tab_delete then
        state.on_tab_delete(state.pending_delete_id)
      end
      state.pending_delete_id = nil
    end
  end

  return height
end

return M