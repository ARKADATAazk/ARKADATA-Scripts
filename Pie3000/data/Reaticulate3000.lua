local scriptPath = debug.getinfo(1,'S').source:match[[^@?(.*[\/])[^\/]-$]]
package.path = package.path .. ";" .. scriptPath .. "lib/?.lua" .. ";" .. scriptPath .. "modules/?.lua"

local json = require('json') 
local jsonBeautify = require('json-beautify')
local addonPieGenerator = require "addonPieGenerator"
require ('ReaticulateReabanksHandler')

local sourceChannel
previousActiveTrack = nil
previousSelectedChannel = -1
currentbankname = "reaticulate"

local debuglog = false


--DEFERED FUNCTIONS-------------------------
-- Function to check the active track in MIDI editor and print appdata if it has changed
function CheckAndProcessActiveMIDITrack()
    local midiEditor = reaper.MIDIEditor_GetActive()
    if midiEditor then
        local activeTake = reaper.MIDIEditor_GetTake(midiEditor)
        if activeTake then
            local activeItem = reaper.GetMediaItemTakeInfo_Value(activeTake, "P_ITEM")
            local activeTrack = reaper.GetMediaItem_Track(activeItem)
            if activeTrack ~= previousActiveTrack then
                previousActiveTrack = activeTrack
                UpdateScriptWithReaticulateAppDataForActiveTrack(activeTrack)
                ListAllBanksFromReaticulateAppData(parsedData)
                MatchingBanks()
            end
        end
    end
end



function CheckSelectedMIDIChannel()
    local midiEditor = reaper.MIDIEditor_GetActive()
    if midiEditor then
        sourceChannel  = reaper.MIDIEditor_GetSetting_int(midiEditor, "default_note_chan")
        sourceChannel = sourceChannel + 1
        if sourceChannel ~= previousSelectedChannel then
            previousSelectedChannel = sourceChannel
            MatchingBanks()
        end
    end
end


--DEFERED FUNCTIONS-------------------------



function UpdateScriptWithReaticulateAppDataForActiveTrack(track)
    local retval, data = reaper.GetSetMediaTrackInfo_String(track, 'P_EXT:reaticulate', '', false)
    if retval and data ~= '' then
        local version = data:sub(1, 1)
        if version == '2' then
            local jsonData = data:sub(2)
            parsedData = json.decode(jsonData)
            if parsedData then
                -- Attempt to pretty-print the JSON data
                local beautifiedJson = jsonBeautify.beautify(parsedData) -- Modify this line if your library supports pretty-printing
                local postChannel = GetReaticulateChannel(parsedData)
                if debuglog then reaper.ShowConsoleMsg("Reaticulate appdata found (version " .. version .. "):\n" .. beautifiedJson .. "\n") end
                if debuglog then reaper.ShowConsoleMsg("POSTCHANNEL = " .. tostring(postChannel).. "\n") end
            else
                reaper.ShowConsoleMsg("Failed to parse JSON data.\n")
            end
        else
            if debuglog then reaper.ShowConsoleMsg("Unknown version of Reaticulate appdata found: " .. version .. "\n") end
            parsedData = ""
        end
    else
        if debuglog then reaper.ShowConsoleMsg("No Reaticulate appdata found for the selected track.\n") end
        parsedData = ""
    end
end




function GetReaticulateChannel(ChannelCheck)
    -- Check if parsedData and parsedData.banks are valid
    if not parsedData or not parsedData.banks then
        if debuglog then reaper.ShowConsoleMsg("parsedData or parsedData.banks is nil.\n") end
        return false
    end

    -- Iterate through each bank in parsedData.banks
    for _, bank in ipairs(parsedData.banks) do
        -- Check if the 'dst' of the bank is 17
        if bank["dst"] == 17 then
            if debuglog then
                reaper.ShowConsoleMsg("Bank with 'dst' 17 found.\n")
            end
            return true
        end
    end
    
    -- No bank with 'dst' 17 was found
    return false
end



