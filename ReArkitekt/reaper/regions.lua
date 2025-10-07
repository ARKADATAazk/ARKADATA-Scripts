-- ReArkitekt/reaper/regions.lua
-- REAPER Region API wrapper with stable ID mapping

local M = {}

local function generate_guid()
  return reaper.genGuid("")
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
        index = i,
        marker_id = markrgnindexnumber,
        name = name,
        start = pos,
        ["end"] = rgnend,
        color = color,
      }
    end
  end
  
  return regions
end

function M.create_rid_mapping(regions, prev_mapping)
  prev_mapping = prev_mapping or {}
  local rid_map = {}
  local next_rid = 1
  
  for rid, data in pairs(prev_mapping) do
    if type(rid) == "number" and rid >= next_rid then
      next_rid = rid + 1
    end
  end
  
  for _, rgn in ipairs(regions) do
    local key = string.format("%s|%.4f|%.4f", rgn.name, rgn.start, rgn["end"])
    local existing_rid = prev_mapping[key]
    
    if existing_rid then
      rid_map[existing_rid] = {
        key = key,
        region = rgn,
        guid = prev_mapping[existing_rid] and prev_mapping[existing_rid].guid or generate_guid()
      }
    else
      rid_map[next_rid] = {
        key = key,
        region = rgn,
        guid = generate_guid()
      }
      next_rid = next_rid + 1
    end
  end
  
  return rid_map
end

function M.get_region_by_index(proj, marker_index)
  proj = proj or 0
  local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = 
    reaper.EnumProjectMarkers3(proj, marker_index)
  
  if not isrgn then
    return nil
  end
  
  return {
    index = marker_index,
    marker_id = markrgnindexnumber,
    name = name,
    start = pos,
    ["end"] = rgnend,
    color = color,
  }
end

function M.go_to_region(proj, marker_index, timeline_order)
  proj = proj or 0
  local rgn = M.get_region_by_index(proj, marker_index)
  if not rgn then return false end
  
  reaper.SetEditCurPos(rgn.start, true, true)
  reaper.UpdateTimeline()
  return true
end

return M