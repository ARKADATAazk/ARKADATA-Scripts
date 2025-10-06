-- ReArkitekt/gui/fx/tile_motion.lua
-- Per-tile animation state for smooth hover/active/selection transitions (refactored)
-- Manages multiple animation tracks per tile using extracted Track class

local Track = require('ReArkitekt.gui.fx.animation.track')

local M = {}

local TileAnimator = {}
TileAnimator.__index = TileAnimator

function M.new(default_speed)
  return setmetatable({
    tracks = {},
    default_speed = default_speed or 12.0,
  }, TileAnimator)
end

function TileAnimator:track(tile_id, track_name, target, speed)
  speed = speed or self.default_speed
  
  if not self.tracks[tile_id] then
    self.tracks[tile_id] = {}
  end
  
  if not self.tracks[tile_id][track_name] then
    self.tracks[tile_id][track_name] = Track.new(target, speed)
  else
    local t = self.tracks[tile_id][track_name]
    t:to(target)
    t:set_speed(speed)
  end
end

function TileAnimator:update(dt)
  for tile_id, tracks in pairs(self.tracks) do
    for track_name, track in pairs(tracks) do
      track:update(dt)
    end
  end
end

function TileAnimator:get(tile_id, track_name)
  if not self.tracks[tile_id] then return 0 end
  if not self.tracks[tile_id][track_name] then return 0 end
  return self.tracks[tile_id][track_name]:get()
end

function TileAnimator:clear()
  self.tracks = {}
end

function TileAnimator:remove_tile(tile_id)
  self.tracks[tile_id] = nil
end

return M