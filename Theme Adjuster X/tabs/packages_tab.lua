-- tabs/packages_tab.lua
-- Packages tab using ReArkitekt colorblocks widget

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local Lifecycle = require('ReArkitekt.core.lifecycle')
local ColorBlocks = require('ReArkitekt.gui.widgets.colorblocks')
local Draw = require('ReArkitekt.gui.draw')
local Effects = require('ReArkitekt.gui.effects')

local M = {}

-- Package-specific tile renderer
local function render_package_tile(ctx, rect, P, state, pkg_system)
  local dl = ImGui.GetWindowDrawList(ctx)
  local x1, y1, x2, y2 = rect[1], rect[2], rect[3], rect[4]
  
  local is_active = pkg_system.active[P.id] == true
  local is_selected = state.selected
  local is_hovered = state.hover
  
  -- Background
  local bg_color = is_active and 0x2D4A37FF or 0x1A1A1AFF
  if is_hovered then
    bg_color = is_active and 0x3A5744FF or 0x2A2A2AFF
  end
  Draw.rect_filled(dl, x1, y1, x2, y2, bg_color, 6)
  
  -- Selection or border
  if is_selected then
    local ant_color = is_active and 0x42E896FF or 0xFFFFFF40
    Effects.marching_ants_rounded(dl, x1+0.5, y1+0.5, x2-0.5, y2-0.5,
                                  ant_color, 1, 6, 8, 6, 20)
  else
    local border_color = is_active and 0x42E896FF or 0x303030FF
    if is_hovered then border_color = 0xCCCCCCFF end
    Draw.rect(dl, x1, y1, x2, y2, border_color, 6, 1)
  end
  
  -- Order badge
  local order_idx = 0
  for i, id in ipairs(pkg_system.order) do
    if id == P.id then order_idx = i; break end
  end
  local badge = '#' .. tostring(order_idx)
  local bw, bh = ImGui.CalcTextSize(ctx, badge)
  local badge_x1, badge_y1 = x1 + 8, y1 + 8
  local badge_x2, badge_y2 = badge_x1 + bw + 10, badge_y1 + bh + 6
  Draw.rect_filled(dl, badge_x1, badge_y1, badge_x2, badge_y2, 
                   is_active and 0x00000099 or 0x00000066, 4)
  Draw.centered_text(ctx, badge, badge_x1, badge_y1, badge_x2, badge_y2, 0xAAAAAAFF)
  
  -- Checkbox
  local cb_size = 16
  local cb_x = x2 - 24
  local cb_y = y1 + 8
  ImGui.SetCursorScreenPos(ctx, cb_x, cb_y)
  ImGui.PushID(ctx, 'cb_' .. P.id)
  local changed, new_active = ImGui.Checkbox(ctx, '##enable', is_active)
  ImGui.PopID(ctx)
  if changed then
    pkg_system.active[P.id] = new_active
    -- Save to settings handled by pkg_system
  end
  
  -- Asset preview mosaic (simplified)
  local tile_w = x2 - x1
  local cell_size = math.min(50, math.floor((tile_w - 40) / 3))
  local mosaic_x = x1 + math.floor((tile_w - cell_size * 3 - 12) / 2)
  local mosaic_y = y1 + 45
  
  for i = 1, math.min(3, #(P.keys_order or {})) do
    local key = P.keys_order[i]
    if key then
      local cx = mosaic_x + (i-1) * (cell_size + 6)
      local color = 0x333333FF + (i * 0x111111FF) -- Simple color variation
      Draw.rect_filled(dl, cx, mosaic_y, cx + cell_size, mosaic_y + cell_size, color, 3)
      Draw.rect(dl, cx, mosaic_y, cx + cell_size, mosaic_y + cell_size, 0x00000088, 3, 1)
      local label = key:sub(1, 3):upper()
      Draw.centered_text(ctx, label, cx, mosaic_y, cx + cell_size, mosaic_y + cell_size, 0xFFFFFFFF)
    end
  end
  
  -- Footer
  local footer_y = y2 - 32
  Draw.rect_filled(dl, x1, footer_y, x2, y2, 0x00000044, 0)
  
  local name = (P.meta and P.meta.name) or P.id
  Draw.text(dl, x1 + 10, footer_y + 7, is_active and 0xFFFFFFFF or 0x999999FF, name)
  
  local count = 0
  for _ in pairs(P.assets or {}) do count = count + 1 end
  Draw.text_right(ctx, x2 - 10, footer_y + 7, 0x888888FF, string.format('%d assets', count))
end

function M.create(theme, settings)
  local L = Lifecycle.new()
  
  -- Mock package system for now (would load from your actual system)
  local pkg_system = {
    active = {},
    order = {},
    filters = { TCP = true, MCP = true, Transport = true, Global = true },
    tile_size = 220,
    search = "",
    demo = false,
  }
  
  -- Load settings
  if settings then
    pkg_system.active = settings:get('pkg_active', {})
    pkg_system.order = settings:get('pkg_order', {})
    pkg_system.tile_size = settings:get('pkg_tilesize', 220)
    pkg_system.filters = settings:get('pkg_filters', pkg_system.filters)
  end
  
  -- Generate demo data
  local function get_packages()
    local packages = {}
    if pkg_system.demo then
      for i = 1, 12 do
        local id = "package_" .. i
        packages[#packages + 1] = {
          id = id,
          meta = { name = "Package " .. i },
          assets = { asset1 = true, asset2 = true },
          keys_order = { "asset1", "asset2", "asset3" },
        }
        if not pkg_system.order[i] then
          pkg_system.order[i] = id
        end
      end
    end
    return packages
  end
  
  -- Create grid widget
  local grid = L:register(ColorBlocks.new({
    id = "packages_grid",
    gap = 12,
    min_col_w = function() return pkg_system.tile_size end,
    get_items = get_packages,
    key = function(P) return P.id end,
    
    on_reorder = function(new_order)
      pkg_system.order = new_order
      if settings then settings:set('pkg_order', new_order) end
    end,
    
    render_tile = function(ctx, rect, P, state)
      render_package_tile(ctx, rect, P, state, pkg_system)
    end,
    
    on_right_click = function(key, selected_keys)
      -- Toggle active state
      pkg_system.active[key] = not pkg_system.active[key]
      if settings then settings:set('pkg_active', pkg_system.active) end
    end,
    
    on_double_click = function(key)
      -- Open micro-manage (not implemented here)
      reaper.ShowMessageBox("Micro-manage: " .. key, "Package", 0)
    end,
  }))
  
  L:on_show(function()
    -- Load/scan packages
  end)
  
  L:begin_frame(function()
    -- Per-frame updates if needed
  end)
  
  return L:export(function(ctx, state)
    -- Toolbar
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameRounding, 4)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 6, 3)
    
    local ch_demo, new_demo = ImGui.Checkbox(ctx, 'Demo mode', pkg_system.demo)
    if ch_demo then
      pkg_system.demo = new_demo
      if settings then settings:set('pkg_demo', new_demo) end
    end
    
    ImGui.SameLine(ctx)
    ImGui.SetNextItemWidth(ctx, 200)
    local ch_search, new_search = ImGui.InputText(ctx, 'Search', pkg_system.search)
    if ch_search then pkg_system.search = new_search end
    
    ImGui.SameLine(ctx)
    ImGui.SetNextItemWidth(ctx, 140)
    local ch_size, new_size = ImGui.SliderInt(ctx, 'Tile Size', pkg_system.tile_size, 160, 420)
    if ch_size then
      pkg_system.tile_size = new_size
      if settings then settings:set('pkg_tilesize', new_size) end
    end
    
    ImGui.PopStyleVar(ctx, 2)
    ImGui.Separator(ctx)
    
    -- Draw grid
    grid:draw(ctx)
  end)
end

return M