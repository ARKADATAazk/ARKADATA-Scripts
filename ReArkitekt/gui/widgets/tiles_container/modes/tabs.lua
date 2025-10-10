-- ReArkitekt/gui/widgets/tiles_container/modes/tabs.lua
-- Tab mode with chip indicators instead of colored backgrounds

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'
local ContextMenu = require('ReArkitekt.gui.widgets.controls.context_menu')
local Chip = require('ReArkitekt.gui.widgets.component.chip')

local M = {}

local TAB_SLIDE_SPEED = 15.0
local DRAG_THRESHOLD = 3.0

local function with_alpha(color, alpha)
  return (color & 0xFFFFFF00) | (alpha & 0xFF)
end

function M.assign_random_color(tab)
  if not tab.chip_color then
    local hue = math.random() * 360
    local sat = 0.6 + math.random() * 0.3
    local val = 0.7 + math.random() * 0.2
    
    local h = hue / 60
    local i = math.floor(h)
    local f = h - i
    local p = val * (1 - sat)
    local q = val * (1 - sat * f)
    local t = val * (1 - sat * (1 - f))
    
    local r, g, b
    if i == 0 then
      r, g, b = val, t, p
    elseif i == 1 then
      r, g, b = q, val, p
    elseif i == 2 then
      r, g, b = p, val, t
    elseif i == 3 then
      r, g, b = p, q, val
    elseif i == 4 then
      r, g, b = t, p, val
    else
      r, g, b = val, p, q
    end
    
    local ri = math.floor(r * 255)
    local gi = math.floor(g * 255)
    local bi = math.floor(b * 255)
    
    tab.chip_color = (ri << 24) | (gi << 16) | (bi << 8) | 0xFF
  end
end

local function draw_plus_button(ctx, dl, x, y, state, cfg)
  local btn_cfg = cfg.tabs.plus_button
  local w = btn_cfg.width
  local h = cfg.element_height or 20

  local is_hovered = ImGui.IsMouseHoveringRect(ctx, x, y, x + w, y + h)
  local is_active = ImGui.IsMouseDown(ctx, 0) and is_hovered

  local bg_color = btn_cfg.bg_color
  if is_active then
    bg_color = btn_cfg.bg_active_color
  elseif is_hovered then
    bg_color = btn_cfg.bg_hover_color
  end

  local border_color = is_hovered and btn_cfg.border_hover_color or btn_cfg.border_color
  local icon_color = is_hovered and btn_cfg.text_hover_color or btn_cfg.text_color

  local corner_flags = ImGui.DrawFlags_RoundCornersTopLeft | ImGui.DrawFlags_RoundCornersBottomLeft
  ImGui.DrawList_AddRectFilled(dl, x, y, x + w, y + h, bg_color, btn_cfg.rounding, corner_flags)
  ImGui.DrawList_AddRect(dl, x, y, x + w, y + h, border_color, btn_cfg.rounding, corner_flags, 1)

  local center_x = x + w * 0.5 
  local center_y = y + h * 0.5 - 1
  local cross_size = 7
  local cross_thickness = 1
  
  ImGui.DrawList_AddRectFilled(dl, 
    center_x - cross_size * 0.5, center_y - cross_thickness * 0.5,
    center_x + cross_size * 0.5, center_y + cross_thickness * 0.5,
    icon_color)
  
  ImGui.DrawList_AddRectFilled(dl,
    center_x - cross_thickness * 0.5, center_y - cross_size * 0.5,
    center_x + cross_thickness * 0.5, center_y + cross_size * 0.5,
    icon_color)

  ImGui.SetCursorScreenPos(ctx, x, y)
  local clicked = ImGui.InvisibleButton(ctx, "##plus_" .. state.id, w, h)

  return clicked, x + w
end

