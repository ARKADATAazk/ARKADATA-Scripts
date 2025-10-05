-- tabs/assembler/ui_packages.lua
-- Packages grid UI with rotating rounded-dash selection,
-- multi-select drag reordering (before/after with side indicator),
-- ghost preview, animated layout reflow, and window-move locking.
-- Fixed selection issues:
--   • Selection rectangle no longer triggers window drag
--   • Selection rectangle draws on top of everything
--   • Packages selected by rectangle intersection, not center point
-- Stretch behavior:
--   • pkg.tile acts as the *minimum* column width
--   • Extra horizontal space is distributed to columns to fill the row
--   • All coordinates integer-snapped to keep borders sharp
-- Selection conventions:
--   • Click tile  : select single
--   • Ctrl+Click  : toggle selection
--   • Shift+Click : select range from last clicked
--   • Click empty : clear all selection
--   • Drag empty  : rectangle-select (hold Ctrl to add, else replace)

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local M = {}

----------------------------------------------------------------
-- TUNING
----------------------------------------------------------------
local ANT_SPEED            = 20
local ANT_COLOR_ENABLED    = 0x42E896FF
local ANT_COLOR_DISABLED   = 0xFFFFFF40

local DRAG_THRESHOLD       = 6
local DROP_LINE_COLOR      = 0x42E896E0
local DROP_LINE_THICKNESS  = 4
local DROP_LINE_RADIUS     = 8

local GHOST_FILL           = 0xFFFFFF22
local GHOST_STROKE         = 0xFFFFFFFF
local GHOST_STROKE_THICK   = 2

local DIM_ORIGINAL_FILL    = 0x00000088
local DIM_ORIGINAL_STROKE  = 0xFFFFFF55

local TILE_ROUNDING        = 6

local BORDER_HOVER_THICKNESS = 1
local BORDER_ANT_THICKNESS   = 1

local LAYOUT_LERP_SPEED    = 14.0
local LAYOUT_SNAP_EPS      = 0.5

local CB_MIN_SIZE          = 12
local CB_PAD_X             = 2
local CB_PAD_Y             = 1

local CONFLICT_TEXT_COL    = 0xFFA500FF

local GRID_PADDING         = 12

----------------------------------------------------------------
-- STATE
----------------------------------------------------------------
local animations = {}
local hover_state = {}

local selection_state = {
  selected = {},
  rect_start = nil,
  rect_current = nil,
  is_dragging = false,
  did_drag = false,
  last_click_time = 0,
  last_click_pkg  = nil,
}

local drag = {
  pressed_id       = nil,
  pressed_was_sel  = false,
  press_pos        = nil,
  active           = false,
  ids              = nil,
  src_bbox         = nil,
  target_id        = nil,
  target_side      = 'before',
  curr_mouse       = nil,
}

local tile_positions = {}
local tile_draw = {}
local last_window_pos = nil

----------------------------------------------------------------
-- HELPERS
----------------------------------------------------------------
local function tooltip(ctx, text)
  if ImGui.IsItemHovered(ctx) then ImGui.SetTooltip(ctx, text or "") end
end

local function lerp(a, b, t) return a + (b - a) * math.min(1.0, t) end

local function animate_value(id, target, speed)
  speed = speed or 8.0
  animations[id] = animations[id] or target
  animations[id] = lerp(animations[id], target, speed * 0.016)
  return animations[id]
end

local function color_lerp(c1, c2, t)
  local r1 = (c1 >> 24) & 0xFF
  local g1 = (c1 >> 16) & 0xFF
  local b1 = (c1 >> 8)  & 0xFF
  local a1 =  c1        & 0xFF
  local r2 = (c2 >> 24) & 0xFF
  local g2 = (c2 >> 16) & 0xFF
  local b2 = (c2 >> 8)  & 0xFF
  local a2 =  c2        & 0xFF
  local r = math.floor(lerp(r1, r2, t))
  local g = math.floor(lerp(g1, g2, t))
  local b = math.floor(lerp(b1, b2, t))
  local a = math.floor(lerp(a1, a2, t))
  return (r << 24) | (g << 16) | (b << 8) | a
end

local function draw_centered_text(ctx, text, minx, miny, maxx, maxy, color)
  local dl = ImGui.GetWindowDrawList(ctx)
  local tw, th = ImGui.CalcTextSize(ctx, text)
  local cx = minx + math.floor((maxx - minx - tw) * 0.5)
  local cy = miny + math.floor((maxy - miny - th) * 0.5)
  ImGui.DrawList_AddText(dl, cx, cy, color or 0xFFFFFFFF, text)
end

local function is_point_in_rect(x, y, x1, y1, x2, y2)
  return x >= math.min(x1, x2) and x <= math.max(x1, x2)
     and y >= math.min(y1, y2) and y <= math.max(y1, y2)
end

local function rects_intersect(ax1, ay1, ax2, ay2, bx1, by1, bx2, by2)
  local a_left,  a_right  = math.min(ax1, ax2), math.max(ax1, ax2)
  local a_top,   a_bottom = math.min(ay1, ay2), math.max(ay1, ay2)
  local b_left,  b_right  = math.min(bx1, bx2), math.max(bx1, bx2)
  local b_top,   b_bottom = math.min(by1, by2), math.max(by1, by2)
  return not (a_left > b_right or a_right < b_left or a_top > b_bottom or a_bottom < b_top)
end

local function rect_copy(r) return {r[1], r[2], r[3], r[4], r[5]} end

local function get_order_index(pkg, id)
  for i, pid in ipairs(pkg.order) do if pid == id then return i end end
  return 0
end

