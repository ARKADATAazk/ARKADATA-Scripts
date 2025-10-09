-- ReArkitekt/gui/systems/responsive_grid.lua
-- Responsive tile sizing calculations for grid widgets
-- Extracted from region_tiles/coordinator.lua to enable reuse

local M = {}

function M.calculate_scaled_gap(tile_height, base_gap, base_height, min_height, responsive_config)
  local gap_config = responsive_config and responsive_config.gap_scaling
  if not gap_config or not gap_config.enabled then
    return base_gap
  end
  
  local min_gap = gap_config.min_gap or 2
  local max_gap = gap_config.max_gap or base_gap
  
  local height_range = base_height - min_height
  if height_range <= 0 then return base_gap end
  
  local height_factor = (tile_height - min_height) / height_range
  height_factor = math.min(1.0, math.max(0.0, height_factor))
  
  local scaled_gap = min_gap + (max_gap - min_gap) * height_factor
  return math.max(min_gap, math.floor(scaled_gap))
end

function M.calculate_responsive_tile_height(opts)
  local item_count = opts.item_count or 0
  local avail_width = opts.avail_width or 0
  local avail_height = opts.avail_height or 0
  local base_gap = opts.base_gap or 12
  local min_col_width = opts.min_col_width or 110
  local base_tile_height = opts.base_tile_height or 72
  local min_tile_height = opts.min_tile_height or 20
  local responsive_config = opts.responsive_config or {}
  
  if not responsive_config.enabled or item_count == 0 then 
    return base_tile_height, base_gap
  end
  
  local scrollbar_buffer = responsive_config.scrollbar_buffer or 24
  local safe_width = avail_width - scrollbar_buffer
  
  local cols = math.max(1, math.floor((safe_width + base_gap) / (min_col_width + base_gap)))
  local rows = math.ceil(item_count / cols)
  
  local total_gap_height = (rows + 1) * base_gap
  local available_for_tiles = avail_height - total_gap_height
  
  if available_for_tiles <= 0 then return base_tile_height, base_gap end
  
  local needed_height = rows * base_tile_height
  
  if needed_height <= available_for_tiles then
    return base_tile_height, base_gap
  end
  
  local scaled_height = math.floor(available_for_tiles / rows)
  local final_height = math.max(min_tile_height, scaled_height)
  
  local round_to = responsive_config.round_to_multiple or 2
  final_height = math.floor((final_height + round_to - 1) / round_to) * round_to
  
  local final_gap = M.calculate_scaled_gap(final_height, base_gap, base_tile_height, min_tile_height, responsive_config)
  
  return final_height, final_gap
end

function M.calculate_grid_metrics(opts)
  local item_count = opts.item_count or 0
  local avail_width = opts.avail_width or 0
  local base_gap = opts.base_gap or 12
  local min_col_width = opts.min_col_width or 110
  local tile_height = opts.tile_height or 72
  
  if item_count == 0 then
    return {
      cols = 0,
      rows = 0,
      total_width = 0,
      total_height = 0,
      tile_width = min_col_width,
      tile_height = tile_height,
    }
  end
  
  local cols = math.max(1, math.floor((avail_width + base_gap) / (min_col_width + base_gap)))
  local rows = math.ceil(item_count / cols)
  
  local inner_width = math.max(0, avail_width - base_gap * (cols + 1))
  local tile_width = math.floor(inner_width / cols)
  
  local total_width = cols * tile_width + (cols + 1) * base_gap
  local total_height = rows * tile_height + (rows + 1) * base_gap
  
  return {
    cols = cols,
    rows = rows,
    total_width = total_width,
    total_height = total_height,
    tile_width = tile_width,
    tile_height = tile_height,
  }
end

function M.calculate_justified_layout(items, opts)
  local available_width = opts.available_width or 0
  local min_widths = opts.min_widths or {}
  local gap = opts.gap or 8
  local max_stretch_ratio = opts.max_stretch_ratio or 1.5
  
  if #items == 0 or available_width <= 0 then
    return {}
  end
  
  local rows = {}
  local current_row = {}
  local current_row_width = 0
  
  for i, item in ipairs(items) do
    local min_width = min_widths[i] or 0
    local needed_width = current_row_width + min_width + (#current_row > 0 and gap or 0)
    
    if #current_row > 0 and needed_width > available_width then
      table.insert(rows, current_row)
      current_row = {}
      current_row_width = 0
    end
    
    table.insert(current_row, {
      index = i,
      item = item,
      min_width = min_width,
    })
    current_row_width = current_row_width + min_width + (#current_row > 1 and gap or 0)
  end
  
  if #current_row > 0 then
    table.insert(rows, current_row)
  end
  
  local layout = {}
  
  for row_idx, row in ipairs(rows) do
    local total_min_width = 0
    for _, cell in ipairs(row) do
      total_min_width = total_min_width + cell.min_width
    end
    
    local total_gap_width = (#row - 1) * gap
    local used_width = total_min_width + total_gap_width
    local extra_width = available_width - used_width
    
    local is_last_row = (row_idx == #rows)
    local should_justify = not is_last_row or #row >= 3
    
    if extra_width > 0 and should_justify then
      local max_allowed_extra = total_min_width * (max_stretch_ratio - 1.0)
      extra_width = math.min(extra_width, max_allowed_extra)
      
      local width_per_item = extra_width / #row
      local distributed = 0
      local accumulated_error = 0
      
      for i, cell in ipairs(row) do
        local ideal_width = cell.min_width + width_per_item
        local floored_width = math.floor(ideal_width)
        
        accumulated_error = accumulated_error + (ideal_width - floored_width)
        
        if accumulated_error >= 1.0 then
          floored_width = floored_width + 1
          accumulated_error = accumulated_error - 1.0
        end
        
        cell.final_width = floored_width
        distributed = distributed + floored_width
      end
      
      local total_with_gaps = distributed + total_gap_width
      if total_with_gaps > available_width then
        local overflow = total_with_gaps - available_width
        for i = #row, 1, -1 do
          if overflow <= 0 then break end
          local can_reduce = math.min(overflow, row[i].final_width - row[i].min_width)
          if can_reduce > 0 then
            row[i].final_width = row[i].final_width - can_reduce
            overflow = overflow - can_reduce
          end
        end
      elseif total_with_gaps < available_width then
        local remaining = available_width - total_with_gaps
        row[#row].final_width = row[#row].final_width + remaining
      end
    else
      for _, cell in ipairs(row) do
        cell.final_width = cell.min_width
      end
    end
    
    table.insert(layout, row)
  end
  
  return layout
end

function M.should_show_scrollbar(grid_height, available_height, buffer)
  buffer = buffer or 24
  return grid_height > (available_height - buffer)
end

function M.create_default_config()
  return {
    enabled = true,
    min_tile_height = 20,
    base_tile_height = 72,
    scrollbar_buffer = 24,
    height_hysteresis = 12,
    stable_frames_required = 2,
    round_to_multiple = 2,
    gap_scaling = {
      enabled = true,
      min_gap = 2,
      max_gap = 12,
    },
  }
end

return M