-- Function to filter parsedData based on the sourceChannel and return the 'v' value of matching banks
function ListAllBanksFromReaticulateAppData(parsedData)
    local availableBanks = {}

    -- Check if parsedData and sourceChannel are provided
    if parsedData == nil then
        --reaper.ShowConsoleMsg("parsedData or sourceChannel is nil\n")
        return availableBanks
    end

    -- Iterate through the 'banks' array in parsedData
    for _, bank in ipairs(parsedData.banks) do
        -- debuglog: Print each bank's 'src' and 'v' values

        table.insert(availableBanks, bank.name)
        if debuglog then reaper.ShowConsoleMsg("Checking bank with src: " .. tostring(bank.src) .. ", v: " .. tostring(bank.v) .. "\n") end
    end

    if debuglog then
        local banksStr = "LIST OF AVAILABLE BANKS: "
        for i, bankName in ipairs(availableBanks) do
            banksStr = banksStr .. bankName .. ", "
        end
        -- Optionally remove the last comma and space
        banksStr = banksStr:sub(1, -3)
        reaper.ShowConsoleMsg(banksStr .. "\n")
    end
    return availableBanks
end

-- Function to filter parsedData based on the sourceChannel and return the 'v' value of matching banks
function FindActiveBankByFilteringForActiveMIDIChannel(parsedData, sourceChannel)
    local matchingBanks = {}  -- Table to hold the 'v' values of matching banks

    -- debuglog: Print the received sourceChannel
    if debuglog then reaper.ShowConsoleMsg("Received sourceChannel: " .. tostring(sourceChannel) .. "\n") end

    -- Check if parsedData and sourceChannel are provided
    if parsedData == nil or sourceChannel == nil then
        --reaper.ShowConsoleMsg("parsedData or sourceChannel is nil\n")
        return matchingBanks
    end

    if parsedData.banks then
        if debuglog then reaper.ShowConsoleMsg("Number of banks in parsedData: " .. tostring(#parsedData.banks) .. "\n") end
    else
        if debuglog then reaper.ShowConsoleMsg("parsedData.banks is nil or not a table\n") end
        return matchingBanks
    end

    for _, bank in ipairs(parsedData.banks) do
        if debuglog then reaper.ShowConsoleMsg("Checking bank with src: " .. tostring(bank.src) .. ", v: " .. tostring(bank.v) .. "\n") end


        if bank.src == 17 then
            table.insert(matchingBanks, bank.v)
            local activebankUUID = bank.v
            currentbankname = bank.name
            if debuglog then reaper.ShowConsoleMsg("Match found. Added UUID: " .. activebankUUID .. "\n") end
            break
        elseif bank.src == sourceChannel then
                table.insert(matchingBanks, bank.v)
                local activebankUUID = bank.v
                currentbankname = bank.name
                if debuglog then reaper.ShowConsoleMsg("Match found. Added UUID: " .. activebankUUID .. "\n") end
                break
        end
    end
    if debuglog then reaper.ShowConsoleMsg("Number of matching banks found: " .. tostring(#matchingBanks) .. "\n") end
    return matchingBanks
end



function MatchingBanks()
    local matchingBanks = FindActiveBankByFilteringForActiveMIDIChannel(parsedData, sourceChannel)
    local availableBanks = ListAllBanksFromReaticulateAppData(parsedData)
    if #matchingBanks == 0 then
        reaper.ShowConsoleMsg("No matching banks found.\n")
--[[         if #availableBanks ~=0 then
            
        end  ]]
    else
        for _, v in ipairs(matchingBanks) do
            reaper.ShowConsoleMsg("Matching bank UUID: " .. v .. "\n")
            -- Use the function to find bank info by UUID
            --local bankInfo, err = findBankInfoByUUID(reaticulateFilePath, v)
            local bankInfo, err = findBankInfoByUUID(combinedContent, v)
            if bankInfo then
                if debuglog then reaper.ShowConsoleMsg("BANK FROM REABANK: " .. bankInfo.bank .. "\n") end
                if debuglog then reaper.ShowConsoleMsg("ENTRIES FROM REABANK: " .. tableToString(bankInfo.entries).. "\n") end
                GenerateInMenuFile(bankInfo)
            else
                if debuglog then reaper.ShowConsoleMsg("BANK FROM REABANK: findBankInfoByUUID didn't work\n") end
            end
        end
    end
end
--local matchingBanks = FindActiveBankByFilteringForActiveMIDIChannel()


function GenerateAddonPie(Content)
    local currententrylist = addonPieGenerator.createEntryList(Content)
    local GeneratedPie = addonPieGenerator.updateMenuFile(currententrylist)
    return GeneratedPie
end
