-- core/package_manager.lua
-- Complete package management system

local M = {}

local SEP = package.config:sub(1,1)
local function join(a,b) return (a:sub(-1)==SEP) and (a..b) or (a..SEP..b) end
local function file_exists(p) local f=io.open(p,"rb"); if f then f:close() return true end return false end
local function read_json(p) 
  local f = io.open(p, "r")
  if not f then return {} end
  local content = f:read("*a")
  f:close()
  -- Simple JSON parse for package metadata
  return loadstring("return " .. content:gsub('("[^"]+")%s*:', '[%1]='))() or {}
end

-- Package class
local Package = {}
Package.__index = Package

function Package:new(id, path)
  local p = setmetatable({
    id = id,
    path = path,
    meta = {},
    assets = {},
    keys_order = {},
  }, self)
  p:load()
  return p
end

function Package:load()
  -- Load package.json metadata
  local meta_path = join(self.path, "package.json")
  if file_exists(meta_path) then
    self.meta = read_json(meta_path)
  else
    self.meta = { name = self.id, author = "Unknown", version = "1.0" }
  end
  
  -- Scan for assets
  self:scan_assets()
end

function Package:scan_assets()
  self.assets = {}
  self.keys_order = {}
  
  local i = 0
  while true do
    local file = reaper.EnumerateFiles(self.path, i)
    if not file then break end
    if file:match("%.png$") then
      local key = file:gsub("%.png$", "")
      self.assets[key] = join(self.path, file)
      table.insert(self.keys_order, key)
    end
    i = i + 1
  end
  
  table.sort(self.keys_order)
end

-- Package Manager
function M.create(settings)
  local mgr = {
    settings = settings,
    packages = {},
    index = {},
    order = {},
    active = {},
    filters = { TCP = true, MCP = true, Transport = true, Global = true },
    search = "",
    tile_size = 220,
    demo = false,
    
    -- Exclusions and pins
    excl = {},  -- package_id -> { asset_key -> true }
    pins = {},  -- asset_key -> package_id
  }
  
  -- Load settings
  if settings then
    mgr.order = settings:get('pkg_order', {})
    mgr.active = settings:get('pkg_active', {})
    mgr.filters = settings:get('pkg_filters', mgr.filters)
    mgr.tile_size = settings:get('pkg_tilesize', 220)
    mgr.demo = settings:get('pkg_demo', false)
    mgr.excl = settings:get('pkg_exclusions', {})
    mgr.pins = settings:get('pkg_pins', {})
  end
  
  function mgr:scan()
    self.packages = {}
    self.index = {}
    
    if self.demo then
      -- Generate demo packages
      for i = 1, 15 do
        local id = "demo_pack_" .. i
        local pack = {
          id = id,
          path = "(demo)",
          meta = {
            name = "Demo Package " .. i,
            author = "Demo Author",
            version = "1.0",
            mosaic = { "tcp_bg", "tcp_envcp", "mcp_bg" },
          },
          assets = {},
          keys_order = {},
        }
        
        -- Add mock assets
        for j = 1, 20 + i * 3 do
          local key = string.format("asset_%02d", j)
          pack.assets[key] = true
          table.insert(pack.keys_order, key)
        end
        
        self.packages[id] = pack
        table.insert(self.index, pack)
      end
    else
      -- Scan real packages directory
      local script_dir = debug.getinfo(1, 'S').source:sub(2):match("(.*"..SEP..")") or ("."..SEP)
      local packages_dir = join(script_dir, "Packages")
      
      local i = 0
      while true do
        local dir = reaper.EnumerateSubdirectories(packages_dir, i)
        if not dir then break end
        
        local pack_path = join(packages_dir, dir)
        local pack = Package:new(dir, pack_path)
        self.packages[dir] = pack
        table.insert(self.index, pack)
        i = i + 1
      end
    end
    
    -- Apply saved order
    if #self.order > 0 then
      local ordered = {}
      local seen = {}
      
      for _, id in ipairs(self.order) do
        if self.packages[id] then
          table.insert(ordered, self.packages[id])
          seen[id] = true
        end
      end
      
      -- Add any new packages not in saved order
      for _, pack in ipairs(self.index) do
        if not seen[pack.id] then
          table.insert(ordered, pack)
        end
      end
      
      self.index = ordered
      
      -- Update order list
      self.order = {}
      for _, pack in ipairs(self.index) do
        table.insert(self.order, pack.id)
      end
    else
      -- Initialize order
      for _, pack in ipairs(self.index) do
        table.insert(self.order, pack.id)
      end
    end
  end
  
  function mgr:visible()
    local visible = {}
    
    for _, pack in ipairs(self.index) do
      local show = true
      
      -- Apply search filter
      if self.search and self.search ~= "" then
        local needle = self.search:lower()
        local haystack = (pack.meta.name or pack.id):lower()
        if not haystack:find(needle, 1, true) then
          show = false
        end
      end
      
      -- Apply category filters (simplified for demo)
      -- In real implementation, check asset categories
      
      if show then
        table.insert(visible, pack)
      end
    end
    
    return visible
  end
  
  function mgr:toggle(id)
    self.active[id] = not self.active[id]
    if self.settings then
      self.settings:set('pkg_active', self.active)
    end
  end
  
  function mgr:conflicts(detailed)
    -- Find asset conflicts between packages
    local conflicts = {}
    local asset_providers = {}  -- asset -> { package_ids }
    
    for _, pack in ipairs(self.index) do
      if self.active[pack.id] then
        for asset in pairs(pack.assets) do
          -- Check if asset is excluded
          if not (self.excl[pack.id] and self.excl[pack.id][asset]) then
            -- Check if asset is pinned to another package
            if not self.pins[asset] or self.pins[asset] == pack.id then
              asset_providers[asset] = asset_providers[asset] or {}
              table.insert(asset_providers[asset], pack.id)
            end
          end
        end
      end
    end
    
    -- Count conflicts per package
    for asset, providers in pairs(asset_providers) do
      if #providers > 1 then
        for _, pack_id in ipairs(providers) do
          conflicts[pack_id] = (conflicts[pack_id] or 0) + 1
        end
      end
    end
    
    return conflicts
  end
  
  -- Initialize
  mgr:scan()
  
  return mgr
end

return M