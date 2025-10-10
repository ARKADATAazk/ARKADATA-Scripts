-- ReArkitekt/features/region_playlist/engine/transport.lua
-- Transport control and seeking logic

local M = {}
local Transport = {}
Transport.__index = Transport

local function _has_sws()
  return (reaper.SNM_GetIntConfigVar ~= nil) and (reaper.SNM_SetIntConfigVar ~= nil)
end

local function _is_playing(proj)
  proj = proj or 0
  local st = reaper.GetPlayStateEx(proj)
  return (st & 1) == 1
end

local function _get_play_pos(proj)
  return reaper.GetPlayPositionEx(proj or 0)
end

function M.new(opts)
  opts = opts or {}
  local self = setmetatable({}, Transport)
  
  self.proj = opts.proj or 0
  self.state = opts.state
  
  self.transport_override = (opts.transport_override == true)
  self.loop_playlist = (opts.loop_playlist == true)
  
  self.is_playing = false
  self.last_seek_time = 0
  self.seek_throttle = 0.06
  
  self._playlist_mode = false
  self._old_smoothseek = nil
  self._old_repeat = nil
  
  return self
end

function Transport:_enter_playlist_mode_if_needed()
  if self._playlist_mode then return end
  
  if _has_sws() then
    self._old_smoothseek = reaper.SNM_GetIntConfigVar("smoothseek", -1)
    reaper.SNM_SetIntConfigVar("smoothseek", 3)

    self._old_repeat = reaper.GetSetRepeat(-1)
    if self._old_repeat == 1 then
      reaper.GetSetRepeat(0)
    end
  end
  self._playlist_mode = true
end

function Transport:_leave_playlist_mode_if_needed()
  if not self._playlist_mode then return end
  
  if _has_sws() then
    if self._old_smoothseek ~= nil then
      reaper.SNM_SetIntConfigVar("smoothseek", self._old_smoothseek)
      self._old_smoothseek = nil
    end
    if self._old_repeat == 1 then
      reaper.GetSetRepeat(1)
    end
    self._old_repeat = nil
  end
  self._playlist_mode = false
end

function Transport:_seek_to_region(region_num)
  local now = reaper.time_precise()
  if now - self.last_seek_time < self.seek_throttle then
    return false
  end
  
  local cursor_pos = reaper.GetCursorPositionEx(self.proj)
  
  reaper.PreventUIRefresh(1)
  reaper.GoToRegion(self.proj, region_num, false)
  
  if not _is_playing(self.proj) then
    reaper.OnPlayButton()
  end
  
  reaper.SetEditCurPos2(self.proj, cursor_pos, false, false)
  reaper.PreventUIRefresh(-1)
  
  self.last_seek_time = now
  return true
end

function Transport:play()
  local rid = self.state:get_current_rid()
  if not rid then return false end

  local region = self.state:get_region_by_rid(rid)
  if not region then return false end

  self:_enter_playlist_mode_if_needed()

  if _is_playing(self.proj) then
    local region_num = region.rid
    self:_seek_to_region(region_num)
  else
    reaper.SetEditCurPos2(self.proj, region.start, false, false)
    reaper.OnPlayButton()
  end

  self.is_playing = true
  self.state.current_idx = -1
  self.state.next_idx = self.state.playlist_pointer
  self.state:update_bounds()
  
  return true
end

function Transport:stop()
  reaper.OnStopButton()
  self.is_playing = false
  self.state.current_idx = -1
  self.state.next_idx = -1
  self:_leave_playlist_mode_if_needed()
end

function Transport:next()
  if #self.state.playlist_order == 0 then return false end
  if self.state.playlist_pointer >= #self.state.playlist_order then return false end
  
  self.state.playlist_pointer = self.state.playlist_pointer + 1

  if _is_playing(self.proj) then
    local rid = self.state:get_current_rid()
    local region = self.state:get_region_by_rid(rid)
    if region then
      return self:_seek_to_region(region.rid)
    end
  else
    return self:play()
  end
  
  return false
end

function Transport:prev()
  if #self.state.playlist_order == 0 then return false end
  if self.state.playlist_pointer <= 1 then return false end
  
  self.state.playlist_pointer = self.state.playlist_pointer - 1

  if _is_playing(self.proj) then
    local rid = self.state:get_current_rid()
    local region = self.state:get_region_by_rid(rid)
    if region then
      return self:_seek_to_region(region.rid)
    end
  else
    return self:play()
  end
  
  return false
end

function Transport:poll_transport_sync()
  if not self.transport_override then return end
  if self.is_playing then return end
  if not _is_playing(self.proj) then return end
  
  local playpos = _get_play_pos(self.proj)
  
  for i, rid in ipairs(self.state.playlist_order) do
    local region = self.state:get_region_by_rid(rid)
    if region then
      if playpos >= region.start and playpos < region["end"] then
        self.state.playlist_pointer = i
        self.is_playing = true
        self.state.current_idx = i
        
        local meta = self.state.playlist_metadata[i]
        local should_loop = meta and meta.current_loop < meta.reps
        
        if should_loop then
          self.state.next_idx = i
        else
          if i < #self.state.playlist_order then
            self.state.next_idx = i + 1
          elseif self.loop_playlist and #self.state.playlist_order > 0 then
            self.state.next_idx = 1
          else
            self.state.next_idx = -1
          end
        end
        
        self.state:update_bounds()
        self:_enter_playlist_mode_if_needed()
        return
      end
    end
  end
end

function Transport:set_transport_override(enabled)
  self.transport_override = not not enabled
end

function Transport:get_transport_override()
  return self.transport_override
end

function Transport:set_loop_playlist(enabled)
  self.loop_playlist = not not enabled
end

function Transport:get_loop_playlist()
  return self.loop_playlist
end

function Transport:check_stopped()
  if not _is_playing(self.proj) then
    if self.is_playing then
      self.is_playing = false
      self.state.current_idx = -1
      self.state.next_idx = -1
      self:_leave_playlist_mode_if_needed()
      return true
    end
  end
  return false
end

M.Transport = Transport
M._is_playing = _is_playing
M._get_play_pos = _get_play_pos
M._has_sws = _has_sws
return M