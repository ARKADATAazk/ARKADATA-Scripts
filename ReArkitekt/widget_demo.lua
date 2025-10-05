-- demo.lua — ReArkitekt ColorBlocks demo (fixed: numeric gap/min_col_w)

-- MUST BE FIRST: Load ImGui
package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua'
local ImGui = require 'imgui' '0.9'

-- ReaImGui presence check (AFTER loading)
if not ImGui.CreateContext then
  reaper.ShowMessageBox("ReaImGui missing (install via ReaPack → ReaTeam Extensions → ReaImGui).",
                        "ReArkitekt Demo", 0)
  return
end

-- Paths to resolve require('ReArkitekt.*') when this file sits inside ReArkitekt/
local function dirname(p) return p:match("^(.*)[/\\]") end
local function join(a,b) local s=package.config:sub(1,1); return (a:sub(-1)==s) and (a..b) or (a..s..b) end
local SRC   = debug.getinfo(1,"S").source:sub(2)
local HERE  = dirname(SRC) or "."
local PARENT= dirname(HERE or ".") or "."
local function addpath(p) if p and p~="" and not package.path:find(p,1,true) then package.path=p..";"..package.path end end
addpath(join(PARENT,"?.lua")); addpath(join(PARENT,"?/init.lua"))
addpath(join(HERE,  "?.lua")); addpath(join(HERE,  "?/init.lua"))

-- Your modules
local Shell        = require("ReArkitekt.app.shell")
local Settings     = (function() local ok,m=pcall(require,"ReArkitekt.core.settings"); return ok and m or nil end)()
local okStyle,Style= pcall(require,"ReArkitekt.gui.style")
local ColorBlocks  = require("ReArkitekt.gui.widgets.colorblocks")
local Draw         = require("ReArkitekt.gui.draw")
local Effects      = require("ReArkitekt.gui.fx.effects")

