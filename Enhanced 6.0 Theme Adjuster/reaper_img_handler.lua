-- reaper_img_handler.lua
-- Pink-line 9-slice + 3-state renderer on top of gfx_image_cache

local RIH = {}

local cache

-- Buffer pool for derived renders (use high range to avoid conflicts)
local DERIVED_START = 2000
local DERIVED_END = 3000
local derived_pool = {}
local next_derived = DERIVED_START

local function alloc_derived_buffer()
  if #derived_pool > 0 then
    return table.remove(derived_pool)
  end
  if next_derived >= DERIVED_END then
    return nil
  end
  local buf = next_derived
  next_derived = next_derived + 1
  return buf
end

local function free_derived_buffer(id)
  if id and id >= DERIVED_START and id < DERIVED_END then
    gfx.setimgdim(id, 0, 0)
    table.insert(derived_pool, id)
  end
end

local derived = {}
local order   = {}
local BUDGET  = 128

-- Temp file management
local SEP = package.config:sub(1,1)
local function get_temp_dir()
  local src = debug.getinfo(1,'S').source:sub(2)
  local dir = src:match("(.*"..SEP..")") or ("."..SEP)
  local temp = dir .. "cache" .. SEP .. "temp_render" .. SEP
  reaper.RecursiveCreateDirectory(temp, 0)
  return temp
end

local function drop_key(k)
  local r = derived[k]
  if r then 
    free_derived_buffer(r.gfx_id)
    if r.img_handle then
      pcall(reaper.ImGui_DestroyImage, r.img_handle)
    end
    if r.temp_file then
      os.remove(r.temp_file)
    end
  end
  derived[k] = nil
end

