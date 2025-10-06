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