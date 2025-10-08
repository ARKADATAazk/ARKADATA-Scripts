-- ReArkitekt/gui/widgets/tiles_container/header.lua
-- Header orchestration and mode switching

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local TabsMode = require('ReArkitekt.gui.widgets.tiles_container.modes.tabs')
local SearchSortMode = require('ReArkitekt.gui.widgets.tiles_container.modes.search_sort')

local M = {}

function M.draw(ctx, dl, x, y, width, height, state, cfg, container_rounding)
  local header_cfg = cfg.header
  if not header_cfg or not header_cfg.enabled then return 0 end
  
  local rounding = container_rounding or 0
  local round_flags = ImGui.DrawFlags_RoundCornersTop or 0
  
  ImGui.DrawList_AddRectFilled(dl, x, y, x + width, y + height, 
    header_cfg.bg_color, rounding, round_flags)
  
  ImGui.DrawList_AddLine(dl, x, y + height, x + width, y + height, 
    header_cfg.border_color, 1)
  
  local ctrl_pressed = ImGui.IsKeyDown(ctx, ImGui.Key_LeftCtrl) or ImGui.IsKeyDown(ctx, ImGui.Key_RightCtrl)
  local f_pressed = ImGui.IsKeyPressed(ctx, ImGui.Key_F)
  
  if ctrl_pressed and f_pressed and header_cfg.mode == 'tabs' then
    state.temp_search_mode = not state.temp_search_mode
    if state.temp_search_mode then
      state.search_text = ""
    end
  end
  
  local mode = header_cfg.mode or 'search_sort'
  if mode == 'tabs' and state.temp_search_mode then
    mode = 'temp_search'
  end
  
  if mode == 'tabs' then
    return TabsMode.draw(ctx, dl, x, y, width, height, state, header_cfg)
  elseif mode == 'search_sort' or mode == 'temp_search' then
    return SearchSortMode.draw(ctx, dl, x, y, width, height, state, header_cfg)
  end
  
  return height
end

return M