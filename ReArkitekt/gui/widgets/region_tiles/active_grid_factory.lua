-- ReArkitekt/gui/widgets/region_tiles/active_grid_factory.lua
-- Factory for creating active grid instances with standardized configuration
-- Extracted from active_grid.lua to separate creation from coordination logic

local Grid = require('ReArkitekt.gui.widgets.grid.core')
local ActiveTile = require('ReArkitekt.gui.widgets.region_tiles.renderers.active')

local M = {}

local function handle_unified_delete(rt, item_keys)
  if not item_keys or #item_keys == 0 then return end
  
  -- Mark items for destroy animation
  if rt.active_grid then
    rt.active_grid:mark_destroyed(item_keys)
  end
  
  -- Clear selection for deleted items
  if rt.active_grid and rt.active_grid.selection then
    for _, key in ipairs(item_keys) do
      rt.active_grid.selection.selected[key] = nil
    end
    if rt.active_grid.behaviors and rt.active_grid.behaviors.on_select then
      rt.active_grid.behaviors.on_select(rt.active_grid.selection:selected_keys())
    end
  end
  
  -- Call the application's delete handler
  if rt.on_active_delete then
    rt.on_active_delete(item_keys)
  end
end

local function create_behaviors(rt)
  return {
    drag_start = function(item_keys)
      -- GridBridge handles drag start via its registration callbacks
      -- No need to manually track drag state here
    end,
    
    right_click = function(key, selected_keys)
      if not rt.on_active_toggle_enabled then return end
      
      if #selected_keys > 1 then
        local playlist_items = rt.active_grid.get_items()
        local item_map = {}
        for _, item in ipairs(playlist_items) do
          item_map[item.key] = item
        end
        
        local clicked_item = item_map[key]
        if clicked_item then
          local new_state = not (clicked_item.enabled ~= false)
          for _, sel_key in ipairs(selected_keys) do
            rt.on_active_toggle_enabled(sel_key, new_state)
          end
        end
      else
        local playlist_items = rt.active_grid.get_items()
        for _, item in ipairs(playlist_items) do
          if item.key == key then
            local new_state = not (item.enabled ~= false)
            rt.on_active_toggle_enabled(key, new_state)
            break
          end
        end
      end
    end,
    
    delete = function(item_keys)
      handle_unified_delete(rt, item_keys)
    end,
    
    alt_click = function(item_keys)
      handle_unified_delete(rt, item_keys)
    end,
    
    play = function(selected_keys)
      if not rt.playback_manager or #selected_keys == 0 then return end
      
      local first_key = selected_keys[1]
      rt.playback_manager:toggle(first_key)
    end,
    
    reorder = function(new_order)
      if not rt.active_grid or not rt.active_grid.drag then return end
      
      local is_copy_mode = false
      if rt.bridge then
        is_copy_mode = rt.bridge:compute_copy_mode('active')
      end
      
      if is_copy_mode and rt.on_active_copy then
        local playlist_items = rt.active_grid.get_items()
        local items_by_key = {}
        for _, item in ipairs(playlist_items) do
          items_by_key[item.key] = item
        end
        
        local dragged_ids = rt.active_grid.drag:get_dragged_ids()
        local dragged_items = {}
        for _, key in ipairs(dragged_ids) do
          if items_by_key[key] then
            dragged_items[#dragged_items + 1] = items_by_key[key]
          end
        end
        
        if #dragged_items > 0 then
          rt.on_active_copy(dragged_items, rt.active_grid.drag:get_target_index())
        end
      elseif rt.on_active_reorder then
        local playlist_items = rt.active_grid.get_items()
        local items_by_key = {}
        for _, item in ipairs(playlist_items) do
          items_by_key[item.key] = item
        end
        
        local new_items = {}
        for _, key in ipairs(new_order) do
          if items_by_key[key] then
            new_items[#new_items + 1] = items_by_key[key]
          end
        end
        
        rt.on_active_reorder(new_items)
      end
    end,
    
    on_select = function(selected_keys)
    end,
  }
end

local function create_external_drop_handler(rt)
  return function(insert_index)
    -- When using GridBridge, this is handled by the bridge's on_cross_grid_drop
    -- This handler is only for fallback mode without bridge
  end
end

local function create_external_drag_check(rt)
  return function()
    if rt.bridge then
      return rt.bridge:is_external_drag_for('active')
    end
    return false
  end
end

local function create_copy_mode_check(rt)
  return function()
    if rt.bridge then
      return rt.bridge:compute_copy_mode('active')
    end
    return false
  end
end

local function create_render_tile(rt, tile_config)
  return function(ctx, rect, item, state)
    local tile_height = rect[4] - rect[2]
    ActiveTile.render(ctx, rect, item, state, rt.get_region_by_rid, rt.active_animator, 
                    rt.on_repeat_cycle, rt.hover_config, tile_height, tile_config.border_thickness, rt.playback_manager)
  end
end

function M.create(rt, config)
  config = config or {}
  
  local base_tile_height = config.base_tile_height_active or 72
  local tile_config = config.tile_config or { border_thickness = 0.5, rounding = 6 }
  local dim_config = config.dim_config or {
    fill_color = 0x00000088,
    stroke_color = 0xFFFFFF33,
    stroke_thickness = 1.5,
    rounding = 6,
  }
  local drop_config = config.drop_config or {}
  local ghost_config = config.ghost_config or {}
  
  return Grid.new({
    id = "active_grid",
    gap = ActiveTile.CONFIG.gap,
    min_col_w = function() return ActiveTile.CONFIG.tile_width end,
    fixed_tile_h = base_tile_height,
    get_items = function() return {} end,
    key = function(item) return item.key end,
    
    external_drag_check = create_external_drag_check(rt),
    is_copy_mode_check = create_copy_mode_check(rt),
    
    behaviors = create_behaviors(rt),
    
    accept_external_drops = true,
    on_external_drop = create_external_drop_handler(rt),
    
    on_destroy_complete = function(key)
      if rt.on_destroy_complete then
        rt.on_destroy_complete(key)
      end
    end,
    
    on_click_empty = function(key)
      if rt.on_repeat_cycle then
        rt.on_repeat_cycle(key)
      end
    end,

    render_tile = create_render_tile(rt, tile_config),
    
    config = {
      spawn = ActiveTile.CONFIG.spawn,
      destroy = { enabled = true },
      ghost = ghost_config,
      dim = dim_config,
      drop = drop_config,
      drag = { threshold = 6 },
    },
  })
end

return M