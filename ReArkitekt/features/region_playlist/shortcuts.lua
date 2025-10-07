-- ReArkitekt/features/region_playlist/shortcuts.lua
-- Keyboard shortcuts for Region Playlist

local M = {}

function M.handle_shortcuts(ctx, bridge)
  local ImGui = require 'imgui' '0.10'
  
  local ctrl = ImGui.IsKeyDown(ctx, ImGui.Mod_Ctrl)
  local shift = ImGui.IsKeyDown(ctx, ImGui.Mod_Shift)
  local alt = ImGui.IsKeyDown(ctx, ImGui.Mod_Alt)
  
  -- Space: Play/Pause
  if ImGui.IsKeyPressed(ctx, ImGui.Key_Space, false) then
    local state = bridge:get_state()
    if state.is_playing then
      bridge:stop()
    else
      bridge:play()
    end
    return true
  end
  
  -- Ctrl+Space: Stop
  if ctrl and ImGui.IsKeyPressed(ctx, ImGui.Key_Space, false) then
    bridge:stop()
    return true
  end
  
  -- Right Arrow: Next region
  if ImGui.IsKeyPressed(ctx, ImGui.Key_RightArrow, false) then
    bridge:next()
    return true
  end
  
  -- Left Arrow: Previous region
  if ImGui.IsKeyPressed(ctx, ImGui.Key_LeftArrow, false) then
    bridge:prev()
    return true
  end
  
  -- Q: Cycle quantize modes
  if ImGui.IsKeyPressed(ctx, ImGui.Key_Q, false) then
    local state = bridge:get_state()
    local modes = { "none", "beat", "bar", "grid" }
    local current_idx = 1
    for i, mode in ipairs(modes) do
      if mode == state.quantize_mode then
        current_idx = i
        break
      end
    end
    local next_idx = (current_idx % #modes) + 1
    bridge:set_quantize_mode(modes[next_idx])
    return true
  end
  
  -- F: Toggle follow playhead
  if ImGui.IsKeyPressed(ctx, ImGui.Key_F, false) then
    local state = bridge:get_state()
    bridge:set_follow_playhead(not state.follow_playhead)
    return true
  end
  
  return false
end

return M