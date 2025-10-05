-- ReArkitekt/gui/widgets/package_tiles/grid.lua
-- Package grid main logic - entry point for package management UI

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local Grid = require('ReArkitekt.gui.widgets.grid.core')
local Motion = require('ReArkitekt.gui.fx.motion')
local TileAnim = require('ReArkitekt.gui.fx.tile_motion')
local Renderer = require('ReArkitekt.gui.widgets.package_tiles.renderer')
local Micromanage = require('ReArkitekt.gui.widgets.package_tiles.micromanage')

local M = {}

local function get_tile_base_color(pkg, P)
  local is_active = pkg.active[P.id] == true
  return is_active and Renderer.CONFIG.colors.bg.active or Renderer.CONFIG.colors.bg.inactive
end

local function draw_package_tile(ctx, pkg, theme, P, rect, state, settings, custom_state)
  local dl = ImGui.GetWindowDrawList(ctx)
  local x1, y1, x2, y2 = rect[1], rect[2], rect[3], rect[4]
  local tile_w, tile_h = x2 - x1, y2 - y1
  
  local is_active = pkg.active[P.id] == true
  local is_selected = state.selected
  local is_hovered = state.hover
  
  custom_state.animator:track(P.id, 'hover', is_hovered and 1.0 or 0.0, Renderer.CONFIG.animation.speed_hover)
  custom_state.animator:track(P.id, 'active', is_active and 1.0 or 0.0, Renderer.CONFIG.animation.speed_active)
  
  local hover_factor = custom_state.animator:get(P.id, 'hover')
  local active_factor = custom_state.animator:get(P.id, 'active')
  
  local bg_active = Motion.color_lerp(Renderer.CONFIG.colors.bg.inactive, Renderer.CONFIG.colors.bg.active, active_factor)
  local bg_final = Motion.color_lerp(bg_active, Renderer.CONFIG.colors.bg.hover_tint, hover_factor * Renderer.CONFIG.colors.bg.hover_influence)
  
  local base_color = get_tile_base_color(pkg, P)
  
  Renderer.TileRenderer.background(dl, rect, bg_final, is_selected and 0 or hover_factor)
  Renderer.TileRenderer.border(dl, rect, base_color, is_selected, is_active, is_hovered)
  Renderer.TileRenderer.order_badge(ctx, dl, pkg, P, x1, y1)
  Renderer.TileRenderer.conflicts(ctx, dl, pkg, P, x1, y1, tile_w)
  Renderer.TileRenderer.checkbox(ctx, pkg, P, custom_state.checkbox_rects, x1, y1, tile_w, tile_h)
  Renderer.TileRenderer.mosaic(ctx, dl, theme, P, x1, y1, tile_w)
  Renderer.TileRenderer.footer(ctx, dl, pkg, P, x1, y1, tile_w, tile_h)
end

function M.create(pkg, settings, theme)
  local custom_state = {
    checkbox_rects = {},
    animator = TileAnim.new(Renderer.CONFIG.animation.speed_hover),
  }
  
  local grid = Grid.new({
    id = "pkg_grid",
    gap = 12,
    min_col_w = function() return pkg.tile or 220 end,
    
    get_items = function() return pkg:visible() end,
    key = function(P) return P.id end,
    
    get_exclusion_zones = function(item, rect)
      local cb_rect = custom_state.checkbox_rects[item.id]
      return cb_rect and {cb_rect} or nil
    end,
    
    behaviors = {
      delete = function(selected_keys)
        if #selected_keys == 0 then return end
        for _, id in ipairs(selected_keys) do
          pkg:remove(id)
        end
        if settings then settings:set('pkg_active', pkg.active) end
      end,
      
      toggle = function(selected_keys)
        if #selected_keys == 0 then return end
        local first_key = selected_keys[1]
        local new_status = not pkg.active[first_key]
        for _, id in ipairs(selected_keys) do
          pkg.active[id] = new_status
        end
        if settings then settings:set('pkg_active', pkg.active) end
      end,
      
      select_all = function()
        for _, P in ipairs(pkg:visible()) do
          grid.selection.selected[P.id] = true
        end
      end,
      
      deselect_all = function()
        grid.selection:clear()
      end,
      
      invert_selection = function()
        for _, P in ipairs(pkg:visible()) do
          grid.selection:toggle(P.id)
        end
      end,
      
      right_click = function(key, selected_keys)
        if #selected_keys > 1 then
          local new_status = not pkg.active[key]
          for _, id in ipairs(selected_keys) do
            pkg.active[id] = new_status
          end
        else
          pkg:toggle(key)
        end
        if settings then settings:set('pkg_active', pkg.active) end
      end,
      
      double_click = function(key)
        Micromanage.open(key)
      end,
      
      alt_click = function(keys_to_delete)
        if #keys_to_delete == 0 then return end
        for _, id in ipairs(keys_to_delete) do
          pkg:remove(id)
        end
        grid.selection:clear()
      end,
      
      reorder = function(new_keys)
        pkg.order = new_keys
        if settings then settings:set('pkg_order', pkg.order) end
      end,
      
      on_select = function(selected_keys)
      end,
      
      drag_start = function(drag_ids)
      end,
    },
    
    render_tile = function(ctx, rect, P, state)
      draw_package_tile(ctx, pkg, theme, P, rect, state, settings, custom_state)
    end,
    
    render_overlays = function(ctx, current_rects)
      for id, rect in pairs(custom_state.checkbox_rects) do
        local x1, y1, x2, y2 = rect[1], rect[2], rect[3], rect[4]
        
        ImGui.SetCursorScreenPos(ctx, x1, y1)
        ImGui.PushID(ctx, 'overlay_cb_' .. id)
        ImGui.InvisibleButton(ctx, '##dummy', x2 - x1, y2 - y1)
        
        if ImGui.IsItemClicked(ctx, 0) then
          pkg.active[id] = not pkg.active[id]
          if settings then settings:set('pkg_active', pkg.active) end
        end
        
        if ImGui.IsItemHovered(ctx) then
          ImGui.SetTooltip(ctx, pkg.active[id] and "Disable package" or "Enable package")
        end
        ImGui.PopID(ctx)
      end
    end,
  })
  
  return {
    grid = grid,
    custom_state = custom_state,
    config = Renderer.CONFIG,
    
    draw = function(self, ctx)
      self.custom_state.checkbox_rects = {}
      self.custom_state.animator:update(0.016)
      self.grid:draw(ctx)
    end,
    
    get_selected = function(self) return self.grid.selection:selected_keys() end,
    get_selected_count = function(self) return self.grid.selection:count() end,
    is_selected = function(self, id) return self.grid.selection:is_selected(id) end,
    clear_selection = function(self) self.grid.selection:clear() end,
    select_single = function(self, id) self.grid.selection:single(id) end,
    toggle_selection = function(self, id) self.grid.selection:toggle(id) end,
    select_multiple = function(self, ids)
      self.grid.selection:clear()
      for _, id in ipairs(ids or {}) do
        self.grid.selection.selected[id] = true
      end
    end,
    
    clear = function(self)
      self.grid:clear()
      self.custom_state.checkbox_rects = {}
      self.custom_state.animator:clear()
    end,
  }
end

return M