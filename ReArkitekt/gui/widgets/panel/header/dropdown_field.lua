-- ReArkitekt/gui/widgets/panel/header/dropdown_field.lua
-- Dropdown wrapper for header layout

local Dropdown = require('ReArkitekt.gui.widgets.controls.dropdown')

local M = {}

function M.draw(ctx, dl, x, y, width, height, config, state)
  local element_id = state.id or "dropdown"
  
  -- Create a unique ID for this specific dropdown instance
  -- This prevents conflicts when multiple panels have dropdowns with the same element ID
  local dropdown_id = string.format("%s_%s", tostring(state._panel_id or "unknown"), element_id)
  
  -- Create dropdown instance if it doesn't exist
  if not state.dropdown_instance then
    state.dropdown_instance = Dropdown.new({
      id = dropdown_id,
      tooltip = config.tooltip,
      tooltip_delay = config.tooltip_delay,
      options = config.options or {},
      current_value = state.dropdown_value or (config.options and config.options[1] and config.options[1].value),
      sort_direction = state.dropdown_direction or "asc",
      on_change = function(value)
        state.dropdown_value = value
        if config.on_change then
          config.on_change(value)
        end
      end,
      on_direction_change = function(direction)
        state.dropdown_direction = direction
        if config.on_direction_change then
          config.on_direction_change(direction)
        end
      end,
      config = {
        width = width,
        height = height,
        tooltip_delay = config.tooltip_delay,
        bg_color = config.bg_color or 0x252525FF,
        bg_hover_color = config.bg_hover_color or 0x303030FF,
        bg_active_color = config.bg_active_color or 0x3A3A3AFF,
        text_color = config.text_color or 0xCCCCCCFF,
        text_hover_color = config.text_hover_color or 0xFFFFFFFF,
        border_color = config.border_color or 0x353535FF,
        border_hover_color = config.border_hover_color or 0x454545FF,
        rounding = config.rounding or 4,
        padding_x = config.padding_x or 10,
        padding_y = config.padding_y or 6,
        arrow_size = config.arrow_size or 6,
        arrow_color = config.arrow_color or 0xCCCCCCFF,
        arrow_hover_color = config.arrow_hover_color or 0xFFFFFFFF,
        enable_mousewheel = config.enable_mousewheel ~= false,
        popup = config.popup or {},
      },
    })
  else
    -- Update value if changed externally
    if state.dropdown_value and state.dropdown_instance.current_value ~= state.dropdown_value then
      state.dropdown_instance:set_value(state.dropdown_value)
    end
    
    -- Update direction if changed externally
    if state.dropdown_direction and state.dropdown_instance.sort_direction ~= state.dropdown_direction then
      state.dropdown_instance:set_direction(state.dropdown_direction)
    end
  end
  
  state.dropdown_instance:draw(ctx, x, y)
  
  return width
end

function M.measure(ctx, config)
  return config.width or 120
end

return M