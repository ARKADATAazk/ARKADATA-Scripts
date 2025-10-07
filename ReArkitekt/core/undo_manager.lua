-- ReArkitekt/core/undo_manager.lua
-- Simple undo/redo stack (no Reaper integration)

local M = {}

function M.new(opts)
  opts = opts or {}
  
  local manager = {
    history = {},
    current_index = 0,
    max_history = opts.max_history or 50,
  }
  
  function manager:push(state)
    if self.current_index < #self.history then
      for i = #self.history, self.current_index + 1, -1 do
        table.remove(self.history, i)
      end
    end
    
    table.insert(self.history, state)
    
    if #self.history > self.max_history then
      table.remove(self.history, 1)
    else
      self.current_index = #self.history
    end
  end
  
  function manager:can_undo()
    return self.current_index > 1
  end
  
  function manager:can_redo()
    return self.current_index < #self.history
  end
  
  function manager:undo()
    if not self:can_undo() then
      return nil
    end
    
    self.current_index = self.current_index - 1
    return self.history[self.current_index]
  end
  
  function manager:redo()
    if not self:can_redo() then
      return nil
    end
    
    self.current_index = self.current_index + 1
    return self.history[self.current_index]
  end
  
  function manager:clear()
    self.history = {}
    self.current_index = 0
  end
  
  function manager:get_current()
    return self.history[self.current_index]
  end
  
  return manager
end

return M