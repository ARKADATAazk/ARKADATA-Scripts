-- ReArkitekt/reaper/transport.lua
-- REAPER transport control wrapper

local M = {}

function M.is_playing(proj)
  proj = proj or 0
  local state = reaper.GetPlayStateEx(proj)
  return (state & 1) == 1
end

function M.is_paused(proj)
  proj = proj or 0
  local state = reaper.GetPlayStateEx(proj)
  return (state & 2) == 2
end

function M.is_recording(proj)
  proj = proj or 0
  local state = reaper.GetPlayStateEx(proj)
  return (state & 4) == 4
end

function M.play(proj)
  proj = proj or 0
  if not M.is_playing(proj) then
    reaper.OnPlayButton()
  end
end

function M.stop(proj)
  proj = proj or 0
  if M.is_playing(proj) then
    reaper.OnStopButton()
  end
end

function M.pause(proj)
  proj = proj or 0
  if M.is_playing(proj) then
    reaper.OnPauseButton()
  end
end

function M.get_play_position(proj)
  proj = proj or 0
  return reaper.GetPlayPositionEx(proj)
end

function M.get_cursor_position(proj)
  proj = proj or 0
  return reaper.GetCursorPositionEx(proj)
end

function M.set_edit_cursor(pos, move_view, seek_play, proj)
  proj = proj or 0
  move_view = move_view == nil and true or move_view
  seek_play = seek_play == nil and true or seek_play
  reaper.SetEditCurPos2(proj, pos, move_view, seek_play)
end

function M.get_project_length(proj)
  proj = proj or 0
  return reaper.GetProjectLength(proj)
end

function M.get_project_state_change_count(proj)
  proj = proj or 0
  return reaper.GetProjectStateChangeCount(proj)
end

function M.update_timeline()
  reaper.UpdateTimeline()
end

function M.get_pdc_offset()
  local offset_samples = reaper.GetOutputLatency()
  local srate = reaper.GetSampleRate()
  return offset_samples / srate
end

return M