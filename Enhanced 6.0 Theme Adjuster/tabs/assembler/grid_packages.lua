-- tabs/assembler/package_tiles.lua
-- Wires the generic grid to your Packages domain: toolbar + tile overlays + persistence.

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local Grid = require('tabs.assembler.grid')
local MM   = require('tabs.assembler.packages_mm') -- exported window

local M = {}
local mm = { open=false, pkgId=nil, search="", multi={} }

-- Checkbox geometry used by both hotzones and drawing
local function compute_checkbox_rect(ctx, core, P, x1,y1,x2,y2)
  local pkg = core.pkg
  local function get_order_index(id)
    for i,pid in ipairs(pkg.order) do if pid==id then return i end end
    return 0
  end
  local ord = get_order_index(P.id)
  local badge = '#'..tostring(ord)
  local _, bh = ImGui.CalcTextSize(ctx, badge)
  local cb_size = math.max(12, math.floor(bh + 2))
  local MARGIN = 8
  local rx2 = x2 - MARGIN
  local ry1 = y1 + MARGIN
  local rx1 = rx2 - cb_size
  local ry2 = ry1 + cb_size
  return rx1,ry1,rx2,ry2, cb_size
end

-- Hotzones: tell the grid where NOT to start selection/drag (e.g., checkbox)
local function hotzones_fn_factory(core)
  return function(P, rect)
    local x1,y1,x2,y2 = rect[1],rect[2],rect[3],rect[4]
    local cbx1,cby1,cbx2,cby2 = compute_checkbox_rect(nil, core, P, x1,y1,x2,y2)
    return { {cbx1,cby1,cbx2,cby2} }
  end
end

