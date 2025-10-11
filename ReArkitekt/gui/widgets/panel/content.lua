-- ReArkitekt/gui/widgets/tiles_container/content.lua
-- Scrollable content area management

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local M = {}

function M.begin_child(ctx, id, width, height, scroll_config)
  local flags = scroll_config.flags or 0
  local scroll_bg = scroll_config.bg_color or 0x00000000
  
  ImGui.PushStyleColor(ctx, ImGui.Col_ScrollbarBg, scroll_bg)
  
  local success = ImGui.BeginChild(ctx, id .. "_scroll", width, height, ImGui.ChildFlags_None, flags)
  
  if not success then
    ImGui.PopStyleColor(ctx, 1)
  end
  
  return success
end

function M.end_child(ctx, container)
  local anti_jitter = container.config.anti_jitter
  
  if anti_jitter and anti_jitter.enabled and anti_jitter.track_scrollbar then
    local cursor_y = ImGui.GetCursorPosY(ctx)
    local content_height = cursor_y
    
    local threshold = anti_jitter.height_threshold or 5
    
    if math.abs(content_height - container.last_content_height) > threshold then
      container.had_scrollbar_last_frame = content_height > (container.actual_child_height + threshold)
      container.last_content_height = content_height
    end
  end
  
  ImGui.EndChild(ctx)
  ImGui.PopStyleColor(ctx, 1)
end

return M