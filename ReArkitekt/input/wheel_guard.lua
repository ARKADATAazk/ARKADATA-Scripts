-- ReArkitekt/input/wheel_guard.lua
-- Wheel input capture that prevents parent scrolling
local ImGui = require('imgui') '0.10'

local M = { _scroll_x = 0, _scroll_y = 0, _consumed = false }

function M.begin(ctx)
  M._scroll_x = (ImGui.GetScrollX and ImGui.GetScrollX(ctx)) or 0
  M._scroll_y = ImGui.GetScrollY(ctx)
  M._consumed = false
end

function M.capture_over_last_item(ctx, on_delta)
  if not ImGui.IsItemHovered(ctx) then return false end
  local vy, vx = ImGui.GetMouseWheel(ctx)
  if vy ~= 0 or vx ~= 0 then
    on_delta(vy, vx, ImGui.GetKeyMods(ctx))
    M._consumed = true
    return true
  end
  return false
end

function M.capture_if(ctx, condition, on_delta)
  if not condition then return false end
  local vy, vx = ImGui.GetMouseWheel(ctx)
  if vy ~= 0 or vx ~= 0 then
    on_delta(vy, vx, ImGui.GetKeyMods(ctx))
    M._consumed = true
    return true
  end
  return false
end

function M.finish(ctx)
  if M._consumed then
    if ImGui.SetScrollX then ImGui.SetScrollX(ctx, M._scroll_x) end
    ImGui.SetScrollY(ctx, M._scroll_y)
  end
end

return M