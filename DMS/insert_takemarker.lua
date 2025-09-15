-- This script inserts a green take marker on the selected item at the edit cursor position and includes extensive debugging.

function Main()
    -- Get the number of selected items
    local item_count = reaper.CountSelectedMediaItems(0)
    reaper.ShowConsoleMsg("Number of selected items: " .. item_count .. "\n")
    
    -- Ensure there is at least one selected item
    if item_count == 0 then
        reaper.ShowConsoleMsg("No items selected. Please select an item and run the script again.\n")
        return
    end

    -- Loop through all selected items
    for i = 0, item_count - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local item_length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        reaper.ShowConsoleMsg(string.format("Item %d: Position = %.3f, Length = %.3f\n", i+1, item_pos, item_length))
        
        -- Get the active take of the item
        local take = reaper.GetActiveTake(item)
        if not take then
            reaper.ShowConsoleMsg(string.format("No active take found for item %d.\n", i+1))
            return
        end

        -- Get the edit cursor position
        local cursor_pos = reaper.GetCursorPosition()
        reaper.ShowConsoleMsg("Edit cursor position: " .. cursor_pos .. "\n")
        
        -- Calculate cursor position relative to the item start
        local rel_pos = cursor_pos - item_pos
        reaper.ShowConsoleMsg(string.format("Relative position on item %d: %.3f\n", i+1, rel_pos))

        -- Check if the cursor is within the item's length
        if rel_pos >= 0 and rel_pos <= item_length then
            -- Insert a take marker at the relative position with the color green (0x00FF00)
            local retval = reaper.SetTakeMarker(take, 1, "Test", rel_pos)  -- Empty string provided for marker name
            if retval ~= -1 then
                reaper.ShowConsoleMsg(string.format("Successfully inserted take marker at relative position %.3f on item %d.\n", rel_pos, i+1))
            else
                reaper.ShowConsoleMsg("Failed to insert take marker.\n")
            end
        else
            reaper.ShowConsoleMsg(string.format("Cursor position %.3f is outside the item boundaries.\n", rel_pos))
        end
    end
    
    -- Update the arrange view and all necessary data structures
    reaper.UpdateArrange()
end

-- Run the script
Main()