-- Small helpers
local function log(...) local t={}; for i=1,select("#",...) do t[#t+1]=tostring(select(i,...)) end reaper.ShowConsoleMsg(table.concat(t," ").."\n") end
local function clamp(x,a,b) if x<a then return a elseif x>b then return b else return x end end
local function hsv_to_rgba(h,s,v,a)
  local i = math.floor(h*6); local f = h*6 - i
  local p = v*(1-s); local q = v*(1-f*s); local t = v*(1-(1-f)*s)
  local r,g,b
  if     i%6==0 then r,g,b=v,t,p
  elseif i%6==1 then r,g,b=q,v,p
  elseif i%6==2 then r,g,b=p,v,t
  elseif i%6==3 then r,g,b=p,q,v
  elseif i%6==4 then r,g,b=t,p,v
  else               r,g,b=v,p,q
  end
  local R = clamp(math.floor(r*255+0.5),0,255)
  local G = clamp(math.floor(g*255+0.5),0,255)
  local B = clamp(math.floor(b*255+0.5),0,255)
  local A = clamp(math.floor((a or 1)*255+0.5),0,255)
  return (R<<24) | (G<<16) | (B<<8) | A -- 0xRRGGBBAA
end

-- Demo data model
local model = {
  items_by_key = {},
  order = {},
  selection = {},
  tile_min_w = 110,      -- numeric (IMPORTANT)
  gap = 12,              -- numeric (IMPORTANT)
  show_labels = true,
  ants = { color_enabled=0xFFFFFFFF, color_disabled=0xFFFFFF55, thickness=2, radius=8, dash=10, gap=6, speed=28 },
}

local function seed_colors()
  model.items_by_key = {}
  model.order = {}
  local n = 168
  for i=1,n do
    local h = (i-1)/n
    local col = hsv_to_rgba(h, 0.85, 0.95, 1.0)
    local key = string.format("C%03d", i)
    model.items_by_key[key] = { key=key, name=key, color=col }
    model.order[#model.order+1] = key
  end
end
seed_colors()

local function get_items()
  local arr = {}
  for _,k in ipairs(model.order) do arr[#arr+1] = model.items_by_key[k] end
  return arr
end
local function key_of(item) return item.key end

-- Tile renderer
local function render_color_tile(ctx, rect, item, state)
  local dl = ImGui.GetWindowDrawList(ctx)
  local x1,y1,x2,y2 = rect[1],rect[2],rect[3],rect[4]

  -- swatch
  Draw.rect_filled(dl, x1, y1, x2, y2, item.color, 6)
  Draw.rect(dl, x1+0.5, y1+0.5, x2-0.5, y2-0.5, 0x00000055, 6, 1)

  -- selection / hover
  if state.selected then
    local a = model.ants
    Effects.marching_ants_rounded(dl, x1, y1, x2, y2, a.color_enabled, a.thickness, a.radius, a.dash, a.gap, a.speed)
  elseif state.hover then
    Draw.rect(dl, x1, y1, x2, y2, 0xFFFFFF40, 6, 1)
  end

  if model.show_labels then
    local tw, th = ImGui.CalcTextSize(ctx, item.name)
    local pad = 6
    local tx = math.floor(x1 + (x2-x1 - tw)*0.5)
    local ty = math.floor(y2 - th - pad)
    ImGui.DrawList_AddText(dl, tx+1, ty+1, 0x000000CC, item.name)
    ImGui.DrawList_AddText(dl, tx,   ty,   0xFFFFFFFF, item.name)
  end
end

-- Grid (NOTE: numbers, not functions)
local grid = ColorBlocks.new({
  id = "colorblocks-demo",
  gap = model.gap,                   -- numeric
  min_col_w = model.tile_min_w,      -- numeric
  get_items = get_items,
  key = key_of,
  render_tile = render_color_tile,

  on_reorder = function(new_keys)
    -- sanitize → keep known keys in the order provided, append any missing at end
    local filtered, have = {}, {}
    for _,k in ipairs(new_keys) do if model.items_by_key[k] then filtered[#filtered+1]=k; have[k]=true end end
    for _,k in ipairs(model.order) do if not have[k] then filtered[#filtered+1]=k end end
    model.order = filtered
    log("[reorder]", #model.order, "items")
  end,

  on_select = function(keys) model.selection = keys end,

  on_right_click = function(key, selected_keys)
    local keys = (#selected_keys>0) and selected_keys or { key }
    for _,k in ipairs(keys) do
      local it = model.items_by_key[k]
      if it then
        local r = math.random()
        it.color = hsv_to_rgba(r, 0.85, 0.95, 1.0)
      end
    end
  end,

  on_click_empty = function() end,
})

-- Toolbar
local function draw_toolbar(ctx)
  ImGui.Text(ctx, "Min column width")
  ImGui.SameLine(ctx)
  local changed, v = ImGui.SliderInt(ctx, "##minw", model.tile_min_w, 60, 220)
  if changed then model.tile_min_w = v end

  ImGui.SameLine(ctx)
  ImGui.Text(ctx, "Gap")
  ImGui.SameLine(ctx)
  changed, v = ImGui.SliderInt(ctx, "##gap", model.gap, 0, 32)
  if changed then model.gap = v end

  ImGui.SameLine(ctx)
  changed, model.show_labels = ImGui.Checkbox(ctx, "Labels", model.show_labels)

  ImGui.SameLine(ctx)
  if ImGui.Button(ctx, "Shuffle") then
    for i = #model.order, 2, -1 do
      local j = math.random(i)
      model.order[i], model.order[j] = model.order[j], model.order[i]
    end
  end

  ImGui.SameLine(ctx)
  if ImGui.Button(ctx, "Reset Colors") then
    seed_colors()
  end

  if ImGui.TreeNode(ctx, "Selection style") then
    local a = model.ants
    ImGui.Text(ctx, "Thickness"); ImGui.SameLine(ctx)
    changed, v = ImGui.SliderInt(ctx, "##th", a.thickness, 1, 4);  if changed then a.thickness=v end
    ImGui.SameLine(ctx); ImGui.Text(ctx, "Radius"); ImGui.SameLine(ctx)
    changed, v = ImGui.SliderInt(ctx, "##rad", a.radius, 0, 16);    if changed then a.radius=v end
    ImGui.SameLine(ctx); ImGui.Text(ctx, "Dash"); ImGui.SameLine(ctx)
    changed, v = ImGui.SliderInt(ctx, "##dash", a.dash, 4, 20);     if changed then a.dash=v end
    ImGui.SameLine(ctx); ImGui.Text(ctx, "Gap"); ImGui.SameLine(ctx)
    changed, v = ImGui.SliderInt(ctx, "##gap2", a.gap, 2, 20);      if changed then a.gap=v end
    ImGui.SameLine(ctx); ImGui.Text(ctx, "Speed"); ImGui.SameLine(ctx)
    changed, v = ImGui.SliderInt(ctx, "##spd", a.speed, 6, 60);     if changed then a.speed=v end
    ImGui.TreePop(ctx)
  end

  ImGui.SameLine(ctx)
  local sel = model.selection or {}
  ImGui.TextDisabled(ctx, string.format("Selected: %d", #sel))
end

-- Main draw — update grid config each frame (keeps sliders live)
local function draw(ctx)
  -- If your widget exposes setters, prefer them; else assign fields.
  if grid.set_gap then grid:set_gap(model.gap) else grid.gap = model.gap end
  if grid.set_min_col_w then grid:set_min_col_w(model.tile_min_w) else grid.min_col_w = model.tile_min_w end

  draw_toolbar(ctx)
  ImGui.Separator(ctx)
  grid:draw(ctx)
end

-- Optional settings
local settings = nil
if Settings and type(Settings.new)=="function" then
  local ok,inst = pcall(Settings.new, join(HERE,"cache"), "demo_colorblocks.json")
  if ok then settings = inst end
end

-- Run via Shell (Window + Style)
Shell.run({
  title        = "ReArkitekt — ColorBlocks Demo",
  draw         = draw,
  settings     = settings,
  style        = okStyle and Style or nil,
  initial_pos  = { x = 120, y = 120 },
  initial_size = { w = 980, h = 620 },
  min_size     = { w = 600, h = 360 },
})