-- Tile overlays (badge, conflicts, checkbox, mosaic, footer)
local function content_renderer_factory(core)
  return function(ctx, P, rect, env)
    local x1,y1,x2,y2 = rect[1],rect[2],rect[3],rect[4]
    local dl = ImGui.GetWindowDrawList(ctx)
    local pkg = core.pkg
    local C = env.style

    -- Order badge
    local function get_order_index(id)
      for i,pid in ipairs(pkg.order) do if pid==id then return i end end
      return 0
    end
    local ord = get_order_index(P.id)
    local badge = '#'..tostring(ord)
    local bw,bh = ImGui.CalcTextSize(ctx, badge)
    local bx1,by1 = x1 + 8, y1 + 8
    local bx2,by2 = bx1 + bw + 10, by1 + bh + 6
    local badge_col = env.is_active and 0x00000099 or 0x00000066
    ImGui.DrawList_AddRectFilled(dl, bx1,by1,bx2,by2, badge_col, 4)
    local tx = bx1 + math.floor((bw+10 - bw)*0.5)
    local ty = by1 + math.floor((bh+6  - bh)*0.5)
    ImGui.DrawList_AddText(dl, tx, ty, 0xAAAAAAFF, badge)
    ImGui.SetCursorScreenPos(ctx, bx1, by1)
    ImGui.InvisibleButton(ctx, '##ordtip-'..P.id, bx2-bx1, by2-by1)
    if ImGui.IsItemHovered(ctx) then ImGui.SetTooltip(ctx, "Overwrite priority") end

    -- Conflicts text
    local conflicts = pkg:conflicts(true)
    local conf = conflicts[P.id] or 0
    if conf > 0 then
      local ctext = string.format('%d conflicts', conf)
      local cw,ch = ImGui.CalcTextSize(ctx, ctext)
      local cx_mid = (x1 + x2) * 0.5
      local tx2 = math.floor(cx_mid - cw * 0.5)
      local ty2 = y1 + 8
      ImGui.DrawList_AddText(dl, tx2, ty2, 0xFFA500FF, ctext)
      ImGui.SetCursorScreenPos(ctx, tx2, ty2)
      ImGui.InvisibleButton(ctx, '##conftip-'..P.id, cw, ch)
      if ImGui.IsItemHovered(ctx) then
        ImGui.SetTooltip(ctx, "Conflicting Assets in Packages\n(autosolved through Overwrite Priority)")
      end
    end

    -- Checkbox (top-right)
    do
      local cbx1,cby1,cbx2,cby2 = compute_checkbox_rect(ctx, core, P, x1,y1,x2,y2)
      ImGui.SetCursorScreenPos(ctx, cbx1, cby1)
      ImGui.PushID(ctx, 'cb-'..P.id)
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 2, 1)
      local changed, nv = ImGui.Checkbox(ctx, '##enable', pkg.active[P.id]==true)
      ImGui.PopStyleVar(ctx)
      if ImGui.IsItemHovered(ctx) then ImGui.SetTooltip(ctx, (pkg.active[P.id] and "Disable package") or "Enable package") end
      ImGui.PopID(ctx)
      if changed then
        pkg.active[P.id] = nv
        if core.deps.settings then core.deps.settings:set('pkg_active', pkg.active) end
      end
    end

    -- Mosaic (center)
    local tile_w = x2 - x1
    local mosaic_padding = 15
    local cell = math.min(math.floor((tile_w - mosaic_padding*2 - 12) / 3), 50)
    local total_w = cell*3 + 12
    local mx0 = x1 + math.floor((tile_w - total_w) / 2)
    local my0 = y1 + 45
    local source = P.meta.mosaic or { P.keys_order[1], P.keys_order[2], P.keys_order[3] }
    for i=1, math.min(3, #source) do
      local fname = source[i] or "asset"
      local key = fname and fname:gsub("%.%w+$","") or "asset"
      local label = key:sub(1,3):upper()
      local col = env.color_from_key and env.color_from_key(key) or 0x555555FF
      local xx = mx0 + (i-1) * (cell + 6)
      local yy = my0
      ImGui.DrawList_AddRectFilled(dl, xx,yy, xx+cell,yy+cell, col, 3)
      if env.add_rect then env.add_rect(dl, xx,yy, xx+cell,yy+cell, 0x00000088, 3, 1)
      else ImGui.DrawList_AddRect(dl, xx,yy, xx+cell,yy+cell, 0x00000088, 3, 0, 1) end
      local tw,th = ImGui.CalcTextSize(ctx, label)
      local cx = xx + math.floor((cell - tw)*0.5)
      local cy = yy + math.floor((cell - th)*0.5)
      ImGui.DrawList_AddText(dl, cx, cy, 0xFFFFFFFF, label)
    end

    -- Footer (name + count)
    local fy = y2 - 32
    ImGui.DrawList_AddRectFilled(dl, x1,fy, x2,y2, 0x00000044, 0, 12)
    local name = P.meta.name or P.id
    local name_col = env.is_active and 0xFFFFFFFF or 0x999999FF
    ImGui.SetCursorScreenPos(ctx, x1 + 10, fy + 7)
    ImGui.PushStyleColor(ctx, ImGui.Col_Text, name_col)
    ImGui.Text(ctx, name)
    ImGui.PopStyleColor(ctx)
    local count=0; for _ in pairs(P.assets) do count=count+1 end
    local count_lbl = string.format('%d assets', count)
    local lw = select(1, ImGui.CalcTextSize(ctx, count_lbl)) or 0
    ImGui.SetCursorScreenPos(ctx, x2 - 10 - lw, fy + 7)
    ImGui.TextColored(ctx, 0x888888FF, count_lbl)
  end
end

-- Toolbar (unchanged behavior)
local function toolbar(ctx, core, grid)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameRounding, 4)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 6, 3)

  local pkg = core.pkg
  if pkg.demo == nil then pkg.demo = false end
  local ch_demo,nv_demo = ImGui.Checkbox(ctx, 'Demo/mock data', pkg.demo)
  if ch_demo then pkg.demo=nv_demo; if core.deps.settings then core.deps.settings:set('pkg_demo', pkg.demo) end; pkg:scan() end

  ImGui.SameLine(ctx)
  ImGui.SetNextItemWidth(ctx, 200)
  local ch_s, new_q = ImGui.InputText(ctx, 'Search', pkg.search or '')
  if ch_s then pkg.search = new_q; if core.deps.settings then core.deps.settings:set('pkg_search', pkg.search) end end

  ImGui.SameLine(ctx)
  ImGui.SetNextItemWidth(ctx, 140)
  local base_min, base_max = 160, 420
  if pkg.tile == nil then pkg.tile = 220 end
  local ch_t, new_tile = ImGui.SliderInt(ctx, '##TileSizeMin', pkg.tile, base_min, base_max)
  if ch_t then pkg.tile = new_tile; if core.deps.settings then core.deps.settings:set('pkg_tilesize', pkg.tile) end end
  ImGui.SameLine(ctx); ImGui.Text(ctx, 'Size')

  ImGui.SameLine(ctx)
  local c1,v1 = ImGui.Checkbox(ctx,'TCP',pkg.filters.TCP); if c1 then pkg.filters.TCP=v1 end
  ImGui.SameLine(ctx)
  local c2,v2 = ImGui.Checkbox(ctx,'MCP',pkg.filters.MCP); if c2 then pkg.filters.MCP=v2 end
  ImGui.SameLine(ctx)
  local c3,v3 = ImGui.Checkbox(ctx,'Transport',pkg.filters.Transport); if c3 then pkg.filters.Transport=v3 end
  ImGui.SameLine(ctx)
  local c4,v4 = ImGui.Checkbox(ctx,'Global',pkg.filters.Global); if c4 then pkg.filters.Global=v4 end
  if c1 or c2 or c3 or c4 then if core.deps.settings then core.deps.settings:set('pkg_filters', pkg.filters) end end

  ImGui.SameLine(ctx)
  if ImGui.Button(ctx, 'Rescan##pkgs') then pkg:scan() end

  ImGui.SameLine(ctx)
  if ImGui.Button(ctx, 'Enable selected') then
    for _,id in ipairs(grid:get_selected_ids()) do pkg.active[id] = true end
    if core.deps.settings then core.deps.settings:set('pkg_active', pkg.active) end
  end
  ImGui.SameLine(ctx)
  if ImGui.Button(ctx, 'Disable selected') then
    for _,id in ipairs(grid:get_selected_ids()) do pkg.active[id] = false end
    if core.deps.settings then core.deps.settings:set('pkg_active', pkg.active) end
  end

  ImGui.PopStyleVar(ctx, 2)
  ImGui.Separator(ctx)
