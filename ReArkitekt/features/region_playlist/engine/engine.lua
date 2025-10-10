-- ReArkitekt/features/region_playlist/engine/engine.lua
-- Refactored: State, Transport, and Transitions extracted

local EngineState = require('ReArkitekt.features.region_playlist.engine.state')
local EngineTransport = require('ReArkitekt.features.region_playlist.engine.transport')
local EngineTransitions = require('ReArkitekt.features.region_playlist.engine.transitions')
local EngineQuantize = require('ReArkitekt.features.region_playlist.engine.quantize')

local M = {}
local Engine = {}
Engine.__index = Engine

function M.new(opts)
  opts = opts or {}
  local self = setmetatable({}, Engine)

  self.proj = opts.proj or 0
  self.state = EngineState.new({ proj = self.proj })
  
  self.transport = EngineTransport.new({
    proj = self.proj,
    state = self.state,
    transport_override = opts.transport_override,
    loop_playlist = opts.loop_playlist,
  })
  
  self.transitions = EngineTransitions.new({
    proj = self.proj,
    state = self.state,
    transport = self.transport,
    on_repeat_cycle = opts.on_repeat_cycle,
  })
  
  self.quantize = EngineQuantize.new({
    proj = self.proj,
    state = self.state,
    transport = self.transport,
  })
  
  self.follow_playhead = (opts.follow_playhead ~= false)
  self.quantize_mode = opts.quantize_mode or "none"
  self.on_repeat_cycle = opts.on_repeat_cycle
  
  return self
end

function Engine:rescan()
  self.state:rescan()
end

function Engine:check_for_changes()
  return self.state:check_for_changes()
end

function Engine:set_order(new_order)
  self.state:set_order(new_order)
end

function Engine:get_current_rid()
  return self.state:get_current_rid()
end

function Engine:set_playlist_pointer(pointer)
  self.state.playlist_pointer = pointer
end

function Engine:get_playlist_pointer()
  return self.state.playlist_pointer
end

function Engine:get_region_by_rid(rid)
  return self.state:get_region_by_rid(rid)
end

function Engine:play()
  return self.transport:play()
end

function Engine:stop()
  return self.transport:stop()
end

function Engine:next()
  return self.transport:next()
end

function Engine:prev()
  return self.transport:prev()
end

function Engine:jump_to_next_quantized(lookahead)
  return self.quantize:jump_to_next_quantized(lookahead)
end

function Engine:update()
  self:check_for_changes()
  
  if self.transport:check_stopped() then
    return
  end
  
  if not self.transport.is_playing then
    self.transport:poll_transport_sync()
    if not self.transport.is_playing then
      return
    end
  end
  
  if #self.state.playlist_order == 0 then return end
  
  self.transitions:handle_smooth_transitions()
  self.quantize:update()
end

function Engine:set_follow_playhead(enabled)
  self.follow_playhead = not not enabled
end

function Engine:set_transport_override(enabled)
  self.transport:set_transport_override(enabled)
end

function Engine:get_transport_override()
  return self.transport:get_transport_override()
end

function Engine:set_loop_playlist(enabled)
  self.transport:set_loop_playlist(enabled)
end

function Engine:get_loop_playlist()
  return self.transport:get_loop_playlist()
end

function Engine:set_quantize_mode(mode)
  self.quantize_mode = mode
end

function Engine:get_quantize_mode()
  return self.quantize_mode
end

function Engine:get_is_playing()
  return self.transport.is_playing
end

function Engine:get_state()
  local state_snapshot = self.state:get_state_snapshot()
  return {
    proj = self.proj,
    region_cache = state_snapshot.region_cache,
    playlist_order = state_snapshot.playlist_order,
    playlist_pointer = state_snapshot.playlist_pointer,
    follow_playhead = self.follow_playhead,
    transport_override = self.transport:get_transport_override(),
    loop_playlist = self.transport:get_loop_playlist(),
    quantize_mode = self.quantize_mode,
    is_playing = self.transport.is_playing,
    has_sws = EngineTransport._has_sws(),
    _playlist_mode = self.transport._playlist_mode,
    current_idx = state_snapshot.current_idx,
    next_idx = state_snapshot.next_idx,
  }
end

M.Engine = Engine
return M