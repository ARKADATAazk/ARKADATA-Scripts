-- ReArkitekt/gui/widgets/region_tiles/active_grid.lua
-- Active grid configuration for region tiles

local Grid = require('ReArkitekt.gui.widgets.grid.core')
local ActiveTile = require('ReArkitekt.gui.widgets.region_tiles.renderers.active')

local M = {}

function M.create_active_grid(rt, config)
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
    
    external_drag_check = function()
      return rt.drag_state.source == 'pool'
    end,
    
    is_copy_mode_check = function()
      return rt.drag_state.is_copy_mode
    end,
    
    behaviors = {
      drag_start = function(item_keys)
        rt.drag_state.source = 'active'
        rt.drag_state.data = item_keys
        rt.drag_state.ctrl_held = false
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
        if rt.on_active_delete then
          rt.on_active_delete(item_keys)
        end
      end,
      
      reorder = function(new_order)
        if rt.drag_state.ctrl_held and rt.on_active_copy then
          local playlist_items = rt.active_grid.get_items()
          local items_by_key = {}
          for _, item in ipairs(playlist_items) do
            items_by_key[item.key] = item
          end
          
          local dragged_items = {}
          for _, key in ipairs(rt.drag_state.data or {}) do
            if items_by_key[key] then
              dragged_items[#dragged_items + 1] = items_by_key[key]
            end
          end
          
          rt.on_active_copy(dragged_items, rt.active_grid.drag.target_index)
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
    },
    
    accept_external_drops = true,
    
    on_external_drop = function(insert_index)
      if rt.drag_state.source == 'pool' and rt.on_pool_to_active then
        local rids = rt.drag_state.data
        local spawned_keys = {}
        
        if type(rids) == 'table' then
          for _, rid in ipairs(rids) do
            local new_key = rt.on_pool_to_active(rid, insert_index)
            if new_key then
              spawned_keys[#spawned_keys + 1] = new_key
            end
            insert_index = insert_index + 1
          end
        else
          local new_key = rt.on_pool_to_active(rids, insert_index)
          if new_key then
            spawned_keys[#spawned_keys + 1] = new_key
          end
        end
        
        if #spawned_keys > 0 then
          rt.pool_grid.selection:clear()
          rt.active_grid.selection:clear()
          
          for _, key in ipairs(spawned_keys) do
            local rect = rt.active_grid.rect_track:get(key)
            if rect then
              rt.active_grid.spawn_anim:spawn(key, rect)
            end
            
            rt.active_grid.selection.selected[key] = true
          end
          
          rt.active_grid.selection.last_clicked = spawned_keys[#spawned_keys]
          
          if rt.active_grid.behaviors and rt.active_grid.behaviors.on_select then
            rt.active_grid.behaviors.on_select(rt.active_grid.selection:selected_keys())
          end
        end
      end
      rt.drag_state.source = nil
      rt.drag_state.data = nil
      rt.drag_state.ctrl_held = false
      rt.drag_state.is_copy_mode = false
    end,
    
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

    render_tile = function(ctx, rect, item, state)
      local tile_height = rect[4] - rect[2]
      ActiveTile.render(ctx, rect, item, state, rt.get_region_by_rid, rt.active_animator, 
                      rt.on_repeat_cycle, rt.hover_config, tile_height, tile_config.border_thickness)
    end,
    
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