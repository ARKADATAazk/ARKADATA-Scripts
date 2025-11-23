-- @description ReaticulateAdapter - Pie3000 Addon
-- @author ARKADATA
-- @donation https://www.paypal.com/donate/?hosted_button_id=2FP22TUPGFPSJ
-- @website https://www.arkadata.com
-- @license GPL v3
-- @version 1.6.0
-- @changelog
--   FIX: Now support "Clone" entries on Reabank files (use to reference an articulation group without rewriting it)
-- @about
--   # ReaticulateAdapter
--   
--   Script that connects "Reaticulate" to "Pie Menu 3000", allowing for dynamic generation of an articulations pie menu depending on active bank.  
--   Also generates a channel/available banks menu, it'll default to this one if there is no active bank. Can also be bind to have quick access to other MIDI Channels and their respective banks.
--   ### Prerequisites
--   **Reaticulate** and **Pie Menu 3000**
-- @provides
--   ReaticulateAdapter.lua
--   [main=main,midi_editor] ReaticulateAdapter_Pie3000_Addon_Articulations.lua
--   [main=main,midi_editor] ReaticulateAdapter_Pie3000_Addon_BanksXChannels.lua
--   functions/*.lua
--   AddonPieGenerator.lua
--   Utils.lua
--   lib/*.lua

local scriptPath = debug.getinfo(1, 'S').source:match [[^@?(.*[\/])[^\/]-$]]
package.path = package.path ..
    ";" .. scriptPath .. "lib/?.lua" .. ";"  .. scriptPath .. "?.lua"

local r = reaper

require "Utils"
local json = require('json')
local jsonBeautify = require('json-beautify')
local addonPieGenerator = require('AddonPieGenerator')

local pieGUID = "ReaticulateAdapter"

local activeBank = ""
local activeChannel = 1

-- Global debug control
local DEBUG_ENABLED = false
local DEBUG_FILE = reaper.GetResourcePath() .. "/Scripts/debug_reaticulate_adapter.txt"

-- Enhanced debug function that writes to both console and file
function DebugLog(message)
    if not DEBUG_ENABLED then return end
    
    -- Write to console
    reaper.ShowConsoleMsg(message)
    
    -- Write to file
    local file = io.open(DEBUG_FILE, "a")
    if file then
        file:write(os.date("%H:%M:%S") .. " - " .. message)
        file:close()
    end
end

-- Clear debug file at startup
if DEBUG_ENABLED then
    local file = io.open(DEBUG_FILE, "w")
    if file then
        file:write("=== DEBUG LOG START ===\n")
        file:close()
    end
    DebugLog("DEBUG: Debug file created at: " .. DEBUG_FILE .. "\n")
end

local debuglog, extendedDebugLog = false, false
local _, extstate = reaper.GetProjExtState(0, "ReaticulateAdapter", "Channel")
local extstatechannel = tonumber(extstate)

-- Helper function to safely convert userdata to numbers
function SafeToNumber(value, default)
    if type(value) == "number" then
        return value
    elseif type(value) == "string" then
        local num = tonumber(value)
        if num then return num end
    elseif type(value) == "userdata" then
        -- Try multiple methods to extract number from userdata
        local str = tostring(value)
        local num = tonumber(str)
        if num then return num end
        
        -- Try extracting number from string representation
        num = tonumber(str:match("([%d%.%-]+)"))
        if num then return num end
        
        -- Try mathematical operations to force conversion
        local success, result = pcall(function() return math.floor(value + 0) end)
        if success and type(result) == "number" then
            return result
        end
    end
    
    if default ~= nil then
        DebugLog("WARNING: Could not convert " .. type(value) .. " to number, using default: " .. tostring(default) .. "\n")
        return default
    end
    return nil
end

-- Get selected events grouped by channel with their earliest time positions
function GetSelectedEventsWithChannelsAndTiming()
    DebugLog("DEBUG: Starting GetSelectedEventsWithChannelsAndTiming\n")
    
    if not MIDIEDITOR then 
        DebugLog("DEBUG: No MIDI editor in GetSelectedEventsWithChannelsAndTiming\n")
        return {} 
    end
    
    local take = r.MIDIEditor_GetTake(MIDIEDITOR)
    if not take or not r.TakeIsMIDI(take) then 
        DebugLog("DEBUG: No valid MIDI take in GetSelectedEventsWithChannelsAndTiming\n")
        return {} 
    end
    
    local channelData = {} -- {channel = {earliest_ppq, events_count}}
    local _, noteCount = r.MIDI_CountEvts(take)
    
    DebugLog("DEBUG: Total notes in take: " .. noteCount .. "\n")
    
    -- Check selected notes
    for i = 0, noteCount - 1 do
        local retval, selected, _, startppqpos, _, channel = r.MIDI_GetNote(take, i)
        if retval and selected then
            local midiChannel = SafeToNumber(channel, 0) + 1 -- Convert to 1-based
            local startppqNum = SafeToNumber(startppqpos, 0)
            
            DebugLog("DEBUG: Found selected note on channel " .. midiChannel .. " at PPQ " .. startppqNum .. "\n")
            
            if not channelData[midiChannel] then
                channelData[midiChannel] = {earliest_ppq = startppqNum, count = 1}
                DebugLog("DEBUG: First note for channel " .. midiChannel .. "\n")
            else
                channelData[midiChannel].count = channelData[midiChannel].count + 1
                if startppqNum < channelData[midiChannel].earliest_ppq then
                    DebugLog("DEBUG: New earliest PPQ for channel " .. midiChannel .. ": " .. startppqNum .. " (was " .. channelData[midiChannel].earliest_ppq .. ")\n")
                    channelData[midiChannel].earliest_ppq = startppqNum
                end
            end
        end
    end
    
    -- Check selected CCs as well
    local _, ccCount = r.MIDI_CountEvts(take)
    for i = 0, ccCount - 1 do
        local retval, selected, _, ppqpos, _, _, channel = r.MIDI_GetCC(take, i)
        if retval and selected then
            local midiChannel = SafeToNumber(channel, 0) + 1 -- Convert to 1-based
            local ppqNum = SafeToNumber(ppqpos, 0)
            
            DebugLog("DEBUG: Found selected CC on channel " .. midiChannel .. " at PPQ " .. ppqNum .. "\n")
            
            if not channelData[midiChannel] then
                channelData[midiChannel] = {earliest_ppq = ppqNum, count = 1}
            else
                channelData[midiChannel].count = channelData[midiChannel].count + 1
                if ppqNum < channelData[midiChannel].earliest_ppq then
                    channelData[midiChannel].earliest_ppq = ppqNum
                end
            end
        end
    end
    
    local channelCount = 0
    for channel, data in pairs(channelData) do
        channelCount = channelCount + 1
        DebugLog("DEBUG: Channel " .. channel .. " has " .. data.count .. " selected events, earliest at PPQ " .. data.earliest_ppq .. "\n")
    end
    DebugLog("DEBUG: GetSelectedEventsWithChannelsAndTiming found " .. channelCount .. " channels with selected events\n")
    
    return channelData
end

-- Get channels from selected events
function GetSelectedEventsChannels()
    DebugLog("DEBUG: Starting GetSelectedEventsChannels\n")
    
    local channelData = GetSelectedEventsWithChannelsAndTiming()
    local channels = {}
    for channel, _ in pairs(channelData) do
        table.insert(channels, channel)
        DebugLog("DEBUG: Found selected events on channel: " .. channel .. "\n")
    end
    table.sort(channels) -- Sort for consistent ordering
    
    DebugLog("DEBUG: GetSelectedEventsChannels returning: " .. table.concat(channels, ",") .. "\n")
    
    return channels
end

-- Determine which banks are represented by selected events
function GetBanksForSelectedChannels(appdata)
    if not appdata or not appdata.banks then return {} end
    
    local selectedChannels = GetSelectedEventsChannels()
    local banksByChannel = {}
    
    for _, channel in ipairs(selectedChannels) do
        for _, bank in ipairs(appdata.banks) do
            if bank.src == channel or bank.src == 17 then -- Include OMNI
                banksByChannel[channel] = bank.name
                break
            end
        end
    end
    
    return banksByChannel
end

-- Determine if all selected channels use the same bank (or OMNI)
function DoSelectedChannelsShareBank(appdata)
    DebugLog("DEBUG: Starting DoSelectedChannelsShareBank\n")
    
    if not appdata then 
        DebugLog("DEBUG: No appdata provided\n")
        return false, nil 
    end
    
    local banksByChannel = GetBanksForSelectedChannels(appdata)
    local channels = GetSelectedEventsChannels()
    
    DebugLog("DEBUG: Channels to check: " .. table.concat(channels, ",") .. "\n")
    for channel, bank in pairs(banksByChannel) do
        DebugLog("DEBUG: Channel " .. channel .. " uses bank: " .. bank .. "\n")
    end
    
    if #channels == 0 then 
        DebugLog("DEBUG: No channels found\n")
        return false, nil 
    end
    
    if #channels == 1 then 
        DebugLog("DEBUG: Single channel, returning bank: " .. tostring(banksByChannel[channels[1]]) .. "\n")
        return true, banksByChannel[channels[1]] 
    end
    
    -- Check if there's an OMNI bank that covers all channels
    for _, bank in ipairs(appdata.banks) do
        if bank.src == 17 then
            DebugLog("DEBUG: Found OMNI bank: " .. bank.name .. "\n")
            return true, bank.name -- OMNI covers all
        end
    end
    
    -- Check if all selected channels have the same bank
    local firstBank = banksByChannel[channels[1]]
    if not firstBank then 
        DebugLog("DEBUG: No bank found for first channel " .. channels[1] .. "\n")
        return false, nil 
    end
    
    DebugLog("DEBUG: First bank: " .. firstBank .. "\n")
    
    for i = 2, #channels do
        DebugLog("DEBUG: Comparing channel " .. channels[i] .. " bank '" .. tostring(banksByChannel[channels[i]]) .. "' with first bank '" .. firstBank .. "'\n")
        
        if banksByChannel[channels[i]] ~= firstBank then
            DebugLog("DEBUG: Banks don't match - different banks detected\n")
            return false, nil
        end
    end
    
    DebugLog("DEBUG: All channels share the same bank: " .. firstBank .. "\n")
    
    return true, firstBank
end

-- ENHANCED: Note-length-aware cursor detection with SWS compatibility
function GetChannelFromClosestSelectedNote()
    DebugLog("DEBUG: Starting GetChannelFromClosestSelectedNote with enhanced note-length-aware detection\n")
    
    if not MIDIEDITOR then 
        DebugLog("DEBUG: No MIDI editor active\n")
        return nil 
    end
    
    local take = r.MIDIEditor_GetTake(MIDIEDITOR)
    if not take or not r.TakeIsMIDI(take) then 
        DebugLog("DEBUG: No valid MIDI take\n")
        return nil 
    end
    
    local mouseData = {}
    local detectionMethod = "Unknown"
    
    -- Method 1: SWS Extension with VERSION COMPATIBILITY handling
    if r.BR_GetMouseCursorContext_Position and r.BR_GetMouseCursorContext_MIDI then
        local context = r.BR_GetMouseCursorContext and r.BR_GetMouseCursorContext() or ""
        DebugLog("DEBUG: Mouse context: '" .. tostring(context) .. "'\n")
        
        if context == "midi_editor" or context:find("midi") then
            local mouseTime = r.BR_GetMouseCursorContext_Position()
            
            -- DETECT SWS VERSION COMPATIBILITY (SWS 2.8.3 has a bug)
            -- Test the function signature to determine which version we have
            local testParam1, testParam2, testParam3, testParam4, testParam5, testParam6 = r.BR_GetMouseCursorContext_MIDI()
            local isSWS283 = (type(testParam1) == "number" and testParam6 == nil)
            
            DebugLog("DEBUG: SWS compatibility test - param1 type: " .. type(testParam1) .. ", param6: " .. tostring(testParam6) .. "\n")
            DebugLog("DEBUG: Detected SWS 2.8.3 compatibility mode: " .. tostring(isSWS283) .. "\n")
            
            local inlineEditor, noteRow, ccLane, ccLaneVal, ccLaneId
            
            if isSWS283 then
                -- SWS 2.8.3 buggy version: different signature
                -- Returns: noteRow, ccLane, ccLaneVal, ccLaneId, ? (5 values, no MIDI editor, no inlineEditor)
                noteRow, ccLane, ccLaneVal, ccLaneId = testParam1, testParam2, testParam3, testParam4
                inlineEditor = false -- Not available in buggy version
                DebugLog("DEBUG: Using SWS 2.8.3 compatibility mode\n")
            else
                -- Normal SWS version: correct signature  
                -- Returns: midiEditor, inlineEditor, noteRow, ccLane, ccLaneVal, ccLaneId (6 values)
                local midiEditor = testParam1
                inlineEditor, noteRow, ccLane, ccLaneVal, ccLaneId = testParam2, testParam3, testParam4, testParam5, testParam6
                DebugLog("DEBUG: Using normal SWS version\n")
            end
            
            DebugLog("DEBUG: SWS raw values - time: " .. type(mouseTime) .. ", noteRow: " .. tostring(noteRow) .. " (type: " .. type(noteRow) .. ")\n")
            DebugLog("DEBUG: SWS MIDI context - inlineEditor: " .. tostring(inlineEditor) .. ", ccLane: " .. tostring(ccLane) .. ", ccLaneVal: " .. tostring(ccLaneVal) .. "\n")
            
            -- Convert time
            local mouseTimeNum = SafeToNumber(mouseTime)
            
            -- CORRECT: noteRow is the actual pitch value (0-127)
            local mousePitchNum = SafeToNumber(noteRow)
            
            -- Validate pitch range (0-127 for MIDI)
            if mousePitchNum and (mousePitchNum < 0 or mousePitchNum > 127) then
                DebugLog("WARNING: Pitch out of MIDI range: " .. mousePitchNum .. ", ignoring\n")
                mousePitchNum = nil
            end
            
            DebugLog("DEBUG: Final converted values - time: " .. tostring(mouseTimeNum) .. ", pitch: " .. tostring(mousePitchNum) .. "\n")
            
            -- Check if we got valid time
            if mouseTimeNum and mouseTimeNum > 0 then
                mouseData.time = mouseTimeNum
                mouseData.pitch = mousePitchNum
                mouseData.ppq = r.MIDI_GetPPQPosFromProjTime(take, mouseTimeNum)
                
                if mousePitchNum then
                    detectionMethod = "SWS_Enhanced2D"  -- TRUE 2D + NOTE LENGTH DETECTION!
                    DebugLog("SUCCESS: Using ENHANCED 2D SWS detection (note-length-aware) - PPQ: " .. tostring(mouseData.ppq) .. ", Pitch: " .. mousePitchNum .. "\n")
                else
                    detectionMethod = "SWS_TimeOnly"
                    DebugLog("DEBUG: Using SWS time-only detection - PPQ: " .. tostring(mouseData.ppq) .. "\n")
                end
            else
                DebugLog("DEBUG: SWS returned invalid values, trying fallbacks\n")
            end
        else
            DebugLog("DEBUG: Not in MIDI editor context, trying fallbacks\n")
        end
    else
        DebugLog("DEBUG: SWS functions not available, trying fallbacks\n")
    end
    
    -- Method 2: Fallback to Edit Cursor Position
    if not mouseData.time then
        local cursorPos = r.GetCursorPosition()
        if cursorPos >= 0 then
            mouseData.time = cursorPos
            mouseData.ppq = r.MIDI_GetPPQPosFromProjTime(take, cursorPos)
            mouseData.pitch = nil -- No pitch info from edit cursor
            detectionMethod = "EditCursor"
            DebugLog("DEBUG: Using edit cursor fallback, time: " .. tostring(cursorPos) .. ", PPQ: " .. tostring(mouseData.ppq) .. "\n")
        end
    end
    
    -- Method 3: Fallback to Time Selection Center
    if not mouseData.time then
        local startTime, endTime = r.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)
        if startTime ~= endTime then
            local centerTime = (startTime + endTime) / 2
            mouseData.time = centerTime
            mouseData.ppq = r.MIDI_GetPPQPosFromProjTime(take, centerTime)
            mouseData.pitch = nil
            detectionMethod = "TimeSelection"
            DebugLog("DEBUG: Using time selection center fallback, time: " .. tostring(centerTime) .. ", PPQ: " .. tostring(mouseData.ppq) .. "\n")
        end
    end
    
    -- Method 4: Last resort - use first selected note's position
    if not mouseData.time then
        local _, noteCount = r.MIDI_CountEvts(take)
        for i = 0, noteCount - 1 do
            local retval, selected, _, startppq, _, _, _ = r.MIDI_GetNote(take, i)
            if retval and selected then
                mouseData.ppq = startppq
                mouseData.time = r.MIDI_GetProjTimeFromPPQPos(take, startppq)
                mouseData.pitch = nil
                detectionMethod = "FirstSelectedNote"
                DebugLog("DEBUG: Using first selected note fallback, PPQ: " .. tostring(startppq) .. "\n")
                break
            end
        end
    end
    
    if not mouseData.ppq then
        DebugLog("DEBUG: Could not determine any reference position\n")
        return nil
    end
    
    DebugLog("DEBUG: Final detection method: " .. detectionMethod .. "\n")
    DebugLog("DEBUG: Reference PPQ: " .. tostring(mouseData.ppq) .. ", Pitch: " .. tostring(mouseData.pitch) .. "\n")
    
    -- Find closest selected note using 2D distance when possible
    local closestNote = nil
    local closestDistance = math.huge
    local _, noteCount = r.MIDI_CountEvts(take)
    local selectedNotesCount = 0
    
    DebugLog("DEBUG: Total notes in take: " .. noteCount .. "\n")
    
    for i = 0, noteCount - 1 do
        local retval, selected, _, startppqpos, endppqpos, channel, pitch, vel = r.MIDI_GetNote(take, i)
        if retval and selected then
            selectedNotesCount = selectedNotesCount + 1
            local midiChannel = SafeToNumber(channel, 0) + 1
            local pitchNum = SafeToNumber(pitch, 0)
            local velNum = SafeToNumber(vel, 127)
            local startppqNum = SafeToNumber(startppqpos, 0)
            local endppqNum = SafeToNumber(endppqpos, 0)  -- FIXED: Properly convert end position
            
            DebugLog("DEBUG: Note #" .. selectedNotesCount .. " - channel: " .. midiChannel .. ", pitch: " .. pitchNum .. ", vel: " .. velNum .. "\n")
            DebugLog("DEBUG: Note #" .. selectedNotesCount .. " - start PPQ: " .. startppqNum .. ", end PPQ: " .. endppqNum .. ", length: " .. (endppqNum - startppqNum) .. "\n")
            
            -- Calculate distance based on detection method
            local distance
            
            -- ENHANCED: Calculate time distance considering full note length
            local timeDiff
            if mouseData.ppq >= startppqNum and mouseData.ppq <= endppqNum then
                -- Mouse cursor is WITHIN the note's time range - perfect hit!
                timeDiff = 0
                DebugLog("DEBUG: Note #" .. selectedNotesCount .. " CH" .. midiChannel .. " - CURSOR WITHIN NOTE RANGE (PPQ " .. startppqNum .. "-" .. endppqNum .. ")\n")
            else
                -- Mouse cursor is OUTSIDE the note's time range
                if mouseData.ppq < startppqNum then
                    -- Before note start
                    timeDiff = (startppqNum - mouseData.ppq) / 480.0
                    DebugLog("DEBUG: Note #" .. selectedNotesCount .. " CH" .. midiChannel .. " - Cursor BEFORE note (distance: " .. string.format("%.3f", timeDiff) .. ")\n")
                else
                    -- After note end  
                    timeDiff = (mouseData.ppq - endppqNum) / 480.0
                    DebugLog("DEBUG: Note #" .. selectedNotesCount .. " CH" .. midiChannel .. " - Cursor AFTER note (distance: " .. string.format("%.3f", timeDiff) .. ")\n")
                end
            end

            if detectionMethod == "SWS_Enhanced2D" and mouseData.pitch then
                -- TRUE 2D DISTANCE CALCULATION WITH NOTE LENGTH!
                local pitchDiff = math.abs(mouseData.pitch - pitchNum) / 127.0  -- Normalize to full range
                
                -- Weighted 2D distance (you can adjust weights)
                local timeWeight = 1.0    -- How important time proximity is
                local pitchWeight = 0.8   -- How important pitch proximity is
                
                distance = math.sqrt((timeDiff * timeWeight)^2 + (pitchDiff * pitchWeight)^2)
                
                DebugLog("DEBUG: Note #" .. selectedNotesCount .. " CH" .. midiChannel .. " ENHANCED 2D - Time diff: " .. string.format("%.3f", timeDiff) .. 
                        ", Pitch diff: " .. string.format("%.3f", pitchDiff) .. ", Distance: " .. string.format("%.3f", distance) .. "\n")
            else
                -- Fallback to time-only detection with note length awareness
                distance = timeDiff
                
                -- Add slight preference for higher velocity notes when distances are very close
                if timeDiff < 0.1 then -- If very close in time
                    local velocityBonus = (127 - velNum) / 127.0 * 0.01 -- Small bonus for higher velocity
                    distance = distance + velocityBonus
                end
                
                -- Add slight preference for middle pitches when time-only detection
                if detectionMethod == "SWS_TimeOnly" or detectionMethod == "EditCursor" then
                    local pitchFromMiddle = math.abs(64 - pitchNum) / 127.0 * 0.05 -- Small bonus for middle pitches
                    distance = distance + pitchFromMiddle
                end
                
                DebugLog("DEBUG: Note #" .. selectedNotesCount .. " CH" .. midiChannel .. " Enhanced Time-only - Distance: " .. string.format("%.3f", distance) .. "\n")
            end
            
            if distance < closestDistance then
                closestDistance = distance
                closestNote = {
                    channel = midiChannel,
                    startppq = startppqNum,
                    pitch = pitchNum,
                    velocity = velNum,
                    distance = distance,
                    method = detectionMethod
                }
                DebugLog("DEBUG: New closest note found - Channel: " .. midiChannel .. ", Distance: " .. string.format("%.3f", distance) .. "\n")
            end
        end
    end
    
    DebugLog("DEBUG: Total selected notes found: " .. selectedNotesCount .. "\n")
    if closestNote then
        DebugLog("DEBUG: Final closest note - Channel: " .. closestNote.channel .. 
                ", Method: " .. closestNote.method .. 
                ", Distance: " .. string.format("%.3f", closestNote.distance) .. "\n")
    else
        DebugLog("DEBUG: No closest note found\n")
    end
    
    return closestNote and closestNote.channel or nil
end

function ReaticulateAdapter(MenuType)
    DebugLog("\n=== DEBUG: Starting ReaticulateAdapter with MenuType: " .. tostring(MenuType) .. " ===\n")
    
    if not CheckMIDIEditorIsActive() then 
        DebugLog("DEBUG: No active MIDI editor\n")
        return handleNoNoActiveMIDIEditorTrack() 
    end
    
    -- First, get the basic active channel
    activeChannel = GetActiveMIDIChannelInMIDIEditor()
    
    DebugLog("DEBUG: Active MIDI channel: " .. activeChannel .. "\n")
    
    local appdata = FetchReaticulateAppDataOnActiveTrack()
    
    if appdata then
        DebugLog("DEBUG: Reaticulate app data found with " .. (#appdata.banks or 0) .. " banks\n")
    else
        DebugLog("DEBUG: No Reaticulate app data found\n")
    end
    
    local reabankData, otherBanksChannels = FilterAndProcessBanks(appdata)

    if MenuType == "Main" then
        if appdata == nil then 
            DebugLog("DEBUG: No appdata, showing predefined Reaticulate\n")
            return handlePredefinedReaticulate() 
        end
        if not reabankData then
            DebugLog("DEBUG: No reabank data, showing banks menu\n")
            return handleBanks(otherBanksChannels)
        end
        DebugLog("DEBUG: Showing articulations menu\n")
        return handleArticulations(reabankData)
    elseif MenuType == "Banks" then
        return handleBanks(otherBanksChannels)
    else
        return handlePredefinedReaticulate()
    end
end

function handleNoNoActiveMIDIEditorTrack()
    local pie = addonPieGenerator.createPie("Open MIDI Editor", pieGUID, {})
    return pie
end

function handleNoReaticulate()
    local pie = addonPieGenerator.createPie("No Reaticulate Data", pieGUID, {})
    return pie
end

function handlePredefinedReaticulate()
    local entries = {
        {name = "Open/Close Reaticulate", col = 255, cmd_name = "Script: Reaticulate_Main.lua"}
    }

    -- Create a pie with predefined entries
    local pie = addonPieGenerator.createPie("Reaticulate Options", "ReaticulateAdapter", {})
    for i, entryData in ipairs(entries) do
        table.insert(pie, {
            func = entryData.func or nil,
            name = entryData.name or "IssueWithEntryData.name",
            argument = entryData.argument or "",
            cmd_name = entryData.cmd_name or "",
            col = entryData.col or 255,
            toggle_state = entryData.toggle_state or false
        })
    end
    return pie
end

-- Enhanced handleArticulations with proper channel and timing data
function handleArticulations(data)
    local selectedChannels = GetSelectedEventsChannels()
    local channelData = GetSelectedEventsWithChannelsAndTiming()
    local hasSelection = #selectedChannels > 0
    
    -- Determine which channels should actually receive this articulation
    local targetChannels = {}
    local targetChannelData = {}
    
    if hasSelection then
        local appdata = FetchReaticulateAppDataOnActiveTrack()
        local sharedBank, bankName = DoSelectedChannelsShareBank(appdata)
        
        if sharedBank then
            -- All channels share the same bank - use all selected channels
            targetChannels = selectedChannels
            targetChannelData = channelData
        else
            -- Different banks - only use channels that match the current bank being shown
            if appdata and appdata.banks then
                for channel, timingData in pairs(channelData) do
                    for _, bank in ipairs(appdata.banks) do
                        if (bank.src == channel or bank.src == 17) and bank.name == activeBank then
                            table.insert(targetChannels, channel)
                            targetChannelData[channel] = timingData
                            break
                        end
                    end
                end
            end
        end
        
        -- Sort target channels for consistent display
        table.sort(targetChannels)
    end
    
    -- Create title with clear indication of what will be affected
    local titleSuffix = ""
    if hasSelection then
        if #selectedChannels > 1 then
            if #targetChannels == #selectedChannels then
                titleSuffix = " (Events: CH" .. table.concat(selectedChannels, ",") .. ")"
            else
                titleSuffix = " (Events: CH" .. table.concat(selectedChannels, ",") .. " → affecting CH" .. table.concat(targetChannels, ",") .. ")"
            end
        else
            titleSuffix = " (Events: CH" .. selectedChannels[1] .. ")"
        end
    else
        titleSuffix = " (Cursor: CH" .. activeChannel .. ")"
    end
    
    local pie = addonPieGenerator.createPie(activeBank .. titleSuffix, pieGUID, data.articulations)
    local MSB_LSB = { string.match(data.bank, "(%d+) (%d+)") }
    
    for i, articulation in ipairs(data.articulations) do
        local parts = { string.match(articulation, "(%d+) (.*)") }
        
        -- Create argument based on whether we have selected events or not
        local argument
        if hasSelection and #targetChannels > 0 then
            -- Use only the channels that should receive this articulation
            local channelTimingData = {}
            for channel, timingData in pairs(targetChannelData) do
                channelTimingData[#channelTimingData + 1] = channel .. ":" .. timingData.earliest_ppq
            end
            argument = table.concat({ MSB_LSB[1], MSB_LSB[2], parts[1], "EVENTS", table.concat(channelTimingData, "|") }, ",")
        else
            -- Use cursor position with active channel
            argument = table.concat({ MSB_LSB[1], MSB_LSB[2], parts[1], "CURSOR", activeChannel }, ",")
        end
        
        table.insert(pie, {
            name = table.concat(parts, " ", 2),
            func = "R3000_PostArticulationEvent",
            argument = argument,
            col = getColorForArticulation(data.articulationslook[i]),
            toggle_state = false,
        })
    end
    return pie
end

function handleBanks(data)
    -- Default pie title; check if data actually has a 'bank' property if needed, or set a default title
    local pie = addonPieGenerator.createPie("Switch to Channel/Bank", pieGUID, data)
    for i, channelInfo in ipairs(data) do
        local toggleState = extstatechannel == channelInfo.channel
        local bankName = channelInfo.bank ~= "" and channelInfo.bank or ""
        local pieEntry = {
            name = formatTo00Size(channelInfo.channel) .. " " .. bankName,
            func = "R3000_SwitchBank",
            argument = tostring(channelInfo.channel),
            col = getColorForChannel(channelInfo.channel) or hexToDec("#dea53b"),
            toggle_state = toggleState,
        }
        -- Optionally, you could decide to disable or alter the function/behavior for channels with no bank
        if bankName == "Empty" then
            pieEntry.func = "R3000_SwitchBank"
            pieEntry.col = 255 -- Grey out or some indication
        end
        table.insert(pie, pieEntry)
    end
    return pie
end

function FetchReaticulateAppDataOnActiveTrack()
    local activeTrack = GetActiveTrackInMIDIEditor() or reaper.GetSelectedTrack(0, 0)
    if not activeTrack then return end
    local retval, data = r.GetSetMediaTrackInfo_String(activeTrack, 'P_EXT:reaticulate', '', false) -- Access Reaticulate's stored track data
    if not retval or data == '' then return end
    local version = data:sub(1, 1)
    if version ~= '2' then return end
    local jsonData = data:sub(2)
    local beautifiedJson = jsonBeautify.beautify(json.decode(jsonData))
    if debuglog then
        DebugLog("Reaticulate appdata found (version " ..
            version .. "):\n" .. beautifiedJson .. "\n")
    end
    return json.decode(jsonData)
end

-- Enhanced FilterAndProcessBanks with note-length-aware cursor detection
function FilterAndProcessBanks(ReaticulateAppdata)
    DebugLog("DEBUG: === STARTING FilterAndProcessBanks - ENHANCED NOTE-LENGTH-AWARE VERSION ===\n")
    
    local allChannels = {}
    local matchingBank = nil

    -- Initialize all channels with an empty bank name
    for i = 1, 17 do
        allChannels[i] = {channel = i, bank = ""}
    end

    if not ReaticulateAppdata or not ReaticulateAppdata.banks or #ReaticulateAppdata.banks == 0 then
        DebugLog("DEBUG: No Reaticulate app data or banks found\n")
        return nil, allChannels
    end

    -- Check if we have selected events
    local selectedChannels = GetSelectedEventsChannels()
    
    DebugLog("DEBUG: FilterAndProcessBanks - Selected channels: " .. table.concat(selectedChannels, ",") .. " (count: " .. #selectedChannels .. ")\n")
    
    if #selectedChannels > 0 then
        -- We have selected events - use the smart selection logic
        local sharedBank, bankName = DoSelectedChannelsShareBank(ReaticulateAppdata)
        
        DebugLog("DEBUG: Shared bank check - sharedBank: " .. tostring(sharedBank) .. ", bankName: " .. tostring(bankName) .. "\n")
        
        if sharedBank and bankName then
            -- All selected channels share the same bank (or OMNI) - use it
            DebugLog("DEBUG: Using shared bank: " .. bankName .. "\n")
            matchingBank = LoopThroughReabanksFiles({ name = bankName })
        else
            -- Different banks - use the ENHANCED note-length-aware cursor detection
            DebugLog("DEBUG: Different banks detected, using enhanced note-length-aware cursor detection\n")
            
            local closestChannel = GetChannelFromClosestSelectedNote()
            
            DebugLog("DEBUG: Enhanced cursor detection result: " .. tostring(closestChannel) .. "\n")
            
            if closestChannel then
                -- Find the bank for the closest channel
                DebugLog("DEBUG: Looking for bank for detected channel " .. closestChannel .. "\n")
                
                for _, bank in ipairs(ReaticulateAppdata.banks) do
                    DebugLog("DEBUG: Checking bank '" .. bank.name .. "' for src channel " .. bank.src .. "\n")
                    
                    if bank.src == closestChannel or bank.src == 17 then -- Include OMNI
                        DebugLog("DEBUG: Found matching bank '" .. bank.name .. "' for detected channel " .. closestChannel .. "\n")
                        matchingBank = LoopThroughReabanksFiles({ name = bank.name })
                        break
                    end
                end
            end
            
            -- Fallback to lowest channel if detection fails
            if not matchingBank then
                DebugLog("DEBUG: Cursor detection failed, using lowest channel fallback\n")
                
                table.sort(selectedChannels)
                local lowestChannel = selectedChannels[1]
                
                DebugLog("DEBUG: Fallback lowest channel: " .. lowestChannel .. "\n")
                
                for _, bank in ipairs(ReaticulateAppdata.banks) do
                    if bank.src == lowestChannel or bank.src == 17 then
                        DebugLog("DEBUG: Found fallback bank '" .. bank.name .. "' for lowest channel " .. lowestChannel .. "\n")
                        matchingBank = LoopThroughReabanksFiles({ name = bank.name })
                        break
                    end
                end
            end
        end
    else
        -- No selected events - use original logic with active channel
        DebugLog("DEBUG: No selected events, using active channel: " .. activeChannel .. "\n")
        
        for _, bank in ipairs(ReaticulateAppdata.banks) do
            if bank.src == 17 or bank.src == activeChannel then
                DebugLog("DEBUG: Found bank '" .. bank.name .. "' for active channel " .. activeChannel .. " or OMNI\n")
                matchingBank = LoopThroughReabanksFiles({ name = bank.name })
                break
            end
        end
    end

    -- Populate all channels
    for _, bank in ipairs(ReaticulateAppdata.banks) do
        if bank.src >= 1 and bank.src <= 17 then
            allChannels[bank.src].bank = bank.name
        end
    end

    if matchingBank then
        DebugLog("DEBUG: Final matching bank found: " .. tostring(activeBank) .. "\n")
    else
        DebugLog("DEBUG: No matching bank found\n")
    end

    return matchingBank, allChannels
end

-- The workflow is:
-- 1. Check main Reaticulate.reabank file first (user's custom banks with full metadata)
-- 2. Check factory Reaticulate-factory.reabank (default banks with full metadata)
-- 3. If bank uses wildcards (Bank * *), get actual MSB/LSB from temp file  
-- 4. If not found in main/factory files, fall back to temp file (basic functionality, no colors)
-- 
-- Main reabank = User's Reaticulate.reabank with custom bank definitions and metadata
-- Factory reabank = Default Reaticulate-factory.reabank that ships with Reaticulate
-- Temp reabank = REAPER's generated file with only active banks (no metadata)

local function getCurrentReabank()
    -- Get the currently active reabank from REAPER's ini (this is usually a temp file)
    local iniFile = reaper.get_ini_file()
    DebugLog("DEBUG: Looking for ini file at: " .. tostring(iniFile) .. "\n")
    
    local file = io.open(iniFile, "r")
    if not file then 
        DebugLog("ERROR: Could not open ini file: " .. tostring(iniFile) .. "\n")
        return nil 
    end
    
    local content = file:read("*all")
    file:close()
    
    if not content or content == "" then
        DebugLog("ERROR: Ini file is empty or could not be read\n")
        return nil
    end
    
    local reabank = content:match("mididefbankprog=([^\r\n]*)")
    if reabank then
        DebugLog("DEBUG: Found reabank setting: " .. reabank .. "\n")
        -- Check if file actually exists
        if reaper.file_exists(reabank) then
            DebugLog("DEBUG: Reabank file exists and is accessible\n")
        else
            DebugLog("ERROR: Reabank file does not exist: " .. reabank .. "\n")
            return nil
        end
    else
        DebugLog("ERROR: No mididefbankprog setting found in ini file\n")
        -- Show first few lines of ini to help debug
        local lines = {}
        for line in content:gmatch("[^\r\n]+") do
            lines[#lines+1] = line
            if #lines >= 10 then break end
        end
        DebugLog("DEBUG: First 10 lines of ini file:\n" .. table.concat(lines, "\n") .. "\n")
    end
    
    return reabank
end

local function getMainReabankPath()
    -- The main reabank file is typically in the Reaticulate folder or Data folder
    local resource_path = reaper.GetResourcePath()
    
    -- Try multiple possible locations
    local possible_paths = {
        resource_path .. "/Scripts/Reaticulate/Reaticulate.reabank",
        resource_path .. "/Data/Reaticulate.reabank",
        resource_path .. "/Scripts/Reaticulate/reaticulate.reabank",  -- lowercase
        resource_path .. "/Data/reaticulate.reabank"  -- lowercase
    }
    
    for _, path in ipairs(possible_paths) do
        if reaper.file_exists(path) then
            DebugLog("DEBUG: Found main reabank file at: " .. path .. "\n")
            return path
        end
    end
    
    DebugLog("WARNING: Main reabank file not found in any expected location\n")
    return nil
end

local function getFactoryReabankPath()
    -- The factory reabank file contains default bank definitions
    local resource_path = reaper.GetResourcePath()
    
    -- Try multiple possible locations for the factory file
    local possible_paths = {
        resource_path .. "/Scripts/Reaticulate/Reaticulate-factory.reabank",
        resource_path .. "/Data/Reaticulate-factory.reabank",
        resource_path .. "/Scripts/Reaticulate/reaticulate-factory.reabank",  -- lowercase
        resource_path .. "/Data/reaticulate-factory.reabank"  -- lowercase
    }
    
    for _, path in ipairs(possible_paths) do
        if reaper.file_exists(path) then
            DebugLog("DEBUG: Found factory reabank file at: " .. path .. "\n")
            return path
        end
    end
    
    DebugLog("DEBUG: Factory reabank file not found\n")
    return nil
end

function LoopThroughReabanksFiles(MatchingBank)
    DebugLog("DEBUG: Starting LoopThroughReabanksFiles with bank name: " .. tostring(MatchingBank.name) .. "\n")
    
    -- First, try to get metadata from the main reabank file
    local mainReabank = getMainReabankPath()
    local reabankData = nil
    
    if mainReabank then
        DebugLog("DEBUG: Trying main reabank file first for full metadata\n")
        local mainContent = readFileContent(mainReabank)
        if mainContent then
            -- Try to find the bank with full metadata in main file
            reabankData = FindReabankDataByName(mainContent, MatchingBank.name)
            if reabankData then
                DebugLog("SUCCESS: Found bank with full metadata in main reabank\n")
                DebugLog("DEBUG: Found " .. #reabankData.articulations .. " articulations and " .. #reabankData.articulationslook .. " color definitions\n")
            end
        end
    end
    
    -- If not found in main file, try the factory reabank
    if not reabankData then
        DebugLog("DEBUG: Bank not found in main reabank, trying factory reabank\n")
        local factoryReabank = getFactoryReabankPath()
        if factoryReabank then
            local factoryContent = readFileContent(factoryReabank)
            if factoryContent then
                reabankData = FindReabankDataByName(factoryContent, MatchingBank.name)
                if reabankData then
                    DebugLog("SUCCESS: Found bank with full metadata in factory reabank\n")
                    DebugLog("DEBUG: Found " .. #reabankData.articulations .. " articulations and " .. #reabankData.articulationslook .. " color definitions\n")
                end
            end
        end
    end
    
    -- If not found in main or factory, fall back to temp reabank (no metadata)
    if not reabankData then
        DebugLog("DEBUG: Bank not found in main or factory reabanks, trying temp file\n")
        local currentReabank = getCurrentReabank()
        if currentReabank then
            local tempContent = readFileContent(currentReabank)
            if tempContent then
                reabankData = FindReabankDataByName(tempContent, MatchingBank.name)
                if reabankData then
                    DebugLog("WARNING: Found bank in temp file but without metadata (colors won't work)\n")
                    DebugLog("DEBUG: Found " .. #reabankData.articulations .. " articulations\n")
                end
            end
        end
    else
        -- If we found the bank in main/factory file with wildcards, we need to get actual MSB/LSB from temp file
        if reabankData.bank:find("%*") then
            DebugLog("DEBUG: Bank has wildcards, checking temp file for actual MSB/LSB values\n")
            local currentReabank = getCurrentReabank()
            if currentReabank then
                local tempContent = readFileContent(currentReabank)
                if tempContent then
                    -- Quick search just for the MSB/LSB values
                    for line in tempContent:gmatch("[^\r\n]+") do
                        local msb, lsb, tempBankName = line:match("^Bank (%d+) (%d+) (.*)$")
                        if tempBankName and tempBankName == MatchingBank.name then
                            DebugLog("DEBUG: Found actual MSB/LSB in temp file: " .. msb .. "/" .. lsb .. "\n")
                            reabankData.bank = msb .. " " .. lsb
                            break
                        end
                    end
                end
            end
        end
    end
    
    if not reabankData then
        DebugLog("ERROR: Bank '" .. tostring(MatchingBank.name) .. "' not found in any reabank file\n")
        return nil
    end
    
    activeBank = MatchingBank.name
    return reabankData
end

function FindReabankDataByName(combinedContent, bankName, cloneDepth)
    cloneDepth = cloneDepth or 0  -- Initialize depth counter for clone recursion
    if cloneDepth > 10 then
        DebugLog("ERROR: Clone recursion depth exceeded (possible circular reference) for bank: '" .. tostring(bankName) .. "'\n")
        return nil, "Clone recursion depth exceeded."
    end

    DebugLog("DEBUG: Searching for bank name: '" .. tostring(bankName) .. "' (clone depth: " .. cloneDepth .. ")\n")

    local reabankData = { id = "", bank = "", articulations = {}, articulationslook = {} }
    if not bankName or bankName == "" then
        DebugLog("ERROR: Bank name not provided or empty\n")
        return nil, "Bank name not provided."
    end

    local found = false
    local capturing = false
    local lineCount = 0
    local currentArticulationIndex = 0
    local pendingMetadata = {}  -- Store metadata for next articulation
    local bankCount = 0
    local cloneTarget = nil  -- Store clone target if found

    for line in combinedContent:gmatch("[^\r\n]+") do
        lineCount = lineCount + 1
        local trimmedLine = line:gsub("^%s*(.-)%s*$", "%1")

        -- Check for bank definition
        if trimmedLine:find("^Bank ") then
            bankCount = bankCount + 1
            -- Extract bank info - handle both "Bank * *" and "Bank 12 0" formats
            local msb, lsb, currentBankName = trimmedLine:match("^Bank ([%d%*]+) ([%d%*]+) (.*)")

            if currentBankName then
                DebugLog("DEBUG: Found bank #" .. bankCount .. " at line " .. lineCount .. ": '" .. currentBankName .. "'\n")

                -- If we were already capturing a different bank, stop
                if found and currentBankName ~= bankName then
                    DebugLog("DEBUG: Found different bank, stopping capture\n")
                    break
                end

                if currentBankName == bankName then
                    found = true
                    capturing = true
                    reabankData.bank = msb .. " " .. lsb
                    currentArticulationIndex = 0
                    pendingMetadata = {}
                    DebugLog("SUCCESS: Found matching bank: '" .. bankName .. "' with MSB/LSB: " .. msb .. "/" .. lsb .. "\n")
                else
                    capturing = false
                end
            end
        elseif capturing then
            -- Capture metadata lines that come before articulations
            if trimmedLine:find("^//! ") then
                -- Check for clone parameter
                if trimmedLine:find("^//! clone=") and currentArticulationIndex == 0 then
                    -- Extract clone target - handle both quoted and unquoted formats
                    local clonePath = trimmedLine:match("^//! clone=\"([^\"]+)\"") or trimmedLine:match("^//! clone=(%S.-)%s*$")
                    if clonePath then
                        -- Extract bank name from path (e.g., "Spitfire/.../BBC Violins 1 Leader" -> "BBC Violins 1 Leader")
                        cloneTarget = clonePath:match("([^/]+)$") or clonePath
                        DebugLog("SUCCESS: Found clone parameter: '" .. clonePath .. "' -> bank name: '" .. cloneTarget .. "'\n")
                    end
                -- This is metadata for the next articulation
                elseif trimmedLine:find("^//! id=") and currentArticulationIndex == 0 then
                    -- Bank UUID
                    reabankData.id = trimmedLine:match("//! id=([%w-]+)")
                    DebugLog("DEBUG: Found bank UUID: " .. tostring(reabankData.id) .. "\n")

                    -- If we found a clone target, resolve it now
                    if cloneTarget then
                        DebugLog("DEBUG: Resolving clone from '" .. bankName .. "' to '" .. cloneTarget .. "'\n")
                        local clonedData = FindReabankDataByName(combinedContent, cloneTarget, cloneDepth + 1)
                        if clonedData then
                            -- Use the cloned articulations but keep our MSB/LSB and ID
                            reabankData.articulations = clonedData.articulations
                            reabankData.articulationslook = clonedData.articulationslook
                            DebugLog("SUCCESS: Cloned " .. #clonedData.articulations .. " articulations from '" .. cloneTarget .. "'\n")
                            -- Return immediately with cloned data
                            return reabankData
                        else
                            DebugLog("ERROR: Could not find clone target bank: '" .. cloneTarget .. "'\n")
                            -- Continue parsing in case there are fallback articulations
                        end
                    end
                else
                    -- Articulation metadata - parse all attributes
                    local metadata = {}
                    
                    -- Extract color
                    local color = trimmedLine:match("c=([%w-]+)")
                    if color then metadata.color = "c=" .. color end
                    
                    -- Extract icon
                    local icon = trimmedLine:match("i=([%w-]+)")
                    if icon then metadata.icon = "i=" .. icon end
                    
                    -- Extract group
                    local group = trimmedLine:match("g=(%d+)")
                    if group then metadata.group = "g=" .. group end
                    
                    -- Extract output
                    local output = trimmedLine:match("o=([%w:,/@]+)")
                    if output then metadata.output = "o=" .. output end
                    
                    -- Extract note name
                    local note_name = trimmedLine:match("n=\"?([^\"]+)\"?")
                    if note_name then metadata.note_name = "n=" .. note_name end
                    
                    -- Store for next articulation
                    pendingMetadata = metadata
                    DebugLog("DEBUG: Stored metadata: " .. trimmedLine .. "\n")
                end

            -- Capture articulation definition
            elseif trimmedLine:find("^%d+ ") then
                -- If we have a clone target and haven't resolved it yet (no id line was found)
                if cloneTarget and currentArticulationIndex == 0 and #reabankData.articulations == 0 then
                    DebugLog("DEBUG: Resolving clone (no id line) from '" .. bankName .. "' to '" .. cloneTarget .. "'\n")
                    local clonedData = FindReabankDataByName(combinedContent, cloneTarget, cloneDepth + 1)
                    if clonedData then
                        -- Use the cloned articulations but keep our MSB/LSB and ID
                        reabankData.articulations = clonedData.articulations
                        reabankData.articulationslook = clonedData.articulationslook
                        DebugLog("SUCCESS: Cloned " .. #clonedData.articulations .. " articulations from '" .. cloneTarget .. "'\n")
                        -- Return immediately with cloned data
                        return reabankData
                    else
                        DebugLog("ERROR: Could not find clone target bank: '" .. cloneTarget .. "'\n")
                        -- Continue parsing local articulations as fallback
                        cloneTarget = nil  -- Clear to prevent re-attempting
                    end
                end

                local entry = trimmedLine:match("^(%d+ .*)")
                if entry then
                    currentArticulationIndex = currentArticulationIndex + 1
                    table.insert(reabankData.articulations, entry)
                    
                    -- Add the pending metadata for this articulation
                    local metadataStr = ""
                    if pendingMetadata.color then
                        metadataStr = pendingMetadata.color
                    else
                        -- Default color if none specified
                        metadataStr = "c=long"
                    end
                    -- You could also store icon, group, output here if needed
                    table.insert(reabankData.articulationslook, metadataStr)
                    
                    DebugLog("DEBUG: Added articulation #" .. currentArticulationIndex .. ": " .. entry .. " with metadata: " .. metadataStr .. "\n")
                    pendingMetadata = {}  -- Clear for next articulation
                end
            
            -- Stop if we hit a new group or bank
            elseif trimmedLine:find("^//! g=") and currentArticulationIndex > 0 then
                DebugLog("DEBUG: Found new group, stopping capture\n")
                break
            elseif trimmedLine == "" and currentArticulationIndex > 0 then
                -- Empty line might indicate end of bank in some formats
                local nextLineIdx = lineCount + 1
                local foundNext = false
                local tempCount = 0
                -- Peek ahead to see if there's more content for this bank
                for nextLine in combinedContent:gmatch("[^\r\n]+") do
                    tempCount = tempCount + 1
                    if tempCount > lineCount then
                        local nextTrimmed = nextLine:gsub("^%s*(.-)%s*$", "%1")
                        if nextTrimmed:find("^%d+ ") or nextTrimmed:find("^//! c=") then
                            foundNext = true
                            break
                        elseif nextTrimmed:find("^Bank ") or nextTrimmed:find("^//! g=") then
                            break
                        end
                    end
                end
                if not foundNext then
                    DebugLog("DEBUG: Empty line and no more articulations found, stopping capture\n")
                    break
                end
            end
        end
    end

    DebugLog("DEBUG: Processed " .. lineCount .. " lines, found " .. bankCount .. " banks total\n")

    if not found then
        DebugLog("ERROR: Bank name '" .. bankName .. "' not found\n")
        DebugLog("DEBUG: Available banks in file:\n")
        -- Show all available banks for debugging
        local availableBanks = {}
        for line in combinedContent:gmatch("[^\r\n]+") do
            local trimmedLine = line:gsub("^%s*(.-)%s*$", "%1")
            if trimmedLine:find("^Bank ") then
                -- Handle both "Bank * *" and "Bank 12 0" formats
                local msb, lsb, foundBankName = trimmedLine:match("^Bank ([%d%*]+) ([%d%*]+) (.*)")
                if foundBankName then
                    availableBanks[#availableBanks+1] = foundBankName
                end
            end
        end
        for i, availableBank in ipairs(availableBanks) do
            DebugLog("  Bank " .. i .. ": '" .. availableBank .. "'\n")
        end
        return nil, "Bank name not found."
    end
    
    -- Ensure we have metadata for all articulations
    while #reabankData.articulationslook < #reabankData.articulations do
        table.insert(reabankData.articulationslook, "c=long")  -- Default color
        DebugLog("DEBUG: Added default color for articulation #" .. #reabankData.articulationslook .. "\n")
    end
    
    DebugLog("SUCCESS: Returning bank data with " .. #reabankData.articulations .. " articulations and " .. #reabankData.articulationslook .. " color definitions\n")
    return reabankData
end

-- Enhanced readFileContent function with better error handling
function readFileContent(fileName)
    DebugLog("DEBUG: Attempting to read file: " .. tostring(fileName) .. "\n")
    
    if not fileName or fileName == "" then
        DebugLog("ERROR: No filename provided to readFileContent\n")
        return nil
    end
    
    if not reaper.file_exists(fileName) then
        DebugLog("ERROR: File does not exist: " .. fileName .. "\n")
        return nil
    end
    
    local file = io.open(fileName, "r")
    if not file then
        DebugLog("ERROR: Could not open file for reading: " .. fileName .. "\n")
        return nil
    end
    
    local content = file:read("*a")
    file:close()
    
    if not content then
        DebugLog("ERROR: File content is nil: " .. fileName .. "\n")
        return nil
    end
    
    DebugLog("DEBUG: Successfully read file, content length: " .. #content .. " characters\n")
    return content
end

--#region Utility functions to check all the relevant Reaper context needed for fetching
function CheckMIDIEditorIsActive()
    MIDIEDITOR = r.MIDIEditor_GetActive()
    if MIDIEDITOR then return true end
end

function GetActiveTrackInMIDIEditor()
    local activeTake = r.MIDIEditor_GetTake(MIDIEDITOR)
    if not activeTake then return end
    local activeItem = r.GetMediaItemTakeInfo_Value(activeTake, "P_ITEM")
    local activeTrack = r.GetMediaItem_Track(activeItem)
    return activeTrack
end

function GetActiveMIDIChannelInMIDIEditor()
    local channelSetting = r.MIDIEditor_GetSetting_int(MIDIEDITOR, "default_note_chan")
    activeChannel = SafeToNumber(channelSetting, 0) + 1
    return activeChannel
end

--#endregion