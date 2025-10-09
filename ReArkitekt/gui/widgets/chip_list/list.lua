-- ReArkitekt/gui/widgets/chip_list/list.lua
-- Chip list container with search/filter and justified layout

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local Chip = require('ReArkitekt.gui.widgets.chip_list.chip')
local ResponsiveGrid = require('ReArkitekt.gui.systems.responsive_grid')

local M = {}

function M.draw(ctx, items, opts)
  opts = opts or {}
  local chip_spacing   = opts.chip_spacing or 8
  local line_spacing   = opts.line_spacing or 8
  local text_h         = ImGui.GetTextLineHeight(ctx)
  local chip_height    = opts.chip_height or (text_h + 6)
  local available_width= opts.max_width or ImGui.GetContentRegionAvail(ctx)
  local selected_ids   = opts.selected_ids or {}
  local search_text    = opts.search_text or ""
  local use_dot_style  = opts.use_dot_style or false
  local justified      = opts.justified or false

  local clicked_id = nil

  -- Filter
  local filtered_items = {}
  for i, item in ipairs(items) do
    if search_text == "" or item.label:lower():find(search_text:lower(), 1, true) then
      filtered_items[#filtered_items+1] = item
    end
  end
  if #filtered_items == 0 then return nil end

  if justified then
    -- Precompute minimum widths for each chip
    local min_widths = {}
    for i, item in ipairs(filtered_items) do
      local chip_opts = {
        padding_h     = opts.padding_h or 14,
        dot_size      = opts.dot_size or 8,
        dot_spacing   = opts.dot_spacing or 10,
        use_dot_style = use_dot_style,
      }
      min_widths[i] = Chip.calculate_min_width(ctx, item.label, chip_opts)
    end

    local layout = ResponsiveGrid.calculate_justified_layout(filtered_items, {
      available_width   = available_width,
      min_widths        = min_widths,
      gap               = chip_spacing,
      max_stretch_ratio = opts.max_stretch_ratio or 1.5,
    })

    -- Keep rows aligned to the same X
    local row_start_x = ImGui.GetCursorPosX(ctx)

    for row_idx, row in ipairs(layout) do
      if row_idx > 1 then
        ImGui.SetCursorPosX(ctx, row_start_x)
      end

      for cell_idx, cell in ipairs(row) do
        local item        = cell.item
        local is_selected = selected_ids[item.id] or false

        local chip_opts = {
          height       = chip_height,
          is_selected  = is_selected,
          bg_color     = opts.bg_color,
          dot_size     = opts.dot_size,
          dot_spacing  = opts.dot_spacing,
          rounding     = opts.rounding or 4,
          explicit_width = cell.final_width,
        }

        local clicked
        if use_dot_style then
          clicked = select(1, Chip.draw_with_dot(ctx, item.label, item.color, chip_opts))
        else
          clicked = select(1, Chip.draw(ctx, item.label, item.color, chip_opts))
        end
        if clicked then clicked_id = item.id end

        if cell_idx < #row then
          ImGui.SameLine(ctx, 0, chip_spacing)
        end
      end

      if row_idx < #layout then
        ImGui.Dummy(ctx, 0, line_spacing)
      end
    end
  else
    -- Flow layout with wrap - FIXED VERSION
    local cursor_start_x = ImGui.GetCursorPosX(ctx)
    local current_x = 0
    local row_count = 0
    local items_in_row = 0

    for i, item in ipairs(filtered_items) do
      local is_selected = selected_ids[item.id] or false
      
      -- Calculate this chip's width
      local chip_width = Chip.calculate_min_width(ctx, item.label, {
        padding_h     = opts.padding_h or 14,
        dot_size      = opts.dot_size or 8,
        dot_spacing   = opts.dot_spacing or 10,
        use_dot_style = use_dot_style,
      })
      
      -- Check if we need to wrap
      local space_needed = chip_width
      if items_in_row > 0 then
        space_needed = space_needed + chip_spacing
      end
      
      if items_in_row > 0 and (current_x + space_needed) > available_width then
        -- Start new line
        ImGui.Dummy(ctx, 0, line_spacing)
        ImGui.SetCursorPosX(ctx, cursor_start_x)
        current_x = 0
        items_in_row = 0
        row_count = row_count + 1
      end
      
      -- Add spacing before chip if not first in row
      if items_in_row > 0 then
        ImGui.SameLine(ctx, 0, chip_spacing)
        current_x = current_x + chip_spacing
      end
      
      -- Draw the chip
      local chip_opts = {
        height       = chip_height,
        is_selected  = is_selected,
        bg_color     = opts.bg_color,
        dot_size     = opts.dot_size,
        dot_spacing  = opts.dot_spacing,
        rounding     = opts.rounding or 4,
      }
      
      local clicked
      if use_dot_style then
        clicked = select(1, Chip.draw_with_dot(ctx, item.label, item.color, chip_opts))
      else
        clicked = select(1, Chip.draw(ctx, item.label, item.color, chip_opts))
      end
      
      if clicked then clicked_id = item.id end
      
      -- Update tracking
      current_x = current_x + chip_width
      items_in_row = items_in_row + 1
    end
  end

  return clicked_id
end

function M.draw_vertical(ctx, items, opts)
  opts = opts or {}
  local item_height = opts.item_height or 28
  local selected_ids = opts.selected_ids or {}
  local search_text = opts.search_text or ""
  local use_dot_style = opts.use_dot_style ~= false
  
  local clicked_id = nil
  
  for i, item in ipairs(items) do
    if search_text == "" or item.label:lower():find(search_text:lower(), 1, true) then
      local is_selected = selected_ids[item.id] or false
      
      local chip_opts = {
        height = item_height,
        is_selected = is_selected,
        bg_color = opts.bg_color,
        dot_size = opts.dot_size,
        dot_spacing = opts.dot_spacing,
        rounding = opts.rounding or 4,
      }
      
      local clicked, chip_w, chip_h
      if use_dot_style then
        clicked, chip_w, chip_h = Chip.draw_with_dot(ctx, item.label, item.color, chip_opts)
      else
        clicked, chip_w, chip_h = Chip.draw(ctx, item.label, item.color, chip_opts)
      end
      
      if clicked then
        clicked_id = item.id
      end
      
      ImGui.Dummy(ctx, 0, 4)
    end
  end
  
  return clicked_id
end

function M.draw_columns(ctx, items, opts)
  opts = opts or {}
  local selected_ids = opts.selected_ids or {}
  local search_text = opts.search_text or ""
  local use_dot_style = opts.use_dot_style or false
  local column_width = opts.column_width or 200
  local column_spacing = opts.column_spacing or 20
  local item_spacing = opts.item_spacing or 4
  
  local text_h = ImGui.GetTextLineHeight(ctx)
  local item_height = opts.item_height or (text_h + 8)
  
  local clicked_id = nil
  
  -- Filter items
  local filtered_items = {}
  for _, item in ipairs(items) do
    if search_text == "" or item.label:lower():find(search_text:lower(), 1, true) then
      table.insert(filtered_items, item)
    end
  end
  
  if #filtered_items == 0 then
    return nil
  end
  
  -- Calculate available height and items per column
  local avail_w, avail_h = ImGui.GetContentRegionAvail(ctx)
  local max_height = opts.max_height or avail_h
  local items_per_column = math.floor(max_height / (item_height + item_spacing))
  if items_per_column < 1 then items_per_column = 1 end
  
  local num_columns = math.ceil(#filtered_items / items_per_column)
  
  -- Store starting position
  local start_x = ImGui.GetCursorPosX(ctx)
  local start_y = ImGui.GetCursorPosY(ctx)
  
  -- Draw items column by column
  for col = 0, num_columns - 1 do
    for row = 0, items_per_column - 1 do
      local idx = col * items_per_column + row + 1
      if idx > #filtered_items then break end
      
      local item = filtered_items[idx]
      local is_selected = selected_ids[item.id] or false
      
      -- Position for this item
      ImGui.SetCursorPos(ctx, 
        start_x + col * (column_width + column_spacing), 
        start_y + row * (item_height + item_spacing))
      
      local chip_opts = {
        height = item_height,
        is_selected = is_selected,
        bg_color = opts.bg_color,
        dot_size = opts.dot_size or 8,
        dot_spacing = opts.dot_spacing or 10,
        rounding = opts.rounding or 4,
        padding_h = opts.padding_h or 12,
        explicit_width = column_width,
        text_align = "left",
      }
      
      local clicked
      if use_dot_style then
        clicked = select(1, Chip.draw_with_dot(ctx, item.label, item.color, chip_opts))
      else
        clicked = select(1, Chip.draw(ctx, item.label, item.color, chip_opts))
      end
      
      if clicked then
        clicked_id = item.id
      end
    end
  end
  
  -- Move cursor past all columns
  local total_height = math.min(#filtered_items, items_per_column) * (item_height + item_spacing)
  local total_width = num_columns * (column_width + column_spacing) - column_spacing
  ImGui.SetCursorPos(ctx, start_x, start_y + total_height)
  ImGui.Dummy(ctx, total_width, 0)
  
  return clicked_id
end

function M.draw_grid(ctx, items, opts)
  opts = opts or {}
  local avail_width = opts.width or ImGui.GetContentRegionAvail(ctx)
  local cols = opts.cols or 3
  local gap = opts.gap or 8
  local selected_ids = opts.selected_ids or {}
  local search_text = opts.search_text or ""
  local use_dot_style = opts.use_dot_style or false
  local justified = opts.justified or false
  
  local text_h = ImGui.GetTextLineHeight(ctx)
  local chip_height = opts.chip_height or (text_h + 6)
  
  local clicked_id = nil
  
  local filtered_items = {}
  for _, item in ipairs(items) do
    if search_text == "" or item.label:lower():find(search_text:lower(), 1, true) then
      table.insert(filtered_items, item)
    end
  end
  
  if #filtered_items == 0 then
    return nil
  end
  
  if justified then
    local min_widths = {}
    for i, item in ipairs(filtered_items) do
      local chip_opts = {
        padding_h = opts.padding_h or 8,
        dot_size = opts.dot_size or 7,
        dot_spacing = opts.dot_spacing or 7,
        use_dot_style = use_dot_style,
      }
      min_widths[i] = Chip.calculate_min_width(ctx, item.label, chip_opts)
    end
    
    local layout = ResponsiveGrid.calculate_justified_layout(filtered_items, {
      available_width = avail_width,
      min_widths = min_widths,
      gap = gap,
      max_stretch_ratio = opts.max_stretch_ratio or 1.4,
    })
    
    local row_start_x = ImGui.GetCursorPosX(ctx)
    
    for row_idx, row in ipairs(layout) do
      if row_idx > 1 then
        ImGui.SetCursorPosX(ctx, row_start_x)
      end
      
      for cell_idx, cell in ipairs(row) do
        local item = cell.item
        local is_selected = selected_ids[item.id] or false
        
        if cell_idx > 1 then
          ImGui.SameLine(ctx, 0, gap)
        end
        
        local chip_opts = {
          height = chip_height,
          is_selected = is_selected,
          bg_color = opts.bg_color,
          dot_size = opts.dot_size or 7,
          dot_spacing = opts.dot_spacing or 7,
          rounding = opts.rounding or 5,
          padding_h = opts.padding_h or 8,
          explicit_width = cell.final_width,
        }
        
        local clicked, chip_w, chip_h
        if use_dot_style then
          clicked, chip_w, chip_h = Chip.draw_with_dot(ctx, item.label, item.color, chip_opts)
        else
          clicked, chip_w, chip_h = Chip.draw(ctx, item.label, item.color, chip_opts)
        end
        
        if clicked then
          clicked_id = item.id
        end
      end
      
      if row_idx < #layout then
        ImGui.Dummy(ctx, 0, gap)
      end
    end
  else
    -- Non-justified grid: Fixed column layout with wrapping
    local row_start_x = ImGui.GetCursorPosX(ctx)
    local col_width = (avail_width - (cols - 1) * gap) / cols
    
    for i, item in ipairs(filtered_items) do
      local is_selected = selected_ids[item.id] or false
      local col = ((i - 1) % cols)
      
      if col > 0 then
        ImGui.SameLine(ctx, 0, gap)
      elseif i > 1 then
        -- New row
        ImGui.Dummy(ctx, 0, gap)
        ImGui.SetCursorPosX(ctx, row_start_x)
      end
      
      local chip_opts = {
        height = chip_height,
        is_selected = is_selected,
        bg_color = opts.bg_color,
        dot_size = opts.dot_size or 7,
        dot_spacing = opts.dot_spacing or 7,
        rounding = opts.rounding or 5,
        padding_h = opts.padding_h or 8,
        explicit_width = col_width,
      }
      
      local clicked
      if use_dot_style then
        clicked = select(1, Chip.draw_with_dot(ctx, item.label, item.color, chip_opts))
      else
        clicked = select(1, Chip.draw(ctx, item.label, item.color, chip_opts))
      end
      
      if clicked then
        clicked_id = item.id
      end
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