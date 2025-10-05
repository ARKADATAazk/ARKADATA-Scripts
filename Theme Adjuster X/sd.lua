-- Theme_Adjuster_X.lua
-- Full version using ReArkitekt library

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

-- Setup paths
local SEP = package.config:sub(1,1)
local script_path = debug.getinfo(1, 'S').source:sub(2)
local script_dir = script_path:match("(.*"..SEP..")") or ("."..SEP)
local parent_dir = script_dir:gsub("[^\\/]+[\\/]$", "")

-- Add ReArkitekt paths
package.path = parent_dir .. "ReArkitekt" .. SEP .. "?.lua;" .. package.path
package.path = parent_dir .. "ReArkitekt" .. SEP .. "core" .. SEP .. "?.lua;" .. package.path
package.path = parent_dir .. "ReArkitekt" .. SEP .. "gui" .. SEP .. "?.lua;" .. package.path
package.path = parent_dir .. "ReArkitekt" .. SEP .. "gui" .. SEP .. "systems" .. SEP .. "?.lua;" .. package.path
package.path = parent_dir .. "ReArkitekt" .. SEP .. "gui" .. SEP .. "widgets" .. SEP .. "?.lua;" .. package.path
package.path = parent_dir .. "ReArkitekt" .. SEP .. "app" .. SEP .. "?.lua;" .. package.path

-- Add Theme Adjuster X paths
package.path = script_dir .. "?.lua;" .. package.path
package.path = script_dir .. "core" .. SEP .. "?.lua;" .. package.path
package.path = script_dir .. "tabs" .. SEP .. "?.lua;" .. package.path

-- Load ReArkitekt modules
local Settings = require('settings')
local Lifecycle = require('lifecycle')
local Style = require('style')
local Draw = require('draw')
local Effects = require('effects')
local ColorBlocks = require('colorblocks')
local Motion = require('motion')

-- Load Theme Adjuster modules (create these in Theme Adjuster X/core/)
local Theme = require('theme')  -- You already have this from original

-- Initialize settings
local cache_dir = script_dir .. "cache"
local settings = Settings.open(cache_dir, "settings.json")

-- Create ImGui context
local ctx = ImGui.CreateContext('Theme Adjuster X')

-- Load fonts
local function load_fonts(ctx)
  local fonts_dir = script_dir .. "fonts" .. SEP
  local function try_font(file, size)
    local path = fonts_dir .. file
    local f = io.open(path, "rb")
    if f then
      f:close()
      return ImGui.CreateFont(path, size, 0)
    end
    return ImGui.CreateFont('sans-serif', size, 0)
  end
  
  local fonts = {
    default = { face = try_font("Roboto-Regular.ttf", 12), size = 12 },
    tabs = { face = try_font("Roboto-Medium.ttf", 13), size = 13 },
    title = { face = try_font("Roboto-Bold.ttf", 15), size = 15 },
  }
  
  for _, font in pairs(fonts) do
    ImGui.Attach(ctx, font.face)
  end
  
  return fonts
end

local fonts = load_fonts(ctx)

-- Create status bar using YOUR existing status_bar.lua
local StatusBar = require('status_bar')  -- Use your 214-line version
local status_bar = StatusBar.create(Theme, {
  height = 26,
  pad = 6,
})
status_bar.set_fonts(status_bar, fonts)

-- Window management
local ui_settings = settings:sub("ui")
local window = {
  open = true,
  first_frame = true,
  pos = ui_settings:get("window.pos", {x = 100, y = 100}),
  size = ui_settings:get("window.size", {w = 980, h = 580}),
}

-- Tab state
local active_tab = ui_settings:get("active_tab", 1)
local tab_instances = {}

-- Create packages grid using ColorBlocks
local packages_grid = nil

local function create_packages_tab()
  local L = Lifecycle.new()
  
  -- Mock package data for now
  local packages = {}
  for i = 1, 12 do
    packages[i] = {
      id = "package_" .. i,
      name = "Package " .. i,
      assets = {},
      active = i <= 6,
    }
  end
  
  -- Create grid
  local grid = L:register(ColorBlocks.new({
    id = "packages",
    gap = 12,
    min_col_w = function() return 220 end,
    get_items = function() return packages end,
    key = function(p) return p.id end,
    
    render_tile = function(ctx, rect, pkg, state)
      local dl = ImGui.GetWindowDrawList(ctx)
      local x1, y1, x2, y2 = rect[1], rect[2], rect[3], rect[4]
      
      -- Background
      local bg = pkg.active and 0x2D4A37FF or 0x1A1A1AFF
      if state.hover then bg = pkg.active and 0x3A5744FF or 0x2A2A2AFF end
      Draw.rect_filled(dl, x1, y1, x2, y2, bg, 6)
      
      -- Selection
      if state.selected then
        Effects.marching_ants_rounded(dl, x1, y1, x2, y2, 0x42E896FF, 1, 6, 8, 6, 20)
      else
        Draw.rect(dl, x1, y1, x2, y2, state.hover and 0xCCCCCCFF or 0x303030FF, 6, 1)
      end
      
      -- Name
      Draw.centered_text(ctx, pkg.name, x1, y1+10, x2, y1+30, 0xFFFFFFFF)
    end,
  }))
  
  packages_grid = grid
  
  return L:export(function(ctx)
    ImGui.Text(ctx, "Packages Grid (using ColorBlocks widget):")
    ImGui.Separator(ctx)
    
    if packages_grid then
      packages_grid:draw(ctx)
    end
  end)
