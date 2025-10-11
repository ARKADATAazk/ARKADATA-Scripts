-- ReArkitekt/gui/widgets/region_tiles/config.lua
-- Configuration defaults for region tiles coordinator

local M = {}

M.DEFAULTS = {
  layout_mode = 'horizontal',
  
  tile_config = {
    border_thickness = 0.5,
    rounding = 6,
  },
  
  container = {
    bg_color = 0x0F0F0FFF,
    border_color = 0x000000DD,
    border_thickness = 1,
    rounding = 8,
    padding = 8,
    
    scroll = {
      flags = 0,
      custom_scrollbar = false,
      bg_color = 0x00000000,
    },
    
    anti_jitter = {
      enabled = true,
      track_scrollbar = true,
      height_threshold = 5,
    },
    
    background_pattern = {
      enabled = false,
      
      primary = {
        type = 'grid',
        spacing = 100,
        color = 0x40404060,
        dot_size = 2.5,
        line_thickness = 1.5,
      },
      
      secondary = {
        enabled = true,
        type = 'grid',
        spacing = 20,
        color = 0x30303040,
        dot_size = 1.5,
        line_thickness = 0.5,
      },
    },
    
    header = {
      enabled = false,
      height = 36,
      bg_color = 0x252525FF,
      border_color = 0x00000066,
      padding_x = 12,
      padding_y = 8,
      spacing = 8,
      
      mode = 'search_sort',
      
      mode_toggle = {
        enabled = false,
        width = 100,
        height = 20,
        bg_color = 0x252525FF,
        bg_hover_color = 0x303030FF,
        bg_active_color = 0x3A3A3AFF,
        text_color = 0xCCCCCCFF,
        text_hover_color = 0xFFFFFFFF,
        border_color = 0x353535FF,
        border_hover_color = 0x454545FF,
        rounding = 4,
        padding_x = 10,
        padding_y = 6,
        
        options = {
          { value = "regions", label = "Regions", icon = "🎵" },
          { value = "playlists", label = "Playlists", icon = "📋" },
        },
      },
      
      tabs = {
        enabled = true,
        plus_button = {
          width = 28,
          height = 24,
          bg_color = 0x252525FF,
          bg_hover_color = 0x303030FF,
          bg_active_color = 0x3A3A3AFF,
          text_color = 0x999999FF,
          text_hover_color = 0xFFFFFFFF,
          border_color = 0x353535FF,
          border_hover_color = 0x454545FF,
          rounding = 3,
          icon = "+",
        },
        tab = {
          min_width = 80,
          max_width = 150,
          height = 24,
          padding_x = 12,
          spacing = 4,
          bg_color = 0x1A1A1AFF,
          bg_hover_color = 0x252525FF,
          bg_active_color = 0x2A2A2AFF,
          text_color = 0xBBBBBBFF,
          text_hover_color = 0xFFFFFFFF,
          text_active_color = 0xFFFFFFFF,
          border_color = 0x353535FF,
          border_active_color = 0x41E0A3FF,
          rounding = 3,
          close_button = {
            enabled = true,
            size = 14,
            padding = 2,
            color = 0x666666FF,
            hover_color = 0xE84A4AFF,
          },
        },
        reserved_right_space = 100,
      },
      
      search = {
        enabled = true,
        placeholder = "Search...",
        width_ratio = 0.5,
        min_width = 150,
        bg_color = 0x1A1A1AFF,
        bg_hover_color = 0x202020FF,
        bg_active_color = 0x242424FF,
        text_color = 0xCCCCCCFF,
        placeholder_color = 0x666666FF,
        border_color = 0x404040FF,
        border_active_color = 0x5A5A5AFF,
        rounding = 4,
        fade_speed = 8.0,
      },
      
      sort_dropdown = {
        enabled = true,
        width = 120,
        height = 26,
        tooltip = "Sorting",
        bg_color = 0x252525FF,
        bg_hover_color = 0x303030FF,
        bg_active_color = 0x3A3A3AFF,
        text_color = 0xCCCCCCFF,
        text_hover_color = 0xFFFFFFFF,
        border_color = 0x353535FF,
        border_hover_color = 0x454545FF,
        rounding = 4,
        padding_x = 10,
        padding_y = 6,
        arrow_size = 4,
        arrow_color = 0x999999FF,
        arrow_hover_color = 0xEEEEEEFF,
        
        options = {
          { value = nil, label = "No Sort" },
          { value = "color", label = "Color" },
          { value = "index", label = "Index" },
          { value = "alpha", label = "Alphabetical" },
          { value = "length", label = "Length" },
        },
      },
    },
  },
  
  responsive_config = {
    enabled = true,
    min_tile_height = 20,
    base_tile_height_active = 72,
    base_tile_height_pool = 72,
    scrollbar_buffer = 24,
    height_hysteresis = 12,
    stable_frames_required = 2,
    round_to_multiple = 2,
    gap_scaling = {
      enabled = true,
      min_gap = 2,
      max_gap = 12,
    },
  },
  
  hover_config = {
    animation_speed_hover = 12.0,
    hover_brightness_factor = 1.5,
    hover_border_lerp = 0.5,
    base_fill_desaturation = 0.4,
    base_fill_brightness = 0.4,
    base_fill_alpha = 0x66,
  },
  
  dim_config = {
    fill_color = 0x00000088,
    stroke_color = 0xFFFFFF33,
    stroke_thickness = 1.5,
    rounding = 6,
  },
  
  drop_config = {
    move_mode = {
      line = { width = 2, color = 0x42E896FF, glow_width = 12, glow_color = 0x42E89633 },
      caps = { width = 8, height = 3, color = 0x42E896FF, rounding = 0, glow_size = 3, glow_color = 0x42E89644 },
    },
    copy_mode = {
      line = { width = 2, color = 0x9C87E8FF, glow_width = 12, glow_color = 0x9C87E833 },
      caps = { width = 8, height = 3, color = 0x9C87E8FF, rounding = 0, glow_size = 3, glow_color = 0x9C87E844 },
    },
    pulse_speed = 2.5,
  },
  
  ghost_config = {
    tile = {
      width = 60,
      height = 40,
      base_fill = 0x1A1A1AFF,
      base_stroke = 0x42E896FF,
      stroke_thickness = 1.5,
      rounding = 4,
      global_opacity = 0.70,
    },
    stack = {
      max_visible = 3,
      offset_x = 3,
      offset_y = 3,
      scale_factor = 0.94,
      opacity_falloff = 0.70,
    },
    badge = {
      bg = 0x1A1A1AEE,
      text = 0xFFFFFFFF,
      border_color = 0x00000099,
      border_thickness = 1,
      rounding = 6,
      padding_x = 6,
      padding_y = 3,
      offset_x = 35,
      offset_y = -35,
      min_width = 20,
      min_height = 18,
      shadow = {
        enabled = true,
        color = 0x00000099,
        offset = 2,
      },
    },
    copy_mode = {
      stroke_color = 0x9C87E8FF,
      glow_color = 0x9C87E833,
      badge_accent = 0x9C87E8FF,
      indicator_text = "+",
      indicator_color = 0x9C87E8FF,
    },
    move_mode = {
      stroke_color = 0x42E896FF,
      glow_color = 0x42E89633,
      badge_accent = 0x42E896FF,
    },
    delete_mode = {
      stroke_color = 0xE84A4AFF,
      glow_color = 0xE84A4A33,
      badge_accent = 0xE84A4AFF,
      indicator_text = "-",
      indicator_color = 0xE84A4AFF,
    },
  },
  
  wheel_config = {
    step = 1,
  },
}

function M.merge_config(defaults, custom)
  if not custom then return defaults end
  local result = {}
  for k, v in pairs(defaults) do
    if custom[k] ~= nil then
      if type(v) == "table" and type(custom[k]) == "table" then
        result[k] = M.merge_config(v, custom[k])
      else
        result[k] = custom[k]
      end
    else
      result[k] = v
    end
  end
  return result
end

return M