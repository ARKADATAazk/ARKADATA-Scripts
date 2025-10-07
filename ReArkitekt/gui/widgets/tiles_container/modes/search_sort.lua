-- ReArkitekt/gui/widgets/tiles_container/modes/search_sort.lua
-- Search + sort mode rendering

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local Dropdown = require('ReArkitekt.gui.widgets.controls.dropdown')

local M = {}

local function draw_search_bar(ctx, dl, x, y, width, height, state, cfg)
  local search_cfg = cfg.search
  if not search_cfg or not search_cfg.enabled then return x + width end
  
  local is_hovered = ImGui.IsMouseHoveringRect(ctx, x, y, x + width, y + height)
  local is_focused = state.search_focused
  
  state.search_alpha = state.search_alpha or 0.3
  local target_alpha = (is_focused or is_hovered or #state.search_text > 0) and 1.0 or 0.3
  local alpha_delta = (target_alpha - state.search_alpha) * search_cfg.fade_speed * ImGui.GetDeltaTime(ctx)
  state.search_alpha = math.max(0.3, math.min(1.0, state.search_alpha + alpha_delta))
  
  local bg_color = search_cfg.bg_color
  if is_focused then
    bg_color = search_cfg.bg_active_color
  elseif is_hovered then
    bg_color = search_cfg.bg_hover_color
  end
  
  local alpha_byte = math.floor(state.search_alpha * 255)
  bg_color = (bg_color & 0xFFFFFF00) | alpha_byte
  
  ImGui.DrawList_AddRectFilled(dl, x, y, x + width, y + height, bg_color, search_cfg.rounding)
  
  local border_color = is_focused and search_cfg.border_active_color or search_cfg.border_color
  border_color = (border_color & 0xFFFFFF00) | alpha_byte
  ImGui.DrawList_AddRect(dl, x, y, x + width, y + height, border_color, search_cfg.rounding, 0, 1)
  
  ImGui.SetCursorScreenPos(ctx, x + 6, y + (height - ImGui.GetTextLineHeight(ctx)) * 0.5 - 2)
  ImGui.PushItemWidth(ctx, width - 12)
  
  ImGui.PushStyleColor(ctx, ImGui.Col_FrameBg, 0x00000000)
  ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgHovered, 0x00000000)
  ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgActive, 0x00000000)
  ImGui.PushStyleColor(ctx, ImGui.Col_Border, 0x00000000)
  
  local text_color = search_cfg.text_color
  text_color = (text_color & 0xFFFFFF00) | alpha_byte
  ImGui.PushStyleColor(ctx, ImGui.Col_Text, text_color)
  
  local changed, new_text = ImGui.InputTextWithHint(ctx, "##search_" .. state.id, 
    search_cfg.placeholder, state.search_text, ImGui.InputTextFlags_None)
  
  if changed then
    state.search_text = new_text
    if state.on_search_changed then
      state.on_search_changed(new_text)
    end
  end
  
  state.search_focused = ImGui.IsItemActive(ctx)
  
  ImGui.PopStyleColor(ctx, 5)
  ImGui.PopItemWidth(ctx)
  
  return x + width
end

local function draw_sort_dropdown(ctx, x, y, content_height, state, cfg)
  local dropdown_cfg = cfg.sort_dropdown
  if not dropdown_cfg or not dropdown_cfg.enabled then return x end
  
  if not state.sort_dropdown then
    state.sort_dropdown = Dropdown.new({
      id = "sort_dropdown_" .. state.id,
      tooltip = dropdown_cfg.tooltip,
      tooltip_delay = dropdown_cfg.tooltip_delay,
      options = dropdown_cfg.options,
      current_value = state.sort_mode,
      sort_direction = state.sort_direction or "asc",
      on_change = function(value)
        state.sort_mode = value
        if state.on_sort_changed then
          state.on_sort_changed(value)
        end
      end,
      on_direction_change = function(direction)
        state.sort_direction = direction
        if state.on_sort_direction_changed then
          state.on_sort_direction_changed(direction)
        end
      end,
      config = {
        width = dropdown_cfg.width,
        height = dropdown_cfg.height,
        tooltip_delay = dropdown_cfg.tooltip_delay,
        bg_color = dropdown_cfg.bg_color,
        bg_hover_color = dropdown_cfg.bg_hover_color,
        bg_active_color = dropdown_cfg.bg_active_color,
        text_color = dropdown_cfg.text_color,
        text_hover_color = dropdown_cfg.text_hover_color,
        border_color = dropdown_cfg.border_color,
        border_hover_color = dropdown_cfg.border_hover_color,
        rounding = dropdown_cfg.rounding,
        padding_x = dropdown_cfg.padding_x,
        padding_y = dropdown_cfg.padding_y,
        arrow_size = dropdown_cfg.arrow_size,
        arrow_color = dropdown_cfg.arrow_color,
        arrow_hover_color = dropdown_cfg.arrow_hover_color,
        enable_mousewheel = true,
        popup = dropdown_cfg.popup,
      },
    })
  end
  
  local dropdown_y = y + (content_height - dropdown_cfg.height) * 0.5
  state.sort_dropdown:draw(ctx, x, dropdown_y)
  
  return x + dropdown_cfg.width
end

function M.draw(ctx, dl, x, y, width, height, state, cfg)
  local cursor_x = x + cfg.padding_x
  local cursor_y = y + cfg.padding_y
  local content_height = height - (cfg.padding_y * 2)
  
  if cfg.search and cfg.search.enabled then
    local search_width = math.max(
      cfg.search.min_width,
      width * cfg.search.width_ratio
    )
    
    cursor_x = draw_search_bar(ctx, dl, cursor_x, cursor_y, 
      search_width, content_height, state, cfg)
    cursor_x = cursor_x + cfg.spacing
  end
  
  if cfg.sort_dropdown and cfg.sort_dropdown.enabled then
    cursor_x = draw_sort_dropdown(ctx, cursor_x, cursor_y, content_height, state, cfg)
  end
  
  return height
end

return M