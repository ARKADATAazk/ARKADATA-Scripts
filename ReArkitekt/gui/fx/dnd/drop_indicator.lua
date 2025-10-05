-- ReArkitekt/gui/widgets/tiles/dnd.drop_indicator.lua
-- Drop indicator for drag and drop reordering with mode-aware colors and orientation support

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local M = {}

local DEFAULTS = {
  move_mode = {
    line = {
      width = 2,
      color = 0x42E896FF,
      glow_width = 12,
      glow_color = 0x42E89633,
    },
    caps = {
      width = 12,
      height = 3,
      color = 0x42E896FF,
      rounding = 0,
      glow_size = 6,
      glow_color = 0x42E89644,
    },
  },
  copy_mode = {
    line = {
      width = 2,
      color = 0x9C87E8FF,
      glow_width = 12,
      glow_color = 0x9C87E833,
    },
    caps = {
      width = 12,
      height = 3,
      color = 0x9C87E8FF,
      rounding = 0,
      glow_size = 6,
      glow_color = 0x9C87E844,
    },
  },
  pulse_speed = 2.5,
}

function M.draw_vertical(ctx, dl, x, y1, y2, config, is_copy_mode)
  local cfg = config or DEFAULTS
  local mode_cfg = is_copy_mode and 
                   ((cfg.copy_mode) or DEFAULTS.copy_mode) or
                   ((cfg.move_mode) or DEFAULTS.move_mode)
  
  local line_cfg = mode_cfg.line or DEFAULTS.move_mode.line
  local caps_cfg = mode_cfg.caps or DEFAULTS.move_mode.caps
  
  local line_width = line_cfg.width or DEFAULTS.move_mode.line.width
  local line_color = line_cfg.color or DEFAULTS.move_mode.line.color
  local glow_width = line_cfg.glow_width or DEFAULTS.move_mode.line.glow_width
  local glow_color = line_cfg.glow_color or DEFAULTS.move_mode.line.glow_color
  
  local cap_width = caps_cfg.width or DEFAULTS.move_mode.caps.width
  local cap_height = caps_cfg.height or DEFAULTS.move_mode.caps.height
  local cap_color = caps_cfg.color or DEFAULTS.move_mode.caps.color
  local cap_rounding = caps_cfg.rounding or DEFAULTS.move_mode.caps.rounding
  local cap_glow_size = caps_cfg.glow_size or DEFAULTS.move_mode.caps.glow_size
  local cap_glow_color = caps_cfg.glow_color or DEFAULTS.move_mode.caps.glow_color
  
  local pulse_speed = cfg.pulse_speed or DEFAULTS.pulse_speed
  
  local pulse = (math.sin(reaper.time_precise() * pulse_speed) * 0.3 + 0.7)
  local pulsed_alpha = math.floor(pulse * 255)
  local pulsed_line = (line_color & 0xFFFFFF00) | pulsed_alpha
  
  ImGui.DrawList_AddRectFilled(dl, x - glow_width/2, y1, x + glow_width/2, y2, glow_color, glow_width/2)
  
  ImGui.DrawList_AddRectFilled(dl, x - line_width/2, y1, x + line_width/2, y2, pulsed_line, line_width/2)
  
  local cap_half_w = cap_width / 2
  local cap_half_h = cap_height / 2
  
  ImGui.DrawList_AddRectFilled(dl, x - cap_half_w - cap_glow_size, y1 - cap_half_h - cap_glow_size, 
                                x + cap_half_w + cap_glow_size, y1 + cap_half_h + cap_glow_size, 
                                cap_glow_color, cap_rounding + cap_glow_size)
  ImGui.DrawList_AddRectFilled(dl, x - cap_half_w - cap_glow_size, y2 - cap_half_h - cap_glow_size, 
                                x + cap_half_w + cap_glow_size, y2 + cap_half_h + cap_glow_size, 
                                cap_glow_color, cap_rounding + cap_glow_size)
  
  ImGui.DrawList_AddRectFilled(dl, x - cap_half_w, y1 - cap_half_h, x + cap_half_w, y1 + cap_half_h, 
                                pulsed_line, cap_rounding)
  ImGui.DrawList_AddRectFilled(dl, x - cap_half_w, y2 - cap_half_h, x + cap_half_w, y2 + cap_half_h, 
                                pulsed_line, cap_rounding)
