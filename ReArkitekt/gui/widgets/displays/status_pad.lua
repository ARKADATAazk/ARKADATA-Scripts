-- ReArkitekt/gui/widgets/displays/status_pad.lua
-- Interactive status tile with a modern, flat design. (ReaImGui 0.9)

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9' -- FIX: Matched version to demo3.lua (0.9)

local Draw   = require('ReArkitekt.gui.draw')
local Colors = require('ReArkitekt.core.colors')

local M = {}

local DEFAULTS = {
  width = 220,
  height = 56,
  rounding = 6,
  base_color = 0x4169E1FF,
  icon_box_size   = 18,
  icon_area_width = 45,
  text_padding_x       = 16,
  text_primary_size    = 1.0,
  text_secondary_size  = 0.9,
  text_line_spacing    = 3,
  hover_animation_speed = 12.0,
  icons = {
    check = "✓",
    cross = "✕",
    minus = "−",
    dot   = "●",
  },
}

-- -------- Font cache (unchanged) --------
local FontPool = {}
local function _scale_key(scale) return string.format('%.3f', scale or 1.0) end
local function _get_scaled_font(ctx, rel_scale)
  rel_scale = rel_scale or 1.0
  local base_px = ImGui.GetFontSize(ctx) or 13
  local pool = FontPool[ctx]
  if not pool or pool.base_px ~= base_px then
    pool = { base_px = base_px, fonts = {} }
    FontPool[ctx] = pool
  end
  local key = _scale_key(rel_scale)
  local font = pool.fonts[key]
  if font == nil then
    local px = math.max(1, math.floor(base_px * rel_scale + 0.5))
    local created = ImGui.CreateFont('sans-serif', px)
    if created then
      ImGui.Attach(ctx, created)
      pool.fonts[key] = created
      font = created
    else
      pool.fonts[key] = false
      font = nil
    end
  elseif font == false then font = nil end
  return font
end

local function _measure_text(ctx, text, rel_scale)
  local font = _get_scaled_font(ctx, rel_scale)
  if font then
    ImGui.PushFont(ctx, font) -- FIX: Removed non-standard 3rd argument
    local w, h = ImGui.CalcTextSize(ctx, text or '')
    ImGui.PopFont(ctx)
    return w, h
  else
    local w, h = ImGui.CalcTextSize(ctx, text or '')
    return w * (rel_scale or 1.0), h * (rel_scale or 1.0)
  end
end

local function _draw_text_scaled_clipped(ctx, text, x, y, max_w, color, rel_scale)
  local font = _get_scaled_font(ctx, rel_scale)
  if font then
    ImGui.PushFont(ctx, font) -- FIX: Removed non-standard 3rd argument
    Draw.text_clipped(ctx, text, x, y, max_w, color)
    ImGui.PopFont(ctx)
  else
    Draw.text_clipped(ctx, text, x, y, max_w, color)
  end
end
-- -----------------------------------------

local StatusPad = {}
StatusPad.__index = StatusPad

function M.new(opts)
  opts = opts or {}
  local pad = setmetatable({
    id             = opts.id or "status_pad",
    width          = opts.width   or DEFAULTS.width,
    height         = opts.height  or DEFAULTS.height,
    rounding       = opts.rounding or DEFAULTS.rounding,
    base_color     = opts.color or DEFAULTS.base_color,
    primary_text   = opts.primary_text or "",
    secondary_text = opts.secondary_text,
    state          = opts.state or false,
    icon_type      = opts.icon_type or "check",
    badge_text     = opts.badge_text,
    on_click       = opts.on_click,
    hover_alpha    = 0,
    config         = {},
  }, StatusPad)
  for k, v in pairs(DEFAULTS) do
    if type(v) ~= "table" then
      pad.config[k] = (opts.config and opts.config[k]) or v
    end
  end
  return pad
end

function StatusPad:_draw_checkbox_icon(ctx, dl, x2, y1)
    local cfg = self.config
    local icon_box_size = cfg.icon_box_size
    local icon_box_x = x2 - cfg.icon_area_width + (cfg.icon_area_width - icon_box_size) / 2
    local icon_box_y = y1 + (self.height - icon_box_size) / 2
    local border_alpha = self.state and 0xFF or 0x99
    local border_color = self.state and self.base_color or Colors.with_alpha(0xFFFFFFFF, border_alpha)
    ImGui.DrawList_AddRect(dl, icon_box_x, icon_box_y, icon_box_x + icon_box_size, icon_box_y + icon_box_size, border_color, 3, 0, 1.5)
    if self.state then
        local icon_char = DEFAULTS.icons[self.icon_type] or DEFAULTS.icons.check
        local font = _get_scaled_font(ctx, 1.1)
        if font then ImGui.PushFont(ctx, font) end -- FIX: Removed non-standard 3rd argument
        
        local text_w, text_h = ImGui.CalcTextSize(ctx, icon_char)
        local icon_x = icon_box_x + (icon_box_size - text_w) / 2
        local icon_y = icon_box_y + (icon_box_size - text_h) / 2
        Draw.text(dl, icon_x, icon_y, self.base_color, icon_char)
        
        if font then ImGui.PopFont(ctx) end -- FIX: Added missing PopFont call
    end
