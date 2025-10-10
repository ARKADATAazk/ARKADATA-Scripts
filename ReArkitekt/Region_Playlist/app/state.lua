-- Region_Playlist/app/state.lua
-- FIXED: Detects project switches and reloads playlist data

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
  last_project_filename = nil,
  undo_manager = nil,
  on_state_restored = nil,
  on_repeat_cycle = nil,
}

M.playlists = {}
M.settings = nil
M.dependency_graph = {}
M.graph_dirty = true

local function get_current_project_filename()
  local proj_path = reaper.GetProjectPath("")
  local proj_name = reaper.GetProjectName(0, "")
  if proj_path == "" or proj_name == "" then
    return nil
  end
  return proj_path .. "/" .. proj_name
end

function M.initialize(settings)
  M.settings = settings
  
  if settings then
    M.state.search_filter = settings:get('pool_search') or ""
    M.state.sort_mode = settings:get('pool_sort')
    M.state.sort_direction = settings:get('pool_sort_direction') or "asc"
    M.state.layout_mode = settings:get('layout_mode') or 'horizontal'
    M.state.pool_mode = settings:get('pool_mode') or 'regions'
  end
  
  M.state.last_project_filename = get_current_project_filename()
  
  M.load_project_state()
  M.rebuild_dependency_graph()
  
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
    get_playlist_by_id = M.get_playlist_by_id,
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