local function draw_tabs_track(ctx, dl, plus_x, tabs_start_x, tabs_end_x, y, height, cfg)
  if not cfg or not cfg.tabs or not cfg.tabs.track then return end
  
  local track_cfg = cfg.tabs.track
  if not track_cfg.enabled then return end
  
  local track_start_x = plus_x - track_cfg.extend_left
  if not track_cfg.include_plus_button then
    track_start_x = tabs_start_x - track_cfg.extend_left
  end
  
  local track_end_x = tabs_end_x + track_cfg.extend_right
  local track_y = y - track_cfg.extend_top
  local track_height = height + track_cfg.extend_top + track_cfg.extend_bottom
  
  ImGui.DrawList_AddRectFilled(
    dl,
    track_start_x, track_y,
    track_end_x, track_y + track_height,
    track_cfg.bg_color,
    track_cfg.rounding
  )
  
  if track_cfg.border_thickness > 0 then
    ImGui.DrawList_AddRect(
      dl,
      track_start_x, track_y,
      track_end_x, track_y + track_height,
      track_cfg.border_color,
      track_cfg.rounding,
      0,
      track_cfg.border_thickness
    )
  end
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

local function calculate_tab_width(ctx, label, tab_cfg, has_chip)
  local text_w = ImGui.CalcTextSize(ctx, label)
  local chip_width = has_chip and 20 or 0
  return math.min(tab_cfg.max_width, math.max(tab_cfg.min_width, text_w + tab_cfg.padding_x * 2 + chip_width))
end

local function init_tab_positions(state)
  if not state.tab_positions then
    state.tab_positions = {}
  end
  
  for _, tab in ipairs(state.tabs) do
    if not state.tab_positions[tab.id] then
      state.tab_positions[tab.id] = {
        current_x = 0,
        target_x = 0,
      }
    end
  end
end

local function update_tab_positions(ctx, state, cfg, start_x)
  local tab_cfg = cfg.tabs.tab
  local spacing = tab_cfg.spacing
  
  local dt = ImGui.GetDeltaTime(ctx)
  local cursor_x = start_x
  
  for i, tab in ipairs(state.tabs) do
    local has_chip = tab.chip_color ~= nil
    local tab_width = calculate_tab_width(ctx, tab.label or "Tab", tab_cfg, has_chip)
    local pos = state.tab_positions[tab.id]
    
    if not pos then
      pos = { current_x = cursor_x, target_x = cursor_x }
      state.tab_positions[tab.id] = pos
    end
    
    pos.target_x = cursor_x
    
    local diff = pos.target_x - pos.current_x
    if math.abs(diff) > 0.5 then
      local move = diff * TAB_SLIDE_SPEED * dt
      pos.current_x = pos.current_x + move
    else
      pos.current_x = pos.target_x
    end
    
    cursor_x = cursor_x + tab_width + spacing
  end
end

