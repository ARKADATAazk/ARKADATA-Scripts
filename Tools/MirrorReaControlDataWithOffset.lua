-- Set the package path to include the directory of this script
local scriptPath = debug.getinfo(1, 'S').source:match [[^@?(.*[\/])[^\/]-$]]
package.path = package.path .. ";" .. scriptPath .. "?.lua"

-- Define a unique key for the toggle state
local toggle_key = "MirrorReaControlDataWithOffset_toggle"

-- Function to toggle the script on/off
function toggleScript()
    -- Get the current state from Reaper's ext state
    local state = reaper.GetExtState("MirrorReaControlDataWithOffset", toggle_key)

    if state == "on" then
        -- Script is currently running, so stop it
        reaper.SetExtState("MirrorReaControlDataWithOffset", toggle_key, "off", true)
        reaper.ShowConsoleMsg("MirrorReaControlDataWithOffset script stopped.\n")
    else
        -- Script is not running, so start it
        reaper.SetExtState("MirrorReaControlDataWithOffset", toggle_key, "on", true)
        reaper.ShowConsoleMsg("MirrorReaControlDataWithOffset script started.\n")
        main()
    end
end




-- User-defined minimum time between regular updates (in seconds)
local update_interval = 1.0 -- 1000 milliseconds = 1 second
local forced_update_interval = 5.0 -- 5000 milliseconds = 5 seconds

-- Initialize tables to store states and times for all tracks and parameters
local previous_states = {}
local last_update_times = {}
local last_forced_update_times = {}
local previous_offset_flags = {}
local previous_offsets = {}

-- Function to get the track's media playback offset in seconds
function getTrackPlaybackOffset(track)
    local offset_seconds = reaper.GetMediaTrackInfo_Value(track, "D_PLAY_OFFSET")
    local offset_enabled = reaper.GetMediaTrackInfo_Value(track, "I_PLAY_OFFSET_FLAG")
    if offset_enabled == 1.0 then
        return 0
    else
        return offset_seconds
    end
end

function findFXByName(track, fx_name)
    local fx_count = reaper.TrackFX_GetCount(track)
    for i = 0, fx_count - 1 do
        local retval, fx_name_out = reaper.TrackFX_GetFXName(track, i, "")
        if fx_name_out:find(fx_name) then
            return i
        end
    end
    return -1 -- FX not found
end

-- Function to serialize the envelope state into a string
function getEnvelopeState(envelope)
    local state = ""
    local point_count = reaper.CountEnvelopePoints(envelope)
    
    for i = 0, point_count - 1 do
        local retval, time, value, shape, tension, selected = reaper.GetEnvelopePoint(envelope, i)
        state = state .. time .. ":" .. value .. ":" .. shape .. ":" .. tension .. ";"
    end

    local num_items = reaper.CountAutomationItems(envelope)
    for i = 0, num_items - 1 do
        local item_point_count = reaper.CountEnvelopePointsEx(envelope, i)
        for j = 0, item_point_count - 1 do
            local retval, time, value, shape, tension, selected = reaper.GetEnvelopePointEx(envelope, i, j)
            state = state .. time .. ":" .. value .. ":" .. shape .. ":" .. tension .. ";"
        end
    end
    return state
end

-- Function to check if a point already exists at a given time
function pointExistsAtTime(envelope, time)
    local point_count = reaper.CountEnvelopePoints(envelope)
    for i = 0, point_count - 1 do
        local retval, pt_time = reaper.GetEnvelopePoint(envelope, i)
        if pt_time == time then
            return true
        end
    end
    return false
end

-- Function to delete all points in the True envelope
function deleteAllPointsInEnvelope(envelope)
    local point_count = reaper.CountEnvelopePoints(envelope)
    for i = point_count - 1, 0, -1 do
        reaper.DeleteEnvelopePointEx(envelope, -1, i)
    end
    reaper.Envelope_SortPoints(envelope) -- Commit the changes
end

-- Function to remove redundant points at the same time (optional safeguard)
function removeRedundantPoints(envelope)
    local point_count = reaper.CountEnvelopePoints(envelope)
    for i = point_count - 1, 1, -1 do
        local retval, time_i = reaper.GetEnvelopePoint(envelope, i)
        for j = i - 1, 0, -1 do
            local retval, time_j = reaper.GetEnvelopePoint(envelope, j)
            if time_i == time_j then
                reaper.DeleteEnvelopePointEx(envelope, -1, i)
                break
            end
        end
    end
    reaper.Envelope_SortPoints(envelope) -- Commit the changes
end

