-- ReArkitekt/gui/widgets/panel/init.lua -- RENAMED
-- Main panel API with tab animation and mode toggle support

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

-- CHANGED: Updated require paths to use 'panel'
local Header = require('ReArkitekt.gui.widgets.panel.header')
local Content = require('ReArkitekt.gui.widgets.panel.content')
local Background = require('ReArkitekt.gui.widgets.panel.background')
local TabAnimator = require('ReArkitekt.gui.widgets.panel.tab_animator')
local Scrollbar = require('ReArkitekt.gui.widgets.controls.scrollbar')
local Config = require('ReArkitekt.gui.widgets.panel.config')

local M = {}
local DEFAULTS = Config.DEFAULTS

local function deep_merge(base, override)
  if not override then return base end
  if not base then return override end
  
  local result = {}
  
  for k, v in pairs(base) do
    result[k] = v
  end
  
  for k, v in pairs(override) do
    if type(v) == 'table' and type(result[k]) == 'table' then
      result[k] = deep_merge(result[k], v)
    else
      result[k] = v
    end
  end
  
  return result
end

local Panel = {} -- RENAMED: from Container to Panel
Panel.__index = Panel -- RENAMED: from Container to Panel

function M.new(opts)
  opts = opts or {}
  
  local panel = setmetatable({ -- RENAMED: from container to panel
    id = opts.id or "panel", -- CHANGED: Default id
    config = deep_merge(DEFAULTS, opts.config),
    
    width = opts.width,
    height = opts.height,
    
    show_overflow_modal = false, -- ADDED: Component now owns its UI state
    
    search_text = "",
    search_focused = false,
    search_alpha = 0.3,
    sort_mode = nil,
    sort_directions = {},
    sort_dropdown = nil,
    
    current_mode = opts.current_mode or "regions",
    
    tabs = {},
    active_tab_id = opts.active_tab_id,
    temp_search_mode = false,
    dragging_tab = nil,
    drop_target = nil,
    pending_delete_id = nil,
    tab_positions = {},
    
    tab_animator = nil,
    enable_tab_animations = opts.enable_tab_animations ~= false,
    
    on_search_changed = opts.on_search_changed,
    on_sort_changed = opts.on_sort_changed,
    on_sort_direction_changed = opts.on_sort_direction_changed,
    on_mode_changed = opts.on_mode_changed,
    on_tab_create = opts.on_tab_create,
    on_tab_change = opts.on_tab_change,
    on_tab_delete = opts.on_tab_delete,
    on_tab_reorder = opts.on_tab_reorder,
    -- REMOVED: on_overflow_tabs_clicked is no longer needed
    
    had_scrollbar_last_frame = false,
    last_content_height = 0,
    scrollbar_size = 0,
    scrollbar = nil,
    actual_child_height = 0,
    child_width = 0,
    child_height = 0,
    child_x = 0,
    child_y = 0,
  }, Panel) -- RENAMED: from Container to Panel
  
  if panel.enable_tab_animations then
    panel.tab_animator = TabAnimator.new({
      spawn_duration = opts.tab_spawn_duration or 0.22,
      destroy_duration = opts.tab_destroy_duration or 0.15,
      on_destroy_complete = function(tab_id)
        if panel.pending_delete_id == tab_id then
          panel.pending_delete_id = nil
        end
      end,
    })
  end
  
  if panel.config.scroll.custom_scrollbar then
    panel.scrollbar = Scrollbar.new({
      id = panel.id .. "_scrollbar",
      config = panel.config.scroll.scrollbar_config,
      on_scroll = function(scroll_pos)
      end,
    })
  end
  
  if opts.tabs then
    local TabsMode = require('ReArkitekt.gui.widgets.panel.modes.tabs') -- CHANGED: Path
    for _, tab in ipairs(opts.tabs) do
      TabsMode.assign_random_color(tab)
    end
    panel.tabs = opts.tabs
  end
  
  return panel
end

-- ADDED: New public methods to manage UI state
function Panel:is_overflow_visible()
  return self.show_overflow_modal
end

function Panel:close_overflow_modal()
  self.show_overflow_modal = false
end
-- End of added methods

function Panel:get_effective_child_width(ctx, base_width)
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