local function draw_tab(ctx, dl, tab_data, is_active, tab_index, y, state, cfg)
  local tab_cfg = cfg.tabs.tab
  local label = tab_data.label or "Tab"
  local id = tab_data.id
  local chip_color = tab_data.chip_color
  local has_chip = chip_color ~= nil
  
  local animator = state.tab_animator
  local is_spawning = animator and animator:is_spawning(id)
  local is_destroying = animator and animator:is_destroying(id)

  local w = calculate_tab_width(ctx, label, tab_cfg, has_chip)
  local h = cfg.element_height or 20
  
  local pos = state.tab_positions[id]
  if not pos then
    pos = { current_x = 0, target_x = 0 }
    state.tab_positions[id] = pos
  end
  
  local x = pos.current_x
  
  if state.dragging_tab and state.dragging_tab.id == id then
    local mx = ImGui.GetMousePos(ctx)
    x = mx - state.dragging_tab.offset_x
  end
  
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
  local is_pressed = ImGui.IsMouseDown(ctx, 0) and is_hovered and not state.dragging_tab

  local apply_alpha = function(color, factor)
    local a = color & 0xFF
    local new_a = math.floor(a * factor)
    return (color & 0xFFFFFF00) | new_a
  end

  local bg_color, border_color, text_color
  
  bg_color = tab_cfg.bg_color
  border_color = tab_cfg.border_color
  text_color = tab_cfg.text_color
  
  if is_active then
    bg_color = tab_cfg.bg_active_color
    border_color = tab_cfg.border_active_color
    text_color = tab_cfg.text_active_color
  elseif is_pressed then
    bg_color = tab_cfg.bg_hover_color
    text_color = tab_cfg.text_hover_color
  elseif is_hovered then
    bg_color = tab_cfg.bg_hover_color
    text_color = tab_cfg.text_hover_color
  end
  
  bg_color = apply_alpha(bg_color, alpha_factor)
  border_color = apply_alpha(border_color, alpha_factor)
  text_color = apply_alpha(text_color, alpha_factor)

  local corner_flags = 0
  if tab_cfg.rounding > 0 then
    corner_flags = ImGui.DrawFlags_RoundCornersTop
  end

  ImGui.DrawList_AddRectFilled(dl, render_x, render_y, render_x + render_w, render_y + render_h, 
                                bg_color, tab_cfg.rounding, corner_flags)

  ImGui.DrawList_AddRect(dl, render_x, render_y, render_x + render_w, render_y + render_h, 
                         border_color, tab_cfg.rounding, corner_flags, 1)

  local content_x = render_x + tab_cfg.padding_x
  
  if has_chip then
    local chip_x = content_x + 2
    local chip_y = render_y + render_h * 0.5
    
    Chip.draw(ctx, {
      style = Chip.STYLE.INDICATOR,
      color = chip_color,
      draw_list = dl,
      x = chip_x,
      y = chip_y,
      radius = tab_cfg.chip_radius or 4,
      is_selected = is_active,
      is_hovered = is_hovered,
      show_glow = is_active or is_hovered,
      glow_layers = 2,
      alpha_factor = alpha_factor,
    })
    
    content_x = content_x + 12
  end

  local text_w, text_h = ImGui.CalcTextSize(ctx, label)
  local text_x = content_x
  local text_y = render_y + (render_h - text_h) * 0.5

  local text_max_w = render_x + render_w - text_x - tab_cfg.padding_x
  if text_w > text_max_w then
    ImGui.DrawList_PushClipRect(dl, text_x, render_y, 
                                render_x + render_w - tab_cfg.padding_x, render_y + render_h, true)
    ImGui.DrawList_AddText(dl, text_x, text_y, text_color, label)
    ImGui.DrawList_PopClipRect(dl)
  else
    ImGui.DrawList_AddText(dl, text_x, text_y, text_color, label)
  end

  ImGui.SetCursorScreenPos(ctx, render_x, render_y)
  ImGui.InvisibleButton(ctx, "##tab_" .. id .. "_" .. state.id, render_w, render_h)

  local clicked = ImGui.IsItemClicked(ctx, 0)
  local right_clicked = ImGui.IsItemClicked(ctx, 1)

  if ImGui.IsItemActive(ctx) and not state.dragging_tab then
    local drag_delta_x, drag_delta_y = ImGui.GetMouseDragDelta(ctx, 0)
    local drag_distance = math.sqrt(drag_delta_x * drag_delta_x + drag_delta_y * drag_delta_y)
    
    if drag_distance > DRAG_THRESHOLD then
      local mx = ImGui.GetMousePos(ctx)
      state.dragging_tab = {
        id = id,
        index = tab_index,
        offset_x = mx - render_x,
        original_index = tab_index,
      }
    end
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

  return clicked, w, delete_requested
end

