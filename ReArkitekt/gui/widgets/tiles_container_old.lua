-- ReArkitekt/gui/widgets/tiles_container.lua
-- Visual container for tile grids with scrolling, borders, and interactive header
-- Updated with tabs support and CTRL+F search overlay

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local Dropdown = require('ReArkitekt.gui.widgets.controls.dropdown')

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
      plus_button = {
        width = 28,
        height = 24,
        bg_color = 0x252525FF,
        bg_hover_color = 0x303030FF,
        bg_active_color = 0x3A3A3AFF,
        text_color = 0x999999FF,
        text_hover_color = 0xFFFFFFFF,
        border_color = 0x353535FF,
        border_hover_color = 0x454545FF,
        rounding = 3,
        icon = "+",
      },
      tab = {
        min_width = 80,
        max_width = 150,
        height = 24,
        padding_x = 12,
        spacing = 4,
        bg_color = 0x1A1A1AFF,
        bg_hover_color = 0x252525FF,
        bg_active_color = 0x2A2A2AFF,
        text_color = 0xBBBBBBFF,
        text_hover_color = 0xFFFFFFFF,
        text_active_color = 0xFFFFFFFF,
        border_color = 0x353535FF,
        border_active_color = 0x41E0A3FF,
        rounding = 3,
        close_button = {
          enabled = true,
          size = 14,
          padding = 2,
          color = 0x666666FF,
          hover_color = 0xE84A4AFF,
        },
      },
      reserved_right_space = 100,
    },
    
    search = {
      enabled = true,
      placeholder = "Search...",
      width_ratio = 0.5,
      min_width = 150,
      bg_color = 0x141414FF,
      bg_hover_color = 0x1A1A1AFF,
      bg_active_color = 0x242424FF,
      text_color = 0xFFFFFFFF,
      placeholder_color = 0x666666FF,
      border_color = 0x333333FF,
      border_active_color = 0x41E0A3FF,
      rounding = 3,
      fade_speed = 8.0,
    },
    
    sort_dropdown = {
      enabled = true,
      width = 120,
      height = 26,
      tooltip = "Sorting",
      tooltip_delay = 0.5,
      bg_color = 0x252525FF,
      bg_hover_color = 0x303030FF,
      bg_active_color = 0x3A3A3AFF,
      text_color = 0xCCCCCCFF,
      text_hover_color = 0xFFFFFFFF,
      border_color = 0x353535FF,
      border_hover_color = 0x454545FF,
      rounding = 4,
      padding_x = 10,
      padding_y = 6,
      arrow_size = 4,
      arrow_color = 0x999999FF,
      arrow_hover_color = 0xEEEEEEFF,
      
      popup = {
        bg_color = 0x1E1E1EFF,
        border_color = 0x404040FF,
        item_bg_color = 0x00000000,
        item_hover_color = 0x3A3A3AFF,
        item_active_color = 0x454545FF,
        item_text_color = 0xCCCCCCFF,
        item_text_hover_color = 0xFFFFFFFF,
        item_selected_color = 0x2A2A2AFF,
        item_selected_text_color = 0xFFFFFFFF,
        rounding = 4,
        padding = 4,
        item_height = 24,
        item_padding_x = 10,
        border_thickness = 1,
      },
      
      options = {
        { value = nil, label = "No Sort" },
        { value = "color", label = "Color" },
        { value = "index", label = "Index" },
        { value = "alpha", label = "Alphabetical" },
      },
    },
    
    info_display = {
      enabled = false,
      show_count = true,
      show_filtered_count = true,
      text_color = 0x999999FF,
      highlight_color = 0x41E0A3FF,
    },
  },
}

local function draw_grid_pattern(dl, x1, y1, x2, y2, spacing, color, thickness)
  local start_x = x1 + (spacing - (x1 % spacing))
  local start_y = y1 + (spacing - (y1 % spacing))
  
  for x = start_x, x2, spacing do
    ImGui.DrawList_AddLine(dl, x, y1, x, y2, color, thickness)
  end
  
  for y = start_y, y2, spacing do
    ImGui.DrawList_AddLine(dl, x1, y, x2, y, color, thickness)
  end
end

