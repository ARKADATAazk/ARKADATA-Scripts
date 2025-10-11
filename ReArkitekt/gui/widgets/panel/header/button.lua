-- ReArkitekt/gui/widgets/panel/header/button.lua
-- Generic button component for headers

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local M = {}

function M.draw(ctx, dl, x, y, width, height, config, state)
  local element_id = config.id or "button"
  local label = config.label or ""
  local icon = config.icon or ""
  
  -- Create unique ID by combining panel ID + element ID
  local unique_id = string.format("%s_%s", tostring(state._panel_id or "unknown"), element_id)
  
  -- Hover detection
  local is_hovered = ImGui.IsMouseHoveringRect(ctx, x, y, x + width, y + height)
  local is_active = ImGui.IsMouseDown(ctx, 0) and is_hovered
  
  -- Colors
  local bg_color = config.bg_color or 0x2A2A2AFF
  if is_active then
    bg_color = config.bg_active_color or 0x1A1A1AFF
  elseif is_hovered then
    bg_color = config.bg_hover_color or 0x3A3A3AFF
  end
  
  local border_color = config.border_color or 0x404040FF
  if is_hovered then
    border_color = config.border_hover_color or border_color
  end
  
  local text_color = config.text_color or 0xAAAAAAFF
  if is_hovered then
    text_color = config.text_hover_color or 0xFFFFFFFF
  end
  
  local rounding = config.rounding or 4
  
  -- Draw background
  ImGui.DrawList_AddRectFilled(dl, x, y, x + width, y + height, bg_color, rounding)
  
  -- Draw border
  if config.border_thickness and config.border_thickness > 0 then
    ImGui.DrawList_AddRect(dl, x, y, x + width, y + height, border_color, rounding, 0, config.border_thickness)
  end
  
  -- Draw content
  local display_text = icon .. (icon ~= "" and label ~= "" and " " or "") .. label
  
  if config.custom_draw then
    -- Allow custom drawing (e.g., for + icon)
    config.custom_draw(ctx, dl, x, y, width, height, is_hovered, is_active, text_color)
  elseif display_text ~= "" then
    local text_w = ImGui.CalcTextSize(ctx, display_text)
    local text_x = x + (width - text_w) * 0.5
    local text_y = y + (height - ImGui.GetTextLineHeight(ctx)) * 0.5
    ImGui.DrawList_AddText(dl, text_x, text_y, text_color, display_text)
  end
  
  -- Invisible button for interaction
  ImGui.SetCursorScreenPos(ctx, x, y)
  ImGui.InvisibleButton(ctx, "##" .. unique_id, width, height)
  
  local clicked = ImGui.IsItemClicked(ctx, 0)
  
  -- Call callback if provided
  if clicked and config.on_click then
    config.on_click()
  end
  
  -- Tooltip
  if is_hovered and config.tooltip then
    ImGui.SetTooltip(ctx, config.tooltip)
  end
  
  return width, clicked
end

function M.measure(ctx, config)
  local label = config.label or ""
  local icon = config.icon or ""
  local display_text = icon .. (icon ~= "" and label ~= "" and " " or "") .. label
  
  if config.width then
    return config.width
  end
  
  local text_w = ImGui.CalcTextSize(ctx, display_text)
  local padding = config.padding_x or 10
  return text_w + padding * 2
end

return M