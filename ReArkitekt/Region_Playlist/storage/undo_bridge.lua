-- ReArkitekt/features/region_playlist/undo_bridge.lua
-- Bridge between undo manager and playlist state

local M = {}

function M.capture_snapshot(playlists, active_playlist_id)
  local snapshot = {
    playlists = {},
    active_playlist = active_playlist_id,
    timestamp = os.time(),
  }
  
  for _, pl in ipairs(playlists) do
    local pl_copy = {
      id = pl.id,
      name = pl.name,
      items = {},
    }
    
    for _, item in ipairs(pl.items) do
      pl_copy.items[#pl_copy.items + 1] = {
        rid = item.rid,
        reps = item.reps,
        enabled = item.enabled,
        key = item.key,
      }
    end
    
    snapshot.playlists[#snapshot.playlists + 1] = pl_copy
  end
  
  return snapshot
end

function M.restore_snapshot(snapshot, region_index)
  local restored_playlists = {}
  
  for _, pl in ipairs(snapshot.playlists) do
    local pl_copy = {
      id = pl.id,
      name = pl.name,
      items = {},
    }
    
    for _, item in ipairs(pl.items) do
      if region_index[item.rid] then
        pl_copy.items[#pl_copy.items + 1] = {
          rid = item.rid,
          reps = item.reps,
          enabled = item.enabled,
          key = item.key,
        }
      end
    end
    
    restored_playlists[#restored_playlists + 1] = pl_copy
  end
  
  return restored_playlists, snapshot.active_playlist
end

function M.should_capture(old_playlists, new_playlists)
  if #old_playlists ~= #new_playlists then
    return true
  end
  
  for i, old_pl in ipairs(old_playlists) do
    local new_pl = new_playlists[i]
    if not new_pl or old_pl.id ~= new_pl.id then
      return true
    end
    
    if #old_pl.items ~= #new_pl.items then
      return true
    end
    
    for j, old_item in ipairs(old_pl.items) do
      local new_item = new_pl.items[j]
      if not new_item or old_item.rid ~= new_item.rid or 
         old_item.reps ~= new_item.reps or 
         old_item.enabled ~= new_item.enabled then
        return true
      end
    end
  end
  
  return false
end

return M