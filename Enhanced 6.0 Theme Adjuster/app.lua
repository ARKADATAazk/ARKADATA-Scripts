-- core/app.lua
local M = {}

----------------------------------------------------------------
-- CONFIGURATION - Adjust these values to customize appearance
----------------------------------------------------------------
local CONFIG = {
  -- Font sizes
  FONT_SIZE_DEFAULT = 13,
  FONT_SIZE_TABS    = 13,
  FONT_SIZE_TITLE   = 15,
  
  -- Header / Tabs
  HEADER_HEIGHT     = 36,
  HEADER_PULL_UP    = 6,   -- How much the header overlaps into title bar area
  
  -- Window sizing
  WINDOW_INITIAL_W  = 980,
  WINDOW_INITIAL_H  = 580,
  WINDOW_MIN_W      = 560,
  WINDOW_MIN_H      = 360,
  WINDOW_INITIAL_X  = 80,
  WINDOW_INITIAL_Y  = 80,
  
  -- Padding & Spacing
  WINDOW_PADDING_H  = 8,   -- Horizontal window padding
  WINDOW_PADDING_V  = 0,   -- Vertical window padding (top)
  FRAME_PADDING_H   = 8,   -- Horizontal frame padding
  FRAME_PADDING_V   = 7,   -- Vertical frame padding
  BODY_PADDING_H    = 8,   -- Body child horizontal padding
  BODY_PADDING_V    = 6,   -- Body child vertical padding
  ITEM_SPACING      = 6,   -- Item spacing (both H and V)
  
  -- Status bar
  STATUS_BAR_HEIGHT = 26,
  STATUS_BAR_PAD    = 6,
  
  -- Tab colors (RGBA hex)
  TAB_ACTIVE_BG     = 0x242424FF,
  TAB_CLICKED_BG    = 0x2A2A2AFF,
  TAB_HOVERED_BG    = 0x202020FF,
  TAB_INACTIVE_BG   = 0x1A1A1AFF,
  TAB_BORDER        = 0x000000FF,
  TAB_TEXT_ACTIVE   = 0xFFFFFFFF,
  TAB_TEXT_INACTIVE = 0xBBBBBB6D,
  
  -- Body colors
  BODY_BG           = 0x242424FF,
  ERROR_TEXT        = 0xFF4444FF,
  
  -- Brand colors (can be overridden in opts)
  BRAND_COLOR       = 0x00B88FCC,
  BRAND_HOVER       = 0x33CCB8CC,
  BRAND_DOWN        = 0x00A07ACC,
  
  -- Text positioning tweaks
  TAB_TEXT_OFFSET_Y = 3,   -- Vertical offset for tab text
  
  -- Other
  BORDER_FUDGE      = 1,   -- Border adjustment for footer positioning
}

----------------------------------------------------------------
-- Fonts
----------------------------------------------------------------
local function load_fonts(ctx, base_dir)
  local SEP = package.config:sub(1,1)
  local F   = base_dir .. "fonts" .. SEP
  local R   = F .. "Roboto-Regular.ttf"
  local M_  = F .. "Roboto-Medium.ttf"
  local B   = F .. "Roboto-Bold.ttf"

  local function exists(p)
    local f = io.open(p, "rb")
    if f then f:close() return true end
  end

  local reg = exists(R) and reaper.ImGui_CreateFontFromFile(R, 0, 0) or reaper.ImGui_CreateFont('sans-serif')
  local med = exists(M_) and reaper.ImGui_CreateFontFromFile(M_, 0, 0) or reg
  local bld = exists(B)  and reaper.ImGui_CreateFontFromFile(B,  0, 0) or reg

  reaper.ImGui_Attach(ctx, reg)
  reaper.ImGui_Attach(ctx, med)
  reaper.ImGui_Attach(ctx, bld)

  return {
    default = { face = reg, size = CONFIG.FONT_SIZE_DEFAULT },
    tabs    = { face = med, size = CONFIG.FONT_SIZE_TABS },
    title   = { face = bld, size = CONFIG.FONT_SIZE_TITLE },
  }
end

local function push_font(ctx, f)
  reaper.ImGui_PushFont(ctx, f.face, f.size)
end

