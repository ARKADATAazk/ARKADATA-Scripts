-- ReArkitekt/gui/widgets/panel/config.lua
-- Default configuration for panel with integrated header design

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
    enabled = false,
    height = 30,
    bg_color = 0x0F0F0FFF,
    border_color = 0x000000DD,
    rounding = 8,
    
    padding = {
      left = 0,
      right = 0,
      top = 0,
      bottom = 0,
    },
    
    elements = {},
  },
}

M.TAB_MODE_DEFAULTS = {
  header = {
    enabled = true,
    height = 20,
    bg_color = 0x0F0F0FFF, 
    border_color = 0x000000DD,
    rounding = 8,
    
    padding = {
      left = 0,
      right = 0,
      top = 0,
      bottom = 0,
    },
    
    elements = {
      {
        id = "tabs",
        type = "tab_strip",
        flex = 1,
        spacing_before = 0,
        config = {
          spacing = 0,
          min_width = 60,
          max_width = 180,
          padding_x = 5,
          
          border_outer_color = 0x000000DD,
          border_inner_color = 0x404040FF,
          border_hover_color = 0x505050FF,
          border_active_color = 0X7B7B7BFF,
          
          bg_color = 0x252525FF,
          bg_hover_color = 0x2A2A2AFF,
          bg_active_color = 0x303030FF,
          
          text_color = 0xAAAAAAFF,
          text_hover_color = 0xFFFFFFFF,
          text_active_color = 0xFFFFFFFF,
          
          chip_radius = 4,
          
          plus_button = {
            width = 23,
            bg_color = 0x252525FF,
            bg_hover_color = 0x2A2A2AFF,
            bg_active_color = 0x1A1A1AFF,
            border_inner_color = 0x404040FF,
            border_hover_color = 0x505050FF,
            text_color = 0xAAAAAAFF,
            text_hover_color = 0xFFFFFFFF,
          },
          
          overflow_button = {
            min_width = 21,
            padding_x = 8,
            bg_color = 0x252525FF,
            bg_hover_color = 0x2A2A2AFF,
            bg_active_color = 0x1A1A1AFF,
            border_inner_color = 0x404040FF,
            border_hover_color = 0x505050FF,
            text_color = 0x707070FF,
            text_hover_color = 0xCCCCCCFF,
          },
          
          track = {
            enabled = false,
          },
          
          context_menu = {
            bg_color = 0x1E1E1EFF,
            hover_color = 0x2E2E2EFF,
            text_color = 0xCCCCCCFF,
            separator_color = 0x404040FF,
            padding = 8,
            item_height = 24,
          },
          
          on_tab_create = nil,
          on_tab_change = nil,
          on_tab_delete = nil,
          on_tab_reorder = nil,
          on_overflow_clicked = nil,
        },
      },
    },
  },
}

M.MIXED_EXAMPLE = {
  header = {
    enabled = true,
    height = 30,
    bg_color = 0x0F0F0FFF,
    border_color = 0x000000DD,
    rounding = 8,
    
    padding = {
      left = 0,
      right = 0,
      top = 0,
      bottom = 0,
    },
    
    elements = {
      {
        id = "add_button",
        type = "button",
        spacing_before = 0,
        config = {
          id = "add",
          width = 30,
          icon = "+",
          tooltip = "Add Item",
          border_outer_color = 0x000000DD,
          border_inner_color = 0x404040FF,
          border_hover_color = 0x505050FF,
          bg_color = 0x252525FF,
          bg_hover_color = 0x2A2A2AFF,
          bg_active_color = 0x1A1A1AFF,
          text_color = 0xAAAAAAFF,
          text_hover_color = 0xFFFFFFFF,
        },
      },
      {
        id = "sep1",
        type = "separator",
        width = 12,
        spacing_before = 0,
        config = {
          show_line = true,
          line_color = 0x30303080,
          line_thickness = 1,
          line_height_ratio = 0.6,
        },
      },
      {
        id = "search",
        type = "search_field",
        width = 200,
        spacing_before = 0,
        config = {
          placeholder = "Search...",
        },
      },
      {
        id = "spacer",
        type = "separator",
        flex = 1,
        spacing_before = 0,
        config = {
          show_line = false,
        },
      },
      {
        id = "sort",
        type = "dropdown_field",
        width = 120,
        spacing_before = 0,
        config = {
          options = {
            { value = "", label = "No Sort" },
            { value = "name", label = "Name" },
          },
        },
      },
    },
  },
}

return M