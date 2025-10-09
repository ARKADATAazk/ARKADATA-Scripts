-- ReArkitekt/gui/widgets/controls/scrollbar.lua
-- Custom scrollbar with smooth animations

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local M = {}

local Scrollbar = {}
Scrollbar.__index = Scrollbar

local DEFAULTS = {
  width = 12,
  padding = 2,
  min_thumb_height = 30,
  
  track_color = 0x00000000,
  track_hover_color = 0x0F0F0FFF,
  
  thumb_color = 0x3A3A3AFF,
  thumb_hover_color = 0x4A4A4AFF,
  thumb_active_color = 0x5A5A5AFF,
  
  thumb_rounding = 4,
  track_rounding = 0,
  
  fade_speed = 10.0,
  auto_hide = false,
  auto_hide_delay = 1.0,
}

function M.new(opts)
  opts = opts or {}
  
  return setmetatable({
    id = opts.id or "scrollbar",
    config = opts.config or DEFAULTS,
    
    scroll_pos = 0,
    content_height = 0,
    visible_height = 0,
    
    is_dragging = false,
    drag_start_y = 0,
    drag_start_scroll = 0,
    
    hover_alpha = 0.0,
    last_interaction = 0,
    
    on_scroll = opts.on_scroll,
  }, Scrollbar)
end

function Scrollbar:update(dt)
  local now = reaper.time_precise()
  
  local target_alpha = 1.0
  if self.config.auto_hide then
    local time_since_interaction = now - self.last_interaction
    if time_since_interaction > self.config.auto_hide_delay and not self.is_dragging then
      target_alpha = 0.0
    end
  end
  
  local alpha_delta = (target_alpha - self.hover_alpha) * self.config.fade_speed * dt
  self.hover_alpha = math.max(0.0, math.min(1.0, self.hover_alpha + alpha_delta))
end

function Scrollbar:set_content_height(height)
  self.content_height = height
end

function Scrollbar:set_visible_height(height)
  self.visible_height = height
end

function Scrollbar:set_scroll_pos(pos)
  self.scroll_pos = math.max(0, math.min(pos, self:get_max_scroll()))
end

function Scrollbar:get_scroll_pos()
  return self.scroll_pos
end

function Scrollbar:get_max_scroll()
  return math.max(0, self.content_height - self.visible_height)
end

function Scrollbar:is_scrollable()
  return self.content_height > self.visible_height
end

function Scrollbar:get_thumb_height()
  if not self:is_scrollable() then
    return 0
  end
  
  local ratio = self.visible_height / self.content_height
  local thumb_h = self.visible_height * ratio
  return math.max(self.config.min_thumb_height, thumb_h)
end

function Scrollbar:get_thumb_position(track_height)
  if not self:is_scrollable() then
    return 0
  end
  
  local max_scroll = self:get_max_scroll()
  if max_scroll <= 0 then
    return 0
  end
  
  local thumb_h = self:get_thumb_height()
  local available_track = track_height - thumb_h
  
  local scroll_ratio = self.scroll_pos / max_scroll
  return scroll_ratio * available_track
end

function Scrollbar:draw(ctx, x, y, height)
  if not self:is_scrollable() then
    return
  end
  
  if self.config.auto_hide and self.hover_alpha < 0.01 then
    return
  end
  
  local dl = ImGui.GetWindowDrawList(ctx)
  local cfg = self.config
  
  local track_x = x + cfg.padding
  local track_y = y
  local track_w = cfg.width - (cfg.padding * 2)
  local track_h = height
  
  local mx, my = ImGui.GetMousePos(ctx)
  local is_track_hovered = mx >= track_x and mx < track_x + track_w and 
                           my >= track_y and my < track_y + track_h
  
  local thumb_h = self:get_thumb_height()
  local thumb_y = track_y + self:get_thumb_position(track_h)
  
  local is_thumb_hovered = mx >= track_x and mx < track_x + track_w and 
                           my >= thumb_y and my < thumb_y + thumb_h
  
  if is_track_hovered or is_thumb_hovered or self.is_dragging then
    self.last_interaction = reaper.time_precise()
  end
  
  local apply_alpha = function(color, alpha)
    local a = color & 0xFF
    local new_a = math.floor(a * alpha)
    return (color & 0xFFFFFF00) | new_a
  end
  
  local track_color = is_track_hovered and cfg.track_hover_color or cfg.track_color
  track_color = apply_alpha(track_color, self.hover_alpha)
  
  if (track_color & 0xFF) > 0 then
    ImGui.DrawList_AddRectFilled(dl, track_x, track_y, track_x + track_w, track_y + track_h,
                                  track_color, cfg.track_rounding)
  end
  
  local thumb_color = cfg.thumb_color
  if self.is_dragging then
    thumb_color = cfg.thumb_active_color
  elseif is_thumb_hovered then
    thumb_color = cfg.thumb_hover_color
  end
  thumb_color = apply_alpha(thumb_color, self.hover_alpha)
  
  ImGui.DrawList_AddRectFilled(dl, track_x, thumb_y, track_x + track_w, thumb_y + thumb_h,
                                thumb_color, cfg.thumb_rounding)
  
  ImGui.SetCursorScreenPos(ctx, track_x, track_y)
  ImGui.InvisibleButton(ctx, self.id .. "_track", track_w, track_h)
  
  if ImGui.IsItemActive(ctx) then
    if not self.is_dragging then
      self.is_dragging = true
      self.drag_start_y = my
      self.drag_start_scroll = self.scroll_pos
      
      local click_in_thumb = my >= thumb_y and my < thumb_y + thumb_h
      if not click_in_thumb then
        local click_ratio = (my - track_y) / track_h
        local target_scroll = click_ratio * self.content_height - (self.visible_height * 0.5)
        self:set_scroll_pos(target_scroll)
        
        if self.on_scroll then
          self.on_scroll(self.scroll_pos)
        end
      end
    else
      local delta_y = my - self.drag_start_y
      local max_scroll = self:get_max_scroll()
      local available_track = track_h - thumb_h
      
      if available_track > 0 then
        local scroll_delta = (delta_y / available_track) * max_scroll
        self:set_scroll_pos(self.drag_start_scroll + scroll_delta)
        
        if self.on_scroll then
          self.on_scroll(self.scroll_pos)
        end
      end
    end
  elseif self.is_dragging and not ImGui.IsMouseDown(ctx, 0) then
    self.is_dragging = false
  end
  
  if is_track_hovered then
    ImGui.SetMouseCursor(ctx, ImGui.MouseCursor_Hand)
  end
end

function Scrollbar:handle_wheel(ctx, wheel_delta, scroll_speed)
  if not self:is_scrollable() then
    return false
  end
  
  if wheel_delta ~= 0 then
    local delta = -wheel_delta * (scroll_speed or 50)
    self:set_scroll_pos(self.scroll_pos + delta)
    self.last_interaction = reaper.time_precise()
    
    if self.on_scroll then
      self.on_scroll(self.scroll_pos)
    end
    
    return true
  end
  
  return false
end

return M