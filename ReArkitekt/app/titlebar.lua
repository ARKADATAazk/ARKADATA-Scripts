-- ReArkitekt/app/titlebar.lua
-- Custom titlebar component with close and maximize buttons

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local M = {}

-- Try to load icon module (optional dependency)
local Icon = nil
do
  local ok, mod = pcall(require, 'ReArkitekt.app.icon')
  if ok then Icon = mod end
end

-- Load defaults from config
local DEFAULTS = {}
do
  local ok, Config = pcall(require, 'ReArkitekt.app.config')
  if ok and Config and Config.get_defaults then
    DEFAULTS = Config.get_defaults().titlebar or {}
  end
end

-- Create a new titlebar instance
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
    
    -- Icon options
    show_icon       = opts.show_icon ~= false,
    icon_size       = opts.icon_size or DEFAULTS.icon_size,
    icon_spacing    = opts.icon_spacing or DEFAULTS.icon_spacing,
    icon_color      = opts.icon_color,
    icon_draw       = opts.icon_draw,
    
    enable_maximize = opts.enable_maximize ~= false,
    is_maximized    = false,
    
    -- Callbacks
    on_close        = opts.on_close,
    on_maximize     = opts.on_maximize,
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
  
  -- Public API
  
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
    -- Safety check: ensure valid dimensions
    if not win_w or win_w <= 0 or not self.height or self.height <= 0 then
      return true
    end
    
    local is_focused = ImGui.IsWindowFocused(ctx, ImGui.FocusedFlags_RootWindow)
    
    -- Get colors from theme or custom
    local bg_color = self.bg_color
    if not bg_color then
      bg_color = is_focused 
        and (self.bg_color_active or ImGui.GetColor(ctx, ImGui.Col_TitleBgActive))
        or ImGui.GetColor(ctx, ImGui.Col_TitleBg)
    end
    
    local text_color = self.text_color or ImGui.GetColor(ctx, ImGui.Col_Text)
    
    -- Draw titlebar as a colored child window
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding, 0, 0)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing, self.button_spacing, 0)
    ImGui.PushStyleColor(ctx, ImGui.Col_ChildBg, bg_color)
    
    local titlebar_flags = ImGui.ChildFlags_None
    local window_flags = ImGui.WindowFlags_NoScrollbar | ImGui.WindowFlags_NoScrollWithMouse
    
    local child_visible = ImGui.BeginChild(ctx, "##titlebar", win_w, self.height, titlebar_flags, window_flags)
    
    local clicked_maximize = false
    local clicked_close = false
    
    if child_visible then
      local content_h = ImGui.GetTextLineHeight(ctx)
      local y_center = (self.height - content_h) * 0.5
      
      ImGui.SetCursorPos(ctx, self.pad_h, y_center)
      
      local title_x_offset = 0
      if self.show_icon then
        local win_x, win_y = ImGui.GetWindowPos(ctx)
        local icon_x = win_x + self.pad_h
        local icon_y = win_y + (self.height - self.icon_size) * 0.5
        local icon_color = self.icon_color or text_color
        
        self:_draw_icon(ctx, icon_x, icon_y, icon_color)
        
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
      
      ImGui.SetCursorPos(ctx, win_w - total_button_width - self.pad_h, 0)
      
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

  -- [REVISED] Draw cleaner, better-proportioned icons for buttons
  function titlebar:_draw_button_icon(ctx, min_x, min_y, max_x, max_y, icon_type, color, bg_color)
    local draw_list = ImGui.GetWindowDrawList(ctx)
    local dpi = ImGui.GetWindowDpiScale(ctx)
    local thickness = math.max(1, math.floor(1.0 * dpi))

    -- Calculate a centered, square area for the icon with 30% padding
    -- Using floor for pixel-perfect alignment
    local h = max_y - min_y
    local padding = math.floor(h * 0.3)
    local ix1, iy1 = min_x + padding, min_y + padding
    local ix2, iy2 = max_x - padding, max_y - padding

    -- For sharp 1px lines, it's best to draw on half-pixel coordinates
    local offset = 0.5
    ix1, iy1 = ix1 + offset, iy1 + offset
    ix2, iy2 = ix2 + offset, iy2 + offset

    if icon_type == 'maximize' then
      ImGui.DrawList_AddRect(draw_list, ix1, iy1, ix2, iy2, color, 0, 0, thickness)

    elseif icon_type == 'restore' then
      local box_w = ix2 - ix1
      local box_h = iy2 - iy1
      local small_offset = math.floor(box_w * 0.2)

      -- Back window
      local bx1, by1 = ix1 + small_offset, iy1
      local bx2, by2 = ix2, iy2 - small_offset
      ImGui.DrawList_AddRect(draw_list, bx1, by1, bx2, by2, color, 0, 0, thickness)
      
      -- Front window (draw filled bg first to hide back lines, then outline)
      local fx1, fy1 = ix1, iy1 + small_offset
      local fx2, fy2 = ix2 - small_offset, iy2
      ImGui.DrawList_AddRectFilled(draw_list, fx1, fy1, fx2, fy2, bg_color)
      ImGui.DrawList_AddRect(draw_list, fx1, fy1, fx2, fy2, color, 0, 0, thickness)

    elseif icon_type == 'close' then
      -- Inset the lines slightly for a cleaner 'X'
      local inset = 1 * dpi
      ImGui.DrawList_AddLine(draw_list, ix1 + inset, iy1 + inset, ix2 - inset, iy2 - inset, color, thickness)
      ImGui.DrawList_AddLine(draw_list, ix1 + inset, iy2 - inset, ix2 - inset, iy1 + inset, color, thickness)
    end
  end
  
  -- Minimal button style with drawn icons
  function titlebar:_draw_buttons_minimal(ctx, bg_color)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 0, 0)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameRounding, 0)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameBorderSize, 0)

    local clicked_maximize = false
    local clicked_close = false
    local icon_color = ImGui.GetColor(ctx, ImGui.Col_Text)

    if self.enable_maximize then
      ImGui.PushStyleColor(ctx, ImGui.Col_Button, DEFAULTS.button_maximize_normal or 0x00000000)
      ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, DEFAULTS.button_maximize_hovered or 0x40FFFFFF)
      ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive, DEFAULTS.button_maximize_active or 0x60FFFFFF)

      if ImGui.Button(ctx, "##max", self.button_width, self.height) then
        clicked_maximize = true
      end
      
      local current_bg_color = DEFAULTS.button_maximize_normal or 0x00000000
      if ImGui.IsItemActive(ctx) then current_bg_color = DEFAULTS.button_maximize_active or 0x60FFFFFF
      elseif ImGui.IsItemHovered(ctx) then current_bg_color = DEFAULTS.button_maximize_hovered or 0x40FFFFFF
      end
      
      local min_x, min_y = ImGui.GetItemRectMin(ctx)
      local max_x, max_y = ImGui.GetItemRectMax(ctx)
      local icon_type = self.is_maximized and "restore" or "maximize"
      self:_draw_button_icon(ctx, min_x, min_y, max_x, max_y, icon_type, icon_color, current_bg_color)

      ImGui.PopStyleColor(ctx, 3)

      if ImGui.IsItemHovered(ctx) then
        ImGui.SetTooltip(ctx, self.is_maximized and "Restore" or "Maximize")
      end

      ImGui.SameLine(ctx)
    end

    ImGui.PushStyleColor(ctx, ImGui.Col_Button, DEFAULTS.button_close_normal or 0x00000000)
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, DEFAULTS.button_close_hovered or 0xCC3333FF)
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive, DEFAULTS.button_close_active or 0xFF1111FF)

    if ImGui.Button(ctx, "##close", self.button_width, self.height) then
      clicked_close = true
    end
    
    local current_bg_color = DEFAULTS.button_close_normal or 0x00000000
    if ImGui.IsItemActive(ctx) then current_bg_color = DEFAULTS.button_close_active or 0xFF1111FF
    elseif ImGui.IsItemHovered(ctx) then current_bg_color = DEFAULTS.button_close_hovered or 0xCC3333FF
    end

    local min_x, min_y = ImGui.GetItemRectMin(ctx)
    local max_x, max_y = ImGui.GetItemRectMax(ctx)
    self:_draw_button_icon(ctx, min_x, min_y, max_x, max_y, "close", icon_color, current_bg_color)
    
    ImGui.PopStyleColor(ctx, 3)
    ImGui.PopStyleVar(ctx, 3)

    if ImGui.IsItemHovered(ctx) then
      ImGui.SetTooltip(ctx, "Close")
    end

    return clicked_maximize, clicked_close
  end
  
  -- Filled button style
  function titlebar:_draw_buttons_filled(ctx)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 0, 0)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameRounding, 0)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameBorderSize, 0)
    
    local clicked_maximize = false
    local clicked_close = false
    
    if self.enable_maximize then
      local icon = self.is_maximized and "⊡" or "□"
      
      ImGui.PushStyleColor(ctx, ImGui.Col_Button, DEFAULTS.button_maximize_filled_normal or 0x808080FF)
      ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, DEFAULTS.button_maximize_filled_hovered or 0x999999FF)
      ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive, DEFAULTS.button_maximize_filled_active or 0x666666FF)
      
      if ImGui.Button(ctx, icon .. "##max", self.button_width, self.height) then
        clicked_maximize = true
      end
      
      ImGui.PopStyleColor(ctx, 3)
      
      if ImGui.IsItemHovered(ctx) then
        ImGui.SetTooltip(ctx, self.is_maximized and "Restore" or "Maximize")
      end
      
      ImGui.SameLine(ctx)
    end
    
    ImGui.PushStyleColor(ctx, ImGui.Col_Button, DEFAULTS.button_close_filled_normal or 0xCC3333FF)
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, DEFAULTS.button_close_filled_hovered or 0xFF4444FF)
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive, DEFAULTS.button_close_filled_active or 0xFF1111FF)
    
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