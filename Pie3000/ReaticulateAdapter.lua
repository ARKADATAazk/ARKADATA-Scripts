-- @description ReaticulateAdapter - Pie3000 Addon
-- @author ARKADATA
-- @donation https://www.paypal.com/donate/?hosted_button_id=2FP22TUPGFPSJ
-- @website https://www.arkadata.com
-- @license GPL v3
-- @version 1.1
-- @changelog
--   Added undo points when inserting articulations ! (oops)
--   Fixed an issue with adding articulation Events to looped content (it'd break the loop, Reaticulate seems to have that issue when inserting Events as well, will get in touch with Tack to see if there is a specific reason for it or if he wants the fix).
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

local debuglog, extendedDebugLog = false, false
local _, extstate = reaper.GetProjExtState(0, "ReaticulateAdapter", "Channel")
local extstatechannel = tonumber(extstate)


local reabanks = {
    r.GetResourcePath() .. "/Data/Reaticulate.reabank",
    r.GetResourcePath() .. "/Scripts/Reaticulate/Reaticulate-factory.reabank"
}






function ReaticulateAdapter(MenuType)
    if  not CheckMIDIEditorIsActive() then return handleNoNoActiveMIDIEditorTrack() end
        activeChannel = GetActiveMIDIChannelInMIDIEditor()

    local appdata = FetchReaticulateAppDataOnActiveTrack()
    if appdata == nil then return handleNoReaticulate() end
    if isEmptyTable(appdata.banks) then return handleNoReaticulate() end

    local reabankData, otherBanksChannels = FilterAndProcessBanks(appdata)

    if MenuType == "Main" then
        if not reabankData then
            return handleBanks(otherBanksChannels)
        end
        return handleArticulations(reabankData)
    elseif MenuType == "Banks" then
        if not CheckMIDIEditorIsActive() then return handleNoReaticulate() end
        return handleBanks(otherBanksChannels)
    else
        return handleNoReaticulate()
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
        if bank.src == 17 or bank.src == activeChannel then  -- Only assign if no previous matching bank was assigned
                matchingBank = LoopThroughReabanksFiles({ uuid = bank.v, name = bank.name })
        end
    end

    -- Then populate all channels except when it matches the special cases
    for _, bank in ipairs(ReaticulateAppdata.banks) do
        if bank.src >= 1 and bank.src <= 17 then
            allChannels[bank.src].bank = bank.name
        end
    end

    -- Now handle the returns after the loop is completely processed
    if matchingBank then
        return matchingBank, allChannels
    else
        return nil, allChannels
    end
end


function LoopThroughReabanksFiles(MatchingBank)
    if debuglog then r.ShowConsoleMsg("Matching bank UUID: " .. MatchingBank.uuid .. "\n") end
    parsedReabanks = combineFileContents(reabanks)
    activeBank = MatchingBank.name
    local reabankData, err = FindReabankDataByUUID(parsedReabanks, MatchingBank.uuid)
    if reabankData then
        if debuglog then r.ShowConsoleMsg("BANK FROM REABANK: " .. reabankData.bank .. " " .. MatchingBank.name .. "\n") end
        if debuglog then
            r.ShowConsoleMsg("articulations FROM REABANK: " ..
                tableToString(reabankData.articulations) .. "\n")
        end
        -- GenerateInMenuFile(reabankData)
    else
        if debuglog then r.ShowConsoleMsg("BANK FROM REABANK: findreabankDataByUUID didn't work\n") end
    end
    return reabankData
end

function FindReabankDataByUUID(combinedContent, uuid)
    local reabankData = { id = "", bank = "", articulations = {}, articulationslook = {} }
    if not uuid or uuid == "" then
        if debuglog then r.ShowConsoleMsg("UUID not provided.\n") end
        return nil, "UUID not provided."
    end

    local found, capturing = false, false

    for line in combinedContent:gmatch("[^\r\n]+") do
        local trimmedLine = line:gsub("^%s*(.-)%s*$", "%1") -- Trim the line once, use it throughout
        if trimmedLine:find("//! id=") then
            local currentBankUUID = trimmedLine:match("//! id=([%w-]+)")
            if extendedDebugLog then
                r.ShowConsoleMsg("Checking UUID: " ..
                    tostring(currentBankUUID) .. " against " .. uuid .. "\n")
            end

            -- Use early break to exit if a new bank is found after matching the desired UUID
            if found and currentBankUUID ~= uuid then break end

            if currentBankUUID == uuid then
                found, capturing = true, true
                reabankData.id = uuid
                if debuglog then r.ShowConsoleMsg("Match found for UUID: " .. uuid .. "\n") end
            end
        elseif capturing then
            ProcessLine(trimmedLine, reabankData)
        end
    end

    if not found then
        if debuglog then r.ShowConsoleMsg("UUID not found in combined content: " .. uuid .. "\n") end
        return nil, "UUID not found."
    end
    return reabankData
end

function ProcessLine(line, reabankData)
    if extendedDebugLog then r.ShowConsoleMsg("Processing line post-match: " .. line .. "\n") end

    if line:find("^Bank") then
        reabankData.bank = line:match("Bank (%d+ %d+)")
    elseif line:find("^%d+") then
        local entry = line:match("(%d+ .*)")
        if entry then table.insert(reabankData.articulations, entry) end
    elseif line:find("^//! c=") then
        local entryLook = line:match("^//! c=(.*)")
        table.insert(reabankData.articulationslook, "c=" .. entryLook)
    end
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