----------------------------------------------------------------
-- Marching ants (rounded rectangle, rotating)
----------------------------------------------------------------
local function draw_marching_ants_rounded(dl, x1, y1, x2, y2, col, thickness, radius, dash, gap, speed_px)
  if x2 <= x1 or y2 <= y1 then return end
  local w, h = x2 - x1, y2 - y1
  local r = math.max(0, math.min(radius or TILE_ROUNDING, math.floor(math.min(w, h) * 0.5)))

  local straight_w = math.max(0, w - 2*r)
  local straight_h = math.max(0, h - 2*r)
  local arc_len = (math.pi * r) / 2
  local L1 = straight_w; local L2 = arc_len
  local L3 = straight_h; local L4 = arc_len
  local L5 = straight_w; local L6 = arc_len
  local L7 = straight_h; local L8 = arc_len
  local L  = L1 + L2 + L3 + L4 + L5 + L6 + L7 + L8
  if L <= 0 then return end

  local function draw_line_subseg(ax, ay, bx, by, u0, u1)
    local seg_len = math.max(1e-6, math.sqrt((bx-ax)^2 + (by-ay)^2))
    local t0, t1 = u0/seg_len, u1/seg_len
    local sx, sy = ax + (bx-ax)*t0, ay + (by-ay)*t0
    local ex, ey = ax + (bx-ax)*t1, ay + (by-ay)*t1
    ImGui.DrawList_AddLine(dl, sx, sy, ex, ey, col, thickness)
  end
  local function draw_arc_subseg(cx, cy, rr, a0, a1, u0, u1)
    local seg_len = math.max(1e-6, rr * math.abs(a1 - a0))
    local aa0 = a0 + (a1 - a0) * (u0 / seg_len)
    local aa1 = a0 + (a1 - a0) * (u1 / seg_len)
    local steps = math.max(1, math.floor((rr * math.abs(aa1 - aa0)) / 3))
    local prevx = cx + rr * math.cos(aa0)
    local prevy = cy + rr * math.sin(aa0)
    for i = 1, steps do
      local t = i / steps
      local ang = aa0 + (aa1 - aa0) * t
      local nx = cx + rr * math.cos(ang)
      local ny = cy + rr * math.sin(ang)
      ImGui.DrawList_AddLine(dl, prevx, prevy, nx, ny, col, thickness)
      prevx, prevy = nx, ny
    end
  end

  local function draw_subpath(s, e)
    if e <= s then return end
    local pos = 0
    if e > pos and s < pos + straight_w and straight_w > 0 then
      local u0 = math.max(0, s - pos); local u1 = math.min(straight_w, e - pos)
      draw_line_subseg(x1+r, y1, x2-r, y1, u0, u1)
    end
    pos = pos + straight_w
    if e > pos and s < pos + arc_len and arc_len > 0 then
      local u0 = math.max(0, s - pos); local u1 = math.min(arc_len, e - pos)
      draw_arc_subseg(x2 - r, y1 + r, r, -math.pi/2, 0, u0, u1)
    end
    pos = pos + arc_len
    if e > pos and s < pos + straight_h and straight_h > 0 then
      local u0 = math.max(0, s - pos); local u1 = math.min(straight_h, e - pos)
      draw_line_subseg(x2, y1+r, x2, y2-r, u0, u1)
    end
    pos = pos + straight_h
    if e > pos and s < pos + arc_len and arc_len > 0 then
      local u0 = math.max(0, s - pos); local u1 = math.min(arc_len, e - pos)
      draw_arc_subseg(x2 - r, y2 - r, r, 0, math.pi/2, u0, u1)
    end
    pos = pos + arc_len
    if e > pos and s < pos + straight_w and straight_w > 0 then
      local u0 = math.max(0, s - pos); local u1 = math.min(straight_w, e - pos)
      draw_line_subseg(x2-r, y2, x1+r, y2, u0, u1)
    end
    pos = pos + straight_w
    if e > pos and s < pos + arc_len and arc_len > 0 then
      local u0 = math.max(0, s - pos); local u1 = math.min(arc_len, e - pos)
      draw_arc_subseg(x1 + r, y2 - r, r, math.pi/2, math.pi, u0, u1)
    end
    pos = pos + arc_len
    if e > pos and s < pos + straight_h and straight_h > 0 then
      local u0 = math.max(0, s - pos); local u1 = math.min(straight_h, e - pos)
      draw_line_subseg(x1, y2-r, x1, y1+r, u0, u1)
    end
    pos = pos + straight_h
    if e > pos and s < pos + arc_len and arc_len > 0 then
      local u0 = math.max(0, s - pos); local u1 = math.min(arc_len, e - pos)
      draw_arc_subseg(x1 + r, y1 + r, r, math.pi, 3*math.pi/2, u0, u1)
    end
  end

  local dash_len = math.max(2, dash or 8)
  local gap_len  = math.max(2, gap  or 6)
  local period   = dash_len + gap_len
  local speed    = math.max(1, speed_px or 120)
  local phase_px = (reaper.time_precise() * speed) % period

  local s = -phase_px
  while s < L do
    local e = s + dash_len
    local cs = math.max(0, s)
    local ce = math.min(L, e)
    if ce > cs then draw_subpath(cs, ce) end
    s = s + period
  end
end

----------------------------------------------------------------
-- Micro-manage UI
----------------------------------------------------------------
local mm_search = ""
local mm_multi  = {}
local mm_window = { open=false, pkgId=nil }

local function ensure_excl_table(core, pkgId)
  core.pkg.excl[pkgId] = core.pkg.excl[pkgId] or {}
  return core.pkg.excl[pkgId]
end

