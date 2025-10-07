-- ReArkitekt/core/undo_manager.lua
-- Undo/Redo state management for Reaper integration

local M = {}

function M.new(opts)
  opts = opts or {}
  
  local manager = {
    history = {},
    current_index = 0,
    max_history = opts.max_history or 50,
    proj = opts.proj or 0,
    last_state_change = -1,
    monitoring_undo = false,
  }
  
  function manager:can_capture()
    return #self.history < self.max_history
  end
  
  function manager:capture_state(state_data)
    if self.current_index < #self.history then
      for i = #self.history, self.current_index + 1, -1 do
        table.remove(self.history, i)
      end
    end
    
    table.insert(self.history, state_data)
    
    if #self.history > self.max_history then
      table.remove(self.history, 1)
    else
      self.current_index = #self.history
    end
  end
  
  function manager:detect_reaper_undo_redo()
    local current_state = reaper.GetProjectStateChangeCount(self.proj)
    
    if self.last_state_change < 0 then
      self.last_state_change = current_state
      return false, false
    end
    
    if current_state == self.last_state_change then
      return false, false
    end
    
    local undo_desc = reaper.Undo_CanUndo2(self.proj)
    local redo_desc = reaper.Undo_CanRedo2(self.proj)
    
    local undo_triggered = undo_desc and undo_desc:find("Undo") ~= nil
    local redo_triggered = redo_desc and redo_desc:find("Redo") == nil and current_state ~= self.last_state_change
    
    self.last_state_change = current_state
    
    return undo_triggered, redo_triggered
  end
  
  function manager:get_previous_state()
    if self.current_index > 1 then
      self.current_index = self.current_index - 1
      return self.history[self.current_index]
    end
    return nil
  end
  
  function manager:get_next_state()
    if self.current_index < #self.history then
      self.current_index = self.current_index + 1
      return self.history[self.current_index]
    end
    return nil
  end
  
  function manager:clear()
    self.history = {}
    self.current_index = 0
  end
  
  return manager
end

return M