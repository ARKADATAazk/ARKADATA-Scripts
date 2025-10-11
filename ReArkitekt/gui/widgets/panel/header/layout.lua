-- ReArkitekt/gui/widgets/panel/header/layout.lua
-- Layout engine for header elements

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local M = {}

local COMPONENTS = {
  tab_strip = require('ReArkitekt.gui.widgets.panel.header.tab_strip'),
  search_field = require('ReArkitekt.gui.widgets.panel.header.search_field'),
  dropdown_field = require('ReArkitekt.gui.widgets.panel.header.dropdown_field'),
  button = require('ReArkitekt.gui.widgets.panel.header.button'),
  separator = require('ReArkitekt.gui.widgets.panel.header.separator'),
}

-- ============================================================================
-- WIDTH CALCULATION
-- ============================================================================

local function calculate_element_width(ctx, element, state)
  local component = COMPONENTS[element.type]
  if not component then return 0 end
  
  if element.width then
    return element.width
  end
  
  if element.flex then
    return nil
  end
  
  if component.measure then
    return component.measure(ctx, element.config or {}, state)
  end
  
  return 0
end

local function layout_elements(ctx, elements, available_width, state)
  local layout = {}
  local fixed_total = 0
  local flex_total = 0
  local spacing = 0
  
  for i, element in ipairs(elements) do
    local width = calculate_element_width(ctx, element, state)
    
    if width then
      fixed_total = fixed_total + width
    else
      flex_total = flex_total + (element.flex or 1)
    end
    
    if i > 1 then
      spacing = spacing + (element.spacing_before or 0)
    end
    
    layout[i] = {
      element = element,
      fixed_width = width,
      flex = element.flex,
    }
  end
  
  local remaining = available_width - fixed_total - spacing
  local flex_unit = flex_total > 0 and (remaining / flex_total) or 0
  
  for i, item in ipairs(layout) do
    if not item.fixed_width then
      item.width = math.max(0, item.flex * flex_unit)
    else
      item.width = item.fixed_width
    end
  end
  
  return layout
end

-- ============================================================================
-- SEPARATOR ROUNDING
-- ============================================================================

local function find_separator_neighbors(elements, separator_index)
  local left_neighbor = nil
  local right_neighbor = nil
  
  for i = separator_index - 1, 1, -1 do
    if elements[i].element.type ~= 'separator' then
      left_neighbor = i
      break
    end
  end
  
  for i = separator_index + 1, #elements do
    if elements[i].element.type ~= 'separator' then
      right_neighbor = i
      break
    end
  end
  
  return left_neighbor, right_neighbor
end

-- ============================================================================
-- ELEMENT STATE MANAGEMENT
-- ============================================================================

local function get_or_create_element_state(state, element)
  if element.type == "tab_strip" then
    local element_state = state[element.id]
    if not element_state then
      element_state = {
        tabs = {},
        active_tab_id = nil,
        tab_positions = {},
        dragging_tab = nil,
        pending_delete_id = nil,
        _tabs_version = 0,
      }
      state[element.id] = element_state
    end
    
    -- Only update tabs if not currently dragging, or if tabs reference changed
    if not element_state.dragging_tab then
      if state.tabs and type(state.tabs) == "table" then
        -- Check if the tabs array reference changed
        if element_state.tabs ~= state.tabs then
          element_state.tabs = state.tabs
          element_state._tabs_version = (element_state._tabs_version or 0) + 1
        end
        element_state.active_tab_id = state.active_tab_id
      end
    end
    
    if state.tab_animator then
      element_state.tab_animator = state.tab_animator
    end
    
    element_state.id = element.id
    element_state._panel_id = state.id
    
    return element_state
  else
    local element_state = state[element.id]
    if not element_state then
      element_state = {}
      state[element.id] = element_state
    end
    element_state.id = element.id
    element_state._panel_id = state.id
    
    return element_state
  end
end

-- ============================================================================
-- MAIN DRAW FUNCTION
-- ============================================================================

function M.draw(ctx, dl, x, y, width, height, state, config)
  if not config or not config.elements or #config.elements == 0 then
    return 0
  end
  
  local padding = config.padding or {}
  local padding_left = padding.left or 8
  local padding_right = padding.right or 8
  local padding_top = padding.top or 4
  local padding_bottom = padding.bottom or 4
  
  local content_width = width - padding_left - padding_right
  local content_height = height - padding_top - padding_bottom
  local content_x = x + padding_left
  local content_y = y + padding_top
  
  local layout = layout_elements(ctx, config.elements, content_width, state)
  
  local separator_roundings = {}
  for i, item in ipairs(layout) do
    if item.element.type == 'separator' then
      local left_idx, right_idx = find_separator_neighbors(layout, i)
      if left_idx then
        separator_roundings[left_idx] = separator_roundings[left_idx] or {}
        separator_roundings[left_idx].round_right = true
      end
      if right_idx then
        separator_roundings[right_idx] = separator_roundings[right_idx] or {}
        separator_roundings[right_idx].round_left = true
      end
    end
  end
  
  local cursor_x = content_x
  
  for i, item in ipairs(layout) do
    local element = item.element
    local element_width = item.width
    local spacing_before = element.spacing_before or 0
    
    cursor_x = cursor_x + spacing_before
    
    local component = COMPONENTS[element.type]
    if component and component.draw then
      local element_config = element.config or {}
      
      if separator_roundings[i] then
        element_config = element_config or {}
        element_config.corner_rounding = separator_roundings[i]
      end
      
      local element_state = get_or_create_element_state(state, element)
      
      local used_width = component.draw(
        ctx, dl,
        cursor_x, content_y,
        element_width, content_height,
        element_config,
        element_state
      )
      
      cursor_x = cursor_x + (used_width or element_width)
    else
      cursor_x = cursor_x + element_width
    end
  end
  
  return height
end

return M