local function draw_dot_pattern(dl, x1, y1, x2, y2, spacing, color, dot_size)
  local half_size = dot_size * 0.5
  local start_x = x1 + (spacing - (x1 % spacing))
  local start_y = y1 + (spacing - (y1 % spacing))
  
  for x = start_x, x2, spacing do
    for y = start_y, y2, spacing do
      ImGui.DrawList_AddCircleFilled(dl, x, y, half_size, color)
    end
  end
end

local function draw_background_pattern(dl, x1, y1, x2, y2, pattern_cfg)
  if not pattern_cfg or not pattern_cfg.enabled then return end
  
  ImGui.DrawList_PushClipRect(dl, x1, y1, x2, y2, true)
  
  if pattern_cfg.secondary and pattern_cfg.secondary.enabled then
    local sec = pattern_cfg.secondary
    if sec.type == 'grid' then
      draw_grid_pattern(dl, x1, y1, x2, y2,
        sec.spacing or DEFAULTS.background_pattern.secondary.spacing,
        sec.color or DEFAULTS.background_pattern.secondary.color,
        sec.line_thickness or DEFAULTS.background_pattern.secondary.line_thickness)
    elseif sec.type == 'dots' then
      draw_dot_pattern(dl, x1, y1, x2, y2,
        sec.spacing or DEFAULTS.background_pattern.secondary.spacing,
        sec.color or DEFAULTS.background_pattern.secondary.color,
        sec.dot_size or DEFAULTS.background_pattern.secondary.dot_size)
    end
  end
  
  local pri = pattern_cfg.primary
  if pri.type == 'grid' then
    draw_grid_pattern(dl, x1, y1, x2, y2,
      pri.spacing or DEFAULTS.background_pattern.primary.spacing,
      pri.color or DEFAULTS.background_pattern.primary.color,
      pri.line_thickness or DEFAULTS.background_pattern.primary.line_thickness)
  elseif pri.type == 'dots' then
    draw_dot_pattern(dl, x1, y1, x2, y2,
      pri.spacing or DEFAULTS.background_pattern.primary.spacing,
      pri.color or DEFAULTS.background_pattern.primary.color,
      pri.dot_size or DEFAULTS.background_pattern.primary.dot_size)
  end
  
  ImGui.DrawList_PopClipRect(dl)
end

local function draw_search_bar(ctx, dl, x, y, width, height, state, cfg)
  local search_cfg = cfg.search
  if not search_cfg or not search_cfg.enabled then return x + width end
  
  local is_hovered = ImGui.IsMouseHoveringRect(ctx, x, y, x + width, y + height)
  local is_focused = state.search_focused
  
  state.search_alpha = state.search_alpha or 0.3
  local target_alpha = (is_focused or is_hovered or #state.search_text > 0) and 1.0 or 0.3
  local alpha_delta = (target_alpha - state.search_alpha) * search_cfg.fade_speed * ImGui.GetDeltaTime(ctx)
  state.search_alpha = math.max(0.3, math.min(1.0, state.search_alpha + alpha_delta))
  
  local bg_color = search_cfg.bg_color
  if is_focused then
    bg_color = search_cfg.bg_active_color
  elseif is_hovered then
    bg_color = search_cfg.bg_hover_color
  end
  
  local alpha_byte = math.floor(state.search_alpha * 255)
  bg_color = (bg_color & 0xFFFFFF00) | alpha_byte
  
  ImGui.DrawList_AddRectFilled(dl, x, y, x + width, y + height, bg_color, search_cfg.rounding)
  
  local border_color = is_focused and search_cfg.border_active_color or search_cfg.border_color
  border_color = (border_color & 0xFFFFFF00) | alpha_byte
  ImGui.DrawList_AddRect(dl, x, y, x + width, y + height, border_color, search_cfg.rounding, 0, 1)
  
  ImGui.SetCursorScreenPos(ctx, x + 8, y + (height - ImGui.GetTextLineHeight(ctx)) * 0.5)
  ImGui.PushItemWidth(ctx, width - 16)
  
  ImGui.PushStyleColor(ctx, ImGui.Col_FrameBg, 0x00000000)
  ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgHovered, 0x00000000)
  ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgActive, 0x00000000)
  ImGui.PushStyleColor(ctx, ImGui.Col_Border, 0x00000000)
  
  local text_color = search_cfg.text_color
  text_color = (text_color & 0xFFFFFF00) | alpha_byte
  ImGui.PushStyleColor(ctx, ImGui.Col_Text, text_color)
  
  local changed, new_text = ImGui.InputTextWithHint(ctx, "##search_" .. state.id, 
    search_cfg.placeholder, state.search_text, ImGui.InputTextFlags_None)
  
  if changed then
    state.search_text = new_text
    if state.on_search_changed then
      state.on_search_changed(new_text)
    end
  end
  
  state.search_focused = ImGui.IsItemActive(ctx)
  
  ImGui.PopStyleColor(ctx, 5)
  ImGui.PopItemWidth(ctx)
  
  return x + width
