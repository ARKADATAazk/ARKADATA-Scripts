--@noindex
--NoIndex: true

local r = reaper
local r = reaper
local pie_path = r.GetResourcePath() .. "/Scripts/Sexan_Scripts/Pie3000/"

local articulations_color = {
    default_colors = {
        ['default'] = '#666666',
        ['short'] = '#6c30c6',
        ['short-light'] = '#9630c6',
        ['short-dark'] = '#533bca',
        ['legato'] = '#218561',
        ['legato-dark'] = '#1c5e46',
        ['legato-light'] = '#49ba91',
        ['long'] = '#305fc6',
        ['long-light'] = '#4474e1',
        ['long-dark'] = '#2c4b94',
        ['textured'] = '#9909bd',
        ['fx'] = '#883333'
    }
}

local channels_color = {
    default_colors = {
        ['1'] = '#B93333',
        ['2'] = '#C07636',
        ['3'] = '#C7B749',
        ['4'] = '#85CC44',
        ['5'] = '#44C8AA',
        ['6'] = '#3E72D2',
        ['7'] = '#8D56D8',
        ['8'] = '#CF47CC',
        ['9'] = '#BF4056',
        ['10'] = '#9E6A54',
        ['11'] = '#CAA368',
        ['12'] = '#BBDC56',
        ['13'] = '#4AD091',
        ['14'] = '#6374AD',
        ['15'] = '#8E75B8',
        ['16'] = '#AD67AE',
        ['17'] = '#808080'
    }
}

-- THIRD PARTY INFO/CHECK
local function ThirdPartyRepos()
    local reapack_process
    local repos = {
        { name = "Sexan_Scripts",    url = 'https://github.com/GoranKovac/ReaScripts/raw/master/index.xml' },
        { name = "Reaticulate",      url = "https://reaticulate.com/index.xml" },
    }

    for i = 1, #repos do
        local retinfo, url, enabled, autoInstall = r.ReaPack_GetRepositoryInfo(repos[i].name)
        if not retinfo then
            retval, error = r.ReaPack_AddSetRepository(repos[i].name, repos[i].url, true, 0)
            reapack_process = true
        end
    end

    -- ADD NEEDED REPOSITORIES
    if reapack_process then
        r.ReaPack_ProcessQueue(true)
        reapack_process = nil
    end
end

