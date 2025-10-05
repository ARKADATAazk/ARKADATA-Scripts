-- ReArkitekt/gui/systems/tile_utilities.lua
-- Shared utility functions for tile rendering

local M = {}

-- Format time in seconds to REAPER-style bars.beats.ticks notation
-- seconds: duration in seconds
-- project_bpm: tempo in beats per minute (default: 120)
-- project_time_sig_num: numerator of time signature (default: 4)
-- Returns: string in format "bars.beats.ticks" (e.g., "2.3.480")
function M.format_bar_length(seconds, project_bpm, project_time_sig_num)
  project_bpm = project_bpm or 120
  project_time_sig_num = project_time_sig_num or 4
  
  local beats_per_bar = project_time_sig_num
  local seconds_per_beat = 60.0 / project_bpm
  local seconds_per_bar = seconds_per_beat * beats_per_bar
  
  local total_beats = seconds / seconds_per_beat
  local bars = math.floor(total_beats / beats_per_bar)
  local remaining_beats = math.floor(total_beats % beats_per_bar)
  local remaining_ticks = math.floor(((total_beats % 1.0) * 960) + 0.5)
  
  return string.format("%d.%d.%02d", bars, remaining_beats, remaining_ticks)
end

return M