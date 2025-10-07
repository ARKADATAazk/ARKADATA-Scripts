-- ReArkitekt/reaper/timing.lua
-- Time/QN conversion and quantization helpers

local M = {}

function M.time_to_qn(time, proj)
  proj = proj or 0
  return reaper.TimeMap2_timeToQN(proj, time)
end

function M.qn_to_time(qn, proj)
  proj = proj or 0
  return reaper.TimeMap_QNToTime(qn)
end

function M.get_tempo_at_time(time, proj)
  proj = proj or 0
  return reaper.TimeMap_GetDividedBpmAtTime(time)
end

function M.get_time_signature_at_time(time, proj)
  proj = proj or 0
  local _, num, denom = reaper.TimeMap_GetTimeSigAtTime(proj, time)
  return num, denom
end

function M.quantize_to_beat(time, proj, allow_backward)
  proj = proj or 0
  allow_backward = allow_backward == nil and true or allow_backward
  
  local qn = M.time_to_qn(time, proj)
  local next_beat_qn = math.ceil(qn)
  
  if not allow_backward and next_beat_qn <= qn then
    next_beat_qn = qn + 1
  end
  
  return M.qn_to_time(next_beat_qn, proj)
end

function M.quantize_to_bar(time, proj, allow_backward)
  proj = proj or 0
  allow_backward = allow_backward == nil and true or allow_backward
  
  local num, denom = M.get_time_signature_at_time(time, proj)
  local beats_per_bar = num or 4
  
  local qn = M.time_to_qn(time, proj)
  local current_bar = math.floor(qn / beats_per_bar)
  local next_bar_qn = (current_bar + 1) * beats_per_bar
  
  if allow_backward then
    local bar_start_qn = current_bar * beats_per_bar
    if math.abs(qn - bar_start_qn) < math.abs(qn - next_bar_qn) then
      next_bar_qn = bar_start_qn
    end
  end
  
  return M.qn_to_time(next_bar_qn, proj)
end

function M.quantize_to_grid(time, proj, allow_backward)
  proj = proj or 0
  allow_backward = allow_backward == nil and true or allow_backward
  
  local grid_div = reaper.GetSetProjectGrid(proj, false)
  if grid_div <= 0 then
    grid_div = 1.0
  end
  
  local qn = M.time_to_qn(time, proj)
  local grid_qn = qn / grid_div
  local next_grid_qn = math.ceil(grid_qn) * grid_div
  
  if not allow_backward and next_grid_qn <= qn then
    next_grid_qn = (grid_qn + 1) * grid_div
  end
  
  return M.qn_to_time(next_grid_qn, proj)
end

function M.calculate_next_transition(region_end, mode, max_lookahead, proj)
  proj = proj or 0
  max_lookahead = max_lookahead or 8.0
  
  local target_time
  
  if mode == "beat" then
    target_time = M.quantize_to_beat(region_end, proj, false)
  elseif mode == "bar" then
    target_time = M.quantize_to_bar(region_end, proj, false)
  elseif mode == "grid" then
    target_time = M.quantize_to_grid(region_end, proj, false)
  else
    target_time = region_end
  end
  
  if target_time - region_end > max_lookahead then
    target_time = region_end
  end
  
  return target_time
end

function M.get_beats_in_region(start_time, end_time, proj)
  proj = proj or 0
  local start_qn = M.time_to_qn(start_time, proj)
  local end_qn = M.time_to_qn(end_time, proj)
  return math.floor(end_qn - start_qn)
end

return M