local function MissingDeps()
    ThirdPartyRepos()
    local pie3000_path = pie_path .. "Sexan_Pie3000.lua"
    local reaticulate_path =  r.GetResourcePath() ..  "/Scripts/Reaticulate/reaticulate.lua"
    
    local deps = {}
   
    if not r.file_exists(pie3000_path) then
        deps[#deps + 1] = '"Sexan PieMenu 3000"'
    end 
    
    if not r.file_exists(reaticulate_path) then
        deps[#deps + 1] = '"Reaticulate: an articulation management system for REAPER"'
    end 

    if #deps ~= 0 then
        r.ShowMessageBox("Need Additional Packages.\nPlease Install it in next window", "MISSING DEPENDENCIES", 0)
        r.ReaPack_BrowsePackages(table.concat(deps, " OR "))
        return "ERROR"
    end
end

if MissingDeps() then return end -- ERROR HAPPENED
-- THIRD PARTY INFO/CHECK

function hexToDec(hex)
    -- Ensure hex is without the hash symbol and has "FF" at the end
    hex = hex:gsub("#", "") .. "FF"
    local len = string.len(hex)
    local dec = 0

    -- Convert hex to decimal
    for i = 1, len do
        local c = string.sub(hex, i, i)
        local value = tonumber(c, 16) -- Convert hex digit to decimal
        dec = dec + value * (16 ^ (len - i))
    end

    -- Adjust for 32-bit signed integer representation
    if dec >= 2^31 then
        dec = dec - 2^32
    end

    return math.floor(dec)
end

function getColorForArticulation(look)
    local defaultColor = 81657855 -- Fallback color
    if not look then return defaultColor end
    local cValue = look:match("c=(%w+%-?%w*)") -- This will match 'long-dark' from 'c=long-dark'
    if cValue and articulations_color.default_colors[cValue] then
        -- Convert hex color to decimal
        local hexColor = articulations_color.default_colors[cValue]
        return hexToDec(hexColor) -- Ensure hexToDec is accessible
    end
    return defaultColor
end

function getColorForChannel(channelIndex)
    -- Convert the numeric index to a string if needed
    local indexKey = tostring(channelIndex)

    -- Retrieve the color from the table
    local color = channels_color.default_colors[indexKey]

    -- Check if the color exists, otherwise return nil or a default color
    if color then
        return hexToDec(color)
    else
        return nil -- or you can return a default color like "#FFFFFF"
    end
end

function calculateRadius(entryListSize)
    local minEntries, maxEntries = 5, 20
    local minRadius, maxRadius = 130, 270

    -- Clamp the entryListSize between minEntries and maxEntries
    entryListSize = math.max(minEntries, math.min(maxEntries, entryListSize))

    -- Calculate the scaling factor
    local scale = (entryListSize - minEntries) / (maxEntries - minEntries)

    -- Linear interpolation between minRadius and maxRadius
    local radius = minRadius + (maxRadius - minRadius) * scale

    return math.floor(radius) -- Return the radius as an integer
end

function formatTo00Size(n)
    -- Convert n to a string in case it is not
    local s = tostring(n)
    -- Check if the string length is 1 (i.e., single digit)
    if #s == 1 then
        return "0" .. s .. " "  -- Append a space if it's a single digit
    elseif s == "17" then
        return "All"
    else
        return s .. " " -- Return the original string if it's not a single digit
    end
end

function tableToString(tbl, indent)
    if not indent then indent = 0 end
    local toprint = string.rep(" ", indent) .. "{\n"
    indent = indent + 2 
    for k, v in pairs(tbl) do
        toprint = toprint .. string.rep(" ", indent)
        if type(k) == "number" then
            toprint = toprint .. "[" .. k .. "] = "
        elseif type(k) == "string" then
            toprint = toprint .. k ..  " = "
        end
        if type(v) == "number" then
            toprint = toprint .. v .. ",\n"
        elseif type(v) == "string" then
            toprint = toprint .. "\"" .. v .. "\",\n"
        elseif type(v) == "table" then
            toprint = toprint .. tableToString(v, indent + 2) .. ",\n"
        else
            toprint = toprint .. "\"" .. tostring(v) .. "\",\n"
        end
    end
    toprint = toprint .. string.rep(" ", indent - 2) .. "}"
    return toprint
end

function printTableToConsole(tableData, Method)
    if not tableData or type(tableData) ~= "table" then
        reaper.ShowConsoleMsg("Invalid data: not a table\n")
        return
    end
    if Method == "Banks" then
        reaper.ShowConsoleMsg("Displaying table data:\n")
        for i, bank in ipairs(tableData) do
            local message = string.format("Entry %d: Name = %s, Channel = %s\n", i, tostring(bank.name),
                tostring(bank.channel))
            reaper.ShowConsoleMsg(message)
        end
    elseif Method == "Articulations" then
        reaper.ShowConsoleMsg("Displaying articulations data:\n")
        for i, articulation in ipairs(tableData.articulations) do
            local message = string.format("Entry %d: Name = %s\n", i, tostring(articulation))
            reaper.ShowConsoleMsg(message)
        end
    end
end

function isEmptyTable(t)
    if t == nil then return true end
    if type(t) ~= "table" then return false end
    return next(t) == nil
end

-- Function to read file content and return as string
function readFileContent(fileName)
    local file = io.open(fileName, "r")
    if not file then
        --if debuglog then reaper.ShowConsoleMsg("File not found: " .. fileName .. "\n") end
        return nil
    else
        local content = file:read("*a") -- Reads the entire file content
        file:close()
        return content
    end
end

-- Combine file contents and return as a single string
function combineFileContents(fileNames)
    local combinedContent = ""
    for _, fileName in ipairs(fileNames) do
        local content = readFileContent(fileName)
        if content then
            combinedContent = combinedContent .. "\n" .. content
        end
    end
    return combinedContent
end



return {
    articulations_color = articulations_color,
    channels_color = channels_color,
    hexToDec = hexToDec,
}