-- Function to copy envelope points from ReaGhostMIDI to ReaTrueMIDI
function copyEnvelope(envelope_ghost, envelope_true, track)
    deleteAllPointsInEnvelope(envelope_true)
    local time_offset = getTrackPlaybackOffset(track)
    local num_items = reaper.CountAutomationItems(envelope_ghost)

    for i = 0, num_items - 1 do
        local item_point_count = reaper.CountEnvelopePointsEx(envelope_ghost, i)
        for j = 0, item_point_count - 1 do
            local retval, time, value, shape, tension, selected = reaper.GetEnvelopePointEx(envelope_ghost, i, j)
            local new_time = time + time_offset
            if not pointExistsAtTime(envelope_true, new_time) then
                reaper.InsertEnvelopePoint(envelope_true, new_time, value, shape, tension, selected, true)
            end
        end
    end

    local point_count = reaper.CountEnvelopePoints(envelope_ghost)
    for i = 0, point_count - 1 do
        local retval, time, value, shape, tension, selected = reaper.GetEnvelopePoint(envelope_ghost, i)
        local new_time = time + time_offset
        if not pointExistsAtTime(envelope_true, new_time) then
            reaper.InsertEnvelopePoint(envelope_true, new_time, value, shape, tension, selected, true)
        end
    end

    reaper.Envelope_SortPoints(envelope_true)
    removeRedundantPoints(envelope_true)
end

function copyEnvelopeIfChanged(envelope_ghost, envelope_true, previous_state, track)
    local current_state = getEnvelopeState(envelope_ghost)
    if current_state ~= previous_state then
        copyEnvelope(envelope_ghost, envelope_true, track)
    end
    return current_state
end

function trackAllMatchingEnvelopes(track)
    local ghost_fx_index = findFXByName(track, "ReaGhostMIDI")
    local true_fx_index = findFXByName(track, "ReaTrueMIDI")

    if ghost_fx_index == -1 or true_fx_index == -1 then
        return -- Exit if either FX is not found
    end

    if not previous_states[track] then
        previous_states[track] = {}
        last_update_times[track] = {}
        last_forced_update_times[track] = {}
        previous_offset_flags[track] = {}
        previous_offsets[track] = {}
    end

    local current_time = reaper.time_precise()

    for paramIndex = 0, reaper.TrackFX_GetNumParams(track, ghost_fx_index) - 1 do
        local envelope_ghost = reaper.GetFXEnvelope(track, ghost_fx_index, paramIndex, false)
        local envelope_true = reaper.GetFXEnvelope(track, true_fx_index, paramIndex, false)

        if envelope_ghost then
            if not previous_states[track][paramIndex] then
                previous_states[track][paramIndex] = getEnvelopeState(envelope_ghost)
                last_update_times[track][paramIndex] = current_time
                last_forced_update_times[track][paramIndex] = current_time
                previous_offset_flags[track][paramIndex] = reaper.GetMediaTrackInfo_Value(track, "B_PLAY_OFFSET_FLAG")
                previous_offsets[track][paramIndex] = getTrackPlaybackOffset(track)
            end

            local create_and_copy = false
            if not envelope_true then
                envelope_true = reaper.GetFXEnvelope(track, true_fx_index, paramIndex, true)
                create_and_copy = true
            end

            local current_offset_flag = reaper.GetMediaTrackInfo_Value(track, "B_PLAY_OFFSET_FLAG")
            local current_offset = getTrackPlaybackOffset(track)

            if create_and_copy or current_offset_flag ~= previous_offset_flags[track][paramIndex] or current_offset ~= previous_offsets[track][paramIndex] then
                deleteAllPointsInEnvelope(envelope_true)
                copyEnvelope(envelope_ghost, envelope_true, track)
                previous_offset_flags[track][paramIndex] = current_offset_flag
                previous_offsets[track][paramIndex] = current_offset
            end

            if current_time - last_update_times[track][paramIndex] >= update_interval then
                previous_states[track][paramIndex] = copyEnvelopeIfChanged(envelope_ghost, envelope_true, previous_states[track][paramIndex], track)
                last_update_times[track][paramIndex] = current_time
            end

            if current_time - last_forced_update_times[track][paramIndex] >= forced_update_interval then
                deleteAllPointsInEnvelope(envelope_true)
                copyEnvelope(envelope_ghost, envelope_true, track)
                last_forced_update_times[track][paramIndex] = current_time
            end
        end
    end
end

function main()
    local track_count = reaper.CountTracks(0)
    for i = 0, track_count - 1 do
        local track = reaper.GetTrack(0, i)
        trackAllMatchingEnvelopes(track)
    end
    reaper.defer(main)
end

toggleScript()