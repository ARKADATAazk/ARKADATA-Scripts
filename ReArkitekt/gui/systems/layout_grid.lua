-- ReArkitekt/gui/systems/layout_grid.lua
-- Pure grid layout calculation - no ImGui dependencies
-- Distributes extra width evenly across columns

local M = {}

-- Calculate grid layout with even distribution of extra space
-- Inputs:
--   avail_w: available width in pixels
--   min_col_w: minimum column width
--   gap: gap between items
--   n_items: number of items to lay out
--   origin_x, origin_y: top-left origin
--   fixed_tile_h: (optional) if provided, use this height instead of calculating from width
-- Returns:
--   cols: number of columns
--   rows: number of rows  
--   rects: array of {x1, y1, x2, y2, index} in screen coordinates
function M.calculate(avail_w, min_col_w, gap, n_items, origin_x, origin_y, fixed_tile_h)
  avail_w = math.max(0, avail_w or 0)
  min_col_w = math.max(80, min_col_w or 160)
  gap = math.max(0, gap or 12)
  n_items = math.max(0, n_items or 0)
  origin_x = origin_x or 0
  origin_y = origin_y or 0
  
  if n_items == 0 then
    return 0, 0, {}
  end
  
  -- Calculate max columns that fit
  local cols = math.max(1, math.floor((avail_w + gap) / (min_col_w + gap)))
  cols = math.min(cols, n_items)
  
  -- Calculate actual column width with distributed extra space
  local inner_w = math.max(0, avail_w - gap * (cols + 1))
  local base_w_total = min_col_w * cols
  local extra = inner_w - base_w_total
  
  local base_w = min_col_w
  if cols == 1 then
    -- Single column takes all available width
    base_w = math.max(80, inner_w)
    extra = 0
  end
  
  -- Distribute extra width evenly, with remainder going to first columns
  local per_col_add = (cols > 0) and math.floor(math.max(0, extra) / cols) or 0
  local remainder = (cols > 0) and math.max(0, extra - per_col_add * cols) or 0
  
  -- Calculate tile height
  local tile_h
  if fixed_tile_h then
    tile_h = math.floor(fixed_tile_h + 0.5)
  else
    tile_h = math.floor((base_w + per_col_add) * 0.65)
  end
  
  -- Calculate rows
  local rows = math.ceil(n_items / cols)
  
  -- Generate rectangles
  local rects = {}
  local x = origin_x + gap
  local y = origin_y + gap
  local col = 1
  
  for idx = 1, n_items do
    -- This column gets extra pixel if within remainder
    local col_w = base_w + per_col_add + ((col <= remainder) and 1 or 0)
    col_w = math.floor(col_w + 0.5)
    
    -- Integer-snap coordinates for crisp rendering
    local x1 = math.floor(x + 0.5)
    local y1 = math.floor(y + 0.5)
    local x2 = x1 + col_w
    local y2 = y1 + tile_h
    
    rects[idx] = {x1, y1, x2, y2, idx}
    
    -- Move to next position
    x = x + col_w + gap
    col = col + 1
    if col > cols then
      col = 1
      x = origin_x + gap
      y = y + tile_h + gap
    end
  end
  
  return cols, rows, rects
end

-- Get total grid height
function M.get_height(rows, tile_h, gap)
  if rows <= 0 then return 0 end
  return rows * (tile_h + gap) + gap
end

return M