end

local function draw_sort_dropdown(ctx, x, y, content_height, state, cfg)
  local dropdown_cfg = cfg.sort_dropdown
  if not dropdown_cfg or not dropdown_cfg.enabled then return x end
  
  if not state.sort_dropdown then
    state.sort_dropdown = Dropdown.new({
      id = "sort_dropdown_" .. state.id,
      tooltip = dropdown_cfg.tooltip,
      tooltip_delay = dropdown_cfg.tooltip_delay,
      options = dropdown_cfg.options,
      current_value = state.sort_mode,
      sort_direction = state.sort_direction or "asc",
      on_change = function(value)
        state.sort_mode = value
        if state.on_sort_changed then
          state.on_sort_changed(value)
        end
      end,
      on_direction_change = function(direction)
        state.sort_direction = direction
        if state.on_sort_direction_changed then
          state.on_sort_direction_changed(direction)
        end
      end,
      config = {
        width = dropdown_cfg.width,
        height = dropdown_cfg.height,
        tooltip_delay = dropdown_cfg.tooltip_delay,
        bg_color = dropdown_cfg.bg_color,
        bg_hover_color = dropdown_cfg.bg_hover_color,
        bg_active_color = dropdown_cfg.bg_active_color,
        text_color = dropdown_cfg.text_color,
        text_hover_color = dropdown_cfg.text_hover_color,
        border_color = dropdown_cfg.border_color,
        border_hover_color = dropdown_cfg.border_hover_color,
        rounding = dropdown_cfg.rounding,
        padding_x = dropdown_cfg.padding_x,
        padding_y = dropdown_cfg.padding_y,
        arrow_size = dropdown_cfg.arrow_size,
        arrow_color = dropdown_cfg.arrow_color,
        arrow_hover_color = dropdown_cfg.arrow_hover_color,
        enable_mousewheel = true,
        popup = dropdown_cfg.popup,
      },
    })
  end
  
  local dropdown_y = y + (content_height - dropdown_cfg.height) * 0.5
  state.sort_dropdown:draw(ctx, x, dropdown_y)
  
  return x + dropdown_cfg.width
end

local function draw_plus_button(ctx, dl, x, y, state, cfg)
  local btn_cfg = cfg.tabs.plus_button
  local w = btn_cfg.width
  local h = btn_cfg.height
  
  local is_hovered = ImGui.IsMouseHoveringRect(ctx, x, y, x + w, y + h)
  local is_active = ImGui.IsMouseDown(ctx, 0) and is_hovered
  
  local bg_color = btn_cfg.bg_color
  if is_active then
    bg_color = btn_cfg.bg_active_color
  elseif is_hovered then
    bg_color = btn_cfg.bg_hover_color
  end
  
  local border_color = is_hovered and btn_cfg.border_hover_color or btn_cfg.border_color
  local text_color = is_hovered and btn_cfg.text_hover_color or btn_cfg.text_color
  
  ImGui.DrawList_AddRectFilled(dl, x, y, x + w, y + h, bg_color, btn_cfg.rounding)
  ImGui.DrawList_AddRect(dl, x, y, x + w, y + h, border_color, btn_cfg.rounding, 0, 1)
  
  local text_w, text_h = ImGui.CalcTextSize(ctx, btn_cfg.icon)
  local text_x = x + (w - text_w) * 0.5
  local text_y = y + (h - text_h) * 0.5
  ImGui.DrawList_AddText(dl, text_x, text_y, text_color, btn_cfg.icon)
  
  ImGui.SetCursorScreenPos(ctx, x, y)
  local clicked = ImGui.InvisibleButton(ctx, "##plus_" .. state.id, w, h)
  
  return clicked, x + w
