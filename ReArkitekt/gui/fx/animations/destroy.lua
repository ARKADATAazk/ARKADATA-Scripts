-- ReArkitekt/gui/fx/animations/destroy.lua
-- Destroy animation: instant red flash then smooth dissolve (refactored)

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'
local Easing = require('ReArkitekt.gui.fx.easing')

local M = {}

local DestroyAnim = {}
DestroyAnim.__index = DestroyAnim

function M.new(opts)
  opts = opts or {}
  
  return setmetatable({
    duration = opts.duration or 0.10,
    destroying = {},
    on_complete = opts.on_complete,
  }, DestroyAnim)
end

function DestroyAnim:destroy(key, rect)
  if not key or not rect then return end
  
  self.destroying[key] = {
    elapsed = 0,
    rect = {rect[1], rect[2], rect[3], rect[4]},
  }
end

function DestroyAnim:is_destroying(key)
  return self.destroying[key] ~= nil
end

function DestroyAnim:update(dt)
  dt = dt or 0.016
  
  local completed = {}
  
  for key, anim in pairs(self.destroying) do
    anim.elapsed = anim.elapsed + dt
    
    if anim.elapsed >= self.duration then
      completed[#completed + 1] = key
    end
  end
  
  for _, key in ipairs(completed) do
    self.destroying[key] = nil
    if self.on_complete then
      self.on_complete(key)
    end
  end
end

function DestroyAnim:get_factor(key)
  local anim = self.destroying[key]
  if not anim then return 0 end
  
  local t = math.min(1, anim.elapsed / self.duration)
  return Easing.ease_out_quad(t)
end

function DestroyAnim:render(ctx, dl, key, base_rect, base_color, rounding)
  local anim = self.destroying[key]
  if not anim then return false end
  
  local t = math.min(1, anim.elapsed / self.duration)
  local rect = anim.rect
  
  local x1, y1, x2, y2 = rect[1], rect[2], rect[3], rect[4]
  local cx = (x1 + x2) * 0.5
  local cy = (y1 + y2) * 0.5
  local w = x2 - x1
  local h = y2 - y1
  
  local zoom_factor = 1.0 + t * 0.08
  local new_w = w * zoom_factor
  local new_h = h * zoom_factor
  
  local nx1 = cx - new_w * 0.5
  local ny1 = cy - new_h * 0.5
  local nx2 = cx + new_w * 0.5
  local ny2 = cy + new_h * 0.5
  
  local target_red = 0xAA333388
  
  local r1 = (base_color >> 24) & 0xFF
  local g1 = (base_color >> 16) & 0xFF
  local b1 = (base_color >> 8) & 0xFF
  local a1 = base_color & 0xFF
  
  local r2 = (target_red >> 24) & 0xFF
  local g2 = (target_red >> 16) & 0xFF
  local b2 = (target_red >> 8) & 0xFF
  
  local red_factor = math.min(1, t * 3)
  
  local r = math.floor(r1 + (r2 - r1) * red_factor)
  local g = math.floor(g1 + (g2 - g1) * red_factor)
  local b = math.floor(b1 + (b2 - b1) * red_factor)
  local a = math.floor(a1 * (1 - Easing.ease_out_quad(t) * 0.9))
  
  local flash_color = (r << 24) | (g << 16) | (b << 8) | a
  
  ImGui.DrawList_AddRectFilled(dl, nx1, ny1, nx2, ny2, flash_color, rounding)
  
  local blur_intensity = Easing.ease_out_quad(t)
  local blur_layers = math.floor(blur_intensity * 3) + 1
  for i = 1, blur_layers do
    local offset = i * 1.5 * blur_intensity
    local blur_alpha = math.floor(a * 0.2 / blur_layers)
    local blur_color = (r << 24) | (g << 16) | (b << 8) | blur_alpha
    
    ImGui.DrawList_AddRectFilled(dl, 
      nx1 - offset, ny1 - offset, 
      nx2 + offset, ny2 + offset, 
      blur_color, rounding + offset * 0.3)
  end
  
  local cross_alpha = math.floor(255 * (1 - Easing.ease_out_quad(t)))
  local cross_color = 0xFF444400 | cross_alpha
  local cross_thickness = 2.5
  
  local cross_size = 20
  local cross_half = cross_size * 0.5
  ImGui.DrawList_AddLine(dl, 
    cx - cross_half, cy - cross_half, 
    cx + cross_half, cy + cross_half, 
    cross_color, cross_thickness)
  ImGui.DrawList_AddLine(dl, 
    cx + cross_half, cy - cross_half, 
    cx - cross_half, cy + cross_half, 
    cross_color, cross_thickness)
  
  return true
end

function DestroyAnim:clear()
  self.destroying = {}
end

function DestroyAnim:remove(key)
  self.destroying[key] = nil
end

return M