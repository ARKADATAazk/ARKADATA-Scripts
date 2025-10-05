-- ReArkitekt/gui/widgets/tiles_container.lua
-- Visual container for tile grids with scrolling and borders
-- Now with scrollbar-aware width calculation to prevent jitter

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local M = {}

----------------------------------------------------------------
-- DEFAULT CONFIGURATION
----------------------------------------------------------------
local DEFAULTS = {
  bg_color = 0x1C1C1CFF,
  border_color = 0x000000DD,
  border_thickness = 1,
  rounding = 8,
  
  padding = 8,
  
  scroll = {
    flags = 0,
    custom_scrollbar = false,
    bg_color = 0x00000000,
  },
  
  anti_jitter = {
    enabled = true,
    track_scrollbar = true,
    height_threshold = 5,
  },
}

----------------------------------------------------------------
-- Container Widget
----------------------------------------------------------------
local Container = {}
Container.__index = Container

function M.new(opts)
  opts = opts or {}
  
  local container = setmetatable({
    id = opts.id or "tiles_container",
    config = opts.config or DEFAULTS,
    
    width = opts.width,
    height = opts.height,
    
    had_scrollbar_last_frame = false,
    last_content_height = 0,
    scrollbar_size = 0,
  }, Container)
  
  return container
end

function Container:get_effective_child_width(ctx, base_width)
  local anti_jitter = self.config.anti_jitter or DEFAULTS.anti_jitter
  
  if not anti_jitter.enabled or not anti_jitter.track_scrollbar then
    return base_width
  end
  
  if self.scrollbar_size == 0 then
    self.scrollbar_size = ImGui.GetStyleVar(ctx, ImGui.StyleVar_ScrollbarSize) or 14
  end
  
  if self.had_scrollbar_last_frame then
    return base_width - self.scrollbar_size
  end
  
  return base_width
end

function Container:begin_draw(ctx)
  local avail_w, avail_h = ImGui.GetContentRegionAvail(ctx)
  local w = self.width or avail_w
  local h = self.height or avail_h
  
  local cursor_x, cursor_y = ImGui.GetCursorScreenPos(ctx)
  local dl = ImGui.GetWindowDrawList(ctx)
  
  local x1, y1 = cursor_x, cursor_y
  local x2, y2 = x1 + w, y1 + h
  
  ImGui.DrawList_AddRectFilled(
    dl, x1, y1, x2, y2,
    self.config.bg_color,
    self.config.rounding
  )
  
  ImGui.DrawList_AddRect(
    dl,
    x1 + 0.5, y1 + 0.5,
    x2 - 0.5, y2 - 0.5,
    self.config.border_color,
    self.config.rounding,
    0,
    self.config.border_thickness
  )
  
  ImGui.SetCursorScreenPos(ctx, x1 + self.config.padding, y1 + self.config.padding)
  
  local child_w = w - (self.config.padding * 2)
  local child_h = h - (self.config.padding * 2)
  
  self.actual_child_height = child_h
  
  local flags = self.config.scroll.flags or DEFAULTS.scroll.flags
  local scroll_bg = self.config.scroll.bg_color or DEFAULTS.scroll.bg_color
  ImGui.PushStyleColor(ctx, ImGui.Col_ScrollbarBg, scroll_bg)
  
  return ImGui.BeginChild(ctx, self.id .. "_scroll", child_w, child_h, ImGui.ChildFlags_None, flags)
end

function Container:end_draw(ctx)
  local anti_jitter = self.config.anti_jitter or DEFAULTS.anti_jitter
  
  if anti_jitter.enabled and anti_jitter.track_scrollbar then
    local cursor_y = ImGui.GetCursorPosY(ctx)
    local content_height = cursor_y
    
    local threshold = anti_jitter.height_threshold or DEFAULTS.anti_jitter.height_threshold
    
    if math.abs(content_height - self.last_content_height) > threshold then
      self.had_scrollbar_last_frame = content_height > (self.actual_child_height + threshold)
      self.last_content_height = content_height
    end
  end
  
  ImGui.EndChild(ctx)
  ImGui.PopStyleColor(ctx, 1)
end

function Container:reset()
  self.had_scrollbar_last_frame = false
  self.last_content_height = 0
end

----------------------------------------------------------------
-- Simple wrapper function for convenience
----------------------------------------------------------------
function M.draw(ctx, id, width, height, content_fn, config)
  config = config or DEFAULTS
  
  local container = M.new({
    id = id,
    width = width,
    height = height,
    config = config,
  })
  
  if container:begin_draw(ctx) then
    if content_fn then
      content_fn(ctx)
    end
  end
  container:end_draw(ctx)
end

return M