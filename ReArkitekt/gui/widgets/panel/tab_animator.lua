-- ReArkitekt/gui/widgets/tiles_container/tab_animator.lua
-- Tab spawn/destroy animation manager

local Easing = require('ReArkitekt.gui.fx.easing')

local M = {}

local TabAnimator = {}
TabAnimator.__index = TabAnimator

function M.new(opts)
  opts = opts or {}
  
  return setmetatable({
    spawn_duration = opts.spawn_duration or 0.22,
    destroy_duration = opts.destroy_duration or 0.15,
    spawning = {},
    destroying = {},
    on_destroy_complete = opts.on_destroy_complete,
  }, TabAnimator)
end

function TabAnimator:spawn(tab_id)
  self.spawning[tab_id] = {
    start_time = reaper.time_precise(),
  }
end

function TabAnimator:destroy(tab_id)
  self.destroying[tab_id] = {
    start_time = reaper.time_precise(),
  }
end

function TabAnimator:is_spawning(tab_id)
  return self.spawning[tab_id] ~= nil
end

function TabAnimator:is_destroying(tab_id)
  return self.destroying[tab_id] ~= nil
end

function TabAnimator:update()
  local now = reaper.time_precise()
  
  local spawn_complete = {}
  for id, anim in pairs(self.spawning) do
    local elapsed = now - anim.start_time
    if elapsed >= self.spawn_duration then
      spawn_complete[#spawn_complete + 1] = id
    end
  end
  
  for _, id in ipairs(spawn_complete) do
    self.spawning[id] = nil
  end
  
  local destroy_complete = {}
  for id, anim in pairs(self.destroying) do
    local elapsed = now - anim.start_time
    if elapsed >= self.destroy_duration then
      destroy_complete[#destroy_complete + 1] = id
    end
  end
  
  for _, id in ipairs(destroy_complete) do
    self.destroying[id] = nil
    if self.on_destroy_complete then
      self.on_destroy_complete(id)
    end
  end
end

function TabAnimator:get_spawn_factor(tab_id)
  local anim = self.spawning[tab_id]
  if not anim then return 1.0 end
  
  local now = reaper.time_precise()
  local elapsed = now - anim.start_time
  local t = math.min(1.0, elapsed / self.spawn_duration)
  
  return Easing.ease_out_cubic(t)
end

function TabAnimator:get_destroy_factor(tab_id)
  local anim = self.destroying[tab_id]
  if not anim then return 0.0 end
  
  local now = reaper.time_precise()
  local elapsed = now - anim.start_time
  local t = math.min(1.0, elapsed / self.destroy_duration)
  
  return Easing.ease_in_cubic(t)
end

function TabAnimator:clear()
  self.spawning = {}
  self.destroying = {}
end

function TabAnimator:remove(tab_id)
  self.spawning[tab_id] = nil
  self.destroying[tab_id] = nil
end

return M