--@noindex
--NoIndex: true


--This is ReaticulateAdapter specific, you wont need it 

local r = reaper

local channel = tonumber(ARGUMENTS) --r.GetExtState("PIE3000", "ActionArgument")

local channeltoextstate = tonumber(1)
if channel == 17 then channeltoextstate = 17
else channeltoextstate = tonumber(channel)
end


r.SetProjExtState(0, "ReaticulateAdapter", "Channel", tostring(channeltoextstate))


local channelActions = {
    [1] = 40218, -- Command for channel 1
    [2] = 40219, -- Command for channel 2
    [3] = 40220, -- Command for channel 3
    [4] = 40221, -- Command for channel 4
    [5] = 40222, -- Command for channel 5
    [6] = 40223, -- Command for channel 6
    [7] = 40224, -- Command for channel 7
    [8] = 40225, -- Command for channel 8
    [9] = 40226, -- Command for channel 9
    [10] = 40227, -- Command for channel 10
    [11] = 40228, -- Command for channel 11
    [12] = 40229, -- Command for channel 12
    [13] = 40230, -- Command for channel 13
    [14] = 40231, -- Command for channel 14
    [15] = 40232, -- Command for channel 15
    [16] = 40233, -- Command for channel 16
    [17] = 40217  -- Command for show all channels
}

local toggleFilterAction = 40504

function checkMIDIEditorFilterStatus()
    local commandID = 40504
    local midiEditorSectionID = 32060
    local state = reaper.GetToggleCommandStateEx(midiEditorSectionID, commandID)

    return state
end



function SetSelectedMIDIChannel(CH)
    if not r.MIDIEditor_GetActive() then return end
    local entryfilterState = checkMIDIEditorFilterStatus()
    local cmd_id = channelActions[CH]
    if cmd_id then
        r.MIDIEditor_OnCommand(r.MIDIEditor_GetActive(), cmd_id)
        if entryfilterState ~= checkMIDIEditorFilterStatus() then
            r.MIDIEditor_OnCommand(r.MIDIEditor_GetActive(), toggleFilterAction)
        end
    end
end

if channel then
    SetSelectedMIDIChannel(channel)
end