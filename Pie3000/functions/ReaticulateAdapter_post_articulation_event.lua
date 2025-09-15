--@noindex
--NoIndex: true

local r = reaper

-- Start an undo block
r.Undo_BeginBlock()

-- Get the active MIDI editor and declare variables for later use
local editor = r.MIDIEditor_GetActive()
local msb, lsb, program, mode, modeData

-- Parse the provided bank program arguments
local bankprogram = ARGUMENTS 
local parts = {}
for part in string.gmatch(bankprogram, "([^,]+)") do
    table.insert(parts, part)
end

if #parts >= 5 then
    msb = tonumber(parts[1])
    lsb = tonumber(parts[2]) 
    program = tonumber(parts[3])
    mode = parts[4] -- "CURSOR" or "EVENTS"
    modeData = parts[5] -- Channel number for CURSOR, or channel:ppq data for EVENTS
end

-- Function for cursor-based insertion (original behavior)
local function InsertAtCursor(take, msb, lsb, program, channel)
    local midiChannel = channel - 1
    local item = r.GetMediaItemTake_Item(take)
    local itemStart = r.GetMediaItemInfo_Value(item, "D_POSITION")
    local itemStartPPQ = r.MIDI_GetPPQPosFromProjTime(take, itemStart)
    local cursorPosSec = r.GetCursorPositionEx(0)
    local cursorPosPPQ = r.MIDI_GetPPQPosFromProjTime(take, cursorPosSec)

    local loopPPQ = r.BR_GetMidiSourceLenPPQ(take)
    local normalizedPosPPQ = (cursorPosPPQ - itemStartPPQ) % loopPPQ + itemStartPPQ

    r.MIDI_InsertCC(take, false, false, normalizedPosPPQ, 0xB0, midiChannel, 0, msb)
    r.MIDI_InsertCC(take, false, false, normalizedPosPPQ, 0xB0, midiChannel, 32, lsb)
    r.MIDI_InsertCC(take, false, false, normalizedPosPPQ, 0xC0, midiChannel, program, 0)
end

-- Function for event-based insertion (per-channel timing)
local function InsertAtEventPositions(take, msb, lsb, program, channelTimingData)
    local item = r.GetMediaItemTake_Item(take)
    local itemStart = r.GetMediaItemInfo_Value(item, "D_POSITION")
    local itemStartPPQ = r.MIDI_GetPPQPosFromProjTime(take, itemStart)
    local loopPPQ = r.BR_GetMidiSourceLenPPQ(take)
    
    for _, data in ipairs(channelTimingData) do
        local channel = data.channel
        local ppq = data.ppq
        local midiChannel = channel - 1 -- Convert to 0-based
        
        -- Normalize position within loop if needed
        local normalizedPosPPQ = (ppq - itemStartPPQ) % loopPPQ + itemStartPPQ
        
        r.MIDI_InsertCC(take, false, false, normalizedPosPPQ, 0xB0, midiChannel, 0, msb)
        r.MIDI_InsertCC(take, false, false, normalizedPosPPQ, 0xB0, midiChannel, 32, lsb)
        r.MIDI_InsertCC(take, false, false, normalizedPosPPQ, 0xC0, midiChannel, program, 0)
    end
end

-- Execute the appropriate function based on mode
if editor and msb and lsb and program and mode and modeData then
    local take = r.MIDIEditor_GetTake(editor)
    if take and r.TakeIsMIDI(take) then
        
        if mode == "CURSOR" then
            local channel = tonumber(modeData)
            if channel then
                InsertAtCursor(take, msb, lsb, program, channel)
                r.Undo_OnStateChange2(0, "Insert Articulation Event (cursor, CH" .. channel .. ")")
            end
            
        elseif mode == "EVENTS" then
            -- Parse channel:ppq data
            local channelTimingData = {}
            for channelPPQ in string.gmatch(modeData, "([^|]+)") do
                local channel, ppq = channelPPQ:match("(%d+):(%d+)")
                if channel and ppq then
                    table.insert(channelTimingData, {
                        channel = tonumber(channel),
                        ppq = tonumber(ppq)
                    })
                end
            end
            
            if #channelTimingData > 0 then
                InsertAtEventPositions(take, msb, lsb, program, channelTimingData)
                
                local channels = {}
                for _, data in ipairs(channelTimingData) do
                    table.insert(channels, tostring(data.channel))
                end
                r.Undo_OnStateChange2(0, "Insert Articulation Event (events, CH" .. table.concat(channels, ",") .. ")")
            end
        end
        
        r.MIDI_Sort(take)
    end
end

-- End the undo block
r.Undo_EndBlock("Insert MIDI CC Events", -1)