end

function StatusPad:draw(ctx, x, y)
  local dl = ImGui.GetWindowDrawList(ctx)
  local x1, y1 = x, y
  local x2, y2 = x + self.width, y + self.height
  local cfg = self.config

  local mx, my   = ImGui.GetMousePos(ctx)
  local hovered  = Draw.point_in_rect(mx, my, x1, y1, x2, y2)
  local dt = ImGui.GetDeltaTime(ctx)
  local target_alpha = hovered and 1.0 or 0.0
  self.hover_alpha = self.hover_alpha + (target_alpha - self.hover_alpha) * cfg.hover_animation_speed * dt
  self.hover_alpha = math.max(0, math.min(1, self.hover_alpha))

  local inactive_fill_color = Colors.adjust_brightness(Colors.desaturate(self.base_color, 0.85), 0.35)
  local active_fill_color = Colors.adjust_brightness(Colors.desaturate(self.base_color, 0.5), 0.5)
  local base_bg = self.state and active_fill_color or inactive_fill_color
  if self.hover_alpha > 0.01 then
    local hover_bg = Colors.adjust_brightness(base_bg, 1.2)
    base_bg = Colors.lerp(base_bg, hover_bg, self.hover_alpha)
  end
  local inactive_border_color = Colors.adjust_brightness(self.base_color, 0.7)
  local border_start_color = self.state and self.base_color or inactive_border_color
  local border_end_color   = self.state and Colors.saturate(self.base_color, 1.5) or Colors.with_alpha(0xFFFFFFFF, 0x50)
  local border_color = Colors.lerp(border_start_color, border_end_color, self.hover_alpha)
  local border_thickness = 1.2 + (self.state and 0.5 or 0) + self.hover_alpha * 0.5
  
  ImGui.DrawList_AddRectFilled(dl, x1, y1, x2, y2, base_bg, self.rounding)
  ImGui.DrawList_AddRect(dl, x1 + 0.5, y1 + 0.5, x2 - 0.5, y2 - 0.5, border_color, self.rounding, 0, border_thickness)

  self:_draw_checkbox_icon(ctx, dl, x2, y1)

  local text_x = x1 + cfg.text_padding_x
  local available_width = self.width - cfg.text_padding_x * 2 - cfg.icon_area_width
  local primary_color   = self.state and 0xFFFFFFFF or 0xCCCCCCFF
  local secondary_color = self.state and 0xAAAAAAFF or 0x888888FF
  if self.secondary_text and self.secondary_text ~= "" then
    local primary_scale   = cfg.text_primary_size
    local secondary_scale = cfg.text_secondary_size
    local _, primary_h   = _measure_text(ctx, self.primary_text,   primary_scale)
    local _, secondary_h = _measure_text(ctx, self.secondary_text, secondary_scale)
    local total_h = primary_h + secondary_h + cfg.text_line_spacing
    local text_y  = y1 + (self.height - total_h) / 2
    _draw_text_scaled_clipped(ctx, self.primary_text, text_x, text_y, available_width, primary_color, primary_scale)
    _draw_text_scaled_clipped(ctx, self.secondary_text, text_x, text_y + primary_h + cfg.text_line_spacing, available_width, secondary_color, secondary_scale)
  else
    local scale  = cfg.text_primary_size
    local _, th  = _measure_text(ctx, self.primary_text, scale)
    local text_y = y1 + (self.height - th) / 2
    _draw_text_scaled_clipped(ctx, self.primary_text, text_x, text_y, available_width, primary_color, scale)
  end

  ImGui.SetCursorScreenPos(ctx, x1, y1)
  ImGui.InvisibleButton(ctx, self.id .. "_btn", self.width, self.height)
  local clicked = ImGui.IsItemClicked(ctx, 0)
  if clicked and self.on_click then self.on_click(not self.state) end
  return clicked
end

function StatusPad:set_state(state) self.state = state end
function StatusPad:get_state() return self.state end
function StatusPad:set_primary_text(text) self.primary_text = text end
function StatusPad:set_secondary_text(text) self.secondary_text = text end
function StatusPad:set_badge_text(text) self.badge_text = text end
function StatusPad:set_color(color) self.base_color = color end

return M