-- tabs/assembler/grid.lua
-- Generic tile grid: layout, hover, selection (click/ctrl/shift/rectangle),
-- drag-reorder visuals + callback, marching-ants selection, rounded tiles,
-- hover shadow, animated layout.
--
-- Usage:
--   local Grid = require('tabs.assembler.grid')
--   local grid = Grid.new({
--     id_fn            = function(item) return item.id end,
--     is_active_fn     = function(item) return false end,   -- (for ants color choice/active tint)
--     on_double_click  = function(id) end,
--     on_right_click   = function(id, selected_ids) end,
--     on_reorder       = function(drag_ids, target_id, side) end,
--     hotzones_fn      = function(item, rect, env) return { {x1,y1,x2,y2}, ... } end, -- clickable zones to ignore for selection/drag start
--     content_renderer = function(ctx, item, rect, env) end, -- draw overlays inside tile
--     style            = { ... } -- optional overrides
--   })
--   grid:draw(ctx, {
--     items          = items,
--     tile_min_w     = 220,
--     add_rect       = add_rect_fn_or_nil,   -- optional crisp border helper
--     color_from_key = color_from_key_fn,    -- optional, passed to content renderer
--   })
--   grid:on_leave()

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local Grid = {}
Grid.__index = Grid

-- ---------- Style (defaults), can be overridden in opts.style ----------
local function default_style()
  return {
    ANT_SPEED              = 20,
    ANT_COLOR_ENABLED      = 0x42E896FF,
    ANT_COLOR_DISABLED     = 0xFFFFFF40,
    DRAG_THRESHOLD         = 6,
    DROP_LINE_COLOR        = 0x42E896E0,
    DROP_LINE_THICKNESS    = 4,
    DROP_LINE_RADIUS       = 8,
    GHOST_FILL             = 0xFFFFFF22,
    GHOST_STROKE           = 0xFFFFFFFF,
    GHOST_STROKE_THICK     = 2,
    DIM_ORIGINAL_FILL      = 0x00000088,
    DIM_ORIGINAL_STROKE    = 0xFFFFFF55,
    TILE_ROUNDING          = 6,
    BORDER_HOVER_THICKNESS = 1,
    BORDER_ANT_THICKNESS   = 1,
    LAYOUT_LERP_SPEED      = 14.0,
    LAYOUT_SNAP_EPS        = 0.5,
    GRID_PADDING           = 12,

    -- Base colors
    BG_INACTIVE            = 0x1A1A1AFF,
    BG_ACTIVEBASE          = 0x2D4A37FF,
    BG_HOVER_TINT          = 0x2A2A2AFF,
    BRD_INACTIVE           = 0x303030FF,
    BRD_ACTIVE             = 0x42E896FF,
    BRD_HOVER              = 0xCCCCCCFF,
  }
end

-- ---------- Small helpers ----------
local function lerp(a,b,t) return a + (b-a) * math.min(1.0, t) end
local function color_lerp(c1,c2,t)
  local function rgba(c) return (c>>24)&0xFF, (c>>16)&0xFF, (c>>8)&0xFF, c&0xFF end
  local r1,g1,b1,a1 = rgba(c1); local r2,g2,b2,a2 = rgba(c2)
  local r = math.floor(lerp(r1,r2,t))
  local g = math.floor(lerp(g1,g2,t))
  local b = math.floor(lerp(b1,b2,t))
  local a = math.floor(lerp(a1,a2,t))
  return (r<<24)|(g<<16)|(b<<8)|a
end
local function is_point_in_rect(x,y,x1,y1,x2,y2)
  return x>=math.min(x1,x2) and x<=math.max(x1,x2)
     and y>=math.min(y1,y2) and y<=math.max(y1,y2)
end
local function rects_intersect(ax1,ay1,ax2,ay2, bx1,by1,bx2,by2)
  local aL,aR = math.min(ax1,ax2), math.max(ax1,ax2)
  local aT,aB = math.min(ay1,ay2), math.max(ay1,ay2)
  local bL,bR = math.min(bx1,bx2), math.max(bx1,bx2)
  local bT,bB = math.min(by1,by2), math.max(by1,by2)
  return not (aL>bR or aR<bL or aT>bB or aB<bT)
end
local function rect_copy(r) return {r[1],r[2],r[3],r[4],r[5]} end

