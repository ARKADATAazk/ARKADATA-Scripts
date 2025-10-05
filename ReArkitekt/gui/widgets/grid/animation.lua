-- ReArkitekt/gui/widgets/grid/animation.lua
-- Animation coordination for grid spawn/destroy effects
-- Thin wrapper around spawn_anim and destroy_anim systems

local SpawnAnim = require('ReArkitekt.gui.systems.spawn_animation')
local DestroyAnim = require('ReArkitekt.gui.systems.destroy_animation')

local M = {}

local AnimationCoordinator = {}
AnimationCoordinator.__index = AnimationCoordinator

function M.new(config)
  config = config or {}
  
  local spawn_cfg = config.spawn or { enabled = true, duration = 0.28 }
  local destroy_cfg = config.destroy or { enabled = true }
  
  return setmetatable({
    spawn_anim = SpawnAnim.new({
      duration = spawn_cfg.duration or 0.28,
    }),
    destroy_anim = DestroyAnim.new({
      duration = destroy_cfg.duration or 0.10,
      on_complete = config.on_destroy_complete,
    }),
    spawn_enabled = spawn_cfg.enabled ~= false,
    destroy_enabled = destroy_cfg.enabled ~= false,
    allow_spawn_on_new = false,
  }, AnimationCoordinator)
end

function AnimationCoordinator:mark_spawned(keys)
  if not self.spawn_enabled then return end
  self.allow_spawn_on_new = true
end

function AnimationCoordinator:mark_destroyed(keys)
  if not self.destroy_enabled then
    if self.destroy_anim.on_complete then
      for _, key in ipairs(keys) do
        self.destroy_anim.on_complete(key)
      end
    end
    return
  end
  
  for _, key in ipairs(keys) do
    local rect = self.rect_track and self.rect_track:get(key)
    if rect then
      self.destroy_anim:destroy(key, rect)
    end
  end
end

function AnimationCoordinator:set_rect_track(rect_track)
  self.rect_track = rect_track
end

function AnimationCoordinator:handle_spawn(new_keys, rect_track)
  if not self.spawn_enabled or not self.allow_spawn_on_new then return end
  if #new_keys == 0 then return end
  
  for _, key in ipairs(new_keys) do
    local rect = rect_track:get(key)
    if rect then
      self.spawn_anim:spawn(key, rect)
    end
  end
  self.allow_spawn_on_new = false
end

function AnimationCoordinator:update(dt)
  self.destroy_anim:update(dt)
end

function AnimationCoordinator:apply_spawn_to_rect(key, rect)
  if not self.spawn_anim:is_spawning(key) then
    return rect
  end
  
  local width_factor = self.spawn_anim:get_width_factor(key)
  local full_width = rect[3] - rect[1]
  local spawn_width = full_width * width_factor
  return {rect[1], rect[2], rect[1] + spawn_width, rect[4]}
end

function AnimationCoordinator:render_destroy_effects(ctx, dl)
  for key, anim_data in pairs(self.destroy_anim.destroying) do
    self.destroy_anim:render(ctx, dl, key, anim_data.rect, 0x1A1A1AFF, 6)
  end
end

function AnimationCoordinator:clear()
  self.spawn_anim:clear()
  self.destroy_anim:clear()
  self.allow_spawn_on_new = false
end

return M