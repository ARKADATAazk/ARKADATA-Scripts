-- ReArkitekt/gui/fx/animation/rect_track.lua
-- Multi-rectangle animation tracker with staggered delays and magnetic snapping
-- Usage:
--   local tracker = RectTrack.new(14.0)
--   tracker:to(item_id, {x1, y1, x2, y2})
--   tracker:to_with_delay(item_id, rect, 0.05)
--   tracker:update(dt)
--   local current_rect = tracker:get(item_id)

local Math = require('ReArkitekt.core.math')

local M = {}

local RectTrack = {}
RectTrack.__index = RectTrack

function M.new(speed, snap_epsilon, magnetic_threshold, magnetic_multiplier)
  return setmetatable({
    rects = {},
    speed = speed or 14.0,
    snap_eps = snap_epsilon or 0.5,
    magnetic_threshold = magnetic_threshold or 30.0,
    magnetic_multiplier = magnetic_multiplier or 2.5,
  }, RectTrack)
end

function RectTrack:to(id, rect)
  if not self.rects[id] then
    self.rects[id] = {
      current = {rect[1], rect[2], rect[3], rect[4]},
      target = {rect[1], rect[2], rect[3], rect[4]},
      delay = 0,
    }
  else
    local r = self.rects[id]
    r.target[1] = rect[1]
    r.target[2] = rect[2]
    r.target[3] = rect[3]
    r.target[4] = rect[4]
    r.delay = 0
  end
end

function RectTrack:to_with_delay(id, rect, delay)
  delay = delay or 0
  
  if not self.rects[id] then
    self.rects[id] = {
      current = {rect[1], rect[2], rect[3], rect[4]},
      target = {rect[1], rect[2], rect[3], rect[4]},
      delay = delay,
    }
  else
    local r = self.rects[id]
    r.target[1] = rect[1]
    r.target[2] = rect[2]
    r.target[3] = rect[3]
    r.target[4] = rect[4]
    r.delay = delay
  end
end

function RectTrack:update(dt)
  dt = dt or 0.016
  
  for id, r in pairs(self.rects) do
    if r.delay and r.delay > 0 then
      r.delay = r.delay - dt
      if r.delay < 0 then r.delay = 0 end
    else
      local dist_sq = 0
      for i = 1, 4 do
        local d = r.target[i] - r.current[i]
        dist_sq = dist_sq + d * d
      end
      local dist = math.sqrt(dist_sq)
      
      local effective_speed = self.speed
      if dist < self.magnetic_threshold then
        effective_speed = self.speed * self.magnetic_multiplier
      end
      
      for i = 1, 4 do
        r.current[i] = Math.lerp(r.current[i], r.target[i], effective_speed * dt)
        
        if math.abs(r.current[i] - r.target[i]) < self.snap_eps then
          r.current[i] = r.target[i]
        end
      end
    end
  end
end

function RectTrack:get(id)
  local r = self.rects[id]
  if not r then return nil end
  return {r.current[1], r.current[2], r.current[3], r.current[4]}
end

function RectTrack:teleport(id, rect)
  if not rect then return end
  if not self.rects[id] then
    self.rects[id] = {
      current = {rect[1], rect[2], rect[3], rect[4]},
      target = {rect[1], rect[2], rect[3], rect[4]},
      delay = 0,
    }
  else
    local r = self.rects[id]
    r.current = {rect[1], rect[2], rect[3], rect[4]}
    r.target = {rect[1], rect[2], rect[3], rect[4]}
    r.delay = 0
  end
end

function RectTrack:teleport_all(new_rects)
  self.rects = {}
  for id, rect in pairs(new_rects) do
    self.rects[id] = {
      current = {rect[1], rect[2], rect[3], rect[4]},
      target = {rect[1], rect[2], rect[3], rect[4]},
      delay = 0,
    }
  end
end

function RectTrack:clear()
  self.rects = {}
end

function RectTrack:remove(id)
  self.rects[id] = nil
end

return M