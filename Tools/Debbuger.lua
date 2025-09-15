package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua'
local ImGui = require 'imgui' '0.9.2'
local ctx = ImGui.CreateContext('Envelope Name Filter')

-- File path to save the input text
local saveFilePath = reaper.GetResourcePath() .. '/input_text.txt'

-- Function to load the saved text from a file
local function loadText()
    local file = io.open(saveFilePath, 'r')
    if file then
        local savedText = file:read('*all')
        file:close()
        -- Split the loaded text by commas and return it as a table
        local textTable = {}
        for value in string.gmatch(savedText, '([^,]+)') do
            table.insert(textTable, value)
        end
        return textTable
    else
        -- Return a default table with 10 empty strings if the file doesn't exist
        return {"", "", "", "", "", "", "", "", "", ""}
    end
end

-- Function to sanitize input by removing commas
local function sanitizeInput(input)
    -- Remove commas to avoid issues with saving and loading
    return input:gsub(",", "")
end

-- Function to save the input text to a file
local function saveText(textTable)
    local file = io.open(saveFilePath, 'w')
    if file then
        file:write(table.concat(textTable, ','))
        file:close()
    end
end

-- Load the initial text values from the file
local inputTexts = loadText()

local function loop()
    -- Set the minimum size of the window on the first frame
    if reaper.ImGui_IsWindowAppearing(ctx) then
        ImGui.SetNextWindowSize(ctx, 400, 300) -- Width: 400px, Height: 300px
    end

    -- Start a new ImGui frame and create a window
    local visible, open = ImGui.Begin(ctx, 'Envelope Name Filter', true)
    if visible then
        -- Flag to check if any text was changed
        local changed = false

        -- Loop through 10 input boxes
        for i = 1, 10 do
            local inputChanged
            inputChanged, inputTexts[i] = ImGui.InputText(ctx, 'Filter ' .. i, inputTexts[i], 256)
            
            -- Sanitize input to remove commas
            inputTexts[i] = sanitizeInput(inputTexts[i])
            
            if inputChanged then
                changed = true
            end
        end

        -- Save the input texts if any was changed
        if changed then
            saveText(inputTexts)
        end

        -- End the window
        ImGui.End(ctx)
    end

    -- Keep the loop running if the window is still open
    if open then
        reaper.defer(loop)
    end
end

-- Start the main loop
reaper.defer(loop)
