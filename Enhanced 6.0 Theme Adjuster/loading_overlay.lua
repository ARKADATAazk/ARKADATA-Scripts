-- core/loading_overlay.lua - Non-blocking loading indicator
local M = {}

local overlay_state = {
  active = false,
  message = "",
  start_time = 0,
}

-- Show overlay (renders immediately on next frame)
function M.show(message)
  overlay_state.active = true
  overlay_state.message = message or "Loading..."
  overlay_state.start_time = reaper.time_precise()
end

-- Hide overlay
function M.hide()
  overlay_state.active = false
  overlay_state.message = ""
end

-- Update message
function M.update(message)
  if overlay_state.active then
    overlay_state.message = message or overlay_state.message
  end
end

-- Draw overlay (call at end of your main draw loop)
function M.draw(ctx)
  if not overlay_state.active then return end
  
  local display_w, display_h = reaper.ImGui_GetMainViewport(ctx)
  if not display_w then return end
  
  -- Draw darkened background
  local dl = reaper.ImGui_GetBackgroundDrawList(ctx)
  reaper.ImGui_DrawList_AddRectFilled(dl, 0, 0, display_w, display_h, 0x000000AA)
  
  -- Calculate centered box
  local box_w, box_h = 400, 120
  local box_x = (display_w - box_w) * 0.5
  local box_y = (display_h - box_h) * 0.5
  
  -- Draw box background
  reaper.ImGui_DrawList_AddRectFilled(dl, box_x, box_y, box_x + box_w, box_y + box_h, 0x1E1E1EFF, 8)
  reaper.ImGui_DrawList_AddRect(dl, box_x, box_y, box_x + box_w, box_y + box_h, 0x00B88FFF, 8, 0, 2)
  
  -- Draw animated spinner dots
  local elapsed = reaper.time_precise() - overlay_state.start_time
  local dot_count = math.floor(elapsed * 2) % 4
  local dots = string.rep(".", dot_count)
  
  -- Draw text
  reaper.ImGui_DrawList_AddText(dl, box_x + 20, box_y + 35, 0xFFFFFFFF, overlay_state.message .. dots)
  reaper.ImGui_DrawList_AddText(dl, box_x + 20, box_y + 65, 0xAAAAAAFF, "Please wait...")
end

-- Execute operation with overlay
function M.with_overlay(ctx, message, operation)
  M.show(message)
  
  -- Force one frame render to show overlay
  local function deferred_operation()
    M.draw(ctx)
    
    -- Small delay to ensure overlay renders
    local start = reaper.time_precise()
    while reaper.time_precise() - start < 0.05 do end
    
    -- Execute the actual operation
    local success, result = pcall(operation)
    
    M.hide()
    
    if not success then
      return nil, tostring(result)
    end
    return result
  end
  
  return deferred_operation()
end

-- Check if overlay is active
function M.is_active()
  return overlay_state.active
end

return M