local function draw_micro_manage_core(ctx, core, P, on_close)
  local flags = core.flags

  ImGui.SetNextItemWidth(ctx, 220)
  local ch_s, new_q = ImGui.InputText(ctx, 'Search##mm', mm_search or '')
  if ch_s then mm_search = new_q end
  ImGui.SameLine(ctx)
  if ImGui.Button(ctx, 'Close##mm') then if on_close then on_close() end end

  local excl = ensure_excl_table(core, P.id)
  if ImGui.Button(ctx, 'Select all##mm') then
    for _,k in ipairs(P.keys_order) do if (mm_search=='' or k:find(mm_search,1,true)) then mm_multi[k]=true end end
  end
  ImGui.SameLine(ctx)
  if ImGui.Button(ctx, 'Clear selection##mm') then mm_multi = {} end
  ImGui.SameLine(ctx)
  if ImGui.Button(ctx, 'Include selected') then
    for key,sel in pairs(mm_multi) do if sel then excl[key]=nil end end
    if core.deps.settings then core.deps.settings:set('pkg_exclusions', core.pkg.excl) end
  end
  ImGui.SameLine(ctx)
  if ImGui.Button(ctx, 'Exclude selected') then
    for key,sel in pairs(mm_multi) do if sel then excl[key]=true end end
    if core.deps.settings then core.deps.settings:set('pkg_exclusions', core.pkg.excl) end
  end
  ImGui.SameLine(ctx)
  if ImGui.Button(ctx, 'Pin selected to this package') then
    for key,sel in pairs(mm_multi) do if sel then core.pkg.pins[key]=P.id end end
    if core.deps.settings then core.deps.settings:set('pkg_pins', core.pkg.pins) end
  end

  local tbl_flags = core.bor(core.flags.TBL_BORDERS, core.flags.TBL_ROWBG, core.flags.TBL_STRETCH)
  if ImGui.BeginTable(ctx, 'mm_table##'..P.id, 4, tbl_flags) then
    ImGui.TableSetupColumn(ctx, 'Sel',     core.flags.COL_WIDTH_FIXED, 36)
    ImGui.TableSetupColumn(ctx, 'Include', core.flags.COL_WIDTH_FIXED, 70)
    ImGui.TableSetupColumn(ctx, 'Key')
    ImGui.TableSetupColumn(ctx, 'Pinned Provider', core.flags.COL_WIDTH_FIXED, 180)
    ImGui.TableHeadersRow(ctx)

    for _, key in ipairs(P.keys_order) do
      if (mm_search=='' or key:find(mm_search,1,true)) then
        ImGui.TableNextRow(ctx)

        ImGui.TableSetColumnIndex(ctx, 0)
        local sel = mm_multi[key] == true
        local c1, v1 = ImGui.Checkbox(ctx, '##sel-'..key, sel); if c1 then mm_multi[key] = v1 end

        ImGui.TableSetColumnIndex(ctx, 1)
        local included = excl[key] ~= true
        local c2, v2 = ImGui.Checkbox(ctx, '##inc-'..key, included)
        if c2 then
          if v2 then excl[key] = nil else excl[key] = true end
          if core.deps.settings then core.deps.settings:set('pkg_exclusions', core.pkg.excl) end
        end

        ImGui.TableSetColumnIndex(ctx, 2)
        ImGui.Text(ctx, key)

        ImGui.TableSetColumnIndex(ctx, 3)
        local current = core.pkg.pins[key] or '(none)'
        local preview = (current=='(none)') and '(none)' or current
        if ImGui.BeginCombo(ctx, '##pin-'..key, preview) then
          if ImGui.Selectable(ctx, '(none)', current=='(none)') then
            core.pkg.pins[key]=nil
            if core.deps.settings then core.deps.settings:set('pkg_pins', core.pkg.pins) end
          end
          for _, PP in ipairs(core.pkg.index) do
            if PP.assets[key] then
              local sel2 = (current == PP.id)
              if ImGui.Selectable(ctx, PP.id, sel2) then
                core.pkg.pins[key]=PP.id
                if core.deps.settings then core.deps.settings:set('pkg_pins', core.pkg.pins) end
              end
            end
          end
          ImGui.EndCombo(ctx)
        end
      end
    end
    ImGui.EndTable(ctx)
  end
end

local function draw_micro_manage_window(ctx, core)
  if not (mm_window.open and mm_window.pkgId) then return end
  local map = {}; for _,P in ipairs(core.pkg.index) do map[P.id]=P end
  local P = map[mm_window.pkgId]
  if not P then mm_window.open=false; mm_window.pkgId=nil; return end
  local title = ("Package • %s – Micro-manage##mmw-%s"):format(P.meta.name or P.id, P.id)
  if ImGui.Begin(ctx, title) then
    ImGui.Text(ctx, P.path or "(mock package)")
    ImGui.Separator(ctx)
    draw_micro_manage_core(ctx, core, P, function() mm_window.open=false; mm_window.pkgId=nil end)
  end
  ImGui.End(ctx)
end

----------------------------------------------------------------
-- DRAG helpers
----------------------------------------------------------------
local function count_selected()
  local n = 0
  for _,sel in pairs(selection_state.selected) do if sel then n = n + 1 end end
  return n
end

