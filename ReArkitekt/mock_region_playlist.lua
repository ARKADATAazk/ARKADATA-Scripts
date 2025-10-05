-- ReArkitekt/mock_region_playlist.lua
-- Region Playlist Demo - Horizontal/Vertical layout toggle

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.10'

local function dirname(p) return p:match("^(.*)[/\\]") end
local function join(a,b) local s=package.config:sub(1,1); return (a:sub(-1)==s) and (a..b) or (a..s..b) end
local function addpath(p) if p and p~="" and not package.path:find(p,1,true) then package.path = p .. ";" .. package.path end end

local SRC   = debug.getinfo(1,"S").source:sub(2)
local HERE  = dirname(SRC) or "."
local PARENT= dirname(HERE or ".") or "."
addpath(join(PARENT,"?.lua")); addpath(join(PARENT,"?/init.lua"))
addpath(join(HERE,  "?.lua")); addpath(join(HERE,  "?/init.lua"))
addpath(join(HERE,  "ReArkitekt/?.lua"))
addpath(join(HERE,  "ReArkitekt/?/init.lua"))
addpath(join(HERE,  "ReArkitekt/?/?.lua"))

local Shell          = require("ReArkitekt.app.shell")
local StatusBar      = require("ReArkitekt.gui.widgets.status_bar")
local RegionTiles    = require("ReArkitekt.gui.widgets.region_tiles.coordinator")
local Draw           = require("ReArkitekt.gui.draw")
local Colors         = require("ReArkitekt.core.colors")

local SettingsOK, Settings = pcall(require, "ReArkitekt.core.settings")
local StyleOK,    Style    = pcall(require, "ReArkitekt.gui.style")

local settings = nil
if SettingsOK and type(Settings.new)=="function" then
  local ok, inst = pcall(Settings.new, join(HERE,"cache"), "region_playlist.json")
  if ok then settings = inst end
end

local mock_regions = {
  { rid=1,  name="Intro", start=0.0, ["end"]=4.5, color=0x4A90E2FF },
  { rid=2,  name="Verse 1", start=4.5, ["end"]=20.0, color=0xE24A4AFF },
  { rid=3,  name="Chorus 1", start=20.0, ["end"]=35.0, color=0x4AE2A3FF },
  { rid=4,  name="Verse 2", start=35.0, ["end"]=50.0, color=0xE24A4AFF },
  { rid=5,  name="Chorus 2", start=50.0, ["end"]=65.0, color=0x4AE2A3FF },
  { rid=6,  name="Bridge", start=65.0, ["end"]=80.0, color=0xE2A34AFF },
  { rid=7,  name="Solo", start=80.0, ["end"]=95.0, color=0xA34AE2FF },
  { rid=8,  name="Chorus 3", start=95.0, ["end"]=110.0, color=0x4AE2A3FF },
  { rid=9,  name="Outro", start=110.0, ["end"]=125.0, color=0x4A90E2FF },
  { rid=10, name="Pre-Chorus", start=17.0, ["end"]=20.0, color=0xE2E24AFF },
  { rid=11, name="Breakdown", start=75.0, ["end"]=80.0, color=0x90E24AFF },
  { rid=12, name="Drop", start=50.0, ["end"]=52.0, color=0xE24A90FF },
}

local playlists = {
  {
    id = "Main",
    name = "Main",
    items = {
      { rid=1, reps=1, key="item_1", enabled=true },
      { rid=2, reps=1, key="item_2", enabled=true },
      { rid=3, reps=2, key="item_3", enabled=true },
      { rid=4, reps=1, key="item_4", enabled=true },
      { rid=5, reps=1, key="item_5", enabled=true },
    },
  },
  {
    id = "Alt Mix",
    name = "Alt Mix",
    items = {
      { rid=1, reps=1, key="item_alt_1", enabled=true },
      { rid=6, reps=1, key="item_alt_2", enabled=true },
      { rid=7, reps=4, key="item_alt_3", enabled=true },
      { rid=9, reps=1, key="item_alt_4", enabled=true },
    },
  },
  {
    id = "Extended",
    name = "Extended",
    items = {},
  },
}

