-- core/settings.lua - debounced settings store in /cache/settings.json

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'
local json = require('json')

local SEP = package.config:sub(1,1)

local Settings = {}
Settings.__index = Settings

local function ensure_dir(path)
  if reaper and reaper.RecursiveCreateDirectory then
    reaper.RecursiveCreateDirectory(path, 0)
  else
    -- naive fallback: try creating leaf
    os.execute((SEP=="\\") and ('mkdir "'..path..'"') or ('mkdir -p "'..path..'"'))
  end
end

local function read_file(p)
  local f = io.open(p, "rb"); if not f then return nil end
  local s = f:read("*a"); f:close(); return s
end

local function write_file_atomic(p, s)
  local tmp = p .. ".tmp"
  local f = assert(io.open(tmp, "wb")); f:write(s or ""); f:close()
  os.remove(p) -- Windows-safe replace
  assert(os.rename(tmp, p))
end

local function split_path(key)
  local out = {}; for part in tostring(key):gmatch("[^%.]+") do out[#out+1]=part end
  return out
end

local function get_nested(t, key, default)
  local cur = t
  for _,k in ipairs(split_path(key)) do
    if type(cur) ~= "table" then return default end
    cur = cur[k]
    if cur == nil then return default end
  end
  return cur
end

local function set_nested(t, key, val)
  local cur = t
  local parts = split_path(key)
  for i=1,#parts-1 do
    local k = parts[i]
    if type(cur[k]) ~= "table" then cur[k] = {} end
    cur = cur[k]
  end
  cur[parts[#parts]] = val
end

local function now() return reaper and reaper.time_precise and reaper.time_precise() or (os.clock()) end

function Settings:sub(prefix)
  local parent = self
  local view = setmetatable({}, {
    __index = {
      get = function(_, key, default) return parent:get(prefix .. "." .. key, default) end
      ,set = function(_, key, val)     parent:set(prefix .. "." .. key, val) end
      ,maybe_flush = function(_) parent:maybe_flush() end
      ,flush = function(_) parent:flush() end
    }
  })
  return view
end

function Settings:get(key, default) return get_nested(self._data, key, default) end

function Settings:set(key, val)
  set_nested(self._data, key, val)
  self._dirty = true
  self._last_touch = now()
end

function Settings:maybe_flush()
  if not self._dirty then return end
  local t = now()
  if (t - (self._last_write or 0)) >= (self._interval or 0.5) then
    self:flush()
  end
end

function Settings:flush()
  if not self._dirty then return end
  ensure_dir(self._dir)
  local ok, serialized = pcall(json.encode, self._data)
  if ok then
    write_file_atomic(self._path, serialized)
    self._dirty = false
    self._last_write = now()
  end
end

-- Factory
local singleton -- reuse one store across modules
local M = {}

function M.open(cache_dir, filename)
  if singleton then return singleton end
  cache_dir = cache_dir or "."
  filename  = filename  or "settings.json"
  local path = cache_dir .. ((cache_dir:sub(-1)==SEP) and "" or SEP) .. filename
  local t = {}
  local s = read_file(path)
  if s then t = json.decode(s) or {} end
  singleton = setmetatable({
    _data = t, _dir = cache_dir, _path = path,
    _dirty = false, _last_touch = 0, _last_write = 0, _interval = 0.5
  }, Settings)
  return singleton
end

return M
