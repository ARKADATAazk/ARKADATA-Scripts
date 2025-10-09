-- ReArkitekt/gui/widgets/tiles_container/header.lua
-- Header rendering coordinator

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local SearchSort = require('ReArkitekt.gui.widgets.tiles_container.modes.search_sort')
local Tabs = require('ReArkitekt.gui.widgets.tiles_container.modes.tabs')

local M = {}

function M.draw(ctx, dl, x, y, w, h, state, config, rounding)
  local header_cfg = config.header
  if not header_cfg or not header_cfg.enabled then
    return 0
  end
  
  ImGui.DrawList_AddRectFilled(dl, x, y, x + w, y + h, header_cfg.bg_color, rounding, ImGui.DrawFlags_RoundCornersTop)
  
  ImGui.DrawList_AddLine(dl, x, y + h - 1, x + w, y + h - 1, header_cfg.border_color, 1)
  
  local mode = header_cfg.mode or 'search_sort'
  
  if mode == 'search_sort' then
    SearchSort.draw(
      ctx, dl,
      x, y,
      w, h,
      state,
      header_cfg,
      state.current_mode,
      state.on_mode_changed
    )
  elseif mode == 'tabs' then
    Tabs.draw(ctx, dl, x, y, w, h, state, header_cfg, state.tab_animator)
  end
  
  return h
end

return M