----------------------------------------------------------------
-- Tabs normalization
----------------------------------------------------------------
local function normalize_tabs(tabs_in)
  local out = {}
  for i, t in ipairs(tabs_in or {}) do
    local id = (type(t) == "table" and t.id) or ("Tab " .. i)
    if type(t) == "function" then
      out[i] = { id = id, draw = t }
    elseif type(t) == "table" then
      if type(t.draw) == "function" then
        out[i] = { id = id, draw = t.draw, begin_frame = t.begin_frame, on_hide = t.on_hide, on_show = t.on_show }
      elseif type(t.draw) == "table" and type(t.draw.draw) == "function" then
        local o = t.draw
        out[i] = { id = id, draw = o.draw, begin_frame = o.begin_frame, on_hide = o.on_hide, on_show = o.on_show }
      else
        out[i] = {
          id          = id,
          draw        = (type(t.draw)        == "function") and t.draw        or function() end,
          begin_frame = (type(t.begin_frame) == "function") and t.begin_frame or nil,
          on_hide     = (type(t.on_hide)     == "function") and t.on_hide     or nil,
          on_show     = (type(t.on_show)     == "function") and t.on_show     or nil,
        }
      end
    else
      out[i] = { id = id, draw = function() end }
    end
  end
  return out
end

----------------------------------------------------------------
-- Pixel snapping helpers (kills blurry 1px borders)
----------------------------------------------------------------
local function snap(x) return math.floor(x + 0.5) end

----------------------------------------------------------------
-- Header (tabstrip) – fixed-width tabs with text clipping
----------------------------------------------------------------
local function draw_tabstrip(ctx, tabs, active_idx, fonts, colors, header_h, pull_up)
  push_font(ctx, fonts.tabs)

  local win_w = select(1, reaper.ImGui_GetContentRegionAvail(ctx)) or 0
  local cursor_x, cursor_y = reaper.ImGui_GetCursorScreenPos(ctx)

  pull_up = pull_up or CONFIG.HEADER_PULL_UP
  cursor_y = cursor_y - pull_up
  reaper.ImGui_SetCursorScreenPos(ctx, cursor_x, cursor_y)

  local tab_count  = #tabs
  local tab_height = header_h or CONFIG.HEADER_HEIGHT
  local dl         = reaper.ImGui_GetWindowDrawList(ctx)
  local active_tab_rect = nil

  -- pixel snapping
  local function snap(v) return math.floor(v + 0.5) end

  -- pre-slice equal widths
  local edges = {}
  for i = 0, tab_count do
    edges[i] = snap(cursor_x + (win_w * i) / math.max(1, tab_count))
  end

  -- small inner padding for safe clipping (prevents drawing under borders)
  local CLIP_PAD = 6

  for i, t in ipairs(tabs) do
    local x1 = edges[i - 1]
    local x2 = edges[i]
    local y1 = snap(cursor_y)
    local y2 = snap(cursor_y + tab_height)
    local w  = x2 - x1

    -- hit area
    reaper.ImGui_SetCursorScreenPos(ctx, x1, y1)
    reaper.ImGui_InvisibleButton(ctx, "##tab"..i, w, y2 - y1)

    local is_hovered = reaper.ImGui_IsItemHovered(ctx)
    local is_clicked = reaper.ImGui_IsItemActive(ctx)
    if reaper.ImGui_IsItemClicked(ctx) then active_idx = i end
    local is_active  = (i == active_idx)

    -- background
    local bg =
      (is_active and CONFIG.TAB_ACTIVE_BG) or
      (is_clicked and CONFIG.TAB_CLICKED_BG) or
      (is_hovered and CONFIG.TAB_HOVERED_BG) or
      CONFIG.TAB_INACTIVE_BG

    reaper.ImGui_DrawList_AddRectFilled(dl, x1, y1, x2, y2, bg, 0)

    -- borders
    local bc = CONFIG.TAB_BORDER
    reaper.ImGui_DrawList_AddLine(dl, x1, y1, x2, y1, bc, 1)      -- top
    if i > 1         then reaper.ImGui_DrawList_AddLine(dl, x1, y1, x1, y2, bc, 1) end -- left
    if i == tab_count then reaper.ImGui_DrawList_AddLine(dl, x2, y1, x2, y2, bc, 1) end -- right
    if not is_active then
      reaper.ImGui_DrawList_AddLine(dl, x1, y2, x2, y2, bc, 1)    -- bottom for inactive
    else
      active_tab_rect = { x1 = x1, x2 = x2, y = y2 }
    end

    -- label: centered when it fits, else left-align + clip on RIGHT only
    local text = t.id or ""
    local tw, th = reaper.ImGui_CalcTextSize(ctx, text)
    local PAD_L, PAD_R = 8, 6
    local tc = is_active and CONFIG.TAB_TEXT_ACTIVE or CONFIG.TAB_TEXT_INACTIVE

    local w = x2 - x1
    local usable_w = w - (PAD_L + PAD_R)
    local tx, ty

    if tw <= usable_w then
      -- Centered (no clipping needed)
      tx = snap(x1 + (w - tw) * 0.5)
      ty = snap(y1 + (tab_height - th) * 0.5 + CONFIG.TAB_TEXT_OFFSET_Y)
      reaper.ImGui_DrawList_AddText(dl, tx, ty, tc, text)
    else
      -- Too wide: left-align, clip only on the right
      tx = snap(x1 + PAD_L)
      ty = snap(y1 + (tab_height - th) * 0.5 + CONFIG.TAB_TEXT_OFFSET_Y)
      local clip_x1 = snap(x1 + PAD_L)   -- same as tx; no left clipping needed
      local clip_x2 = snap(x2 - PAD_R)   -- hard right cutoff
      reaper.ImGui_DrawList_PushClipRect(dl, clip_x1, y1, clip_x2, y2, true)
      reaper.ImGui_DrawList_AddText(dl, tx, ty, tc, text)
      reaper.ImGui_DrawList_PopClipRect(dl)
    end
  end

  -- active thick baseline + edge continuation
  if active_tab_rect then
    local bottom_y = snap(cursor_y + tab_height)
    local left_edge = edges[0]
    local right_edge = edges[tab_count]

    if active_tab_rect.x1 > left_edge then
      reaper.ImGui_DrawList_AddLine(dl, left_edge, bottom_y, active_tab_rect.x1 - 1, bottom_y, CONFIG.TAB_BORDER, 1)
    end
    if active_tab_rect.x2 < right_edge then
      reaper.ImGui_DrawList_AddLine(dl, active_tab_rect.x2 + 1, bottom_y, right_edge, bottom_y, CONFIG.TAB_BORDER, 1)
    end
    reaper.ImGui_DrawList_AddRectFilled(dl,
      active_tab_rect.x1, bottom_y - 1, active_tab_rect.x2, bottom_y + 1, CONFIG.TAB_ACTIVE_BG)
  end

  reaper.ImGui_SetCursorScreenPos(ctx, snap(cursor_x), snap(cursor_y + tab_height))
  reaper.ImGui_PopFont(ctx)
  return active_idx
