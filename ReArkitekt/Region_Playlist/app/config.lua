-- Region_Playlist/app/config.lua
-- Structural config + semantic colors (widget chrome comes from defaults)

local M = {}

-- Animation speeds
M.ANIMATION = {
  HOVER_SPEED = 12.0,
  FADE_SPEED = 8.0,
}

-- Semantic operation colors (move/copy/delete visual feedback)
M.ACCENT = {
  GREEN = 0x42E896FF,   -- Move operation
  PURPLE = 0x9C87E8FF,  -- Copy operation
  RED = 0xE84A4AFF,     -- Delete operation
}

-- Dimmed tile appearance
M.DIM = {
  FILL = 0x00000088,
  STROKE = 0xFFFFFF33,
}

-- Transport dimensions
M.TRANSPORT = {
  height = 120,
  padding = 12,
  spacing = 12,
}

-- Quantize settings
M.QUANTIZE = {
  default_lookahead = 0.30,
  min_lookahead = 0.20,
  max_lookahead = 3.0,
  
  grid_options = {
    { label = "Measure", value = "measure" },
    { label = "1 Bar (4/4)", value = "4.0" },
    { label = "1/2 Note", value = "2.0" },
    { label = "1/4 Note", value = "1.0" },
    { label = "1/8 Note", value = "0.5" },
    { label = "1/16 Note", value = "0.25" },
    { label = "1/32 Note", value = "0.125" },
    { label = "1/64 Note", value = "0.0625" },
  },
}

-- Layout button (custom drawn in gui.lua)
M.LAYOUT_BUTTON = {
  width = 32,
  height = 32,
  rounding = 4,
  bg_color = 0x2A2A2AFF,
  bg_hover = 0x3A3A3AFF,
  bg_active = 0x4A4A4AFF,
  border_color = 0x404040FF,
  border_hover = 0x606060FF,
  icon_color = 0xAAAAAAFF,
  icon_hover = 0xFFFFFFFF,
  animation_speed = 12.0,
}

-- Separator dimensions
M.SEPARATOR = {
  horizontal = {
    default_position = 180,
    min_active_height = 100,
    min_pool_height = 100,
    gap = 8,
    thickness = 6,
  },
  vertical = {
    default_position = 280,
    min_active_width = 200,
    min_pool_width = 200,
    gap = 8,
    thickness = 6,
  },
}

-- Active container: tabs only
function M.get_active_container_config(callbacks)
  return {
    header = {
      enabled = true,
      height = 23,
      elements = {
        {
          id = "tabs",
          type = "tab_strip",
          flex = 1,
          spacing_before = 0,
          config = {
            spacing = 0,
            min_width = 60,
            max_width = 150,
            padding_x = 8,
            chip_radius = 4,
            
            on_tab_create = callbacks.on_tab_create,
            on_tab_change = callbacks.on_tab_change,
            on_tab_delete = callbacks.on_tab_delete,
            on_tab_reorder = callbacks.on_tab_reorder,
            on_overflow_clicked = callbacks.on_overflow_clicked,
          },
        },
      },
    },
  }
end

-- Pool container: mode toggle, search, sort
function M.get_pool_container_config(callbacks)
  return {
    header = {
      enabled = true,
      height = 30,
      elements = {
        {
          id = "mode_toggle",
          type = "button",
          width = 100,
          spacing_before = 0,
          config = {
            label = "Regions",
            on_click = callbacks.on_mode_toggle,
          },
        },
        {
          id = "spacer1",
          type = "separator",
          flex = 1,
          spacing_before = 0,
          config = { show_line = false },
        },
        {
          id = "search",
          type = "search_field",
          width = 200,
          spacing_before = 0,
          config = {
            placeholder = "Search...",
            on_change = callbacks.on_search_changed,
          },
        },
        {
          id = "sort",
          type = "dropdown_field",
          width = 120,
          spacing_before = 0,
          config = {
            tooltip = "Sort by",
            tooltip_delay = 0.5,
            options = {
              { value = nil, label = "No Sort" },
              { value = "color", label = "Color" },
              { value = "index", label = "Index" },
              { value = "alpha", label = "Alphabetical" },
              { value = "length", label = "Length" },
            },
            enable_mousewheel = true,
            on_change = callbacks.on_sort_changed,
            on_direction_change = callbacks.on_sort_direction_changed,
          },
        },
      },
    },
  }
end

-- Region tiles structural config
function M.get_region_tiles_config(layout_mode)
  return {
    layout_mode = layout_mode or 'horizontal',
    
    tile_config = {
      border_thickness = 0.5,
      rounding = 6,
    },
    
    container = {
      border_thickness = 1,
      rounding = 8,
      padding = 8,
      
      scroll = {
        flags = 0,
        custom_scrollbar = false,
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
          spacing = 50,
          line_thickness = 1.5,
        },
        secondary = {
          enabled = true,
          type = 'grid',
          spacing = 5,
          line_thickness = 0.5,
        },
      },
      
      header = {
        enabled = false,
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
      animation_speed_hover = M.ANIMATION.HOVER_SPEED,
      hover_brightness_factor = 1.5,
      hover_border_lerp = 0.5,
      base_fill_desaturation = 0.4,
      base_fill_brightness = 0.4,
      base_fill_alpha = 0x66,
    },
    
    dim_config = {
      fill_color = M.DIM.FILL,
      stroke_color = M.DIM.STROKE,
      stroke_thickness = 1.5,
      rounding = 6,
    },
    
    drop_config = {
      move_mode = {
        line = { 
          width = 2, 
          color = M.ACCENT.GREEN,
          glow_width = 12, 
          glow_color = 0x42E89633 
        },
        caps = { 
          width = 8, 
          height = 3, 
          color = M.ACCENT.GREEN,
          rounding = 0, 
          glow_size = 3, 
          glow_color = 0x42E89644 
        },
      },
      copy_mode = {
        line = { 
          width = 2, 
          color = M.ACCENT.PURPLE,
          glow_width = 12, 
          glow_color = 0x9C87E833 
        },
        caps = { 
          width = 8, 
          height = 3, 
          color = M.ACCENT.PURPLE,
          rounding = 0, 
          glow_size = 3, 
          glow_color = 0x9C87E844 
        },
      },
      pulse_speed = 2.5,
    },
    
    ghost_config = {
      tile = {
        width = 60,
        height = 40,
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
          offset = 2,
        },
      },
      copy_mode = {
        stroke_color = M.ACCENT.PURPLE,
        glow_color = 0x9C87E833,
        badge_accent = M.ACCENT.PURPLE,
        indicator_text = "+",
        indicator_color = M.ACCENT.PURPLE,
      },
      move_mode = {
        stroke_color = M.ACCENT.GREEN,
        glow_color = 0x42E89633,
        badge_accent = M.ACCENT.GREEN,
      },
      delete_mode = {
        stroke_color = M.ACCENT.RED,
        glow_color = 0xE84A4A33,
        badge_accent = M.ACCENT.RED,
        indicator_text = "-",
        indicator_color = M.ACCENT.RED,
      },
    },
    
    wheel_config = {
      step = 1,
    },
  }
end

return M