-- ---------- Marching ants rounded rectangle (part of grid) ----------
local function draw_marching_ants_rounded(dl, x1,y1,x2,y2, col, thick, radius, style)
  local C = style
  if x2<=x1 or y2<=y1 then return end
  local w,h = x2-x1, y2-y1
  local r = math.max(0, math.min(radius or C.TILE_ROUNDING, math.floor(math.min(w,h)*0.5)))
  local straight_w, straight_h = math.max(0,w-2*r), math.max(0,h-2*r)
  local arc_len = (math.pi*r)/2
  local L = straight_w+arc_len+straight_h+arc_len+straight_w+arc_len+straight_h+arc_len
  if L<=0 then return end

  local function line(ax,ay,bx,by,u0,u1)
    local seg = math.max(1e-6, ((bx-ax)^2+(by-ay)^2)^0.5)
    local t0,t1 = u0/seg, u1/seg
    local sx,sy = ax+(bx-ax)*t0, ay+(by-ay)*t0
    local ex,ey = ax+(bx-ax)*t1, ay+(by-ay)*t1
    ImGui.DrawList_AddLine(dl, sx,sy,ex,ey, col, thick)
  end
  local function arc(cx,cy,rr,a0,a1,u0,u1)
    local seg = math.max(1e-6, rr*math.abs(a1-a0))
    local aa0 = a0 + (a1-a0)*(u0/seg)
    local aa1 = a0 + (a1-a0)*(u1/seg)
    local steps = math.max(1, math.floor((rr*math.abs(aa1-aa0))/3))
    local px,py = cx+rr*math.cos(aa0), cy+rr*math.sin(aa0)
    for i=1,steps do
      local t = i/steps
      local ang = aa0 + (aa1-aa0)*t
      local nx,ny = cx+rr*math.cos(ang), cy+rr*math.sin(ang)
      ImGui.DrawList_AddLine(dl, px,py,nx,ny, col, thick)
      px,py = nx,ny
    end
  end

  local dash_len = 8
  local gap_len  = 6
  local period   = dash_len + gap_len
  local speed    = math.max(1, C.ANT_SPEED)
  local phase_px = (reaper.time_precise() * speed) % period

  local function subpath(s,e)
    local pos=0
    if e>pos and s<pos+straight_w and straight_w>0 then
      line(x1+r,y1, x2-r,y1, math.max(0,s-pos), math.min(straight_w,e-pos)) end
    pos=pos+straight_w
    if e>pos and s<pos+arc_len and arc_len>0 then
      arc(x2-r,y1+r, r, -math.pi/2, 0, math.max(0,s-pos), math.min(arc_len,e-pos)) end
    pos=pos+arc_len
    if e>pos and s<pos+straight_h and straight_h>0 then
      line(x2,y1+r, x2,y2-r, math.max(0,s-pos), math.min(straight_h,e-pos)) end
    pos=pos+straight_h
    if e>pos and s<pos+arc_len and arc_len>0 then
      arc(x2-r,y2-r, r, 0, math.pi/2, math.max(0,s-pos), math.min(arc_len,e-pos)) end
    pos=pos+arc_len
    if e>pos and s<pos+straight_w and straight_w>0 then
      line(x2-r,y2, x1+r,y2, math.max(0,s-pos), math.min(straight_w,e-pos)) end
    pos=pos+straight_w
    if e>pos and s<pos+arc_len and arc_len>0 then
      arc(x1+r,y2-r, r, math.pi/2, math.pi, math.max(0,s-pos), math.min(arc_len,e-pos)) end
    pos=pos+arc_len
    if e>pos and s<pos+straight_h and straight_h>0 then
      line(x1,y2-r, x1,y1+r, math.max(0,s-pos), math.min(straight_h,e-pos)) end
    pos=pos+straight_h
    if e>pos and s<pos+arc_len and arc_len>0 then
      arc(x1+r,y1+r, r, math.pi, 3*math.pi/2, math.max(0,s-pos), math.min(arc_len,e-pos)) end
  end

  local s = -phase_px
  while s < L do
    local e = s + dash_len
    local cs,ce = math.max(0,s), math.min(L,e)
    if ce>cs then subpath(cs,ce) end
    s = s + period
  end
end

