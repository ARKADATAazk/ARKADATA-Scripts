-- @description ReaticulateAdapter - Pie3000 Addon
-- @author ARKADATA
-- @donation https://www.paypal.com/donate/?hosted_button_id=2FP22TUPGFPSJ
-- @website https://www.arkadata.com
-- @license GPL v3
-- @version 1.2.1
-- @changelog
--   Cleared leftover debug logging.
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

local debuglog, extendedDebugLog = false, false
local _, extstate = reaper.GetProjExtState(0, "ReaticulateAdapter", "Channel")
local extstatechannel = tonumber(extstate)






function ReaticulateAdapter(MenuType)
    if  not CheckMIDIEditorIsActive() then return handleNoNoActiveMIDIEditorTrack() end
        activeChannel = GetActiveMIDIChannelInMIDIEditor()

    local appdata = FetchReaticulateAppDataOnActiveTrack()
    --if appdata == nil then return handlePredefinedReaticulate() end
    --if isEmptyTable(appdata.banks) then return handleNoReaticulate() end

    local reabankData, otherBanksChannels = FilterAndProcessBanks(appdata)

    if MenuType == "Main" then
        if appdata == nil then return handlePredefinedReaticulate() end
        if not reabankData then
            return handleBanks(otherBanksChannels)
        end
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
        --{name = "Add Reaticulate To Track", func = "func1", argument = "arg1", col = 255, toggle_state = false, cmd_name = ""},
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

