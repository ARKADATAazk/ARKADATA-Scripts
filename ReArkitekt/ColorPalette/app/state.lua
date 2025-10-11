-- ReArkitekt/ColorPalette/app/state.lua
-- State management and color palette calculation

local Colors = require('ReArkitekt.core.colors')

local M = {}

-- Target types for color application
M.TARGET_TYPES = {
  "Tracks",
  "Items", 
  "Takes",
  "Take Markers",
  "Markers",
  "Regions"
}

-- Action types
M.ACTION_TYPES = {
  "Default",
  "Random All",
  "Random Each",
  "In Order"
}

-- Default state
local DEFAULTS = {
  palette = {
    cols = 15,
    rows = 3,
    hue = 0,
    sat = {0.26, 0.50},
    lum = {0.71, 0.50},
    include_grey = true,
    spacing = 1,
  },
  target_index = 1,  -- Tracks
  action_index = 1,  -- Default
  auto_close = false,
  set_children = false,
}

local state = {
  palette = {},
  target_index = 1,
  action_index = 1,
  auto_close = false,
  set_children = false,
  settings = nil,
  palette_colors = {},
}

function M.initialize(settings)
  state.settings = settings
  
  -- Load palette config
  state.palette.cols = settings:get("palette.cols", DEFAULTS.palette.cols)
  state.palette.rows = settings:get("palette.rows", DEFAULTS.palette.rows)
  state.palette.hue = settings:get("palette.hue", DEFAULTS.palette.hue)
  state.palette.sat = settings:get("palette.sat", DEFAULTS.palette.sat)
  state.palette.lum = settings:get("palette.lum", DEFAULTS.palette.lum)
  state.palette.include_grey = settings:get("palette.include_grey", DEFAULTS.palette.include_grey)
  state.palette.spacing = settings:get("palette.spacing", DEFAULTS.palette.spacing)
  
  -- Load UI state
  state.target_index = settings:get("target_index", DEFAULTS.target_index)
  state.action_index = settings:get("action_index", DEFAULTS.action_index)
  state.auto_close = settings:get("auto_close", DEFAULTS.auto_close)
  state.set_children = settings:get("set_children", DEFAULTS.set_children)
  
  -- Calculate initial palette
  M.recalculate_palette()
end

function M.recalculate_palette()
  state.palette_colors = {}
  
  local cols = state.palette.cols
  local rows = state.palette.rows
  local base_hue = state.palette.hue
  local sat_points = state.palette.sat
  local lum_points = state.palette.lum
  local include_grey = state.palette.include_grey
  
  for row = 0, rows - 1 do
    for col = 0, cols - 1 do
      local hue, sat, lum
      
      -- Calculate hue
      if include_grey and col == 0 then
        hue = 0
        sat = 0
      else
        local hue_col = include_grey and (col - 1) or col
        local hue_range = include_grey and (cols - 1) or cols
        hue = (hue_col / hue_range + base_hue) % 1.0
      end
      
      -- Calculate saturation and luminance using gradient points
      local t = rows > 1 and (row / (rows - 1)) or 0
      
      -- Linear interpolation between gradient points
      if #sat_points == 2 then
        sat = sat_points[1] + (sat_points[2] - sat_points[1]) * t
      else
        sat = sat_points[1] or 0.5
      end
      
      if #lum_points == 2 then
        lum = lum_points[1] + (lum_points[2] - lum_points[1]) * t
      else
        lum = lum_points[1] or 0.5
      end
      
      -- Force grey column to zero saturation
      if include_grey and col == 0 then
        sat = 0
      end
      
      -- Convert HSL to RGB
      local r, g, b = Colors.hsl_to_rgb(hue, sat, lum)
      local color = Colors.components_to_rgba(r, g, b, 0xFF)
      
      table.insert(state.palette_colors, color)
    end
  end
end

function M.get_palette_colors()
  return state.palette_colors
end

function M.get_palette_config()
  return state.palette
end

function M.get_target_type()
  return M.TARGET_TYPES[state.target_index]
end

function M.set_target_type(index)
  state.target_index = index
  if state.settings then
    state.settings:set("target_index", index)
  end
end

function M.get_action_type()
  return M.ACTION_TYPES[state.action_index]
end

function M.set_action_type(index)
  state.action_index = index
  if state.settings then
    state.settings:set("action_index", index)
  end
end

function M.set_auto_close(value)
  state.auto_close = value
  if state.settings then
    state.settings:set("auto_close", value)
  end
end

function M.get_auto_close()
  return state.auto_close
end

function M.set_children(value)
  state.set_children = value
  if state.settings then
    state.settings:set("set_children", value)
  end
end

function M.get_set_children()
  return state.set_children
end

function M.update_palette_hue(hue)
  state.palette.hue = hue
  if state.settings then
    state.settings:set("palette.hue", hue)
  end
  M.recalculate_palette()
end

function M.update_palette_sat(sat_array)
  state.palette.sat = sat_array
  if state.settings then
    state.settings:set("palette.sat", sat_array)
  end
  M.recalculate_palette()
end

function M.update_palette_lum(lum_array)
  state.palette.lum = lum_array
  if state.settings then
    state.settings:set("palette.lum", lum_array)
  end
  M.recalculate_palette()
end

function M.update_palette_grey(include_grey)
  state.palette.include_grey = include_grey
  if state.settings then
    state.settings:set("palette.include_grey", include_grey)
  end
  M.recalculate_palette()
end

function M.update_palette_size(cols, rows)
  if cols then 
    state.palette.cols = cols
    if state.settings then
      state.settings:set("palette.cols", cols)
    end
  end
  if rows then 
    state.palette.rows = rows
    if state.settings then
      state.settings:set("palette.rows", rows)
    end
  end
  M.recalculate_palette()
end

function M.update_palette_spacing(spacing)
  state.palette.spacing = spacing
  if state.settings then
    state.settings:set("palette.spacing", spacing)
  end
end

function M.restore_default_colors()
  state.palette.hue = DEFAULTS.palette.hue
  state.palette.sat = {DEFAULTS.palette.sat[1], DEFAULTS.palette.sat[2]}
  state.palette.lum = {DEFAULTS.palette.lum[1], DEFAULTS.palette.lum[2]}
  state.palette.include_grey = DEFAULTS.palette.include_grey
  
  if state.settings then
    state.settings:set("palette.hue", state.palette.hue)
    state.settings:set("palette.sat", state.palette.sat)
    state.settings:set("palette.lum", state.palette.lum)
    state.settings:set("palette.include_grey", state.palette.include_grey)
  end
  
  M.recalculate_palette()
end

function M.restore_default_sizes()
  state.palette.cols = DEFAULTS.palette.cols
  state.palette.rows = DEFAULTS.palette.rows
  state.palette.spacing = DEFAULTS.palette.spacing
  
  if state.settings then
    state.settings:set("palette.cols", state.palette.cols)
    state.settings:set("palette.rows", state.palette.rows)
    state.settings:set("palette.spacing", state.palette.spacing)
  end
  
  M.recalculate_palette()
end

function M.save()
  if state.settings and state.settings.flush then
    state.settings:flush()
  end
end

return M