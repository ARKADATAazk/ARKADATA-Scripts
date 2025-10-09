-- ReArkitekt/gui/widgets/status_bar.lua
-- Modular status bar rendering - positioning handled by window

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local M = {}

local function add_text(dl, x, y, col_u32, s)
  if dl and ImGui.DrawList_AddText then
    ImGui.DrawList_AddText(dl, x, y, col_u32, tostring(s or ""))
  end
end

function M.new(config)
  config = config or {}
  
  local H           = config.height or 28
  local LEFT_PAD    = config.left_pad or 10
  local TEXT_PAD    = config.text_pad or 8
  local CHIP_SIZE   = config.chip_size or 10
  local RIGHT_PAD   = config.right_pad or 10
  
  local get_status  = config.get_status or function() return {} end
  local right_text  = ""
  local popup_state = { open = false, data = nil }
  
  -- Resize handle configuration
  local show_resize_handle = config.show_resize_handle
  if show_resize_handle == nil then
    show_resize_handle = true  -- Default enabled
  end
  local RESIZE_SQUARE_SIZE = config.resize_square_size or 3
  local RESIZE_SPACING = config.resize_spacing or 1
  
  -- Resize drag state
  local resize_dragging = false
  local drag_start_x = 0
  local drag_start_y = 0
  local drag_start_w = 0
  local drag_start_h = 0
  local pending_resize_w = nil
  local pending_resize_h = nil
  
  local style   = config.style or {}
  local palette = style.palette or {}
  
  local COL_BG      = palette.grey_08 or 0x1E1E1EFF
  local COL_BORDER  = palette.black or 0x000000FF
  local COL_TEXT    = palette.grey_c0 or 0xC0C0FF
  local COL_SEP     = palette.grey_66 or 0x666666FF
  
  local DEFAULT_TEAL   = palette.teal or 0x41E0A3FF
  local DEFAULT_YELLOW = palette.yellow or 0xE0B341FF
  local DEFAULT_RED    = palette.red or 0xE04141FF
  
  local CHIP_BORDER = palette.black or 0x000000FF
  local RESIZE_HANDLE_COLOR = palette.grey_66 or 0x666666FF

  local function set_right_text(text)
    right_text = text or ""
  end
  
  local function apply_pending_resize(ctx)
    if pending_resize_w and pending_resize_h then
      ImGui.SetNextWindowSize(ctx, pending_resize_w, pending_resize_h, ImGui.Cond_Always)
    end
  end
  
  local function draw_popup(ctx)
    if popup_state.open and popup_state.data then
      local popup_id = popup_state.data.popup_id or "StatusBarPopup"
      if ImGui.BeginPopup(ctx, popup_id) then
        if popup_state.data.draw_content then
          popup_state.data.draw_content(ctx, popup_state)
        end
        ImGui.EndPopup(ctx)
      else
        popup_state.open = false
      end
    end
  end

  local function draw_resize_handle(ctx, dl, bar_x, bar_y, bar_w, bar_h)
    if not show_resize_handle then
      return 0
    end
    
    local sz = RESIZE_SQUARE_SIZE
    local gap = RESIZE_SPACING
    
    -- Calculate total width needed for resize handle
    -- Pattern: 3 bottom, 2 middle, 1 top (stairs going up-right)
    local total_width = (sz * 3) + (gap * 2) + 6
    local handle_padding = 8  -- Interaction area padding
    
    -- Position from right edge
    local handle_right = bar_x + bar_w - 6
    local center_y = bar_y + (bar_h / 2)
    
    -- Define interactive area (larger than visual for better UX)
    local interact_x1 = handle_right - total_width - handle_padding
    local interact_y1 = bar_y + 2
    local interact_x2 = bar_x + bar_w
    local interact_y2 = bar_y + bar_h - 2
    
    -- Check if mouse is hovering over the grip area
    local is_hovering = ImGui.IsMouseHoveringRect(ctx, interact_x1, interact_y1, interact_x2, interact_y2, false)
    
    -- Handle resize dragging with ImGui
    local mouse_down = ImGui.IsMouseDown(ctx, ImGui.MouseButton_Left)
    
    if is_hovering and ImGui.IsMouseClicked(ctx, ImGui.MouseButton_Left) then
      -- Start drag
      resize_dragging = true
      local mx, my = ImGui.GetMousePos(ctx)
      drag_start_x = mx
      drag_start_y = my
      
      -- Get current window size from ImGui
      drag_start_w, drag_start_h = ImGui.GetWindowSize(ctx)
      
      reaper.ShowConsoleMsg("Resize grip: DRAG START - w=" .. drag_start_w .. " h=" .. drag_start_h .. "\n")
    end
    
    if resize_dragging then
      if mouse_down then
        -- Continue dragging - calculate new size
        local mx, my = ImGui.GetMousePos(ctx)
        local delta_x = mx - drag_start_x
        local delta_y = my - drag_start_y
        
        pending_resize_w = math.max(200, drag_start_w + delta_x)
        pending_resize_h = math.max(100, drag_start_h + delta_y)
        
        reaper.ShowConsoleMsg("Resize grip: DRAGGING - new_w=" .. pending_resize_w .. " new_h=" .. pending_resize_h .. " (delta: " .. delta_x .. ", " .. delta_y .. ")\n")
      else
        -- Mouse released - end drag
        resize_dragging = false
        pending_resize_w = nil
        pending_resize_h = nil
        reaper.ShowConsoleMsg("Resize grip: DRAG END\n")
      end
    end
    
    -- Set cursor to resize diagonal when hovering or dragging
    if is_hovering or resize_dragging then
      ImGui.SetMouseCursor(ctx, ImGui.MouseCursor_ResizeNWSE)
    end
    
    -- Determine color based on hover/drag state (subtle highlight)
    local grip_color = (is_hovering or resize_dragging) and (palette.grey_52 or 0x858585FF) or RESIZE_HANDLE_COLOR
    
    -- Draw 6 squares in stair pattern (bottom-left to top-right)
    -- Row 1 (bottom): 3 squares
    local row1_y = center_y + 3
    ImGui.DrawList_AddRectFilled(dl, handle_right - (sz * 3) - (gap * 2), row1_y, handle_right - (sz * 2) - (gap * 2), row1_y + sz, grip_color, 0, 0)
    ImGui.DrawList_AddRectFilled(dl, handle_right - (sz * 2) - gap, row1_y, handle_right - sz - gap, row1_y + sz, grip_color, 0, 0)
    ImGui.DrawList_AddRectFilled(dl, handle_right - sz, row1_y, handle_right, row1_y + sz, grip_color, 0, 0)
    
    -- Row 2 (middle): 2 squares, shifted right
    local row2_y = center_y - 1
    ImGui.DrawList_AddRectFilled(dl, handle_right - (sz * 2) - gap, row2_y, handle_right - sz - gap, row2_y + sz, grip_color, 0, 0)
    ImGui.DrawList_AddRectFilled(dl, handle_right - sz, row2_y, handle_right, row2_y + sz, grip_color, 0, 0)
    
    -- Row 3 (top): 1 square, shifted right
    local row3_y = center_y - 5
    ImGui.DrawList_AddRectFilled(dl, handle_right - sz, row3_y, handle_right, row3_y + sz, grip_color, 0, 0)
    
    return total_width
  end

  local function render(ctx)
    local w = select(1, ImGui.GetContentRegionAvail(ctx)) or 0
    local sx, sy = ImGui.GetCursorScreenPos(ctx)
    local dl = ImGui.GetWindowDrawList(ctx)
    
    local _, available_h = ImGui.GetContentRegionAvail(ctx)
    local h = available_h > 0 and available_h or H
    
    local x1, y1, x2, y2 = sx, sy, sx + w, sy + h
    
    -- Calculate resize handle width
    local resize_handle_width = show_resize_handle and 30 or 0
    
    -- Use Selectable to block window dragging on LEFT part only
    ImGui.Selectable(ctx, "##statusbar_nodrag", false, ImGui.SelectableFlags_Disabled, w - resize_handle_width, h)
    
    -- Add an InvisibleButton over the resize grip area to block window dragging there too
    if show_resize_handle and resize_handle_width > 0 then
      ImGui.SetCursorScreenPos(ctx, sx + w - resize_handle_width, sy)
      ImGui.InvisibleButton(ctx, "##resize_grip_area", resize_handle_width, h)
    end
    
    -- Reset cursor for drawing on top
    ImGui.SetCursorScreenPos(ctx, sx, sy)

    ImGui.DrawList_AddRectFilled(dl, x1, y1, x2, y2, COL_BG, 0, 0)
    ImGui.DrawList_AddLine(dl, x1, y1, x2, y1, COL_BORDER, 1.0)

    local status = get_status()
    local chip_color = status.color or DEFAULT_TEAL
    local status_text = status.text or "READY"
    
    local center_y = y1 + (h / 2)
    
    local chip_y1 = center_y - (CHIP_SIZE / 2)
    local chip_y2 = chip_y1 + CHIP_SIZE
    local chip_x1 = x1 + LEFT_PAD
    local chip_x2 = chip_x1 + CHIP_SIZE

    ImGui.DrawList_AddRectFilled(dl, chip_x1, chip_y1, chip_x2, chip_y2, chip_color, 0, 0)
    ImGui.DrawList_AddRect(dl, chip_x1, chip_y1, chip_x2, chip_y2, CHIP_BORDER, 0, 0, 1.0)

    local text_w, text_h = ImGui.CalcTextSize(ctx, status_text)
    local label_y = center_y - (text_h / 2)
    
    add_text(dl, chip_x2 + TEXT_PAD, label_y, chip_color, status_text)

    local left_text_w = select(1, ImGui.CalcTextSize(ctx, status_text)) or 0
    local cursor_x = LEFT_PAD + CHIP_SIZE + TEXT_PAD + left_text_w + 10

    local button_height = math.min(20, h - 8)
    local button_y = center_y - (button_height / 2)
    
    if status.buttons then
      for i, btn in ipairs(status.buttons) do
        ImGui.SetCursorScreenPos(ctx, sx + cursor_x, sy + button_y)
        local btn_w = math.max(100, (select(1, ImGui.CalcTextSize(ctx, btn.label)) or 0) + 16)
        if ImGui.Button(ctx, btn.label .. "##statusbar_" .. i, btn_w, button_height) then
          if btn.action then
            btn.action(ctx)
          end
          if btn.popup then
            popup_state.open = true
            popup_state.data = btn.popup
            ImGui.OpenPopup(ctx, btn.popup.popup_id or "StatusBarPopup")
          end
        end
        cursor_x = cursor_x + btn_w + 5
      end
    end

    draw_popup(ctx)

    -- Calculate resize handle width first
    local resize_handle_width = 0
    if show_resize_handle then
      resize_handle_width = 16  -- Approximate width of resize handle
    end

    local right_items = {}
    if right_text and right_text ~= "" then
      table.insert(right_items, right_text)
    end
    if status.right_buttons then
      for _, btn in ipairs(status.right_buttons) do
        table.insert(right_items, { type = "button", data = btn })
      end
    end

    local total_right_w = 0
    local item_widths = {}
    
    for _, item in ipairs(right_items) do
      if type(item) == "string" then
        local text_w = select(1, ImGui.CalcTextSize(ctx, item)) or 0
        table.insert(item_widths, { type = "text", width = text_w, content = item })
        total_right_w = total_right_w + text_w + 10
      elseif type(item) == "table" and item.type == "button" then
        local btn = item.data
        local btn_w = btn.width or math.max(80, (select(1, ImGui.CalcTextSize(ctx, btn.label)) or 0) + 16)
        table.insert(item_widths, { type = "button", width = btn_w, data = btn })
        total_right_w = total_right_w + btn_w + 10
      end
    end

    if #right_items > 1 then
      total_right_w = total_right_w + 10 + 10
    end

    -- Account for resize handle in positioning
    local right_x = w - RIGHT_PAD - total_right_w - resize_handle_width - 8
    
    for i, item_info in ipairs(item_widths) do
      if item_info.type == "text" then
        local _, rtext_h = ImGui.CalcTextSize(ctx, item_info.content)
        local rtext_y = center_y - (rtext_h / 2)
        add_text(dl, x1 + right_x, rtext_y, COL_TEXT, item_info.content)
        right_x = right_x + item_info.width + 10
      elseif item_info.type == "button" then
        if i > 1 then
          local sep_x = right_x - 5
          local sep_y1 = y1 + 4
          local sep_y2 = y2 - 4
          ImGui.DrawList_AddLine(dl, x1 + sep_x, sep_y1, x1 + sep_x, sep_y2, COL_SEP, 1.0)
          right_x = right_x + 10
        end
        
        ImGui.SetCursorScreenPos(ctx, sx + right_x, sy + button_y)
        if ImGui.Button(ctx, item_info.data.label .. "##statusbar_right_" .. i, item_info.data.width or 80, button_height) then
          if item_info.data.action then
            item_info.data.action(ctx)
          end
          if item_info.data.popup then
            popup_state.open = true
            popup_state.data = item_info.data.popup
            ImGui.OpenPopup(ctx, item_info.data.popup.popup_id or "StatusBarPopup")
          end
        end
        right_x = right_x + item_info.width + 10
      end
    end

    -- Draw resize handle at the very right
    draw_resize_handle(ctx, dl, x1, y1, w, h)

    ImGui.Dummy(ctx, 0, H)
  end

  return {
    height = H,
    set_right_text = set_right_text,
    apply_pending_resize = apply_pending_resize,
    render = render,
  }
end

return M