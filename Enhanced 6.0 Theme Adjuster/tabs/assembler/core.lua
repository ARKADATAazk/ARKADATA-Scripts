-- tabs/assembler/core.lua
-- Enhanced core: shared state, scanning, helpers, selection management, and settings persistence.

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local M = {}

-- Console logger with timestamp
local function log(fmt, ...)
  local timestamp = os.date("%H:%M:%S")
  local msg = ("[Assembler %s] " .. fmt .. "\n"):format(timestamp, ...)
  reaper.ShowConsoleMsg(msg)
end

-- Enhanced try wrapper with better error reporting
local function try(name, fn)
  local ok, err = xpcall(fn, debug.traceback)
  if not ok then
    log("ERROR in %s:\n%s", name, err)
  end
  return ok
end

-- Path utils
local SEP = package.config:sub(1,1)
local function join(a,b) if a:sub(-1)==SEP then return a..b else return a..SEP..b end end
local function file_exists(p) local f=io.open(p,'rb'); if f then f:close(); return true end end
local function read_all(p) local f=io.open(p,'rb'); if not f then return nil end local s=f:read('*a'); f:close(); return s end

-- Flags resolver (safe across ReaImGui versions)
local function FLAG(name)
  local v = reaper[name]
  if type(v) == 'function' then
    local ok, ret = pcall(v)
    if ok and type(ret) == 'number' then return ret end
  elseif type(v) == 'number' then
    return v
  end
  return 0
end

local function bor(...)
  local r, n = 0, select('#', ...)
  for i=1,n do local v=select(i,...); if type(v)=='number' then r=r+v end end
  return r
end

-- Enhanced draw helpers with modern effects
local function add_rect(dl, x1,y1,x2,y2, col, rounding, thickness)
  ImGui.DrawList_AddRect(dl, x1,y1,x2,y2, col, rounding or 0, 0, thickness or 1)
end

local function add_shadow(dl, x1,y1,x2,y2, intensity, spread, rounding)
  intensity = intensity or 0.3
  spread = spread or 8
  rounding = rounding or 0
  
  for i = spread, 1, -1 do
    local alpha = math.floor((intensity * 255 * (i / spread)))
    local offset = (spread - i) * 1.5
    ImGui.DrawList_AddRectFilled(dl,
      x1 - offset, y1 - offset + spread/2,
      x2 + offset, y2 + offset + spread/2,
      (0x000000 << 8) | alpha, rounding)
  end
end

-- Enhanced color palette with vibrant modern colors
local _palette = {
  0x42E896FF, -- Vibrant teal/green
  0x5BCEFAFF, -- Bright cyan
  0xFFB84DFF, -- Warm orange
  0xFF6B7AFF, -- Coral red
  0xA78BFAFF, -- Soft purple
  0x4ADE80FF, -- Fresh green
  0xFBBF24FF, -- Golden yellow
  0xEC4899FF, -- Hot pink
  0x8B5CF6FF, -- Deep purple
  0x06B6D4FF, -- Cyan
  0xF97316FF, -- Orange
  0x84CC16FF, -- Lime
}

