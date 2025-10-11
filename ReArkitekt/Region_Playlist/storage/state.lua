-- ReArkitekt/features/region_playlist/state.lua
-- Region Playlist state persistence via Project ExtState
-- FIXED: Colors persist correctly and generation is centralized.

local JSON = require('ReArkitekt.core.json')
local Colors = require('ReArkitekt.core.colors') -- Added

local M = {}

local EXT_STATE_SECTION = "ReArkitekt_RegionPlaylist"
local KEY_PLAYLISTS = "playlists"
local KEY_ACTIVE = "active_playlist"
local KEY_SETTINGS = "settings"

-- (No changes to migrate functions)
local function migrate_playlist_items(items)
  for _, item in ipairs(items) do
    if not item.type then
      item.type = "region"
    end
    if item.type == "region" and not item.reps then
      item.reps = 1
    end
    if item.enabled == nil then
      item.enabled = true
    end
  end
  return items
end

local function migrate_playlists(playlists, proj)
  local needs_save = false
  
  for _, pl in ipairs(playlists) do
    if pl.items then
      migrate_playlist_items(pl.items)
    end
    if not pl.chip_color then
      pl.chip_color = M.generate_chip_color()
      needs_save = true
    end
  end
  
  if needs_save then
    M.save_playlists(playlists, proj)
  end
  
  return playlists
end

-- (No changes to save/load functions)
function M.save_playlists(playlists, proj)
  proj = proj or 0
  local json_str = JSON.encode(playlists)
  reaper.SetProjExtState(proj, EXT_STATE_SECTION, KEY_PLAYLISTS, json_str)
end

function M.load_playlists(proj)
  proj = proj or 0
  local ok, json_str = reaper.GetProjExtState(proj, EXT_STATE_SECTION, KEY_PLAYLISTS)
  if ok ~= 1 or not json_str or json_str == "" then
    return {}
  end
  
  local success, playlists = pcall(JSON.decode, json_str)
  if not success then
    return {}
  end
  
  return migrate_playlists(playlists or {}, proj)
end

function M.save_active_playlist(playlist_id, proj)
  proj = proj or 0
  reaper.SetProjExtState(proj, EXT_STATE_SECTION, KEY_ACTIVE, playlist_id)
end

function M.load_active_playlist(proj)
  proj = proj or 0
  local ok, playlist_id = reaper.GetProjExtState(proj, EXT_STATE_SECTION, KEY_ACTIVE)
  if ok ~= 1 or not playlist_id or playlist_id == "" then
    return nil
  end
  return playlist_id
end

function M.save_settings(settings, proj)
  proj = proj or 0
  local json_str = JSON.encode(settings)
  reaper.SetProjExtState(proj, EXT_STATE_SECTION, KEY_SETTINGS, json_str)
end

function M.load_settings(proj)
  proj = proj or 0
  local ok, json_str = reaper.GetProjExtState(proj, EXT_STATE_SECTION, KEY_SETTINGS)
  if ok ~= 1 or not json_str or json_str == "" then
    return {}
  end
  
  local success, settings = pcall(JSON.decode, json_str)
  if not success then
    return {}
  end
  
  return settings or {}
end

function M.clear_all(proj)
  proj = proj or 0
  reaper.SetProjExtState(proj, EXT_STATE_SECTION, KEY_PLAYLISTS, "")
  reaper.SetProjExtState(proj, EXT_STATE_SECTION, KEY_ACTIVE, "")
  reaper.SetProjExtState(proj, EXT_STATE_SECTION, KEY_SETTINGS, "")
end

function M.get_or_create_default_playlist(playlists, regions)
  if #playlists > 0 then
    return playlists
  end
  
  local default_items = {}
  for i, region in ipairs(regions) do
    default_items[#default_items + 1] = {
      type = "region",
      rid = i,
      reps = 1,
      enabled = true,
      key = "region_" .. i,
    }
  end
  
  return {
    {
      id = "Main",
      name = "Main Playlist",
      items = default_items,
      chip_color = M.generate_chip_color(),
    }
  }
end

--- REFACTORED FUNCTION ---
function M.generate_chip_color()
  local hue = math.random()
  local saturation = 0.65 + math.random() * 0.25
  local lightness = 0.50 + math.random() * 0.15
  
  local r, g, b = Colors.hsl_to_rgb(hue, saturation, lightness)
  return Colors.components_to_rgba(r, g, b, 0xFF)
end

return M