end

local function draw_tab(ctx, dl, x, y, tab_data, is_active, state, cfg)
  local tab_cfg = cfg.tabs.tab
  local label = tab_data.label or "Tab"
  local id = tab_data.id
  
  local text_w, text_h = ImGui.CalcTextSize(ctx, label)
  
  local close_btn_space = 0
  if tab_cfg.close_button.enabled and #state.tabs > 1 then
    close_btn_space = tab_cfg.close_button.size + tab_cfg.close_button.padding
  end
  
  local w = math.min(tab_cfg.max_width, math.max(tab_cfg.min_width, text_w + tab_cfg.padding_x * 2 + close_btn_space))
  local h = tab_cfg.height
  
  local is_hovered = ImGui.IsMouseHoveringRect(ctx, x, y, x + w, y + h)
  local is_pressed = ImGui.IsMouseDown(ctx, 0) and is_hovered
  
  local bg_color = tab_cfg.bg_color
  if is_active then
    bg_color = tab_cfg.bg_active_color
  elseif is_pressed then
    bg_color = tab_cfg.bg_active_color
  elseif is_hovered then
    bg_color = tab_cfg.bg_hover_color
  end
  
  local border_color = is_active and tab_cfg.border_active_color or tab_cfg.border_color
  local text_color = is_active and tab_cfg.text_active_color or (is_hovered and tab_cfg.text_hover_color or tab_cfg.text_color)
  
  ImGui.DrawList_AddRectFilled(dl, x, y, x + w, y + h, bg_color, tab_cfg.rounding)
  ImGui.DrawList_AddRect(dl, x, y, x + w, y + h, border_color, tab_cfg.rounding, 0, 1)
  
  local text_x = x + tab_cfg.padding_x
  local text_y = y + (h - text_h) * 0.5
  
  local text_max_w = w - tab_cfg.padding_x * 2 - close_btn_space
  if text_w > text_max_w then
    ImGui.DrawList_PushClipRect(dl, x + tab_cfg.padding_x, y, x + w - tab_cfg.padding_x - close_btn_space, y + h, true)
    ImGui.DrawList_AddText(dl, text_x, text_y, text_color, label)
    ImGui.DrawList_PopClipRect(dl)
  else
    ImGui.DrawList_AddText(dl, text_x, text_y, text_color, label)
  end
  
  ImGui.SetCursorScreenPos(ctx, x, y)
  local clicked = ImGui.InvisibleButton(ctx, "##tab_" .. id .. "_" .. state.id, w, h)
  
  local close_clicked = false
  if tab_cfg.close_button.enabled and #state.tabs > 1 then
    local close_size = tab_cfg.close_button.size
    local close_x = x + w - tab_cfg.padding_x - close_size
    local close_y = y + (h - close_size) * 0.5
    
    local close_hovered = ImGui.IsMouseHoveringRect(ctx, close_x, close_y, close_x + close_size, close_y + close_size)
    local close_color = close_hovered and tab_cfg.close_button.hover_color or tab_cfg.close_button.color
    
    local padding = 3
    ImGui.DrawList_AddLine(dl, close_x + padding, close_y + padding, close_x + close_size - padding, close_y + close_size - padding, close_color, 1.5)
    ImGui.DrawList_AddLine(dl, close_x + close_size - padding, close_y + padding, close_x + padding, close_y + close_size - padding, close_color, 1.5)
    
    ImGui.SetCursorScreenPos(ctx, close_x, close_y)
    if ImGui.InvisibleButton(ctx, "##close_" .. id .. "_" .. state.id, close_size, close_size) then
      close_clicked = true
    end
  end
  
  return clicked, close_clicked, x + w
end

