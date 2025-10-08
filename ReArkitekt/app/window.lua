-- ReArkitekt/app/window.lua
-- Window with integrated status bar, saved geometry, and custom titlebar (ReaImGui 0.9+)

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local M = {}

local WF_None = 0

local function floor(n) return math.floor(n + 0.5) end

-- Constructor
function M.new(opts)
  opts = opts or {}

  local win = {
    -- external
    settings        = opts.settings,
    title           = opts.title or "Window",
    flags           = opts.flags or WF_None,

    -- layout
    content_padding = opts.content_padding or 12,
    titlebar_pad_h  = opts.titlebar_pad_h,
    titlebar_pad_v  = opts.titlebar_pad_v or 7,
    title_font      = opts.title_font,

    -- geometry
    initial_pos     = opts.initial_pos  or { x = 100, y = 100 },
    initial_size    = opts.initial_size or { w = 900, h = 600 },
    min_size        = opts.min_size     or { w = 400, h = 300 },

    -- status bar
    status_bar      = opts.status_bar,

    -- titlebar options (pass to titlebar module)
    titlebar_opts   = {
      height          = opts.titlebar_height or 28,
      pad_h           = opts.titlebar_pad_h or 12,
      pad_v           = opts.titlebar_pad_v or 0,
      button_width    = opts.titlebar_button_width or 44,
      button_spacing  = opts.titlebar_button_spacing or 0,
      button_style    = opts.titlebar_button_style or "minimal",
      separator       = opts.titlebar_separator,
      bg_color        = opts.titlebar_bg_color,
      bg_color_active = opts.titlebar_bg_color_active,
      text_color      = opts.titlebar_text_color,
      enable_maximize = opts.enable_maximize ~= false,
      title_font      = opts.title_font,
      show_icon       = opts.show_icon,
      icon_size       = opts.icon_size,
      icon_spacing    = opts.icon_spacing,
      icon_color      = opts.icon_color,
      icon_draw       = opts.icon_draw,
    },

    -- maximize feature
    _is_maximized   = false,
    _pre_max_pos    = nil,
    _pre_max_size   = nil,
    _max_viewport   = nil,
    _pending_maximize = false,
    _pending_restore  = false,

    -- internals
    _saved_pos      = nil,
    _saved_size     = nil,
    _pos_size_set   = false,
    _body_open      = false,
    _begun          = false,
    _titlebar       = nil,
  }

  -- Force NoTitleBar and NoScrollbar since we draw custom
  if ImGui.WindowFlags_NoTitleBar then
    win.flags = win.flags | ImGui.WindowFlags_NoTitleBar
  end
  if ImGui.WindowFlags_NoCollapse then
    win.flags = win.flags | ImGui.WindowFlags_NoCollapse
  end
  if ImGui.WindowFlags_NoScrollbar then
    win.flags = win.flags | ImGui.WindowFlags_NoScrollbar
  end
  -- FIX: Prevent scrolling the main window with the mouse wheel
  if ImGui.WindowFlags_NoScrollWithMouse then
    win.flags = win.flags | ImGui.WindowFlags_NoScrollWithMouse
  end

  -- Restore persisted geometry if settings provided
  if win.settings then
    win._saved_pos  = win.settings:get("window.pos",  nil)
    win._saved_size = win.settings:get("window.size", nil)
    win._is_maximized = win.settings:get("window.maximized", false)
  end

  -- Lazy-create a default status bar if not provided
  if not win.status_bar then
    local ok, StatusBar = pcall(require, 'ReArkitekt.gui.widgets.status_bar')
    if ok and StatusBar and StatusBar.new then
      win.status_bar = StatusBar.new({
        height = 34,
        get_status = function() return { text = "READY", color = 0x41E0A3FF } end
      })
    end
  end

  -- Create titlebar component
  do
    local ok, Titlebar = pcall(require, 'ReArkitekt.app.titlebar')
    if ok and Titlebar and Titlebar.new then
      win.titlebar_opts.title = win.title
      win.titlebar_opts.on_close = function()
        win._should_close = true
      end
      win.titlebar_opts.on_maximize = function()
        win:_maximize_requested()
      end
      
      win._titlebar = Titlebar.new(win.titlebar_opts)
      win._titlebar:set_maximized(win._is_maximized)
    end
  end

  -- Public API

  function win:set_title(s)
    self.title = tostring(s or self.title)
    if self._titlebar then
      self._titlebar:set_title(self.title)
    end
  end
  
  function win:set_title_font(font)
    self.title_font = font
    if self._titlebar then
      self._titlebar.title_font = font
    end
  end

  function win:toggle_status_bar(enabled)
    if enabled == false then
      self.status_bar = nil
      return
    end
    if self.status_bar then return end
    local ok, StatusBar = pcall(require, 'ReArkitekt.gui.widgets.status_bar')
    if ok and StatusBar and StatusBar.new then
      self.status_bar = StatusBar.new({
        height = 34,
        get_status = function() return { text = "READY", color = 0x41E0A3FF } end
      })
    end
  end

  function win:_maximize_requested()
    reaper.ShowConsoleMsg("[MAXIMIZE] Button clicked\n")
    if ImGui.IsWindowDocked then
      if self._current_ctx and ImGui.IsWindowDocked(self._current_ctx) then
        reaper.ShowConsoleMsg("[MAXIMIZE] Window is docked, ignoring\n")
        return
      end
    end
    reaper.ShowConsoleMsg("[MAXIMIZE] Setting pending_maximize = true\n")
    self._pending_maximize = true
  end

  function win:_toggle_maximize()
    if not self._current_ctx then return end
    local ctx = self._current_ctx
    
    reaper.ShowConsoleMsg("[MAXIMIZE] _toggle_maximize called, is_maximized = " .. tostring(self._is_maximized) .. "\n")
    
    if self._is_maximized then
      reaper.ShowConsoleMsg("[MAXIMIZE] Restoring window\n")
      self._is_maximized = false
      self._pending_restore = true
    else
      -- Save current window position and size
      local wx, wy = ImGui.GetWindowPos(ctx)
      local ww, wh = ImGui.GetWindowSize(ctx)
      self._pre_max_pos = { x = floor(wx), y = floor(wy) }
      self._pre_max_size = { w = floor(ww), h = floor(wh) }
      
      reaper.ShowConsoleMsg(string.format("[MAXIMIZE] Saved pre-max: pos(%d,%d) size(%d,%d)\n", 
        self._pre_max_pos.x, self._pre_max_pos.y, self._pre_max_size.w, self._pre_max_size.h))
      
      -- Try JS_ReaScriptAPI for proper monitor detection
      local js_success = false
      if reaper.JS_Window_GetViewportFromRect then
        local left, top, right, bottom = reaper.JS_Window_GetViewportFromRect(
          wx, wy, wx + ww, wy + wh, true
        )
        if left and right and top and bottom then
          self._max_viewport = { 
            x = left, 
            y = top, 
            w = right - left, 
            h = bottom - top 
          }
          reaper.ShowConsoleMsg(string.format("[MAXIMIZE] JS_API monitor: pos(%d,%d) size(%dx%d)\n",
            left, top, right - left, bottom - top))
          js_success = true
        end
      end
      
      -- Fallback: Estimate monitor based on position
      if not js_success then
        reaper.ShowConsoleMsg("[MAXIMIZE] JS_ReaScriptAPI not available, using fallback\n")
        local monitor_width = 1920
        local monitor_height = 1080
        local taskbar_offset = 40
        
        local monitor_index = math.floor((self._pre_max_pos.x + monitor_width / 2) / monitor_width)
        local monitor_left = monitor_index * monitor_width
        local monitor_top = 0
        
        self._max_viewport = { 
          x = monitor_left, 
          y = monitor_top,
          w = monitor_width, 
          h = monitor_height - taskbar_offset 
        }
        
        reaper.ShowConsoleMsg(string.format("[MAXIMIZE] Estimated monitor %d: pos(%d,%d) size(%dx%d)\n",
          monitor_index, monitor_left, monitor_top, self._max_viewport.w, self._max_viewport.h))
      end
      
      self._is_maximized = true
    end
    
    -- Update titlebar state
    if self._titlebar then
      self._titlebar:set_maximized(self._is_maximized)
    end
    
    -- Save maximize state
    if self.settings then
      self.settings:set("window.maximized", self._is_maximized)
    end
  end

  function win:_apply_geometry(ctx)
    reaper.ShowConsoleMsg(string.format("[MAXIMIZE] _apply_geometry: is_maximized=%s, has_viewport=%s, pending_restore=%s\n",
      tostring(self._is_maximized), tostring(self._max_viewport ~= nil), tostring(self._pending_restore)))
    
    -- Apply maximize geometry BEFORE Begin() using SetNextWindow*
    if self._is_maximized and self._max_viewport then
      reaper.ShowConsoleMsg(string.format("[MAXIMIZE] Applying maximized geometry: pos(%d,%d) size(%dx%d)\n",
        self._max_viewport.x or 0, self._max_viewport.y or 0, self._max_viewport.w, self._max_viewport.h))
      if self._max_viewport.x and self._max_viewport.y then
        ImGui.SetNextWindowPos(ctx, self._max_viewport.x, self._max_viewport.y, ImGui.Cond_Always)
      end
      ImGui.SetNextWindowSize(ctx, self._max_viewport.w, self._max_viewport.h, ImGui.Cond_Always)
      self._pos_size_set = true
    elseif self._pending_restore and self._pre_max_pos then
      reaper.ShowConsoleMsg(string.format("[MAXIMIZE] Restoring geometry: pos(%d,%d) size(%d,%d)\n",
        self._pre_max_pos.x, self._pre_max_pos.y, self._pre_max_size.w, self._pre_max_size.h))
      -- Restore both position and size
      ImGui.SetNextWindowPos(ctx, self._pre_max_pos.x, self._pre_max_pos.y, ImGui.Cond_Always)
      ImGui.SetNextWindowSize(ctx, self._pre_max_size.w, self._pre_max_size.h, ImGui.Cond_Always)
      self._pending_restore = false
      self._pos_size_set = true
    elseif not self._pos_size_set then
      -- Only set initial geometry on first frame
      local pos  = self._saved_pos  or self.initial_pos
      local size = self._saved_size or self.initial_size
      if pos  and pos.x  and pos.y  then ImGui.SetNextWindowPos(ctx,  pos.x,  pos.y) end
      if size and size.w and size.h then ImGui.SetNextWindowSize(ctx, size.w, size.h) end
      self._pos_size_set = true
    end
    
    if ImGui.SetNextWindowSizeConstraints and self.min_size then
      ImGui.SetNextWindowSizeConstraints(ctx, self.min_size.w, self.min_size.h, 99999, 99999)
    end
  end

  function win:_save_geometry(ctx)
    if not self.settings then return end
    if self._is_maximized then return end
    
    local wx, wy = ImGui.GetWindowPos(ctx)
    local ww, wh = ImGui.GetWindowSize(ctx)
    local pos  = { x = floor(wx), y = floor(wy) }
    local size = { w = floor(ww), h = floor(wh) }

    if (not self._saved_pos) or pos.x ~= self._saved_pos.x or pos.y ~= self._saved_pos.y then
      self._saved_pos = pos
      self.settings:set("window.pos", pos)
    end
    if (not self._saved_size) or size.w ~= self._saved_size.w or size.h ~= self._saved_size.h then
      self._saved_size = size
      self.settings:set("window.size", size)
    end
  end

  -- Draw outer window
  function win:Begin(ctx)
    self._body_open = false
    self._should_close = false
    self._current_ctx = ctx
    
    self:_apply_geometry(ctx)

    -- Outer: zero padding
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding, 0, 0)

    local visible, open = ImGui.Begin(ctx, self.title .. "##main", true, self.flags)
    self._begun = true

    if visible then
      -- Handle pending maximize request AFTER window exists
      if self._pending_maximize then
        reaper.ShowConsoleMsg("[MAXIMIZE] Processing pending_maximize in Begin()\n")
        self:_toggle_maximize()
        self._pending_maximize = false
      end
      
      -- Draw custom titlebar only when NOT docked
      if self._titlebar and not ImGui.IsWindowDocked(ctx) then
        local win_w, _ = ImGui.GetWindowSize(ctx)
        local keep_open = self._titlebar:render(ctx, win_w)
        if not keep_open then
          self._should_close = true
        end
      end
      
      self:_save_geometry(ctx)
    end

    ImGui.PopStyleVar(ctx)
    
    -- Override open state if close button was clicked
    if self._should_close then
      open = false
    end
    
    return visible, open
  end

  -- Body child: padded content area, height adjusted for status bar
  function win:BeginBody(ctx)
    if self._body_open then return false end
    local _, avail_h = ImGui.GetContentRegionAvail(ctx)
    local status_h   = (self.status_bar and self.status_bar.height) or 0
    local body_h     = floor(avail_h - status_h)
    if body_h < 24 then return false end

    ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding, self.content_padding, self.content_padding)
    local success = ImGui.BeginChild(ctx, "##body", 0, body_h)
    self._body_open = true
    return success
  end

  function win:EndBody(ctx)
    if not self._body_open then return end
    ImGui.EndChild(ctx)
    ImGui.PopStyleVar(ctx)
    self._body_open = false
  end

  -- Optional hooks for a tabs area (kept for API parity)
  function win:BeginTabs(_) return true end
  function win:EndTabs(_) end

  function win:End(ctx)
    -- Status bar: flush bottom, full width, no spacing
    if self.status_bar and self.status_bar.render then
      local _, avail_h = ImGui.GetContentRegionAvail(ctx)
      if avail_h >= 0 then
        local x, y = ImGui.GetCursorPos(ctx)
        if y < 0 then y = 0 end
        ImGui.SetCursorPos(ctx, 0, y)
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing, 0, 0)
        self.status_bar.render(ctx)
        ImGui.PopStyleVar(ctx)
      end
    end

    if self._begun then ImGui.End(ctx) end
    self._begun = false
  end

  return win
end

return M