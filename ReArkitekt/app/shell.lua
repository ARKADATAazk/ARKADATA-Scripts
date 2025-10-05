-- ReArkitekt/app/shell.lua
-- Simple app wrapper that creates window and runs main loop

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local Runtime = require('ReArkitekt.app.runtime')
local Window  = require('ReArkitekt.app.window')

local M = {}

local function load_fonts(ctx, font_sizes)
  font_sizes = font_sizes or {}
  local default_size = font_sizes.default or 13
  local title_size = font_sizes.title or 16
  
  local SEP = package.config:sub(1,1)
  local src = debug.getinfo(1, 'S').source:sub(2)
  local this_dir = src:match("(.*"..SEP..")") or ("."..SEP)
  local parent_dir = this_dir:match("^(.*"..SEP..")[^"..SEP.."]*"..SEP.."$") or this_dir
  local fonts_dir = parent_dir .. "fonts" .. SEP

  local R  = fonts_dir .. "Roboto-Regular.ttf"
  local B  = fonts_dir .. "Roboto-Bold.ttf"

  local function exists(p) local f=io.open(p,"rb"); if f then f:close(); return true end end
  local reg = exists(R) and ImGui.CreateFont(R, default_size, 0) or ImGui.CreateFont('sans-serif', default_size, 0)
  local bld = exists(B) and ImGui.CreateFont(B, title_size, 0) or reg

  ImGui.Attach(ctx, reg)
  ImGui.Attach(ctx, bld)
  return { default = reg, title = bld }
end

function M.run(opts)
  opts = opts or {}

  local title     = opts.title or "ReArkitekt App"
  local draw_fn   = opts.draw  or function(ctx, state) ImGui.Text(ctx, "No draw function provided") end
  local style     = opts.style
  local settings  = opts.settings

  local ctx = ImGui.CreateContext(title)
  local fonts = load_fonts(ctx, opts.font_sizes)

  local window = Window.new({
    title           = title,
    title_font      = fonts.title,
    settings        = settings and settings:sub("ui") or nil,
    initial_pos     = opts.initial_pos,
    initial_size    = opts.initial_size,
    min_size        = opts.min_size,
    status_bar      = opts.status_bar,
    style           = style,
    content_padding = opts.content_padding or 12,
  })

  local state = {
    window   = window,
    settings = settings,
    fonts    = fonts,
  }

  local runtime = Runtime.new({
    title = title,
    ctx   = ctx,

    on_frame = function(ctx)
      if style and style.PushMyStyle then style.PushMyStyle(ctx) end
      ImGui.PushFont(ctx, fonts.default)

      local visible, open = window:Begin(ctx)
      if visible then
        -- Draw content - tabs will be full width, content will be padded
        draw_fn(ctx, state)
      end
      window:End(ctx)

      ImGui.PopFont(ctx)
      if style and style.PopMyStyle then style.PopMyStyle(ctx) end

      if settings and settings.maybe_flush then settings:maybe_flush() end
      return open ~= false
    end,

    on_destroy = function()
      if settings and settings.flush then settings:flush() end
      if opts.on_close then opts.on_close() end
    end,
  })

  runtime:start()
  return runtime
end

return M