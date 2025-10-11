-- Region_Playlist/app/config/region_tiles.lua
-- Complete region tiles configuration

local Constants = require('Region_Playlist.app.config.constants')

local M = {}

function M.get_config(layout_mode)
  return {
    layout_mode = layout_mode or 'horizontal',
    
    tile_config = {
      border_thickness = 0.5,
      rounding = 6,
    },
    
    container = {
      bg_color = Constants.COLORS.BG_PRIMARY,
      border_color = Constants.COLORS.BORDER_PRIMARY,
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
        enabled = Constants.GRID.ENABLED,
        
        primary = {
          type = 'grid',
          spacing = Constants.GRID.PRIMARY_SPACING,
          color = Constants.GRID.PRIMARY_COLOR,
          line_thickness = Constants.GRID.PRIMARY_THICKNESS,
        },
        
        secondary = {
          enabled = Constants.GRID.SECONDARY_ENABLED,
          type = 'grid',
          spacing = Constants.GRID.SECONDARY_SPACING,
          color = Constants.GRID.SECONDARY_COLOR,
          line_thickness = Constants.GRID.SECONDARY_THICKNESS,
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
      animation_speed_hover = Constants.ANIMATION.HOVER_SPEED,
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
        line = { 
          width = 2, 
          color = Constants.COLORS.ACCENT_GREEN, 
          glow_width = 12, 
          glow_color = 0x42E89633 
        },
        caps = { 
          width = 8, 
          height = 3, 
          color = Constants.COLORS.ACCENT_GREEN, 
          rounding = 0, 
          glow_size = 3, 
          glow_color = 0x42E89644 
        },
      },
      copy_mode = {
        line = { 
          width = 2, 
          color = Constants.COLORS.ACCENT_PURPLE, 
          glow_width = 12, 
          glow_color = 0x9C87E833 
        },
        caps = { 
          width = 8, 
          height = 3, 
          color = Constants.COLORS.ACCENT_PURPLE, 
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
        base_fill = Constants.COLORS.BG_PRIMARY,
        base_stroke = Constants.COLORS.ACCENT_GREEN,
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
        text = Constants.COLORS.TEXT_PRIMARY,
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
        stroke_color = Constants.COLORS.ACCENT_PURPLE,
        glow_color = 0x9C87E833,
        badge_accent = Constants.COLORS.ACCENT_PURPLE,
        indicator_text = "+",
        indicator_color = Constants.COLORS.ACCENT_PURPLE,
      },
      move_mode = {
        stroke_color = Constants.COLORS.ACCENT_GREEN,
        glow_color = 0x42E89633,
        badge_accent = Constants.COLORS.ACCENT_GREEN,
      },
      delete_mode = {
        stroke_color = Constants.COLORS.ACCENT_RED,
        glow_color = 0xE84A4A33,
        badge_accent = Constants.COLORS.ACCENT_RED,
        indicator_text = "-",
        indicator_color = Constants.COLORS.ACCENT_RED,
      },
    },
    
    wheel_config = {
      step = 1,
    },
  }
end

return M