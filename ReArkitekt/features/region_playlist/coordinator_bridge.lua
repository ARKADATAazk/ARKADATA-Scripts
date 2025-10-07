-- ReArkitekt/features/region_playlist/coordinator_bridge.lua
-- Bridge between engine and gui - updated for native REAPER RIDs

local Engine = require('ReArkitekt.features.region_playlist.engine')
local Playback = require('ReArkitekt.features.region_playlist.playback')
local State = require('ReArkitekt.features.region_playlist.state')

local M = {}

function M.create(opts)
  opts = opts or {}
  
  local saved_settings = State.load_settings(opts.proj)
  
  local engine = Engine.new({
    proj = opts.proj,
    quantize_mode = saved_settings.quantize_mode or "none",
    follow_playhead = saved_settings.follow_playhead or false,
  })
  
  local playback = Playback.new(engine, {
    on_region_change = opts.on_region_change,
    on_playback_start = opts.on_playback_start,
    on_playback_stop = opts.on_playback_stop,
    on_transition_scheduled = opts.on_transition_scheduled,
  })
  
  local bridge = {
    engine = engine,
    playback = playback,
    proj = opts.proj or 0,
  }
  
  function bridge:update()
    self.playback:update()
  end
  
  function bridge:sync_from_ui_playlist(playlist_items)
    local order = {}
    for _, item in ipairs(playlist_items) do
      if item.rid and item.enabled ~= false then
        order[#order + 1] = item.rid
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
    local settings = State.load_settings(self.proj)
    settings.quantize_mode = mode
    State.save_settings(settings, self.proj)
  end
  
  function bridge:set_follow_playhead(enabled)
    self.engine.follow_playhead = enabled
    local settings = State.load_settings(self.proj)
    settings.follow_playhead = enabled
    State.save_settings(settings, self.proj)
  end
  
  function bridge:get_state()
    return self.engine:get_state()
  end
  
  return bridge
end

return M