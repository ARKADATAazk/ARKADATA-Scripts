-- ReArkitekt/gui/systems/selection.lua
-- Selection model with Ctrl/Shift support and rectangle selection
-- Pure logic, no UI dependencies

local M = {}

local Selection = {}
Selection.__index = Selection

function M.new()
  return setmetatable({
    selected = {},      -- id -> bool
    last_clicked = nil, -- id of last clicked item
  }, Selection)
end

-- Select single item (clear others)
function Selection:single(id)
  self.selected = {}
  if id then
    self.selected[id] = true
    self.last_clicked = id
  end
end

-- Toggle selection of an item
function Selection:toggle(id)
  if not id then return end
  self.selected[id] = not self.selected[id]
  if self.selected[id] then
    self.last_clicked = id
  end
end

-- Select range between two items given an order
-- order: array of all item ids in display order
-- from_id: start of range
-- to_id: end of range
function Selection:range(order, from_id, to_id)
  if not order or not from_id or not to_id then return end
  
  local selecting = false
  for _, id in ipairs(order) do
    if id == from_id or id == to_id then
      self.selected[id] = true
      if not selecting then
        selecting = true
      else
        break -- Found both ends
      end
    elseif selecting then
      self.selected[id] = true
    end
  end
  self.last_clicked = to_id
end

-- Apply rectangle selection
-- aabb: {x1, y1, x2, y2} of selection rectangle
-- rects_by_key: table of id -> {x1, y1, x2, y2}
-- mode: "replace" (default) or "add"
function Selection:apply_rect(aabb, rects_by_key, mode)
  if not aabb or not rects_by_key then return end
  mode = mode or "replace"
  
  if mode == "replace" then
    self.selected = {}
  end
  
  local ax1, ay1, ax2, ay2 = aabb[1], aabb[2], aabb[3], aabb[4]
  local a_left = math.min(ax1, ax2)
  local a_right = math.max(ax1, ax2)
  local a_top = math.min(ay1, ay2)
  local a_bottom = math.max(ay1, ay2)
  
  local last_selected = nil
  for id, rect in pairs(rects_by_key) do
    local bx1, by1, bx2, by2 = rect[1], rect[2], rect[3], rect[4]
    local b_left = math.min(bx1, bx2)
    local b_right = math.max(bx1, bx2)
    local b_top = math.min(by1, by2)
    local b_bottom = math.max(by1, by2)
    
    -- Check intersection
    local intersects = not (a_left > b_right or a_right < b_left or 
                            a_top > b_bottom or a_bottom < b_top)
    if intersects then
      self.selected[id] = true
      last_selected = id
    end
  end
  
  -- Update last_clicked so SHIFT+click works after rectangle selection
  if last_selected then
    self.last_clicked = last_selected
  end
end

-- Check if item is selected
function Selection:is_selected(id)
  return self.selected[id] == true
end

-- Clear all selections
function Selection:clear()
  self.selected = {}
  self.last_clicked = nil
end

-- Get count of selected items
function Selection:count()
  local n = 0
  for _, v in pairs(self.selected) do
    if v then n = n + 1 end
  end
  return n
end

-- Get selected keys in given order
-- order: array of all item ids
-- Returns: array of selected ids in same order
function Selection:selected_keys_in(order)
  local out = {}
  for _, id in ipairs(order or {}) do
    if self.selected[id] then
      out[#out + 1] = id
    end
  end
  return out
end

-- Get all selected keys (unordered)
function Selection:selected_keys()
  local out = {}
  for id, sel in pairs(self.selected) do
    if sel then out[#out + 1] = id end
  end
  return out
end

return M