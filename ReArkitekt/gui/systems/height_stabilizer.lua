-- ReArkitekt/gui/systems/height_stabilizer.lua
-- Height stabilization to prevent jittery layout changes
-- Requires multiple consecutive frames of a new height before accepting it

local M = {}

local HeightStabilizer = {}
HeightStabilizer.__index = HeightStabilizer

-- Create a new height stabilizer
-- opts: optional configuration table
--   stable_frames_required: number of consecutive frames needed to accept change (default: 2)
--   height_hysteresis: minimum pixel difference to trigger change consideration (default: 12)
function M.new(opts)
  opts = opts or {}
  
  return setmetatable({
    current_height = nil,
    candidate_height = nil,
    stable_frames = 0,
    stable_frames_required = opts.stable_frames_required or 2,
    height_hysteresis = opts.height_hysteresis or 12,
  }, HeightStabilizer)
end

-- Update with a new height measurement
-- new_height: the proposed new height in pixels
-- Returns: the stabilized height (may be old height if change hasn't stabilized)
function HeightStabilizer:update(new_height)
  local stable_required = self.stable_frames_required
  local hysteresis = self.height_hysteresis
  
  -- First time: accept immediately
  if not self.current_height then
    self.current_height = new_height
    self.candidate_height = new_height
    self.stable_frames = stable_required
    return new_height
  end
  
  -- Within hysteresis of current: keep current and reset stability
  if math.abs(new_height - self.current_height) <= hysteresis then
    self.stable_frames = stable_required
    return self.current_height
  end
  
  -- Check if this matches our candidate height
  if self.candidate_height and math.abs(new_height - self.candidate_height) <= hysteresis then
    self.stable_frames = self.stable_frames + 1
    if self.stable_frames >= stable_required then
      -- Candidate has been stable long enough, accept it
      self.current_height = self.candidate_height
      self.stable_frames = stable_required
      return self.current_height
    end
  else
    -- New candidate height detected
    self.candidate_height = new_height
    self.stable_frames = 0
  end
  
  -- Not stable yet, return current
  return self.current_height
end

-- Reset stabilizer state
function HeightStabilizer:reset()
  self.current_height = nil
  self.candidate_height = nil
  self.stable_frames = 0
end

return M