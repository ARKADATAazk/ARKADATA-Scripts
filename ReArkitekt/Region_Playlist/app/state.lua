-- Region_Playlist/app/state.lua
-- Application state management

local CoordinatorBridge = require("ReArkitekt.features.region_playlist.coordinator_bridge")
local RegionState = require("ReArkitekt.features.region_playlist.state")
local UndoManager = require("ReArkitekt.core.undo_manager")
local UndoBridge = require("ReArkitekt.features.region_playlist.undo_bridge")
local Colors = require("ReArkitekt.core.colors")

local M = {}

M.state = {
  active_playlist = nil,
  search_filter = "",
  sort_mode = nil,
  sort_direction = "asc",
  layout_mode = 'horizontal',
  region_index = {},
  pool_order = {},
  pending_spawn = {},
  pending_select = {},
  pending_destroy = {},
  bridge = nil,
  last_project_state = -1,
  undo_manager = nil,
  last_snapshot = nil,
}

M.playlists = {}

function M.initialize(settings)
  if settings then
    M.state.search_filter = settings:get('pool_search') or ""
    M.state.sort_mode = settings:get('pool_sort')
    M.state.sort_direction = settings:get('pool_sort_direction') or "asc"
    M.state.layout_mode = settings:get('layout_mode') or 'horizontal'
  end
  
  M.load_project_state()
  
  M.state.bridge = CoordinatorBridge.create({
    proj = 0,
    on_region_change = function(rid, region, pointer)
    end,
    on_playback_start = function(rid)
    end,
    on_playback_stop = function()
    end,
    on_transition_scheduled = function(rid, region_end, transition_time)
    end,
  })
  
  M.state.undo_manager = UndoManager.new({ proj = 0, max_history = 50 })
  
  M.refresh_regions()
  M.sync_playlist_to_engine()
  M.capture_undo_snapshot()
end

function M.load_project_state()
  M.playlists = RegionState.load_playlists(0)
  
  if #M.playlists == 0 then
    M.playlists = {
      {
        id = "Main",
        name = "Main",
        items = {},
      }
    }
    RegionState.save_playlists(M.playlists, 0)
  end
  
  local saved_active = RegionState.load_active_playlist(0)
  M.state.active_playlist = saved_active or M.playlists[1].id
end

function M.get_active_playlist()
  for _, pl in ipairs(M.playlists) do
    if pl.id == M.state.active_playlist then
      return pl
    end
  end
  return M.playlists[1]
end

