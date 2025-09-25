-- core/image_cache.lua
-- Budgeted, safe image cache for ReaImGui.
-- - Validates handles each frame before drawing (prevents stale-handle warnings)
-- - Recreates on demand within a per-frame creation budget
-- - Never calls ImGui_Image on an invalid handle
-- - Simple API: new({budget=?}), begin_frame(), draw_thumb(ctx,path,cell),
--              preload(path|{paths}), unload(path), clear()

local M = {}

-- ---------- helpers ----------

local function img_flags_noerr()
  return (type(reaper.ImGui_ImageFlags_NoErrors) == "function") and reaper.ImGui_ImageFlags_NoErrors() or 0
end

local function create_image(path)
  local ok, img = pcall(reaper.ImGui_CreateImage, path, img_flags_noerr())
  if ok and img then return img end
  return nil
end

local function destroy_image(img)
  if not img then return end
  pcall(reaper.ImGui_DestroyImage, img)
end

local function image_size(img)
  local ok, w, h = pcall(reaper.ImGui_Image_GetSize, img)
  if ok and w and h then return w, h end
  return nil, nil
end

-- ---------- cache object ----------

local Cache = {}
Cache.__index = Cache

-- opts:
--   budget : max images to (re)create per frame (default 48)
function M.new(opts)
  opts = opts or {}
  local self = setmetatable({
    _cache        = {},          -- path -> { img=?, w=?, h=? } | false (permanent fail)
    _creates_left = 0,           -- per-frame remaining budget
    _budget       = math.max(0, tonumber(opts.budget or 48)) -- >=0
  }, Cache)
  return self
end

-- Call once per frame (your lifecycle should do this for you)
function Cache:begin_frame()
  self._creates_left = self._budget
end

-- Unload everything (called on tab hide/close)
function Cache:clear()
  for _, rec in pairs(self._cache) do
    if rec and rec.img then
      destroy_image(rec.img)
      rec.img = nil
    end
  end
  self._cache = {}
  collectgarbage('collect')
end

-- Unload a single path
function Cache:unload(path)
  local rec = self._cache[path]
  if rec and rec.img then destroy_image(rec.img) end
  self._cache[path] = nil
end

-- Pre-create image(s) within budget
function Cache:preload(item)
  if type(item) == "table" then
    for _, p in ipairs(item) do self:preload(p) end
    return
  end
  local path = item
  if not path or path == "" then return end
  local rec = self._cache[path]
  if rec == false then return end           -- previously failed
  if rec and rec.img then return end        -- already loaded
  if self._creates_left <= 0 then return end

  local img = create_image(path)
  if img then
    local w, h = image_size(img)
    if not w then
      destroy_image(img)
      self._cache[path] = false
      return
    end
    self._cache[path] = { img = img, w = w, h = h }
    self._creates_left = self._creates_left - 1
  else
    self._cache[path] = false
  end
end

-- Ensure a valid record exists or create one (budgeted).
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

  rec = { img = img, w = w, h = h }
  self._cache[path] = rec
  self._creates_left = self._creates_left - 1
  return rec
end

-- Re-validate a record's handle; if stale, try to recreate within budget.
local function validate_record(self, path, rec)
  if not rec or not rec.img then return ensure_record(self, path) end

  local w, h = image_size(rec.img)
  if w and h then
    -- keep sizes fresh
    rec.w, rec.h = w, h
    return rec
  end

  -- stale -> destroy and recreate
  destroy_image(rec.img)
  self._cache[path] = nil
  return ensure_record(self, path)
end

-- Draw helper: fit original image into (cell x cell) while preserving aspect.
-- Returns true if drawn, false if a placeholder was drawn.
function Cache:draw_thumb(ctx, path, cell)
  cell = math.max(1, math.floor(tonumber(cell) or 1))

  if not path or path == "" then
    reaper.ImGui_Dummy(ctx, cell, cell)
    return false
  end

  -- validate / (re)create within budget
  local rec = validate_record(self, path, self._cache[path])
  if not rec or not rec.img then
    reaper.ImGui_Dummy(ctx, cell, cell)
    return false
  end

  local w, h = rec.w or 0, rec.h or 0
  if w <= 0 or h <= 0 then
    destroy_image(rec.img); self._cache[path] = false
    reaper.ImGui_Dummy(ctx, cell, cell)
    return false
  end

  -- ✦ Final safety: re-check size RIGHT before drawing.
  local w2, h2 = image_size(rec.img)
  if not w2 or not h2 then
    destroy_image(rec.img); self._cache[path] = nil
    -- try recreate once if budget allows
    rec = ensure_record(self, path)
    if not rec or not rec.img then
      self._cache[path] = false
      reaper.ImGui_Dummy(ctx, cell, cell)
      return false
    end
    w, h = rec.w, rec.h
  else
    w, h = w2, h2
  end

  local scale = math.min(cell / w, cell / h)
  local dw = math.max(1, math.floor(w * scale))
  local dh = math.max(1, math.floor(h * scale))

  local ok = pcall(reaper.ImGui_Image, ctx, rec.img, dw, dh)
  if not ok then
    destroy_image(rec.img); self._cache[path] = false
    reaper.ImGui_Dummy(ctx, cell, cell)
    return false
  end

  return true
end

-- Optional: draw to an exact size (stretches to w x h)
function Cache:draw_fit(ctx, path, w, h)
  w = math.max(1, math.floor(tonumber(w) or 1))
  h = math.max(1, math.floor(tonumber(h) or 1))

  if not path or path == "" then
    reaper.ImGui_Dummy(ctx, w, h)
    return false
  end

  local rec = validate_record(self, path, self._cache[path])
  if not rec then
    reaper.ImGui_Dummy(ctx, w, h)
    return false
  end

  local ok = pcall(reaper.ImGui_Image, ctx, rec.img, w, h)
  if not ok then
    destroy_image(rec.img)
    self._cache[path] = false
    reaper.ImGui_Dummy(ctx, w, h)
    return false
  end

  return true
end

return M
