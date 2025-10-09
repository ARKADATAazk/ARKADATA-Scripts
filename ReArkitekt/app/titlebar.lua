-- ReArkitekt/app/titlebar.lua
-- Custom titlebar component with close and maximize buttons, icon double-click for profiling

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local M = {}

local Icon = nil
do
  local ok, mod = pcall(require, 'ReArkitekt.app.icon')
  if ok then Icon = mod end
end

local DEFAULTS = {}
do
  local ok, Config = pcall(require, 'ReArkitekt.app.config')
  if ok and Config and Config.get_defaults then
    DEFAULTS = Config.get_defaults().titlebar or {}
  else
    DEFAULTS = {
      height          = 26,
      pad_h           = 12,
      pad_v           = 0,
      button_width    = 44,
      button_spacing  = 0,
      button_style    = "minimal",
      icon_size       = 18,
      icon_spacing    = 8,
      button_maximize_normal  = 0x00000000,
      button_maximize_hovered = 0x57C290FF,
      button_maximize_active  = 0x60FFFFFF,
      button_close_normal     = 0x00000000,
      button_close_hovered    = 0xCC3333FF,
      button_close_active     = 0xFF1111FF,
      button_maximize_filled_normal  = 0x808080FF,
      button_maximize_filled_hovered = 0x999999FF,
      button_maximize_filled_active  = 0x666666FF,
      button_close_filled_normal     = 0xCC3333FF,
      button_close_filled_hovered    = 0xFF4444FF,
      button_close_filled_active     = 0xFF1111FF,
    }
  end
end

