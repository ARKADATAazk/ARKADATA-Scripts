-- ReArkitekt/gui/widgets/grid/dnd_state.lua
-- Drag-and-drop state machine for grid widgets
-- Extracted from grid/core.lua to enable testing and reuse

local M = {}

local DnDState = {}
DnDState.__index = DnDState

function M.new(opts)
  opts = opts or {}
  
  return setmetatable({
    pressed_id = nil,
    pressed_was_selected = false,
    press_pos = nil,
    active = false,
    ids = nil,
    target_index = nil,
    pending_selection = nil,
    threshold = opts.threshold or 6,
  }, DnDState)
end

function DnDState:start_press(id, was_selected, mx, my)
  self.pressed_id = id
  self.pressed_was_selected = was_selected
  self.press_pos = {mx, my}
  self.pending_selection = nil
end

function DnDState:set_pending_selection(id)
  self.pending_selection = id
end

function DnDState:should_start_drag(current_mx, current_my)
  if not self.press_pos then return false end
  local dx = current_mx - self.press_pos[1]
  local dy = current_my - self.press_pos[2]
  return (dx * dx + dy * dy) >= (self.threshold * self.threshold)
end

function DnDState:activate_drag(dragged_ids)
  self.active = true
  self.ids = dragged_ids
  self.pending_selection = nil
end

function DnDState:set_target(index)
  self.target_index = index
end

function DnDState:is_active()
  return self.active == true
end

function DnDState:is_pressed()
  return self.pressed_id ~= nil
end

function DnDState:get_pressed_id()
  return self.pressed_id
end

function DnDState:was_pressed_selected()
  return self.pressed_was_selected == true
end

function DnDState:get_dragged_ids()
  return self.ids or {}
end

function DnDState:get_target_index()
  return self.target_index
end

function DnDState:has_pending_selection()
  return self.pending_selection ~= nil
end

function DnDState:get_pending_selection()
  return self.pending_selection
end

function DnDState:clear_pending_selection()
  self.pending_selection = nil
end

function DnDState:release()
  local pending = self.pending_selection
  self.pressed_id = nil
  self.pressed_was_selected = false
  self.press_pos = nil
  self.active = false
  self.ids = nil
  self.target_index = nil
  self.pending_selection = nil
  return pending
end

function DnDState:cancel_drag()
  self.active = false
  self.ids = nil
  self.target_index = nil
  self.pending_selection = nil
end

function DnDState:clear()
  self:release()
end

return M