-- ReArkitekt/gui/widgets/panel/header/search_field.lua
-- Search input field with integrated design

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local M = {}

local DEFAULTS = {
  placeholder = "Search...",
  fade_speed = 8.0,
  bg_color = 0x252525FF,
  bg_hover_color = 0x2A2A2AFF,
  bg_active_color = 0x2A2A2AFF,
  border_outer_color = 0x000000DD,
  border_inner_color = 0x404040FF,
  border_active_color = 0XB0B0B077,
  text_color = 0xCCCCCCFF,
}

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
  config = config or {}
  
  for k, v in pairs(DEFAULTS) do
    if config[k] == nil then config[k] = v end
  end
  
  local element_id = config.id or "search"
  local unique_id = string.format("%s_%s", tostring(state._panel_id or "unknown"), element_id)
  
  state.search_text = state.search_text or ""
  state.search_focused = state.search_focused or false
  state.search_alpha = state.search_alpha or 0.3
  
  local is_hovered = ImGui.IsMouseHoveringRect(ctx, x, y, x + width, y + height)
  
  local target_alpha = (state.search_focused or is_hovered or #state.search_text > 0) and 1.0 or 0.3
  local alpha_delta = (target_alpha - state.search_alpha) * config.fade_speed * ImGui.GetDeltaTime(ctx)
  state.search_alpha = math.max(0.3, math.min(1.0, state.search_alpha + alpha_delta))
  
  local bg_color = config.bg_color
  if state.search_focused then
    bg_color = config.bg_active_color
  elseif is_hovered then
    bg_color = config.bg_hover_color
  end
  
  local alpha_byte = math.floor(state.search_alpha * 255)
  bg_color = (bg_color & 0xFFFFFF00) | alpha_byte
  
  local corner_rounding = config.corner_rounding
  local rounding = corner_rounding and corner_rounding.rounding or 0
  local corner_flags = get_corner_flags(corner_rounding)
  
  ImGui.DrawList_AddRectFilled(dl, x, y, x + width, y + height, bg_color, rounding, corner_flags)
  
  local border_inner = state.search_focused and config.border_active_color or config.border_inner_color
  border_inner = (border_inner & 0xFFFFFF00) | alpha_byte
  ImGui.DrawList_AddRect(dl, x + 1, y + 1, x + width - 1, y + height - 1, border_inner, rounding, corner_flags, 1)
  
  local border_outer = (config.border_outer_color & 0xFFFFFF00) | alpha_byte
  ImGui.DrawList_AddRect(dl, x, y, x + width, y + height, border_outer, rounding, corner_flags, 1)
  
  ImGui.SetCursorScreenPos(ctx, x + 6, y + (height - ImGui.GetTextLineHeight(ctx)) * 0.5 - 2)
  ImGui.PushItemWidth(ctx, width - 12)
  
  ImGui.PushStyleColor(ctx, ImGui.Col_FrameBg, 0x00000000)
  ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgHovered, 0x00000000)
  ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgActive, 0x00000000)
  ImGui.PushStyleColor(ctx, ImGui.Col_Border, 0x00000000)
  
  local text_color = (config.text_color & 0xFFFFFF00) | alpha_byte
  ImGui.PushStyleColor(ctx, ImGui.Col_Text, text_color)
  
  local changed, new_text = ImGui.InputTextWithHint(
    ctx, 
    "##" .. unique_id, 
    config.placeholder, 
    state.search_text, 
    ImGui.InputTextFlags_None
  )
  
  if changed then
    state.search_text = new_text
    if config.on_change then
      config.on_change(new_text)
    end
  end
  
  state.search_focused = ImGui.IsItemActive(ctx)
  
  ImGui.PopStyleColor(ctx, 5)
  ImGui.PopItemWidth(ctx)
  
  return width, changed
end

function M.measure(ctx, config)
  return config.width or 200
end

return M