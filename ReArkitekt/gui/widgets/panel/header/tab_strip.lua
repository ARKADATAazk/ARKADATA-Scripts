-- ReArkitekt/gui/widgets/panel/header/tab_strip.lua
-- Tab strip component with drag & drop, animations, overflow

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

local function draw_plus_button(ctx, dl, x, y, width, height, config, state, unique_id)
  local btn_cfg = config.plus_button or {}
  
  local is_hovered = ImGui.IsMouseHoveringRect(ctx, x, y, x + width, y + height)
  local is_active = ImGui.IsMouseDown(ctx, 0) and is_hovered

  local bg_color = btn_cfg.bg_color or 0x2A2A2AFF
  if is_active then
    bg_color = btn_cfg.bg_active_color or 0x1A1A1AFF
  elseif is_hovered then
    bg_color = btn_cfg.bg_hover_color or 0x3A3A3AFF
  end

  local border_color = is_hovered and (btn_cfg.border_hover_color or 0x42E896FF) or (btn_cfg.border_color or 0x404040FF)
  local icon_color = is_hovered and (btn_cfg.text_hover_color or 0xFFFFFFFF) or (btn_cfg.text_color or 0xAAAAAAFF)

  local rounding = btn_cfg.rounding or 4
  local corner_flags = ImGui.DrawFlags_RoundCornersTopLeft | ImGui.DrawFlags_RoundCornersBottomLeft
  
  ImGui.DrawList_AddRectFilled(dl, x, y, x + width, y + height, bg_color, rounding, corner_flags)
  ImGui.DrawList_AddRect(dl, x, y, x + width, y + height, border_color, rounding, corner_flags, 1)

  local center_x = x + width * 0.5 
  local center_y = y + height * 0.5 - 1
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
  local clicked = ImGui.InvisibleButton(ctx, "##plus_" .. unique_id, width, height)

  return clicked, width
end

local function draw_overflow_button(ctx, dl, x, y, width, height, config, state, hidden_count, unique_id)
  local btn_cfg = config.overflow_button or {
    min_width = 21,
    padding_x = 8,
    bg_color = 0x1C1C1CFF,
    bg_hover_color = 0x282828FF,
    bg_active_color = 0x252525FF,
    text_color = 0x707070FF,
    text_hover_color = 0xCCCCCCFF,
    border_color = 0x303030FF,
    border_hover_color = 0x404040FF,
    rounding = 4,
  }
  
  local count_text = tostring(hidden_count)
  
  local is_hovered = ImGui.IsMouseHoveringRect(ctx, x, y, x + width, y + height)
  local is_active = ImGui.IsMouseDown(ctx, 0) and is_hovered

  local bg_color = btn_cfg.bg_color
  if is_active then
    bg_color = btn_cfg.bg_active_color
  elseif is_hovered then
    bg_color = btn_cfg.bg_hover_color
  end

  local border_color = is_hovered and btn_cfg.border_hover_color or btn_cfg.border_color
  local text_color = is_hovered and btn_cfg.text_hover_color or btn_cfg.text_color

  local corner_flags = ImGui.DrawFlags_RoundCornersTopRight | ImGui.DrawFlags_RoundCornersBottomRight
  local rounding = btn_cfg.rounding
  
  ImGui.DrawList_AddRectFilled(dl, x, y, x + width, y + height, bg_color, rounding, corner_flags)
  ImGui.DrawList_AddRect(dl, x, y, x + width, y + height, border_color, rounding, corner_flags, 1)

  local text_w = ImGui.CalcTextSize(ctx, count_text)
  local text_x = x + (width - text_w) * 0.5
  local text_y = y + (height - ImGui.GetTextLineHeight(ctx)) * 0.5
  ImGui.DrawList_AddText(dl, text_x, text_y, text_color, count_text)

  ImGui.SetCursorScreenPos(ctx, x, y)
  local clicked = ImGui.InvisibleButton(ctx, "##overflow_" .. unique_id, width, height)

  return clicked
end

