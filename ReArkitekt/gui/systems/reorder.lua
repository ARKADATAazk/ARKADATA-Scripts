-- ReArkitekt/gui/systems/reorder.lua
-- Pure reordering logic for drag and drop
-- No UI dependencies, just array manipulation

local M = {}

-- Helper: convert list to set
local function set_from(list)
  local t = {}
  for _, id in ipairs(list or {}) do
    t[id] = true
  end
  return t
end

-- Insert dragged items relative to a target
-- order_keys: array of all item ids in current order
-- dragged_keys: array of ids being dragged
-- target_key: id of the drop target
-- side: "before" or "after"
-- Returns: new order array
function M.insert_relative(order_keys, dragged_keys, target_key, side)
  if not order_keys or not dragged_keys or #dragged_keys == 0 or not target_key then
    return order_keys
  end
  
  -- Can't drop onto something being dragged
  local dragging = set_from(dragged_keys)
  if dragging[target_key] then
    return order_keys
  end
  
  -- Remove dragged items from order
  local base = {}
  for _, id in ipairs(order_keys) do
    if not dragging[id] then
      base[#base + 1] = id
    end
  end
  
  -- Find insertion point
  local insert_idx = #base + 1
  for i, id in ipairs(base) do
    if id == target_key then
      insert_idx = (side == 'after') and (i + 1) or i
      break
    end
  end
  
  -- Build new order
  local new_order = {}
  
  -- Items before insertion point
  for i = 1, insert_idx - 1 do
    new_order[#new_order + 1] = base[i]
  end
  
  -- Dragged items
  for _, id in ipairs(dragged_keys) do
    new_order[#new_order + 1] = id
  end
  
  -- Items after insertion point
  for i = insert_idx, #base do
    new_order[#new_order + 1] = base[i]
  end
  
  return new_order
end

-- Move items up in order
-- order_keys: array of all item ids
-- selected_keys: array of ids to move up
-- Returns: new order array
function M.move_up(order_keys, selected_keys)
  if not order_keys or not selected_keys or #selected_keys == 0 then
    return order_keys
  end
  
  local selected = set_from(selected_keys)
  local new_order = {}
  
  for i, id in ipairs(order_keys) do
    if i > 1 and selected[id] and not selected[order_keys[i-1]] then
      -- Swap with previous
      new_order[#new_order] = id
      new_order[#new_order + 1] = order_keys[i-1]
    elseif not selected[id] or i == 1 then
      new_order[#new_order + 1] = id
    end
  end
  
  return new_order
end

-- Move items down in order
-- order_keys: array of all item ids
-- selected_keys: array of ids to move down
-- Returns: new order array
function M.move_down(order_keys, selected_keys)
  if not order_keys or not selected_keys or #selected_keys == 0 then
    return order_keys
  end
  
  local selected = set_from(selected_keys)
  local new_order = {}
  local skip_next = false
  
  for i, id in ipairs(order_keys) do
    if skip_next then
      skip_next = false
      new_order[#new_order + 1] = id
    elseif i < #order_keys and selected[id] and not selected[order_keys[i+1]] then
      -- Swap with next
      new_order[#new_order + 1] = order_keys[i+1]
      new_order[#new_order + 1] = id
      skip_next = true
    else
      new_order[#new_order + 1] = id
    end
  end
  
  return new_order
end

return M