function Panel:begin_draw(ctx)
  local dt = ImGui.GetDeltaTime(ctx)
  self:update(dt)
  
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
    header_height = Header.draw(ctx, dl, x1, y1, w, header_cfg.height, self, self.config, self.config.rounding)
  end
  
  local content_y1 = y1 + header_height
  
  Background.draw(dl, x1, content_y1, x2, y2, self.config.background_pattern)
  
  if self.config.border_thickness > 0 then
    ImGui.DrawList_AddRect(
      dl,
      x1, y1,
      x2, y2,
      self.config.border_color,
      self.config.rounding,
      0,
      self.config.border_thickness
    )
  end
  
  local border_inset = self.config.border_thickness
  local child_x = x1 + border_inset
  local child_y = content_y1 + border_inset
  
  self.child_x = child_x
  self.child_y = child_y
  
  local scrollbar_width = 0
  if self.scrollbar then
    scrollbar_width = self.config.scroll.scrollbar_config.width
  end
  
  ImGui.SetCursorScreenPos(ctx, child_x, child_y)
  
  local child_w = w - (border_inset * 2) - scrollbar_width
  local child_h = (h - header_height) - (border_inset * 2)
  
  self.child_width = child_w
  self.child_height = child_h
  self.actual_child_height = child_h
  
  local success = Content.begin_child(ctx, self.id, child_w, child_h, self.config.scroll)
  
  if success and self.config.padding > 0 then
    ImGui.SetCursorPos(ctx, self.config.padding, self.config.padding)
  end
  
  return success
end

function Panel:end_draw(ctx)
  local content_height = ImGui.GetCursorPosY(ctx)
  local scroll_y = ImGui.GetScrollY(ctx)
  local scroll_max_y = ImGui.GetScrollMaxY(ctx)
  
  if self.scrollbar then
    self.scrollbar:set_content_height(content_height)
    self.scrollbar:set_visible_height(self.child_height)
    self.scrollbar:set_scroll_pos(scroll_y)
    
    if self.scrollbar.is_dragging then
      ImGui.SetScrollY(ctx, self.scrollbar:get_scroll_pos())
    end
  end
  
  Content.end_child(ctx, self)
  
  if self.scrollbar and self.scrollbar:is_scrollable() then
    local scrollbar_x = self.child_x + self.child_width - self.config.scroll.scrollbar_config.width
    local scrollbar_y = self.child_y
    
    self.scrollbar:draw(ctx, scrollbar_x, scrollbar_y, self.child_height)
  end
end

function Panel:reset()
  self.had_scrollbar_last_frame = false
  self.last_content_height = 0
  self.search_text = ""
  self.search_focused = false
  self.search_alpha = 0.3
  self.sort_mode = nil
  self.sort_directions = {}
  self.sort_dropdown = nil
  self.temp_search_mode = false
  self.dragging_tab = nil
  self.drop_target = nil
  self.pending_delete_id = nil
  self.tab_positions = {}
  
  if self.tab_animator then
    self.tab_animator:clear()
  end
  
  if self.scrollbar then
    self.scrollbar:set_scroll_pos(0)
  end
end

function Panel:update(dt)
  if self.scrollbar then
    self.scrollbar:update(dt or 0.016)
  end
end

function Panel:get_search_text()
  return self.search_text
end

function Panel:get_sort_mode()
  return self.sort_mode
end

function Panel:get_sort_direction()
  if not self.sort_mode or self.sort_mode == "" then
    return nil
  end
  return self.sort_directions[self.sort_mode] or "asc"
end

function Panel:set_search_text(text)
  self.search_text = text or ""
end

function Panel:set_sort_mode(mode)
  self.sort_mode = mode
  if self.sort_dropdown then
    self.sort_dropdown:set_value(mode)
  end
end

function Panel:set_sort_direction(mode, direction)
  if mode and mode ~= "" then
    self.sort_directions[mode] = direction or "asc"
    if self.sort_dropdown then
      self.sort_dropdown:set_direction(self.sort_directions[mode])
    end
  end
end

function Panel:set_current_mode(mode)
  self.current_mode = mode
end

function Panel:get_current_mode()
  return self.current_mode
end

function Panel:set_tabs(tabs, active_id)
  local old_ids = {}
  for _, tab in ipairs(self.tabs) do
    old_ids[tab.id] = true
  end
  
  self.tabs = tabs or {}
  
  local TabsMode = require('ReArkitekt.gui.widgets.panel.modes.tabs') -- CHANGED: Path
  for _, tab in ipairs(self.tabs) do
    TabsMode.assign_random_color(tab)
  end
  
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

function Panel:get_active_tab_id()
  return self.active_tab_id
end

function Panel:set_active_tab_id(id)
  self.active_tab_id = id
end

function Panel:add_tab(tab_data)
  local TabsMode = require('ReArkitekt.gui.widgets.panel.modes.tabs') -- CHANGED: Path
  TabsMode.assign_random_color(tab_data)
  
  table.insert(self.tabs, tab_data)
  if self.tab_animator then
    self.tab_animator:spawn(tab_data.id)
  end
end

function Panel:remove_tab(tab_id)
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
  
  local panel = M.new({ -- RENAMED: from container
    id = id,
    width = width,
    height = height,
    config = config,
    on_search_changed = on_search_changed,
    on_sort_changed = on_sort_changed,
  })
  
  if panel:begin_draw(ctx) then
    if content_fn then
      content_fn(ctx)
    end
  end
  panel:end_draw(ctx)
  
  return panel
end

return M