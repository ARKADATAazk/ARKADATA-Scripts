-- ReArkitekt/gui/fx/dnd/drop_indicator.lua
-- Drop indicator for drag and drop reordering (uses your existing colors.lua)

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'
local DndConfig = require('ReArkitekt.gui.fx.dnd.config')

local M = {}

function M.draw_vertical(ctx, dl, x, y1, y2, config, is_copy_mode)
  local cfg = config or DndConfig.DROP_DEFAULTS
  local mode_cfg = DndConfig.get_mode_config(config, is_copy_mode, false)
  
  -- Access nested line config
  local line_cfg = (mode_cfg and mode_cfg.line) or (cfg.line) or DndConfig.DROP_DEFAULTS
  local line_width = cfg.line_width or line_cfg.width or DndConfig.DROP_DEFAULTS.line_width
  local line_color = line_cfg.color or mode_cfg.stroke_color or DndConfig.MODES.move.stroke_color
  local glow_width = cfg.glow_width or line_cfg.glow_width or DndConfig.DROP_DEFAULTS.glow_width
  local glow_color = line_cfg.glow_color or mode_cfg.glow_color or DndConfig.MODES.move.glow_color
  
  -- Access nested caps config
  local caps_cfg = (mode_cfg and mode_cfg.caps) or (cfg.caps) or DndConfig.DROP_DEFAULTS.caps
  local cap_width = caps_cfg.width or DndConfig.DROP_DEFAULTS.caps.width
  local cap_height = caps_cfg.height or DndConfig.DROP_DEFAULTS.caps.height
  local cap_color = caps_cfg.color or mode_cfg.stroke_color or DndConfig.MODES.move.stroke_color
  local cap_rounding = caps_cfg.rounding or DndConfig.DROP_DEFAULTS.caps.rounding
  local cap_glow_size = caps_cfg.glow_size or DndConfig.DROP_DEFAULTS.caps.glow_size
  local cap_glow_color = caps_cfg.glow_color or mode_cfg.glow_color or DndConfig.MODES.move.glow_color
  
  local pulse_speed = cfg.pulse_speed or DndConfig.DROP_DEFAULTS.pulse_speed
  
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
  local cfg = config or DndConfig.DROP_DEFAULTS
  local mode_cfg = DndConfig.get_mode_config(config, is_copy_mode, false)
  
  -- Access nested line config
  local line_cfg = (mode_cfg and mode_cfg.line) or (cfg.line) or DndConfig.DROP_DEFAULTS
  local line_width = cfg.line_width or line_cfg.width or DndConfig.DROP_DEFAULTS.line_width
  local line_color = line_cfg.color or mode_cfg.stroke_color or DndConfig.MODES.move.stroke_color
  local glow_width = cfg.glow_width or line_cfg.glow_width or DndConfig.DROP_DEFAULTS.glow_width
  local glow_color = line_cfg.glow_color or mode_cfg.glow_color or DndConfig.MODES.move.glow_color
  
  -- Access nested caps config
  local caps_cfg = (mode_cfg and mode_cfg.caps) or (cfg.caps) or DndConfig.DROP_DEFAULTS.caps
  local cap_width = caps_cfg.width or DndConfig.DROP_DEFAULTS.caps.width
  local cap_height = caps_cfg.height or DndConfig.DROP_DEFAULTS.caps.height
  local cap_color = caps_cfg.color or mode_cfg.stroke_color or DndConfig.MODES.move.stroke_color
  local cap_rounding = caps_cfg.rounding or DndConfig.DROP_DEFAULTS.caps.rounding
  local cap_glow_size = caps_cfg.glow_size or DndConfig.DROP_DEFAULTS.caps.glow_size
  local cap_glow_color = caps_cfg.glow_color or mode_cfg.glow_color or DndConfig.MODES.move.glow_color
  
  local pulse_speed = cfg.pulse_speed or DndConfig.DROP_DEFAULTS.pulse_speed
  
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