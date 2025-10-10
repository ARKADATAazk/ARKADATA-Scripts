-- Region_Playlist/app/shortcuts.lua
-- Keyboard shortcut handling

local ImGui = require 'imgui' '0.10'

local M = {}

function M.handle_keyboard_shortcuts(ctx, state, region_tiles)
  local ctrl = ImGui.IsKeyDown(ctx, ImGui.Mod_Ctrl)
  local shift = ImGui.IsKeyDown(ctx, ImGui.Mod_Shift)
  
  if ctrl and ImGui.IsKeyPressed(ctx, ImGui.Key_Z, false) then
    local State = require("Region_Playlist.app.state")
    if shift then
      State.redo()
    else
      State.undo()
    end
    return true
  end
  
  if ctrl and ImGui.IsKeyPressed(ctx, ImGui.Key_Y, false) then
    local State = require("Region_Playlist.app.state")
    State.redo()
    return true
  end
  
  if ImGui.IsKeyPressed(ctx, ImGui.Key_Space, false) then
    local bridge_state = state.bridge:get_state()
    
    if bridge_state.is_playing then
      state.bridge:stop()
    else
      if region_tiles.active_grid and region_tiles.active_grid.selection then
        local selected = region_tiles.active_grid.selection:selected_keys()
        if #selected > 0 then
          local State = require("Region_Playlist.app.state")
          local pl = State.get_active_playlist()
          local engine_index = state.bridge:item_key_to_engine_index(pl.items, selected[1])
          if engine_index then
            state.bridge.engine:set_playlist_pointer(engine_index)
          end
        end
      end
      
      local success = state.bridge:play()
      if not success then
        reaper.ShowConsoleMsg("Failed to play - check playlist\n")
      end
    end
    return true
  end
  
  if ImGui.IsKeyPressed(ctx, ImGui.Key_RightArrow, false) then
    state.bridge:next()
    return true
  end
  
  if ImGui.IsKeyPressed(ctx, ImGui.Key_LeftArrow, false) then
    state.bridge:prev()
    return true
  end
  
  if ImGui.IsKeyPressed(ctx, ImGui.Key_Q, false) then
    local bridge_state = state.bridge:get_state()
    local modes = { "none", "beat", "bar", "grid" }
    local current_idx = 1
    for i, mode in ipairs(modes) do
      if mode == bridge_state.quantize_mode then
        current_idx = i
        break
      end
    end
    local next_idx = (current_idx % #modes) + 1
    state.bridge:set_quantize_mode(modes[next_idx])
    return true
  end
  
  return false
end

return M