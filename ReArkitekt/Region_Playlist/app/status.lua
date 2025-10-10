-- Region_Playlist/app/status.lua
-- Status bar configuration

local StatusBar = require("ReArkitekt.app.chrome.status_bar")

local M = {}

local function get_app_status(State)
  return function()
    local mode_text = State.state.layout_mode == 'horizontal' and "Timeline Mode" or "List Mode"
    
    local bridge_state = State.state.bridge:get_state()
    local status_text = "READY"
    
    if bridge_state.is_playing then
      local current_rid = State.state.bridge:get_current_rid()
      if current_rid then
        local region = State.state.region_index[current_rid]
        if region then
          local progress = State.state.bridge:get_progress() or 0
          local time_remaining = State.state.bridge:get_time_remaining()
          status_text = string.format("PLAYING: %s [%d/%d] %.0f%%", 
            region.name, 
            bridge_state.playlist_pointer, 
            #bridge_state.playlist_order,
            progress * 100)
          if time_remaining then
            status_text = status_text .. string.format(" - %.1fs", time_remaining)
          end
        end
      end
    end
    
    local quantize_text = bridge_state.quantize_mode or "none"
    if quantize_text ~= "none" then
      quantize_text = "Quantize: " .. quantize_text
    else
      quantize_text = "No quantize"
    end
    
    return {
      color = 0x41E0A3FF,
      text = status_text .. "  • " .. mode_text .. "  • " .. quantize_text .. "  • Space=Play  Arrows=Prev/Next  Q=Quantize",
      buttons = nil,
      right_buttons = nil,
    }
  end
end

function M.create(State, Style)
  return StatusBar.new({
    height = 34,
    get_status = get_app_status(State),
    style = Style and { palette = Style.palette } or nil
  })
end

return M