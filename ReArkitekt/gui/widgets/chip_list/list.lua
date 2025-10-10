-- ReArkitekt/gui/widgets/chip_list/list.lua
-- Chip list container with multiple layout modes

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local Chip = require('ReArkitekt.gui.widgets.component.chip')
local ResponsiveGrid = require('ReArkitekt.gui.systems.responsive_grid')

local M = {}

local function _filter_items(items, search_text)
  if search_text == "" then return items end
  local filtered = {}
  for _, item in ipairs(items) do
    if item.label:lower():find(search_text:lower(), 1, true) then
      filtered[#filtered + 1] = item
    end
  end
  return filtered
end

local function _draw_chip(ctx, item, is_selected, opts)
  return Chip.draw(ctx, {
    style = opts.style,
    label = item.label,
    color = item.color,
    height = opts.chip_height,
    is_selected = is_selected,
    bg_color = opts.bg_color,
    dot_size = opts.dot_size,
    dot_spacing = opts.dot_spacing,
    rounding = opts.rounding,
    padding_h = opts.padding_h,
    explicit_width = opts.explicit_width,
    text_align = opts.text_align,
  })
end

function M.draw(ctx, items, opts)
  opts = opts or {}
  local filtered = _filter_items(items, opts.search_text or "")
  if #filtered == 0 then return nil end
  
  local chip_spacing = opts.chip_spacing or 8
  local line_spacing = opts.line_spacing or 8
  local text_h = ImGui.GetTextLineHeight(ctx)
  local chip_height = opts.chip_height or (text_h + 6)
  local available_width = opts.max_width or ImGui.GetContentRegionAvail(ctx)
  local selected_ids = opts.selected_ids or {}
  local style = opts.use_dot_style and Chip.STYLE.DOT or Chip.STYLE.PILL
  local justified = opts.justified or false
  
  local clicked_id = nil
  local draw_opts = {
    style = style,
    chip_height = chip_height,
    bg_color = opts.bg_color,
    dot_size = opts.dot_size,
    dot_spacing = opts.dot_spacing,
    rounding = opts.rounding or 4,
    padding_h = opts.padding_h or (style == Chip.STYLE.DOT and 12 or 14),
  }
  
  if justified then
    local min_widths = {}
    for i, item in ipairs(filtered) do
      min_widths[i] = Chip.calculate_width(ctx, item.label, draw_opts)
    end
    
    local layout = ResponsiveGrid.calculate_justified_layout(filtered, {
      available_width = available_width,
      min_widths = min_widths,
      gap = chip_spacing,
      max_stretch_ratio = opts.max_stretch_ratio or 1.5,
    })
    
    local row_start_x = ImGui.GetCursorPosX(ctx)
    
    for row_idx, row in ipairs(layout) do
      if row_idx > 1 then ImGui.SetCursorPosX(ctx, row_start_x) end
      
      for cell_idx, cell in ipairs(row) do
        draw_opts.explicit_width = cell.final_width
        local clicked = _draw_chip(ctx, cell.item, selected_ids[cell.item.id], draw_opts)
        if clicked then clicked_id = cell.item.id end
        if cell_idx < #row then ImGui.SameLine(ctx, 0, chip_spacing) end
      end
      
      if row_idx < #layout then ImGui.Dummy(ctx, 0, line_spacing) end
    end
  else
    local cursor_start_x = ImGui.GetCursorPosX(ctx)
    local current_x = 0
    local items_in_row = 0
    
    for _, item in ipairs(filtered) do
      local chip_width = Chip.calculate_width(ctx, item.label, draw_opts)
      local space_needed = chip_width + (items_in_row > 0 and chip_spacing or 0)
      
      if items_in_row > 0 and (current_x + space_needed) > available_width then
        ImGui.Dummy(ctx, 0, line_spacing)
        ImGui.SetCursorPosX(ctx, cursor_start_x)
        current_x = 0
        items_in_row = 0
      end
      
      if items_in_row > 0 then
        ImGui.SameLine(ctx, 0, chip_spacing)
        current_x = current_x + chip_spacing
      end
      
      draw_opts.explicit_width = nil
      local clicked = _draw_chip(ctx, item, selected_ids[item.id], draw_opts)
      if clicked then clicked_id = item.id end
      
      current_x = current_x + chip_width
      items_in_row = items_in_row + 1
    end
  end
  
  return clicked_id
end

function M.draw_vertical(ctx, items, opts)
  opts = opts or {}
  local filtered = _filter_items(items, opts.search_text or "")
  if #filtered == 0 then return nil end
  
  local item_height = opts.item_height or 28
  local selected_ids = opts.selected_ids or {}
  local style = (opts.use_dot_style ~= false) and Chip.STYLE.DOT or Chip.STYLE.PILL
  
  local clicked_id = nil
  local draw_opts = {
    style = style,
    chip_height = item_height,
    bg_color = opts.bg_color,
    dot_size = opts.dot_size,
    dot_spacing = opts.dot_spacing,
    rounding = opts.rounding or 4,
    padding_h = opts.padding_h or 12,
  }
  
  for _, item in ipairs(filtered) do
    local clicked = _draw_chip(ctx, item, selected_ids[item.id], draw_opts)
    if clicked then clicked_id = item.id end
    ImGui.Dummy(ctx, 0, 4)
  end
  
  return clicked_id
end

function M.draw_columns(ctx, items, opts)
  opts = opts or {}
  local filtered = _filter_items(items, opts.search_text or "")
  if #filtered == 0 then return nil end
  
  local selected_ids = opts.selected_ids or {}
  local style = opts.use_dot_style and Chip.STYLE.DOT or Chip.STYLE.PILL
  local column_width = opts.column_width or 200
  local column_spacing = opts.column_spacing or 20
  local item_spacing = opts.item_spacing or 4
  local text_h = ImGui.GetTextLineHeight(ctx)
  local item_height = opts.item_height or (text_h + 8)
  
  local clicked_id = nil
  local draw_opts = {
    style = style,
    chip_height = item_height,
    bg_color = opts.bg_color,
    dot_size = opts.dot_size or 8,
    dot_spacing = opts.dot_spacing or 10,
    rounding = opts.rounding or 4,
    padding_h = opts.padding_h or 12,
    explicit_width = column_width,
    text_align = "left",
  }
  
  local avail_w, avail_h = ImGui.GetContentRegionAvail(ctx)
  local max_height = opts.max_height or avail_h
  local items_per_column = math.floor(max_height / (item_height + item_spacing))
  if items_per_column < 1 then items_per_column = 1 end
  
  local num_columns = math.ceil(#filtered / items_per_column)
  local start_x = ImGui.GetCursorPosX(ctx)
  local start_y = ImGui.GetCursorPosY(ctx)
  
  for col = 0, num_columns - 1 do
    for row = 0, items_per_column - 1 do
      local idx = col * items_per_column + row + 1
      if idx > #filtered then break end
      
      ImGui.SetCursorPos(ctx, 
        start_x + col * (column_width + column_spacing), 
        start_y + row * (item_height + item_spacing))
      
      local clicked = _draw_chip(ctx, filtered[idx], selected_ids[filtered[idx].id], draw_opts)
      if clicked then clicked_id = filtered[idx].id end
    end
  end
  
  local total_height = math.min(#filtered, items_per_column) * (item_height + item_spacing)
  local total_width = num_columns * (column_width + column_spacing) - column_spacing
  ImGui.SetCursorPos(ctx, start_x, start_y + total_height)
  ImGui.Dummy(ctx, total_width, 0)
  
  return clicked_id
end

function M.draw_grid(ctx, items, opts)
  opts = opts or {}
  local filtered = _filter_items(items, opts.search_text or "")
  if #filtered == 0 then return nil end
  
  local avail_width = opts.width or ImGui.GetContentRegionAvail(ctx)
  local cols = opts.cols or 3
  local gap = opts.gap or 8
  local selected_ids = opts.selected_ids or {}
  local style = opts.use_dot_style and Chip.STYLE.DOT or Chip.STYLE.PILL
  local justified = opts.justified or false
  local text_h = ImGui.GetTextLineHeight(ctx)
  local chip_height = opts.chip_height or (text_h + 6)
  
  local clicked_id = nil
  local draw_opts = {
    style = style,
    chip_height = chip_height,
    bg_color = opts.bg_color,
    dot_size = opts.dot_size or 7,
    dot_spacing = opts.dot_spacing or 7,
    rounding = opts.rounding or 5,
    padding_h = opts.padding_h or 8,
  }
  
  if justified then
    local min_widths = {}
    for i, item in ipairs(filtered) do
      min_widths[i] = Chip.calculate_width(ctx, item.label, draw_opts)
    end
    
    local layout = ResponsiveGrid.calculate_justified_layout(filtered, {
      available_width = avail_width,
      min_widths = min_widths,
      gap = gap,
      max_stretch_ratio = opts.max_stretch_ratio or 1.4,
    })
    
    local row_start_x = ImGui.GetCursorPosX(ctx)
    
    for row_idx, row in ipairs(layout) do
      if row_idx > 1 then ImGui.SetCursorPosX(ctx, row_start_x) end
      
      for cell_idx, cell in ipairs(row) do
        if cell_idx > 1 then ImGui.SameLine(ctx, 0, gap) end
        
        draw_opts.explicit_width = cell.final_width
        local clicked = _draw_chip(ctx, cell.item, selected_ids[cell.item.id], draw_opts)
        if clicked then clicked_id = cell.item.id end
      end
      
      if row_idx < #layout then ImGui.Dummy(ctx, 0, gap) end
    end
  else
    local row_start_x = ImGui.GetCursorPosX(ctx)
    local col_width = (avail_width - (cols - 1) * gap) / cols
    draw_opts.explicit_width = col_width
    
    for i, item in ipairs(filtered) do
      local col = ((i - 1) % cols)
      
      if col > 0 then
        ImGui.SameLine(ctx, 0, gap)
      elseif i > 1 then
        ImGui.Dummy(ctx, 0, gap)
        ImGui.SetCursorPosX(ctx, row_start_x)
      end
      
      local clicked = _draw_chip(ctx, item, selected_ids[item.id], draw_opts)
      if clicked then clicked_id = item.id end
    end
  end
  
  return clicked_id
end

function M.draw_auto(ctx, items, opts)
  opts = opts or {}
  local layout_mode = opts.layout_mode or "flow"
  
  if layout_mode == "columns" then
    return M.draw_columns(ctx, items, opts)
  elseif layout_mode == "grid" then
    return M.draw_grid(ctx, items, opts)
  elseif layout_mode == "vertical" then
    return M.draw_vertical(ctx, items, opts)
  else
    return M.draw(ctx, items, opts)
  end
end

return M