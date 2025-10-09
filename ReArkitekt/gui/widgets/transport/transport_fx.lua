-- ReArkitekt/gui/widgets/transport/transport_fx.lua
-- Simple glass transport effects

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.10'

local Colors = require('ReArkitekt.core.colors')

local M = {}

M.DEFAULT_CONFIG = {
  rounding = 8,
  
  base = {
    color = 0x161616FF,
  },
  
  specular = {
    height = 40,
    strength = 0.01,
  },
  
  inner_glow = {
    size = 20,
    strength = 0.10,
  },
  
  border = {
    color = 0x000000FF,
    thickness = 1,
  },
  
  hover = {
    specular_boost = 1.5,
    glow_boost = 1.3,
    transition_speed = 6.0,
  },
}

function M.render_base(dl, x1, y1, x2, y2, config)
  ImGui.DrawList_AddRectFilled(dl, x1, y1, x2, y2, config.base.color, config.rounding)
end

function M.render_specular(dl, x1, y1, x2, y2, config, hover_factor)
  hover_factor = hover_factor or 0
  local spec_cfg = config.specular
  
  local strength = spec_cfg.strength * (1.0 + hover_factor * (config.hover.specular_boost - 1.0))
  local spec_y2 = y1 + spec_cfg.height
  
  local alpha_top = math.floor(255 * strength)
  local color_top = Colors.components_to_rgba(255, 255, 255, alpha_top)
  local color_bottom = Colors.components_to_rgba(255, 255, 255, 0)
  
  ImGui.DrawList_AddRectFilledMultiColor(dl, x1, y1, x2, spec_y2,
    color_top, color_top, color_bottom, color_bottom)
end

function M.render_inner_glow(dl, x1, y1, x2, y2, config, hover_factor)
  hover_factor = hover_factor or 0
  local glow_cfg = config.inner_glow
  
  local strength = glow_cfg.strength * (1.0 + hover_factor * (config.hover.glow_boost - 1.0))
  local size = glow_cfg.size
  local alpha = math.floor(255 * strength)
  
  local shadow_color = Colors.components_to_rgba(0, 0, 0, alpha)
  local transparent = Colors.components_to_rgba(0, 0, 0, 0)
  
  ImGui.DrawList_AddRectFilledMultiColor(dl,
    x1, y1,
    x2, y1 + size,
    shadow_color, shadow_color, transparent, transparent)
  
  ImGui.DrawList_AddRectFilledMultiColor(dl,
    x1, y1,
    x1 + size, y2,
    shadow_color, transparent, transparent, shadow_color)
  
  ImGui.DrawList_AddRectFilledMultiColor(dl,
    x2 - size, y1,
    x2, y2,
    transparent, shadow_color, shadow_color, transparent)
  
  ImGui.DrawList_AddRectFilledMultiColor(dl,
    x1, y2 - size,
    x2, y2,
    transparent, transparent, shadow_color, shadow_color)
end

function M.render_border(dl, x1, y1, x2, y2, config)
  local border_cfg = config.border
  ImGui.DrawList_AddRect(dl, x1, y1, x2, y2, border_cfg.color, config.rounding, 0, border_cfg.thickness)
end

function M.render_complete(dl, x1, y1, x2, y2, config, hover_factor)
  config = config or M.DEFAULT_CONFIG
  hover_factor = hover_factor or 0
  
  M.render_base(dl, x1, y1, x2, y2, config)
  M.render_specular(dl, x1, y1, x2, y2, config, hover_factor)
  M.render_inner_glow(dl, x1, y1, x2, y2, config, hover_factor)
  M.render_border(dl, x1, y1, x2, y2, config)
end

return M