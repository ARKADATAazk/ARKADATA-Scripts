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
  
  local H           = config.height or 34  -- Increased default from 26 to 34
  local LEFT_PAD    = config.left_pad or 10
  local TEXT_PAD    = config.text_pad or 8
  local CHIP_SIZE   = config.chip_size or 10
  local RIGHT_PAD   = config.right_pad or 10
  
  -- Text vertical offset for visual centering (positive = move up)
  local TEXT_OFFSET = config.text_offset or 2  -- Adjust this value if text appears too high/low
  
  local get_status  = config.get_status or function() return {} end
  local right_text  = ""
  local popup_state = { open = false, data = nil }
  
  local style   = config.style or {}
  local palette = style.palette or {}
  
  local COL_BG      = palette.grey_08 or 0x1E1E1EFF
  local COL_BORDER  = palette.black or 0x000000FF
  local COL_TEXT    = palette.grey_c0 or 0xC0C0C0FF
  local COL_SEP     = palette.grey_66 or 0x666666FF
  
  local DEFAULT_TEAL   = palette.teal or 0x41E0A3FF
  local DEFAULT_YELLOW = palette.yellow or 0xE0B341FF
  local DEFAULT_RED    = palette.red or 0xE04141FF
  
  local CHIP_BORDER = palette.black or 0x000000FF

  local function set_right_text(text)
    right_text = text or ""
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

  local function render(ctx)
    local w = select(1, ImGui.GetContentRegionAvail(ctx)) or 0
    local sx, sy = ImGui.GetCursorScreenPos(ctx)
    local dl = ImGui.GetWindowDrawList(ctx)
    local h = H

    local x1, y1, x2, y2 = sx, sy, sx + w, sy + h

    ImGui.DrawList_AddRectFilled(dl, x1, y1, x2, y2, COL_BG, 0, 0)
    ImGui.DrawList_AddLine(dl, x1, y1, x2, y1, COL_BORDER, 1.0)

    local status = get_status()
    local chip_color = status.color or DEFAULT_TEAL
    local status_text = status.text or "READY"
    
    -- Center the chip vertically
    local chip_y1 = y1 + math.floor((h - CHIP_SIZE) / 2)
    local chip_y2 = chip_y1 + CHIP_SIZE
    local chip_x1 = x1 + LEFT_PAD
    local chip_x2 = chip_x1 + CHIP_SIZE

    ImGui.DrawList_AddRectFilled(dl, chip_x1, chip_y1, chip_x2, chip_y2, chip_color, 0, 0)
    ImGui.DrawList_AddRect(dl, chip_x1, chip_y1, chip_x2, chip_y2, CHIP_BORDER, 0, 0, 1.0)

    -- Get actual font metrics for proper text centering
    local font = ImGui.GetFont(ctx)
    local font_size = ImGui.GetFontSize(ctx)
    
    -- Calculate text baseline position for vertical centering
    -- ImGui positions text from the top-left corner of the text box
    -- We apply an offset for better visual centering since text has ascenders/descenders
    local text_height = font_size
    local label_y = y1 + math.floor((h - text_height) / 2) - TEXT_OFFSET
    
    add_text(dl, chip_x2 + TEXT_PAD, label_y, chip_color, status_text)

    local left_text_w = select(1, ImGui.CalcTextSize(ctx, status_text)) or 0
    local cursor_x = LEFT_PAD + CHIP_SIZE + TEXT_PAD + left_text_w + 10

    -- Buttons positioning
    local button_height = math.min(24, H - 8)  -- Scale button height with status bar height, leaving 4px padding top/bottom
    local button_y = math.floor((h - button_height) / 2)
    
    if status.buttons then
      for i, btn in ipairs(status.buttons) do
        ImGui.SetCursorPos(ctx, cursor_x, button_y)
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

    local right_x = w - RIGHT_PAD - total_right_w
    
    for i, item_info in ipairs(item_widths) do
      if item_info.type == "text" then
        add_text(dl, x1 + right_x, label_y, COL_TEXT, item_info.content)
        right_x = right_x + item_info.width + 10
      elseif item_info.type == "button" then
        if i > 1 then
          local sep_x = right_x - 5
          local sep_y1 = y1 + 4
          local sep_y2 = y2 - 4
          ImGui.DrawList_AddLine(dl, x1 + sep_x, sep_y1, x1 + sep_x, sep_y2, COL_SEP, 1.0)
          right_x = right_x + 10
        end
        
        ImGui.SetCursorPos(ctx, right_x, button_y)
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

    ImGui.Dummy(ctx, 0, h)
  end

  return {
    height = H,
    set_right_text = set_right_text,
    render = render,
  }
end

return M