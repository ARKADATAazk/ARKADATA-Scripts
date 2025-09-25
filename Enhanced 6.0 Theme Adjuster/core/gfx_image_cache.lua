-- core/gfx_image_cache.lua
-- Budgeted cache for gfx buffer images (for use with reaper_img_handler)
-- Provides get_gfx(path) -> { id, w, h } interface

local M = {}

local Cache = {}
Cache.__index = Cache

-- Simple buffer pool manager (gfx has limited buffer slots)
local BUFFER_START = 100  -- Start from buffer 100 to avoid conflicts
local BUFFER_END = 1000   -- Use buffers 100-999
local buffer_pool = {}
local next_buffer = BUFFER_START

local function alloc_buffer()
  if #buffer_pool > 0 then
    return table.remove(buffer_pool)
  end
  if next_buffer >= BUFFER_END then
    return nil  -- Out of buffers
  end
  local buf = next_buffer
  next_buffer = next_buffer + 1
  return buf
end

local function free_buffer(id)
  if id and id >= BUFFER_START and id < BUFFER_END then
    gfx.setimgdim(id, 0, 0)
    table.insert(buffer_pool, id)
  end
end

function M.new(opts)
  opts = opts or {}
  local self = setmetatable({
    _cache        = {},
    _creates_left = 0,
    _budget       = math.max(0, tonumber(opts.budget or 48))
  }, Cache)
  return self
end

function Cache:begin_frame()
  self._creates_left = self._budget
end

function Cache:clear()
  for _, rec in pairs(self._cache) do
    if rec and rec.id then
      free_buffer(rec.id)
    end
  end
  self._cache = {}
  collectgarbage('collect')
end

function Cache:unload(path)
  local rec = self._cache[path]
  if rec and rec.id then
    free_buffer(rec.id)
  end
  self._cache[path] = nil
end

local function load_to_gfx(path)
  if not path or path == "" then return nil end
  
  local id = alloc_buffer()
  if not id then return nil end
  
  local ok = gfx.loadimg(id, path)
  if ok < 0 then
    free_buffer(id)
    return nil
  end
  
  local old = gfx.dest
  gfx.dest = id
  local w, h = gfx.getimgdim(id)
  gfx.dest = old
  
  if not w or not h or w <= 0 or h <= 0 then
    free_buffer(id)
    return nil
  end
  
  return { id = id, w = w, h = h }
end

function Cache:get_gfx(path)
  if not path or path == "" then return nil end
  
  local rec = self._cache[path]
  if rec == false then return nil end
  if rec and rec.id then return rec end
  
  if self._creates_left <= 0 then return nil end
  
  local loaded = load_to_gfx(path)
  if not loaded then
    self._cache[path] = false
    return nil
  end
  
  self._cache[path] = loaded
  self._creates_left = self._creates_left - 1
  return loaded
end

function Cache:preload(item)
  if type(item) == "table" then
    for _, p in ipairs(item) do self:preload(p) end
    return
  end
  local path = item
  if not path or path == "" then return end
  
  local rec = self._cache[path]
  if rec == false then return end
  if rec and rec.id then return end
  if self._creates_left <= 0 then return end
  
  local loaded = load_to_gfx(path)
  if loaded then
    self._cache[path] = loaded
    self._creates_left = self._creates_left - 1
  else
    self._cache[path] = false
  end
end

return M