local function color_from_key(key)
  local s = 0
  for i=1,#key do s = (s*131 + key:byte(i)) % 1000003 end
  return _palette[(s % #_palette) + 1]
end

local function infer_area(key)
  if key:match('^tcp_') then return 'TCP'
  elseif key:match('^mcp_') then return 'MCP'
  elseif key:match('^transport_') then return 'Transport'
  else return 'Global' end
end

-- Enhanced FS helpers for packages scan
local function list_files(dir, ext, out)
  out = out or {}
  local i=0; while true do
    local f = reaper.EnumerateFiles(dir, i); if not f then break end
    if (not ext) or f:lower():sub(-#ext) == ext:lower() then out[#out+1] = join(dir, f) end
    i=i+1
  end
  return out
end

local function list_subdirs(dir, out)
  out = out or {}
  local j=0; while true do
    local s = reaper.EnumerateSubdirectories(dir, j); if not s then break end
    out[#out+1] = join(dir, s); j=j+1
  end
  return out
end

local function read_manifest(pkg_dir)
  local mpath = join(pkg_dir, 'manifest.json')
  if not file_exists(mpath) then return nil end
  local s = read_all(mpath); if not s then return nil end
  local ok, json = pcall(require, 'json'); if not ok or not json or not json.decode then return nil end
  local ok2, data = pcall(json.decode, s); if not ok2 or type(data) ~= 'table' then return nil end
  return data
end

function M.new(deps)
  -- deps: { lifecycle, image_cache, assembler, theme, settings }
  local settings = deps.settings
  local theme    = deps.theme
  local assembler= deps.assembler
  local cache    = deps.image_cache

  local core = {
    deps = deps,
    log  = log,
    try  = try,
    bor  = bor,
    add_rect = add_rect,
    add_shadow = add_shadow,
    color_from_key = color_from_key,
    infer_area = infer_area,
    cache = cache,

    -- Enhanced flags with additional button flags
    flags = {
      TBL_NOBODY      = FLAG('ImGui_TableFlags_NoBordersInBody'),
      TBL_ROWBG       = FLAG('ImGui_TableFlags_RowBg'),
      TBL_BORDERS     = FLAG('ImGui_TableFlags_Borders'),
      TBL_SIZING_SAME = FLAG('ImGui_TableFlags_SizingStretchSame'),
      TBL_SIZING_PROP = FLAG('ImGui_TableFlags_SizingStretchProp'),
      COL_WIDTH_FIXED = FLAG('ImGui_TableColumnFlags_WidthFixed'),
      MB_LEFT  = (function() local v=FLAG('ImGui_MouseButton_Left');  return (v~=0) and v or 0 end)(),
      MB_RIGHT = (function() local v=FLAG('ImGui_MouseButton_Right'); return (v~=0) and v or 1 end)(),
      BUTTON_FLAGS_MOUSEBUTTONMASK = FLAG('ImGui_ButtonFlags_MouseButtonMask'),
    },
    
    -- Selection management
    selection = {
      packages = {},
      assets = {},
      clear = function(self) self.packages = {}; self.assets = {} end,
    },
  }
  core.flags.TBL_STRETCH = (core.flags.TBL_SIZING_SAME ~= 0) and core.flags.TBL_SIZING_SAME or core.flags.TBL_SIZING_PROP

  -------------------------------------------------------
  -- ASSETS state + API
  -------------------------------------------------------
  local selections = assembler.load_selections() or {}
  local variants   = {}
  local elements   = {}

  local assets = {
    selections = selections,
    variants   = variants,
    elements   = elements,
    card = (settings and settings:get('card_size', 120)) or 120,
    grid = (settings and settings:get('grid_size', 96)) or 96,
    show_original_sizes = (settings and settings:get('show_original_sizes', false)) or false,
    gallery_original_sizes = (settings and settings:get('gallery_original_sizes', false)) or false,
  }

  local function get_roots()
    local roots = {}
    local dir = theme.prepare_images(false)
    if dir then roots[#roots+1] = join(dir, 'Assembler') end
    return roots
  end

  function assets:rescan()
    log("refresh_variants: begin")
    self.variants = assembler.scan_variants(get_roots()) or {}
    self.elements = {}
    for k,_ in pairs(self.variants) do self.elements[#self.elements+1] = k end
    table.sort(self.elements)
    if cache and cache.clear then cache:clear() end
    collectgarbage('collect')
    log("refresh_variants: %d elements", #self.elements)
  end

  function assets:thumb(key)
    if self.selections[key] and self.selections[key].path then return self.selections[key].path end
    local list = self.variants[key]
    if not list or not list[1] then return nil end
    return list[1].path
  end

  function assets:pick(key, variant_path)
    self.selections[key] = { path = variant_path, dest = (key or "element") .. ".png" }
    assembler.save_selections(self.selections)
  end

  core.assets = assets

  -------------------------------------------------------
  -- PACKAGES state + API with enhanced selection support
  -------------------------------------------------------
  local packages_index = {}
  local pkg = {
    index   = packages_index,
    active  = (settings and settings:get('pkg_active', {})) or {},
    order   = (settings and settings:get('pkg_order', {})) or {},
    pins    = (settings and settings:get('pkg_pins', {})) or {},
    excl    = (settings and settings:get('pkg_exclusions', {})) or {},
    filters = (settings and settings:get('pkg_filters', { TCP=true, MCP=true, Transport=true, Global=true })) or { TCP=true, MCP=true, Transport=true, Global=true },
    search  = (settings and settings:get('pkg_search','')) or '',
    tile    = (settings and settings:get('pkg_tilesize', 240)) or 240,
    demo    = (settings and settings:get('pkg_demo', nil)),
  }

  local function seed_mock_packages()
    local function aset(list)
      local t, o = {}, {}
      for _,k in ipairs(list) do t[k]=true; o[#o+1]=k end
      return t,o
    end
    local P = {}
    local c1, o1 = aset({'tcp_panel_bg','tcp_mute_on','tcp_recarm_on','track_solo_on','global_read'})
    P[#P+1] = { id='CleanLines', path='(mock)/CleanLines', assets=c1, keys_order=o1,
      meta={ name='CleanLines', tags={'flat','light','modern'}, color='#42E896', mosaic={'tcp_panel_bg.png','tcp_mute_on.png','track_solo_on.png'} } }
    local c2, o2 = aset({'tcp_mute_on','tcp_recarm_on','global_touch','global_write','transport_bg'})
    P[#P+1] = { id='DarkBevel', path='(mock)/DarkBevel', assets=c2, keys_order=o2,
      meta={ name='DarkBevel', tags={'bevel','dark','classic'}, color='#5BCEFA', mosaic={'tcp_mute_on.png','global_write.png','transport_bg.png'} } }
    local c3, o3 = aset({'transport_basis_half','transport_basis_quarter','transport_tap','transport_bg','transport_bpm'})
    P[#P+1] = { id='TransportGlyphs', path='(mock)/TransportGlyphs', assets=c3, keys_order=o3,
      meta={ name='Transport Glyphs', tags={'transport','minimal'}, color='#FFB84D', mosaic={'transport_bg.png','transport_tap.png','transport_bpm.png'} } }
    local c4, o4 = aset({'tcp_panel_bg','tcp_env_read','tcp_env_latch','tcp_mute_on'})
    P[#P+1] = { id='TCPGlass', path='(mock)/TCPGlass', assets=c4, keys_order=o4,
      meta={ name='TCP Light Glass', tags={'tcp','glass','light','modern'}, color='#A78BFA', mosaic={'tcp_panel_bg.png','tcp_env_read.png','tcp_mute_on.png'} } }
    local c5, o5 = aset({'mcp_panel_bg','mcp_fx_on','mcp_fx_off','mcp_io_on','mcp_send_on'})
    P[#P+1] = { id='MCPModern', path='(mock)/MCPModern', assets=c5, keys_order=o5,
      meta={ name='MCP Modern', tags={'mcp','sleek','professional'}, color='#4ADE80', mosaic={'mcp_panel_bg.png','mcp_fx_on.png','mcp_io_on.png'} } }
    local c6, o6 = aset({'global_play','global_stop','global_record','global_pause','global_repeat'})
    P[#P+1] = { id='GlobalControls', path='(mock)/GlobalControls', assets=c6, keys_order=o6,
      meta={ name='Global Controls', tags={'global','controls','essential'}, color='#FF6B7A', mosaic={'global_play.png','global_stop.png','global_record.png'} } }
    return P
  end

  local function scan_packages_real()
    local base = theme.prepare_images(false)
    if not base then return {} end
    local pkg_root = join(join(base, 'Assembler'), 'Packages')
    local subdirs = list_subdirs(pkg_root, {})
    local out = {}
    for _, pdir in ipairs(subdirs) do
      local id = (pdir:match("[^\\/]+$") or "Package")
      local assets = {}
      local keys_order = {}
      for _, fp in ipairs(list_files(pdir, '.png', {})) do
        local name = fp:match("[^\\/]+$") or fp
        local key = (name:gsub("%.%w+$",""))
        assets[key] = fp
        keys_order[#keys_order+1] = key
      end
      local meta_raw = read_manifest(pdir) or {}
      local meta = {
        name = meta_raw.name or id,
        tags = meta_raw.tags or {},
        color = (meta_raw.preview and meta_raw.preview.color) or nil,
        mosaic = (meta_raw.preview and meta_raw.preview.mosaic) or nil,
      }
      out[#out+1] = { id=id, path=pdir, assets=assets, keys_order=keys_order, meta=meta }
    end
    return out
  end

  local function ensure_order(ids)
    if #pkg.order == 0 then
      for _,id in ipairs(ids) do pkg.order[#pkg.order+1] = id end
      if settings then settings:set('pkg_order', pkg.order) end
    else
      local known = {}
      for _,id in ipairs(pkg.order) do known[id] = true end
      for _,id in ipairs(ids) do if not known[id] then pkg.order[#pkg.order+1]=id end end
      local keep = {}
      for _,id in ipairs(ids) do keep[id]=true end
      local filtered = {}
      for _,id in ipairs(pkg.order) do if keep[id] then filtered[#filtered+1]=id end end
      pkg.order = filtered
      if settings then settings:set('pkg_order', pkg.order) end
    end
  end

  function pkg:scan()
    log("refresh_packages: begin")
    if self.demo == nil then
      local real = scan_packages_real()
      if #real == 0 then
        self.index = seed_mock_packages()
        self.demo = true
        if settings then settings:set('pkg_demo', true) end
        log("refresh_packages: using MOCK (%d pkgs)", #self.index)
      else
        self.index = real
        self.demo = false
        if settings then settings:set('pkg_demo', false) end
        log("refresh_packages: using REAL (%d pkgs)", #self.index)
      end
    else
      if self.demo then
        self.index = seed_mock_packages()
      else
        self.index = scan_packages_real()
      end
      log("refresh_packages: explicit mode (%s) -> %d pkgs", tostring(self.demo), #self.index)
    end
    local ids = {}
    for _,P in ipairs(self.index) do ids[#ids+1]=P.id end
    ensure_order(ids)
  end

  function pkg:visible()
    local out = {}
    local q = (self.search or ''):lower()
    -- map id->P for order
    local map = {}; for _,P in ipairs(self.index) do map[P.id]=P end
    -- ordered list
    local ordered = {}
    for _,id in ipairs(self.order) do if map[id] then ordered[#ordered+1]=map[id] end end
    -- append any new
    local known={}; for _,id in ipairs(self.order) do known[id]=true end
    for _,P in ipairs(self.index) do if not known[P.id] then ordered[#ordered+1]=P end end
    -- filter
    for _, P in ipairs(ordered) do
      local label = (P.meta.name or P.id):lower()
      local tagstr = table.concat(P.meta.tags or {}, ' '):lower()
      local pass = (q == '') or label:find(q,1,true) or tagstr:find(q,1,true)
      if pass then
        local any=false
        for key,_ in pairs(P.assets) do
          if self.filters[infer_area(key)] then any=true; break end
        end
        if any then out[#out+1] = P end
      end
    end
    return out
  end

  function pkg:conflicts(active_only)
    local key_count = {}
    for _, P in ipairs(self.index) do
      if (not active_only) or self.active[P.id] then
        for k,_ in pairs(P.assets) do key_count[k] = (key_count[k] or 0) + 1 end
      end
    end
    local out = {}
    for _, P in ipairs(self.index) do
      local c = 0
      if (not active_only) or self.active[P.id] then
        for k,_ in pairs(P.assets) do if (key_count[k] or 0) > 1 then c = c + 1 end end
      end
      out[P.id] = c
    end
    return out
  end

  function pkg:reorder(srcId, beforeId)
    local src,dst
    for i,id in ipairs(self.order) do if id==srcId then src=i end; if id==beforeId then dst=i end end
    if not (src and dst) then return end
    local id = table.remove(self.order, src)
    if src < dst then dst = dst - 1 end
    table.insert(self.order, dst, id)
    if settings then settings:set('pkg_order', self.order) end
    log("reorder: %s -> before %s", srcId, beforeId)
  end

  function pkg:toggle(id)
    self.active[id] = not (self.active[id] == true)
    if settings then settings:set('pkg_active', self.active) end
    log("toggle: %s -> %s", id, tostring(self.active[id]))
  end
  
  -- Batch operations for selection
  function pkg:activate_selected(selected)
    local count = 0
    for pid, is_selected in pairs(selected) do
      if is_selected then
        self.active[pid] = true
        count = count + 1
      end
    end
    if settings then settings:set('pkg_active', self.active) end
    log("activated %d selected packages", count)
  end
  
  function pkg:deactivate_selected(selected)
    local count = 0
    for pid, is_selected in pairs(selected) do
      if is_selected then
        self.active[pid] = false
        count = count + 1
      end
    end
    if settings then settings:set('pkg_active', self.active) end
    log("deactivated %d selected packages", count)
  end

  core.pkg = pkg

  -------------------------------------------------------
  -- Export
  -------------------------------------------------------
  return core
end

return M