-- ReArkitekt/gui/widgets/transport/transport_container.lua
-- Glass transport container with obsidian aesthetics

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.10'

local TransportFX = require('ReArkitekt.gui.widgets.transport.transport_fx')

local M = {}

local DEFAULTS = {
  padding = {
    top = 12,
    bottom = 12,
    left = 16,
    right = 16,
  },
  
  height = 48,
  
  fx = TransportFX.DEFAULT_CONFIG,
  
  hover_fade_speed = 6.0,
}

local TransportContainer = {}
TransportContainer.__index = TransportContainer

function M.new(opts)
  opts = opts or {}
  
  local container = setmetatable({
    id = opts.id or "transport_container",
    config = opts.config or DEFAULTS,
    
    height = opts.height or DEFAULTS.height,
    width = opts.width,
    
    hover_alpha = 0.0,
    last_bounds = { x1 = 0, y1 = 0, x2 = 0, y2 = 0 },
    
    on_hover_changed = opts.on_hover_changed,
  }, TransportContainer)
  
  return container
end

function TransportContainer:update_hover_state(ctx, x1, y1, x2, y2, dt)
  local mx, my = ImGui.GetMousePos(ctx)
  local is_hovered = mx >= x1 and mx < x2 and my >= y1 and my < y2
  
  local target_alpha = is_hovered and 1.0 or 0.0
  local fade_speed = self.config.hover_fade_speed or DEFAULTS.hover_fade_speed
  
  local delta = (target_alpha - self.hover_alpha) * fade_speed * dt
  self.hover_alpha = math.max(0.0, math.min(1.0, self.hover_alpha + delta))
  
  return is_hovered
end

function TransportContainer:begin_draw(ctx)
  local avail_w, avail_h = ImGui.GetContentRegionAvail(ctx)
  local w = self.width or avail_w
  local h = self.height
  
  local cursor_x, cursor_y = ImGui.GetCursorScreenPos(ctx)
  local dl = ImGui.GetWindowDrawList(ctx)
  
  local x1, y1 = cursor_x, cursor_y
  local x2, y2 = x1 + w, y1 + h
  
  self.last_bounds = { x1 = x1, y1 = y1, x2 = x2, y2 = y2 }
  
  local dt = ImGui.GetDeltaTime(ctx)
  local is_hovered = self:update_hover_state(ctx, x1, y1, x2, y2, dt)
  
  TransportFX.render_complete(dl, x1, y1, x2, y2, self.config.fx, self.hover_alpha)
  
  if self.on_hover_changed then
    self.on_hover_changed(is_hovered, self.hover_alpha)
  end
  
  local padding = self.config.padding or DEFAULTS.padding
  local content_x = x1 + padding.left
  local content_y = y1 + padding.top
  local content_w = w - padding.left - padding.right
  local content_h = h - padding.top - padding.bottom
  
  ImGui.SetCursorScreenPos(ctx, content_x, content_y)
  
  return content_w, content_h
end

function TransportContainer:end_draw(ctx)
  local bounds = self.last_bounds
  ImGui.SetCursorScreenPos(ctx, bounds.x1, bounds.y2)
end

function TransportContainer:reset()
  self.hover_alpha = 0.0
end

function TransportContainer:get_hover_factor()
  return self.hover_alpha
end

function TransportContainer:set_height(height)
  self.height = height
end

function TransportContainer:set_width(width)
  self.width = width
end

function M.draw(ctx, id, width, height, content_fn, config)
  config = config or DEFAULTS
  
  local container = M.new({
    id = id,
    width = width,
    height = height,
    config = config,
  })
  
  local content_w, content_h = container:begin_draw(ctx)
  
  if content_fn then
    content_fn(ctx, content_w, content_h)
  end
  
  container:end_draw(ctx)
  
  return container
end

return M