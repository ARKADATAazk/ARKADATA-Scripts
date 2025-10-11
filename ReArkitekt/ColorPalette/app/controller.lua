-- ReArkitekt/ColorPalette/app/controller.lua
-- Handles color application to REAPER targets

local M = {}

local Controller = {}
Controller.__index = Controller

function M.new()
  local controller = setmetatable({}, Controller)
  return controller
end

function Controller:get_selected_targets(target_type)
  local targets = {}
  
  if target_type == "Tracks" then
    local count = reaper.CountSelectedTracks(0)
    for i = 0, count - 1 do
      targets[#targets + 1] = reaper.GetSelectedTrack(0, i)
    end
    
  elseif target_type == "Items" then
    local count = reaper.CountSelectedMediaItems(0)
    for i = 0, count - 1 do
      targets[#targets + 1] = reaper.GetSelectedMediaItem(0, i)
    end
    
  elseif target_type == "Takes" then
    local count = reaper.CountSelectedMediaItems(0)
    for i = 0, count - 1 do
      local item = reaper.GetSelectedMediaItem(0, i)
      local take = reaper.GetActiveTake(item)
      if take then
        targets[#targets + 1] = {item = item, take = take}
      end
    end
    
  elseif target_type == "Take Markers" then
    -- For take markers, we'll store items with takes that have markers
    local count = reaper.CountSelectedMediaItems(0)
    for i = 0, count - 1 do
      local item = reaper.GetSelectedMediaItem(0, i)
      local take = reaper.GetActiveTake(item)
      if take and reaper.GetNumTakeMarkers then
        local num_markers = reaper.GetNumTakeMarkers(take)
        if num_markers > 0 then
          targets[#targets + 1] = {item = item, take = take}
        end
      end
    end
    
  elseif target_type == "Markers" or target_type == "Regions" then
    -- Get markers/regions in time selection or at cursor
    local cursor_pos = reaper.GetCursorPosition()
    local time_start, time_end = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
    local has_time_sel = (time_start ~= time_end)
    
    local _, num_markers, num_regions = reaper.CountProjectMarkers(0)
    local total = num_markers + num_regions
    
    for i = 0, total - 1 do
      local retval, is_region, pos, rgnend, name, markrgnindex = reaper.EnumProjectMarkers(i)
      
      local matches_type = (target_type == "Markers" and not is_region) or 
                          (target_type == "Regions" and is_region)
      
      if matches_type then
        local in_range = false
        
        if has_time_sel then
          if is_region then
            in_range = (pos >= time_start and pos <= time_end) or 
                      (rgnend >= time_start and rgnend <= time_end) or
                      (time_start >= pos and time_start <= rgnend)
          else
            in_range = (pos >= time_start and pos <= time_end)
          end
        else
          if is_region then
            in_range = (cursor_pos >= pos and cursor_pos <= rgnend)
          else
            in_range = (math.abs(pos - cursor_pos) < 0.001)
          end
        end
        
        if in_range then
          targets[#targets + 1] = {
            index = i,
            markrgnindex = markrgnindex,
            is_region = is_region,
            pos = pos,
            rgnend = rgnend,
            name = name
          }
        end
      end
    end
  end
  
  return targets
end

function Controller:apply_color_to_targets(targets, color, target_type, set_children)
  if not targets or #targets == 0 then return end
  
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)
  
  if target_type == "Tracks" then
    for _, track in ipairs(targets) do
      reaper.SetMediaTrackInfo_Value(track, "I_CUSTOMCOLOR", color)
    end
    
    if set_children then
      -- SWS extension command to set children track colors
      local cmd_id = reaper.NamedCommandLookup("_SWS_COLCHILDREN")
      if cmd_id > 0 then
        reaper.Main_OnCommand(cmd_id, 0)
      end
    end
    
  elseif target_type == "Items" then
    for _, item in ipairs(targets) do
      reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", color)
      -- Reset take colors to default
      reaper.Main_OnCommand(41337, 0)
    end
    
  elseif target_type == "Takes" then
    for _, data in ipairs(targets) do
      reaper.SetMediaItemTakeInfo_Value(data.take, "I_CUSTOMCOLOR", color)
    end
    
  elseif target_type == "Take Markers" then
    local cursor_pos = reaper.GetCursorPosition()
    local time_start, time_end = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
    local has_time_sel = (time_start ~= time_end)
    
    for _, data in ipairs(targets) do
      local item_pos = reaper.GetMediaItemInfo_Value(data.item, "D_POSITION")
      local take_offset = reaper.GetMediaItemTakeInfo_Value(data.take, "D_STARTOFFS")
      local playrate = reaper.GetMediaItemTakeInfo_Value(data.take, "D_PLAYRATE")
      
      local num_markers = reaper.GetNumTakeMarkers and reaper.GetNumTakeMarkers(data.take) or 0
      for j = 0, num_markers - 1 do
        local retval, name, marker_color = reaper.GetTakeMarker(data.take, j)
        if retval then
          local marker_pos = item_pos + (retval - take_offset) / playrate
          
          local in_range = false
          if has_time_sel then
            in_range = (marker_pos >= time_start and marker_pos <= time_end)
          else
            in_range = (math.abs(marker_pos - cursor_pos) < 0.001)
          end
          
          if in_range and reaper.SetTakeMarker then
            reaper.SetTakeMarker(data.take, j, name, retval, color)
          end
        end
      end
    end
    
  elseif target_type == "Markers" or target_type == "Regions" then
    for _, data in ipairs(targets) do
      if color ~= 0 then
        reaper.SetProjectMarker3(0, data.markrgnindex, data.is_region, data.pos, data.rgnend, data.name, color)
      else
        -- Setting to default (0) requires delete and re-add
        reaper.DeleteProjectMarkerByIndex(0, data.index)
        reaper.AddProjectMarker(0, data.is_region, data.pos, data.rgnend, data.name, math.max(data.index, 1))
      end
    end
  end
  
  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
  reaper.Undo_EndBlock("Color Palette: Set " .. target_type .. " color", -1)
end

function Controller:generate_random_colors(count, base_colors)
  local colors = {}
  
  for i = 1, count do
    local random_idx = math.random(1, #base_colors)
    colors[#colors + 1] = base_colors[random_idx]
  end
  
  return colors
end

function Controller:apply_color(color, target_type, action_type, set_children)
  -- Debug output
  reaper.ShowConsoleMsg("Target Type: " .. target_type .. "\n")
  reaper.ShowConsoleMsg("Action Type: " .. action_type .. "\n")
  
  local targets = self:get_selected_targets(target_type)
  
  reaper.ShowConsoleMsg("Targets found: " .. #targets .. "\n")
  
  if #targets == 0 then
    reaper.ShowMessageBox("No " .. target_type .. " selected", "Color Palette", 0)
    return
  end
  
  -- Convert RGBA to REAPER's BGR format
  local r = (color >> 24) & 0xFF
  local g = (color >> 16) & 0xFF
  local b = (color >> 8) & 0xFF
  local native_color = 0x01000000 | (b << 16) | (g << 8) | r
  
  if action_type == "Default" then
    self:apply_color_to_targets(targets, 0, target_type, set_children)
    
  elseif action_type == "Random All" then
    -- All targets get the same random color (the clicked one)
    self:apply_color_to_targets(targets, native_color, target_type, set_children)
    
  elseif action_type == "Random Each" then
    -- Each target gets a random color from palette
    -- For now, just apply the clicked color to all
    -- TODO: Implement proper random-each logic with palette colors
    self:apply_color_to_targets(targets, native_color, target_type, set_children)
    
  elseif action_type == "In Order" then
    -- Apply colors in order from palette
    -- For now, just apply the clicked color to all
    -- TODO: Implement proper in-order logic with palette colors
    self:apply_color_to_targets(targets, native_color, target_type, set_children)
  end
end

return M