local app_state = {
  active_playlist = settings and settings:get('active_playlist') or "Main",
  search_filter = settings and settings:get('pool_search') or "",
  layout_mode = settings and settings:get('layout_mode') or 'horizontal',
  region_index = {},
  pool_order = {},
  pending_spawn = {},
  pending_select = {},
  pending_destroy = {},
}

for _, region in ipairs(mock_regions) do
  app_state.region_index[region.rid] = region
  app_state.pool_order[#app_state.pool_order + 1] = region.rid
end

local function get_active_playlist()
  for _, pl in ipairs(playlists) do
    if pl.id == app_state.active_playlist then
      return pl
    end
  end
  return playlists[1]
end

local function get_filtered_pool_regions()
  local result = {}
  local search = app_state.search_filter:lower()
  
  for _, rid in ipairs(app_state.pool_order) do
    local region = app_state.region_index[rid]
    if region and (search == "" or region.name:lower():find(search, 1, true)) then
      result[#result + 1] = region
    end
  end
  
  return result
end

local region_tiles = RegionTiles.create({
  get_region_by_rid = function(rid)
    return app_state.region_index[rid]
  end,
  
  allow_pool_reorder = true,
  
  config = {
    layout_mode = app_state.layout_mode,
  },
  
  on_playlist_changed = function(new_id)
    app_state.active_playlist = new_id
    if settings then settings:set('active_playlist', new_id) end
  end,
  
  on_active_reorder = function(new_order)
    local pl = get_active_playlist()
    pl.items = new_order
    if settings then settings:set('playlists', playlists) end
  end,
  
  on_active_remove = function(item_key)
    local pl = get_active_playlist()
    local new_items = {}
    for _, item in ipairs(pl.items) do
      if item.key ~= item_key then
        new_items[#new_items + 1] = item
      end
    end
    pl.items = new_items
    if settings then settings:set('playlists', playlists) end
  end,
  
  on_active_toggle_enabled = function(item_key, new_state)
    local pl = get_active_playlist()
    for _, item in ipairs(pl.items) do
      if item.key == item_key then
        item.enabled = new_state
        if settings then settings:set('playlists', playlists) end
        return
      end
    end
  end,
  
  on_active_delete = function(item_keys)
    local pl = get_active_playlist()
    local keys_to_delete = {}
    for _, key in ipairs(item_keys) do
      keys_to_delete[key] = true
    end
    
    local new_items = {}
    for _, item in ipairs(pl.items) do
      if not keys_to_delete[item.key] then
        new_items[#new_items + 1] = item
      end
    end
    pl.items = new_items
    
    if settings then settings:set('playlists', playlists) end
    
    for _, key in ipairs(item_keys) do
      app_state.pending_destroy[#app_state.pending_destroy + 1] = key
    end
  end,
  
  on_destroy_complete = function(key)
  end,
  
  on_active_copy = function(dragged_items, target_index)
    local pl = get_active_playlist()
    
    local dragged_keys = {}
    for _, item in ipairs(dragged_items) do
      dragged_keys[item.key] = true
    end
    
    local filtered_items = {}
    for _, item in ipairs(pl.items) do
      if not dragged_keys[item.key] then
        filtered_items[#filtered_items + 1] = item
      end
    end
    
    local actual_insert_idx
    
    if target_index <= 1 then
      actual_insert_idx = 1
    elseif target_index > #filtered_items then
      actual_insert_idx = #pl.items + 1
    else
      local ref_item = filtered_items[target_index - 1]
      for i, item in ipairs(pl.items) do
        if item.key == ref_item.key then
          actual_insert_idx = i + 1
          break
        end
      end
    end
    
    local new_keys = {}
    for i, item in ipairs(dragged_items) do
      local new_item = {
        rid = item.rid,
        reps = item.reps or 1,
        enabled = item.enabled ~= false,
        key = "item_" .. item.rid .. "_" .. reaper.time_precise() .. "_" .. i
      }
      table.insert(pl.items, actual_insert_idx + i - 1, new_item)
      new_keys[#new_keys + 1] = new_item.key
    end
    
    if settings then settings:set('playlists', playlists) end
    
    for _, key in ipairs(new_keys) do
      app_state.pending_spawn[#app_state.pending_spawn + 1] = key
      app_state.pending_select[#app_state.pending_select + 1] = key
    end
  end,
  
  on_pool_to_active = function(rid, insert_index)
    local pl = get_active_playlist()
    local new_item = {
      rid = rid,
      reps = 1,
      enabled = true,
      key = "item_" .. rid .. "_" .. reaper.time_precise()
    }
    table.insert(pl.items, insert_index or (#pl.items + 1), new_item)
    if settings then settings:set('playlists', playlists) end
    return new_item.key
  end,
  
  on_pool_reorder = function(new_rids)
    app_state.pool_order = new_rids
    if settings then settings:set('pool_order', app_state.pool_order) end
  end,
  
  on_repeat_cycle = function(item_key)
    local pl = get_active_playlist()
    for _, item in ipairs(pl.items) do
      if item.key == item_key then
        local reps = item.reps or 1
        if reps == 1 then item.reps = 2
        elseif reps == 2 then item.reps = 4
        elseif reps == 4 then item.reps = 8
        else item.reps = 1 end
        if settings then settings:set('playlists', playlists) end
        return
      end
    end
  end,
  
  on_repeat_adjust = function(keys, delta)
    local pl = get_active_playlist()
    for _, key in ipairs(keys) do
      for _, item in ipairs(pl.items) do
        if item.key == key then
          local current_reps = item.reps or 1
          local new_reps = math.max(0, current_reps + delta)
          item.reps = new_reps
          break
        end
      end
    end
    if settings then settings:set('playlists', playlists) end
  end,
  
  on_repeat_sync = function(keys, target_reps)
    local pl = get_active_playlist()
    for _, key in ipairs(keys) do
      for _, item in ipairs(pl.items) do
        if item.key == key then
          item.reps = target_reps
          break
        end
      end
    end
    if settings then settings:set('playlists', playlists) end
  end,
  
  on_pool_double_click = function(rid)
    local pl = get_active_playlist()
    local new_item = {
      rid = rid,
      reps = 1,
      enabled = true,
      key = "item_" .. rid .. "_" .. reaper.time_precise()
    }
    pl.items[#pl.items + 1] = new_item
    if settings then settings:set('playlists', playlists) end
    
    app_state.pending_spawn[#app_state.pending_spawn + 1] = new_item.key
    app_state.pending_select[#app_state.pending_select + 1] = new_item.key
  end,
  
  settings = settings,
})

local app_status = "ready"

local function get_app_status()
  local mode_text = app_state.layout_mode == 'horizontal' and "Timeline Mode" or "List Mode"
  local status_configs = {
    ready = {
      color = 0x41E0A3FF,
      text = "READY  •  " .. mode_text .. "  •  Drag pool items to active (purple)  •  CTRL+Drag to copy (purple)  •  Drag outside to remove (red)",
      buttons = nil,
      right_buttons = nil,
    },
  }
  return status_configs[app_status] or status_configs.ready
end

local status_bar = StatusBar.new({
  height = 34,
  get_status = get_app_status,
  style = StyleOK and Style and { palette = Style.palette } or nil
})

local LAYOUT_BUTTON_CONFIG = {
  width = 32,
  height = 32,
  bg_color = 0x2A2A2AFF,
  bg_hover = 0x3A3A3AFF,
  bg_active = 0x4A4A4AFF,
  border_color = 0x404040FF,
  border_hover = 0x606060FF,
  icon_color = 0xAAAAAAFF,
  icon_hover = 0xFFFFFFFF,
  rounding = 4,
  animation_speed = 12.0,
}

local layout_button_animator = require('ReArkitekt.gui.fx.tile_motion').new(LAYOUT_BUTTON_CONFIG.animation_speed)

local function draw_layout_toggle_button(ctx)
  local dl = ImGui.GetWindowDrawList(ctx)
  local cursor_x, cursor_y = ImGui.GetCursorScreenPos(ctx)
  
  local btn_w = LAYOUT_BUTTON_CONFIG.width
  local btn_h = LAYOUT_BUTTON_CONFIG.height
  
  local mx, my = ImGui.GetMousePos(ctx)
  local is_hovered = mx >= cursor_x and mx < cursor_x + btn_w and my >= cursor_y and my < cursor_y + btn_h
  
  layout_button_animator:track('btn', 'hover', is_hovered and 1.0 or 0.0, LAYOUT_BUTTON_CONFIG.animation_speed)
  local hover_factor = layout_button_animator:get('btn', 'hover')
  
  local bg_base = LAYOUT_BUTTON_CONFIG.bg_color
  local bg_target = LAYOUT_BUTTON_CONFIG.bg_hover
  local bg_color = Colors.lerp(bg_base, bg_target, hover_factor)
  
  local border_base = LAYOUT_BUTTON_CONFIG.border_color
  local border_target = LAYOUT_BUTTON_CONFIG.border_hover
  local border_color = Colors.lerp(border_base, border_target, hover_factor)
  
  local icon_base = LAYOUT_BUTTON_CONFIG.icon_color
  local icon_target = LAYOUT_BUTTON_CONFIG.icon_hover
  local icon_color = Colors.lerp(icon_base, icon_target, hover_factor)
  
  ImGui.DrawList_AddRectFilled(dl, cursor_x, cursor_y, cursor_x + btn_w, cursor_y + btn_h, 
                                bg_color, LAYOUT_BUTTON_CONFIG.rounding)
  ImGui.DrawList_AddRect(dl, cursor_x + 0.5, cursor_y + 0.5, cursor_x + btn_w - 0.5, cursor_y + btn_h - 0.5, 
                        border_color, LAYOUT_BUTTON_CONFIG.rounding, 0, 1)
  
  local padding = 6
  local icon_x = cursor_x + padding
  local icon_y = cursor_y + padding
  local icon_w = btn_w - padding * 2
  local icon_h = btn_h - padding * 2
  
  if app_state.layout_mode == 'horizontal' then
    local bar_h = 3
    local gap = 2
    local bar_w = icon_w
    
    for i = 0, 2 do
      local bar_y = icon_y + i * (bar_h + gap)
      ImGui.DrawList_AddRectFilled(dl, icon_x, bar_y, icon_x + bar_w, bar_y + bar_h, 
                                    icon_color, 1)
    end
  else
    local bar_w = 3
    local gap = 2
    local bar_h = icon_h
    
    for i = 0, 2 do
      local bar_x = icon_x + i * (bar_w + gap)
      ImGui.DrawList_AddRectFilled(dl, bar_x, icon_y, bar_x + bar_w, icon_y + bar_h, 
                                    icon_color, 1)
    end
  end
  
  ImGui.SetCursorScreenPos(ctx, cursor_x, cursor_y)
  ImGui.InvisibleButton(ctx, "##layout_toggle", btn_w, btn_h)
  
  if ImGui.IsItemClicked(ctx, 0) then
    app_state.layout_mode = (app_state.layout_mode == 'horizontal') and 'vertical' or 'horizontal'
    region_tiles:set_layout_mode(app_state.layout_mode)
    if settings then settings:set('layout_mode', app_state.layout_mode) end
  end
  
  if ImGui.IsItemHovered(ctx) then
    local tooltip = app_state.layout_mode == 'horizontal' and "Switch to List Mode" or "Switch to Timeline Mode"
    ImGui.SetTooltip(ctx, tooltip)
  end
  
  ImGui.SameLine(ctx, 0, 12)
end

local function draw(ctx, state)
  if #app_state.pending_spawn > 0 then
    region_tiles.active_grid:mark_spawned(app_state.pending_spawn)
    app_state.pending_spawn = {}
  end
  
  if #app_state.pending_select > 0 then
    region_tiles.pool_grid.selection:clear()
    region_tiles.active_grid.selection:clear()
    
    for _, key in ipairs(app_state.pending_select) do
      region_tiles.active_grid.selection.selected[key] = true
    end
    region_tiles.active_grid.selection.last_clicked = app_state.pending_select[#app_state.pending_select]
    
    if region_tiles.active_grid.on_select then
      region_tiles.active_grid.on_select(region_tiles.active_grid.selection:selected_keys())
    end
    
    app_state.pending_select = {}
  end
  
  if #app_state.pending_destroy > 0 then
    region_tiles.active_grid:mark_destroyed(app_state.pending_destroy)
    app_state.pending_destroy = {}
  end
  
  region_tiles:update_animations(0.016)
  layout_button_animator:update(0.016)
  
  local avail_w, avail_h = ImGui.GetContentRegionAvail(ctx)
  local status_bar_height = status_bar and status_bar.height or 0
  local content_h = math.floor(avail_h - status_bar_height + 0.5)
  
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding, 12, 12)
  
  local child_flags = ImGui.ChildFlags_AlwaysUseWindowPadding
  local window_flags = ImGui.WindowFlags_NoScrollbar
  ImGui.BeginChild(ctx, "##content", 0, content_h, child_flags, window_flags)
  
  local selector_height = 44
  
  draw_layout_toggle_button(ctx)
  ImGui.Text(ctx, "PLAYLISTS")
  ImGui.Dummy(ctx, 1, 2)
  region_tiles:draw_selector(ctx, playlists, app_state.active_playlist, selector_height)
  
  ImGui.Dummy(ctx, 1, 16)
  
  local pl = get_active_playlist()
  local filtered_regions = get_filtered_pool_regions()
  
  if app_state.layout_mode == 'horizontal' then
    local active_height = 180
    local pool_height = 280
    
    ImGui.Text(ctx, "ACTIVE SEQUENCE")
    ImGui.Dummy(ctx, 1, 4)
    region_tiles:draw_active(ctx, pl, active_height)
    
    ImGui.Dummy(ctx, 1, 16)
    
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 6, 3)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameRounding, 4)
    ImGui.SetNextItemWidth(ctx, 200)
    local ch_s, new_q = ImGui.InputText(ctx, 'Search', app_state.search_filter or '')
    if ch_s then 
      app_state.search_filter = new_q
      if settings then settings:set('pool_search', app_state.search_filter) end
    end
    ImGui.PopStyleVar(ctx, 2)
    
    ImGui.SameLine(ctx)
    ImGui.Text(ctx, "REGION POOL")
    
    ImGui.Dummy(ctx, 1, 4)
    region_tiles:draw_pool(ctx, filtered_regions, pool_height)
  else
    local content_w, content_h = ImGui.GetContentRegionAvail(ctx)
    
    local active_width = 280
    local gap = 16
    local pool_width = content_w - active_width - gap
    
    local start_cursor_x, start_cursor_y = ImGui.GetCursorScreenPos(ctx)
    
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing, 0, 0)
    
    if ImGui.BeginChild(ctx, "##left_column", active_width, content_h, ImGui.ChildFlags_None, 0) then
      ImGui.Text(ctx, "ACTIVE SEQUENCE")
      ImGui.Dummy(ctx, 1, 4)
      local label_consumed = ImGui.GetCursorPosY(ctx)
      region_tiles:draw_active(ctx, pl, content_h - label_consumed)
    end
    ImGui.EndChild(ctx)
    
    ImGui.PopStyleVar(ctx)
    
    ImGui.SetCursorScreenPos(ctx, start_cursor_x + active_width + gap, start_cursor_y)
    
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing, 0, 0)
    
    if ImGui.BeginChild(ctx, "##right_column", pool_width, content_h, ImGui.ChildFlags_None, 0) then
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 6, 3)
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameRounding, 4)
      ImGui.SetNextItemWidth(ctx, 200)
      local ch_s, new_q = ImGui.InputText(ctx, 'Search', app_state.search_filter or '')
      if ch_s then 
        app_state.search_filter = new_q
        if settings then settings:set('pool_search', app_state.search_filter) end
      end
      ImGui.PopStyleVar(ctx, 2)
      
      ImGui.SameLine(ctx)
      ImGui.Text(ctx, "REGION POOL")
      
      ImGui.Dummy(ctx, 1, 4)
      local label_consumed = ImGui.GetCursorPosY(ctx)
      region_tiles:draw_pool(ctx, filtered_regions, content_h - label_consumed)
    end
    ImGui.EndChild(ctx)
    
    ImGui.PopStyleVar(ctx)
  end
  
  ImGui.EndChild(ctx)
  ImGui.PopStyleVar(ctx)
  
  region_tiles:draw_ghosts(ctx)
end

Shell.run({
  title        = "ReArkitekt - Region Playlist",
  draw         = draw,
  settings     = settings,
  style        = StyleOK and Style or nil,
  initial_pos  = { x = 120, y = 120 },
  initial_size = { w = 1000, h = 700 },
  min_size     = { w = 700, h = 500 },
  status_bar   = status_bar,
  content_padding = 12,
})