end

----------------------------------------------------------------
-- App
----------------------------------------------------------------
function M.run(opts)
  opts = opts or {}
  local title  = opts.title or 'App'
  local style  = opts.style
  local tabs   = normalize_tabs(opts.tabs or {})
  local theme  = opts.theme

  local colors = {
    active = opts.brandColor or CONFIG.BRAND_COLOR,
    hover  = opts.brandHover or CONFIG.BRAND_HOVER,
    down   = opts.brandDown  or CONFIG.BRAND_DOWN,
  }

  local ctx = reaper.ImGui_CreateContext(title)

  local SEP = package.config:sub(1,1)
  local src = debug.getinfo(1, 'S').source:sub(2)
  local base_dir = (src:match("(.*"..SEP..")") or ("."..SEP)):gsub("core"..SEP.."$", "")

  local fonts = load_fonts(ctx, base_dir)

  -- === settings store (persist active tab + window geom) =====================
  local settings = opts.settings_store or require('settings').open(base_dir .. "cache", "settings.json")
  local ui_store = settings:sub("ui")
  local saved_active = tonumber(ui_store:get("active_tab", 1)) or 1
  if saved_active < 1 or saved_active > #tabs then saved_active = 1 end

  local saved_pos  = ui_store:get("win.pos", nil)  -- {x=,y=}
  local saved_size = ui_store:get("win.size", nil) -- {w=,h=}
  local applied_geometry_once = false
  local function apply_saved_geometry_once()
    if applied_geometry_once then return end
    if saved_pos and saved_pos.x and saved_pos.y then
      reaper.ImGui_SetNextWindowPos(ctx, saved_pos.x, saved_pos.y)
    else
      reaper.ImGui_SetNextWindowPos(ctx, CONFIG.WINDOW_INITIAL_X, CONFIG.WINDOW_INITIAL_Y)
    end
    if saved_size and saved_size.w and saved_size.h then
      reaper.ImGui_SetNextWindowSize(ctx, saved_size.w, saved_size.h)
    else
      reaper.ImGui_SetNextWindowSize(ctx, CONFIG.WINDOW_INITIAL_W, CONFIG.WINDOW_INITIAL_H)
    end
    applied_geometry_once = true
  end
  -- ==========================================================================

  local WIN_FLAGS = (reaper.ImGui_WindowFlags_NoCollapse and reaper.ImGui_WindowFlags_NoCollapse() or 0)
  if reaper.ImGui_WindowFlags_NoScrollbar then
    WIN_FLAGS = WIN_FLAGS | reaper.ImGui_WindowFlags_NoScrollbar()
  end
  if reaper.ImGui_WindowFlags_NoScrollWithMouse then
    WIN_FLAGS = WIN_FLAGS | reaper.ImGui_WindowFlags_NoScrollWithMouse()
  end

  local status_bar = require('status_bar').create(theme, { 
    height = CONFIG.STATUS_BAR_HEIGHT, 
    pad = CONFIG.STATUS_BAR_PAD 
  })
  if status_bar.set_fonts then status_bar.set_fonts(fonts) end
  local HAS_CHILD_DRAW = (type(status_bar.draw_child) == "function")

  local state = {
    active_idx           = saved_active, -- restored
    _did_initial_on_show = false,
    status_note          = nil,
  }

  local function destroy()
    local cur = tabs[state.active_idx]
    if cur and cur.on_hide then pcall(cur.on_hide) end
    -- final flush settings
    if settings and settings.flush then settings:flush() end
    if reaper.ImGui_DestroyContext then reaper.ImGui_DestroyContext(ctx) end
  end

  local function first_use()
    -- Geometry is applied by our own setter above; we still clamp min size.
    if reaper.ImGui_SetNextWindowSizeConstraints then
      reaper.ImGui_SetNextWindowSizeConstraints(ctx, CONFIG.WINDOW_MIN_W, CONFIG.WINDOW_MIN_H, 9999, 9999)
    end
  end

  -- Get proper child flags including NoMove to prevent dragging from content
  local CHILD_NONE = (reaper.ImGui_ChildFlags_None and reaper.ImGui_ChildFlags_None() or 0)
  local CHILD_NO_MOVE = 0
  if reaper.ImGui_ChildFlags_NoMove then
    CHILD_NO_MOVE = reaper.ImGui_ChildFlags_NoMove()
  end
  
  local open = true

  local HEADER_PULL_UP = CONFIG.HEADER_PULL_UP
  local header_h       = CONFIG.HEADER_HEIGHT

  local function frame()
    if not open then destroy(); return end

    -- apply saved geom (once, before Begin)
    apply_saved_geometry_once()
    first_use()

    if style and style.PushMyStyle then style.PushMyStyle(ctx) end

    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowPadding(), CONFIG.WINDOW_PADDING_H, CONFIG.WINDOW_PADDING_V)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(),  CONFIG.FRAME_PADDING_H, CONFIG.FRAME_PADDING_V)
    push_font(ctx, fonts.title)
    local visible, wnd_open = reaper.ImGui_Begin(ctx, title, true, WIN_FLAGS)
    reaper.ImGui_PopFont(ctx)
    reaper.ImGui_PopStyleVar(ctx, 2)
    open = (wnd_open ~= false)

    if visible then
      -- capture live geometry and persist (debounced by store)
      do
        local wx, wy = reaper.ImGui_GetWindowPos(ctx)
        local ww, wh = reaper.ImGui_GetWindowSize(ctx)
        local pos = { x = math.floor(wx + 0.5), y = math.floor(wy + 0.5) }
        local sz  = { w = math.floor(ww + 0.5), h = math.floor(wh + 0.5) }
        -- only write if changed
        if (not saved_pos) or (pos.x ~= saved_pos.x or pos.y ~= saved_pos.y) then
          saved_pos = pos
          ui_store:set("win.pos", saved_pos)
        end
        if (not saved_size) or (sz.w ~= saved_size.w or sz.h ~= saved_size.h) then
          saved_size = sz
          ui_store:set("win.size", saved_size)
        end
      end

      local footer_h_total  = (status_bar.height or 26) + (status_bar.pad or 0)
      local BORDER_FUDGE    = CONFIG.BORDER_FUDGE
      local reserve_h_body  = math.max(0, footer_h_total - BORDER_FUDGE)

      do
        local no_scroll = (reaper.ImGui_WindowFlags_NoScrollbar() | reaper.ImGui_WindowFlags_NoScrollWithMouse())

        local win_x, _ = reaper.ImGui_GetWindowPos(ctx)
        local win_w, _ = reaper.ImGui_GetWindowSize(ctx)
        local _, content_y = reaper.ImGui_GetCursorScreenPos(ctx)

        reaper.ImGui_SetCursorScreenPos(ctx, snap(win_x), snap(content_y))
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowPadding(), 0, 0)
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ChildBorderSize(), 0)

        if reaper.ImGui_BeginChild(ctx, "##header", snap(win_w), header_h + HEADER_PULL_UP, CHILD_NONE, no_scroll) then
          if not state._did_initial_on_show and tabs[state.active_idx] and tabs[state.active_idx].on_show then
            pcall(tabs[state.active_idx].on_show)
            state._did_initial_on_show = true
          end
          local new_idx = draw_tabstrip(ctx, tabs, state.active_idx, fonts, colors, header_h, HEADER_PULL_UP)
          if new_idx ~= state.active_idx then
            local prev, nextt = tabs[state.active_idx], tabs[new_idx]
            if prev  and prev.on_hide then pcall(prev.on_hide) end
            if nextt and nextt.on_show then pcall(nextt.on_show) end
            state.active_idx = new_idx
            -- persist active tab immediately
            ui_store:set("active_tab", state.active_idx)
          end
          reaper.ImGui_EndChild(ctx)
        end
        reaper.ImGui_PopStyleVar(ctx, 2)
      end

      do
        local avail_w, avail_h = reaper.ImGui_GetContentRegionAvail(ctx)
        avail_w = avail_w or 0; avail_h = avail_h or 0

        local body_h = math.max(1, (avail_h - reserve_h_body + HEADER_PULL_UP))

        local cur_x, cur_y = reaper.ImGui_GetCursorScreenPos(ctx)
        reaper.ImGui_SetCursorScreenPos(ctx, snap(cur_x), snap(cur_y - HEADER_PULL_UP))

        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowPadding(), CONFIG.BODY_PADDING_H, CONFIG.BODY_PADDING_V)
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ChildBorderSize(), 0)
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing(), CONFIG.ITEM_SPACING, CONFIG.ITEM_SPACING)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ChildBg(), CONFIG.BODY_BG)

        -- Use CHILD_NO_MOVE flag to prevent dragging the parent window from child content
        if reaper.ImGui_BeginChild(ctx, "##body", -1, body_h, CHILD_NONE | CHILD_NO_MOVE, 0) then
          local cur = tabs[state.active_idx]
          if cur and cur.begin_frame then pcall(cur.begin_frame) end

          if cur and cur.draw then
            push_font(ctx, fonts.default)
            local ok, err = pcall(cur.draw, ctx, state)
            reaper.ImGui_PopFont(ctx)
            if not ok then
              reaper.ImGui_TextColored(ctx, CONFIG.ERROR_TEXT, 'Tab error: ' .. tostring(err))
            end
          else
            reaper.ImGui_Text(ctx, "No tab content.")
          end

          reaper.ImGui_Dummy(ctx, 0, reserve_h_body)
          reaper.ImGui_EndChild(ctx)
        end
        reaper.ImGui_PopStyleColor(ctx, 1)
        reaper.ImGui_PopStyleVar(ctx, 3)
      end

      do
        local win_x, win_y = reaper.ImGui_GetWindowPos(ctx)
        local win_w, win_h = reaper.ImGui_GetWindowSize(ctx)

        local anchor_y = win_y + win_h - footer_h_total - (BORDER_FUDGE - 0)
        if anchor_y < win_y then anchor_y = win_y end
        reaper.ImGui_SetCursorScreenPos(ctx, snap(win_x), snap(anchor_y))

        local no_scroll = (reaper.ImGui_WindowFlags_NoScrollbar() | reaper.ImGui_WindowFlags_NoScrollWithMouse())
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowPadding(), 0, 0)
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ChildBorderSize(), 0)
        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing(), 0, 0)

        if reaper.ImGui_BeginChild(ctx, "##footer", snap(win_w), footer_h_total, CHILD_NONE, no_scroll) then
          if status_bar.set_right_note then status_bar.set_right_note(state.status_note) end
          if status_bar.set_main_window_info then
            status_bar.set_main_window_info(win_x, win_y, win_w, win_h)
          end
          if HAS_CHILD_DRAW then
            status_bar.draw_child(ctx, 32 or 26)
          else
            status_bar.draw(ctx)
          end
          reaper.ImGui_EndChild(ctx)
        end

        reaper.ImGui_PopStyleVar(ctx, 3)
      end
    end

    reaper.ImGui_End(ctx)
    if style and style.PopMyStyle then style.PopMyStyle(ctx) end

    -- tick debounced writer
    if settings and settings.maybe_flush then settings:maybe_flush() end

    if open then reaper.defer(frame) else destroy() end
  end

  reaper.defer(frame)
end

return M