-- ReArkitekt/app/shell.lua
-- App runner: context, fonts, optional style push/pop, window lifecycle, profiling support
-- Extended with overlay manager support

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui   = require 'imgui' '0.9'
local Runtime = require('ReArkitekt.app.runtime')
local Window  = require('ReArkitekt.app.window')

local M = {}

local DEFAULTS = {}
do
  local ok, Config = pcall(require, 'ReArkitekt.app.config')
  if ok and Config and Config.get_defaults then
    DEFAULTS = Config.get_defaults()
  else
    DEFAULTS = {
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
  end
end

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

  local cfg = {
    window = DEFAULTS.window,
    fonts  = DEFAULTS.fonts,
  }

  if opts.window then merge(cfg.window, opts.window) end
  if opts.fonts  or opts.font_sizes then
    merge(cfg.fonts, (opts.fonts or opts.font_sizes))
  end

  local title    = opts.title or cfg.window.title
  local draw_fn  = opts.draw or function(ctx) ImGui.Text(ctx, 'No draw function provided') end
  local style    = opts.style
  local settings = opts.settings
  local raw_content = (opts.raw_content == true)
  local enable_profiling = opts.enable_profiling ~= false

  local ctx   = ImGui.CreateContext(title)
  local fonts = load_fonts(ctx, cfg.fonts)

  local window = Window.new({
    title           = title,
    title_font      = fonts.title,
    settings        = settings and settings:sub('ui') or nil,
    initial_pos     = opts.initial_pos  or cfg.window.initial_pos,
    initial_size    = opts.initial_size or cfg.window.initial_size,
    min_size        = opts.min_size     or cfg.window.min_size,
    show_status_bar = opts.show_status_bar,
    show_titlebar   = opts.show_titlebar,
    get_status_func = opts.get_status_func,
    status_bar_height = DEFAULTS.status_bar and DEFAULTS.status_bar.height or 28,
    content_padding = opts.content_padding or cfg.window.content_padding,
    titlebar_pad_h  = opts.titlebar_pad_h,
    titlebar_pad_v  = opts.titlebar_pad_v,
    flags           = opts.flags,
    style           = style,
    tabs            = opts.tabs,
    bg_color_floating = opts.bg_color_floating,
    bg_color_docked   = opts.bg_color_docked,
  })
  
  -- Pass overlay manager to window if provided
  if opts.overlay then
    window.overlay = opts.overlay
  end

  local state = {
    window   = window,
    settings = settings,
    fonts    = fonts,
    style    = style,
    overlay  = opts.overlay,
    profiling = {
      enabled = enable_profiling,
      frame_start = 0,
      draw_time = 0,
      total_time = 0,
    }
  }

  local function draw_with_profiling(ctx, state)
    if enable_profiling and window.start_timer then
      window:start_timer("draw")
    end
    
    local result = draw_fn(ctx, state)
    
    if enable_profiling and window.end_timer then
      state.profiling.draw_time = window:end_timer("draw")
    end
    
    return result
  end

  local runtime = Runtime.new({
    title = title,
    ctx   = ctx,

    on_frame = function(ctx)
      if enable_profiling then
        state.profiling.frame_start = reaper.time_precise()
      end
      
      if style and style.PushMyStyle then 
        if enable_profiling and window.start_timer then
          window:start_timer("style_push")
        end
        style.PushMyStyle(ctx)
        if enable_profiling and window.end_timer then
          window:end_timer("style_push")
        end
      end
      
      ImGui.PushFont(ctx, fonts.default)

      local visible, open = window:Begin(ctx)
      if visible then
        if raw_content then
          draw_with_profiling(ctx, state)
        else
          if window:BeginBody(ctx) then
            draw_with_profiling(ctx, state)
            window:EndBody(ctx)
          end
        end
      end
      window:End(ctx)

      ImGui.PopFont(ctx)
      
      if style and style.PopMyStyle then 
        if enable_profiling and window.start_timer then
          window:start_timer("style_pop")
        end
        style.PopMyStyle(ctx)
        if enable_profiling and window.end_timer then
          window:end_timer("style_pop")
        end
      end

      if settings and settings.maybe_flush then 
        if enable_profiling and window.start_timer then
          window:start_timer("settings_flush")
        end
        settings:maybe_flush()
        if enable_profiling and window.end_timer then
          window:end_timer("settings_flush")
        end
      end
      
      if enable_profiling then
        state.profiling.total_time = (reaper.time_precise() - state.profiling.frame_start) * 1000
        if window.profiling then
          window.profiling.custom_timers["total_frame"] = state.profiling.total_time
        end
      end
      
      return open ~= false
    end,

    on_destroy = function()
      if settings and settings.flush then settings:flush() end
      if opts.on_close then opts.on_close() end
    end,
  })

  state.start_timer = function(name)
    if window.start_timer then
      window:start_timer(name)
    end
  end
  
  state.end_timer = function(name)
    if window.end_timer then
      return window:end_timer(name)
    end
    return 0
  end
  
  state.toggle_profiling = function()
    if window.toggle_profiling then
      window:toggle_profiling()
    end
  end
  
  state.get_profiling_data = function()
    if window.profiling then
      return window.profiling
    end
    return nil
  end

  runtime:start()
  return runtime
end

return M