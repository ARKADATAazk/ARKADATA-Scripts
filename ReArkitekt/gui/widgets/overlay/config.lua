-- ReArkitekt/gui/widgets/overlay/config.lua
-- Configuration for modal overlay and sheet appearance

local M = {}

local default_config = {
  scrim = {
    color = 0x1A1A1AFF,
    opacity = 0.94,
  },
  
  sheet = {
    background = {
      color = 0x1A1A1AFF,
      opacity = 0.96,
    },
    
    shadow = {
      enabled = true,
      layers = 4,
      max_offset = 12,
      base_alpha = 20,
    },
    
    border = {
      outer_color = 0x404040FF,
      outer_opacity = 0.7,
      outer_thickness = 1.5,
      inner_color = 0xFFFFFFFF,
      inner_opacity = 0.10,
      inner_thickness = 1.0,
    },
    
    gradient = {
      top_enabled = true,
      top_color = 0xFFFFFFFF,
      top_height = 80,
      top_max_alpha = 0.06,
      
      bottom_enabled = true,
      bottom_color = 0x000000FF,
      bottom_height = 60,
      bottom_max_alpha = 0.08,
    },
    
    header = {
      height = 42,
      text_color = 0xFFFFFFFF,
      text_opacity = 1.0,
      
      divider_color = 0x666666FF,
      divider_opacity = 0.31,
      divider_thickness = 1.0,
      divider_fade_width = 60,
      
      highlight_color = 0xFFFFFFFF,
      highlight_opacity = 0.06,
      highlight_thickness = 1.0,
    },
    
    rounding = 12,
  },
}

local current_config = nil

function M.get()
  if not current_config then
    current_config = {}
    for k, v in pairs(default_config) do
      if type(v) == "table" then
        current_config[k] = {}
        for k2, v2 in pairs(v) do
          if type(v2) == "table" then
            current_config[k][k2] = {}
            for k3, v3 in pairs(v2) do
              current_config[k][k2][k3] = v3
            end
          else
            current_config[k][k2] = v2
          end
        end
      else
        current_config[k] = v
      end
    end
  end
  return current_config
end

function M.override(overrides)
  local config = M.get()
  local new_config = {}
  
  for k, v in pairs(config) do
    if type(v) == "table" then
      new_config[k] = {}
      for k2, v2 in pairs(v) do
        if type(v2) == "table" then
          new_config[k][k2] = {}
          for k3, v3 in pairs(v2) do
            new_config[k][k2][k3] = v3
          end
        else
          new_config[k][k2] = v2
        end
      end
    else
      new_config[k] = v
    end
  end
  
  if overrides then
    for k, v in pairs(overrides) do
      if type(v) == "table" and new_config[k] then
        for k2, v2 in pairs(v) do
          if type(v2) == "table" and new_config[k][k2] then
            for k3, v3 in pairs(v2) do
              new_config[k][k2][k3] = v3
            end
          else
            new_config[k][k2] = v2
          end
        end
      else
        new_config[k] = v
      end
    end
  end
  
  return new_config
end

function M.reset()
  current_config = nil
end

return M