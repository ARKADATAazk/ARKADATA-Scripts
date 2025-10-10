-- Region_Playlist/app/config.lua
-- Visual configuration and constants

local M = {}

M.GRID = {
  ENABLED = true,
  PRIMARY_SPACING = 50,
  PRIMARY_COLOR = 0x14141490,
  PRIMARY_THICKNESS = 1.5,
  SECONDARY_ENABLED = true,
  SECONDARY_SPACING = 5,
  SECONDARY_COLOR = 0x14141420,
  SECONDARY_THICKNESS = 0.5,
}

M.CONTAINER = {
  BG_COLOR = 0x1A1A1AFF,
  BORDER_COLOR = 0x000000DD,
}

M.TRANSPORT = {
  height = 120,
}

M.LAYOUT_BUTTON = {
  width = 32,
  height = 32,
  bg_color = 0x2A2A2AFF,
  bg_hover = 0x3A3A3AFF,
  bg_active = 0x4A4A4AFF,
  border_color = 0x404040FF,
  border_hover = 0x606060FF,
  icon_color = 0xAAAAAAFF,
  icon_hover = 0xFFFFFFFF,
  rounding = 4,
  animation_speed = 12.0,
}

M.QUANTIZE = {
  default_lookahead = 0.25,
  min_lookahead = 0.1,
  max_lookahead = 1.0,
}

function M.get_region_tiles_config(layout_mode)
  return {
    layout_mode = layout_mode,
    
    container = {
      bg_color = M.CONTAINER.BG_COLOR,
      border_color = M.CONTAINER.BORDER_COLOR,
      border_thickness = 1,
      rounding = 8,
      padding = 8,
      
      background_pattern = {
        enabled = M.GRID.ENABLED,
        
        primary = {
          type = 'grid',
          spacing = M.GRID.PRIMARY_SPACING,
          color = M.GRID.PRIMARY_COLOR,
          line_thickness = M.GRID.PRIMARY_THICKNESS,
        },
        
        secondary = {
          enabled = M.GRID.SECONDARY_ENABLED,
          type = 'grid',
          spacing = M.GRID.SECONDARY_SPACING,
          color = M.GRID.SECONDARY_COLOR,
          line_thickness = M.GRID.SECONDARY_THICKNESS,
        },
      },
      
      header = {
        enabled = true,
        height = 30,
        element_height = 20,
        bg_color = 0x1F1F1FFF,
        border_color = 0x00000066,
        padding_x = 12,
        spacing = 8,
        
        mode = 'search_sort',
        
        mode_toggle = {
          enabled = true,
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
            { value = "playlists", label = "Playlists", icon = "📂" },
          },
        },
        
        tabs = {
          enabled = true,
          plus_button = {
            width = 21,
            bg_color = 0x2A2A2AFF,
            bg_hover_color = 0x3A3A3AFF,
            bg_active_color = 0x4A4A4AFF,
            text_color = 0xAAAAAAFF,
            text_hover_color = 0xFFFFFFFF,
            border_color = 0x404040FF,
            border_hover_color = 0x606060FF,
            rounding = 4,
            icon = "+",
          },
          tab = {
            min_width = 60,
            max_width = 150,
            padding_x = 8,
            spacing = 0,
            bg_color = 0x1C1C1CFF,
            bg_hover_color = 0x282828FF,
            bg_active_color = 0x252525FF,
            text_color = 0x707070FF,
            text_hover_color = 0xCCCCCCFF,
            text_active_color = 0xFFFFFFFF,
            border_color = 0x303030FF,
            border_active_color = 0x404040FF,
            rounding = 0,
            chip_radius = 4,
          },
          context_menu = {
            bg_color = 0x1E1E1EFF,
            border_color = 0x404040FF,
            item_hover_color = 0x3A3A3AFF,
            item_text_color = 0xCCCCCCFF,
            item_text_hover_color = 0xFFFFFFFF,
            rounding = 4,
            padding = 4,
            item_height = 24,
            item_padding_x = 10,
            border_thickness = 1,
          },
          reserved_right_space = 100,
        },
        
        search = {
          enabled = true,
          placeholder = "Search regions...",
          width_ratio = 0.3,
          min_width = 180,
          bg_color = 0x141414FF,
          bg_hover_color = 0x1A1A1AFF,
          bg_active_color = 0x202020FF,
          text_color = 0xCCCCCCFF,
          placeholder_color = 0x666666FF,
          border_color = 0x808080FF,
          border_active_color = 0x41E0A3FF,
          rounding = 4,
          fade_speed = 10.0,
        },
        
        sort_dropdown = {
          enabled = true,
          width = 130,
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
  }
end

return M