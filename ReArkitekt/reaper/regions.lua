-- ReArkitekt/reaper/regions.lua
-- REAPER Region API wrapper - uses native markrgnindexnumber as stable RID

local M = {}

local FALLBACK_COLOR = 0x4A5A6AFF

local function convert_reaper_color_to_rgba(native_color)
  if not native_color or native_color == 0 then
    return FALLBACK_COLOR
  end
  
  local color_int = native_color | 0x1000000
  local r, g, b = reaper.ColorFromNative(color_int)
  
  return (r << 24) | (g << 16) | (b << 8) | 0xFF
end

function M.scan_project_regions(proj)
  proj = proj or 0
  local regions = {}
  local _, num_markers, num_regions = reaper.CountProjectMarkers(proj)
  
  for i = 0, num_markers + num_regions - 1 do
    local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = 
      reaper.EnumProjectMarkers3(proj, i)
    
    if isrgn then
      regions[#regions + 1] = {
        rid = markrgnindexnumber,
        index = i,
        name = name,
        start = pos,
        ["end"] = rgnend,
        color = convert_reaper_color_to_rgba(color),
      }
    end
  end
  
  return regions
end

function M.get_region_by_rid(proj, target_rid)
  proj = proj or 0
  local _, num_markers, num_regions = reaper.CountProjectMarkers(proj)
  
  for i = 0, num_markers + num_regions - 1 do
    local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = 
      reaper.EnumProjectMarkers3(proj, i)
    
    if isrgn and markrgnindexnumber == target_rid then
      return {
        rid = markrgnindexnumber,
        index = i,
        name = name,
        start = pos,
        ["end"] = rgnend,
        color = convert_reaper_color_to_rgba(color),
      }
    end
  end
  
  return nil
end

-- NEW (Seamless) Implementation using native API function
function M.go_to_region(proj, target_rid)
  proj = proj or 0
  local rgn = M.get_region_by_rid(proj, target_rid)
  if not rgn then return false end 
  
  -- The core REAPER API function that performs a smooth seek to the region's start.
  -- The rgn.index (the internal marker index number) is the required 'region_index'.
  -- The 'false' argument tells REAPER to use the assigned region number, not the timeline order.
  -- This single call handles the smooth seek on its own, similar to the C++ extension.
  reaper.GoToRegion(proj, rgn.index, false)
  
  reaper.UpdateTimeline()
  return true
end

return M