local function draw_track(ctx, dl, x, y, width, height, config)
  local track_cfg = config.track
  if not track_cfg or not track_cfg.enabled then return end
  
  local track_x = x - track_cfg.extend_left
  local track_y = y - track_cfg.extend_top
  local track_width = width + track_cfg.extend_left + track_cfg.extend_right
  local track_height = height + track_cfg.extend_top + track_cfg.extend_bottom
  
  ImGui.DrawList_AddRectFilled(
    dl,
    track_x, track_y,
    track_x + track_width, track_y + track_height,
    track_cfg.bg_color or 0x1A1A1AFF,
    track_cfg.rounding or 6
  )
  
  if track_cfg.border_thickness and track_cfg.border_thickness > 0 then
    ImGui.DrawList_AddRect(
      dl,
      track_x, track_y,
      track_x + track_width, track_y + track_height,
      track_cfg.border_color or 0x0A0A0AFF,
      track_cfg.rounding or 6,
      0,
      track_cfg.border_thickness
    )
  end
end

local function calculate_tab_width(ctx, label, config, has_chip)
  local text_w = ImGui.CalcTextSize(ctx, label)
  local chip_width = has_chip and 20 or 0
  local min_width = config.min_width or 60
  local max_width = config.max_width or 180
  local padding_x = config.padding_x or 5
  
  return math.min(max_width, math.max(min_width, text_w + padding_x * 2 + chip_width))
end

local function init_tab_positions(state)
  if not state.tab_positions then
    state.tab_positions = {}
  end
  
  for _, tab in ipairs(state.tabs or {}) do
    if not state.tab_positions[tab.id] then
      state.tab_positions[tab.id] = {
        current_x = 0,
        target_x = 0,
      }
    end
  end
end

local function update_tab_positions(ctx, state, config, start_x)
  local spacing = config.spacing or 6
  local dt = ImGui.GetDeltaTime(ctx)
  local cursor_x = start_x
  
  for i, tab in ipairs(state.tabs or {}) do
    local has_chip = tab.chip_color ~= nil
    local tab_width = calculate_tab_width(ctx, tab.label or "Tab", config, has_chip)
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