end

-- Create tabs
local tabs = {
  { id = "Packages", instance = nil },
  { id = "Assembler", instance = nil },
  { id = "Debug", instance = nil },
}

-- Main frame
local function frame()
  if not window.open then
    settings:flush()
    return
  end
  
  -- Window setup
  if window.first_frame then
    ImGui.SetNextWindowPos(ctx, window.pos.x, window.pos.y)
    ImGui.SetNextWindowSize(ctx, window.size.w, window.size.h)
    if ImGui.SetNextWindowSizeConstraints then
      ImGui.SetNextWindowSizeConstraints(ctx, 560, 360, 9999, 9999)
    end
    window.first_frame = false
  end
  
  -- Apply ReArkitekt style
  Style.PushMyStyle(ctx)
  
  -- Window flags
  local flags = ImGui.WindowFlags_NoCollapse
  if ImGui.WindowFlags_NoScrollbar then
    flags = flags | ImGui.WindowFlags_NoScrollbar
  end
  
  -- Custom window padding for header
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding, 8, 0)
  ImGui.PushFont(ctx, fonts.title.face)
  
  local visible, open = ImGui.Begin(ctx, 'Theme Adjuster X', true, flags)
  
  ImGui.PopFont(ctx)
  ImGui.PopStyleVar(ctx)
  
  window.open = open
  
  if visible then
    -- Save geometry
    local wx, wy = ImGui.GetWindowPos(ctx)
    local ww, wh = ImGui.GetWindowSize(ctx)
    window.pos = {x = wx, y = wy}
    window.size = {w = ww, h = wh}
    ui_settings:set("window.pos", window.pos)
    ui_settings:set("window.size", window.size)
    
    -- Calculate layout
    local avail_h = select(2, ImGui.GetContentRegionAvail(ctx)) or 0
    local footer_h = status_bar.height + status_bar.pad
    local content_h = math.max(1, avail_h - footer_h)
    
    -- Main content
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding, 0, 0)
    
    if ImGui.BeginChild(ctx, "##main", -1, content_h, false, ImGui.WindowFlags_NoScrollbar) then
      -- Custom tab bar
      local tab_h = 36
      local dl = ImGui.GetWindowDrawList(ctx)
      local cx, cy = ImGui.GetCursorScreenPos(ctx)
      local tab_w = (select(1, ImGui.GetContentRegionAvail(ctx)) or 0) / #tabs
      
      ImGui.PushFont(ctx, fonts.tabs.face)
      
      -- Draw tabs
      for i, tab in ipairs(tabs) do
        local x1 = cx + (i-1) * tab_w
        local x2 = cx + i * tab_w
        local y1 = cy
        local y2 = cy + tab_h
        
        ImGui.SetCursorScreenPos(ctx, x1, y1)
        ImGui.InvisibleButton(ctx, "##tab"..i, x2-x1, tab_h)
        
        local hovered = ImGui.IsItemHovered(ctx)
        local clicked = ImGui.IsItemClicked(ctx)
        
        if clicked then
          active_tab = i
          ui_settings:set("active_tab", i)
        end
        
        -- Tab background
        local bg = (i == active_tab) and 0x242424FF or 0x1A1A1AFF
        Draw.rect_filled(dl, x1, y1, x2, y2, bg, 0)
        
        -- Tab border
        Draw.line(dl, x1, y1, x2, y1, 0x000000FF, 1)
        if i > 1 then Draw.line(dl, x1, y1, x1, y2, 0x000000FF, 1) end
        if i == #tabs then Draw.line(dl, x2, y1, x2, y2, 0x000000FF, 1) end
        if i ~= active_tab then Draw.line(dl, x1, y2, x2, y2, 0x000000FF, 1) end
        
        -- Tab text
        local text_color = (i == active_tab) and 0xFFFFFFFF or 0xBBBBBB6D
        Draw.centered_text(ctx, tab.id, x1, y1, x2, y2, text_color)
      end
      
      ImGui.PopFont(ctx)
      
      -- Tab content area
      ImGui.SetCursorScreenPos(ctx, cx, cy + tab_h)
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding, 8, 8)
      ImGui.PushStyleColor(ctx, ImGui.Col_ChildBg, 0x242424FF)
      
      if ImGui.BeginChild(ctx, "##tab_content", -1, -1, false, 0) then
        ImGui.PushFont(ctx, fonts.default.face)
        
        -- Draw active tab content
        if active_tab == 1 then
          -- Create packages tab on demand
          if not tabs[1].instance then
            tabs[1].instance = create_packages_tab()
          end
          if tabs[1].instance and tabs[1].instance.draw then
            tabs[1].instance.draw(ctx)
          end
        else
          ImGui.Text(ctx, "Tab: " .. tabs[active_tab].id)
          ImGui.BulletText(ctx, "Content coming soon...")
        end
        
        ImGui.PopFont(ctx)
        ImGui.EndChild(ctx)
      end
      
      ImGui.PopStyleColor(ctx)
      ImGui.PopStyleVar(ctx)
      
      ImGui.EndChild(ctx)
    end
    
    ImGui.PopStyleVar(ctx)
    
    -- Status bar
    status_bar:set_main_window_info(wx, wy, ww, wh)
    status_bar:draw_child(ctx, footer_h)
    
    ImGui.End(ctx)
  end
  
  Style.PopMyStyle(ctx)
  
  settings:maybe_flush()
  
  if window.open then
    reaper.defer(frame)
  end
end

-- Start
reaper.defer(frame)