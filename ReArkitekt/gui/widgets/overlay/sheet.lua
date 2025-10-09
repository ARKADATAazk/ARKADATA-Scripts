-- ReArkitekt/gui/widgets/overlay/sheet.lua
-- A task-oriented modal "sheet" with visual polish

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local Draw   = require('ReArkitekt.gui.draw')
local Colors = require('ReArkitekt.core.colors')
local Style  = require('ReArkitekt.gui.style')
local OverlayConfig = require('ReArkitekt.gui.widgets.overlay.config')

local Sheet = {}

function Sheet.render(ctx, alpha, bounds, content_fn, opts)
  opts = opts or {}
  
  local config = OverlayConfig.get()
  if opts.config then
    config = OverlayConfig.override(opts.config)
  end
  
  local w = math.floor(bounds.w * (opts.width  or 0.72))
  local h = math.floor(bounds.h * (opts.height or 0.72))
  local x = math.floor(bounds.x + (bounds.w - w) * 0.5)
  local y = math.floor(bounds.y + (bounds.h - h) * 0.5)
  local r = opts.rounding or config.sheet.rounding

  local bg_base = config.sheet.background.color
  local bg = Colors.with_alpha(bg_base, math.floor(255 * config.sheet.background.opacity * alpha))
  local dl = bounds.dl
  
  if config.sheet.shadow.enabled then
    for i = config.sheet.shadow.layers, 1, -1 do
      local shadow_offset = math.floor((i / config.sheet.shadow.layers) * config.sheet.shadow.max_offset)
      local shadow_alpha = math.floor((config.sheet.shadow.base_alpha / i) * alpha)
      local shadow_color = Colors.with_alpha(0x000000FF, shadow_alpha)
      Draw.rect_filled(dl, 
        x - shadow_offset, y - shadow_offset, 
        x + w + shadow_offset, y + h + shadow_offset, 
        shadow_color, r + shadow_offset)
    end
  end
  
  Draw.rect_filled(dl, x, y, x+w, y+h, bg, r)
  
  if config.sheet.gradient.top_enabled then
    local gradient_height = config.sheet.gradient.top_height
    local max_alpha = config.sheet.gradient.top_max_alpha
    for i = 0, gradient_height, 2 do
      local grad_alpha = math.floor((1.0 - (i / gradient_height)) * max_alpha * 255 * alpha)
      local grad_color = Colors.with_alpha(config.sheet.gradient.top_color, grad_alpha)
      Draw.rect_filled(dl, x, y + i, x + w, y + i + 2, grad_color, 0)
    end
  end
  
  if config.sheet.gradient.bottom_enabled then
    local bottom_gradient_height = config.sheet.gradient.bottom_height
    local max_alpha = config.sheet.gradient.bottom_max_alpha
    for i = 0, bottom_gradient_height, 2 do
      local progress = i / bottom_gradient_height
      local grad_alpha = math.floor(progress * max_alpha * 255 * alpha)
      local grad_color = Colors.with_alpha(config.sheet.gradient.bottom_color, grad_alpha)
      Draw.rect_filled(dl, x, y + h - bottom_gradient_height + i, x + w, y + h - bottom_gradient_height + i + 2, grad_color, 0)
    end
  end
  
  local border_color = Colors.with_alpha(
    config.sheet.border.outer_color, 
    math.floor(255 * config.sheet.border.outer_opacity * alpha)
  )
  Draw.rect(dl, x, y, x+w, y+h, border_color, r, config.sheet.border.outer_thickness)
  
  local inner_border = Colors.with_alpha(
    config.sheet.border.inner_color,
    math.floor(255 * config.sheet.border.inner_opacity * alpha)
  )
  Draw.rect(dl, x + 1, y + 1, x + w - 1, y + h - 1, inner_border, r - 1, config.sheet.border.inner_thickness)

  local hh = opts.header_h or config.sheet.header.height
  local title = tostring(opts.title or "")
  if #title > 0 then
    local title_color = Colors.with_alpha(
      config.sheet.header.text_color,
      math.floor(255 * config.sheet.header.text_opacity * alpha)
    )
    Draw.text(dl, x + 20, y + math.floor((hh - 14) / 2), title_color, title)
    
    local divider_y = y + hh
    local divider_gradient_w = config.sheet.header.divider_fade_width
    local divider_base_alpha = math.floor(255 * config.sheet.header.divider_opacity * alpha)
    
    for i = 0, divider_gradient_w do
      local progress = i / divider_gradient_w
      local div_alpha = math.floor(progress * divider_base_alpha)
      local div_color = Colors.with_alpha(config.sheet.header.divider_color, div_alpha)
      Draw.line(dl, x + i, divider_y, x + i, divider_y, div_color, config.sheet.header.divider_thickness)
    end
    
    local main_divider = Colors.with_alpha(config.sheet.header.divider_color, divider_base_alpha)
    Draw.line(dl, x + divider_gradient_w, divider_y, x + w - divider_gradient_w, divider_y, main_divider, config.sheet.header.divider_thickness)
    
    for i = 0, divider_gradient_w do
      local progress = 1.0 - (i / divider_gradient_w)
      local div_alpha = math.floor(progress * divider_base_alpha)
      local div_color = Colors.with_alpha(config.sheet.header.divider_color, div_alpha)
      Draw.line(dl, x + w - divider_gradient_w + i, divider_y, x + w - divider_gradient_w + i, divider_y, div_color, config.sheet.header.divider_thickness)
    end
    
    local highlight = Colors.with_alpha(
      config.sheet.header.highlight_color,
      math.floor(255 * config.sheet.header.highlight_opacity * alpha)
    )
    Draw.line(dl, x + divider_gradient_w, divider_y + 1, x + w - divider_gradient_w, divider_y + 1, highlight, config.sheet.header.highlight_thickness)
  end

  ImGui.SetCursorScreenPos(ctx, x, y + hh)
  local child_flags = ImGui.ChildFlags_None or 0
  local window_flags = ImGui.WindowFlags_NoScrollbar or 0
  ImGui.BeginChild(ctx, '##sheet', w, h - hh, child_flags, window_flags)
  if content_fn then content_fn(ctx, w, h - hh, alpha) end
  ImGui.EndChild(ctx)
end

return Sheet