local function draw_tab(ctx, dl, tab_data, is_active, tab_index, x, y, width, height, state, config, unique_id)
  local label = tab_data.label or "Tab"
  local id = tab_data.id
  local chip_color = tab_data.chip_color
  local has_chip = chip_color ~= nil
  
  local animator = state.tab_animator
  local is_spawning = animator and animator:is_spawning(id)
  local is_destroying = animator and animator:is_destroying(id)
  
  local render_x, render_y, render_w, render_h = x, y, width, height
  local alpha_factor = 1.0
  
  if is_spawning and animator.get_spawn_factor then
    local spawn_factor = animator:get_spawn_factor(id)
    local target_w = width * spawn_factor
    local offset_x = (width - target_w) * 0.5
    render_x = x + offset_x
    render_w = target_w
    alpha_factor = spawn_factor
  elseif is_destroying and animator.get_destroy_factor then
    local destroy_factor = animator:get_destroy_factor(id)
    local scale = 1.0 - destroy_factor
    local new_w = width * scale
    local new_h = height * scale
    local offset_x = (width - new_w) * 0.5
    local offset_y = (height - new_h) * 0.5
    render_x = x + offset_x
    render_y = y + offset_y
    render_w = new_w
    render_h = new_h
    alpha_factor = 1.0 - destroy_factor
  end

  local is_hovered = ImGui.IsMouseHoveringRect(ctx, render_x, render_y, render_x + render_w, render_y + render_h)
  local is_pressed = ImGui.IsMouseDown(ctx, 0) and is_hovered and not state.dragging_tab

  local apply_alpha = function(color, factor)
    local a = color & 0xFF
    local new_a = math.floor(a * factor)
    return (color & 0xFFFFFF00) | new_a
  end

  local bg_color = config.bg_color or 0x2A2A2AFF
  local border_color = config.border_color or 0x404040FF
  local text_color = config.text_color or 0xAAAAAAFF
  
  if is_active then
    bg_color = config.bg_active_color or 0x42E89644
    border_color = config.border_active_color or 0x42E896FF
    text_color = config.text_active_color or 0xFFFFFFFF
  elseif is_pressed then
    bg_color = config.bg_hover_color or 0x3A3A3AFF
    text_color = config.text_hover_color or 0xFFFFFFFF
  elseif is_hovered then
    bg_color = config.bg_hover_color or 0x3A3A3AFF
    text_color = config.text_hover_color or 0xFFFFFFFF
  end
  
  bg_color = apply_alpha(bg_color, alpha_factor)
  border_color = apply_alpha(border_color, alpha_factor)
  text_color = apply_alpha(text_color, alpha_factor)

  local rounding = config.rounding or 4
  local corner_flags = ImGui.DrawFlags_RoundCornersTop

  ImGui.DrawList_AddRectFilled(dl, render_x, render_y, render_x + render_w, render_y + render_h, 
                                bg_color, rounding, corner_flags)
  ImGui.DrawList_AddRect(dl, render_x, render_y, render_x + render_w, render_y + render_h, 
                         border_color, rounding, corner_flags, 1)

  local content_x = render_x + (config.padding_x or 5)
  
  if has_chip then
    local chip_x = content_x + 2
    local chip_y = render_y + render_h * 0.5
    
    Chip.draw(ctx, {
      style = Chip.STYLE.INDICATOR,
      color = chip_color,
      draw_list = dl,
      x = chip_x,
      y = chip_y,
      radius = config.chip_radius or 4,
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

  local text_max_w = render_x + render_w - text_x - (config.padding_x or 5)
  if text_w > text_max_w then
    ImGui.DrawList_PushClipRect(dl, text_x, render_y, 
                                render_x + render_w - (config.padding_x or 5), render_y + render_h, true)
    ImGui.DrawList_AddText(dl, text_x, text_y, text_color, label)
    ImGui.DrawList_PopClipRect(dl)
  else
    ImGui.DrawList_AddText(dl, text_x, text_y, text_color, label)
  end

  ImGui.SetCursorScreenPos(ctx, render_x, render_y)
  ImGui.InvisibleButton(ctx, "##tab_" .. id .. "_" .. unique_id, render_w, render_h)

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
    ImGui.OpenPopup(ctx, "##tab_context_" .. id .. "_" .. unique_id)
  end

  if ContextMenu.begin(ctx, "##tab_context_" .. id .. "_" .. unique_id, config.context_menu) then
    if ContextMenu.item(ctx, "Delete Playlist", config.context_menu) then
      delete_requested = true
    end
    ContextMenu.end_menu(ctx)
  end

  return clicked, delete_requested
end

function M.draw(ctx, dl, x, y, available_width, height, config, state)
  config = config or {}
  state = state or {}
  
  local element_id = state.id or "tabstrip"
  
  -- Create unique ID by combining panel ID + element ID
  local unique_id = string.format("%s_%s", tostring(state._panel_id or "unknown"), element_id)
  
  state.tabs = state.tabs or {}
  state.active_tab_id = state.active_tab_id
  
  if state.tab_animator then
    state.tab_animator:update()
  end

  init_tab_positions(state)

  local plus_cfg = config.plus_button or {}
  local plus_width = plus_cfg.width or 23
  local spacing = config.spacing or 6

  reaper.ShowConsoleMsg(string.format(
  "[TabStrip Debug]\n" ..
  "  unique_id: %s\n" ..
  "  state.tabs count: %d\n" ..
  "  state.active_tab_id: %s\n" ..
  "  state.id: %s\n" ..
  "  state._panel_id: %s\n" ..
  "  available_width: %.1f\n" ..
  "  plus_width: %d\n" ..
  "  spacing: %d\n",
  unique_id,
  state.tabs and #state.tabs or 0,
  tostring(state.active_tab_id or "nil"),
  tostring(state.id or "nil"),
  tostring(state._panel_id or "nil"),
  available_width,
  plus_width,
  spacing
))

if state.tabs then
  reaper.ShowConsoleMsg(string.format("  Tabs array:\n"))
  for i, tab in ipairs(state.tabs) do
    reaper.ShowConsoleMsg(string.format(
      "    [%d] id=%s, label=%s\n",
      i,
      tostring(tab.id or "nil"),
      tostring(tab.label or "nil")
    ))
  end
else
  reaper.ShowConsoleMsg("  state.tabs is nil!\n")
end

reaper.ShowConsoleMsg("\n")
  
  -- FIRST PASS: Calculate which tabs fit WITHOUT overflow button
  local tabs_available_width_no_overflow = available_width - plus_width - spacing
  
  local visible_indices = {}
  local current_width = 0
  
  for i, tab in ipairs(state.tabs) do
    local has_chip = tab.chip_color ~= nil
    local tab_width = calculate_tab_width(ctx, tab.label or "Tab", config, has_chip)
    local needed = tab_width + (i > 1 and spacing or 0)
    
    if current_width + needed <= tabs_available_width_no_overflow then
      visible_indices[#visible_indices + 1] = i
      current_width = current_width + needed
    else
      break  -- Stop once we can't fit more
    end
  end
  
  -- Calculate overflow count
  local overflow_count = #state.tabs - #visible_indices

  reaper.ShowConsoleMsg(string.format(
  "[First Pass - No Overflow]\n" ..
  "  tabs_available_width_no_overflow: %.1f\n" ..
  "  visible_indices count: %d\n",
  tabs_available_width_no_overflow,
  #visible_indices
))

for i, idx in ipairs(visible_indices) do
  local tab = state.tabs[idx]
  local has_chip = tab.chip_color ~= nil
  local tab_width = calculate_tab_width(ctx, tab.label or "Tab", config, has_chip)
  reaper.ShowConsoleMsg(string.format(
    "  Visible[%d]: idx=%d, label=%s, width=%.1f, chip=%s\n",
    i, idx,
    tostring(tab.label),
    tab_width,
    has_chip and "yes" or "no"
  ))
end

reaper.ShowConsoleMsg(string.format(
  "  current_width used: %.1f\n" ..
  "  overflow_count: %d\n\n",
  current_width,
  overflow_count
))
  
  -- SECOND PASS: If there's overflow, recalculate with overflow button space reserved
  local overflow_width = 0
  if overflow_count > 0 then
    local overflow_cfg = config.overflow_button or { min_width = 21, padding_x = 8 }
    local count_text = tostring(overflow_count)  -- Use HIDDEN count, not total!
    local text_w = ImGui.CalcTextSize(ctx, count_text)
    overflow_width = math.max(overflow_cfg.min_width or 21, text_w + (overflow_cfg.padding_x or 8) * 2)
    
    -- Recalculate visible tabs with overflow button space reserved
    local tabs_available_width_with_overflow = available_width - plus_width - spacing - overflow_width - spacing
    
    visible_indices = {}
    current_width = 0
    
    for i, tab in ipairs(state.tabs) do
      local has_chip = tab.chip_color ~= nil
      local tab_width = calculate_tab_width(ctx, tab.label or "Tab", config, has_chip)
      local needed = tab_width + (i > 1 and spacing or 0)
      
      if current_width + needed <= tabs_available_width_with_overflow then
        visible_indices[#visible_indices + 1] = i
        current_width = current_width + needed
      else
        break
      end
    end
    
    -- Recalculate overflow count after adjustment
    overflow_count = #state.tabs - #visible_indices
  end
  
  local tabs_start_x = x + plus_width + spacing
  
  local tabs_total_width = current_width
  if overflow_count > 0 then
    tabs_total_width = tabs_total_width + spacing + overflow_width
  end
  
  if config.track and config.track.enabled then
    local track_start_x = x
    if not config.track.include_plus_button then
      track_start_x = tabs_start_x
    end
    
    draw_track(ctx, dl, track_start_x, y, 
               tabs_start_x - track_start_x + tabs_total_width, 
               height, config)
  end

  local plus_clicked, _ = draw_plus_button(ctx, dl, x, y, plus_width, height, config, state, unique_id)
  
  if plus_clicked and config.on_tab_create then
    config.on_tab_create()
  end

  if state.dragging_tab and ImGui.IsMouseDragging(ctx, 0) then
    local mx = ImGui.GetMousePos(ctx)
    local dragged_tab = state.tabs[state.dragging_tab.index]
    local has_chip = dragged_tab.chip_color ~= nil
    local dragged_width = calculate_tab_width(ctx, dragged_tab.label or "Tab", config, has_chip)
    
    local drag_center_x = mx - state.dragging_tab.offset_x + dragged_width * 0.5
    
    local positions = {}
    local current_x = tabs_start_x
    
    for i = 1, #state.tabs do
      if i ~= state.dragging_tab.index then
        local tab = state.tabs[i]
        local tab_has_chip = tab.chip_color ~= nil
        local tab_w = calculate_tab_width(ctx, tab.label or "Tab", config, tab_has_chip)
        
        table.insert(positions, {
          index = i,
          center = current_x + tab_w * 0.5,
        })
        
        current_x = current_x + tab_w + spacing
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
    if config.on_tab_reorder and state.dragging_tab.original_index ~= state.dragging_tab.index then
      config.on_tab_reorder(state.dragging_tab.original_index, state.dragging_tab.index)
    end
    state.dragging_tab = nil
  end

  update_tab_positions(ctx, state, config, tabs_start_x)
  
  local id_to_delete = nil
  local clicked_tab_id = nil

  for i, tab_data in ipairs(state.tabs) do
    local is_visible = false
    for _, vis_idx in ipairs(visible_indices) do
      if vis_idx == i then
        is_visible = true
        break
      end
    end
    
    if is_visible then
      local pos = state.tab_positions[tab_data.id]
      if pos then
        local has_chip = tab_data.chip_color ~= nil
        local tab_w = calculate_tab_width(ctx, tab_data.label or "Tab", config, has_chip)
        local tab_x = pos.current_x
        
        if state.dragging_tab and state.dragging_tab.id == tab_data.id then
          local mx = ImGui.GetMousePos(ctx)
          tab_x = mx - state.dragging_tab.offset_x
        end
        
        local is_active = (tab_data.id == state.active_tab_id)
        local clicked, delete_requested = draw_tab(ctx, dl, tab_data, is_active, 
                                                   i, tab_x, y, tab_w, height, state, config, unique_id)

        if clicked and not (state.dragging_tab or ImGui.IsMouseDragging(ctx, 0)) then
          clicked_tab_id = tab_data.id
        end

        if delete_requested then
          id_to_delete = tab_data.id
        end
      end
    end
  end
  
  if overflow_count > 0 then
    local overflow_x = tabs_start_x + current_width + spacing
    local overflow_clicked = draw_overflow_button(ctx, dl, overflow_x, y, overflow_width, height, 
                                                   config, state, overflow_count, unique_id)
    
    if overflow_clicked and config.on_overflow_clicked then
      config.on_overflow_clicked()
    end
  end

  if clicked_tab_id then
    state.active_tab_id = clicked_tab_id
    if config.on_tab_change then
      config.on_tab_change(clicked_tab_id)
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
            if config.on_tab_change then
              config.on_tab_change(tab.id)
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
            if config.on_tab_change then
              config.on_tab_change(tab.id)
            end
            break
          end
        end
      end
      
      if config.on_tab_delete then
        config.on_tab_delete(id_to_delete)
      end
    end
  end

  if state.pending_delete_id and state.tab_animator then
    if not state.tab_animator:is_destroying(state.pending_delete_id) then
      if config.on_tab_delete then
        config.on_tab_delete(state.pending_delete_id)
      end
      state.pending_delete_id = nil
    end
  end

  return plus_width + spacing + tabs_total_width
end

function M.measure(ctx, config, state)
  state = state or {}
  config = config or {}
  
  local plus_width = (config.plus_button and config.plus_button.width) or 23
  local spacing = config.spacing or 6
  
  if not state.tabs or #state.tabs == 0 then
    return plus_width
  end
  
  local total = plus_width + spacing
  
  for i, tab in ipairs(state.tabs) do
    local has_chip = tab.chip_color ~= nil
    local tab_w = calculate_tab_width(ctx, tab.label or "Tab", config, has_chip)
    total = total + tab_w
    if i < #state.tabs then
      total = total + spacing
    end
  end
  
  return total
end

return M