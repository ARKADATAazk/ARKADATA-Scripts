-- ReArkitekt/app/window.lua
-- Window with integrated status bar support and content padding

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local M = {}

local CF_None = ImGui.ChildFlags_None or 0
local WF_None = 0

local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end

function M.new(opts)
  opts = opts or {}

  local win = {
    settings        = opts.settings,
    title           = opts.title or "Window",
    flags           = opts.flags or 0,

    content_padding = opts.content_padding or 12,

    titlebar_pad_h  = opts.titlebar_pad_h,
    titlebar_pad_v  = opts.titlebar_pad_v or 7,
    title_font      = opts.title_font,

    initial_pos     = opts.initial_pos  or { x = 100, y = 100 },
    initial_size    = opts.initial_size or { w = 900, h = 600 },
    min_size        = opts.min_size     or { w = 400, h = 300 },

    status_bar      = opts.status_bar,
    
    _pos_size_applied   = false,
    _saved_pos          = nil,
    _saved_size         = nil,
    _body_child_open    = false,
  }

  if ImGui.WindowFlags_NoCollapse then
    win.flags = win.flags | ImGui.WindowFlags_NoCollapse
  end

  if win.settings then
    win._saved_pos  = win.settings:get("window.pos",  nil)
    win._saved_size = win.settings:get("window.size", nil)
  end

  if not win.status_bar then
    local ok, StatusBar = pcall(require, 'ReArkitekt.gui.widgets.status_bar')
    if ok and StatusBar and StatusBar.new then
      win.status_bar = StatusBar.new({
        height = 34,
        style  = opts.style and { palette = opts.style.palette } or nil,
        get_status = function() return { text = "READY", color = 0x41E0A3FF } end
      })
    end
  end

  function win:toggle_status_bar(enabled)
    if enabled == false then
      self.status_bar = nil
    elseif not self.status_bar then
      local ok, StatusBar = pcall(require, 'ReArkitekt.gui.widgets.status_bar')
      if ok and StatusBar and StatusBar.new then
        self.status_bar = StatusBar.new({
          height = 34,
          get_status = function() return { text = "READY", color = 0x41E0A3FF } end
        })
      end
    end
  end

  function win:_apply_geometry(ctx)
    if not self._pos_size_applied then
      local pos  = self._saved_pos  or self.initial_pos
      local size = self._saved_size or self.initial_size
      if pos and pos.x and pos.y then ImGui.SetNextWindowPos(ctx, pos.x, pos.y) end
      if size and size.w and size.h then ImGui.SetNextWindowSize(ctx, size.w, size.h) end
      self._pos_size_applied = true
    end
    
    if ImGui.SetNextWindowSizeConstraints and self.min_size then
      ImGui.SetNextWindowSizeConstraints(ctx, self.min_size.w, self.min_size.h, 99999, 99999)
    end
  end

  function win:_save_geometry(ctx)
    if not self.settings then return end
    local wx, wy = ImGui.GetWindowPos(ctx)
    local ww, wh = ImGui.GetWindowSize(ctx)
    local pos  = { x = math.floor(wx + 0.5), y = math.floor(wy + 0.5) }
    local size = { w = math.floor(ww + 0.5), h = math.floor(wh + 0.5) }
    if not self._saved_pos or pos.x ~= self._saved_pos.x or pos.y ~= self._saved_pos.y then
      self._saved_pos = pos
      self.settings:set("window.pos", pos)
    end
    if not self._saved_size or size.w ~= self._saved_size.w or size.h ~= self._saved_size.h then
      self._saved_size = size
      self.settings:set("window.size", size)
    end
  end

  function win:Begin(ctx)
    self._body_child_open = false
    
    self:_apply_geometry(ctx)

    ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding, 0, 0)

    local pushed_frame_pad = false
    if self.titlebar_pad_v or self.titlebar_pad_h then
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, self.titlebar_pad_h or 8, self.titlebar_pad_v or 7)
      pushed_frame_pad = true
    end

    if self.title_font then ImGui.PushFont(ctx, self.title_font) end
    local visible, open = ImGui.Begin(ctx, self.title, true, self.flags)
    if self.title_font then ImGui.PopFont(ctx) end
    if pushed_frame_pad then ImGui.PopStyleVar(ctx) end

    if visible then
      self:_save_geometry(ctx)
    end

    return visible, open
  end

  function win:BeginBody(ctx)
    if self._body_child_open then return false end

    local _, avail_h = ImGui.GetContentRegionAvail(ctx)
    local status_bar_height = self.status_bar and self.status_bar.height or 0
    local body_h = math.floor(avail_h - status_bar_height + 0.5)

    if body_h < 50 then return false end

    -- Body child has padding
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding, self.content_padding, self.content_padding)
    
    ImGui.BeginChild(ctx, "##body", 0, body_h)
    self._body_child_open = true
    
    return true
  end

  function win:EndBody(ctx)
    if not self._body_child_open then return end
    ImGui.EndChild(ctx)
    ImGui.PopStyleVar(ctx)
    self._body_child_open = false
  end
  
  function win:BeginTabs(ctx)
    -- Tabs area is full-width, no padding
    return true
  end
  
  function win:EndTabs(ctx)
    -- Nothing needed, just a marker
  end

  function win:End(ctx)
    if self.status_bar and self.status_bar.render then
      local _, avail_h = ImGui.GetContentRegionAvail(ctx)
      if avail_h > 20 then
        local x, y = ImGui.GetCursorPos(ctx)
        ImGui.SetCursorPos(ctx, 0, y - 4)
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing, 0, 0)
        self.status_bar.render(ctx)
        ImGui.PopStyleVar(ctx)
      end
    end

    ImGui.End(ctx)
    ImGui.PopStyleVar(ctx)
  end

  return win
end

return M