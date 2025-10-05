-- core/image_cache.lua
-- Metadata-driven 3-state image detection and caching
-- Now supports opts.no_crop=true to bypass 3-state slicing (show full image)
package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'
local M = {}

local metadata = nil

local function load_metadata()
  if metadata then return metadata end
  
  local SEP = package.config:sub(1,1)
  local src = debug.getinfo(1,'S').source:sub(2)
  local dir = src:match("(.*"..SEP..")") or ("."..SEP)
  local meta_path = dir:gsub("core"..SEP.."$", "") .. "reaper_img_metadata.json"
  
  local file = io.open(meta_path, "r")
  if not file then
    metadata = { images = {} }
    return metadata
  end
  
  local content = file:read("*a")
  file:close()
  
  local json_ok, json = pcall(require, 'json')
  if json_ok and json and json.decode then
    local result = json.decode(content)
    if result and result.images then
      metadata = result
      return metadata
    end
  end
  
  metadata = { images = {} }
  local images_start = content:match('"images"%s*:%s*{')
  if images_start then
    local start_pos = content:find('"images"%s*:%s*{')
    if start_pos then
      local images_content = content:sub(start_pos)
      for img_name, is_3state_str in images_content:gmatch('"([^"]+)"%s*:%s*{[^}]*"is_3state"%s*:%s*(%a+)') do
        if img_name ~= "_comment" then
          metadata.images[img_name] = { is_3state = (is_3state_str == "true") }
        end
      end
    end
  end
  
  return metadata
end

local function img_flags_noerr()
  return (type(ImGui.ImageFlags_NoErrors) == "function") and ImGui.ImageFlags_NoErrors or 0
end

local function create_image(path)
  local ok, img = pcall(ImGui.CreateImage, path, img_flags_noerr)
  if ok and img then return img end
  return nil
end

local function destroy_image(img)
  if not img then return end
  pcall(ImGui.DestroyImage, img)
end

local function image_size(img)
  local ok, w, h = pcall(ImGui.Image_GetSize, img)
  if ok and w and h then return w, h end
  return nil, nil
end

local function get_image_name(path)
  if not path then return nil end
  local name = path:match("[^\\/]+$") or path
  return name:gsub("%.png$", ""):gsub("%.PNG$", "")
end

local function is_three_state_from_metadata(path)
  local meta = load_metadata()
  local name = get_image_name(path)
  if not name then return false end
  local img_meta = meta.images[name]
  return img_meta and img_meta.is_3state == true
end

local Cache = {}
Cache.__index = Cache

function M.new(opts)
  opts = opts or {}
  local self = setmetatable({
    _cache        = {},
    _creates_left = 0,
    _budget       = math.max(0, tonumber(opts.budget or 48)),
    _no_crop      = opts.no_crop == true,  -- <— NEW: bypass slicing when true
  }, Cache)
  return self
end

function Cache:begin_frame()
  self._creates_left = self._budget
end

function Cache:clear()
  for _, rec in pairs(self._cache) do
    if rec and rec.img then destroy_image(rec.img) end
  end
  self._cache = {}
  collectgarbage('collect')
end

function Cache:unload(path)
  local rec = self._cache[path]
  if rec and rec.img then destroy_image(rec.img) end
  self._cache[path] = nil
end

function Cache:set_no_crop(b)
  self._no_crop = not not b
  -- We keep existing records; drawing uses stored src rects.
  -- If you want to refresh to full frames immediately, call :clear() after toggling.
end

local function ensure_record(self, path)
  if not path or path == "" then return nil end

  local rec = self._cache[path]
  if rec == false then return nil end
  if rec and rec.img then return rec end

  if self._creates_left <= 0 then return nil end

  local img = create_image(path)
  if not img then
    self._cache[path] = false
    return nil
  end

  local w, h = image_size(img)
  if not w then
    destroy_image(img)
    self._cache[path] = false
    return nil
  end

  -- Decide source rectangle once on creation
  local src_x, src_y, src_w, src_h
  if self._no_crop then
    -- Show the whole texture (no slicing)
    src_x, src_y, src_w, src_h = 0, 0, w, h
  else
    if is_three_state_from_metadata(path) and w > 0 then
      local frame_w = math.floor(w / 3)
      src_x, src_y, src_w, src_h = 0, 0, frame_w, h
    else
      src_x, src_y, src_w, src_h = 0, 0, w, h
    end
  end
  
  rec = { 
    img = img, 
    w = w, 
    h = h,
    src_x = src_x,
    src_y = src_y, 
    src_w = src_w,
    src_h = src_h
  }
  self._cache[path] = rec
  self._creates_left = self._creates_left - 1
  return rec
