-- Helper Functions
local function calculateItemTimeOffset(item)
    local item_start_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local take = reaper.GetActiveTake(item)
    local take_start_offset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
    return item_start_pos - take_start_offset
end

local function calculate_tempo(pos1, pos2, beats)
    local time_diff = pos2 - pos1
    return time_diff > 0 and 60 / (time_diff / beats) or nil
end

local function get_measure_details(pos)
    local _, measure_number = reaper.TimeMap2_timeToBeats(0, pos)
    local measure_start_time = reaper.TimeMap2_beatsToTime(0, 0, measure_number)
    local next_measure_start_time = reaper.TimeMap2_beatsToTime(0, 0, measure_number + 1)
    return measure_start_time, next_measure_start_time, measure_number
end

local function calculate_distance(measure_time, pos)
    local epsilon = 1e-12
    local distance = math.abs(measure_time - pos)
    return distance < epsilon and 0 or distance
end

local function adjust_tempo(pos1, pos, current_tempo, beats_per_measure)
    local current_duration = pos - pos1
    local current_beats = current_duration * current_tempo / 60
    local target_measures = math.floor((current_beats / beats_per_measure) + 0.5)
    return (target_measures * beats_per_measure) * 60 / current_duration
end

-- Main Execution Block
local item = reaper.GetSelectedMediaItem(0, 0)
if not item or not reaper.GetActiveTake(item) then
    reaper.ShowMessageBox("Error: No item selected or active take found.", "Error", 0)
    return
end

local num_markers = reaper.GetNumTakeMarkers(reaper.GetActiveTake(item))
if num_markers < 3 then
    reaper.ShowMessageBox("Error: At least three markers are required.", "Error", 0)
    return
end

local offset_difference = calculateItemTimeOffset(item)
local pos1 = reaper.GetTakeMarker(reaper.GetActiveTake(item), 0) + offset_difference
local pos2 = reaper.GetTakeMarker(reaper.GetActiveTake(item), 1) + offset_difference
local initial_tempo = calculate_tempo(pos1, pos2, 4)
if not initial_tempo then
    reaper.ShowMessageBox("Error in tempo calculation", "Error", 0)
    return
end
reaper.SetCurrentBPM(0, initial_tempo, true)
reaper.ShowConsoleMsg(string.format("Marker 1-2 Tempo: %.4f\n\n",
                                   initial_tempo))


for i = 2, num_markers - 1 do
    local pos = reaper.GetTakeMarker(reaper.GetActiveTake(item), i) + offset_difference
    local previous_measure_start_time, next_measure_start_time, measure_number = get_measure_details(pos)
    local distance_to_previous_measure = calculate_distance(previous_measure_start_time, pos)
    local distance_to_next_measure = calculate_distance(next_measure_start_time, pos)
    local new_tempo = adjust_tempo(pos1, pos, initial_tempo, 4)
    reaper.SetCurrentBPM(0, new_tempo, true)

    -- Debug Output for each marker
    reaper.ShowConsoleMsg(string.format("Marker %d: Pos %.4f, New Tempo: %.4f\nPrevious Measure Start: %.4f, Distance: %.4f, Measure Number: %d\nNext Measure Start: %.4f, Distance: %.4f, Measure Number: %d\n\n",
                                        i, pos, new_tempo, previous_measure_start_time, distance_to_previous_measure, measure_number, next_measure_start_time, distance_to_next_measure, measure_number + 1))
end

reaper.UpdateArrange()
