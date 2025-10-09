-- Region_Playlist/app/state.lua
-- Pure data layer with repeat cycle tracking and nested playlist support

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
  pool_mode = 'regions',
  region_index = {},
  pool_order = {},
  pending_spawn = {},
  pending_select = {},
  pending_destroy = {},
  bridge = nil,
  last_project_state = -1,
  undo_manager = nil,
  on_state_restored = nil,
  on_repeat_cycle = nil,
}

M.playlists = {}
M.settings = nil

function M.initialize(settings)
  M.settings = settings
  
  if settings then
    M.state.search_filter = settings:get('pool_search') or ""
    M.state.sort_mode = settings:get('pool_sort')
    M.state.sort_direction = settings:get('pool_sort_direction') or "asc"
    M.state.layout_mode = settings:get('layout_mode') or 'horizontal'
    M.state.pool_mode = settings:get('pool_mode') or 'regions'
  end
  
  M.load_project_state()
  
  M.ensure_playlist_colors()
  
  M.state.bridge = CoordinatorBridge.create({
    proj = 0,
    on_region_change = function(rid, region, pointer) end,
    on_playback_start = function(rid) end,
    on_playback_stop = function() end,
    on_transition_scheduled = function(rid, region_end, transition_time) end,
    on_repeat_cycle = function(key, current_loop, total_reps)
      if M.state.on_repeat_cycle then
        M.state.on_repeat_cycle(key, current_loop, total_reps)
      end
    end,
  })
  
  M.state.undo_manager = UndoManager.new({ max_history = 50 })
  
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
        chip_color = RegionState.generate_chip_color(),
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

function M.get_playlist_by_id(playlist_id)
  for _, pl in ipairs(M.playlists) do
    if pl.id == playlist_id then
      return pl
    end
  end
  return nil
end

function M.get_tabs()
  local tabs = {}
  for _, pl in ipairs(M.playlists) do
    tabs[#tabs + 1] = {
      id = pl.id,
      label = pl.name or ("Playlist " .. pl.id),
    }
  end
  return tabs
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

function M.persist()
  RegionState.save_playlists(M.playlists, 0)
  RegionState.save_active_playlist(M.state.active_playlist, 0)
end

function M.persist_ui_prefs()
  if not M.settings then return end
  M.settings:set('pool_search', M.state.search_filter)
  M.settings:set('pool_sort', M.state.sort_mode)
  M.settings:set('pool_sort_direction', M.state.sort_direction)
  M.settings:set('layout_mode', M.state.layout_mode)
  M.settings:set('pool_mode', M.state.pool_mode)
end

function M.capture_undo_snapshot()
  local snapshot = UndoBridge.capture_snapshot(M.playlists, M.state.active_playlist)
  M.state.undo_manager:push(snapshot)
end

function M.clear_pending()
  M.state.pending_spawn = {}
  M.state.pending_select = {}
  M.state.pending_destroy = {}
end

function M.restore_snapshot(snapshot)
  if not snapshot then return false end
  
  local restored_playlists, restored_active = UndoBridge.restore_snapshot(
    snapshot, 
    M.state.region_index
  )
  
  M.playlists = restored_playlists
  M.state.active_playlist = restored_active
  
  M.persist()
  M.clear_pending()
  M.sync_playlist_to_engine()
  
  if M.state.on_state_restored then
    M.state.on_state_restored()
  end
  
  return true
end

function M.undo()
  if not M.state.undo_manager:can_undo() then
    return false
  end
  
  local snapshot = M.state.undo_manager:undo()
  return M.restore_snapshot(snapshot)
end

function M.redo()
  if not M.state.undo_manager:can_redo() then
    return false
  end
  
  local snapshot = M.state.undo_manager:redo()
  return M.restore_snapshot(snapshot)
end

function M.can_undo()
  return M.state.undo_manager:can_undo()
end

function M.can_redo()
  return M.state.undo_manager:can_redo()
end

function M.set_active_playlist(playlist_id)
  M.state.active_playlist = playlist_id
  M.persist()
  M.sync_playlist_to_engine()
end

local function compare_by_color(a, b)
  local color_a = a.color or 0
  local color_b = b.color or 0
  return Colors.compare_colors(color_a, color_b)
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

function M.get_playlists_for_pool()
  local pool_playlists = {}
  for _, pl in ipairs(M.playlists) do
    if pl.id ~= M.state.active_playlist then
      pool_playlists[#pool_playlists + 1] = {
        id = pl.id,
        name = pl.name,
        items = pl.items,
        chip_color = pl.chip_color or RegionState.generate_chip_color(),
      }
    end
  end
  return pool_playlists
end

function M.ensure_playlist_colors()
  local changed = false
  for _, pl in ipairs(M.playlists) do
    if not pl.chip_color then
      pl.chip_color = RegionState.generate_chip_color()
      changed = true
    end
  end
  if changed then
    M.persist()
  end
end

function M.detect_circular_reference(target_playlist_id, playlist_id_to_add)
  if target_playlist_id == playlist_id_to_add then
    return true, {target_playlist_id}
  end
  
  local visited = {}
  local path = {}
  
  local function dfs(current_id)
    if visited[current_id] then
      return false
    end
    
    visited[current_id] = true
    path[#path + 1] = current_id
    
    if current_id == target_playlist_id then
      return true, path
    end
    
    local pl = M.get_playlist_by_id(current_id)
    if not pl then
      table.remove(path)
      return false
    end
    
    for _, item in ipairs(pl.items) do
      if item.type == "playlist" and item.playlist_id then
        local circular, circular_path = dfs(item.playlist_id)
        if circular then
          return true, circular_path
        end
      end
    end
    
    table.remove(path)
    return false
  end
  
  local playlist_to_add = M.get_playlist_by_id(playlist_id_to_add)
  if not playlist_to_add then
    return false
  end
  
  for _, item in ipairs(playlist_to_add.items) do
    if item.type == "playlist" and item.playlist_id then
      local circular, circular_path = dfs(item.playlist_id)
      if circular then
        table.insert(circular_path, 1, playlist_id_to_add)
        return true, circular_path
      end
    end
  end
  
  return false
end

function M.create_playlist_item(playlist_id, reps)
  local playlist = M.get_playlist_by_id(playlist_id)
  if not playlist then
    return nil
  end
  
  return {
    type = "playlist",
    playlist_id = playlist_id,
    reps = reps or 1,
    enabled = true,
    key = "playlist_" .. playlist_id .. "_" .. reaper.time_precise(),
    chip_color = playlist.chip_color,
  }
end

function M.cleanup_deleted_regions()
  local removed_any = false
  
  for _, pl in ipairs(M.playlists) do
    local i = 1
    while i <= #pl.items do
      local item = pl.items[i]
      if item.type == "region" and not M.state.region_index[item.rid] then
        table.remove(pl.items, i)
        removed_any = true
        M.state.pending_destroy[item.key] = true
      else
        i = i + 1
      end
    end
  end
  
  if removed_any then
    M.persist()
  end
  
  return removed_any
end

function M.update()
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
    end
    
    M.sync_playlist_to_engine()
    M.state.last_project_state = current_project_state
  end
end

return M