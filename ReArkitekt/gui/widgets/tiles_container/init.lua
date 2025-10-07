-- ReArkitekt/gui/widgets/tiles_container/init.lua
-- Main container API with tab animation support

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local Header = require('ReArkitekt.gui.widgets.tiles_container.header')
local Content = require('ReArkitekt.gui.widgets.tiles_container.content')
local Background = require('ReArkitekt.gui.widgets.tiles_container.background')
local TabAnimator = require('ReArkitekt.gui.widgets.tiles_container.tab_animator')

local M = {}

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
  
  background_pattern = {
    enabled = true,
    primary = {
      type = 'grid',
      spacing = 100,
      color = 0x40404060,
      dot_size = 2.5,
      line_thickness = 1.5,
    },
    secondary = {
      enabled = true,
      type = 'grid',
      spacing = 20,
      color = 0x30303040,
      dot_size = 1.5,
      line_thickness = 0.5,
    },
  },
  
  header = {
    enabled = true,
    height = 36,
    bg_color = 0x0F0F0FFF,
    border_color = 0x000000DD,
    padding_x = 12,
    padding_y = 8,
    spacing = 8,
    mode = 'search_sort',
    
    tabs = {
      enabled = true,
      reserved_right_space = 50,
      plus_button = {
        width = 28,
        height = 20,
        rounding = 4,
        icon = "+",
        bg_color = 0x2A2A2AFF,
        bg_hover_color = 0x3A3A3AFF,
        bg_active_color = 0x1A1A1AFF,
        border_color = 0x404040FF,
        border_hover_color = 0x42E896FF,
        text_color = 0xAAAAAAFF,
        text_hover_color = 0xFFFFFFFF,
      },
      tab = {
        min_width = 60,
        max_width = 180,
        height = 20,
        padding_x = 12,
        spacing = 6,
        rounding = 4,
        bg_color = 0x2A2A2AFF,
        bg_hover_color = 0x3A3A3AFF,
        bg_active_color = 0x42E89644,
        border_color = 0x404040FF,
        border_active_color = 0x42E896FF,
        text_color = 0xAAAAAAFF,
        text_hover_color = 0xFFFFFFFF,
        text_active_color = 0xFFFFFFFF,
      },
      context_menu = {
        bg_color = 0x1E1E1EFF,
        hover_color = 0x2E2E2EFF,
        text_color = 0xCCCCCCFF,
        separator_color = 0x404040FF,
        padding = 8,
        item_height = 24,
      },
      drag_config = {
        tile = {
          width = 60,
          height = 20,
          rounding = 4,
          stroke_thickness = 1.5,
          global_opacity = 0.85,
        },
        stack = {
          max_visible = 1,
        },
        shadow = {
          enabled = true,
          layers = 3,
          base_color = 0x00000066,
          offset = 3,
          blur_spread = 1.5,
        },
      },
      drop_config = {
        line_width = 2,
        glow_width = 10,
        pulse_speed = 3.0,
        line = {
          color = 0x42E896FF,
          glow_color = 0x42E89644,
        },
        caps = {
          width = 8,
          height = 3,
          rounding = 1,
          glow_size = 4,
          color = 0x42E896FF,
          glow_color = 0x42E89644,
        },
      },
    },
  },
}

local Container = {}
Container.__index = Container

