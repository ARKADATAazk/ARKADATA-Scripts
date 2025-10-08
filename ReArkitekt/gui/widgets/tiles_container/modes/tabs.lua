-- ReArkitekt/gui/widgets/tiles_container/modes/tabs.lua
-- Tab mode with smooth drag reordering and custom colors

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'
local ContextMenu = require('ReArkitekt.gui.widgets.controls.context_menu')
local Easing = require('ReArkitekt.gui.fx.easing')

local M = {}

local TAB_SLIDE_SPEED = 15.0 -- Higher = faster animation
local DRAG_THRESHOLD = 3.0 -- Pixels before drag starts

-- Random color palette (similar to region tiles)
local COLOR_PALETTE = {
  0x42E896FF,  -- Green
  0xE84C3DFF,  -- Red
  0x3D9EE8FF,  -- Blue
  0xE89C42FF,  -- Orange
  0xA742E8FF,  -- Purple
  0xE842A7FF,  -- Pink
  0x42E8D4FF,  -- Cyan
  0xE8D442FF,  -- Yellow
  0x8E42E8FF,  -- Violet
  0xE86542FF,  -- Coral
}

local function generate_random_color()
  -- 40% chance to be grey (nil), 60% chance to get a random color
  if math.random() < 0.4 then
    return nil
  end
  return COLOR_PALETTE[math.random(#COLOR_PALETTE)]
end

-- Call this when creating new tabs to assign random colors
function M.assign_random_color(tab_data)
  if not tab_data.color then
    tab_data.color = generate_random_color()
  end
  return tab_data
end

local function desaturate(color, factor)
  local r = (color >> 24) & 0xFF
  local g = (color >> 16) & 0xFF
  local b = (color >> 8) & 0xFF
  local a = color & 0xFF
  
  local gray = r * 0.299 + g * 0.587 + b * 0.114
  
  r = math.floor(r + (gray - r) * factor)
  g = math.floor(g + (gray - g) * factor)
  b = math.floor(b + (gray - b) * factor)
  
  return (r << 24) | (g << 16) | (b << 8) | a
end

local function adjust_brightness(color, factor)
  local r = (color >> 24) & 0xFF
  local g = (color >> 16) & 0xFF
  local b = (color >> 8) & 0xFF
  local a = color & 0xFF
  
  r = math.floor(math.min(255, r * factor))
  g = math.floor(math.min(255, g * factor))
  b = math.floor(math.min(255, b * factor))
  
  return (r << 24) | (g << 16) | (b << 8) | a
end

local function with_alpha(color, alpha)
  return (color & 0xFFFFFF00) | (alpha & 0xFF)
end

local function same_hue_variant(base_color, saturation, brightness, alpha)
  local r = (base_color >> 24) & 0xFF
  local g = (base_color >> 16) & 0xFF
  local b = (base_color >> 8) & 0xFF
  
  local max_c = math.max(r, g, b)
  local min_c = math.min(r, g, b)
  local delta = max_c - min_c
  
  local h = 0
  if delta > 0 then
    if max_c == r then
      h = ((g - b) / delta) % 6
    elseif max_c == g then
      h = ((b - r) / delta) + 2
    else
      h = ((r - g) / delta) + 4
    end
    h = h * 60
  end
  
  local s = saturation
  local v = brightness
  
  local c = v * s
  local x = c * (1 - math.abs((h / 60) % 2 - 1))
  local m = v - c
  
  local r1, g1, b1
  if h < 60 then
    r1, g1, b1 = c, x, 0
  elseif h < 120 then
    r1, g1, b1 = x, c, 0
  elseif h < 180 then
    r1, g1, b1 = 0, c, x
  elseif h < 240 then
    r1, g1, b1 = 0, x, c
  elseif h < 300 then
    r1, g1, b1 = x, 0, c
  else
    r1, g1, b1 = c, 0, x
  end
  
  r = math.floor((r1 + m) * 255)
  g = math.floor((g1 + m) * 255)
  b = math.floor((b1 + m) * 255)
  
  return (r << 24) | (g << 16) | (b << 8) | alpha
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

local function calculate_tab_width(ctx, label, tab_cfg)
  local text_w = ImGui.CalcTextSize(ctx, label)
  return math.min(tab_cfg.max_width, math.max(tab_cfg.min_width, text_w + tab_cfg.padding_x * 2))
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
  
  -- Calculate target positions
  for i, tab in ipairs(state.tabs) do
    local tab_width = calculate_tab_width(ctx, tab.label or "Tab", tab_cfg)
    local pos = state.tab_positions[tab.id]
    
    if not pos then
      pos = { current_x = cursor_x, target_x = cursor_x }
      state.tab_positions[tab.id] = pos
    end
    
    pos.target_x = cursor_x
    
    -- Smooth interpolation
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
  
  local animator = state.tab_animator
  local is_spawning = animator and animator:is_spawning(id)
  local is_destroying = animator and animator:is_destroying(id)

  local w = calculate_tab_width(ctx, label, tab_cfg)
  local h = cfg.element_height or 20
  
  local pos = state.tab_positions[id]
  if not pos then
    pos = { current_x = 0, target_x = 0 }
    state.tab_positions[id] = pos
  end
  
  local x = pos.current_x
  
  -- If dragging this tab, use mouse position
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
  
  -- Use custom color system if tab has a color
  if tab_cfg.use_custom_colors and tab_data.color then
    local base_color = tab_data.color
    
    -- Derive fill color from base (like tiles)
    bg_color = desaturate(base_color, tab_cfg.fill_desaturation or 0.4)
    bg_color = adjust_brightness(bg_color, tab_cfg.fill_brightness or 0.50)
    bg_color = with_alpha(bg_color, tab_cfg.fill_alpha or 0xDD)
    
    -- Derive border color
    border_color = same_hue_variant(base_color, 
      tab_cfg.border_saturation or 0.7, 
      tab_cfg.border_brightness or 0.75, 
      tab_cfg.border_alpha or 0xFF)
    
    -- Derive text color (index style from tiles)
    text_color = same_hue_variant(base_color,
      tab_cfg.text_index_saturation or 0.85,
      tab_cfg.text_index_brightness or 0.95,
      0xFF)
    
    -- Brighten on hover
    if is_hovered or is_active then
      bg_color = adjust_brightness(bg_color, 1.15)
    end
    
    -- Brighten more when active
    if is_active then
      bg_color = adjust_brightness(bg_color, 1.10)
      text_color = 0xFFFFFFFF
    end
  else
    -- Use default grey colors
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

  local text_w, text_h = ImGui.CalcTextSize(ctx, label)
  local text_x = render_x + (render_w - text_w) * 0.5
  local text_y = render_y + (render_h - text_h) * 0.5

  local text_max_w = render_w - 8
  if text_w > text_max_w then
    ImGui.DrawList_PushClipRect(dl, render_x + 4, render_y, 
                                render_x + render_w - 4, render_y + render_h, true)
    ImGui.DrawList_AddText(dl, text_x, text_y, text_color, label)
    ImGui.DrawList_PopClipRect(dl)
  else
    ImGui.DrawList_AddText(dl, text_x, text_y, text_color, label)
  end

  ImGui.SetCursorScreenPos(ctx, render_x, render_y)
  ImGui.InvisibleButton(ctx, "##tab_" .. id .. "_" .. state.id, render_w, render_h)

  local clicked = ImGui.IsItemClicked(ctx, 0)
  local right_clicked = ImGui.IsItemClicked(ctx, 1)

  -- Start dragging only after threshold
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

  local plus_clicked, new_x = draw_plus_button(ctx, dl, cursor_x, cursor_y, state, cfg)
  local tabs_start_x = new_x + tabs_cfg.tab.spacing

  if plus_clicked and state.on_tab_create then
    state.on_tab_create()
  end

  -- Handle dragging reorder
  if state.dragging_tab and ImGui.IsMouseDragging(ctx, 0) then
    local mx = ImGui.GetMousePos(ctx)
    local dragged_tab = state.tabs[state.dragging_tab.index]
    local dragged_width = calculate_tab_width(ctx, dragged_tab.label or "Tab", tabs_cfg.tab)
    
    -- Calculate center of dragged tab based on mouse position and grab offset
    local drag_center_x = mx - state.dragging_tab.offset_x + dragged_width * 0.5
    
    -- Build list of tab positions excluding dragged tab
    local positions = {}
    local current_x = tabs_start_x
    
    for i = 1, #state.tabs do
      if i ~= state.dragging_tab.index then
        local tab = state.tabs[i]
        local tab_w = calculate_tab_width(ctx, tab.label or "Tab", tabs_cfg.tab)
        
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
    
    -- Find insertion point based on drag center
    local target_index = 1
    
    for i, pos in ipairs(positions) do
      if drag_center_x > pos.center then
        -- Drag center is past this tab's center, so we'd go after it
        target_index = pos.index + 1
      else
        -- Drag center is before this tab's center
        break
      end
    end
    
    -- Adjust for array removal
    if target_index > state.dragging_tab.index then
      target_index = target_index - 1
    end
    
    -- Clamp
    target_index = math.max(1, math.min(#state.tabs, target_index))
    
    -- Reorder immediately if position changed
    if target_index ~= state.dragging_tab.index then
      local dragged_tab_data = table.remove(state.tabs, state.dragging_tab.index)
      table.insert(state.tabs, target_index, dragged_tab_data)
      state.dragging_tab.index = target_index
    end
  end

  -- End dragging
  if state.dragging_tab and not ImGui.IsMouseDown(ctx, 0) then
    if state.on_tab_reorder and state.dragging_tab.original_index ~= state.dragging_tab.index then
      state.on_tab_reorder(state.dragging_tab.original_index, state.dragging_tab.index)
    end
    state.dragging_tab = nil
  end

  -- Update positions with smooth animation
  update_tab_positions(ctx, state, cfg, tabs_start_x)

  local available_width = width - (cursor_x - x) - tabs_cfg.reserved_right_space
  
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

--[[
  TAB COLORS:
  
  Colors are automatically randomized when tabs are created via set_tabs() or add_tab().
  - 40% chance to be grey (no color)
  - 60% chance to get a random color from the palette
  
  To override the automatic color:
  
  container:add_tab({ id = "my_tab", label = "My Tab", color = 0x42E896FF })  -- Force green
  container:add_tab({ id = "grey_tab", label = "Grey", color = nil })         -- Force grey
  
  To change a tab's color later:
  
  for _, tab in ipairs(container.tabs) do
    if tab.id == "playlist1" then
      tab.color = 0xE84C3DFF  -- Change to red
      break
    end
  end
  
  Available colors in palette:
  0x42E896FF (Green), 0xE84C3DFF (Red), 0x3D9EE8FF (Blue), 0xE89C42FF (Orange),
  0xA742E8FF (Purple), 0xE842A7FF (Pink), 0x42E8D4FF (Cyan), 0xE8D442FF (Yellow),
  0x8E42E8FF (Violet), 0xE86542FF (Coral)
]]

return M