end

-- Public
function M.draw(ctx, core)
  if not M._grid then
    M._grid = Grid.new({
      id_fn        = function(P) return P.id end,
      is_active_fn = function(P) return core.pkg.active[P.id]==true end,
      on_double_click = function(id) mm.open=true; mm.pkgId=id; mm.search=""; mm.multi={} end,
      on_right_click  = function(id, selected_ids)
        local pkg = core.pkg
        if #selected_ids>1 then
          local pivot = pkg.active[id]~=true
          for _,pid in ipairs(selected_ids) do pkg.active[pid]=pivot end
        else
          pkg:toggle(id)
        end
        if core.deps.settings then core.deps.settings:set('pkg_active', pkg.active) end
      end,
      on_reorder = function(drag_ids, target_id, side)
        local pkg = core.pkg
        local dragging = {}
        for _,id in ipairs(drag_ids) do dragging[id]=true end
        local base={}
        for _, id in ipairs(pkg.order) do if not dragging[id] then base[#base+1]=id end end
        local insert_idx=#base+1
        for i,id in ipairs(base) do if id==target_id then insert_idx=(side=='after') and (i+1) or i; break end end
        local new_order={}
        for i=1, insert_idx-1 do new_order[#new_order+1]=base[i] end
        for _,id in ipairs(drag_ids) do new_order[#new_order+1]=id end
        for i=insert_idx, #base do new_order[#new_order+1]=base[i] end
        pkg.order = new_order
        if core.deps.settings then core.deps.settings:set('pkg_order', pkg.order) end
      end,
      hotzones_fn      = hotzones_fn_factory(core),
      content_renderer = content_renderer_factory(core),
      -- style = { ... } -- override here if needed
    })
  end

  toolbar(ctx, core, M._grid)

  local visible = core.pkg:visible()
  if #visible == 0 then
    ImGui.Text(ctx, 'No packages found.')
    if not core.pkg.demo then ImGui.BulletText(ctx, 'Enable "Demo/mock data" to preview the UX without images.') end
    if mm.open then MM.draw_window(ctx, core, mm) end
    return
  end

  M._grid:draw(ctx, {
    items          = visible,
    tile_min_w     = core.pkg.tile or 220,
    add_rect       = core.add_rect,
    color_from_key = core.color_from_key,
  })

  if mm.open then MM.draw_window(ctx, core, mm) end
end

function M.on_leave(core)
  if M._grid then M._grid:on_leave() end
  mm.open, mm.pkgId, mm.search, mm.multi = false, nil, "", {}
end

return M
