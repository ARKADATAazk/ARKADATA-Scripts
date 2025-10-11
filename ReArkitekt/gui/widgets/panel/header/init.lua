-- ReArkitekt/gui/widgets/panel/header/init.lua
-- Header coordinator - uses layout engine

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local Layout = require('ReArkitekt.gui.widgets.panel.header.layout')

local M = {}

function M.draw(ctx, dl, x, y, w, h, state, config, rounding)
  local header_cfg = config.header
  if not header_cfg or not header_cfg.enabled then
    return 0
  end
  
  ImGui.DrawList_AddRectFilled(
    dl, x, y, x + w, y + h,
    header_cfg.bg_color or 0x0F0F0FFF,
    rounding,
    ImGui.DrawFlags_RoundCornersTop
  )
  
  ImGui.DrawList_AddLine(
    dl, x, y + h - 1, x + w, y + h - 1,
    header_cfg.border_color or 0x000000DD,
    1
  )
  
  Layout.draw(ctx, dl, x, y, w, h, state, header_cfg)
  
  return h
end

return M