function M.new(opts)
  opts = opts or {}
  
  local container = setmetatable({
    id = opts.id or "tiles_container",
    config = opts.config or DEFAULTS,
    
    width = opts.width,
    height = opts.height,
    
    search_text = "",
    search_focused = false,
    search_alpha = 0.3,
    sort_mode = nil,
    sort_direction = "asc",
    sort_dropdown = nil,
    
    tabs = opts.tabs or {},
    active_tab_id = opts.active_tab_id,
    temp_search_mode = false,
    dragging_tab = nil,
    drop_target = nil,
    pending_delete_id = nil,
    
    tab_animator = nil,
    enable_tab_animations = opts.enable_tab_animations ~= false,
    
    on_search_changed = opts.on_search_changed,
    on_sort_changed = opts.on_sort_changed,
    on_sort_direction_changed = opts.on_sort_direction_changed,
    on_tab_create = opts.on_tab_create,
    on_tab_change = opts.on_tab_change,
    on_tab_delete = opts.on_tab_delete,
    on_tab_reorder = opts.on_tab_reorder,
    
    had_scrollbar_last_frame = false,
    last_content_height = 0,
    scrollbar_size = 0,
    
    actual_child_height = 0,
  }, Container)
  
  if container.enable_tab_animations then
    container.tab_animator = TabAnimator.new({
      spawn_duration = opts.tab_spawn_duration or 0.22,
      destroy_duration = opts.tab_destroy_duration or 0.15,
      on_destroy_complete = function(tab_id)
        if container.pending_delete_id == tab_id then
          container.pending_delete_id = nil
        end
      end,
    })
  end
  
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
  
  local header_cfg = self.config.header or DEFAULTS.header
  local header_height = 0
  
  if header_cfg.enabled then
    header_height = Header.draw(ctx, dl, x1, y1, w, header_cfg.height, self, self.config)
  end
  
  local content_y1 = y1 + header_height
  
  Background.draw(dl, x1, content_y1, x2, y2, self.config.background_pattern)
  
  ImGui.DrawList_AddRect(
    dl,
    x1 + 0.5, y1 + 0.5,
    x2 - 0.5, y2 - 0.5,
    self.config.border_color,
    self.config.rounding,
    0,
    self.config.border_thickness
  )
  
  ImGui.SetCursorScreenPos(ctx, x1 + self.config.padding, content_y1 + self.config.padding)
  
  local child_w = w - (self.config.padding * 2)
  local child_h = (h - header_height) - (self.config.padding * 2)
  
  self.actual_child_height = child_h
  
  return Content.begin_child(ctx, self.id, child_w, child_h, self.config.scroll)
end

function Container:end_draw(ctx)
  Content.end_child(ctx, self)
end

function Container:reset()
  self.had_scrollbar_last_frame = false
  self.last_content_height = 0
  self.search_text = ""
  self.search_focused = false
  self.search_alpha = 0.3
  self.sort_mode = nil
  self.sort_dropdown = nil
  self.temp_search_mode = false
  self.dragging_tab = nil
  self.drop_target = nil
  self.pending_delete_id = nil
  
  if self.tab_animator then
    self.tab_animator:clear()
  end
end

function Container:get_search_text()
  return self.search_text
end

function Container:get_sort_mode()
  return self.sort_mode
end

function Container:set_search_text(text)
  self.search_text = text or ""
end

function Container:set_sort_mode(mode)
  self.sort_mode = mode
  if self.sort_dropdown then
    self.sort_dropdown:set_value(mode)
  end
end

function Container:set_sort_direction(direction)
  self.sort_direction = direction or "asc"
  if self.sort_dropdown then
    self.sort_dropdown:set_direction(direction)
  end
end

function Container:set_tabs(tabs, active_id)
  local old_ids = {}
  for _, tab in ipairs(self.tabs) do
    old_ids[tab.id] = true
  end
  
  self.tabs = tabs or {}
  
  if self.tab_animator then
    for _, tab in ipairs(self.tabs) do
      if not old_ids[tab.id] then
        self.tab_animator:spawn(tab.id)
      end
    end
  end
  
  if active_id then
    self.active_tab_id = active_id
  elseif #self.tabs > 0 then
    self.active_tab_id = self.tabs[1].id
  end
end

function Container:get_active_tab_id()
  return self.active_tab_id
end

function Container:set_active_tab_id(id)
  self.active_tab_id = id
end

function Container:add_tab(tab_data)
  table.insert(self.tabs, tab_data)
  if self.tab_animator then
    self.tab_animator:spawn(tab_data.id)
  end
end

function Container:remove_tab(tab_id)
  if self.tab_animator then
    self.tab_animator:destroy(tab_id)
    self.pending_delete_id = tab_id
  else
    for i, tab in ipairs(self.tabs) do
      if tab.id == tab_id then
        table.remove(self.tabs, i)
        break
      end
    end
  end
end

function M.draw(ctx, id, width, height, content_fn, config, on_search_changed, on_sort_changed)
  config = config or DEFAULTS
  
  local container = M.new({
    id = id,
    width = width,
    height = height,
    config = config,
    on_search_changed = on_search_changed,
    on_sort_changed = on_sort_changed,
  })
  
  if container:begin_draw(ctx) then
    if content_fn then
      content_fn(ctx)
    end
  end
  container:end_draw(ctx)
  
  return container
end

return M