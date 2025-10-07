-- ReArkitekt/gui/widgets/controls/context_menu.lua
-- Reusable context menu widget

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local M = {}

local DEFAULTS = {
  bg_color = 0x1E1E1EFF,
  border_color = 0x404040FF,
  item_bg_color = 0x00000000,
  item_hover_color = 0x3A3A3AFF,
  item_active_color = 0x454545FF,
  item_text_color = 0xCCCCCCFF,
  item_text_hover_color = 0xFFFFFFFF,
  item_disabled_color = 0x666666FF,
  separator_color = 0x404040FF,
  rounding = 4,
  padding = 4,
  item_height = 24,
  item_padding_x = 10,
  border_thickness = 1,
}

function M.begin(ctx, id, config)
  config = config or {}
  
  local bg_color = config.bg_color or DEFAULTS.bg_color
  local border_color = config.border_color or DEFAULTS.border_color
  local rounding = config.rounding or DEFAULTS.rounding
  local padding = config.padding or DEFAULTS.padding
  local border_thickness = config.border_thickness or DEFAULTS.border_thickness
  
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding, padding, padding)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowRounding, rounding)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_PopupRounding, rounding)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowBorderSize, border_thickness)
  
  ImGui.PushStyleColor(ctx, ImGui.Col_PopupBg, bg_color)
  ImGui.PushStyleColor(ctx, ImGui.Col_Border, border_color)
  
  local popup_open = ImGui.BeginPopup(ctx, id)
  
  if not popup_open then
    ImGui.PopStyleColor(ctx, 2)
    ImGui.PopStyleVar(ctx, 4)
  end
  
  return popup_open
end

function M.end_menu(ctx)
  ImGui.EndPopup(ctx)
  ImGui.PopStyleColor(ctx, 2)
  ImGui.PopStyleVar(ctx, 4)
end

function M.item(ctx, label, config)
  config = config or {}
  
  local item_height = config.item_height or DEFAULTS.item_height
  local item_padding_x = config.item_padding_x or DEFAULTS.item_padding_x
  local item_hover_color = config.item_hover_color or DEFAULTS.item_hover_color
  local item_text_color = config.item_text_color or DEFAULTS.item_text_color
  local item_text_hover_color = config.item_text_hover_color or DEFAULTS.item_text_hover_color
  
  local dl = ImGui.GetWindowDrawList(ctx)
  local item_x, item_y = ImGui.GetCursorScreenPos(ctx)
  local avail_w = ImGui.GetContentRegionAvail(ctx)
  
  local text_w, text_h = ImGui.CalcTextSize(ctx, label)
  local item_w = math.max(avail_w, text_w + item_padding_x * 2)
  
  local item_hovered = ImGui.IsMouseHoveringRect(ctx, item_x, item_y, item_x + item_w, item_y + item_height)
  
  if item_hovered then
    ImGui.DrawList_AddRectFilled(dl, item_x, item_y, item_x + item_w, item_y + item_height, item_hover_color, 2)
  end
  
  local text_color = item_hovered and item_text_hover_color or item_text_color
  local text_x = item_x + item_padding_x
  local text_y = item_y + (item_height - text_h) * 0.5
  
  ImGui.DrawList_AddText(dl, text_x, text_y, text_color, label)
  
  ImGui.InvisibleButton(ctx, label .. "_item", item_w, item_height)
  
  return ImGui.IsItemClicked(ctx, 0)
end

function M.separator(ctx, config)
  config = config or {}
  local separator_color = config.separator_color or DEFAULTS.separator_color
  
  local x, y = ImGui.GetCursorScreenPos(ctx)
  local avail_w = ImGui.GetContentRegionAvail(ctx)
  
  local dl = ImGui.GetWindowDrawList(ctx)
  ImGui.DrawList_AddLine(dl, x, y + 4, x + avail_w, y + 4, separator_color, 1)
  
  ImGui.Dummy(ctx, 1, 8)
end

return M