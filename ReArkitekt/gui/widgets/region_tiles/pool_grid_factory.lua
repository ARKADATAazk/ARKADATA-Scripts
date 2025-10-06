-- ReArkitekt/gui/widgets/region_tiles/pool_grid_factory.lua
-- Factory for creating pool grid instances with standardized configuration
-- Extracted from pool_grid.lua to separate creation from coordination logic

local Grid = require('ReArkitekt.gui.widgets.grid.core')
local PoolTile = require('ReArkitekt.gui.widgets.region_tiles.renderers.pool')

local M = {}

local function create_behaviors(rt)
  return {
    drag_start = function(item_keys)
      if rt.bridge then
        return
      end
      
      local rids = {}
      for _, key in ipairs(item_keys) do
        local rid = tonumber(key:match("pool_(%d+)"))
        if rid then
          rids[#rids + 1] = rid
        end
      end
      rt.drag_state.source = 'pool'
      rt.drag_state.data = rids
      rt.drag_state.ctrl_held = false
    end,
    
    reorder = function(new_order)
      if not rt.allow_pool_reorder or not rt.on_pool_reorder then return end
      
      local rids = {}
      for _, key in ipairs(new_order) do
        local rid = tonumber(key:match("pool_(%d+)"))
        if rid then
          rids[#rids + 1] = rid
        end
      end
      
      rt.on_pool_reorder(rids)
    end,
    
    double_click = function(key)
      local rid = tonumber(key:match("pool_(%d+)"))
      if rid and rt.on_pool_double_click then
        rt.on_pool_double_click(rid)
      end
    end,
    
    on_select = function(selected_keys)
    end,
  }
end

local function create_external_drag_check(rt)
  return function()
    if rt.bridge then
      return rt.bridge:is_external_drag_for('pool')
    end
    return rt.drag_state.source == 'active'
  end
end

local function create_copy_mode_check(rt)
  return function()
    if rt.bridge then
      return rt.bridge:compute_copy_mode('pool')
    end
    return rt.drag_state.is_copy_mode
  end
end

local function create_render_tile(rt, tile_config)
  return function(ctx, rect, region, state)
    local tile_height = rect[4] - rect[2]
    PoolTile.render(ctx, rect, region, state, rt.pool_animator, rt.hover_config, 
                    tile_height, tile_config.border_thickness)
  end
end

function M.create(rt, config)
  config = config or {}
  
  local base_tile_height = config.base_tile_height_pool or 72
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
    id = "pool_grid",
    gap = PoolTile.CONFIG.gap,
    min_col_w = function() return PoolTile.CONFIG.tile_width end,
    fixed_tile_h = base_tile_height,
    get_items = function() return {} end,
    key = function(region) return "pool_" .. tostring(region.rid) end,
    
    external_drag_check = create_external_drag_check(rt),
    is_copy_mode_check = create_copy_mode_check(rt),
    
    behaviors = create_behaviors(rt),
    
    accept_external_drops = false,
    
    render_tile = create_render_tile(rt, tile_config),
    
    config = {
      spawn = PoolTile.CONFIG.spawn,
      ghost = ghost_config,
      dim = dim_config,
      drop = drop_config,
      drag = { threshold = 6 },
    },
  })
end

return M