-- ReArkitekt/features/region_playlist/engine.lua
-- Region Playlist Engine - simplified to use native REAPER region IDs

local Regions = require('ReArkitekt.reaper.regions')
local Transport = require('ReArkitekt.reaper.transport')
local Timing = require('ReArkitekt.reaper.timing')

local M = {}
local Engine = {}
Engine.__index = Engine

function M.new(opts)
  opts = opts or {}
  local self = setmetatable({}, Engine)
  
  self.proj = opts.proj or 0
  self.region_cache = {}
  self.playlist_order = {}
  self.playlist_pointer = 1
  self.quantize_mode = opts.quantize_mode or "none"
  self.follow_playhead = opts.follow_playhead or false
  self.transport_override = opts.transport_override or false
  self.state_change_count = 0
  self.epsilon = opts.epsilon or 0.016
  self.scheduled_jump = nil
  self.is_playing = false
  
  self:rescan()
  
  return self
end

function Engine:rescan()
  local regions = Regions.scan_project_regions(self.proj)
  
  self.region_cache = {}
  for _, rgn in ipairs(regions) do
    self.region_cache[rgn.rid] = rgn
  end
  
  self.state_change_count = Transport.get_project_state_change_count(self.proj)
end

function Engine:check_for_changes()
  local current_state = Transport.get_project_state_change_count(self.proj)
  if current_state ~= self.state_change_count then
    self:rescan()
    return true
  end
  return false
end

function Engine:set_order(new_order)
  self.playlist_order = {}
  for _, rid in ipairs(new_order) do
    if self.region_cache[rid] then
      self.playlist_order[#self.playlist_order + 1] = rid
    end
  end
  self.playlist_pointer = math.min(self.playlist_pointer, #self.playlist_order)
end

function Engine:set_quantize_mode(mode)
  if mode == "none" or mode == "beat" or mode == "bar" or mode == "grid" then
    self.quantize_mode = mode
  end
end

function Engine:set_transport_override(enabled)
  self.transport_override = enabled
end

function Engine:get_transport_override()
  return self.transport_override
end

function Engine:get_current_rid()
  if self.playlist_pointer < 1 or self.playlist_pointer > #self.playlist_order then
    return nil
  end
  return self.playlist_order[self.playlist_pointer]
end

function Engine:get_region_by_rid(rid)
  return self.region_cache[rid]
end

function Engine:play()
  local rid = self:get_current_rid()
  if not rid then 
    return false 
  end
  
  local region = self:get_region_by_rid(rid)
  if not region then 
    return false 
  end
  
  Transport.set_play_position(region.start, true, self.proj)
  
  if not Transport.is_playing(self.proj) then
    Transport.play(self.proj)
  end
  
  self.is_playing = true
  self.scheduled_jump = nil
  
  return true
end

function Engine:stop()
  Transport.stop(self.proj)
  self.is_playing = false
  self.scheduled_jump = nil
end

function Engine:next()
  if self.playlist_pointer < #self.playlist_order then
    self.playlist_pointer = self.playlist_pointer + 1
    return self:play()
  end
  return false
end

function Engine:prev()
  if self.playlist_pointer > 1 then
    self.playlist_pointer = self.playlist_pointer - 1
    return self:play()
  end
  return false
end

function Engine:jump_to_index(idx)
  if idx >= 1 and idx <= #self.playlist_order then
    self.playlist_pointer = idx
    return self:play()
  end
  return false
end

function Engine:poll_transport_sync()
  if not self.transport_override then return end
  if self.is_playing then return end
  
  if not Transport.is_playing(self.proj) then return end
  
  local playpos = Transport.get_play_position(self.proj)
  
  for i, rid in ipairs(self.playlist_order) do
    local region = self:get_region_by_rid(rid)
    if region then
      if playpos >= region.start and playpos < region["end"] then
        self.playlist_pointer = i
        self.is_playing = true
        self.scheduled_jump = nil
        return
      end
    end
  end
end

function Engine:update()
  self:check_for_changes()
  
  if not Transport.is_playing(self.proj) then
    self.is_playing = false
    self.scheduled_jump = nil
    return
  end
  
  if not self.is_playing then
    self:poll_transport_sync()
    if not self.is_playing then
      return
    end
  end
  
  local playpos = Transport.get_play_position(self.proj)
  local rid = self:get_current_rid()
  if not rid then return end
  
  local region = self:get_region_by_rid(rid)
  if not region then return end
  
  if self.scheduled_jump then
    if playpos >= self.scheduled_jump - self.epsilon then
      self:next()
      return
    end
  else
    local transition_time = region["end"]
    
    if self.quantize_mode ~= "none" then
      transition_time = Timing.calculate_next_transition(
        region["end"], 
        self.quantize_mode, 
        8.0, 
        self.proj
      )
    end
    
    if playpos >= region["end"] - self.epsilon then
      if transition_time > region["end"] + self.epsilon then
        self.scheduled_jump = transition_time
      else
        self:next()
      end
    end
  end
  
  if self.follow_playhead then
    for i, check_rid in ipairs(self.playlist_order) do
      local check_region = self:get_region_by_rid(check_rid)
      if check_region then
        if playpos >= check_region.start and playpos < check_region["end"] then
          if i ~= self.playlist_pointer then
            self.playlist_pointer = i
          end
          break
        end
      end
    end
  end
end

function Engine:get_state()
  return {
    region_cache = self.region_cache,
    playlist_order = self.playlist_order,
    playlist_pointer = self.playlist_pointer,
    quantize_mode = self.quantize_mode,
    is_playing = self.is_playing,
    scheduled_jump = self.scheduled_jump,
    follow_playhead = self.follow_playhead,
    transport_override = self.transport_override,
  }
end

return M