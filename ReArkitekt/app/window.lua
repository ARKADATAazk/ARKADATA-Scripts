-- ReArkitekt/app/window.lua
-- Window with integrated status bar, saved geometry, and clean padding (ReaImGui 0.9+)

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
    settings        = opts.settings,                 -- Settings handle (recommend settings:sub("ui"))
    title           = opts.title or "Window",
    flags           = opts.flags or WF_None,

    -- layout
    content_padding = opts.content_padding or 12,    -- inner padding for the body child
    titlebar_pad_h  = opts.titlebar_pad_h,           -- optional FramePadding.x for title
    titlebar_pad_v  = opts.titlebar_pad_v or 7,      -- FramePadding.y for title
    title_font      = opts.title_font,               -- optional ImGui font for titlebar text

    -- geometry
    initial_pos     = opts.initial_pos  or { x = 100, y = 100 },
    initial_size    = opts.initial_size or { w = 900, h = 600 },
    min_size        = opts.min_size     or { w = 400, h = 300 },

    -- status bar (object with .height and .render(ctx))
    status_bar      = opts.status_bar,

    -- internals
    _saved_pos      = nil,
    _saved_size     = nil,
    _pos_size_set   = false,
    _body_open      = false,
    _begun          = false,
  }

  -- No collapse by default if available
  if ImGui.WindowFlags_NoCollapse then
    win.flags = win.flags | ImGui.WindowFlags_NoCollapse
  end

  -- Restore persisted geometry if settings provided
  if win.settings then
    win._saved_pos  = win.settings:get("window.pos",  nil)
    win._saved_size = win.settings:get("window.size", nil)
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

  -- Public API --------------------------------------------------------------

  function win:set_title(s) self.title = tostring(s or self.title) end
  function win:set_title_font(font) self.title_font = font end

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

  function win:_apply_geometry(ctx)
    if not self._pos_size_set then
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

  -- Draw outer window (titlebar + content region)
  function win:Begin(ctx)
    self._body_open = false
    self:_apply_geometry(ctx)

    -- Outer: zero padding, we’ll pad the body child only
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding, 0, 0)
    local pushed = 1

    local pushed_title_pad = false
    if self.titlebar_pad_v or self.titlebar_pad_h then
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, self.titlebar_pad_h or 8, self.titlebar_pad_v or 7)
      pushed = pushed + 1
      pushed_title_pad = true
    end

    local font_pushed = false
    if self.title_font then
      ImGui.PushFont(ctx, self.title_font)
      font_pushed = true
    end

    local visible, open = ImGui.Begin(ctx, self.title, true, self.flags)
    self._begun = true

    if font_pushed then ImGui.PopFont(ctx) end
    if pushed_title_pad then ImGui.PopStyleVar(ctx) end
    ImGui.PopStyleVar(ctx) -- WindowPadding

    if visible then self:_save_geometry(ctx) end
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
    ImGui.BeginChild(ctx, "##body", 0, body_h)
    self._body_open = true
    return true
  end

  function win:EndBody(ctx)
    if not self._body_open then return end
    ImGui.EndChild(ctx)
    ImGui.PopStyleVar(ctx) -- body padding
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
