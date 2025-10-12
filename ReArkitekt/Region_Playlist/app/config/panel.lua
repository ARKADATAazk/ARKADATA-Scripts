-- Region_Playlist/app/config/panel.lua
-- Panel container configurations

local Constants = require('Region_Playlist.app.config.constants')

local M = {}

-- Base panel configuration (shared by both containers)
local function get_base_config()
  return {
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
  }
end

-- Active container configuration (with tabs)
function M.get_active_container_config(callbacks)
  callbacks = callbacks or {}
  
  local config = get_base_config()
  
  config.header = {
    enabled = true,
    height = 23,
    bg_color = Constants.COLORS.BG_SECONDARY,
    border_color = Constants.COLORS.BORDER_SECONDARY,
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
          max_width = 150,
          padding_x = 8,
          chip_radius = 4,
          
          -- NEW: 3-layer borders
          border_outer_color = 0x000000DD,
          border_inner_color = 0x404040FF,
          border_hover_color = 0x505050FF,
          border_active_color = 0X626262FF,
          
          -- Colors
          bg_color = 0x252525FF,
          bg_hover_color = 0x2A2A2AFF,
          bg_active_color = 0x303030FF,
          text_color = Constants.COLORS.TEXT_TERTIARY,
          text_hover_color = Constants.COLORS.TEXT_SECONDARY,
          text_active_color = Constants.COLORS.TEXT_PRIMARY,
          
          -- Plus button
          plus_button = {
            width = 23,
            bg_color = 0x252525FF,
            bg_hover_color = 0x2A2A2AFF,
            bg_active_color = 0x1A1A1AFF,
            border_inner_color = 0x404040FF,
            border_hover_color = 0x505050FF,
            text_color = Constants.COLORS.TEXT_TERTIARY,
            text_hover_color = Constants.COLORS.TEXT_SECONDARY,
          },
          
          -- Overflow button
          overflow_button = {
            min_width = 21,
            padding_x = 8,
            bg_color = 0x252525FF,
            bg_hover_color = 0x2A2A2AFF,
            bg_active_color = 0x1A1A1AFF,
            border_inner_color = 0x404040FF,
            border_hover_color = 0x505050FF,
            text_color = Constants.COLORS.TEXT_TERTIARY,
            text_hover_color = Constants.COLORS.TEXT_SECONDARY,
          },
          
          -- Track background - DISABLED
          track = {
            enabled = false,
          },
          
          -- Context menu
          context_menu = {
            bg_color = 0x1E1E1EFF,
            hover_color = 0x2E2E2EFF,
            text_color = Constants.COLORS.TEXT_SECONDARY,
            separator_color = 0x404040FF,
            padding = 8,
            item_height = 24,
          },
          
          -- Callbacks
          on_tab_create = callbacks.on_tab_create,
          on_tab_change = callbacks.on_tab_change,
          on_tab_delete = callbacks.on_tab_delete,
          on_tab_reorder = callbacks.on_tab_reorder,
          on_overflow_clicked = callbacks.on_overflow_clicked,
        },
      },
    },
  }
  
  return config
end

-- Pool container configuration (with search & sort)
function M.get_pool_container_config(callbacks)
  callbacks = callbacks or {}
  
  local config = get_base_config()
  
  config.header = {
    enabled = true,
    height = 30,
    bg_color = Constants.COLORS.BG_SECONDARY,
    border_color = Constants.COLORS.BORDER_SECONDARY,
    rounding = 8,
    
    padding = {
      left = 0,
      right = 0,
      top = 0,
      bottom = 0,
    },
    
    elements = {
      -- Mode toggle button (Regions/Playlists)
      {
        id = "mode_toggle",
        type = "button",
        width = 100,
        spacing_before = 0,
        config = {
          label = "Regions",
          border_outer_color = 0x000000DD,
          border_inner_color = 0x404040FF,
          border_hover_color = 0x505050FF,
          bg_color = 0x252525FF,
          bg_hover_color = 0x2A2A2AFF,
          bg_active_color = 0x3A3A3AFF,
          text_color = Constants.COLORS.TEXT_SECONDARY,
          text_hover_color = Constants.COLORS.TEXT_PRIMARY,
          on_click = callbacks.on_mode_toggle,
        },
      },
      
      -- Flexible spacer
      {
        id = "spacer1",
        type = "separator",
        flex = 1,
        spacing_before = 0,
        config = { show_line = false },
      },
      
      -- Search field
      {
        id = "search",
        type = "search_field",
        width = 200,
        spacing_before = 0,
        config = {
          placeholder = "Search...",
          fade_speed = Constants.ANIMATION.FADE_SPEED,
          border_outer_color = 0x000000DD,
          border_inner_color = 0x404040FF,
          border_active_color = 0x42E89677,
          bg_color = 0x252525FF,
          bg_hover_color = 0x2A2A2AFF,
          bg_active_color = 0x2A2A2AFF,
          text_color = Constants.COLORS.TEXT_SECONDARY,
          on_change = callbacks.on_search_changed,
        },
      },
      
      -- Sort dropdown
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
          border_outer_color = 0x000000DD,
          border_inner_color = 0x404040FF,
          border_hover_color = 0x505050FF,
          bg_color = 0x252525FF,
          bg_hover_color = 0x2A2A2AFF,
          bg_active_color = 0x3A3A3AFF,
          text_color = Constants.COLORS.TEXT_SECONDARY,
          text_hover_color = Constants.COLORS.TEXT_PRIMARY,
          padding_x = 10,
          padding_y = 6,
          arrow_size = 6,
          arrow_color = Constants.COLORS.TEXT_SECONDARY,
          arrow_hover_color = Constants.COLORS.TEXT_PRIMARY,
          enable_mousewheel = true,
          popup = {
            bg_color = 0x1E1E1EFF,
            hover_color = 0x2E2E2EFF,
            text_color = Constants.COLORS.TEXT_SECONDARY,
            separator_color = 0x404040FF,
            padding = 8,
            item_height = 24,
          },
          on_change = callbacks.on_sort_changed,
          on_direction_change = callbacks.on_sort_direction_changed,
        },
      },
    },
  }
  
  return config
end

return M