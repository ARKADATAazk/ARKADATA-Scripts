-- core/progress_bar.lua - Modal progress indicator
local M = {}

local active_progress = nil

function M.create()
  local state = {
    active = false,
    message = "Loading...",
    ctx = nil,
    start_time = 0,
  }
  
  function state.show(ctx, message)
    state.active = true
    state.message = message or "Loading..."
    state.ctx = ctx
    state.start_time = reaper.ImGui_GetTime(ctx)
  end
  
  function state.update(message)
    if state.active and message then
      state.message = message
    end
  end
  
  function state.hide()
    state.active = false
    state.ctx = nil
  end
  
  function state.draw()
    if not state.active or not state.ctx then return end
    
    local ctx = state.ctx
    
    -- Center the popup
    local display_w, display_h = reaper.ImGui_GetMainViewport(ctx)
    if display_w and display_h then
      reaper.ImGui_SetNextWindowPos(ctx, display_w * 0.5, display_h * 0.5, reaper.ImGui_Cond_Always(), 0.5, 0.5)
    end
    
    reaper.ImGui_SetNextWindowSize(ctx, 400, 120, reaper.ImGui_Cond_Always())
    
    local window_flags = reaper.ImGui_WindowFlags_NoResize()
      | reaper.ImGui_WindowFlags_NoMove()
      | reaper.ImGui_WindowFlags_NoCollapse()
      | reaper.ImGui_WindowFlags_NoScrollbar()
      | reaper.ImGui_WindowFlags_NoSavedSettings()
    
    if reaper.ImGui_BeginPopupModal(ctx, 'Progress##loading', nil, window_flags) then
      reaper.ImGui_Text(ctx, state.message)
      reaper.ImGui_Spacing(ctx)
      
      -- Indeterminate progress bar (animated)
      local progress = -1.0 * reaper.ImGui_GetTime(ctx)
      reaper.ImGui_ProgressBar(ctx, progress, -1, 0, 'Please wait...')
      
      reaper.ImGui_Spacing(ctx)
      reaper.ImGui_TextDisabled(ctx, 'Processing...')
      
      reaper.ImGui_EndPopup(ctx)
    end
  end
  
  function state.is_active()
    return state.active
  end
  
  return state
end

-- Wrapper for operations with progress
function M.with_progress(ctx, message, operation)
  local progress = M.create()
  progress.show(ctx, message)
  
  -- Open the modal
  reaper.ImGui_OpenPopup(ctx, 'Progress##loading')
  
  -- Draw once to show it
  progress.draw()
  
  -- Force GUI update
  local function do_with_defer()
    -- Draw progress
    progress.draw()
    
    -- Execute operation
    local success, result, error_msg = pcall(operation, progress)
    
    -- Hide progress
    progress.hide()
    
    if not success then
      return nil, "Operation failed: " .. tostring(result)
    end
    
    return result, error_msg
  end
  
  return do_with_defer()
end

return M