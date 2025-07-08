--@noindex
--NoIndex: true


local addonPieGenerator = {}

local scriptPath = debug.getinfo(1, 'S').source:match [[^@?(.*[\/])[^\/]-$]]
package.path = package.path .. ";" .. scriptPath .. "?.lua"

require "Utils"

function addonPieGenerator.createPieActions(entries, tbl)
    for i, entryData in ipairs(entries) do
        local entry = {
            name = entryData.name or "IssueWithEntryData.name",
            argument = entryData.argument or "",
            cmd_name = entryData.cmd_name or "",
            col = entryData.col or 255,
            toggle_state = entryData.toggle_state or false
        }
        -- Add func to the entry only if it is non-empty
        if entryData.func and entryData.func ~= "" then
            entry.func = entryData.func
        end
        table.insert(tbl, entry)
    end
end

function addonPieGenerator.createPie(Name, guid, PieEntriesList, radiusoverride)
    local radius = calculateRadius(#PieEntriesList) -- Calculate radius based on entry count
    return {
        name = Name,
        RADIUS = radiusoverride or radius,
        col = 255,
        guid = guid,
        menu = true,
    }
end


return addonPieGenerator