local function draw_tabs_header(ctx, dl, x, y, width, height, state, cfg)
  local tabs_cfg = cfg.tabs
  if not tabs_cfg or not tabs_cfg.enabled then return 0 end
  
  local cursor_x = x + cfg.padding_x
  local cursor_y = y + cfg.padding_y
  local content_height = height - (cfg.padding_y * 2)
  
  local plus_clicked, new_x = draw_plus_button(ctx, dl, cursor_x, cursor_y, state, cfg)
  cursor_x = new_x + tabs_cfg.tab.spacing
  
  if plus_clicked and state.on_tab_create then
    state.on_tab_create()
  end
  
  local available_width = width - (cursor_x - x) - tabs_cfg.reserved_right_space
  
  for i, tab_data in ipairs(state.tabs) do
    local is_active = (tab_data.id == state.active_tab_id)
    local clicked, close_clicked, next_x = draw_tab(ctx, dl, cursor_x, cursor_y, tab_data, is_active, state, cfg)
    
    if clicked and state.on_tab_change then
      state.on_tab_change(tab_data.id)
    end
    
    if close_clicked and state.on_tab_delete then
      state.on_tab_delete(tab_data.id)
    end
    
    cursor_x = next_x + tabs_cfg.tab.spacing
    
    if cursor_x - x > available_width then
      break
    end
  end
  
  return height
end

local function draw_search_sort_header(ctx, dl, x, y, width, height, state, cfg)
  local header_cfg = cfg
  
  local cursor_x = x + header_cfg.padding_x
  local cursor_y = y + header_cfg.padding_y
  local content_height = height - (header_cfg.padding_y * 2)
  
  if header_cfg.search and header_cfg.search.enabled then
    local search_width = math.max(
      header_cfg.search.min_width,
      width * header_cfg.search.width_ratio
    )
    
    cursor_x = draw_search_bar(ctx, dl, cursor_x, cursor_y, 
      search_width, content_height, state, header_cfg)
    cursor_x = cursor_x + header_cfg.spacing
  end
  
  if header_cfg.sort_dropdown and header_cfg.sort_dropdown.enabled then
    cursor_x = draw_sort_dropdown(ctx, cursor_x, cursor_y, content_height, state, header_cfg)
  end
  
  return height
end

local function draw_header(ctx, dl, x, y, width, height, state, cfg)
  local header_cfg = cfg.header
  if not header_cfg or not header_cfg.enabled then return 0 end
  
  ImGui.DrawList_AddRectFilled(dl, x, y, x + width, y + height, 
    header_cfg.bg_color, 0)
  
  ImGui.DrawList_AddLine(dl, x, y + height, x + width, y + height, 
    header_cfg.border_color, 1)
  
  local ctrl_pressed = ImGui.IsKeyDown(ctx, ImGui.Key_LeftCtrl) or ImGui.IsKeyDown(ctx, ImGui.Key_RightCtrl)
  local f_pressed = ImGui.IsKeyPressed(ctx, ImGui.Key_F)
  
  if ctrl_pressed and f_pressed and header_cfg.mode == 'tabs' then
    state.temp_search_mode = not state.temp_search_mode
    if state.temp_search_mode then
      state.search_text = ""
    end
  end
  
  local mode = header_cfg.mode or 'search_sort'
  if mode == 'tabs' and state.temp_search_mode then
    mode = 'temp_search'
  end
  
  if mode == 'tabs' then
    return draw_tabs_header(ctx, dl, x, y, width, height, state, header_cfg)
  elseif mode == 'search_sort' or mode == 'temp_search' then
    return draw_search_sort_header(ctx, dl, x, y, width, height, state, header_cfg)
  end
  
  return height
end

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
    
    on_search_changed = opts.on_search_changed,
    on_sort_changed = opts.on_sort_changed,
    on_sort_direction_changed = opts.on_sort_direction_changed,
    on_tab_create = opts.on_tab_create,
    on_tab_change = opts.on_tab_change,
    on_tab_delete = opts.on_tab_delete,
    
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
  
  local header_cfg = self.config.header or DEFAULTS.header
  local header_height = 0
  
  if header_cfg.enabled then
    header_height = draw_header(ctx, dl, x1, y1, w, header_cfg.height, self, self.config)
  end
  
  local content_y1 = y1 + header_height
  
  draw_background_pattern(dl, x1, content_y1, x2, y2, self.config.background_pattern)
  
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
  self.search_text = ""
  self.search_focused = false
  self.search_alpha = 0.3
  self.sort_mode = nil
  self.sort_dropdown = nil
  self.temp_search_mode = false
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
  self.tabs = tabs or {}
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