-- ---------- ctor ----------
function Grid.new(opts)
  local self = setmetatable({}, Grid)
  self.id_fn            = (opts and opts.id_fn)            or function(x) return x.id end
  self.is_active_fn     = (opts and opts.is_active_fn)     or function(_) return false end
  self.on_double_click  = (opts and opts.on_double_click)  or nil
  self.on_right_click   = (opts and opts.on_right_click)   or nil
  self.on_reorder       = (opts and opts.on_reorder)       or nil
  self.hotzones_fn      = (opts and opts.hotzones_fn)      or function() return nil end
  self.content_renderer = (opts and opts.content_renderer) or nil
  self.C = default_style()
  if opts and opts.style then for k,v in pairs(opts.style) do self.C[k]=v end end

  self.anim = {}
  self.hover = {}
  self.sel = { selected={}, rect_start=nil, rect_cur=nil, is_drag=false, did_drag=false, last_click_time=0, last_click_id=nil }
  self.drag = { pressed_id=nil, pressed_was_sel=false, press_pos=nil, active=false, ids=nil, src_bbox=nil, target_id=nil, target_side='before', curr_mouse=nil }
  self.tile_pos  = {}
  self.tile_draw = {}
  self.last_win_pos = nil
  return self
end

-- ---------- selection helpers ----------
local function count_selected(sel_tbl) local n=0 for _,v in pairs(sel_tbl) do if v then n=n+1 end end return n end
local function ordered_selection_in_order(items, id_fn, sel_tbl)
  local out={}
  for _, it in ipairs(items) do local id=id_fn(it); if sel_tbl[id] then out[#out+1]=id end end
  return out
end
local function set_from(list) local t={} for _,id in ipairs(list or {}) do t[id]=true end return t end
local function group_bbox(ids, tile_draw, tile_pos)
  local x1,y1,x2,y2 = math.huge, math.huge, -math.huge, -math.huge
  for _,id in ipairs(ids) do
    local r = tile_draw[id] or tile_pos[id]
    if r then
      x1=math.min(x1,r[1]); y1=math.min(y1,r[2])
      x2=math.max(x2,r[3]); y2=math.max(y2,r[4])
    end
  end
  if x1==math.huge then return nil end
  return {x1,y1,x2,y2}
end

-- ---------- layout ----------
local function compute_layout(self, ctx, items, tile_min_w)
  local C = self.C
  local avail_w = select(1, ImGui.GetContentRegionAvail(ctx)) or 0
  local pad = C.GRID_PADDING
  local min_w = math.max(120, tonumber(tile_min_w) or 220)
  local cols = math.max(1, math.floor((avail_w + pad) / (min_w + pad)))
  cols = math.min(cols, #items)
  local inner_w = math.max(0, avail_w - pad * (cols + 1))
  local base_w_total = min_w * cols
  local extra = inner_w - base_w_total
  local per_col = (cols>0) and math.floor(math.max(0, extra)/cols) or 0
  local rem     = (cols>0) and math.max(0, extra - per_col*cols) or 0
  local tile_h  = math.floor((min_w + per_col) * 0.65)
  local rows    = math.ceil(#items / math.max(cols,1))
  local grid_h  = rows * (tile_h + pad) + pad

  local ox, oy = ImGui.GetCursorScreenPos(ctx)
  self.tile_pos = {}
  local x = ox + pad
  local y = oy + pad
  local c = 1
  for idx, it in ipairs(items) do
    local col_w = min_w + per_col + ((c<=rem) and 1 or 0)
    col_w = math.floor(col_w + 0.5)
    local x1, y1 = math.floor(x+0.5), math.floor(y+0.5)
    local x2, y2 = x1 + col_w, y1 + tile_h
    local id = self.id_fn(it)
    self.tile_pos[id] = {x1,y1,x2,y2, idx}

    x = x + col_w + pad
    c = c + 1
    if c > cols then
      c = 1
      x = ox + pad
      y = y + tile_h + pad
    end
  end
  return { grid_height = grid_h }
end

-- ---------- background catcher + selection rectangle ----------
local function draw_selection_rect(self, ctx)
  if self.sel.is_drag and self.sel.rect_start and self.sel.rect_cur then
    local C = self.C
    local dl = ImGui.GetWindowDrawList(ctx)
    local x1,y1 = self.sel.rect_start[1], self.sel.rect_start[2]
    local x2,y2 = self.sel.rect_cur[1],   self.sel.rect_cur[2]
    ImGui.DrawList_AddRectFilled(dl, math.min(x1,x2), math.min(y1,y2),
                                             math.max(x1,x2), math.max(y1,y2), 0xFFFFFF22, C.TILE_ROUNDING)
    ImGui.DrawList_AddRect(dl,       math.min(x1,x2), math.min(y1,y2),
                                             math.max(x1,x2), math.max(y1,y2), 0xFFFFFFFF, C.TILE_ROUNDING, 0, 1)
  end
end

local function background_catcher(self, ctx, grid_h, hotzones)
  local content_min_x, content_min_y = ImGui.GetCursorScreenPos(ctx)
  local avail_w = select(1, ImGui.GetContentRegionAvail(ctx)) or 0

  local mx,my = ImGui.GetMousePos(ctx)
  local over_excl = false
  if hotzones and #hotzones>0 then
    for _,r in ipairs(hotzones) do
      if is_point_in_rect(mx,my, r[1],r[2],r[3],r[4]) then over_excl=true; break end
    end
  end

  if over_excl then
    ImGui.Dummy(ctx, avail_w, grid_h)
  else
    ImGui.InvisibleButton(ctx, "##grid_bg", avail_w, grid_h)
  end
  -- allow the background element to overlap domain widgets (prevents click-eating)
  ImGui.SetItemAllowOverlap(ctx)

  if ImGui.IsItemClicked(ctx, ImGui.MouseButton_Left) then
    -- start rectangle selection unless we’re directly over a tile (handled later)
    local mx2,my2 = ImGui.GetMousePos(ctx)
    self.sel.rect_start = {mx2,my2}
    self.sel.rect_cur   = nil
    self.sel.is_drag    = true
    self.sel.did_drag   = false
  end

  if self.sel.is_drag and ImGui.IsMouseDragging(ctx, ImGui.MouseButton_Left, 5) then
    local mx2,my2 = ImGui.GetMousePos(ctx)
    self.sel.rect_cur = {mx2,my2}; self.sel.did_drag = true
  end

  if self.sel.is_drag and ImGui.IsMouseReleased(ctx, ImGui.MouseButton_Left) then
    if not self.sel.did_drag then self.sel.selected = {}; self.sel.last_click_id = nil end
    self.sel.is_drag = false
    self.sel.rect_start, self.sel.rect_cur, self.sel.did_drag = nil, nil, false
  end

  ImGui.SetCursorScreenPos(ctx, content_min_x, content_min_y)
end

-- ---------- public draw ----------
function Grid:draw(ctx, args)
  local items          = assert(args.items, "grid:draw() requires args.items")
  local tile_min_w     = args.tile_min_w or 220
  local add_rect       = args.add_rect      -- optional
  local color_from_key = args.color_from_key -- optional

  local C = self.C

  -- Compute layout
  local layout = compute_layout(self, ctx, items, tile_min_w)

  -- Precompute hotzones for all tiles (so bg catcher can avoid starting sel/drag)
  local hotzones = {}
  if self.hotzones_fn then
    for _, it in ipairs(items) do
      local id = self.id_fn(it)
      local r  = self.tile_draw[id] or self.tile_pos[id]
      if r then
        local hz = self.hotzones_fn(it, r, { color_from_key=color_from_key })
        if hz then for _,x in ipairs(hz) do hotzones[#hotzones+1] = x end end
      end
    end
  end

  -- Background catcher
  background_catcher(self, ctx, layout.grid_height, hotzones)

  -- Animate positions (snap when window moved)
  do
    local wx, wy = ImGui.GetWindowPos(ctx)
    local moved = false
    if self.last_win_pos then moved = (wx~=self.last_win_pos[1] or wy~=self.last_win_pos[2]) end
    self.last_win_pos = {wx,wy}
    if moved then
      for _, it in ipairs(items) do local id=self.id_fn(it); local r=self.tile_pos[id]; if r then self.tile_draw[id]=rect_copy(r) end end
    else
      for _, it in ipairs(items) do
        local id=self.id_fn(it); local r=self.tile_pos[id]
        if r then
          local td=self.tile_draw[id]
          if not td then self.tile_draw[id]=rect_copy(r)
          else
            td[1]=lerp(td[1],r[1], C.LAYOUT_LERP_SPEED*0.016)
            td[2]=lerp(td[2],r[2], C.LAYOUT_LERP_SPEED*0.016)
            td[3]=lerp(td[3],r[3], C.LAYOUT_LERP_SPEED*0.016)
            td[4]=lerp(td[4],r[4], C.LAYOUT_LERP_SPEED*0.016)
            if math.abs(td[1]-r[1])<C.LAYOUT_SNAP_EPS then td[1]=r[1] end
            if math.abs(td[2]-r[2])<C.LAYOUT_SNAP_EPS then td[2]=r[2] end
            if math.abs(td[3]-r[3])<C.LAYOUT_SNAP_EPS then td[3]=r[3] end
            if math.abs(td[4]-r[4])<C.LAYOUT_SNAP_EPS then td[4]=r[4] end
          end
        end
      end
    end
  end

  -- Per-tile input + base visuals + content
  local mx,my = ImGui.GetMousePos(ctx)
  for _, it in ipairs(items) do
    local id = self.id_fn(it)
    local r  = self.tile_draw[id] or self.tile_pos[id]
    if r then
      local x1,y1,x2,y2 = r[1],r[2],r[3],r[4]
      local w,h = x2-x1, y2-y1

      -- hover
      self.hover[id] = is_point_in_rect(mx,my, x1,y1,x2,y2)

      -- clicks (ignore if mouse is in any hotzone over this rect)
      local over_excl = false
      if self.hotzones_fn then
        local hz = self.hotzones_fn(it, r, { color_from_key=color_from_key })
        if hz then
          for _,rr in ipairs(hz) do if is_point_in_rect(mx,my, rr[1],rr[2],rr[3],rr[4]) then over_excl=true; break end end
        end
      end

      -- LMB selection / ctrl / shift
      if (not self.sel.is_drag) and (not self.drag.active) and (not over_excl) then
        if self.hover[id] and ImGui.IsMouseClicked(ctx, ImGui.MouseButton_Left) then
          local shift = ImGui.IsKeyDown(ctx, ImGui.Key_LeftShift) or ImGui.IsKeyDown(ctx, ImGui.Key_RightShift)
          local ctrl  = ImGui.IsKeyDown(ctx, ImGui.Key_LeftCtrl)  or ImGui.IsKeyDown(ctx, ImGui.Key_RightCtrl)
          local already = self.sel.selected[id] == true
          if ctrl then
            self.sel.selected[id] = not already
          elseif shift and self.sel.last_click_id then
            -- range select in item order
            local selecting=false
            for _,it2 in ipairs(items) do
              local id2 = self.id_fn(it2)
              if id2==self.sel.last_click_id or id2==id then
                self.sel.selected[id2] = true
                if not selecting then selecting=true else break end
              elseif selecting then self.sel.selected[id2]=true end
            end
          else
            if not already then self.sel.selected = {}; self.sel.selected[id] = true end
          end

          self.sel.last_click_id = id
          self.sel.last_click_time = reaper.time_precise()

          self.drag.pressed_id = id
          self.drag.pressed_was_sel = already
          self.drag.press_pos  = {mx,my}
          self.drag.active = false
          self.drag.ids, self.drag.src_bbox, self.drag.target_id = nil, nil, nil
          self.drag.target_side = 'before'
        end
      end

      -- RMB
      if (not over_excl) and self.hover[id] and ImGui.IsMouseClicked(ctx, ImGui.MouseButton_Right) then
        if self.on_right_click then
          local selected_ids = {}
          for sid,sel in pairs(self.sel.selected) do if sel then selected_ids[#selected_ids+1]=sid end end
          self.on_right_click(id, selected_ids)
        end
      end

      -- Double click
      if (not over_excl) and self.hover[id] and ImGui.IsMouseDoubleClicked(ctx, ImGui.MouseButton_Left) then
        if self.on_double_click then self.on_double_click(id) end
      end

      -- selection rectangle evaluation
      if self.sel.is_drag and self.sel.rect_start and self.sel.rect_cur then
        local rx1,ry1 = self.sel.rect_start[1], self.sel.rect_start[2]
        local rx2,ry2 = self.sel.rect_cur[1],   self.sel.rect_cur[2]
        local ctrl = ImGui.IsKeyDown(ctx, ImGui.Key_LeftCtrl) or ImGui.IsKeyDown(ctx, ImGui.Key_RightCtrl)
        if rects_intersect(rx1,ry1,rx2,ry2, x1,y1,x2,y2) then self.sel.selected[id]=true
        elseif not ctrl then self.sel.selected[id]=false end
      end

      -- BASE VISUALS (rounded square, hover, ants on selection)
      local dl = ImGui.GetWindowDrawList(ctx)
      local is_active  = self.is_active_fn(it) == true
      local is_sel     = self.sel.selected[id] == true
      local hv_key     = 'hv_'..id
      local ac_key     = 'ac_'..id
      self.anim[hv_key] = self.anim[hv_key] or 0
      self.anim[ac_key] = self.anim[ac_key] or 0
      local hover_t  = lerp(self.anim[hv_key], self.hover[id] and 1 or 0, 12.0*0.016);      self.anim[hv_key]=hover_t
      local active_t = lerp(self.anim[ac_key], is_active and 1 or 0, 8.0*0.016);            self.anim[ac_key]=active_t

      local bg_active  = color_lerp(self.C.BG_INACTIVE, self.C.BG_ACTIVEBASE, active_t)
      local bg_final   = color_lerp(bg_active, self.C.BG_HOVER_TINT, hover_t * 0.4)
      local brd_base   = color_lerp(self.C.BRD_INACTIVE, self.C.BRD_ACTIVE, active_t)
      local brd_final  = self.hover[id] and color_lerp(brd_base, self.C.BRD_HOVER, hover_t) or brd_base

      if hover_t > 0.01 and not is_sel then
        local alpha = math.floor(hover_t * 20)
        local shadow = (0x000000 << 8) | alpha
        for i=2,1,-1 do
          ImGui.DrawList_AddRectFilled(dl, x1 - i, y1 - i + 2, x2 + i, y2 + i + 2, shadow, self.C.TILE_ROUNDING)
        end
      end

      ImGui.DrawList_AddRectFilled(dl, x1,y1,x2,y2, bg_final, self.C.TILE_ROUNDING)

      if is_sel then
        local sel_col = is_active and self.C.ANT_COLOR_ENABLED or self.C.ANT_COLOR_DISABLED
        draw_marching_ants_rounded(dl, x1+0.5, y1+0.5, x2-0.5, y2-0.5, sel_col, self.C.BORDER_ANT_THICKNESS, self.C.TILE_ROUNDING, self.C)
      else
        if add_rect then add_rect(dl, x1,y1,x2,y2, brd_final, self.C.TILE_ROUNDING, self.C.BORDER_HOVER_THICKNESS)
        else ImGui.DrawList_AddRect(dl, x1,y1,x2,y2, brd_final, self.C.TILE_ROUNDING, 0, self.C.BORDER_HOVER_THICKNESS) end
      end

      -- CONTENT (domain overlay)
      if self.content_renderer then
        self.content_renderer(ctx, it, r, {
          add_rect = add_rect,
          color_from_key = color_from_key,
          is_active = is_active,
          is_hover  = self.hover[id] == true,
          is_selected = is_sel,
          style = self.C,
        })
      end
    end
  end

  -- DRAG logic & visuals
  do
    local mx3,my3 = ImGui.GetMousePos(ctx)
    if self.drag.pressed_id and not self.drag.active and not self.sel.is_drag then
      if ImGui.IsMouseDragging(ctx, ImGui.MouseButton_Left, self.C.DRAG_THRESHOLD) then
        self.drag.active = true
        if count_selected(self.sel.selected)>0 and self.sel.selected[self.drag.pressed_id] then
          self.drag.ids = ordered_selection_in_order(items, self.id_fn, self.sel.selected)
        else
          self.drag.ids = { self.drag.pressed_id }
          self.sel.selected = { [self.drag.pressed_id]=true }
        end
        self.drag.src_bbox = group_bbox(self.drag.ids, self.tile_draw, self.tile_pos)
      end
    end

    if self.drag.active then
      self.drag.curr_mouse = {mx3,my3}
      local dragged = set_from(self.drag.ids)
      self.drag.target_id, self.drag.target_side = nil, 'before'

      for _,it in ipairs(items) do
        local id = self.id_fn(it)
        if not dragged[id] then
          local r = self.tile_draw[id] or self.tile_pos[id]
          if r and is_point_in_rect(mx3,my3, r[1],r[2],r[3],r[4]) then
            self.drag.target_id = id
            local midx = (r[1]+r[3])*0.5
            self.drag.target_side = (mx3 < midx) and 'before' or 'after'
            break
          end
        end
      end

      local dl2 = ImGui.GetWindowDrawList(ctx)
      for _,id in ipairs(self.drag.ids) do
        local r = self.tile_draw[id] or self.tile_pos[id]
        if r then
          ImGui.DrawList_AddRectFilled(dl2, r[1],r[2],r[3],r[4], self.C.DIM_ORIGINAL_FILL, self.C.TILE_ROUNDING)
          ImGui.DrawList_AddRect(dl2, r[1]+0.5,r[2]+0.5,r[3]-0.5,r[4]-0.5, self.C.DIM_ORIGINAL_STROKE, self.C.TILE_ROUNDING, 0, 2)
        end
      end

      if self.drag.src_bbox then
        local x1,y1,x2,y2 = self.drag.src_bbox[1],self.drag.src_bbox[2],self.drag.src_bbox[3],self.drag.src_bbox[4]
        local dx,dy = mx3 - self.drag.press_pos[1], my3 - self.drag.press_pos[2]
        x1,y1,x2,y2 = x1+dx, y1+dy, x2+dx, y2+dy
        ImGui.DrawList_AddRectFilled(dl2, x1,y1,x2,y2, self.C.GHOST_FILL, self.C.TILE_ROUNDING+2)
        ImGui.DrawList_AddRect(dl2, x1+0.5,y1+0.5,x2-0.5,y2-0.5, self.C.GHOST_STROKE, self.C.TILE_ROUNDING+2, 0, self.C.GHOST_STROKE_THICK)
        local label = tostring(#self.drag.ids)
        local tw, th = ImGui.CalcTextSize(ctx, label)
        local bx1, by1 = x2 - (tw+14), y1 - (th+14)
        local bx2, by2 = bx1 + tw + 8, by1 + th + 8
        ImGui.DrawList_AddRectFilled(dl2, bx1,by1,bx2,by2, 0x000000AA, 6)
        local cx,cy = bx1 + math.floor((bx2-bx1-tw)*0.5), by1 + math.floor((by2-by1-th)*0.5)
        ImGui.DrawList_AddText(dl2, cx, cy, 0xFFFFFFFF, label)
      end

      if self.drag.target_id then
        local r = self.tile_draw[self.drag.target_id] or self.tile_pos[self.drag.target_id]
        if r then
          local x = (self.drag.target_side=='before') and r[1] or r[3]
          ImGui.DrawList_AddLine(dl2, x, r[2]-6, x, r[4]+6, self.C.DROP_LINE_COLOR, self.C.DROP_LINE_THICKNESS)
          ImGui.DrawList_AddRectFilled(dl2, x-2, r[2]-6, x+2, r[2]-2, self.C.DROP_LINE_COLOR, self.C.DROP_LINE_RADIUS)
          ImGui.DrawList_AddRectFilled(dl2, x-2, r[4]+2, x+2, r[4]+6, self.C.DROP_LINE_COLOR, self.C.DROP_LINE_RADIUS)
        end
      end

      if ImGui.IsMouseReleased(ctx, ImGui.MouseButton_Left) then
        if self.drag.target_id and self.on_reorder then
          self.on_reorder(self.drag.ids, self.drag.target_id, self.drag.target_side)
        end
        self.drag = { pressed_id=nil, pressed_was_sel=false, press_pos=nil, active=false, ids=nil, src_bbox=nil, target_id=nil, target_side='before', curr_mouse=nil }
      end
    else
      if ImGui.IsMouseReleased(ctx, ImGui.MouseButton_Left) then
        self.drag.pressed_id, self.drag.pressed_was_sel, self.drag.press_pos = nil, false, nil
      end
    end
  end

  draw_selection_rect(self, ctx)
end

function Grid:on_leave()
  self.anim, self.hover = {}, {}
  self.sel = { selected={}, rect_start=nil, rect_cur=nil, is_drag=false, did_drag=false, last_click_time=0, last_click_id=nil }
  self.drag = { pressed_id=nil, pressed_was_sel=false, press_pos=nil, active=false, ids=nil, src_bbox=nil, target_id=nil, target_side='before', curr_mouse=nil }
  self.tile_pos, self.tile_draw = {}, {}
  self.last_win_pos = nil
end

-- Convenience: let the host read/act on selection
function Grid:get_selected_ids()
  local out = {}
  for id,sel in pairs(self.sel.selected) do if sel then out[#out+1]=id end end
  return out
end
function Grid:clear_selection() self.sel.selected = {} end

return Grid