-- Helper function to process articulations
function handleArticulations(data)
    local pie = addonPieGenerator.createPie(activeBank, pieGUID, data.articulations)
    local MSB_LSB = { string.match(data.bank, "(%d+) (%d+)") }
    for i, articulation in ipairs(data.articulations) do
        local parts = { string.match(articulation, "(%d+) (.*)") }
        table.insert(pie, {
            name = table.concat(parts, " ", 2),
            func = "R3000_PostArticulationEvent",
            argument = table.concat({ MSB_LSB[1], MSB_LSB[2], parts[1],activeChannel }, ","),
            col = getColorForArticulation(data.articulationslook[i]),
            toggle_state = false,
            --icon = "/Scripts/ARKADATA Scripts/Pie3000/articulations icons/pizz.png",
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
        --local channelColor = channelInfo.bank ~= "" and hexToDec("#dea53b") or 255
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
        r.ShowConsoleMsg("Reaticulate appdata found (version " ..
            version .. "):\n" .. beautifiedJson .. "\n")
    end
    return json.decode(jsonData)
end

function FilterAndProcessBanks(ReaticulateAppdata)
    local allChannels = {}
    local matchingBank = nil

    -- Initialize all channels with an empty bank name
    for i = 1, 17 do
        allChannels[i] = {channel = i, bank = ""}
    end

    if not ReaticulateAppdata or not ReaticulateAppdata.banks or #ReaticulateAppdata.banks == 0 then
        return nil, allChannels
    end

    -- First, find if there's a matching bank for special cases (channel 17 or active channel)
    for _, bank in ipairs(ReaticulateAppdata.banks) do
        if bank.src == 17 or bank.src == activeChannel then
            -- Pass bank name instead of UUID
            matchingBank = LoopThroughReabanksFiles({ name = bank.name })
        end
    end

    -- Then populate all channels
    for _, bank in ipairs(ReaticulateAppdata.banks) do
        if bank.src >= 1 and bank.src <= 17 then
            allChannels[bank.src].bank = bank.name
        end
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
    if DEBUG_ENABLED then
        reaper.ShowConsoleMsg("DEBUG: Looking for ini file at: " .. tostring(iniFile) .. "\n")
    end
    
    local file = io.open(iniFile, "r")
    if not file then 
        if DEBUG_ENABLED then
            reaper.ShowConsoleMsg("ERROR: Could not open ini file: " .. tostring(iniFile) .. "\n")
        end
        return nil 
    end
    
    local content = file:read("*all")
    file:close()
    
    if not content or content == "" then
        if DEBUG_ENABLED then
            reaper.ShowConsoleMsg("ERROR: Ini file is empty or could not be read\n")
        end
        return nil
    end
    
    local reabank = content:match("mididefbankprog=([^\r\n]*)")
    if reabank then
        if DEBUG_ENABLED then
            reaper.ShowConsoleMsg("DEBUG: Found reabank setting: " .. reabank .. "\n")
        end
        -- Check if file actually exists
        if reaper.file_exists(reabank) then
            if DEBUG_ENABLED then
                reaper.ShowConsoleMsg("DEBUG: Reabank file exists and is accessible\n")
            end
        else
            if DEBUG_ENABLED then
                reaper.ShowConsoleMsg("ERROR: Reabank file does not exist: " .. reabank .. "\n")
            end
            return nil
        end
    else
        if DEBUG_ENABLED then
            reaper.ShowConsoleMsg("ERROR: No mididefbankprog setting found in ini file\n")
            -- Show first few lines of ini to help debug
            local lines = {}
            for line in content:gmatch("[^\r\n]+") do
                lines[#lines+1] = line
                if #lines >= 10 then break end
            end
            reaper.ShowConsoleMsg("DEBUG: First 10 lines of ini file:\n" .. table.concat(lines, "\n") .. "\n")
        end
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
            if DEBUG_ENABLED then
                reaper.ShowConsoleMsg("DEBUG: Found main reabank file at: " .. path .. "\n")
            end
            return path
        end
    end
    
    if DEBUG_ENABLED then
        reaper.ShowConsoleMsg("WARNING: Main reabank file not found in any expected location\n")
    end
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
            if DEBUG_ENABLED then
                reaper.ShowConsoleMsg("DEBUG: Found factory reabank file at: " .. path .. "\n")
            end
            return path
        end
    end
    
    if DEBUG_ENABLED then
        reaper.ShowConsoleMsg("DEBUG: Factory reabank file not found\n")
    end
    return nil
end

function LoopThroughReabanksFiles(MatchingBank)
    if DEBUG_ENABLED then
        reaper.ShowConsoleMsg("DEBUG: Starting LoopThroughReabanksFiles with bank name: " .. tostring(MatchingBank.name) .. "\n")
    end
    
    -- First, try to get metadata from the main reabank file
    local mainReabank = getMainReabankPath()
    local reabankData = nil
    
    if mainReabank then
        if DEBUG_ENABLED then
            reaper.ShowConsoleMsg("DEBUG: Trying main reabank file first for full metadata\n")
        end
        local mainContent = readFileContent(mainReabank)
        if mainContent then
            -- Try to find the bank with full metadata in main file
            reabankData = FindReabankDataByName(mainContent, MatchingBank.name)
            if reabankData then
                if DEBUG_ENABLED then
                    reaper.ShowConsoleMsg("SUCCESS: Found bank with full metadata in main reabank\n")
                    reaper.ShowConsoleMsg("DEBUG: Found " .. #reabankData.articulations .. " articulations and " .. #reabankData.articulationslook .. " color definitions\n")
                end
            end
        end
    end
    
    -- If not found in main file, try the factory reabank
    if not reabankData then
        if DEBUG_ENABLED then
            reaper.ShowConsoleMsg("DEBUG: Bank not found in main reabank, trying factory reabank\n")
        end
        local factoryReabank = getFactoryReabankPath()
        if factoryReabank then
            local factoryContent = readFileContent(factoryReabank)
            if factoryContent then
                reabankData = FindReabankDataByName(factoryContent, MatchingBank.name)
                if reabankData then
                    if DEBUG_ENABLED then
                        reaper.ShowConsoleMsg("SUCCESS: Found bank with full metadata in factory reabank\n")
                        reaper.ShowConsoleMsg("DEBUG: Found " .. #reabankData.articulations .. " articulations and " .. #reabankData.articulationslook .. " color definitions\n")
                    end
                end
            end
        end
    end
    
    -- If not found in main or factory, fall back to temp reabank (no metadata)
    if not reabankData then
        if DEBUG_ENABLED then
            reaper.ShowConsoleMsg("DEBUG: Bank not found in main or factory reabanks, trying temp file\n")
        end
        local currentReabank = getCurrentReabank()
        if currentReabank then
            local tempContent = readFileContent(currentReabank)
            if tempContent then
                reabankData = FindReabankDataByName(tempContent, MatchingBank.name)
                if reabankData then
                    if DEBUG_ENABLED then
                        reaper.ShowConsoleMsg("WARNING: Found bank in temp file but without metadata (colors won't work)\n")
                        reaper.ShowConsoleMsg("DEBUG: Found " .. #reabankData.articulations .. " articulations\n")
                    end
                end
            end
        end
    else
        -- If we found the bank in main/factory file with wildcards, we need to get actual MSB/LSB from temp file
        if reabankData.bank:find("%*") then
            if DEBUG_ENABLED then
                reaper.ShowConsoleMsg("DEBUG: Bank has wildcards, checking temp file for actual MSB/LSB values\n")
            end
            local currentReabank = getCurrentReabank()
            if currentReabank then
                local tempContent = readFileContent(currentReabank)
                if tempContent then
                    -- Quick search just for the MSB/LSB values
                    for line in tempContent:gmatch("[^\r\n]+") do
                        local msb, lsb, tempBankName = line:match("^Bank (%d+) (%d+) (.*)$")
                        if tempBankName and tempBankName == MatchingBank.name then
                            if DEBUG_ENABLED then
                                reaper.ShowConsoleMsg("DEBUG: Found actual MSB/LSB in temp file: " .. msb .. "/" .. lsb .. "\n")
                            end
                            reabankData.bank = msb .. " " .. lsb
                            break
                        end
                    end
                end
            end
        end
    end
    
    if not reabankData then
        if DEBUG_ENABLED then
            reaper.ShowConsoleMsg("ERROR: Bank '" .. tostring(MatchingBank.name) .. "' not found in any reabank file\n")
        end
        return nil
    end
    
    activeBank = MatchingBank.name
    return reabankData
end

function FindReabankDataByName(combinedContent, bankName)
    if DEBUG_ENABLED then
        reaper.ShowConsoleMsg("DEBUG: Searching for bank name: '" .. tostring(bankName) .. "'\n")
    end
    
    local reabankData = { id = "", bank = "", articulations = {}, articulationslook = {} }
    if not bankName or bankName == "" then
        if DEBUG_ENABLED then
            reaper.ShowConsoleMsg("ERROR: Bank name not provided or empty\n")
        end
        return nil, "Bank name not provided."
    end

    local found = false
    local capturing = false
    local lineCount = 0
    local currentArticulationIndex = 0
    local pendingMetadata = {}  -- Store metadata for next articulation
    local bankCount = 0
    
    for line in combinedContent:gmatch("[^\r\n]+") do
        lineCount = lineCount + 1
        local trimmedLine = line:gsub("^%s*(.-)%s*$", "%1")
        
        -- Check for bank definition
        if trimmedLine:find("^Bank ") then
            bankCount = bankCount + 1
            -- Extract bank info - handle both "Bank * *" and "Bank 12 0" formats
            local msb, lsb, currentBankName = trimmedLine:match("^Bank ([%d%*]+) ([%d%*]+) (.*)")
            
            if currentBankName then
                if DEBUG_ENABLED then
                    reaper.ShowConsoleMsg("DEBUG: Found bank #" .. bankCount .. " at line " .. lineCount .. ": '" .. currentBankName .. "'\n")
                end
                
                -- If we were already capturing a different bank, stop
                if found and currentBankName ~= bankName then 
                    if DEBUG_ENABLED then
                        reaper.ShowConsoleMsg("DEBUG: Found different bank, stopping capture\n")
                    end
                    break
                end
                
                if currentBankName == bankName then
                    found = true
                    capturing = true
                    reabankData.bank = msb .. " " .. lsb
                    currentArticulationIndex = 0
                    pendingMetadata = {}
                    if DEBUG_ENABLED then
                        reaper.ShowConsoleMsg("SUCCESS: Found matching bank: '" .. bankName .. "' with MSB/LSB: " .. msb .. "/" .. lsb .. "\n")
                    end
                else
                    capturing = false
                end
            end
        elseif capturing then
            -- Capture metadata lines that come before articulations
            if trimmedLine:find("^//! ") then
                -- This is metadata for the next articulation
                if trimmedLine:find("^//! id=") and currentArticulationIndex == 0 then
                    -- Bank UUID
                    reabankData.id = trimmedLine:match("//! id=([%w-]+)")
                    if DEBUG_ENABLED then
                        reaper.ShowConsoleMsg("DEBUG: Found bank UUID: " .. tostring(reabankData.id) .. "\n")
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
                    if DEBUG_ENABLED then
                        reaper.ShowConsoleMsg("DEBUG: Stored metadata: " .. trimmedLine .. "\n")
                    end
                end
            
            -- Capture articulation definition
            elseif trimmedLine:find("^%d+ ") then
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
                    
                    if DEBUG_ENABLED then
                        reaper.ShowConsoleMsg("DEBUG: Added articulation #" .. currentArticulationIndex .. ": " .. entry .. " with metadata: " .. metadataStr .. "\n")
                    end
                    pendingMetadata = {}  -- Clear for next articulation
                end
            
            -- Stop if we hit a new group or bank
            elseif trimmedLine:find("^//! g=") and currentArticulationIndex > 0 then
                if DEBUG_ENABLED then
                    reaper.ShowConsoleMsg("DEBUG: Found new group, stopping capture\n")
                end
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
                    if DEBUG_ENABLED then
                        reaper.ShowConsoleMsg("DEBUG: Empty line and no more articulations found, stopping capture\n")
                    end
                    break
                end
            end
        end
    end

    if DEBUG_ENABLED then
        reaper.ShowConsoleMsg("DEBUG: Processed " .. lineCount .. " lines, found " .. bankCount .. " banks total\n")
    end

    if not found then
        if DEBUG_ENABLED then
            reaper.ShowConsoleMsg("ERROR: Bank name '" .. bankName .. "' not found\n")
            reaper.ShowConsoleMsg("DEBUG: Available banks in file:\n")
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
                reaper.ShowConsoleMsg("  Bank " .. i .. ": '" .. availableBank .. "'\n")
            end
        end
        return nil, "Bank name not found."
    end
    
    -- Ensure we have metadata for all articulations
    while #reabankData.articulationslook < #reabankData.articulations do
        table.insert(reabankData.articulationslook, "c=long")  -- Default color
        if DEBUG_ENABLED then
            reaper.ShowConsoleMsg("DEBUG: Added default color for articulation #" .. #reabankData.articulationslook .. "\n")
        end
    end
    
    if DEBUG_ENABLED then
        reaper.ShowConsoleMsg("SUCCESS: Returning bank data with " .. #reabankData.articulations .. " articulations and " .. #reabankData.articulationslook .. " color definitions\n")
    end
    return reabankData
end

-- Enhanced readFileContent function with better error handling
function readFileContent(fileName)
    if DEBUG_ENABLED then
        reaper.ShowConsoleMsg("DEBUG: Attempting to read file: " .. tostring(fileName) .. "\n")
    end
    
    if not fileName or fileName == "" then
        if DEBUG_ENABLED then
            reaper.ShowConsoleMsg("ERROR: No filename provided to readFileContent\n")
        end
        return nil
    end
    
    if not reaper.file_exists(fileName) then
        if DEBUG_ENABLED then
            reaper.ShowConsoleMsg("ERROR: File does not exist: " .. fileName .. "\n")
        end
        return nil
    end
    
    local file = io.open(fileName, "r")
    if not file then
        if DEBUG_ENABLED then
            reaper.ShowConsoleMsg("ERROR: Could not open file for reading: " .. fileName .. "\n")
        end
        return nil
    end
    
    local content = file:read("*a")
    file:close()
    
    if not content then
        if DEBUG_ENABLED then
            reaper.ShowConsoleMsg("ERROR: File content is nil: " .. fileName .. "\n")
        end
        return nil
    end
    
    if DEBUG_ENABLED then
        reaper.ShowConsoleMsg("DEBUG: Successfully read file, content length: " .. #content .. " characters\n")
    end
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
    activeChannel = r.MIDIEditor_GetSetting_int(MIDIEDITOR, "default_note_chan") + 1
    return activeChannel
end








--#endregion----------------------------------------------------------------------------