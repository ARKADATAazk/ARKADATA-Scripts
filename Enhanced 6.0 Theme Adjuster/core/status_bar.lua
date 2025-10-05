-- core/status_bar.lua
-- Footer drawn INSIDE a child window (no bleed; fully clickable; flush-ready)
package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'
local M = {}

local function add_text(dl, x, y, col_u32, s)
  if dl and ImGui.DrawList_AddText then
    ImGui.DrawList_AddText(dl, x, y, col_u32, tostring(s or ""))
  end
end

function M.create(theme, opts)
  local H          = (opts and opts.height) or 26
  local PAD        = (opts and opts.pad) or 6
  local right_note = nil
  
  local main_window = { x = 0, y = 0, w = 800, h = 600 }
  local stored_fonts = nil

  local style  = require('style')
  local C      = (style and style.palette) or {}
  local BLACK  = C.black  or 0x000000FF
  local TEAL   = C.teal   or 0x41E0A3FF
  local YELLOW = C.yellow or 0xE0B341FF
  local RED    = C.red    or 0xE04141FF

  local COL_BG     = C.grey_08
  local COL_BORDER = BLACK
  local COL_TEXT_R = 0xC0C0C0FF
  local COL_SEP    = 0x666666FF

  local CHIP_BORDER = BLACK
  local CHIP_SIZE   = 10
  local LEFT_PAD    = 10
  local TEXT_PAD    = 8

  local zip_idx    = 1
  local zips_cache = {}
  
  local about = require('about').create(theme)

  local function get_display_info()
    local status, _, zip_name = theme.get_status()
    if status == "direct" then
      return { color=TEAL,   text="READY - Direct Folder", button_text=nil,            button_action=nil,    can_rebuild=true }
    elseif status == "linked-ready" then
      return { color=YELLOW, text="READY - ZIP Cache",     button_text=zip_name and ("Linked: " .. zip_name) or "Relink ZIP",
               button_action="pick", can_rebuild=true }
    elseif status == "linked-needs-build" then
      return { color=YELLOW, text="LINKED - Build Cache",  button_text=zip_name and ("Build: " .. zip_name) or "Build Cache",
               button_action="build", can_rebuild=true }
    elseif status == "zip-ready" then
      return { color=YELLOW, text="READY - ZIP Cache",     button_text=nil,            button_action=nil,    can_rebuild=true }
    elseif status == "zip-needs-build" then
      return { color=YELLOW, text="ZIP - Build Cache",     button_text="Build Cache",  button_action="build", can_rebuild=true }
    elseif status == "needs-link" then
      return { color=RED,    text="NOT LINKED",            button_text="Pick ZIP",     button_action="pick", can_rebuild=false }
    else
      return { color=RED,    text="ERROR",                 button_text="Pick ZIP",     button_action="pick", can_rebuild=false }
    end
  end

  local function open_zip_popup(ctx)
    zips_cache = (theme and theme.list_theme_zips and theme.list_theme_zips()) or {}
    if zip_idx < 1 or zip_idx > #zips_cache then zip_idx = 1 end
    ImGui.OpenPopup(ctx, 'Pick .ReaperThemeZip##statusbar')
  end

  local function draw_zip_popup(ctx)
    if ImGui.BeginPopup(ctx, 'Pick .ReaperThemeZip##statusbar') then
      local info = theme.get_theme_info()
      if #zips_cache == 0 then
        ImGui.Text(ctx, 'No .ReaperThemeZip files found in ColorThemes.')
      else
        local preview = zips_cache[zip_idx]:match("[^\\/]+$") or zips_cache[zip_idx]
        if ImGui.BeginCombo(ctx, 'ZIP', preview) then
          for i,p in ipairs(zips_cache) do
            local label = p:match("[^\\/]+$") or p
            local sel = (i == zip_idx)
            if ImGui.Selectable(ctx, label, sel) then zip_idx = i end
          end
          ImGui.EndCombo(ctx)
        end
        if ImGui.Button(ctx, 'Link and Build Cache##statusbar') then
          if theme.build_cache_from_zip and zips_cache[zip_idx] and info.theme_name then
            theme.build_cache_from_zip(info.theme_name, zips_cache[zip_idx])
          end
          ImGui.CloseCurrentPopup(ctx)
        end
        ImGui.SameLine(ctx)
        if ImGui.Button(ctx, 'Cancel##statusbar') then
          ImGui.CloseCurrentPopup(ctx)
        end
      end
      ImGui.EndPopup(ctx)
    end
  end

  local function set_right_note(s) right_note = s end
  
  local function set_main_window_info(x, y, w, h)
    main_window.x = x
    main_window.y = y
    main_window.w = w
    main_window.h = h
  end
  
  local function set_fonts(fonts)
    stored_fonts = fonts
  end

  local function draw_child(ctx, forced_h)
    local w = select(1, ImGui.GetContentRegionAvail(ctx)) or 0
    local sx, sy = ImGui.GetCursorScreenPos(ctx)
    local dl = ImGui.GetWindowDrawList(ctx)
    local h = forced_h or H

    local x1, y1, x2, y2 = sx, sy, sx + w, sy + h

    ImGui.DrawList_AddRectFilled(dl, x1, y1, x2, y2, COL_BG, 0, 0)
    ImGui.DrawList_AddLine(dl, x1, y1, x2, y1, COL_BORDER, 1.0)

    local display = get_display_info()

    local chip_y1 = y1 + math.floor((h - CHIP_SIZE) / 2)
    local chip_y2 = chip_y1 + CHIP_SIZE
    local chip_x1 = x1 + LEFT_PAD
    local chip_x2 = chip_x1 + CHIP_SIZE

    ImGui.DrawList_AddRectFilled(dl, chip_x1, chip_y1, chip_x2, chip_y2, display.color, 0, 0)
    ImGui.DrawList_AddRect(dl,       chip_x1, chip_y1, chip_x2, chip_y2, BLACK, 0, 0, 1.0)

    local label_y = y1 + math.floor((h - 14) / 2) - 1
    add_text(dl, chip_x2 + TEXT_PAD, label_y, display.color, display.text)

    local left_text_w = select(1, ImGui.CalcTextSize(ctx, display.text)) or 0

    ImGui.SetCursorPos(ctx, LEFT_PAD + CHIP_SIZE + TEXT_PAD + left_text_w + 10, math.floor((h - 20) / 2))
    if display.button_text then
      local btn_w = math.max(100, (select(1, ImGui.CalcTextSize(ctx, display.button_text)) or 0) + 16)
      if ImGui.Button(ctx, display.button_text .. '##statusbar', btn_w, 20) then
        if display.button_action == "pick"  then open_zip_popup(ctx)
        elseif display.button_action == "build" then theme.prepare_images(true) end
      end
      ImGui.SameLine(ctx)
    end
    draw_zip_popup(ctx)

    local theme_name = ''
    if theme and theme.get_theme_info then
      local info = theme.get_theme_info()
      theme_name = info and (info.theme_name or '') or ''
    end

    local right_text = theme_name
    if right_note and right_note ~= '' then
      right_text = (right_text ~= '' and (right_note .. '  ·  ' .. right_text)) or right_note
    end

    local right_text_w = (right_text ~= '' and (select(1, ImGui.CalcTextSize(ctx, right_text)) or 0)) or 0
    local right_margin = 10
    local rebuild_w = 100
    local about_w = 20
    local sep_margin = 10

    local about_x = w - right_margin - about_w
    local sep_x = about_x - sep_margin
    local rebuild_x = sep_x - sep_margin - rebuild_w
    local text_x = rebuild_x - 10 - right_text_w

    if display.can_rebuild then
      ImGui.SetCursorPos(ctx, rebuild_x, math.floor((h - 20) / 2))
      if ImGui.Button(ctx, 'Rebuild Cache##statusbar', rebuild_w, 20) then
        theme.prepare_images(true)
      end
    else
      text_x = sep_x - sep_margin - right_text_w
    end

    if right_text ~= '' then
      add_text(dl, x1 + text_x, label_y, COL_TEXT_R, right_text)
    end

    local sep_y1 = y1 + 4
    local sep_y2 = y2 - 4
    ImGui.DrawList_AddLine(dl, x1 + sep_x, sep_y1, x1 + sep_x, sep_y2, COL_SEP, 1.0)

    ImGui.SetCursorPos(ctx, about_x, math.floor((h - 20) / 2))
    if ImGui.Button(ctx, '?##statusbar', about_w, 20) then
      about.show(ctx, true, stored_fonts, main_window.x, main_window.y, main_window.w, main_window.h)
    end
    
    about.draw(ctx)

    ImGui.Dummy(ctx, 0, h + PAD)
  end

  local function draw_overlay(ctx) draw_child(ctx, H) end

  return {
    height                = H,
    pad                   = PAD,
    set_right_note        = set_right_note,
    set_main_window_info  = set_main_window_info,
    set_fonts             = set_fonts,
    draw_child            = draw_child,
    draw                  = draw_overlay,
  }
end

return M