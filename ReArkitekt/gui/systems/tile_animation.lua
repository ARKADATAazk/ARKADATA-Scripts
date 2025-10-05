-- ReArkitekt/gui/systems/tile_animation.lua
-- Per-tile animation state for smooth hover/active/selection transitions
-- Manages multiple animation tracks per tile (hover, active, etc.)

local M = {}

local function lerp(a, b, t)
  return a + (b - a) * math.min(1.0, t)
end

local TileAnimator = {}
TileAnimator.__index = TileAnimator

function M.new(default_speed)
  return setmetatable({
    animations = {},  -- tile_id -> { track_name -> {current, target, speed} }
    default_speed = default_speed or 12.0,
  }, TileAnimator)
end

function TileAnimator:track(tile_id, track_name, target, speed)
  speed = speed or self.default_speed
  
  if not self.animations[tile_id] then
    self.animations[tile_id] = {}
  end
  
  if not self.animations[tile_id][track_name] then
    self.animations[tile_id][track_name] = {
      current = target,
      target = target,
      speed = speed,
    }
  else
    self.animations[tile_id][track_name].target = target
    self.animations[tile_id][track_name].speed = speed
  end
end

function TileAnimator:update(dt)
  dt = dt or 0.016
  
  for tile_id, tracks in pairs(self.animations) do
    for track_name, anim in pairs(tracks) do
      anim.current = lerp(anim.current, anim.target, anim.speed * dt)
    end
  end
end

function TileAnimator:get(tile_id, track_name)
  if not self.animations[tile_id] then return 0 end
  if not self.animations[tile_id][track_name] then return 0 end
  return self.animations[tile_id][track_name].current
end

function TileAnimator:clear()
  self.animations = {}
end

function TileAnimator:remove_tile(tile_id)
  self.animations[tile_id] = nil
end

return M