function M.draw(ctx, dl, x, y, width, height, state, cfg)
  local tabs_cfg = cfg.tabs
  if not tabs_cfg or not tabs_cfg.enabled then return height end

  if state.tab_animator then
    state.tab_animator:update()
  end

  init_tab_positions(state)

  local element_height = cfg.element_height or 20
  local cursor_x = x + cfg.padding_x
  local cursor_y = y + (height - element_height) * 0.5

  local tabs_start_x = cursor_x + tabs_cfg.plus_button.width + tabs_cfg.tab.spacing
  
  local tabs_end_x = tabs_start_x
  for i, tab in ipairs(state.tabs) do
    local has_chip = tab.chip_color ~= nil
    local tab_width = calculate_tab_width(ctx, tab.label or "Tab", tabs_cfg.tab, has_chip)
    tabs_end_x = tabs_end_x + tab_width
    if i < #state.tabs then
      tabs_end_x = tabs_end_x + tabs_cfg.tab.spacing
    end
  end
  
  draw_tabs_track(ctx, dl, cursor_x, tabs_start_x, tabs_end_x, cursor_y, element_height, cfg)

  local plus_clicked, new_x = draw_plus_button(ctx, dl, cursor_x, cursor_y, state, cfg)
  tabs_start_x = new_x + tabs_cfg.tab.spacing

  if plus_clicked and state.on_tab_create then
    state.on_tab_create()
  end

  if state.dragging_tab and ImGui.IsMouseDragging(ctx, 0) then
    local mx = ImGui.GetMousePos(ctx)
    local dragged_tab = state.tabs[state.dragging_tab.index]
    local has_chip = dragged_tab.chip_color ~= nil
    local dragged_width = calculate_tab_width(ctx, dragged_tab.label or "Tab", tabs_cfg.tab, has_chip)
    
    local drag_center_x = mx - state.dragging_tab.offset_x + dragged_width * 0.5
    
    local positions = {}
    local current_x = tabs_start_x
    
    for i = 1, #state.tabs do
      if i ~= state.dragging_tab.index then
        local tab = state.tabs[i]
        local tab_has_chip = tab.chip_color ~= nil
        local tab_w = calculate_tab_width(ctx, tab.label or "Tab", tabs_cfg.tab, tab_has_chip)
        
        table.insert(positions, {
          index = i,
          left = current_x,
          center = current_x + tab_w * 0.5,
          right = current_x + tab_w,
          width = tab_w
        })
        
        current_x = current_x + tab_w + tabs_cfg.tab.spacing
      end
    end
    
    local target_index = 1
    
    for i, pos in ipairs(positions) do
      if drag_center_x > pos.center then
        target_index = pos.index + 1
      else
        break
      end
    end
    
    if target_index > state.dragging_tab.index then
      target_index = target_index - 1
    end
    
    target_index = math.max(1, math.min(#state.tabs, target_index))
    
    if target_index ~= state.dragging_tab.index then
      local dragged_tab_data = table.remove(state.tabs, state.dragging_tab.index)
      table.insert(state.tabs, target_index, dragged_tab_data)
      state.dragging_tab.index = target_index
    end
  end

  if state.dragging_tab and not ImGui.IsMouseDown(ctx, 0) then
    if state.on_tab_reorder and state.dragging_tab.original_index ~= state.dragging_tab.index then
      state.on_tab_reorder(state.dragging_tab.original_index, state.dragging_tab.index)
    end
    state.dragging_tab = nil
  end

  update_tab_positions(ctx, state, cfg, tabs_start_x)
  
  local id_to_delete = nil
  local clicked_tab_id = nil

  for i, tab_data in ipairs(state.tabs) do
    local is_active = (tab_data.id == state.active_tab_id)
    local clicked, tab_w, delete_requested = draw_tab(ctx, dl, tab_data, is_active, 
                                                       i, cursor_y, state, cfg)

    if clicked and not (state.dragging_tab or ImGui.IsMouseDragging(ctx, 0)) then
      clicked_tab_id = tab_data.id
    end

    if delete_requested then
      id_to_delete = tab_data.id
    end
  end

  if clicked_tab_id then
    state.active_tab_id = clicked_tab_id
    if state.on_tab_change then
      state.on_tab_change(clicked_tab_id)
    end
  end

  if id_to_delete and #state.tabs > 1 then
    local is_active = (id_to_delete == state.active_tab_id)
    
    if state.tab_animator then
      state.tab_animator:destroy(id_to_delete)
      state.pending_delete_id = id_to_delete
      
      if is_active then
        for i, tab in ipairs(state.tabs) do
          if tab.id ~= id_to_delete then
            state.active_tab_id = tab.id
            if state.on_tab_change then
              state.on_tab_change(tab.id)
            end
            break
          end
        end
      end
    else
      if is_active then
        for i, tab in ipairs(state.tabs) do
          if tab.id ~= id_to_delete then
            state.active_tab_id = tab.id
            if state.on_tab_change then
              state.on_tab_change(tab.id)
            end
            break
          end
        end
      end
      
      if state.on_tab_delete then
        state.on_tab_delete(id_to_delete)
      end
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