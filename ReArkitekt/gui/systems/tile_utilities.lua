-- ReArkitekt/gui/systems/tile_utilities.lua

local M = {}

function M.format_bar_length(start_time, end_time, proj)
  proj = proj or 0
  
  
  local duration = end_time - start_time
  if duration <= 0 then
    reaper.ShowConsoleMsg(string.format("ERROR: duration <= 0 (%.3f)\n", duration))
    return "0.0.00"
  end
  
  local start_qn = reaper.TimeMap2_timeToQN(proj, start_time)
  local end_qn = reaper.TimeMap2_timeToQN(proj, end_time)
  local total_qn = end_qn - start_qn
  
  -- Debug first call only
  if not M._debug_printed then
    reaper.ShowConsoleMsg(string.format("Duration: %.3fs, QN: %.3f\n", duration, total_qn))
    M._debug_printed = true
  end
  
  if total_qn <= 0 then
    local bpm = reaper.Master_GetTempo()
    local _, time_sig_num = reaper.GetSetProjectGrid(proj, false)
    if not time_sig_num or time_sig_num == 0 then
      time_sig_num = 4
    end
    local beats_per_second = bpm / 60.0
    total_qn = duration * beats_per_second
  end
  
  local _, time_sig_num = reaper.TimeMap_GetTimeSigAtTime(proj, start_time)
  if not time_sig_num or time_sig_num == 0 then
    time_sig_num = 4
  end
  
  local bars = math.floor(total_qn / time_sig_num)
  local remaining_qn = total_qn - (bars * time_sig_num)
  local beats = math.floor(remaining_qn)
  local hundredths = math.floor((remaining_qn - beats) * 100)
  
  return string.format("%d.%d.%02d", bars, beats, hundredths)
end

return M