-- ReArkitekt/features/region_playlist/coordinator_bridge.lua
-- Unified bridge with loop-aware playlist sync and nested playlist support

local Engine = require("ReArkitekt.features.region_playlist.engine")
local Playback = require("ReArkitekt.features.region_playlist.playback")
local RegionState = require("ReArkitekt.features.region_playlist.state")

local M = {}

function M.create(opts)
  opts = opts or {}
  
  local saved_settings = RegionState.load_settings(opts.proj or 0)
  
  local bridge = {
    proj = opts.proj or 0,
    controller = nil,
    get_playlist_by_id = opts.get_playlist_by_id,
  }
  
  bridge.engine = Engine.new({
    proj = bridge.proj,
    quantize_mode = saved_settings.quantize_mode or "none",
    follow_playhead = saved_settings.follow_playhead or false,
    transport_override = saved_settings.transport_override or false,
    loop_playlist = saved_settings.loop_playlist or false,
    on_repeat_cycle = opts.on_repeat_cycle,
    playlist_lookup = opts.get_playlist_by_id,
  })
  
  bridge.playback = Playback.new(bridge.engine, {
    on_region_change = opts.on_region_change,
    on_playback_start = opts.on_playback_start,
    on_playback_stop = opts.on_playback_stop,
    on_transition_scheduled = opts.on_transition_scheduled,
  })
  
  function bridge:set_controller(controller)
    self.controller = controller
  end
  
  function bridge:set_playlist_lookup(fn)
    self.get_playlist_by_id = fn
    self.engine.playlist_lookup = fn
  end
  
  function bridge:update()
    self.playback:update()
  end
  
  function bridge:sync_from_ui_playlist(playlist_items)
    local order = {}
    for _, item in ipairs(playlist_items) do
      if item.enabled ~= false then
        if item.type == "playlist" then
          order[#order + 1] = {
            type = "playlist",
            playlist_id = item.playlist_id,
            reps = item.reps or 1,
            key = item.key,
          }
        else
          order[#order + 1] = {
            type = "region",
            rid = item.rid,
            reps = item.reps or 1,
            key = item.key,
          }
        end
      end
    end
    self.engine:set_order(order)
  end
  
  function bridge:get_regions_for_ui()
    local regions = {}
    for rid, rgn in pairs(self.engine.region_cache) do
      regions[#regions + 1] = {
        rid = rid,
        name = rgn.name,
        start = rgn.start,
        ["end"] = rgn["end"],
        color = rgn.color,
      }
    end
    return regions
  end
  
  function bridge:get_current_rid()
    return self.engine:get_current_rid()
  end
  
  function bridge:get_progress()
    return self.playback:get_progress()
  end
  
  function bridge:get_time_remaining()
    return self.playback:get_time_remaining()
  end
  
  function bridge:play()
    return self.engine:play()
  end
  
  function bridge:stop()
    return self.engine:stop()
  end
  
  function bridge:next()
    return self.engine:next()
  end
  
  function bridge:prev()
    return self.engine:prev()
  end
  
  function bridge:set_quantize_mode(mode)
    self.engine:set_quantize_mode(mode)
    local settings = RegionState.load_settings(self.proj)
    settings.quantize_mode = mode
    RegionState.save_settings(settings, self.proj)
  end
  
  function bridge:set_loop_playlist(enabled)
    self.engine:set_loop_playlist(enabled)
    local settings = RegionState.load_settings(self.proj)
    settings.loop_playlist = enabled
    RegionState.save_settings(settings, self.proj)
  end
  
  function bridge:get_loop_playlist()
    return self.engine:get_loop_playlist()
  end
  
  function bridge:get_state()
    local engine_state = self.engine:get_state()
    return {
      is_playing = engine_state.is_playing,
      playlist_pointer = engine_state.playlist_pointer,
      playlist_order = engine_state.playlist_order,
      quantize_mode = engine_state.quantize_mode,
      context_depth = engine_state.context_depth,
    }
  end
  
  function bridge:item_key_to_engine_index(playlist_items, item_key)
    if not playlist_items or not item_key then return nil end
    
    local engine_index = 0
    
    for _, item in ipairs(playlist_items) do
      if item.enabled ~= false then
        if item.key == item_key then
          return engine_index + 1
        end
        engine_index = engine_index + 1
      end
    end
    
    return nil
  end
  
  return bridge
end

return M