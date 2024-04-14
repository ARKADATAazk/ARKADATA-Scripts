--@noindex
--NoIndex: true

local r = reaper

-- Start an undo block
r.Undo_BeginBlock()

-- Get the active MIDI editor and declare variables for later use
local editor = r.MIDIEditor_GetActive()
local msb, lsb, program, channel

-- Parse the provided bank program arguments
local numbers = {}
local bankprogram = ARGUMENTS 
for number in string.gmatch(bankprogram, "%d+") do
    table.insert(numbers, tonumber(number))
end

if #numbers >= 4 then
    msb, lsb, program, channel = table.unpack(numbers)
end

-- Define the function to insert MIDI events
local function InsertBankAndProgramChange(take, msb, lsb, program, channel)
    local midiChannel = channel - 1
    local item = r.GetMediaItemTake_Item(take)
    local itemStart = r.GetMediaItemInfo_Value(item, "D_POSITION")
    local itemStartPPQ = r.MIDI_GetPPQPosFromProjTime(take, itemStart)
    local cursorPosSec = r.GetCursorPositionEx(0)
    local cursorPosPPQ = r.MIDI_GetPPQPosFromProjTime(take, cursorPosSec)

    -- Get the loop length in PPQ from the BR function
    local loopPPQ = r.BR_GetMidiSourceLenPPQ(take)
    local normalizedPosPPQ = (cursorPosPPQ - itemStartPPQ) % loopPPQ + itemStartPPQ

    local noteSelected = false
    local earliestNotePPQ = nil

    -- Find the earliest note position if any notes are selected
    local _, noteCount = r.MIDI_CountEvts(take)
    for i = 0, noteCount - 1 do
        local retval, selected, _, startppqpos = r.MIDI_GetNote(take, i)
        if retval and selected then
            noteSelected = true
            if not earliestNotePPQ or startppqpos < earliestNotePPQ then
                earliestNotePPQ = startppqpos
            end
        end
    end

    -- Use the position of the earliest selected note or the cursor position
    if noteSelected and earliestNotePPQ then
        normalizedPosPPQ = earliestNotePPQ
    end

    -- Insert MIDI events at the determined position
    r.MIDI_InsertCC(take, false, false, normalizedPosPPQ, 0xB0, midiChannel, 0, msb)
    r.MIDI_InsertCC(take, false, false, normalizedPosPPQ, 0xB0, midiChannel, 32, lsb)
    r.MIDI_InsertCC(take, false, false, normalizedPosPPQ, 0xC0, midiChannel, program, 0)
    r.MIDI_Sort(take)
end

-- Execute the function if a valid MIDI take is selected
if editor then
    local take = r.MIDIEditor_GetTake(editor)
    if take and r.TakeIsMIDI(take) then
        InsertBankAndProgramChange(take, msb, lsb, program, channel)
        r.Undo_OnStateChange2(0, "Insert Articulation Event")
    end
end

-- End the undo block
local undoPoint = "Insert MIDI CC Events"

