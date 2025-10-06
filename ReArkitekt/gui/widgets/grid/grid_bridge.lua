-- ReArkitekt/gui/widgets/grid/grid_bridge.lua
-- Coordinates drag-and-drop between multiple grid instances
-- Enables multi-grid workflows without coupling grid implementations

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.10'

local M = {}

local GridBridge = {}
GridBridge.__index = GridBridge

function M.new(config)
  config = config or {}
  
  return setmetatable({
    grids = {},
    active_source_grid = nil,
    drag_payload = nil,
    copy_mode_detector = config.copy_mode_detector,
    delete_mode_detector = config.delete_mode_detector,
    on_cross_grid_drop = config.on_cross_grid_drop,
    on_drag_canceled = config.on_drag_canceled,
  }, GridBridge)
end

function GridBridge:register_grid(id, grid, opts)
  opts = opts or {}
  
  self.grids[id] = {
    instance = grid,
    accepts_drops_from = opts.accepts_drops_from or {},
    provides_drops_to = opts.provides_drops_to or {},
    bounds = nil,
    on_drag_start = opts.on_drag_start,
    on_drop = opts.on_drop,
  }
  
  local bridge = self
  
  grid.external_drag_check = function()
    return bridge:is_external_drag_for(id)
  end
  
  grid.is_copy_mode_check = function()
    return bridge:compute_copy_mode(id)
  end
  
  if grid.behaviors then
    local original_drag_start = grid.behaviors.drag_start
    grid.behaviors.drag_start = function(item_keys)
      bridge:start_drag(id, item_keys)
      if original_drag_start then
        original_drag_start(item_keys)
      end
      if opts.on_drag_start then
        opts.on_drag_start(item_keys)
      end
    end
  end
  
  grid.on_external_drop = function(insert_index)
    bridge:handle_drop(id, insert_index)
  end
end

function GridBridge:unregister_grid(id)
  self.grids[id] = nil
  if self.active_source_grid == id then
    self:clear_drag()
  end
end

function GridBridge:update_bounds(id, x1, y1, x2, y2)
  if self.grids[id] then
    self.grids[id].bounds = {x1, y1, x2, y2}
  end
end

function GridBridge:start_drag(source_id, payload)
  self.active_source_grid = source_id
  self.drag_payload = {
    source = source_id,
    data = payload,
    type = self.grids[source_id] and self.grids[source_id].instance.id or "unknown",
  }
end

function GridBridge:is_external_drag_for(grid_id)
  if not self.active_source_grid then return false end
  return self.active_source_grid ~= grid_id
end

function GridBridge:is_drag_active()
  return self.active_source_grid ~= nil
end

function GridBridge:get_source_grid()
  return self.active_source_grid
end

function GridBridge:get_drag_payload()
  return self.drag_payload
end

function GridBridge:can_accept_drop(source_id, target_id)
  local target = self.grids[target_id]
  if not target then return false end
  
  local accepts_from = target.accepts_drops_from
  if type(accepts_from) == "table" then
    for _, allowed_source in ipairs(accepts_from) do
      if allowed_source == source_id or allowed_source == "*" then
        return true
      end
    end
    return false
  end
  
  return accepts_from == true or accepts_from == "*"
end

function GridBridge:get_hovered_grid(mx, my)
  for id, grid_data in pairs(self.grids) do
    if grid_data.bounds then
      local b = grid_data.bounds
      if mx >= b[1] and mx < b[3] and my >= b[2] and my < b[4] then
        return id
      end
    end
  end
  return nil
end

function GridBridge:is_mouse_over_grid(ctx, grid_id)
  local grid_data = self.grids[grid_id]
  if not grid_data or not grid_data.bounds then return false end
  
  local mx, my = ImGui.GetMousePos(ctx)
  local b = grid_data.bounds
  return mx >= b[1] and mx < b[3] and my >= b[2] and my < b[4]
end

function GridBridge:compute_copy_mode(target_id)
  if not self.active_source_grid or not self.drag_payload then return false end
  
  if self.copy_mode_detector then
    return self.copy_mode_detector(self.active_source_grid, target_id, self.drag_payload)
  end
  
  return false
end

function GridBridge:compute_delete_mode(ctx, target_id)
  if not self.active_source_grid or not self.drag_payload then return false end
  
  if self.delete_mode_detector then
    return self.delete_mode_detector(ctx, self.active_source_grid, target_id, self.drag_payload)
  end
  
  return false
end

function GridBridge:handle_drop(target_id, insert_index)
  if not self.drag_payload or not self.active_source_grid then return end
  
  if not self:can_accept_drop(self.active_source_grid, target_id) then
    self:clear_drag()
    return
  end
  
  local drop_info = {
    source_grid = self.active_source_grid,
    target_grid = target_id,
    payload = self.drag_payload.data,
    insert_index = insert_index,
    is_copy_mode = self:compute_copy_mode(target_id),
  }
  
  local grid_data = self.grids[target_id]
  if grid_data and grid_data.on_drop then
    grid_data.on_drop(drop_info)
  end
  
  if self.on_cross_grid_drop then
    self.on_cross_grid_drop(drop_info)
  end
  
  self:clear_drag()
end

function GridBridge:cancel_drag()
  if self.active_source_grid and self.on_drag_canceled then
    self.on_drag_canceled({
      source_grid = self.active_source_grid,
      payload = self.drag_payload and self.drag_payload.data or nil,
    })
  end
  self:clear_drag()
end

function GridBridge:clear_drag()
  self.active_source_grid = nil
  self.drag_payload = nil
end

function GridBridge:get_drag_count()
  if not self.drag_payload or not self.drag_payload.data then return 0 end
  local data = self.drag_payload.data
  return type(data) == 'table' and #data or 1
end

function GridBridge:clear()
  self.grids = {}
  self:clear_drag()
end

return M