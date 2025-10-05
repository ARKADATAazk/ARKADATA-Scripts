-- ReArkitekt/gui/widgets/selection_rectangle.lua
-- Standalone selection rectangle overlay widget
-- Marquee selection (LEFT click + drag on background, square corners)

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local M = {}

local SelRect = {}
SelRect.__index = SelRect

-- Create a new selection rectangle widget
function M.new(opts)
  opts = opts or {}

  return setmetatable({
    -- State
    active = false,
    mode = "replace",  -- "replace" or "add"
    start_pos = nil,
    current_pos = nil,
    dragged = false,
  }, SelRect)
end

-- Begin a selection (LEFT mouse button on background)
function SelRect:begin(x, y, mode)
  self.active = true
  self.mode = mode or "replace"
  self.start_pos = {x, y}
  self.current_pos = {x, y}
  self.dragged = false
end

-- Update current position (while dragging)
function SelRect:update(x, y)
  if not self.active then return end
  self.current_pos = {x, y}
  
  -- Check if we've actually dragged (moved more than a few pixels)
  if self.start_pos then
    local dx = math.abs(x - self.start_pos[1])
    local dy = math.abs(y - self.start_pos[2])
    if dx > 3 or dy > 3 then
      self.dragged = true
    end
  end
end

-- Check if selection is active
function SelRect:is_active()
  return self.active
end

-- Check if we actually dragged (not just clicked)
function SelRect:did_drag()
  return self.dragged
end

-- Get the selection AABB
function SelRect:aabb()
  if not self.active or not self.start_pos or not self.current_pos then
    return nil
  end

  local x1 = math.min(self.start_pos[1], self.current_pos[1])
  local y1 = math.min(self.start_pos[2], self.current_pos[2])
  local x2 = math.max(self.start_pos[1], self.current_pos[1])
  local y2 = math.max(self.start_pos[2], self.current_pos[2])

  -- Snap to pixel boundaries for crisp rendering
  x1 = math.floor(x1 + 0.5)
  y1 = math.floor(y1 + 0.5)
  x2 = math.floor(x2 + 0.5)
  y2 = math.floor(y2 + 0.5)

  return x1, y1, x2, y2
end

-- Clear the selection
function SelRect:clear()
  self.active = false
  self.start_pos = nil
  self.current_pos = nil
  self.mode = "replace"
  self.dragged = false
end

-- End the selection (returns AABB for final processing)
function SelRect:finish()
  local x1, y1, x2, y2 = self:aabb()
  local did_drag = self.dragged
  self:clear()
  return x1, y1, x2, y2, did_drag
end

return M