end

local function validate_record(self, path, rec)
  if not rec or not rec.img then
    return ensure_record(self, path)
  end

  if type(rec.img) ~= "userdata" then
    pcall(destroy_image, rec.img)
    self._cache[path] = nil
    return ensure_record(self, path)
  end

  local ok, w, h = pcall(ImGui.Image_GetSize, rec.img)
  if ok and w and h and w > 0 and h > 0 then
    rec.w, rec.h = w, h
    return rec
  end
  
  pcall(destroy_image, rec.img)
  self._cache[path] = nil
  return ensure_record(self, path)
end

function Cache:draw_original(ctx, path)
  if not path or path == "" then
    ImGui.Dummy(ctx, 16, 16)
    return false
  end
  local rec = validate_record(self, path, self._cache[path])
  if not rec or not rec.img then
    ImGui.Dummy(ctx, 16, 16)
    return false
  end
  local u0 = rec.src_x / rec.w
  local v0 = rec.src_y / rec.h
  local u1 = (rec.src_x + rec.src_w) / rec.w
  local v1 = (rec.src_y + rec.src_h) / rec.h
  local ok = pcall(ImGui.Image, ctx, rec.img, rec.src_w, rec.src_h, u0, v0, u1, v1)
  if not ok then
    destroy_image(rec.img)
    self._cache[path] = false
    ImGui.Dummy(ctx, rec.src_w or 16, rec.src_h or 16)
    return false
  end
  return true
end

function Cache:draw_thumb(ctx, path, cell)
  cell = math.max(1, math.floor(tonumber(cell) or 1))
  if not path or path == "" then
    ImGui.Dummy(ctx, cell, cell)
    return false
  end
  local rec = validate_record(self, path, self._cache[path])
  if not rec or not rec.img then
    ImGui.Dummy(ctx, cell, cell)
    return false
  end
  local src_w, src_h = rec.src_w, rec.src_h
  if src_w <= 0 or src_h <= 0 then
    ImGui.Dummy(ctx, cell, cell)
    return false
  end
  local scale = math.min(cell / src_w, cell / src_h)
  local dw = math.max(1, math.floor(src_w * scale))
  local dh = math.max(1, math.floor(src_h * scale))
  local u0 = rec.src_x / rec.w
  local v0 = rec.src_y / rec.h
  local u1 = (rec.src_x + rec.src_w) / rec.w
  local v1 = (rec.src_y + rec.src_h) / rec.h
  local ok = pcall(ImGui.Image, ctx, rec.img, dw, dh, u0, v0, u1, v1)
  if not ok then
    destroy_image(rec.img)
    self._cache[path] = false
    ImGui.Dummy(ctx, cell, cell)
    return false
  end
  return true
end

function Cache:draw_fit(ctx, path, w, h)
  w = math.max(1, math.floor(tonumber(w) or 1))
  h = math.max(1, math.floor(tonumber(h) or 1))
  if not path or path == "" then
    ImGui.Dummy(ctx, w, h)
    return false
  end
  local rec = validate_record(self, path, self._cache[path])
  if not rec then
    ImGui.Dummy(ctx, w, h)
    return false
  end
  local u0 = rec.src_x / rec.w
  local v0 = rec.src_y / rec.h
  local u1 = (rec.src_x + rec.src_w) / rec.w
  local v1 = (rec.src_y + rec.src_h) / rec.h
  local ok = pcall(ImGui.Image, ctx, rec.img, w, h, u0, v0, u1, v1)
  if not ok then
    destroy_image(rec.img)
    self._cache[path] = false
    ImGui.Dummy(ctx, w, h)
    return false
  end
  return true
end

return M