function M.reload_project_data()
  if M.state.bridge and M.state.bridge.engine and M.state.bridge.engine.is_playing then
    M.state.bridge:stop()
  end
  
  M.load_project_state()
  M.rebuild_dependency_graph()
  M.refresh_regions()
  M.sync_playlist_to_engine()
  
  M.state.undo_manager = UndoManager.new({ max_history = 50 })
  
  M.clear_pending()
  
  if M.state.on_state_restored then
    M.state.on_state_restored()
  end
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
      chip_color = pl.chip_color,
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
  M.mark_graph_dirty()
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
  
  if M.state.bridge and M.state.bridge.engine and M.state.bridge.engine.is_playing then
    M.state.bridge:stop()
  end
  
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
  
  -- ONLY sort if there's an active sort mode
  if sort_mode == "color" then
    table.sort(result, compare_by_color)
  elseif sort_mode == "index" then
    table.sort(result, compare_by_index)
  elseif sort_mode == "alpha" then
    table.sort(result, compare_by_alpha)
  elseif sort_mode == "length" then
    table.sort(result, compare_by_length)
  end
  
  -- CRITICAL FIX: Only reverse if we have an active sort mode AND direction is desc
  if sort_mode and sort_mode ~= "" and sort_dir == "desc" then
    local reversed = {}
    for i = #result, 1, -1 do
      reversed[#reversed + 1] = result[i]
    end
    result = reversed
  end
  
  return result
end


local function compare_playlists_by_alpha(a, b)
  local name_a = (a.name or ""):lower()
  local name_b = (b.name or ""):lower()
  return name_a < name_b
end

local function compare_playlists_by_item_count(a, b)
  local count_a = #a.items
  local count_b = #b.items
  return count_a < count_b
end

function M.mark_graph_dirty()
  M.graph_dirty = true
end

function M.rebuild_dependency_graph()
  M.dependency_graph = {}
  
  for _, pl in ipairs(M.playlists) do
    M.dependency_graph[pl.id] = {
      direct_deps = {},
      all_deps = {},
      is_disabled_for = {}
    }
    
    for _, item in ipairs(pl.items) do
      if item.type == "playlist" and item.playlist_id then
        M.dependency_graph[pl.id].direct_deps[#M.dependency_graph[pl.id].direct_deps + 1] = item.playlist_id
      end
    end
  end
  
  for _, pl in ipairs(M.playlists) do
    local all_deps = {}
    local visited = {}
    
    local function collect_deps(pid)
      if visited[pid] then return end
      visited[pid] = true
      
      local node = M.dependency_graph[pid]
      if not node then return end
      
      for _, dep_id in ipairs(node.direct_deps) do
        all_deps[dep_id] = true
        collect_deps(dep_id)
      end
    end
    
    collect_deps(pl.id)
    
    M.dependency_graph[pl.id].all_deps = all_deps
  end
  
  for target_id, target_node in pairs(M.dependency_graph) do
    for source_id, source_node in pairs(M.dependency_graph) do
      if target_id ~= source_id then
        if source_node.all_deps[target_id] or target_id == source_id then
          target_node.is_disabled_for[source_id] = true
        end
      end
    end
  end
  
  M.graph_dirty = false
end

function M.is_playlist_draggable_to(playlist_id, target_playlist_id)
  if M.graph_dirty then
    M.rebuild_dependency_graph()
  end
  
  if playlist_id == target_playlist_id then
    return false
  end
  
  local target_node = M.dependency_graph[target_playlist_id]
  if not target_node then
    return true
  end
  
  if target_node.is_disabled_for[playlist_id] then
    return false
  end
  
  local playlist_node = M.dependency_graph[playlist_id]
  if not playlist_node then
    return true
  end
  
  if playlist_node.all_deps[target_playlist_id] then
    return false
  end
  
  return true
end

function M.get_playlists_for_pool()
  if M.graph_dirty then
    M.rebuild_dependency_graph()
  end
  
  local pool_playlists = {}
  local active_id = M.state.active_playlist
  
  for _, pl in ipairs(M.playlists) do
    if pl.id ~= active_id then
      local is_draggable = M.is_playlist_draggable_to(pl.id, active_id)
      
      pool_playlists[#pool_playlists + 1] = {
        id = pl.id,
        name = pl.name,
        items = pl.items,
        chip_color = pl.chip_color or RegionState.generate_chip_color(),
        is_disabled = not is_draggable,
      }
    end
  end
  
  local search = M.state.search_filter:lower()
  if search ~= "" then
    local filtered = {}
    for _, pl in ipairs(pool_playlists) do
      if pl.name:lower():find(search, 1, true) then
        filtered[#filtered + 1] = pl
      end
    end
    pool_playlists = filtered
  end
  
  local sort_mode = M.state.sort_mode
  local sort_dir = M.state.sort_direction or "asc"
  
  if sort_mode == "alpha" then
    table.sort(pool_playlists, compare_playlists_by_alpha)
  elseif sort_mode == "length" then
    table.sort(pool_playlists, compare_playlists_by_item_count)
  end
  
  if sort_dir == "desc" then
    local reversed = {}
    for i = #pool_playlists, 1, -1 do
      reversed[#reversed + 1] = pool_playlists[i]
    end
    pool_playlists = reversed
  end
  
  return pool_playlists
end

function M.detect_circular_reference(target_playlist_id, playlist_id_to_add)
  if M.graph_dirty then
    M.rebuild_dependency_graph()
  end
  
  if target_playlist_id == playlist_id_to_add then
    return true, {target_playlist_id}
  end
  
  local target_node = M.dependency_graph[target_playlist_id]
  if target_node and target_node.is_disabled_for[playlist_id_to_add] then
    return true, {playlist_id_to_add, target_playlist_id}
  end
  
  local playlist_node = M.dependency_graph[playlist_id_to_add]
  if playlist_node and playlist_node.all_deps[target_playlist_id] then
    local path = {playlist_id_to_add}
    
    local function build_path(from_id, to_id, current_path)
      if from_id == to_id then
        return current_path
      end
      
      local node = M.dependency_graph[from_id]
      if not node then return nil end
      
      for _, dep_id in ipairs(node.direct_deps) do
        if not current_path[dep_id] then
          local new_path = {}
          for k, v in pairs(current_path) do new_path[k] = v end
          new_path[dep_id] = true
          
          local result = build_path(dep_id, to_id, new_path)
          if result then
            return result
          end
        end
      end
      
      return nil
    end
    
    local path_set = {[playlist_id_to_add] = true}
    local full_path_set = build_path(playlist_id_to_add, target_playlist_id, path_set)
    
    if full_path_set then
      local path_array = {}
      for pid in pairs(full_path_set) do
        path_array[#path_array + 1] = pid
      end
      path_array[#path_array + 1] = target_playlist_id
      return true, path_array
    end
    
    return true, {playlist_id_to_add, "...", target_playlist_id}
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
  local current_project_filename = get_current_project_filename()
  
  if current_project_filename ~= M.state.last_project_filename then
    M.state.last_project_filename = current_project_filename
    M.reload_project_data()
    return
  end
  
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