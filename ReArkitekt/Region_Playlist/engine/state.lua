-- ReArkitekt/features/region_playlist/engine/state.lua
-- State management for region playlist engine

local Regions = require('ReArkitekt.reaper.regions')
local Transport = require('ReArkitekt.reaper.transport')

local M = {}
local State = {}
State.__index = State

function M.new(opts)
  opts = opts or {}
  local self = setmetatable({}, State)
  
  self.proj = opts.proj or 0
  
  -- Region tracking
  self.region_cache = {}
  self.state_change_count = 0
  
  -- Playlist tracking
  self.playlist_order = {}
  self.playlist_metadata = {}
  self.playlist_pointer = 1
  
  -- Transition state
  self.current_idx = -1
  self.next_idx = -1
  self.current_bounds = {start_pos = 0, end_pos = -1}
  self.next_bounds = {start_pos = 0, end_pos = -1}
  self.last_play_pos = -1
  
  -- Boundary epsilon for floating point comparison
  self.boundary_epsilon = 0.01
  
  self:rescan()
  
  return self
end

function State:rescan()
  local regions = Regions.scan_project_regions(self.proj)
  
  self.region_cache = {}
  for _, rgn in ipairs(regions) do
    self.region_cache[rgn.rid] = rgn
  end
  
  self.state_change_count = Transport.get_project_state_change_count(self.proj)
end

function State:check_for_changes()
  local current_state = Transport.get_project_state_change_count(self.proj)
  if current_state ~= self.state_change_count then
    self:rescan()
    return true
  end
  return false
end

function State:set_order(new_order)
  self.playlist_order = {}
  self.playlist_metadata = {}
  
  for _, entry in ipairs(new_order) do
    local rid = type(entry) == "table" and entry.rid or entry
    if self.region_cache[rid] then
      self.playlist_order[#self.playlist_order + 1] = rid
      self.playlist_metadata[#self.playlist_metadata + 1] = {
        key = type(entry) == "table" and entry.key or nil,
        reps = type(entry) == "table" and entry.reps or 1,
        current_loop = 1,
      }
    end
  end
  
  self.playlist_pointer = self:_clamp(self.playlist_pointer, 1, math.max(1, #self.playlist_order))
  self.current_idx = -1
  self.next_idx = -1
end

function State:get_current_rid()
  if self.playlist_pointer < 1 or self.playlist_pointer > #self.playlist_order then
    return nil
  end
  return self.playlist_order[self.playlist_pointer]
end

function State:get_region_by_rid(rid)
  return self.region_cache[rid]
end

function State:update_bounds()
  if self.current_idx >= 1 and self.current_idx <= #self.playlist_order then
    local rid = self.playlist_order[self.current_idx]
    local region = self:get_region_by_rid(rid)
    if region then
      self.current_bounds.start_pos = region.start
      self.current_bounds.end_pos = region["end"]
    end
  else
    self.current_bounds.start_pos = 0
    self.current_bounds.end_pos = -1
  end
  
  if self.next_idx >= 1 and self.next_idx <= #self.playlist_order then
    local rid = self.playlist_order[self.next_idx]
    local region = self:get_region_by_rid(rid)
    if region then
      self.next_bounds.start_pos = region.start
      self.next_bounds.end_pos = region["end"]
    end
  else
    self.next_bounds.start_pos = 0
    self.next_bounds.end_pos = -1
  end
end

function State:find_index_at_position(pos)
  for i = 1, #self.playlist_order do
    local rid = self.playlist_order[i]
    local region = self:get_region_by_rid(rid)
    if region and pos >= region.start and pos < region["end"] - 1e-9 then
      return i
    end
  end
  return -1
end

function State:_clamp(i, lo, hi)
  if i < lo then return lo end
  if i > hi then return hi end
  return i
end

function State:get_state_snapshot()
  return {
    proj = self.proj,
    region_cache = self.region_cache,
    playlist_order = self.playlist_order,
    playlist_pointer = self.playlist_pointer,
    current_idx = self.current_idx,
    next_idx = self.next_idx,
  }
end

return M