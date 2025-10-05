-- ReArkitekt/app/runtime.lua
-- Owns the ImGui context and main defer loop
-- Provides a clean API for running a frame callback

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local M = {}

-- Create and manage an ImGui context with defer loop
-- opts: {
--   title = string,
--   ctx = context (optional, if not provided will create one),
--   on_frame = function(ctx) -> bool (return false to close),
--   on_destroy = function() (optional cleanup)
-- }
function M.new(opts)
  opts = opts or {}
  local title = opts.title or "Application"
  local ctx = opts.ctx or ImGui.CreateContext(title)  -- Accept existing or create new
  
  local runtime = {
    ctx = ctx,
    open = true,
    on_frame = opts.on_frame or function(ctx) return true end,
    on_destroy = opts.on_destroy
  }
  
  -- Main defer loop
  local function frame()
    if not runtime.open then
      if runtime.on_destroy then
        runtime.on_destroy()
      end
      -- Note: ImGui 0.9 doesn't have DestroyContext - cleanup is automatic
      return
    end
    
    -- Call the frame callback
    local continue = runtime.on_frame(ctx)
    if continue == false then
      runtime.open = false
    end
    
    if runtime.open then
      reaper.defer(frame)
    else
      if runtime.on_destroy then
        runtime.on_destroy()
      end
      -- Note: ImGui 0.9 doesn't have DestroyContext - cleanup is automatic
    end
  end
  
  -- Start the loop
  function runtime:start()
    reaper.defer(frame)
  end
  
  -- Request close
  function runtime:request_close()
    self.open = false
  end
  
  return runtime
end

return M