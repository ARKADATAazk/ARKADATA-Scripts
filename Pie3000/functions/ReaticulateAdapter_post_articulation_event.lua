--@noindex
--NoIndex: true

local r = reaper

local bankprogram = ARGUMENTS 

local editor = r.MIDIEditor_GetActive()
local msb, lsb, program, channel
local numbers = {}

for number in string.gmatch(bankprogram, "%d+") do
    table.insert(numbers, tonumber(number))
end

if numbers then
    msb, lsb, program, channel = numbers[1], numbers[2], numbers[3], numbers[4]
end


function InsertBankAndProgramChange(take, msb, lsb, program)
    local midiChannel = channel-1

    -- Get the item's start and end times in PPQ
    local item = r.GetMediaItemTake_Item(take)
    local itemStart = r.GetMediaItemInfo_Value(item, "D_POSITION")
    local itemEnd = itemStart + r.GetMediaItemInfo_Value(item, "D_LENGTH")
    local itemStartPPQ = r.MIDI_GetPPQPosFromProjTime(take, itemStart)
    local itemEndPPQ = r.MIDI_GetPPQPosFromProjTime(take, itemEnd)

    -- Initially, set the insertion position to the play cursor's position
    local cursorPosSec = r.GetCursorPositionEx(0)
    local insertPosPPQ = r.MIDI_GetPPQPosFromProjTime(take, cursorPosSec)

    -- Adjust the insertion position based on selected notes, if any
    local noteSelected = false
    local earliestNotePPQ = nil
    local _, noteCount = r.MIDI_CountEvts(take)
    for i = 0, noteCount - 1 do
        local retval, selected, _, startppqpos, _, _, _, _ = r.MIDI_GetNote(take, i)
        if retval and selected then
            noteSelected = true
            if earliestNotePPQ == nil or startppqpos < earliestNotePPQ then
                earliestNotePPQ = startppqpos
            end
        end
    end

    -- Use the earliest selected note's position if a note is selected; otherwise, use the play cursor position
    if noteSelected and earliestNotePPQ then
        insertPosPPQ = earliestNotePPQ
    end

    -- Check if the determined insertion position is within the item bounds
    if insertPosPPQ < itemStartPPQ or insertPosPPQ > itemEndPPQ then
        -- Outside the item bounds; do not insert anything
        return
    end

    -- Insert Bank Select MSB and LSB, and Program Change at the determined position

    r.MIDI_InsertCC(take, false, false, insertPosPPQ, 0xb0, midiChannel, 0, msb)
    r.MIDI_InsertCC(take, false, false, insertPosPPQ, 0xb0, midiChannel, 32, lsb)
    r.MIDI_InsertCC(take, false, false, insertPosPPQ, 0xc0, midiChannel, program, 0)

    -- Sort the MIDI take after inserting the events
    r.MIDI_Sort(take)
end


if editor then
    local take = r.MIDIEditor_GetTake(editor)
    if take and r.TakeIsMIDI(take) then
        InsertBankAndProgramChange(take, msb, lsb, program) -- MSB, LSB, Program Number
--[[     else
        r.ShowMessageBox("No valid MIDI take is selected.", "Error", 0) ]]
    end
--[[ else
    r.ShowMessageBox("No MIDI Editor is open.", "Error", 0) ]]
end

