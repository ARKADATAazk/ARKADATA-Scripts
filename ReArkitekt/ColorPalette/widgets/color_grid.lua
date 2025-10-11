-- ReArkitekt/ColorPalette/widgets/color_grid.lua
-- Simple color button grid widget with drag-to-move support

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local Colors = require('ReArkitekt.core.colors')
local Draw = require('ReArkitekt.gui.draw')

local M = {}

local ColorGrid = {}
ColorGrid.__index = ColorGrid

function M.new()
  local grid = setmetatable({
    hover_color_index = nil,
    hover_alpha = 0,
  }, ColorGrid)
  
  return grid
end

function ColorGrid:calculate_tile_size(ctx, num_colors, cols, spacing)
  local avail_w, avail_h = ImGui.GetContentRegionAvail(ctx)
  
  local rows = math.ceil(num_colors / cols)
  
  local total_spacing_w = (cols - 1) * spacing
  local total_spacing_h = (rows - 1) * spacing
  
  local tile_w = math.floor((avail_w - total_spacing_w) / cols)
  local tile_h = math.floor((avail_h - total_spacing_h) / rows)
  
  local tile_size = math.min(tile_w, tile_h)
  tile_size = math.max(tile_size, 24)
  
  return tile_size
end

function ColorGrid:draw(ctx, colors, config, allow_interaction)
  -- Default to allowing interaction if not specified
  if allow_interaction == nil then
    allow_interaction = true
  end
  
  if not colors or #colors == 0 then
    ImGui.Text(ctx, "No colors to display")
    return nil
  end
  
  local cols = config.cols or 15
  local spacing = config.spacing or 1
  
  local tile_size = self:calculate_tile_size(ctx, #colors, cols, spacing)
  local rounding = 4
  
  local origin_x, origin_y = ImGui.GetCursorScreenPos(ctx)
  local dl = ImGui.GetWindowDrawList(ctx)
  
  local clicked_color = nil
  local mx, my = ImGui.GetMousePos(ctx)
  
  -- Update hover alpha
  local dt = ImGui.GetDeltaTime(ctx)
  local alpha_speed = 8.0
  local target_alpha = (self.hover_color_index and allow_interaction) and 1.0 or 0.0
  self.hover_alpha = self.hover_alpha + (target_alpha - self.hover_alpha) * alpha_speed * dt
  self.hover_alpha = math.max(0, math.min(1, self.hover_alpha))
  
  -- Draw all color tiles
  for i, color in ipairs(colors) do
    local col_idx = (i - 1) % cols
    local row_idx = math.floor((i - 1) / cols)
    
    local x = origin_x + col_idx * (tile_size + spacing)
    local y = origin_y + row_idx * (tile_size + spacing)
    
    local x1, y1 = x, y
    local x2, y2 = x + tile_size, y + tile_size
    
    -- Check if mouse is hovering this tile
    local is_hovered = allow_interaction and mx >= x1 and mx < x2 and my >= y1 and my < y2
    
    if is_hovered then
      self.hover_color_index = i
    end
    
    -- Use full color directly
    local fill_color = color
    local border_color = Colors.with_alpha(color, 0xFF)
    
    -- Apply hover brightening
    if is_hovered and self.hover_alpha > 0.01 then
      fill_color = Colors.lerp(fill_color, Colors.adjust_brightness(color, 1.2), self.hover_alpha)
    end
    
    -- Draw hover shadow
    if is_hovered and self.hover_alpha > 0.1 then
      local shadow_alpha = math.floor(self.hover_alpha * 30)
      local shadow_color = (0x000000 << 8) | shadow_alpha
      
      for offset = 2, 1, -1 do
        Draw.rect_filled(dl, x1 - offset, y1 - offset, x2 + offset, y2 + offset, shadow_color, rounding)
      end
    end
    
    -- Draw tile fill
    Draw.rect_filled(dl, x1, y1, x2, y2, fill_color, rounding)
    
    -- Draw black border (1px)
    Draw.rect(dl, x1, y1, x2, y2, 0x000000FF, rounding, 1)
    
    -- Draw color border on top for hover effect
    if is_hovered then
      Draw.rect(dl, x1, y1, x2, y2, border_color, rounding, 2)
    end
    
    -- Create invisible button for interaction
    ImGui.SetCursorScreenPos(ctx, x1, y1)
    ImGui.InvisibleButton(ctx, "##color_" .. i, tile_size, tile_size)
    
    -- Only process clicks if interaction is allowed
    if allow_interaction and ImGui.IsItemClicked(ctx, 0) then
      clicked_color = color
    end
    
    -- Tooltip with hex color (only when interaction allowed)
    if allow_interaction and ImGui.IsItemHovered(ctx) then
      ImGui.SetTooltip(ctx, string.format("#%06X", color >> 8))
    end
  end
  
  -- Reset hover if mouse is not over any tile
  if not ImGui.IsAnyItemHovered(ctx) then
    self.hover_color_index = nil
  end
  
  return clicked_color
end

return M