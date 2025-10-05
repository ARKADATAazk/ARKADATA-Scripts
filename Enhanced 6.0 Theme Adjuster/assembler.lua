-- assembler.lua — variants manager + packing (auto elements)

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local A = {}
local SEP = package.config:sub(1,1)

-- utils
local function join(a,b) return (a:sub(-1)==SEP) and (a..b) or (a..SEP..b) end
local function file_exists(p) local f=io.open(p,"rb") if f then f:close() return true end end
local function dir_exists(p) return p and (reaper.EnumerateFiles(p,0) or reaper.EnumerateSubdirectories(p,0)) ~= nil end
local function read_all(p) local f=io.open(p,"rb"); if not f then return nil end local s=f:read("*a"); f:close(); return s end
local function write_all(p,s) local f=io.open(p,"wb"); if not f then return false end f:write(s or ""); f:close(); return true end
local function script_dir() local src=debug.getinfo(1,'S').source:sub(2); return src:match("(.*"..SEP..")") or ("."..SEP) end
local function ensure_dir(p) reaper.RecursiveCreateDirectory(p, 0) end

-- tiny json (trusted data)
local function json_encode(t)
  local function esc(s) return s:gsub('[\\"]','\\%0'):gsub('\n','\\n') end
  local function val(v)
    if type(v)=="table" then
      if #v>0 then local a={} for i=1,#v do a[i]=val(v[i]) end; return "["..table.concat(a,",").."]" end
      local o={} for k,x in pairs(v) do o[#o+1]='"'..esc(tostring(k))..'":'..val(x) end; return "{"..table.concat(o,",").."}"
    elseif type(v)=="string" then return '"'..esc(v)..'"'
    elseif type(v)=="number" then return tostring(v)
    elseif type(v)=="boolean" then return v and "true" or "false" end
    return "null"
  end
  return val(t)
end
local function json_decode(s) local ok,res=pcall(function() return assert(load("return "..s))() end); return ok and res or nil end

-- public paths
function A.paths()
  local root = script_dir()
  local cache = join(root, "cache")
  local assembler = join(root, "Assembler")
  return {
    root=root, cache=cache, assembler=assembler,
    selections=join(cache,"assembler_selection.json"),
    work=join(cache,"work_theme"),
  }
end

-- scan Assembler/<element>/ *.png
function A.scan_variants(roots)
  local P = A.paths()
  roots = roots or { P.assembler }

  local out = {}  -- { [element] = { {name, path}, ... } }

  local function scan_root(root)
    if not root or root == "" then return end
    if not (reaper.EnumerateFiles(root,0) or reaper.EnumerateSubdirectories(root,0)) then return end

    local i=0
    while true do
      local el = reaper.EnumerateSubdirectories(root, i)
      if not el then break end
      local sub = (root:sub(-1) == SEP) and (root .. el) or (root .. SEP .. el)

      local list, j = {}, 0
      while true do
        local f = reaper.EnumerateFiles(sub, j)
        if not f then break end
        if f:lower():sub(-4)==".png" then
          list[#list+1] = { name=f:gsub("%.png$",""), path=sub .. SEP .. f }
        end
        j=j+1
      end
      if #list > 0 then
        out[el] = out[el] or {}
        for _,v in ipairs(list) do out[el][#out[el]+1] = v end
      end
      i=i+1
    end
  end

  for _,root in ipairs(roots) do scan_root(root) end

  for el, list in pairs(out) do
    table.sort(list, function(a,b) return a.name:lower() < b.name:lower() end)
  end
  return out
end


-- default destination filename from element name (can be overridden in UI)
local function default_dest_for(element)
  -- simple default: "<element>.png"
  return (element or "element")..".png"
end

-- selections load/save: { [element] = { path, dest } }
function A.load_selections()
  local P=A.paths(); ensure_dir(P.cache)
  local s=read_all(P.selections); if not s or s=="" then return {} end
  return json_decode(s) or {}
end
function A.save_selections(sel)
  local P=A.paths(); ensure_dir(P.cache)
  return write_all(P.selections, json_encode(sel))
end

-- copy helper
local function copy_file(src, dst_dir, new_name)
  local data=read_all(src); if not data then return false,"read fail" end
  ensure_dir(dst_dir)
  local dst = join(dst_dir, new_name or (src:match("[^\\/]+$") or "file.png"))
  return write_all(dst, data), dst
end

-- rm -rf dir
local function rm_rf(dir)
  if not dir_exists(dir) then return end
  local i=0; while true do local f=reaper.EnumerateFiles(dir,i); if not f then break end os.remove(join(dir,f)); i=i+1 end
  local j=0; local subs={}
  while true do local s=reaper.EnumerateSubdirectories(dir,j); if not s then break end subs[#subs+1]=join(dir,s); j=j+1 end
  for _,sd in ipairs(subs) do rm_rf(sd) end
  os.remove(dir)
end

-- clone folder tree
local function copy_tree(src, dst)
  ensure_dir(dst)
  local i=0; while true do local f=reaper.EnumerateFiles(src,i); if not f then break end
    local ok=copy_file(join(src,f), dst, f); if not ok then return false end
    i=i+1
  end
  local j=0; while true do local s=reaper.EnumerateSubdirectories(src,j); if not s then break end
    local sd=join(src,s); local dd=join(dst,s); local ok=copy_tree(sd,dd); if not ok then return false end
    j=j+1
  end
  return true
end

-- zip writer
local function try_run(cmd) local r=os.execute(cmd); return r==true or r==0 end
local function make_zip(src_dir, out_zip)
  local osname=reaper.GetOS() or ""
  if osname:find("Win") then
    local ps = ([[powershell -NoProfile -Command "Set-Location '%s'; if (Test-Path '%s') {Remove-Item '%s' -Force}; Compress-Archive -Path * -DestinationPath '%s' -Force"]])
      :format(src_dir:gsub("'", "''"), out_zip:gsub("'", "''"), out_zip:gsub("'", "''"), out_zip:gsub("'", "''"))
    return try_run(ps)
  else
    local zip = ([[cd "%s" && rm -f "%s" && zip -qr "%s" *]]):format(src_dir,out_zip,out_zip)
    return try_run(zip)
  end
end

-- apply selections
-- theme_info: { mode="direct"|"zip", ui_dir=..., cache_dir=..., themes_dir=..., theme_name=... }
function A.apply(theme_info, selections)
  if not selections or next(selections)==nil then return false,"No selections" end

  if theme_info.mode=="direct" and theme_info.ui_dir and dir_exists(theme_info.ui_dir) then
    for el,rec in pairs(selections) do
      if rec.path and file_exists(rec.path) then
        local dest = rec.dest or default_dest_for(el)
        local ok = select(1, copy_file(rec.path, theme_info.ui_dir, dest))
        if not ok then return false, "Copy failed: "..tostring(dest) end
      end
    end
    return true,"Patched files copied to ui_img"
  elseif theme_info.mode=="zip" and theme_info.cache_dir and dir_exists(theme_info.cache_dir) then
    local P=A.paths()
    rm_rf(P.work); ensure_dir(P.work)
    if not copy_tree(theme_info.cache_dir, P.work) then return false,"Clone cache failed" end

    -- find a likely ui_img dir (most PNGs)
    local function count_pngs(d)
      local n=0;i=0;while true do local f=reaper.EnumerateFiles(d,i);if not f then break end if f:lower():sub(-4)==".png" then n=n+1 end i=i+1 end
      local j=0;while true do local s=reaper.EnumerateSubdirectories(d,j);if not s then break end n=n+count_pngs(join(d,s)); j=j+1 end
      return n
    end
    local function find_ui_img(root)
      local best, bestN = root, count_pngs(root)
      local j=0; while true do local s=reaper.EnumerateSubdirectories(root,j); if not s then break end
        local d=join(root,s); local n=count_pngs(d); if n>bestN then best,bestN=d,n end
        j=j+1
      end
      return best
    end
    local ui_work = find_ui_img(P.work)

    for el,rec in pairs(selections) do
      if rec.path and file_exists(rec.path) then
        local dest = rec.dest or default_dest_for(el)
        local ok = select(1, copy_file(rec.path, ui_work, dest))
        if not ok then return false, "Copy failed: "..tostring(dest) end
      end
    end

    local patched_name = (theme_info.theme_name or "Theme").."_patched.ReaperThemeZip"
    local out_zip = join(P.cache, patched_name)
    if not make_zip(P.work, out_zip) then return false,"Zip failed" end

    local final = join(theme_info.themes_dir, patched_name)
    local data=read_all(out_zip); if not data then return false,"Zip readback failed" end
    os.remove(final)
    if not write_all(final, data) then return false,"Zip move failed" end

    reaper.OpenColorThemeFile(final)
    reaper.ThemeLayout_RefreshAll()
    return true,"Patched ZIP created and theme loaded"
  end

  return false,"Invalid theme mode"
end

-- expose default dest for UI
function A.default_dest_for(element) return default_dest_for(element) end

return A