local function touch(k)
  for i=#order,1,-1 do if order[i]==k then table.remove(order,i) break end end
  order[#order+1] = k
  if #order > BUDGET then
    local ev = table.remove(order, 1)
    if ev then drop_key(ev) end
  end
end

function RIH.clear()
  for _, r in pairs(derived) do 
    free_derived_buffer(r.gfx_id)
    if r.img_handle then
      pcall(reaper.ImGui_DestroyImage, r.img_handle)
    end
    if r.temp_file then
      os.remove(r.temp_file)
    end
  end
  derived, order = {}, {}
  collectgarbage('collect')
end

local PINK = { {1,0,1}, {1,1,0} }
local pink_cache = {}

local function is_pink(r, g, b)
  for i=1,2 do
    local c = PINK[i]
    if (math.abs(r-c[1])<1e-3 and math.abs(g-c[2])<1e-3 and math.abs(b-c[3])<1e-3) then return true end
  end
  return false
end

local function read_pink(src_id, sw, sh)
  local hit = pink_cache[src_id]
  if hit then return hit end

  local old = gfx.dest
  gfx.dest = src_id

  local function scan_horiz(y)
    for x=0,sw-1 do
      local r,g,b = gfx.getpixel(x,y)
      if not is_pink(r,g,b) then return x end
    end
    return sw
  end
  local function scan_vert(x)
    for y=0,sh-1 do
      local r,g,b = gfx.getpixel(x,y)
      if not is_pink(r,g,b) then return y end
    end
    return sh
  end

  local inset_l = scan_vert(0)
  local inset_t = scan_horiz(0)
  local inset_r = scan_vert(sw-1)
  local inset_b = scan_horiz(sh-1)

  gfx.dest = old

  local has = (inset_l>0 or inset_t>0 or inset_r>0 or inset_b>0)
  local cw = math.max(0, sw - inset_l - (sw - inset_r))
  local ch = math.max(0, sh - inset_t - (sh - inset_b))
  local m = { has=has, l=inset_l, t=inset_t, r=inset_r, b=inset_b, cw=cw, ch=ch, sw=sw, sh=sh }
  pink_cache[src_id] = m
  return m
end

local function is_three_state(m) return (m and m.cw and m.cw > 0 and (m.cw % 3) == 0) end

local function blit9(src, sx, sy, sw, sh, dst, dw, dh)
  local old = gfx.dest
  gfx.dest = dst
  gfx.set(0,0,0,0); gfx.rect(0,0,dw,dh,1)

  local b = 1
  local c_w, c_h = math.max(0, sw-2*b), math.max(0, sh-2*b)
  local dc_w, dc_h = math.max(0, dw-2*b), math.max(0, dh-2*b)

  gfx.blit(src,1,0, sx,         sy,         b,b,  0,     0,     b,b)
  gfx.blit(src,1,0, sx+sw-b,    sy,         b,b,  dw-b,  0,     b,b)
  gfx.blit(src,1,0, sx,         sy+sh-b,    b,b,  0,     dh-b,  b,b)
  gfx.blit(src,1,0, sx+sw-b,    sy+sh-b,    b,b,  dw-b,  dh-b,  b,b)

  if c_w>0 then
    gfx.blit(src,1,0, sx+b, sy,          c_w,b,  b,     0,     dc_w,b)
    gfx.blit(src,1,0, sx+b, sy+sh-b,     c_w,b,  b,     dh-b,  dc_w,b)
  end
  if c_h>0 then
    gfx.blit(src,1,0, sx,   sy+b,        b,c_h,  0,     b,     b,   dc_h)
    gfx.blit(src,1,0, sx+sw-b, sy+b,     b,c_h,  dw-b,  b,     b,   dc_h)
  end

  if c_w>0 and c_h>0 then
    gfx.blit(src,1,0, sx+b, sy+b,        c_w,c_h, b,    b,     dc_w,dc_h)
  end

  gfx.dest = old
end

local function render_frame(src_id, pink, state, dst, out_w, out_h)
  local sx, sy = pink.l, pink.t
  local fw, fh = pink.cw > 0 and pink.cw or pink.sw, pink.ch > 0 and pink.ch or pink.sh
  if is_three_state(pink) then
    fw = math.floor(fw/3)
    sx = sx + fw * (state or 0)
  end
  if pink.has then
    blit9(src_id, sx, sy, fw, fh, dst, out_w, out_h)
  else
    local old = gfx.dest
    gfx.dest = dst
    gfx.set(0,0,0,0); gfx.rect(0,0,out_w,out_h,1)
    gfx.blit(src_id, 1, 0, sx, sy, fw, fh, 0, 0, out_w, out_h)
    gfx.dest = old
  end
end

local function ensure_render(path, size, state, native)
  if not cache or not cache.get_gfx then return nil end
  local src = cache:get_gfx(path)
  if not src or not src.id then return nil end
  local key = table.concat({ path, size or 0, state or 0, native and 1 or 0 }, "@")
  local got = derived[key]
  if got and got.img_handle then touch(key); return got end

  local sw, sh = src.w, src.h
  local pink = read_pink(src.id, sw, sh)

  local fw, fh = pink.cw > 0 and pink.cw or sw, pink.ch > 0 and pink.ch or sh
  if is_three_state(pink) then fw = math.floor(fw/3) end

  local out_w, out_h
  if native then
    out_w, out_h = fw, fh
  else
    local maxd = math.max(fw, fh)
    local s = (size and size > 0) and (size / maxd) or 1
    out_w = math.max(1, math.floor(fw * s + 0.5))
    out_h = math.max(1, math.floor(fh * s + 0.5))
  end

  local gfx_id = alloc_derived_buffer()
  if not gfx_id then return nil end
  
  gfx.setimgdim(gfx_id, out_w, out_h)
  render_frame(src.id, pink, state or 0, gfx_id, out_w, out_h)

  -- Save gfx buffer to temp file
  local temp_dir = get_temp_dir()
  local temp_file = temp_dir .. "render_" .. key:gsub("[^%w]", "_") .. ".png"
  
  local old_dest = gfx.dest
  gfx.dest = gfx_id
  local save_ok = gfx.save(temp_file)
  gfx.dest = old_dest
  
  if save_ok < 0 then
    free_derived_buffer(gfx_id)
    return nil
  end

  -- Load temp file as ImGui image
  local img_flags = (type(reaper.ImGui_ImageFlags_NoErrors) == "function") and reaper.ImGui_ImageFlags_NoErrors() or 0
  local ok, img_handle = pcall(reaper.ImGui_CreateImage, temp_file, img_flags)
  
  if not ok or not img_handle then
    free_derived_buffer(gfx_id)
    os.remove(temp_file)
    return nil
  end

  local rec = { gfx_id = gfx_id, img_handle = img_handle, temp_file = temp_file, w = out_w, h = out_h }
  derived[key] = rec
  touch(key)
  return rec
end

function RIH.attach_cache(c) cache = c end

function RIH.img(ctx, path, size, state)
  local rec = ensure_render(path, size or 96, state or 0, false)
  if rec and rec.img_handle then
    reaper.ImGui_Image(ctx, rec.img_handle, rec.w, rec.h)
  else
    reaper.ImGui_Dummy(ctx, size or 16, size or 16)
  end
end

function RIH.img_native(ctx, path, state)
  local rec = ensure_render(path, 0, state or 0, true)
  if rec and rec.img_handle then
    reaper.ImGui_Image(ctx, rec.img_handle, rec.w, rec.h)
  else
    reaper.ImGui_Dummy(ctx, 16, 16)
  end
end

return RIH