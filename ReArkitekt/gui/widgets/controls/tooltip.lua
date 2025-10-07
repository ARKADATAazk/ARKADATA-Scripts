-- ReArkitekt/gui/widgets/controls/tooltip.lua
-- Reusable styled tooltip widget

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local M = {}

local DEFAULTS = {
  bg_color = 0x2A2A2AFF,
  border_color = 0x404040FF,
  text_color = 0xEEEEEEFF,
  padding_x = 8,
  padding_y = 6,
  rounding = 4,
  border_thickness = 1,
  offset_x = 12,
  offset_y = 12,
  max_width = 300,
  delay = 0.0,
}

local tooltip_state = {
  hover_start_time = 0,
  last_text = "",
  is_visible = false,
}

function M.show(ctx, text, config)
  if not text or text == "" then return end
  
  config = config or {}
  
  local bg_color = config.bg_color or DEFAULTS.bg_color
  local border_color = config.border_color or DEFAULTS.border_color
  local text_color = config.text_color or DEFAULTS.text_color
  local padding_x = config.padding_x or DEFAULTS.padding_x
  local padding_y = config.padding_y or DEFAULTS.padding_y
  local rounding = config.rounding or DEFAULTS.rounding
  local border_thickness = config.border_thickness or DEFAULTS.border_thickness
  
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding, padding_x, padding_y)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowRounding, rounding)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowBorderSize, border_thickness)
  
  ImGui.PushStyleColor(ctx, ImGui.Col_PopupBg, bg_color)
  ImGui.PushStyleColor(ctx, ImGui.Col_Border, border_color)
  ImGui.PushStyleColor(ctx, ImGui.Col_Text, text_color)
  
  ImGui.SetTooltip(ctx, text)
  
  ImGui.PopStyleColor(ctx, 3)
  ImGui.PopStyleVar(ctx, 3)
end

function M.show_delayed(ctx, text, config)
  if not text or text == "" then
    tooltip_state.is_visible = false
    tooltip_state.last_text = ""
    return
  end
  
  config = config or {}
  local delay = config.delay or DEFAULTS.delay
  
  if text ~= tooltip_state.last_text then
    tooltip_state.hover_start_time = reaper.time_precise()
    tooltip_state.last_text = text
    tooltip_state.is_visible = false
  end
  
  local elapsed = reaper.time_precise() - tooltip_state.hover_start_time
  
  if elapsed >= delay then
    tooltip_state.is_visible = true
    M.show(ctx, text, config)
  end
end

function M.show_at_mouse(ctx, text, config)
  if not text or text == "" then return end
  
  config = config or {}
  
  local bg_color = config.bg_color or DEFAULTS.bg_color
  local border_color = config.border_color or DEFAULTS.border_color
  local text_color = config.text_color or DEFAULTS.text_color
  local padding_x = config.padding_x or DEFAULTS.padding_x
  local padding_y = config.padding_y or DEFAULTS.padding_y
  local rounding = config.rounding or DEFAULTS.rounding
  local border_thickness = config.border_thickness or DEFAULTS.border_thickness
  local offset_x = config.offset_x or DEFAULTS.offset_x
  local offset_y = config.offset_y or DEFAULTS.offset_y
  local max_width = config.max_width or DEFAULTS.max_width
  
  local mx, my = ImGui.GetMousePos(ctx)
  
  local text_w, text_h = ImGui.CalcTextSize(ctx, text, nil, nil, false, max_width)
  local tooltip_w = text_w + padding_x * 2
  local tooltip_h = text_h + padding_y * 2
  
  local x = mx + offset_x
  local y = my + offset_y
  
  local viewport_w, viewport_h = ImGui.GetMainViewport(ctx)
  if x + tooltip_w > viewport_w then
    x = mx - tooltip_w - offset_x
  end
  if y + tooltip_h > viewport_h then
    y = my - tooltip_h - offset_y
  end
  
  local dl = ImGui.GetForegroundDrawList(ctx)
  
  ImGui.DrawList_AddRectFilled(dl, x, y, x + tooltip_w, y + tooltip_h, bg_color, rounding)
  ImGui.DrawList_AddRect(dl, x + 0.5, y + 0.5, x + tooltip_w - 0.5, y + tooltip_h - 0.5, 
                         border_color, rounding, 0, border_thickness)
  
  ImGui.DrawList_AddText(dl, x + padding_x, y + padding_y, text_color, text)
end

function M.reset()
  tooltip_state.hover_start_time = 0
  tooltip_state.last_text = ""
  tooltip_state.is_visible = false
end

return M