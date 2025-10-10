-- ReArkitekt/gui/widgets/tiles_container/config.lua
-- Default configuration for tiles container

local M = {}

M.DEFAULTS = {
  bg_color = 0x1C1C1CFF,
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
    enabled = true,
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
    enabled = true,
    height = 30,
    element_height = 20,
    bg_color = 0x0F0F0FFF,
    border_color = 0x000000DD,
    padding_x = 12,
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
      reserved_right_space = 50,
      plus_button = {
        width = 23,
        rounding = 4,
        icon = "+",
        bg_color = 0x2A2A2AFF,
        bg_hover_color = 0x3A3A3AFF,
        bg_active_color = 0x1A1A1AFF,
        border_color = 0x404040FF,
        border_hover_color = 0x42E896FF,
        text_color = 0xAAAAAAFF,
        text_hover_color = 0xFFFFFFFF,
      },
      tab = {
        min_width = 60,
        max_width = 180,
        padding_x = 5,
        spacing = 6,
        rounding = 4,
        bg_color = 0x2A2A2AFF,
        bg_hover_color = 0x3A3A3AFF,
        bg_active_color = 0x42E89644,
        border_color = 0x404040FF,
        border_active_color = 0x42E896FF,
        text_color = 0xAAAAAAFF,
        text_hover_color = 0xFFFFFFFF,
        text_active_color = 0xFFFFFFFF,
        use_custom_colors = true,
        fill_desaturation = 0.4,
        fill_brightness = 0.50,
        fill_alpha = 0xDD,
        border_saturation = 0.7,
        border_brightness = 0.75,
        border_alpha = 0xFF,
        text_index_saturation = 0.85,
        text_index_brightness = 0.95,
      },
      track = {
        enabled = true,
        bg_color = 0x1A1A1AFF,
        border_color = 0x0A0A0AFF,
        border_thickness = 1,
        rounding = 6,
        extend_top = 2,
        extend_bottom = 2,
        extend_left = 2,
        extend_right = 2,
        include_plus_button = true,
      },
      context_menu = {
        bg_color = 0x1E1E1EFF,
        hover_color = 0x2E2E2EFF,
        text_color = 0xCCCCCCFF,
        separator_color = 0x404040FF,
        padding = 8,
        item_height = 24,
      },
      drag_config = {
        tile = {
          width = 60,
          rounding = 4,
          stroke_thickness = 1.5,
          global_opacity = 0.85,
        },
        stack = {
          max_visible = 1,
        },
        shadow = {
          enabled = true,
          layers = 3,
          base_color = 0x00000066,
          offset = 3,
          blur_spread = 1.5,
        },
      },
      drop_config = {
        line_width = 2,
        glow_width = 10,
        pulse_speed = 3.0,
        line = {
          color = 0x42E896FF,
          glow_color = 0x42E89644,
        },
        caps = {
          width = 8,
          height = 3,
          rounding = 1,
          glow_size = 4,
          color = 0x42E896FF,
          glow_color = 0x42E89644,
        },
      },
    },
  },
}

return M