end

function M.draw_horizontal(ctx, dl, x1, x2, y, config, is_copy_mode)
  local cfg = config or DEFAULTS
  local mode_cfg = is_copy_mode and 
                   ((cfg.copy_mode) or DEFAULTS.copy_mode) or
                   ((cfg.move_mode) or DEFAULTS.move_mode)
  
  local line_cfg = mode_cfg.line or DEFAULTS.move_mode.line
  local caps_cfg = mode_cfg.caps or DEFAULTS.move_mode.caps
  
  local line_width = line_cfg.width or DEFAULTS.move_mode.line.width
  local line_color = line_cfg.color or DEFAULTS.move_mode.line.color
  local glow_width = line_cfg.glow_width or DEFAULTS.move_mode.line.glow_width
  local glow_color = line_cfg.glow_color or DEFAULTS.move_mode.line.glow_color
  
  local cap_width = caps_cfg.width or DEFAULTS.move_mode.caps.width
  local cap_height = caps_cfg.height or DEFAULTS.move_mode.caps.height
  local cap_color = caps_cfg.color or DEFAULTS.move_mode.caps.color
  local cap_rounding = caps_cfg.rounding or DEFAULTS.move_mode.caps.rounding
  local cap_glow_size = caps_cfg.glow_size or DEFAULTS.move_mode.caps.glow_size
  local cap_glow_color = caps_cfg.glow_color or DEFAULTS.move_mode.caps.glow_color
  
  local pulse_speed = cfg.pulse_speed or DEFAULTS.pulse_speed
  
  local pulse = (math.sin(reaper.time_precise() * pulse_speed) * 0.3 + 0.7)
  local pulsed_alpha = math.floor(pulse * 255)
  local pulsed_line = (line_color & 0xFFFFFF00) | pulsed_alpha
  
  ImGui.DrawList_AddRectFilled(dl, x1, y - glow_width/2, x2, y + glow_width/2, glow_color, glow_width/2)
  
  ImGui.DrawList_AddRectFilled(dl, x1, y - line_width/2, x2, y + line_width/2, pulsed_line, line_width/2)
  
  local cap_half_w = cap_width / 2
  local cap_half_h = cap_height / 2
  
  ImGui.DrawList_AddRectFilled(dl, x1 - cap_half_w - cap_glow_size, y - cap_half_h - cap_glow_size, 
                                x1 + cap_half_w + cap_glow_size, y + cap_half_h + cap_glow_size, 
                                cap_glow_color, cap_rounding + cap_glow_size)
  ImGui.DrawList_AddRectFilled(dl, x2 - cap_half_w - cap_glow_size, y - cap_half_h - cap_glow_size, 
                                x2 + cap_half_w + cap_glow_size, y + cap_half_h + cap_glow_size, 
                                cap_glow_color, cap_rounding + cap_glow_size)
  
  ImGui.DrawList_AddRectFilled(dl, x1 - cap_half_w, y - cap_half_h, x1 + cap_half_w, y + cap_half_h, 
                                pulsed_line, cap_rounding)
  ImGui.DrawList_AddRectFilled(dl, x2 - cap_half_w, y - cap_half_h, x2 + cap_half_w, y + cap_half_h, 
                                pulsed_line, cap_rounding)
end

function M.draw(ctx, dl, config, is_copy_mode, orientation, ...)
  if orientation == 'horizontal' then
    local x1, x2, y = ...
    M.draw_horizontal(ctx, dl, x1, x2, y, config, is_copy_mode)
  else
    local x, y1, y2 = ...
    M.draw_vertical(ctx, dl, x, y1, y2, config, is_copy_mode)
  end
end

return M