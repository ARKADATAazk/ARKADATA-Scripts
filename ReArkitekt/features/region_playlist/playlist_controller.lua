-- ReArkitekt/features/region_playlist/playlist_controller.lua
-- Centralized playlist operations with automatic undo/save/sync

local M = {}
local Controller = {}
Controller.__index = Controller

function M.new(state_module, settings, undo_manager)
  local ctrl = setmetatable({
    state = state_module,
    settings = settings,
    undo = undo_manager,
  }, Controller)
  
  return ctrl
end

function Controller:_commit()
  self.state.persist()
  self.state.sync_playlist_to_engine()
end

function Controller:_with_undo(fn)
  self.state.capture_undo_snapshot()
  local success, result = pcall(fn)
  if success then
    self:_commit()
    return true, result
  else
    return false, result
  end
end

function Controller:_get_playlist(id)
  for _, pl in ipairs(self.state.playlists) do
    if pl.id == id then
      return pl
    end
  end
  return nil
end

function Controller:_generate_playlist_id()
  local max_id = 0
  for _, pl in ipairs(self.state.playlists) do
    local id_num = tonumber(pl.id)
    if id_num and id_num > max_id then
      max_id = id_num
    end
  end
  return tostring(max_id + 1)
end

function Controller:_generate_item_key(rid, suffix)
  local base = "item_" .. rid .. "_" .. reaper.time_precise()
  return suffix and (base .. "_" .. suffix) or base
end

function Controller:create_playlist(name)
  return self:_with_undo(function()
    local new_id = self:_generate_playlist_id()
    local new_playlist = {
      id = new_id,
      name = name or ("Playlist " .. new_id),
      items = {},
    }
    
    self.state.playlists[#self.state.playlists + 1] = new_playlist
    self.state.state.active_playlist = new_id
    
    return new_id
  end)
end

function Controller:delete_playlist(id)
  if #self.state.playlists <= 1 then
    return false, "Cannot delete last playlist"
  end
  
  return self:_with_undo(function()
    local delete_index = nil
    for i, pl in ipairs(self.state.playlists) do
      if pl.id == id then
        delete_index = i
        break
      end
    end
    
    if not delete_index then
      error("Playlist not found")
    end
    
    table.remove(self.state.playlists, delete_index)
    
    if self.state.state.active_playlist == id then
      local new_active_index = math.min(delete_index, #self.state.playlists)
      self.state.state.active_playlist = self.state.playlists[new_active_index].id
    end
  end)
end

function Controller:reorder_playlists(from_idx, to_idx)
  if from_idx == to_idx then
    return true
  end
  
  return self:_with_undo(function()
    local moved_playlist = table.remove(self.state.playlists, from_idx)
    table.insert(self.state.playlists, to_idx, moved_playlist)
  end)
end

function Controller:add_item(playlist_id, rid, insert_index)
  return self:_with_undo(function()
    local pl = self:_get_playlist(playlist_id)
    if not pl then
      error("Playlist not found")
    end
    
    local new_item = {
      rid = rid,
      reps = 1,
      enabled = true,
      key = self:_generate_item_key(rid),
    }
    
    table.insert(pl.items, insert_index or (#pl.items + 1), new_item)
    return new_item.key
  end)
end

function Controller:add_items_batch(playlist_id, rids, insert_index)
  return self:_with_undo(function()
    local pl = self:_get_playlist(playlist_id)
    if not pl then
      error("Playlist not found")
    end
    
    local keys = {}
    local idx = insert_index or (#pl.items + 1)
    
    for i, rid in ipairs(rids) do
      local new_item = {
        rid = rid,
        reps = 1,
        enabled = true,
        key = self:_generate_item_key(rid, i),
      }
      table.insert(pl.items, idx + i - 1, new_item)
      keys[#keys + 1] = new_item.key
    end
    
    return keys
  end)
end

function Controller:copy_items(playlist_id, items, insert_index)
  return self:_with_undo(function()
    local pl = self:_get_playlist(playlist_id)
    if not pl then
      error("Playlist not found")
    end
    
    local keys = {}
    local idx = insert_index or (#pl.items + 1)
    
    for i, item in ipairs(items) do
      local new_item = {
        rid = item.rid,
        reps = item.reps or 1,
        enabled = item.enabled ~= false,
        key = self:_generate_item_key(item.rid, i),
      }
      table.insert(pl.items, idx + i - 1, new_item)
      keys[#keys + 1] = new_item.key
    end
    
    return keys
  end)
end

function Controller:reorder_items(playlist_id, new_order)
  return self:_with_undo(function()
    local pl = self:_get_playlist(playlist_id)
    if not pl then
      error("Playlist not found")
    end
    
    pl.items = new_order
  end)
end

function Controller:delete_items(playlist_id, item_keys)
  return self:_with_undo(function()
    local pl = self:_get_playlist(playlist_id)
    if not pl then
      error("Playlist not found")
    end
    
    local keys_set = {}
    for _, k in ipairs(item_keys) do
      keys_set[k] = true
    end
    
    local new_items = {}
    for _, item in ipairs(pl.items) do
      if not keys_set[item.key] then
        new_items[#new_items + 1] = item
      end
    end
    
    pl.items = new_items
  end)
end

function Controller:toggle_item_enabled(playlist_id, item_key, enabled)
  return self:_with_undo(function()
    local pl = self:_get_playlist(playlist_id)
    if not pl then
      error("Playlist not found")
    end
    
    for _, item in ipairs(pl.items) do
      if item.key == item_key then
        item.enabled = enabled
        return
      end
    end
  end)
end

function Controller:adjust_repeats(playlist_id, item_keys, delta)
  return self:_with_undo(function()
    local pl = self:_get_playlist(playlist_id)
    if not pl then
      error("Playlist not found")
    end
    
    local keys_set = {}
    for _, k in ipairs(item_keys) do
      keys_set[k] = true
    end
    
    for _, item in ipairs(pl.items) do
      if keys_set[item.key] then
        item.reps = math.max(0, (item.reps or 1) + delta)
      end
    end
  end)
end

function Controller:sync_repeats(playlist_id, item_keys, target_reps)
  return self:_with_undo(function()
    local pl = self:_get_playlist(playlist_id)
    if not pl then
      error("Playlist not found")
    end
    
    local keys_set = {}
    for _, k in ipairs(item_keys) do
      keys_set[k] = true
    end
    
    for _, item in ipairs(pl.items) do
      if keys_set[item.key] then
        item.reps = target_reps
      end
    end
  end)
end

function Controller:cycle_repeats(playlist_id, item_key)
  return self:_with_undo(function()
    local pl = self:_get_playlist(playlist_id)
    if not pl then
      error("Playlist not found")
    end
    
    for _, item in ipairs(pl.items) do
      if item.key == item_key then
        local reps = item.reps or 1
        if reps == 1 then
          item.reps = 2
        elseif reps == 2 then
          item.reps = 4
        elseif reps == 4 then
          item.reps = 8
        else
          item.reps = 1
        end
        return
      end
    end
  end)
end

function Controller:undo()
  return self.state.undo()
end

function Controller:redo()
  return self.state.redo()
end

function Controller:can_undo()
  return self.state.can_undo()
end

function Controller:can_redo()
  return self.state.can_redo()
end

return M