local function ordered_selection_in_pkg_order(pkg)
  local out = {}
  for _, id in ipairs(pkg.order) do
    if selection_state.selected[id] then out[#out+1] = id end
  end
  return out
end

local function compute_group_bbox(ids)
  local x1,y1,x2,y2 = math.huge, math.huge, -math.huge, -math.huge
  for _, id in ipairs(ids) do
    local r = tile_draw[id] or tile_positions[id]
    if r then
      x1 = math.min(x1, r[1]); y1 = math.min(y1, r[2])
      x2 = math.max(x2, r[3]); y2 = math.max(y2, r[4])
    end
  end
  if x1 == math.huge then return nil end
  return {x1,y1,x2,y2}
end

local function set_from(list)
  local t = {}
  for _,id in ipairs(list or {}) do t[id] = true end
  return t
end

local function perform_group_insert_relative(pkg, ids, target_id, side)
  if not ids or #ids == 0 or not target_id then return end
  local dragging = set_from(ids)
  if dragging[target_id] then return end

  local base = {}
  for _, id in ipairs(pkg.order) do if not dragging[id] then base[#base+1] = id end end

  local insert_idx = #base + 1
  for i, id in ipairs(base) do
    if id == target_id then
      insert_idx = (side == 'after') and (i + 1) or i
      break
    end
  end

  local new_order = {}
  for i = 1, insert_idx - 1 do new_order[#new_order + 1] = base[i] end
  for _, id in ipairs(ids) do new_order[#new_order + 1] = id end
  for i = insert_idx, #base do new_order[#new_order + 1] = base[i] end

  pkg.order = new_order
end

----------------------------------------------------------------
-- CHECKBOX GEOMETRY
----------------------------------------------------------------
local function compute_checkbox_rect(ctx, pkg, id, r_minx, r_miny, r_maxx, r_maxy)
  local ord = get_order_index(pkg, id)
  local badge = '#' .. tostring(ord)
  local _, bh = ImGui.CalcTextSize(ctx, badge)
  local cb_size = math.max(CB_MIN_SIZE, math.floor(bh + 2))

  local MARGIN = 8
  local x2 = r_maxx - MARGIN
  local y1 = r_miny + MARGIN
  local x1 = x2 - cb_size
  local y2 = y1 + cb_size
  return x1, y1, x2, y2, cb_size
end

----------------------------------------------------------------
-- TILE RENDERING
----------------------------------------------------------------
local function draw_package_tile(ctx, core, P, idx, minx, miny, maxx, maxy)
  local dl = ImGui.GetWindowDrawList(ctx)
  local pkg = core.pkg
  local tile_w = maxx - minx

  local hover_id  = 'hover_'  .. P.id
  local active_id = 'active_' .. P.id

  local is_active   = pkg.active[P.id] == true
  local is_selected = selection_state.selected[P.id] == true
  local is_hovered  = hover_state[P.id] == true

  local hover_factor  = animate_value(hover_id,  is_hovered and 1.0 or 0.0, 12.0)
  local active_factor = animate_value(active_id, is_active  and 1.0 or 0.0,  8.0)

  local BG_INACTIVE   = 0x1A1A1AFF
  local BG_ACTIVEBASE = 0x2D4A37FF
  local BG_ACTIVE     = color_lerp(BG_INACTIVE, BG_ACTIVEBASE, active_factor)
  local BG_FINAL      = color_lerp(BG_ACTIVE, 0x2A2A2AFF, hover_factor * 0.4)

  local BRD_INACTIVE  = 0x303030FF
  local BRD_ACTIVE    = 0x42E896FF
  local BRD_HOVER     = 0xCCCCCCFF
  local BRD_BASE      = color_lerp(BRD_INACTIVE, BRD_ACTIVE, active_factor)
  local BRD_FINAL     = is_hovered and color_lerp(BRD_BASE, BRD_HOVER, hover_factor) or BRD_BASE

  if hover_factor > 0.01 and not is_selected then
    local shadow_alpha = math.floor(hover_factor * 20)
    local shadow_col = (0x000000 << 8) | shadow_alpha
    for i = 2, 1, -1 do
      ImGui.DrawList_AddRectFilled(dl, minx - i, miny - i + 2, maxx + i, maxy + i + 2, shadow_col, TILE_ROUNDING)
    end
  end

  ImGui.DrawList_AddRectFilled(dl, minx, miny, maxx, maxy, BG_FINAL, TILE_ROUNDING)

  if is_selected then
    local sel_col = is_active and ANT_COLOR_ENABLED or ANT_COLOR_DISABLED
    draw_marching_ants_rounded(
      dl, minx+0.5, miny+0.5, maxx-0.5, maxy-0.5,
      sel_col, BORDER_ANT_THICKNESS, TILE_ROUNDING, 8, 6, ANT_SPEED
    )
  else
    local border_thickness = BORDER_HOVER_THICKNESS
    core.add_rect(dl, minx, miny, maxx, maxy, BRD_FINAL, TILE_ROUNDING, border_thickness)
  end

  local ord = get_order_index(pkg, P.id)
  local badge = '#' .. tostring(ord)
  local bw, bh = ImGui.CalcTextSize(ctx, badge)
  local bx1, by1 = minx + 8, miny + 8
  local bx2, by2 = bx1 + bw + 10, by1 + bh + 6
  local badge_col = is_active and 0x00000099 or 0x00000066
  ImGui.DrawList_AddRectFilled(dl, bx1, by1, bx2, by2, badge_col, 4)
  draw_centered_text(ctx, badge, bx1, by1, bx2, by2, 0xAAAAAAFF)

  ImGui.SetCursorScreenPos(ctx, bx1, by1)
  ImGui.InvisibleButton(ctx, '##ordtip-'..P.id, bx2-bx1, by2-by1)
  tooltip(ctx, "Overwrite priority")

  local conflicts = core.pkg:conflicts(true)
  local conf = conflicts[P.id] or 0
  if conf > 0 then
    local ctext = string.format('%d conflicts', conf)
    local cw, ch = ImGui.CalcTextSize(ctx, ctext)
    local cx_mid = (minx + maxx) * 0.5
    local tx = math.floor(cx_mid - cw * 0.5)
    local ty = miny + 8
    ImGui.DrawList_AddText(dl, tx, ty, CONFLICT_TEXT_COL, ctext)

    ImGui.SetCursorScreenPos(ctx, tx, ty)
    ImGui.InvisibleButton(ctx, '##conftip-'..P.id, cw, ch)
    tooltip(ctx, "Conflicting Assets in Packages\n(autosolved through Overwrite Priority)")
  end

  do
    local cbx1, cby1, cbx2, cby2 = compute_checkbox_rect(ctx, pkg, P.id, minx, miny, maxx, maxy)
    ImGui.SetCursorScreenPos(ctx, cbx1, cby1)
    ImGui.PushID(ctx, 'cb-'..P.id)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, CB_PAD_X, CB_PAD_Y)
    local changed, new_active = ImGui.Checkbox(ctx, '##enable', is_active)
    ImGui.PopStyleVar(ctx)
    tooltip(ctx, is_active and "Disable package" or "Enable package")
    ImGui.PopID(ctx)
    if changed then
      pkg.active[P.id] = new_active
      if core.deps.settings then core.deps.settings:set('pkg_active', pkg.active) end
    end
  end

  local mosaic_padding = 15
  local cell_size = math.min(math.floor((tile_w - mosaic_padding * 2 - 12) / 3), 50)
  local total_mosaic_width = cell_size * 3 + 12
  local mosaic_x = minx + math.floor((tile_w - total_mosaic_width) / 2)
  local mosaic_y = miny + 45

  local source = P.meta.mosaic or { P.keys_order[1], P.keys_order[2], P.keys_order[3] }
  for i = 1, math.min(3, #source) do
    local fname = source[i] or "asset"
    local key = fname and fname:gsub("%.%w+$","") or "asset"
    local label = key:sub(1,3):upper()
    local col = core.color_from_key(key)
    local cxx = mosaic_x + (i-1) * (cell_size + 6)
    local cyy = mosaic_y
    ImGui.DrawList_AddRectFilled(dl, cxx, cyy, cxx + cell_size, cyy + cell_size, col, 3)
    core.add_rect(dl, cxx, cyy, cxx + cell_size, cyy + cell_size, 0x00000088, 3, 1)
    draw_centered_text(ctx, label, cxx, cyy, cxx + cell_size, cyy + cell_size, 0xFFFFFFFF)
  end

  local footer_y = maxy - 32
  local footer_gradient = 0x00000044
  ImGui.DrawList_AddRectFilled(dl, minx, footer_y, maxx, maxy, footer_gradient, 0, 12)

  local name = P.meta.name or P.id
  local name_color = is_active and 0xFFFFFFFF or 0x999999FF
  ImGui.SetCursorScreenPos(ctx, minx + 10, footer_y + 7)
  ImGui.PushStyleColor(ctx, ImGui.Col_Text, name_color)
  ImGui.Text(ctx, name)
  ImGui.PopStyleColor(ctx)

  local count = 0; for _ in pairs(P.assets) do count = count + 1 end
  local count_lbl = string.format('%d assets', count)
  local label_w = select(1, ImGui.CalcTextSize(ctx, count_lbl)) or 0
  ImGui.SetCursorScreenPos(ctx, maxx - 10 - label_w, footer_y + 7)
  ImGui.TextColored(ctx, 0x888888FF, count_lbl)
end

----------------------------------------------------------------
-- GRID BACKGROUND & selection rect
----------------------------------------------------------------
local function handle_selection_rect(ctx, core, grid_height, visible)
  local content_min_x, content_min_y = ImGui.GetCursorScreenPos(ctx)
  local avail_w = select(1, ImGui.GetContentRegionAvail(ctx)) or 0

  local mx, my = ImGui.GetMousePos(ctx)
  local over_any_checkbox = false
  local pkg = core.pkg
  for _, P in ipairs(visible) do
    local r = tile_draw[P.id] or tile_positions[P.id]
    if r then
      local cbx1, cby1, cbx2, cby2 = compute_checkbox_rect(ctx, pkg, P.id, r[1], r[2], r[3], r[4])
      if is_point_in_rect(mx, my, cbx1, cby1, cbx2, cby2) then
        over_any_checkbox = true
        break
      end
    end
  end

  if over_any_checkbox then
    ImGui.Dummy(ctx, avail_w, grid_height)
  else
    ImGui.InvisibleButton(ctx, "##grid_background", avail_w, grid_height)
  end

  local bg_clicked = ImGui.IsItemClicked(ctx, core.flags.MB_LEFT)

  if bg_clicked then
    local mx2, my2 = ImGui.GetMousePos(ctx)
    local over_tile = false
    for _, P in ipairs(visible) do
      local r = tile_draw[P.id] or tile_positions[P.id]
      if r and is_point_in_rect(mx2, my2, r[1], r[2], r[3], r[4]) then
        over_tile = true
        break
      end
    end

    if not over_tile then
      selection_state.rect_start = {mx2, my2}
      selection_state.rect_current = nil
      selection_state.is_dragging = true
      selection_state.did_drag = false
    end
  end

  if selection_state.is_dragging then
    if ImGui.IsMouseDragging(ctx, core.flags.MB_LEFT, 5) then
      local mx2, my2 = ImGui.GetMousePos(ctx)
      selection_state.rect_current = {mx2, my2}
      selection_state.did_drag = true
    end
  end

  if selection_state.is_dragging and ImGui.IsMouseReleased(ctx, core.flags.MB_LEFT) then
    if not selection_state.did_drag then
      selection_state.selected = {}
      selection_state.last_click_pkg = nil
    end
    selection_state.is_dragging = false
    selection_state.rect_start = nil
    selection_state.rect_current = nil
    selection_state.did_drag = false
  end

  ImGui.SetCursorScreenPos(ctx, content_min_x, content_min_y)
end

local function draw_selection_rect(ctx)
  if selection_state.is_dragging and selection_state.rect_start and selection_state.rect_current then
    local dl = ImGui.GetWindowDrawList(ctx)
    local x1, y1 = selection_state.rect_start[1], selection_state.rect_start[2]
    local x2, y2 = selection_state.rect_current[1], selection_state.rect_current[2]
    ImGui.DrawList_AddRectFilled(dl, math.min(x1, x2), math.min(y1, y2),
                                             math.max(x1, x2), math.max(y1, y2), 0xFFFFFF22, TILE_ROUNDING)
    ImGui.DrawList_AddRect(dl,       math.min(x1, x2), math.min(y1, y2),
                                             math.max(x1, x2), math.max(y1, y2), 0xFFFFFFFF, TILE_ROUNDING, 0, 1)
  end
end

----------------------------------------------------------------
-- MAIN DRAW
----------------------------------------------------------------
function M.draw(ctx, core)
  local flags, bor = core.flags, core.bor
  local pkg = core.pkg

  ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameRounding, 4)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 6, 3)

  if pkg.demo == nil then pkg.demo = false end
  local ch_demo, nv_demo = ImGui.Checkbox(ctx, 'Demo/mock data', pkg.demo)
  if ch_demo then pkg.demo = nv_demo; if core.deps.settings then core.deps.settings:set('pkg_demo', pkg.demo) end; pkg:scan() end

  ImGui.SameLine(ctx)
  ImGui.SetNextItemWidth(ctx, 200)
  local ch_s, new_q = ImGui.InputText(ctx, 'Search', pkg.search or '')
  if ch_s then pkg.search = new_q; if core.deps.settings then core.deps.settings:set('pkg_search', pkg.search) end end

  ImGui.SameLine(ctx)
  ImGui.SetNextItemWidth(ctx, 140)
  local base_min = 160
  local base_max = 420
  if pkg.tile == nil then pkg.tile = 220 end
  local ch_t, new_tile = ImGui.SliderInt(ctx, '##TileSizeMin', pkg.tile, base_min, base_max)
  if ch_t then pkg.tile = new_tile; if core.deps.settings then core.deps.settings:set('pkg_tilesize', pkg.tile) end end
  ImGui.SameLine(ctx)
  ImGui.Text(ctx, 'Size')

  ImGui.SameLine(ctx)
  local c1, v1 = ImGui.Checkbox(ctx, 'TCP', pkg.filters.TCP); if c1 then pkg.filters.TCP = v1 end
  ImGui.SameLine(ctx)
  local c2, v2 = ImGui.Checkbox(ctx, 'MCP', pkg.filters.MCP); if c2 then pkg.filters.MCP = v2 end
  ImGui.SameLine(ctx)
  local c3, v3 = ImGui.Checkbox(ctx, 'Transport', pkg.filters.Transport); if c3 then pkg.filters.Transport = v3 end
  ImGui.SameLine(ctx)
  local c4, v4 = ImGui.Checkbox(ctx, 'Global', pkg.filters.Global); if c4 then pkg.filters.Global = v4 end
  if c1 or c2 or c3 or c4 then if core.deps.settings then core.deps.settings:set('pkg_filters', pkg.filters) end end

  ImGui.SameLine(ctx)
  if ImGui.Button(ctx, 'Rescan##pkgs') then pkg:scan() end

  ImGui.SameLine(ctx)
  if ImGui.Button(ctx, 'Enable selected') then
    for pid, sel in pairs(selection_state.selected) do if sel then pkg.active[pid] = true end end
    if core.deps.settings then core.deps.settings:set('pkg_active', pkg.active) end
  end

  ImGui.SameLine(ctx)
  if ImGui.Button(ctx, 'Disable selected') then
    for pid, sel in pairs(selection_state.selected) do if sel then pkg.active[pid] = false end end
    if core.deps.settings then core.deps.settings:set('pkg_active', pkg.active) end
  end

  ImGui.PopStyleVar(ctx, 2)
  ImGui.Separator(ctx)

  local visible = pkg:visible()
  if #visible == 0 then
    ImGui.Text(ctx, 'No packages found.')
    if not pkg.demo then ImGui.BulletText(ctx, 'Enable "Demo/mock data" to preview the UX without images.') end
    draw_micro_manage_window(ctx, core)
    return
  end

  local avail_w = select(1, ImGui.GetContentRegionAvail(ctx)) or 0
  local padding  = GRID_PADDING
  local min_w    = math.max(120, tonumber(pkg.tile) or 220)
  local cols = math.max(1, math.floor((avail_w + padding) / (min_w + padding)))
  cols = math.min(cols, #visible)

  local inner_w = math.max(0, avail_w - padding * (cols + 1))
  local base_w_total = min_w * cols
  local extra = inner_w - base_w_total
  local base_w = min_w
  if cols == 1 then
    base_w = math.max(80, inner_w)
    extra  = 0
  end
  local per_col_add = (cols > 0) and math.floor(math.max(0, extra) / cols) or 0
  local remainder   = (cols > 0) and math.max(0, extra - per_col_add * cols) or 0
  local tile_h      = math.floor((base_w + per_col_add) * 0.65)
  local rows        = math.ceil(#visible / cols)
  local grid_height = rows * (tile_h + padding) + padding

  local origin_x, origin_y = ImGui.GetCursorScreenPos(ctx)
  tile_positions = {}
  do
    local x = origin_x + padding
    local y = origin_y + padding
    local c = 1
    for idx, P in ipairs(visible) do
      local col_w = base_w + per_col_add + ((c <= remainder) and 1 or 0)
      col_w = math.floor(col_w + 0.5)
      local x1, y1 = math.floor(x + 0.5), math.floor(y + 0.5)
      local x2, y2 = x1 + col_w, y1 + tile_h
      tile_positions[P.id] = {x1, y1, x2, y2, idx}

      x = x + col_w + padding
      c = c + 1
      if c > cols then
        c = 1
        x = origin_x + padding
        y = y + tile_h + padding
      end
    end
  end

  handle_selection_rect(ctx, core, grid_height, visible)

  local wx, wy = ImGui.GetWindowPos(ctx)
  local window_moved = false
  if last_window_pos then
    if wx ~= last_window_pos[1] or wy ~= last_window_pos[2] then
      window_moved = true
    end
  end
  last_window_pos = {wx, wy}

  if window_moved then
    for _, P in ipairs(visible) do
      local r = tile_positions[P.id]
      if r then tile_draw[P.id] = rect_copy(r) end
    end
  else
    for _, P in ipairs(visible) do
      local r = tile_positions[P.id]
      if r then
        local td = tile_draw[P.id]
        if not td then
          tile_draw[P.id] = rect_copy(r)
        else
          td[1] = lerp(td[1], r[1], LAYOUT_LERP_SPEED * 0.016)
          td[2] = lerp(td[2], r[2], LAYOUT_LERP_SPEED * 0.016)
          td[3] = lerp(td[3], r[3], LAYOUT_LERP_SPEED * 0.016)
          td[4] = lerp(td[4], r[4], LAYOUT_LERP_SPEED * 0.016)
          if math.abs(td[1]-r[1]) < LAYOUT_SNAP_EPS then td[1]=r[1] end
          if math.abs(td[2]-r[2]) < LAYOUT_SNAP_EPS then td[2]=r[2] end
          if math.abs(td[3]-r[3]) < LAYOUT_SNAP_EPS then td[3]=r[3] end
          if math.abs(td[4]-r[4]) < LAYOUT_SNAP_EPS then td[4]=r[4] end
        end
      end
    end
  end

  local mx2, my2 = ImGui.GetMousePos(ctx)
  for _, P in ipairs(visible) do
    local r = tile_draw[P.id] or tile_positions[P.id]
    if not r then goto continue end
    local minx, miny, maxx, maxy = r[1], r[2], r[3], r[4]

    hover_state[P.id] = is_point_in_rect(mx2, my2, minx, miny, maxx, maxy)

    local cbx1, cby1, cbx2, cby2 = compute_checkbox_rect(ctx, pkg, P.id, minx, miny, maxx, maxy)
    local over_checkbox = is_point_in_rect(mx2, my2, cbx1, cby1, cbx2, cby2)

    if not selection_state.is_dragging and not drag.active and not over_checkbox then
      if hover_state[P.id] and ImGui.IsMouseClicked(ctx, flags.MB_LEFT) then
        local shift_held = ImGui.IsKeyDown(ctx, ImGui.Key_LeftShift) or ImGui.IsKeyDown(ctx, ImGui.Key_RightShift)
        local ctrl_held  = ImGui.IsKeyDown(ctx, ImGui.Key_LeftCtrl)  or ImGui.IsKeyDown(ctx, ImGui.Key_RightCtrl)
        local already_selected = selection_state.selected[P.id] == true

        if ctrl_held then
          selection_state.selected[P.id] = not already_selected
        elseif shift_held and selection_state.last_click_pkg then
          local start_id, end_id = selection_state.last_click_pkg, P.id
          local selecting = false
          for _, VP in ipairs(visible) do
            if VP.id == start_id or VP.id == end_id then
              selection_state.selected[VP.id] = true
              if not selecting then selecting = true else break end
            elseif selecting then
              selection_state.selected[VP.id] = true
            end
          end
        else
          if not already_selected then
            selection_state.selected = {}
            selection_state.selected[P.id] = true
          end
        end

        selection_state.last_click_pkg = P.id
        selection_state.last_click_time = reaper.time_precise()

        drag.pressed_id      = P.id
        drag.pressed_was_sel = already_selected
        drag.press_pos       = {mx2, my2}
        drag.active          = false
        drag.ids             = nil
        drag.src_bbox        = nil
        drag.target_id       = nil
        drag.target_side     = 'before'
      end
    end

    if not over_checkbox and hover_state[P.id] and ImGui.IsMouseClicked(ctx, flags.MB_RIGHT) then
      local selected_count = count_selected()
      if selected_count > 1 and selection_state.selected[P.id] then
        local new_status = not pkg.active[P.id]
        for pid, sel in pairs(selection_state.selected) do if sel then pkg.active[pid] = new_status end end
        if core.deps.settings then core.deps.settings:set('pkg_active', pkg.active) end
      else
        pkg:toggle(P.id)
      end
    end

    if not over_checkbox and hover_state[P.id] and ImGui.IsMouseDoubleClicked(ctx, flags.MB_LEFT) then
      mm_window.open = true
      mm_window.pkgId = P.id
      mm_search = ""; mm_multi = {}
      core.log("double-click: open micro-manage window for %s", P.id)
    end

    if selection_state.is_dragging and selection_state.rect_start and selection_state.rect_current then
      local rx1, ry1 = selection_state.rect_start[1], selection_state.rect_start[2]
      local rx2, ry2 = selection_state.rect_current[1], selection_state.rect_current[2]
      local ctrl_held = ImGui.IsKeyDown(ctx, ImGui.Key_LeftCtrl) or ImGui.IsKeyDown(ctx, ImGui.Key_RightCtrl)
      if rects_intersect(rx1, ry1, rx2, ry2, minx, miny, maxx, maxy) then
        selection_state.selected[P.id] = true
      elseif not ctrl_held then
        selection_state.selected[P.id] = false
      end
    end

    draw_package_tile(ctx, core, P, r[5] or 0, minx, miny, maxx, maxy)

    ::continue::
  end

  local mx3, my3 = ImGui.GetMousePos(ctx)
  if drag.pressed_id and not drag.active and not selection_state.is_dragging then
    if ImGui.IsMouseDragging(ctx, flags.MB_LEFT, DRAG_THRESHOLD) then
      drag.active = true
      if count_selected() > 0 and selection_state.selected[drag.pressed_id] then
        drag.ids = ordered_selection_in_pkg_order(pkg)
      else
        drag.ids = { drag.pressed_id }
        selection_state.selected = {}
        selection_state.selected[drag.pressed_id] = true
      end
      drag.src_bbox = compute_group_bbox(drag.ids)
    end
  end

  if drag.active then
    drag.curr_mouse = {mx3, my3}
    local dragged_set = set_from(drag.ids)
    drag.target_id = nil
    drag.target_side = 'before'

    for _, P in ipairs(visible) do
      if not dragged_set[P.id] then
        local r = tile_draw[P.id] or tile_positions[P.id]
        if r and is_point_in_rect(mx3, my3, r[1], r[2], r[3], r[4]) then
          drag.target_id = P.id
          local midx = (r[1]+r[3])*0.5
          drag.target_side = (mx3 < midx) and 'before' or 'after'
          break
        end
      end
    end

    local dl2 = ImGui.GetWindowDrawList(ctx)
    for _, id in ipairs(drag.ids) do
      local r = tile_draw[id] or tile_positions[id]
      if r then
        ImGui.DrawList_AddRectFilled(dl2, r[1], r[2], r[3], r[4], DIM_ORIGINAL_FILL, TILE_ROUNDING)
        ImGui.DrawList_AddRect(dl2, r[1]+0.5, r[2]+0.5, r[3]-0.5, r[4]-0.5, DIM_ORIGINAL_STROKE, TILE_ROUNDING, 0, 2)
      end
    end

    if drag.src_bbox then
      local x1,y1,x2,y2 = drag.src_bbox[1], drag.src_bbox[2], drag.src_bbox[3], drag.src_bbox[4]
      local dx, dy = mx3 - drag.press_pos[1], my3 - drag.press_pos[2]
      x1, y1, x2, y2 = x1+dx, y1+dy, x2+dx, y2+dy
      ImGui.DrawList_AddRectFilled(dl2, x1, y1, x2, y2, GHOST_FILL, TILE_ROUNDING+2)
      ImGui.DrawList_AddRect(dl2, x1+0.5, y1+0.5, x2-0.5, y2-0.5, GHOST_STROKE, TILE_ROUNDING+2, 0, GHOST_STROKE_THICK)
      local label = tostring(#drag.ids)
      local tw, th = ImGui.CalcTextSize(ctx, label)
      local bx1, by1 = x2 - (tw+14), y1 - (th+14)
      local bx2, by2 = bx1 + tw + 8, by1 + th + 8
      ImGui.DrawList_AddRectFilled(dl2, bx1, by1, bx2, by2, 0x000000AA, 6)
      draw_centered_text(ctx, label, bx1, by1, bx2, by2, 0xFFFFFFFF)
    end

    if drag.target_id then
      local r = tile_draw[drag.target_id] or tile_positions[drag.target_id]
      if r then
        local x = (drag.target_side == 'before') and r[1] or r[3]
        ImGui.DrawList_AddLine(dl2, x, r[2]-6, x, r[4]+6, DROP_LINE_COLOR, DROP_LINE_THICKNESS)
        ImGui.DrawList_AddRectFilled(dl2, x-2, r[2]-6, x+2, r[2]-2, DROP_LINE_COLOR, DROP_LINE_RADIUS)
        ImGui.DrawList_AddRectFilled(dl2, x-2, r[4]+2, x+2, r[4]+6, DROP_LINE_COLOR, DROP_LINE_RADIUS)
      end
    end

    if ImGui.IsMouseReleased(ctx, flags.MB_LEFT) then
      if drag.target_id then
        perform_group_insert_relative(pkg, drag.ids, drag.target_id, drag.target_side)
        if core.deps.settings then core.deps.settings:set('pkg_order', pkg.order) end
      end
      drag.pressed_id = nil
      drag.pressed_was_sel = false
      drag.press_pos  = nil
      drag.active     = false
      drag.ids        = nil
      drag.src_bbox   = nil
      drag.target_id  = nil
      drag.target_side= 'before'
      drag.curr_mouse = nil
    end
  else
    if ImGui.IsMouseReleased(ctx, flags.MB_LEFT) then
      drag.pressed_id = nil
      drag.pressed_was_sel = false
      drag.press_pos  = nil
    end
  end

  draw_selection_rect(ctx)
  draw_micro_manage_window(ctx, core)
end

----------------------------------------------------------------
-- LEAVE TAB CLEANUP
----------------------------------------------------------------
function M.on_leave(core)
  mm_window.open = false
  mm_window.pkgId = nil
  selection_state = {
    selected = {},
    rect_start = nil,
    rect_current = nil,
    is_dragging = false,
    did_drag = false,
    last_click_time = 0,
    last_click_pkg = nil,
  }
  hover_state = {}
  animations = {}
  drag = { pressed_id=nil, pressed_was_sel=false, press_pos=nil, active=false, ids=nil, src_bbox=nil, target_id=nil, target_side='before', curr_mouse=nil }
  tile_positions = {}
  tile_draw = {}
  last_window_pos = nil
end

return M