function M.refresh_regions()
  local regions = M.state.bridge:get_regions_for_ui()
  
  M.state.region_index = {}
  M.state.pool_order = {}
  
  for _, region in ipairs(regions) do
    M.state.region_index[region.rid] = region
    M.state.pool_order[#M.state.pool_order + 1] = region.rid
  end
end

function M.sync_playlist_to_engine()
  local pl = M.get_active_playlist()
  M.state.bridge:sync_from_ui_playlist(pl.items)
end

function M.capture_undo_snapshot()
  local snapshot = UndoBridge.capture_snapshot(M.playlists, M.state.active_playlist)
  M.state.undo_manager:capture_state(snapshot)
  M.state.last_snapshot = snapshot
end

function M.apply_undo_snapshot(snapshot)
  if not snapshot then return false end
  
  local restored_playlists, restored_active = UndoBridge.restore_snapshot(
    snapshot, 
    M.state.region_index
  )
  
  M.playlists = restored_playlists
  M.state.active_playlist = restored_active
  
  RegionState.save_playlists(M.playlists, 0)
  RegionState.save_active_playlist(M.state.active_playlist, 0)
  
  M.sync_playlist_to_engine()
  
  return true
end

local function rgb_to_hsl(color)
  local r, g, b, a = Colors.rgba_to_components(color)
  r, g, b = r / 255, g / 255, b / 255
  
  local max_c = math.max(r, g, b)
  local min_c = math.min(r, g, b)
  local delta = max_c - min_c
  
  local h = 0
  local s = 0
  local l = (max_c + min_c) / 2
  
  if delta ~= 0 then
    s = (l > 0.5) and (delta / (2 - max_c - min_c)) or (delta / (max_c + min_c))
    
    if max_c == r then
      h = ((g - b) / delta + (g < b and 6 or 0)) / 6
    elseif max_c == g then
      h = ((b - r) / delta + 2) / 6
    else
      h = ((r - g) / delta + 4) / 6
    end
  end
  
  return h, s, l
end

local function get_color_sort_key(color)
  if not color or color == 0 then
    return -1, 0, 0
  end
  
  local h, s, l = rgb_to_hsl(color)
  
  if s < 0.08 then
    return 999, l, s
  end
  
  local hue_degrees = h * 360
  
  return hue_degrees, s, l
end

local function compare_by_color(a, b)
  local color_a = a.color or 0
  local color_b = b.color or 0
  
  local h_a, s_a, l_a = get_color_sort_key(color_a)
  local h_b, s_b, l_b = get_color_sort_key(color_b)
  
  if math.abs(h_a - h_b) > 0.01 then
    return h_a < h_b
  end
  
  if math.abs(s_a - s_b) > 0.01 then
    return s_a > s_b
  end
  
  return l_a > l_b
end

local function compare_by_index(a, b)
  return a.rid < b.rid
end

local function compare_by_alpha(a, b)
  local name_a = (a.name or ""):lower()
  local name_b = (b.name or ""):lower()
  return name_a < name_b
end

local function compare_by_length(a, b)
  local len_a = (a["end"] or 0) - (a.start or 0)
  local len_b = (b["end"] or 0) - (b.start or 0)
  return len_a < len_b
end

function M.get_filtered_pool_regions()
  local result = {}
  local search = M.state.search_filter:lower()
  
  for _, rid in ipairs(M.state.pool_order) do
    local region = M.state.region_index[rid]
    if region and (search == "" or region.name:lower():find(search, 1, true)) then
      result[#result + 1] = region
    end
  end
  
  local sort_mode = M.state.sort_mode
  local sort_dir = M.state.sort_direction or "asc"
  
  if sort_mode == "color" then
    table.sort(result, compare_by_color)
  elseif sort_mode == "index" then
    table.sort(result, compare_by_index)
  elseif sort_mode == "alpha" then
    table.sort(result, compare_by_alpha)
  elseif sort_mode == "length" then
    table.sort(result, compare_by_length)
  end
  
  if sort_dir == "desc" then
    local reversed = {}
    for i = #result, 1, -1 do
      reversed[#reversed + 1] = result[i]
    end
    result = reversed
  end
  
  return result
end

function M.cleanup_deleted_regions()
  local removed_any = false
  
  for _, pl in ipairs(M.playlists) do
    local i = 1
    while i <= #pl.items do
      local item = pl.items[i]
      if not M.state.region_index[item.rid] then
        table.remove(pl.items, i)
        removed_any = true
        M.state.pending_destroy[item.key] = true
      else
        i = i + 1
      end
    end
  end
  
  if removed_any then
    RegionState.save_playlists(M.playlists, 0)
  end
  
  return removed_any
end

function M.check_for_project_changes()
  local current_project_state = reaper.GetProjectStateChangeCount(0)
  if current_project_state ~= M.state.last_project_state then
    local old_region_count = 0
    for _ in pairs(M.state.region_index) do
      old_region_count = old_region_count + 1
    end
    
    M.refresh_regions()
    
    local new_region_count = 0
    for _ in pairs(M.state.region_index) do
      new_region_count = new_region_count + 1
    end
    
    local regions_deleted = new_region_count < old_region_count
    
    if regions_deleted then
      M.cleanup_deleted_regions()
      M.capture_undo_snapshot()
    end
    
    local undo_triggered, redo_triggered = M.state.undo_manager:detect_reaper_undo_redo()
    
    if undo_triggered then
      local prev_state = M.state.undo_manager:get_previous_state()
      M.apply_undo_snapshot(prev_state)
    elseif redo_triggered then
      local next_state = M.state.undo_manager:get_next_state()
      M.apply_undo_snapshot(next_state)
    else
      if M.state.last_snapshot and 
         UndoBridge.should_capture(M.state.last_snapshot.playlists, M.playlists) then
        M.capture_undo_snapshot()
      end
      M.sync_playlist_to_engine()
    end
    
    M.state.last_project_state = current_project_state
  end
end


return M