function M.new(opts)
  opts = opts or {}
  
  local titlebar = {
    title           = opts.title or "Window",
    title_font      = opts.title_font,
    
    height          = opts.height or DEFAULTS.height,
    pad_h           = opts.pad_h or DEFAULTS.pad_h,
    pad_v           = opts.pad_v or DEFAULTS.pad_v,
    button_width    = opts.button_width or DEFAULTS.button_width,
    button_spacing  = opts.button_spacing or DEFAULTS.button_spacing,
    button_style    = opts.button_style or DEFAULTS.button_style,
    separator       = opts.separator ~= false,
    
    bg_color        = opts.bg_color,
    bg_color_active = opts.bg_color_active,
    text_color      = opts.text_color,
    
    show_icon       = opts.show_icon ~= false,
    icon_size       = opts.icon_size or DEFAULTS.icon_size,
    icon_spacing    = opts.icon_spacing or DEFAULTS.icon_spacing,
    icon_color      = opts.icon_color,
    icon_draw       = opts.icon_draw,
    
    enable_maximize = opts.enable_maximize ~= false,
    is_maximized    = false,
    
    on_close        = opts.on_close,
    on_maximize     = opts.on_maximize,
    on_icon_double_click = opts.on_icon_double_click,
    
    -- Icon interaction state
    icon_last_click_time = 0,
    icon_double_click_threshold = 0.3, -- 300ms
  }
  
  function titlebar:_draw_icon(ctx, x, y, color)
    if self.icon_draw then
      self.icon_draw(ctx, x, y, self.icon_size, color)
    elseif Icon and Icon.draw_rearkitekt then
      Icon.draw_rearkitekt(ctx, x, y, self.icon_size, color)
    else
      local draw_list = ImGui.GetWindowDrawList(ctx)
      local dpi = ImGui.GetWindowDpiScale(ctx)
      local r = (self.icon_size * 0.5) * dpi
      ImGui.DrawList_AddCircleFilled(draw_list, x + r, y + r, r, color)
    end
  end
  
  function titlebar:set_title(title)
    self.title = tostring(title or self.title)
  end
  
  function titlebar:set_maximized(state)
    self.is_maximized = state
  end
  
  function titlebar:set_icon_visible(visible)
    self.show_icon = visible
  end
  
  function titlebar:set_icon_color(color)
    self.icon_color = color
  end
  
  function titlebar:render(ctx, win_w)
    if not win_w or win_w <= 0 or not self.height or self.height <= 0 then
      return true
    end
    
    local is_focused = ImGui.IsWindowFocused(ctx, ImGui.FocusedFlags_RootWindow)
    
    local bg_color = self.bg_color
    if not bg_color then
      bg_color = is_focused 
        and (self.bg_color_active or ImGui.GetColor(ctx, ImGui.Col_TitleBgActive))
        or ImGui.GetColor(ctx, ImGui.Col_TitleBg)
    end
    
    local text_color = self.text_color or ImGui.GetColor(ctx, ImGui.Col_Text)
    
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding, 0, 0)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing, self.button_spacing, 0)
    ImGui.PushStyleColor(ctx, ImGui.Col_ChildBg, bg_color)
    
    local titlebar_flags = ImGui.ChildFlags_None
    local window_flags = ImGui.WindowFlags_NoScrollbar | ImGui.WindowFlags_NoScrollWithMouse
    
    local child_visible = ImGui.BeginChild(ctx, "##titlebar", win_w, self.height, titlebar_flags, window_flags)
    
    local clicked_maximize = false
    local clicked_close = false
    local icon_double_clicked = false
    
    if child_visible then
      local content_h = ImGui.GetTextLineHeight(ctx)
      local y_center = (self.height - content_h) * 0.5 + 1
      
      ImGui.SetCursorPos(ctx, self.pad_h, y_center)
      
      local title_x_offset = 0
      if self.show_icon then
        local win_x, win_y = ImGui.GetWindowPos(ctx)
        local icon_x = win_x + self.pad_h
        local icon_y = win_y + (self.height - self.icon_size) * 0.5
        local icon_color = self.icon_color or text_color
        
        -- Create invisible button for icon click detection
        ImGui.SetCursorPos(ctx, self.pad_h, (self.height - self.icon_size) * 0.5)
        ImGui.InvisibleButton(ctx, "##icon_button", self.icon_size, self.icon_size)
        
        local icon_hovered = ImGui.IsItemHovered(ctx)
        -- FIXED: Use IsItemClicked instead of the complex condition
        local icon_clicked = ImGui.IsItemClicked(ctx, ImGui.MouseButton_Left)
        
        -- Detect double-click
        if icon_clicked then
          local current_time = reaper.time_precise()
          if current_time - self.icon_last_click_time < self.icon_double_click_threshold then
            icon_double_clicked = true
            self.icon_last_click_time = 0  -- Reset to prevent triple-click detection
          else
            self.icon_last_click_time = current_time
          end
        end
        
        -- Modify icon color on hover
        local draw_color = icon_color
        if icon_hovered then
          -- Brighten on hover
          local r = (draw_color >> 24) & 0xFF
          local g = (draw_color >> 16) & 0xFF
          local b = (draw_color >> 8) & 0xFF
          local a = draw_color & 0xFF
          r = math.min(255, r + 30)
          g = math.min(255, g + 30)
          b = math.min(255, b + 30)
          draw_color = (r << 24) | (g << 16) | (b << 8) | a
        end
        
        self:_draw_icon(ctx, icon_x, icon_y, draw_color)
        
        -- Show tooltip on hover
        if icon_hovered then
          ImGui.SetTooltip(ctx, "Double-click to toggle profiling")
        end
        
        title_x_offset = self.icon_size + self.icon_spacing
        ImGui.SetCursorPos(ctx, self.pad_h + title_x_offset, y_center)
      end
      
      ImGui.PushStyleColor(ctx, ImGui.Col_Text, text_color)
      if self.title_font then ImGui.PushFont(ctx, self.title_font) end
      
      ImGui.Text(ctx, self.title)
      
      if self.title_font then ImGui.PopFont(ctx) end
      ImGui.PopStyleColor(ctx)
      
      local num_buttons = 1 + (self.enable_maximize and 1 or 0)
      local total_button_width = (self.button_width * num_buttons) + (self.button_spacing * (num_buttons - 1))
      
      ImGui.SetCursorPos(ctx, win_w - total_button_width, 0)
      
      if self.button_style == "filled" then
        clicked_maximize, clicked_close = self:_draw_buttons_filled(ctx)
      else
        clicked_maximize, clicked_close = self:_draw_buttons_minimal(ctx, bg_color)
      end
    end
    
    ImGui.EndChild(ctx)
    ImGui.PopStyleColor(ctx)
    ImGui.PopStyleVar(ctx, 2)
    
    if self.separator then
      ImGui.Separator(ctx)
    end
    
    -- Handle icon double-click
    if icon_double_clicked and self.on_icon_double_click then
      self.on_icon_double_click()
    end
    
    if clicked_maximize and self.on_maximize then
      self.on_maximize()
    end
    
    if clicked_close then
      if self.on_close then
        self.on_close()
        return true
      else
        return false
      end
    end
    
    return true
  end

  function titlebar:_draw_button_icon(ctx, min_x, min_y, max_x, max_y, icon_type, color, button_bg_color)
    local draw_list = ImGui.GetWindowDrawList(ctx)
    local dpi = ImGui.GetWindowDpiScale(ctx)
    local thickness = math.max(1, math.floor(1.0 * dpi))

    local h = max_y - min_y
    local w = max_x - min_x
    
    local v_padding = math.floor(h * 0.35)
    local iy1 = min_y + v_padding
    local iy2 = max_y - v_padding

    local icon_h = iy2 - iy1
    
    local square_size = icon_h
    if square_size % 2 == 1 then
        square_size = square_size - 1
    end
    
    local center_x = min_x + (w / 2)
    local half_size = square_size / 2
    local ix1 = math.floor(center_x - half_size)
    local ix2 = ix1 + square_size

    if icon_type == 'maximize' then
        ImGui.DrawList_AddRect(draw_list, ix1, iy1, ix2, iy2, color, 0, 0, thickness)

    elseif icon_type == 'restore' then
        local small_offset = math.floor((ix2 - ix1) * 0.25)
        local bx1, by1 = ix1 + small_offset, iy1
        local bx2, by2 = ix2, iy2 - small_offset
        ImGui.DrawList_AddRect(draw_list, bx1, by1, bx2, by2, color, 0, 0, thickness)
        
        local fx1, fy1 = ix1, iy1 + small_offset
        local fx2, fy2 = ix2 - small_offset, iy2
        ImGui.DrawList_AddRectFilled(draw_list, fx1, fy1, fx2, fy2, button_bg_color)
        ImGui.DrawList_AddRect(draw_list, fx1, fy1, fx2, fy2, color, 0, 0, thickness)

    elseif icon_type == 'close' then
        ImGui.DrawList_AddLine(draw_list, ix1, iy1, ix2, iy2, color, thickness)
        ImGui.DrawList_AddLine(draw_list, ix1, iy2, ix2, iy1, color, thickness)
    end
  end

  function titlebar:_draw_buttons_minimal(ctx, bg_color)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 0, 0)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameRounding, 0)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameBorderSize, 0)

    local clicked_maximize = false
    local clicked_close = false
    local icon_color = ImGui.GetColor(ctx, ImGui.Col_Text)

    if self.enable_maximize then
      ImGui.PushStyleColor(ctx, ImGui.Col_Button, DEFAULTS.button_maximize_normal)
      ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, DEFAULTS.button_maximize_hovered)
      ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive, DEFAULTS.button_maximize_active)

      if ImGui.Button(ctx, "##max", self.button_width, self.height) then
        clicked_maximize = true
      end
      
      local is_hovered = ImGui.IsItemHovered(ctx)
      local is_active = ImGui.IsItemActive(ctx)
      
      local current_button_bg
      if is_active then
        current_button_bg = DEFAULTS.button_maximize_active
      elseif is_hovered then
        current_button_bg = DEFAULTS.button_maximize_hovered
      else
        current_button_bg = bg_color
      end
      
      local min_x, min_y = ImGui.GetItemRectMin(ctx)
      local max_x, max_y = ImGui.GetItemRectMax(ctx)
      local icon_type = self.is_maximized and "restore" or "maximize"
      self:_draw_button_icon(ctx, min_x, min_y, max_x, max_y, icon_type, icon_color, current_button_bg)

      ImGui.PopStyleColor(ctx, 3)

      if is_hovered then
        ImGui.SetTooltip(ctx, self.is_maximized and "Restore" or "Maximize")
      end

      ImGui.SameLine(ctx)
    end

    ImGui.PushStyleColor(ctx, ImGui.Col_Button, DEFAULTS.button_close_normal)
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, DEFAULTS.button_close_hovered)
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive, DEFAULTS.button_close_active)

    if ImGui.Button(ctx, "##close", self.button_width, self.height) then
      clicked_close = true
    end

    local is_hovered = ImGui.IsItemHovered(ctx)
    local is_active = ImGui.IsItemActive(ctx)
    
    local current_button_bg
    if is_active then
      current_button_bg = DEFAULTS.button_close_active
    elseif is_hovered then
      current_button_bg = DEFAULTS.button_close_hovered
    else
      current_button_bg = bg_color
    end

    local min_x, min_y = ImGui.GetItemRectMin(ctx)
    local max_x, max_y = ImGui.GetItemRectMax(ctx)
    self:_draw_button_icon(ctx, min_x, min_y, max_x, max_y, "close", icon_color, current_button_bg)
    
    ImGui.PopStyleColor(ctx, 3)
    ImGui.PopStyleVar(ctx, 3)

    if is_hovered then
      ImGui.SetTooltip(ctx, "Close")
    end

    return clicked_maximize, clicked_close
  end

  function titlebar:_draw_buttons_filled(ctx)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 0, 0)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameRounding, 0)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameBorderSize, 0)
    
    local clicked_maximize = false
    local clicked_close = false
    
    if self.enable_maximize then
      local icon = self.is_maximized and "⊡" or "▢"
      
      ImGui.PushStyleColor(ctx, ImGui.Col_Button, DEFAULTS.button_maximize_filled_normal)
      ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, DEFAULTS.button_maximize_filled_hovered)
      ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive, DEFAULTS.button_maximize_filled_active)
      
      if ImGui.Button(ctx, icon .. "##max", self.button_width, self.height) then
        clicked_maximize = true
      end
      
      ImGui.PopStyleColor(ctx, 3)
      
      if ImGui.IsItemHovered(ctx) then
        ImGui.SetTooltip(ctx, self.is_maximized and "Restore" or "Maximize")
      end
      
      ImGui.SameLine(ctx)
    end
    
    ImGui.PushStyleColor(ctx, ImGui.Col_Button, DEFAULTS.button_close_filled_normal)
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, DEFAULTS.button_close_filled_hovered)
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive, DEFAULTS.button_close_filled_active)
    
    if ImGui.Button(ctx, "X##close", self.button_width, self.height) then
      clicked_close = true
    end
    
    ImGui.PopStyleColor(ctx, 3)
    ImGui.PopStyleVar(ctx, 3)
    
    if ImGui.IsItemHovered(ctx) then
      ImGui.SetTooltip(ctx, "Close")
    end
    
    return clicked_maximize, clicked_close
  end
  
  return titlebar
end

return M