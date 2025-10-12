-- ReArkitekt/gui/widgets/panel/header/button.lua
-- Generic button component for headers with integrated design

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local M = {}

local function get_corner_flags(corner_rounding)
  if not corner_rounding then
    return 0
  end
  
  local flags = 0
  if corner_rounding.round_top_left then
    flags = flags | ImGui.DrawFlags_RoundCornersTopLeft
  end
  if corner_rounding.round_top_right then
    flags = flags | ImGui.DrawFlags_RoundCornersTopRight
  end
  
  return flags
end

function M.draw(ctx, dl, x, y, width, height, config, state)
  local element_id = config.id or "button"
  local label = config.label or ""
  local icon = config.icon or ""
  
  local unique_id = string.format("%s_%s", tostring(state._panel_id or "unknown"), element_id)
  
  local is_hovered = ImGui.IsMouseHoveringRect(ctx, x, y, x + width, y + height)
  local is_active = ImGui.IsMouseDown(ctx, 0) and is_hovered
  
  local bg_color = config.bg_color or 0x252525FF
  if is_active then
    bg_color = config.bg_active_color or 0x1A1A1AFF
  elseif is_hovered then
    bg_color = config.bg_hover_color or 0x2A2A2AFF
  end
  
  local border_outer = config.border_outer_color or 0x000000DD
  local border_inner = config.border_inner_color or 0x404040FF
  if is_hovered then
    border_inner = config.border_hover_color or 0x505050FF
  end
  
  local text_color = config.text_color or 0xAAAAAAFF
  if is_hovered then
    text_color = config.text_hover_color or 0xFFFFFFFF
  end
  
  local corner_rounding = config.corner_rounding
  local rounding = corner_rounding and corner_rounding.rounding or 0
  local corner_flags = get_corner_flags(corner_rounding)
  
  ImGui.DrawList_AddRectFilled(dl, x, y, x + width, y + height, bg_color, rounding, corner_flags)
  
  ImGui.DrawList_AddRect(dl, x + 1, y + 1, x + width - 1, y + height - 1, border_inner, rounding, corner_flags, 1)
  
  ImGui.DrawList_AddRect(dl, x, y, x + width, y + height, border_outer, rounding, corner_flags, 1)
  
  local display_text = icon .. (icon ~= "" and label ~= "" and " " or "") .. label
  
  if config.custom_draw then
    config.custom_draw(ctx, dl, x, y, width, height, is_hovered, is_active, text_color)
  elseif display_text ~= "" then
    local text_w = ImGui.CalcTextSize(ctx, display_text)
    local text_x = x + (width - text_w) * 0.5
    local text_y = y + (height - ImGui.GetTextLineHeight(ctx)) * 0.5
    ImGui.DrawList_AddText(dl, text_x, text_y, text_color, display_text)
  end
  
  ImGui.SetCursorScreenPos(ctx, x, y)
  ImGui.InvisibleButton(ctx, "##" .. unique_id, width, height)
  
  local clicked = ImGui.IsItemClicked(ctx, 0)
  
  if clicked and config.on_click then
    config.on_click()
  end
  
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