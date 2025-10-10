-- ReArkitekt/app/chrome/status_bar/widget.lua
-- Modular status bar rendering - positioning handled by the containing window

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'
local Chip = require('ReArkitekt.gui.widgets.component.chip')
local StatusBarConfig = require('ReArkitekt.app.chrome.status_bar.config')

local M = {}

local function add_text(dl, x, y, col_u32, s)
  if dl and ImGui.DrawList_AddText then
    ImGui.DrawList_AddText(dl, x, y, col_u32, tostring(s or ""))
  end
end

function M.new(config)
  config = config or {}

  -- Merge with defaults and optional preset
  local preset_name = config.preset
  config = StatusBarConfig.merge(config, preset_name)

  local H         = config.height
  local LEFT_PAD  = config.left_pad
  local TEXT_PAD  = config.text_pad
  local CHIP_SIZE = config.chip_size
  local RIGHT_PAD = config.right_pad

  local get_status  = config.get_status or function() return {} end
  local right_text  = ""
  local popup_state = { open = false, data = nil }

  local show_resize_handle   = config.show_resize_handle
  local RESIZE_SQUARE_SIZE   = config.resize_square_size
  local RESIZE_SPACING       = config.resize_spacing

  local resize_dragging   = false
  local drag_start_x      = 0
  local drag_start_y      = 0
  local drag_start_w      = 0
  local drag_start_h      = 0
  local pending_resize_w  = nil
  local pending_resize_h  = nil

  local style   = config.style or {}
  local palette = style.palette or {}

  local COL_BG     = palette.grey_08  or 0x1E1E1EFF
  local COL_BORDER = palette.black    or 0x000000FF
  local COL_TEXT   = palette.grey_c0  or 0xC0C0C0FF  -- fixed RGBA fallback
  local COL_SEP    = palette.grey_66  or 0x666666FF

  local DEFAULT_TEAL   = palette.teal    or 0x41E0A3FF
  local DEFAULT_YELLOW = palette.yellow  or 0xE0B341FF
  local DEFAULT_RED    = palette.red     or 0xE04141FF

  local RESIZE_HANDLE_COLOR = palette.grey_66 or 0x666666FF

  -- Chip configuration from merged config
  local chip_config           = config.chip
  local chip_shape            = chip_config.shape
  local chip_rounding         = chip_config.rounding
  local chip_show_glow        = chip_config.show_glow
  local chip_glow_layers      = chip_config.glow_layers
  local chip_shadow           = chip_config.shadow
  local chip_shadow_offset_x  = chip_config.shadow_offset_x
  local chip_shadow_offset_y  = chip_config.shadow_offset_y
  local chip_shadow_blur      = chip_config.shadow_blur
  local chip_shadow_alpha     = chip_config.shadow_alpha
  local chip_border           = chip_config.border
  local chip_border_color     = chip_config.border_color
  local chip_border_thickness = chip_config.border_thickness

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

    local sz    = RESIZE_SQUARE_SIZE
    local gap   = RESIZE_SPACING

    local total_width   = (sz * 3) + (gap * 2) + 6
    local handle_padding = 8

    local handle_right = bar_x + bar_w - 6
    local center_y     = bar_y + (bar_h / 2)

    local interact_x1 = handle_right - total_width - handle_padding
    local interact_y1 = bar_y + 2
    local interact_x2 = bar_x + bar_w
    local interact_y2 = bar_y + bar_h - 2

    local is_hovering = ImGui.IsMouseHoveringRect(ctx, interact_x1, interact_y1, interact_x2, interact_y2, false)
    local mouse_down  = ImGui.IsMouseDown(ctx, ImGui.MouseButton_Left)

    if is_hovering and ImGui.IsMouseClicked(ctx, ImGui.MouseButton_Left) then
      resize_dragging = true
      local mx, my = ImGui.GetMousePos(ctx)
      drag_start_x, drag_start_y = mx, my
      drag_start_w, drag_start_h = ImGui.GetWindowSize(ctx)
      reaper.ShowConsoleMsg("Resize grip: DRAG START - w=" .. drag_start_w .. " h=" .. drag_start_h .. "\n")
    end

    if resize_dragging then
      if mouse_down then
        local mx, my = ImGui.GetMousePos(ctx)
        local delta_x = mx - drag_start_x
        local delta_y = my - drag_start_y
        pending_resize_w = math.max(200, drag_start_w + delta_x)
        pending_resize_h = math.max(100, drag_start_h + delta_y)
        reaper.ShowConsoleMsg("Resize grip: DRAGGING - new_w=" .. pending_resize_w .. " new_h=" .. pending_resize_h .. " (delta: " .. delta_x .. ", " .. delta_y .. ")\n")
      else
        resize_dragging = false
        pending_resize_w, pending_resize_h = nil, nil
        reaper.ShowConsoleMsg("Resize grip: DRAG END\n")
      end
    end

    if is_hovering or resize_dragging then
      ImGui.SetMouseCursor(ctx, ImGui.MouseCursor_ResizeNWSE)
    end

    local grip_color = (is_hovering or resize_dragging) and (palette.grey_52 or 0x858585FF) or RESIZE_HANDLE_COLOR

    local row1_y = center_y + 3
    ImGui.DrawList_AddRectFilled(dl, handle_right - (sz * 3) - (gap * 2), row1_y, handle_right - (sz * 2) - (gap * 2), row1_y + sz, grip_color, 0, 0)
    ImGui.DrawList_AddRectFilled(dl, handle_right - (sz * 2) - gap,           row1_y, handle_right - sz - gap,                   row1_y + sz, grip_color, 0, 0)
    ImGui.DrawList_AddRectFilled(dl, handle_right - sz,                        row1_y, handle_right,                              row1_y + sz, grip_color, 0, 0)

    local row2_y = center_y - 1
    ImGui.DrawList_AddRectFilled(dl, handle_right - (sz * 2) - gap, row2_y, handle_right - sz - gap, row2_y + sz, grip_color, 0, 0)
    ImGui.DrawList_AddRectFilled(dl, handle_right - sz,              row2_y, handle_right,           row2_y + sz, grip_color, 0, 0)

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
    local resize_handle_width = show_resize_handle and 30 or 0

    ImGui.Selectable(ctx, "##statusbar_nodrag", false, ImGui.SelectableFlags_Disabled, w - resize_handle_width, h)

    if show_resize_handle and resize_handle_width > 0 then
      ImGui.SetCursorScreenPos(ctx, sx + w - resize_handle_width, sy)
      ImGui.InvisibleButton(ctx, "##resize_grip_area", resize_handle_width, h)
    end

    ImGui.SetCursorScreenPos(ctx, sx, sy)

    -- Background + top border
    ImGui.DrawList_AddRectFilled(dl, x1, y1, x2, y2, COL_BG, 0, 0)
    ImGui.DrawList_AddLine(dl, x1, y1, x2, y1, COL_BORDER, 1.0)

    -- Status content
    local status       = get_status()
    local chip_color   = status.color or DEFAULT_TEAL
    local status_text  = status.text  or "READY"

    local center_y = y1 + (h / 2)
    local chip_x   = x1 + LEFT_PAD + (CHIP_SIZE / 2)
    local chip_y   = center_y

    local chip_opts = {
      style = Chip.STYLE.INDICATOR,
      draw_list = dl,
      x = chip_x,
      y = chip_y,
      color = chip_color,
      shape = chip_shape,
      radius = chip_shape == Chip.SHAPE.CIRCLE and (CHIP_SIZE / 2) or nil,
      size = chip_shape   == Chip.SHAPE.SQUARE and CHIP_SIZE       or nil,
      rounding = chip_shape == Chip.SHAPE.SQUARE and chip_rounding or nil,
      show_glow = chip_show_glow,
      glow_layers = chip_glow_layers,
      shadow = chip_shadow,
      shadow_offset_x = chip_shadow_offset_x,
      shadow_offset_y = chip_shadow_offset_y,
      shadow_blur = chip_shadow_blur,
      shadow_alpha = chip_shadow_alpha,
      border = chip_border,
      border_color = chip_border_color,
      border_thickness = chip_border_thickness,
    }

    Chip.draw(ctx, chip_opts)

    local text_w, text_h = ImGui.CalcTextSize(ctx, status_text)
    local label_y = center_y - (text_h / 2)
    local label_x = x1 + LEFT_PAD + CHIP_SIZE + TEXT_PAD
    add_text(dl, label_x, label_y, chip_color, status_text)

    local left_text_w = text_w or 0
    local cursor_x = LEFT_PAD + CHIP_SIZE + TEXT_PAD + left_text_w + 10

    local button_height = math.min(20, h - 8)
    local button_y = center_y - (button_height / 2)

    if status.buttons then
      for i, btn in ipairs(status.buttons) do
        ImGui.SetCursorScreenPos(ctx, sx + cursor_x, sy + button_y)
        local btn_w = math.max(100, (select(1, ImGui.CalcTextSize(ctx, btn.label)) or 0) + 16)
        if ImGui.Button(ctx, btn.label .. "##statusbar_" .. i, btn_w, button_height) then
          if btn.action then btn.action(ctx) end
          if btn.popup  then
            popup_state.open = true
            popup_state.data = btn.popup
            ImGui.OpenPopup(ctx, btn.popup.popup_id or "StatusBarPopup")
          end
        end
        cursor_x = cursor_x + btn_w + 5
      end
    end

    draw_popup(ctx)

    local resize_handle_width_final = show_resize_handle and 16 or 0

    local right_items = {}
    if right_text and right_text ~= "" then table.insert(right_items, right_text) end
    if status.right_buttons then
      for _, btn in ipairs(status.right_buttons) do
        table.insert(right_items, { type = "button", data = btn })
      end
    end

    local total_right_w, item_widths = 0, {}
    for _, item in ipairs(right_items) do
      if type(item) == "string" then
        local tw = select(1, ImGui.CalcTextSize(ctx, item)) or 0
        table.insert(item_widths, { type = "text", width = tw, content = item })
        total_right_w = total_right_w + tw + 10
      elseif type(item) == "table" and item.type == "button" then
        local btn = item.data
        local bw = btn.width or math.max(80, (select(1, ImGui.CalcTextSize(ctx, btn.label)) or 0) + 16)
        table.insert(item_widths, { type = "button", width = bw, data = btn })
        total_right_w = total_right_w + bw + 10
      end
    end
    if #right_items > 1 then total_right_w = total_right_w + 20 end

    local right_x = w - RIGHT_PAD - total_right_w - resize_handle_width_final - 8

    for i, info in ipairs(item_widths) do
      if info.type == "text" then
        local _, rtext_h = ImGui.CalcTextSize(ctx, info.content)
        local rtext_y = center_y - (rtext_h / 2)
        add_text(dl, x1 + right_x, rtext_y, COL_TEXT, info.content)
        right_x = right_x + info.width + 10
      elseif info.type == "button" then
        if i > 1 then
          local sep_x = right_x - 5
          local sep_y1 = y1 + 4
          local sep_y2 = y2 - 4
          ImGui.DrawList_AddLine(dl, x1 + sep_x, sep_y1, x1 + sep_x, sep_y2, COL_SEP, 1.0)
          right_x = right_x + 10
        end
        ImGui.SetCursorScreenPos(ctx, sx + right_x, sy + button_y)
        if ImGui.Button(ctx, info.data.label .. "##statusbar_right_" .. i, info.data.width or 80, button_height) then
          if info.data.action then info.data.action(ctx) end
          if info.data.popup  then
            popup_state.open = true
            popup_state.data = info.data.popup
            ImGui.OpenPopup(ctx, info.data.popup.popup_id or "StatusBarPopup")
          end
        end
        right_x = right_x + info.width + 10
      end
    end

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
