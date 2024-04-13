--@noindex
--NoIndex: true


local addonPieGenerator = {}

local scriptPath = debug.getinfo(1, 'S').source:match [[^@?(.*[\/])[^\/]-$]]
package.path = package.path .. ";" .. scriptPath .. "?.lua"

require "Utils"

function addonPieGenerator.createPieActions(entries, tbl)
    for i, entryData in ipairs(entries) do
        local func = entryData.func or ""
        local name = entryData.name or "IssueWithentryData.name"
        local argument = entryData.argument or ""
        local col = entryData.col  or 255
        local toggle_state = entry.toggle_state or false
        table.insert(tbl, {
            func = func,
            name = name,
            argument = argument,
            col = col,
            toggle_state = toggle_state,
        }
        )
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
