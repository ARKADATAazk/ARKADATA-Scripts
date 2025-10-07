-- ReArkitekt/app/shell.lua
-- App runner: context, fonts, optional style push/pop, window lifecycle

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui   = require 'imgui' '0.9'
local Runtime = require('ReArkitekt.app.runtime')
local Window  = require('ReArkitekt.app.window')

local M = {}

-- Defaults (can be overridden by optional ReArkitekt/app/config.lua)
local DEFAULTS = {
  window = {
    title           = 'ReArkitekt App',
    content_padding = 12,
    min_size        = { w = 400, h = 300 },
    initial_size    = { w = 900, h = 600 },
    initial_pos     = { x = 100, y = 100 },
  },
  fonts = {
    default        = 13,
    title          = 16,
    family_regular = 'Inter_18pt-Regular.ttf',
    family_bold    = 'Inter_18pt-SemiBold.ttf',
  },
}

local function merge(dst, src)
  if not src then return dst end
  for k,v in pairs(src) do
    if type(v) == 'table' and type(dst[k]) == 'table' then
      merge(dst[k], v)
    else
      dst[k] = v
    end
  end
  return dst
end

-- Font loader (../fonts relative to this file). Fallback: system 'sans-serif'.
local function load_fonts(ctx, font_cfg)
  font_cfg = merge({
    default        = DEFAULTS.fonts.default,
    title          = DEFAULTS.fonts.title,
    family_regular = DEFAULTS.fonts.family_regular,
    family_bold    = DEFAULTS.fonts.family_bold,
  }, font_cfg or {})

  local SEP      = package.config:sub(1,1)
  local src      = debug.getinfo(1, 'S').source:sub(2)
  local this_dir = src:match('(.*'..SEP..')') or ('.'..SEP)
  local parent   = this_dir:match('^(.*'..SEP..')[^'..SEP..']*'..SEP..'$') or this_dir
  local fontsdir = parent .. 'fonts' .. SEP

  local R = fontsdir .. font_cfg.family_regular
  local B = fontsdir .. font_cfg.family_bold

  local function exists(p) local f = io.open(p, 'rb'); if f then f:close(); return true end end
  local default_font = exists(R) and ImGui.CreateFont(R, font_cfg.default)
                                or ImGui.CreateFont('sans-serif', font_cfg.default)
  local title_font   = exists(B) and ImGui.CreateFont(B, font_cfg.title)
                                or default_font

  ImGui.Attach(ctx, default_font)
  ImGui.Attach(ctx, title_font)
  return { default = default_font, title = title_font }
end

function M.run(opts)
  opts = opts or {}

  -- Optional external config
  do
    local ok, Config = pcall(require, 'ReArkitekt.app.config')
    if ok and type(Config) == 'table' and Config.get_defaults then
      DEFAULTS = merge(DEFAULTS, Config.get_defaults())
    end
  end

  -- Effective cfg (defaults + user overrides)
  local cfg = merge({
    window = {},
    fonts  = {},
  }, DEFAULTS)

  if opts.window then merge(cfg.window, opts.window) end
  if opts.fonts  or opts.font_sizes then
    merge(cfg.fonts, (opts.fonts or opts.font_sizes))
  end

  local title    = opts.title or cfg.window.title
  local draw_fn  = opts.draw or function(ctx) ImGui.Text(ctx, 'No draw function provided') end
  local style    = opts.style
  local settings = opts.settings   -- recommend passing a Settings root; shell uses :sub('ui')

  -- Context + fonts
  local ctx   = ImGui.CreateContext(title)
  local fonts = load_fonts(ctx, cfg.fonts)

  -- Window instance
  local window = Window.new({
    title           = title,
    title_font      = fonts.title,
    settings        = settings and settings:sub('ui') or nil,
    initial_pos     = opts.initial_pos  or cfg.window.initial_pos,
    initial_size    = opts.initial_size or cfg.window.initial_size,
    min_size        = opts.min_size     or cfg.window.min_size,
    status_bar      = opts.status_bar,
    content_padding = opts.content_padding or cfg.window.content_padding,
    titlebar_pad_h  = opts.titlebar_pad_h,
    titlebar_pad_v  = opts.titlebar_pad_v,
    flags           = opts.flags,
  })

  local state = {
    window   = window,
    settings = settings,
    fonts    = fonts,
    style    = style,
  }

  local runtime = Runtime.new({
    title = title,
    ctx   = ctx,

    on_frame = function(ctx)
      -- Optional global style
      if style and style.PushMyStyle then style.PushMyStyle(ctx) end
      ImGui.PushFont(ctx, fonts.default)

      local visible, open = window:Begin(ctx)
      if visible then
        draw_fn(ctx)
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
