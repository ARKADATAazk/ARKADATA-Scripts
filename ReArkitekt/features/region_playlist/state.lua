-- ReArkitekt/features/region_playlist/state.lua
-- Region Playlist state persistence via Project ExtState

local JSON = require('ReArkitekt.core.json')

local M = {}

local EXT_STATE_SECTION = "ReArkitekt_RegionPlaylist"
local KEY_PLAYLISTS = "playlists"
local KEY_ACTIVE = "active_playlist"
local KEY_SETTINGS = "settings"

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
  
  return playlists or {}
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
    }
  }
end

return M