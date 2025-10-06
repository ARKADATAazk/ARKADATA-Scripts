-- ReArkitekt/gui/widgets/grid/drop_zones.lua
-- Drop zone calculation for grid drag-and-drop operations
-- FIXED: Vertical drop zones now position correctly, matching actual insertion behavior
-- FIXED: Drop zones are now constrained to the grid's bounds to prevent overlap between adjacent grids.

local M = {}

local function build_non_dragged_items(items, key_fn, dragged_set, rect_track)
  local non_dragged = {}
  for i, item in ipairs(items) do
    local key = key_fn(item)
    if not dragged_set[key] then
      local rect = rect_track:get(key)
      if rect then
        non_dragged[#non_dragged + 1] = {
          item = item,
          key = key,
          original_index = i,
          rect = rect,
        }
      end
    end
  end
  return non_dragged
end

local function create_horizontal_drop_zones(non_dragged_items, grid_bounds)
  local zones = {}
  
  -- Use grid boundaries if available, otherwise fall back to a large number
  local top_bound = grid_bounds and grid_bounds[2] or -10000
  local bottom_bound = grid_bounds and grid_bounds[4] or 10000
  
  for i, entry in ipairs(non_dragged_items) do
    local rect = entry.rect
    local midy = (rect[2] + rect[4]) * 0.5
    
    if i == 1 then
      local between_y = rect[2]
      zones[#zones + 1] = {
        x1 = rect[1],
        x2 = rect[3],
        y1 = top_bound,
        y2 = midy,
        index = 1,
        between_y = between_y,
        orientation = 'horizontal',
      }
    end
    
    local next_entry = non_dragged_items[i + 1]
    if next_entry then
      local next_rect = next_entry.rect
      local next_midy = (next_rect[2] + next_rect[4]) * 0.5
      local between_y = (rect[4] + next_rect[2]) * 0.5
      
      zones[#zones + 1] = {
        x1 = math.min(rect[1], next_rect[1]),
        x2 = math.max(rect[3], next_rect[3]),
        y1 = midy,
        y2 = next_midy,
        index = i + 1,
        between_y = between_y,
        orientation = 'horizontal',
      }
    else
      local between_y = rect[4]
      zones[#zones + 1] = {
        x1 = rect[1],
        x2 = rect[3],
        y1 = midy,
        y2 = bottom_bound,
        index = i + 1,
        between_y = between_y,
        orientation = 'horizontal',
      }
    end
  end
  
  return zones
end

local function create_vertical_drop_zones(non_dragged_items, grid_bounds)
  local zones = {}
  
  -- Use grid boundaries if available, otherwise fall back to a large number
  local left_bound = grid_bounds and grid_bounds[1] or -10000
  local right_bound = grid_bounds and grid_bounds[3] or 10000
  
  local rows = {}
  for _, entry in ipairs(non_dragged_items) do
    local rect = entry.rect
    local row_found = false
    
    for _, row in ipairs(rows) do
      local row_top = row[1].rect[2]
      local row_bottom = row[1].rect[4]
      
      if not (rect[4] < row_top or rect[2] > row_bottom) then
        row[#row + 1] = entry
        row_found = true
        break
      end
    end
    
    if not row_found then
      rows[#rows + 1] = {entry}
    end
  end
  
  for _, row in ipairs(rows) do
    table.sort(row, function(a, b) return a.rect[1] < b.rect[1] end)
  end
  
  local sequential_items = {}
  for _, row in ipairs(rows) do
    for _, entry in ipairs(row) do
      sequential_items[#sequential_items + 1] = entry
    end
  end
  
  for i, entry in ipairs(sequential_items) do
    local rect = entry.rect
    local midx = (rect[1] + rect[3]) * 0.5
    
    if i == 1 then
      zones[#zones + 1] = {
        x1 = left_bound,
        x2 = midx,
        y1 = rect[2],
        y2 = rect[4],
        index = 1,
        between_x = rect[1],
        orientation = 'vertical',
      }
    end
    
    local next_entry = sequential_items[i + 1]
    if next_entry then
      local next_rect = next_entry.rect
      local next_midx = (next_rect[1] + next_rect[3]) * 0.5
      
      local same_row = not (rect[4] < next_rect[2] or next_rect[4] < rect[2])
      
      if same_row then
        local between_x = (rect[3] + next_rect[1]) * 0.5
        zones[#zones + 1] = {
          x1 = midx,
          x2 = next_midx,
          y1 = math.min(rect[2], next_rect[2]),
          y2 = math.max(rect[4], next_rect[4]),
          index = i + 1,
          between_x = between_x,
          orientation = 'vertical',
        }
      else
        zones[#zones + 1] = {
          x1 = midx,
          x2 = right_bound,
          y1 = rect[2],
          y2 = rect[4],
          index = i + 1,
          between_x = rect[3],
          orientation = 'vertical',
        }
        
        zones[#zones + 1] = {
          x1 = left_bound,
          x2 = next_midx,
          y1 = next_rect[2],
          y2 = next_rect[4],
          index = i + 1,
          between_x = next_rect[1],
          orientation = 'vertical',
        }
      end
    else
      zones[#zones + 1] = {
        x1 = midx,
        x2 = right_bound,
        y1 = rect[2],
        y2 = rect[4],
        index = i + 1,
        between_x = rect[3],
        orientation = 'vertical',
      }
    end
  end
  
  return zones
end

local function find_zone_at_point(zones, mx, my)
  for _, zone in ipairs(zones) do
    if mx >= zone.x1 and mx <= zone.x2 and my >= zone.y1 and my <= zone.y2 then
      if zone.orientation == 'horizontal' then
        return zone.index, zone.between_y, zone.x1, zone.x2, zone.orientation
      else
        return zone.index, zone.between_x, zone.y1, zone.y2, zone.orientation
      end
    end
  end
  return nil, nil, nil, nil, nil
end

function M.find_drop_target(mx, my, items, key_fn, dragged_set, rect_track, is_single_column, grid_bounds)
  local non_dragged = build_non_dragged_items(items, key_fn, dragged_set, rect_track)
  
  if #non_dragged == 0 then
    if grid_bounds then
      local orientation = is_single_column and 'horizontal' or 'vertical'
      local x1, y1, x2, y2 = grid_bounds[1], grid_bounds[2], grid_bounds[3], grid_bounds[4]
      
      if orientation == 'horizontal' then
        local between_y = y1 + 20
        return 1, between_y, x1, x2, orientation
      else
        local between_x = x1 + 20
        return 1, between_x, y1, y2, orientation
      end
    end
    
    return 1, nil, nil, nil, nil
  end
  
  local zones
  if is_single_column then
    zones = create_horizontal_drop_zones(non_dragged, grid_bounds)
  else
    zones = create_vertical_drop_zones(non_dragged, grid_bounds)
  end
  
  return find_zone_at_point(zones, mx, my)
end

function M.find_external_drop_target(mx, my, items, key_fn, rect_track, is_single_column, grid_bounds)
  return M.find_drop_target(mx, my, items, key_fn, {}, rect_track, is_single_column, grid_bounds)
end

function M.build_dragged_set(dragged_ids)
  local set = {}
  if not dragged_ids then return set end
  for _, id in ipairs(dragged_ids) do
    set[id] = true
  end
  return set
end

return M