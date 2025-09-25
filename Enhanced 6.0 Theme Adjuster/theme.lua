-- core/theme.lua â€“ Streamlined theme/cache management with JSON-based linking
local M = {}
local SEP = package.config:sub(1,1)

-- ---------------- utils ----------------
local function join(a,b) return (a:sub(-1)==SEP) and (a..b) or (a..SEP..b) end
local function file_exists(p) local f=io.open(p,"rb"); if f then f:close() return true end end
local function dir_exists(p) return p and (reaper.EnumerateFiles(p,0) or reaper.EnumerateSubdirectories(p,0)) ~= nil end
local function read_text(p) local f=io.open(p,"rb"); if not f then return nil end local s=f:read("*a"); f:close(); return s end
local function write_text(p,s) local f=io.open(p,"wb"); if not f then return false end f:write(s or ""); f:close(); return true end
local function dirname(p) return p and p:match("^(.*[\\/])") or "" end
local function basename_no_ext(p) local n=(p or ""):match("[^\\/]+$") or p return n and n:gsub("%.%w+$","") or nil end
local function script_base_dir() local src=debug.getinfo(1,'S').source:sub(2); return src:match("(.*"..SEP..")") or ("."..SEP) end

local function list_files(dir, ext, out)
  out = out or {}
  local i=0; while true do
    local f = reaper.EnumerateFiles(dir, i); if not f then break end
    if not ext or f:lower():sub(-#ext) == ext:lower() then out[#out+1] = join(dir, f) end
    i=i+1
  end
  return out
end

local function list_files_recursive(dir, ext, out)
  out = list_files(dir, ext, out or {})
  local j=0; while true do
    local s = reaper.EnumerateSubdirectories(dir, j); if not s then break end
    out = list_files_recursive(join(dir, s), ext, out)
    j=j+1
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

local function remove_dir_rec(dir)
  if not dir_exists(dir) then return end
  for _,p in ipairs(list_files(dir, nil, {})) do os.remove(p) end
  for _,sd in ipairs(list_subdirs(dir, {})) do remove_dir_rec(sd) end
  os.remove(dir)
end

local function try_run(cmd) local r=os.execute(cmd); return r==true or r==0 end

local function unzip(zip_path, dest_dir)
  reaper.RecursiveCreateDirectory(dest_dir, 0)
  local osname = reaper.GetOS() or ""
  if osname:find("Win") then
    local ps = ([[powershell -NoProfile -Command "Try{Expand-Archive -LiteralPath '%s' -DestinationPath '%s' -Force;$Host.SetShouldExit(0)}Catch{$Host.SetShouldExit(1)}"]])
      :format(zip_path:gsub("'", "''"), dest_dir:gsub("'", "''"))
    if try_run(ps) then return true end
    return try_run(([[tar -xf "%s" -C "%s"]]):format(zip_path, dest_dir))
  else
    if try_run(([[unzip -o -qq "%s" -d "%s"]]):format(zip_path, dest_dir)) then return true end
    return try_run(([[tar -xf "%s" -C "%s"]]):format(zip_path, dest_dir))
  end
end

-- Simple JSON encode/decode for theme->ZIP mappings
local function json_encode(tbl)
  local parts = {}
  for k, v in pairs(tbl) do
    parts[#parts+1] = ('"%s":"%s"'):format(tostring(k):gsub('"', '\\"'), tostring(v):gsub('"', '\\"'))
  end
  return "{" .. table.concat(parts, ",") .. "}"
end

local function json_decode(str)
  if not str or str == "" then return {} end
  local tbl = {}
  for k, v in str:gmatch('"([^"]+)":"([^"]+)"') do
    tbl[k] = v
  end
  return tbl
end

-- -------------- Paths & Storage --------------
local CACHE_ROOT = join(script_base_dir(), "cache")
local CACHE_DIR  = join(CACHE_ROOT, "cached_theme")
local LINKS_PATH = join(CACHE_ROOT, "theme_links.json")

-- -------------- Theme info --------------
function M.get_theme_info()
  local info = {}
  info.resource_path = reaper.GetResourcePath()
  info.themes_dir    = join(info.resource_path, "ColorThemes")
  info.theme_path    = reaper.GetLastColorThemeFile()
  info.theme_name    = basename_no_ext(info.theme_path or "")
  info.theme_ext     = info.theme_path and info.theme_path:match("%.([%w]+)$") or nil
  info.os            = reaper.GetOS()
  info.reaper_ver    = reaper.GetAppVersion()
  local r = select(1, reaper.ThemeLayout_GetParameter(0))
  info.has_theme_params = (r ~= nil)
  return info
end

-- -------------- Link management (JSON-based, using theme names as keys) --------------
local function load_links()
  local txt = read_text(LINKS_PATH)
  return json_decode(txt or "")
end

local function save_links(links)
  reaper.RecursiveCreateDirectory(CACHE_ROOT, 0)
  return write_text(LINKS_PATH, json_encode(links))
end

function M.get_linked_zip(theme_name)
  local links = load_links()
  return links[theme_name]
end

function M.set_linked_zip(theme_name, zip_path)
  local links = load_links()
  links[theme_name] = zip_path
  save_links(links)
end

function M.get_all_links()
  return load_links()
end

function M.clear_link(theme_name)
  local links = load_links()
  links[theme_name] = nil
  save_links(links)
end

-- -------------- ui_img parse --------------
local function parse_ui_img(theme_file, themes_dir)
  local txt = read_text(theme_file); if not txt then return nil end
  txt = txt:gsub("\r\n","\n"):gsub("\r","\n")
  for line in txt:gmatch("([^\n]+)") do
    line = line:gsub("%s*;.*$",""):gsub("%s*//.*$","")
    local k,v = line:match("^%s*([%w_%-]+)%s*=%s*(.-)%s*$")
    if k and v and k:lower()=="ui_img" and v~="" then
      v = v:gsub('^"(.*)"$', "%1"):gsub("^'(.*)'$", "%1")
      if v:match("^%a:[\\/\\]") or v:match("^/") then return v end
      local base = dirname(theme_file)
      local p1 = join(base, v); if dir_exists(p1) then return p1 end
      local p2 = join(themes_dir, v); if dir_exists(p2) then return p2 end
      return nil
    end
  end
  return nil
end

local function find_reapertheme_in(dir)
  local all = list_files_recursive(dir, ".ReaperTheme", {})
  return all[1]
end

local function guess_image_dir(root)
  local best, best_count = nil, -1
  for _, d in ipairs(list_subdirs(root, {})) do
    local c = #list_files_recursive(d, ".png", {})
    if c > best_count then best, best_count = d, c end
  end
  if best then return best end
  if #list_files_recursive(root, ".png", {}) > 0 then return root end
  return nil
end

-- -------------- Cache management --------------
local function cache_ready()
  return dir_exists(CACHE_DIR) and (#list_files_recursive(CACHE_DIR, ".png", {}) >= 5)
end

function M.list_theme_zips()
  local info = M.get_theme_info()
  local out = {}
  local i=0
  while true do
    local f = reaper.EnumerateFiles(info.themes_dir, i); if not f then break end
    if f:lower():sub(-15)==".reaperthemezip" then out[#out+1] = join(info.themes_dir, f) end
    i=i+1
  end
  table.sort(out, function(a,b) return a:lower() < b:lower() end)
  return out
end

function M.build_cache_from_zip(theme_name, zip_path)
  if not (zip_path and file_exists(zip_path)) then return nil, "ZIP not found" end
  reaper.RecursiveCreateDirectory(CACHE_ROOT, 0)
  remove_dir_rec(CACHE_DIR)
  reaper.RecursiveCreateDirectory(CACHE_DIR, 0)
  if not unzip(zip_path, CACHE_DIR) then return nil, "Unzip failed" end
  
  M.set_linked_zip(theme_name, zip_path)

  local inner = find_reapertheme_in(CACHE_DIR)
  local inner_dir = inner and (inner:match("^(.*[\\/])") or CACHE_DIR) or CACHE_DIR
  local ui = nil
  if inner then
    local txt = read_text(inner)
    if txt then
      txt = txt:gsub("\r\n","\n"):gsub("\r","\n")
      for line in txt:gmatch("([^\n]+)") do
        line = line:gsub("%s*;.*$",""):gsub("%s*//.*$","")
        local k,v = line:match("^%s*([%w_%-]+)%s*=%s*(.-)%s*$")
        if k and k:lower()=="ui_img" and v and v~="" then
          v = v:gsub('^"(.*)"$', "%1"):gsub("^'(.*)'$", "%1")
          if v:match("^%a:[\\/\\]") or v:match("^/") then ui = v else ui = join(inner_dir, v) end
          break
        end
      end
    end
  end
  if ui and dir_exists(ui) then return ui, nil end
  local g = guess_image_dir(CACHE_DIR)
  return (g or CACHE_DIR), (ui and not dir_exists(ui)) and "ui_img not found in ZIP; guessed" or nil
end

-- ----------- Status detection (no side effects) -----------
-- Returns: status, dir, linked_zip_name
function M.get_status()
  local info = M.get_theme_info()
  if not info.theme_path or not info.theme_name then return "error", nil, nil end
  local ext = info.theme_ext and info.theme_ext:lower() or "reapertheme"

  if ext == "reapertheme" then
    local ui = parse_ui_img(info.theme_path, info.themes_dir)
    if ui and dir_exists(ui) then 
      return "direct", ui, nil 
    end
    
    local linked_zip = M.get_linked_zip(info.theme_name)
    if linked_zip and file_exists(linked_zip) then
      if cache_ready() then 
        local zip_name = linked_zip:match("[^\\/]+$") or linked_zip
        return "linked-ready", CACHE_DIR, zip_name
      else
        local zip_name = linked_zip:match("[^\\/]+$") or linked_zip
        return "linked-needs-build", nil, zip_name
      end
    end
    return "needs-link", nil, nil
    
  elseif ext == "reaperthemezip" then
    if cache_ready() then 
      local zip_name = info.theme_path:match("[^\\/]+$") or info.theme_path
      return "zip-ready", CACHE_DIR, zip_name
    else
      return "zip-needs-build", nil, nil
    end
  end

  return "error", nil, nil
end

-- Simplified prepare: either returns dir or nil
function M.prepare_images(force_rebuild)
  local info = M.get_theme_info()
  local status, dir, _ = M.get_status()
  
  if status == "direct" then
    return dir
  end
  
  if status == "linked-ready" and not force_rebuild then
    return dir
  end
  
  if status == "linked-needs-build" or (status == "linked-ready" and force_rebuild) then
    local linked_zip = M.get_linked_zip(info.theme_name)
    if linked_zip then
      local new_dir, _ = M.build_cache_from_zip(info.theme_name, linked_zip)
      return new_dir
    end
  end
  
  if status == "zip-ready" and not force_rebuild then
    return dir
  end
  
  if status == "zip-needs-build" or (status == "zip-ready" and force_rebuild) then
    local new_dir, _ = M.build_cache_from_zip(info.theme_name, info.theme_path)
    return new_dir
  end
  
  return nil
end

-- -------------- Image listing --------------
function M.sample_images(img_dir, limit, opts)
  if not img_dir then return {}, 0 end
  limit = limit or 96
  opts  = opts or { recursive = true }
  local pngs = (opts.recursive ~= false) and list_files_recursive(img_dir, ".png") or list_files(img_dir, ".png")
  table.sort(pngs, function(a,b) return a:lower() < b:lower() end)
  if opts.filter and opts.filter ~= "" then
    local needle = opts.filter:lower()
    local filtered = {}
    for _,p in ipairs(pngs) do 
      if p:lower():find(needle, 1, true) then 
        filtered[#filtered+1] = p 
      end
    end
    pngs = filtered
  end
  local out = {}
  for i=1, math.min(limit, #pngs) do out[#out+1] = pngs[i] end
  return out, #pngs
end

function M.get_cache_dir() return CACHE_DIR end

-- Reload theme in REAPER
function M.reload_theme_in_reaper()
  local t = reaper.GetLastColorThemeFile()
  if t then reaper.OpenColorThemeFile(t) end
  reaper.ThemeLayout_RefreshAll()
end

return M