-- package_tiles.lua
-- Package-specific implementation using colorblocks grid widget

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local Grid = require('ReArkitekt.gui.widgets.colorblocks')
local Draw = require('ReArkitekt.gui.draw')
local Effects = require('ReArkitekt.gui.effects')
local Colors = require('ReArkitekt.gui.colors')
local Motion = require('ReArkitekt.gui.systems.motion')
local TileAnim = require('ReArkitekt.gui.systems.tile_animation')

local M = {}

local CONFIG = {
  tile = {
    rounding = 6,
    hover_shadow = { enabled = true, max_offset = 2, max_alpha = 20 },
  },
  
  colors = {
    bg = { inactive = 0x1A1A1AFF, active = 0x2D4A37FF, hover_tint = 0x2A2A2AFF, hover_influence = 0.4 },
    border = { inactive = 0x303030FF, active = nil, hover = nil, thickness = 0.5 },
    text = { active = 0xFFFFFFFF, inactive = 0x999999FF, secondary = 0x888888FF, conflict = 0xFFA500FF },
    badge = { bg_active = 0x00000099, bg_inactive = 0x00000066, text = 0xAAAAAAFF },
    footer = { gradient = 0x00000044 },
  },
  
  selection = {
    ant_speed = 20,
    ant_color = nil,
    ant_dash = 8,
    ant_gap = 6,
    brightness_factor = 1.8,
    saturation_factor = 0.6,
  },
  
  badge = { padding_x = 10, padding_y = 6, rounding = 4, margin = 8 },
  checkbox = { min_size = 12, padding_x = 2, padding_y = 1, margin = 8 },
  footer = { height = 32 },
  
  mosaic = {
    padding = 15, max_size = 50, gap = 6, count = 3,
    rounding = 3, border_color = 0x00000088, border_thickness = 1, y_offset = 45,
  },
  
  animation = { speed_hover = 12.0, speed_active = 8.0 },
}

local mm_window = { open = false, pkgId = nil }
local mm_search = ""
local mm_multi = {}

local function get_order_index(pkg, id)
  for i, pid in ipairs(pkg.order) do
    if pid == id then return i end
  end
  return 0
end

local function tooltip(ctx, text)
  if ImGui.IsItemHovered(ctx) then 
    ImGui.SetTooltip(ctx, text or "") 
  end
end

local function compute_checkbox_rect(ctx, pkg, id, tile_x, tile_y, tile_w, tile_h)
  local ord = get_order_index(pkg, id)
  local badge = '#' .. tostring(ord)
  local _, bh = ImGui.CalcTextSize(ctx, badge)
  local size = math.max(CONFIG.checkbox.min_size, math.floor(bh + 2))
  
  local x2 = tile_x + tile_w - CONFIG.checkbox.margin
  local y1 = tile_y + CONFIG.checkbox.margin
  return x2 - size, y1, x2, y1 + size
end

local function get_tile_base_color(pkg, P)
  local is_active = pkg.active[P.id] == true
  return is_active and CONFIG.colors.bg.active or CONFIG.colors.bg.inactive
end

local TileRenderer = {}

function TileRenderer.background(dl, rect, bg_color, hover_factor)
  local x1, y1, x2, y2 = rect[1], rect[2], rect[3], rect[4]
  
  if CONFIG.tile.hover_shadow.enabled and hover_factor > 0.01 then
    local shadow_alpha = math.floor(hover_factor * CONFIG.tile.hover_shadow.max_alpha)
    local shadow_col = (0x000000 << 8) | shadow_alpha
    for i = CONFIG.tile.hover_shadow.max_offset, 1, -1 do
      Draw.rect_filled(dl, x1 - i, y1 - i + 2, x2 + i, y2 + i + 2, shadow_col, CONFIG.tile.rounding)
    end
  end
  
  Draw.rect_filled(dl, x1, y1, x2, y2, bg_color, CONFIG.tile.rounding)
end

function TileRenderer.border(dl, rect, base_color, is_selected, is_active, is_hovered)
  local x1, y1, x2, y2 = rect[1], rect[2], rect[3], rect[4]
  
  if is_selected then
    local ant_color
    if CONFIG.selection.ant_color then
      ant_color = CONFIG.selection.ant_color
    else
      ant_color = Colors.generate_marching_ants_color(
        base_color,
        CONFIG.selection.brightness_factor,
        CONFIG.selection.saturation_factor
      )
    end
    
    Effects.marching_ants_rounded(
      dl, x1 + 0.5, y1 + 0.5, x2 - 0.5, y2 - 0.5,
      ant_color, CONFIG.colors.border.thickness, CONFIG.tile.rounding,
      CONFIG.selection.ant_dash, CONFIG.selection.ant_gap, CONFIG.selection.ant_speed
    )
  else
    local border_color
    
    if is_hovered then
      if CONFIG.colors.border.hover then
        border_color = CONFIG.colors.border.hover
      else
        border_color = Colors.generate_active_border(base_color, 0.6, 1.8)
      end
    elseif is_active then
      if CONFIG.colors.border.active then
        border_color = CONFIG.colors.border.active
      else
        border_color = Colors.generate_active_border(base_color, 0.7, 1.6)
      end
    else
      if CONFIG.colors.border.inactive then
        border_color = CONFIG.colors.border.inactive
      else
        border_color = Colors.generate_border(base_color, 0.2, 0.8)
      end
    end
    
    Draw.rect(dl, x1, y1, x2, y2, border_color, CONFIG.tile.rounding, CONFIG.colors.border.thickness)
  end
end

function TileRenderer.order_badge(ctx, dl, pkg, P, tile_x, tile_y)
  local order_index = get_order_index(pkg, P.id)
  local badge = '#' .. tostring(order_index)
  local bw, bh = ImGui.CalcTextSize(ctx, badge)
  
  local x1 = tile_x + CONFIG.badge.margin
  local y1 = tile_y + CONFIG.badge.margin
  local x2 = x1 + bw + CONFIG.badge.padding_x
  local y2 = y1 + bh + CONFIG.badge.padding_y
  
  local is_active = pkg.active[P.id] == true
  local bg = is_active and CONFIG.colors.badge.bg_active or CONFIG.colors.badge.bg_inactive
  
  Draw.rect_filled(dl, x1, y1, x2, y2, bg, CONFIG.badge.rounding)
  Draw.centered_text(ctx, badge, x1, y1, x2, y2, CONFIG.colors.badge.text)
  
  ImGui.SetCursorScreenPos(ctx, x1, y1)
  ImGui.InvisibleButton(ctx, '##ordtip-' .. P.id, x2 - x1, y2 - y1)
  tooltip(ctx, "Overwrite priority")
end

function TileRenderer.conflicts(ctx, dl, pkg, P, tile_x, tile_y, tile_w)
  local conflicts = pkg:conflicts(true)
  local conf_count = conflicts[P.id] or 0
  if conf_count == 0 then return end
  
  local text = string.format('%d conflicts', conf_count)
  local tw, th = ImGui.CalcTextSize(ctx, text)
  local x = tile_x + math.floor((tile_w - tw) / 2)
  local y = tile_y + CONFIG.badge.margin
  
  Draw.text(dl, x, y, CONFIG.colors.text.conflict, text)
  
  ImGui.SetCursorScreenPos(ctx, x, y)
  ImGui.InvisibleButton(ctx, '##conftip-' .. P.id, tw, th)
  tooltip(ctx, "Conflicting Assets in Packages\n(autosolved through Overwrite Priority)")
end

function TileRenderer.checkbox(ctx, pkg, P, cb_rects, tile_x, tile_y, tile_w, tile_h)
  local x1, y1, x2, y2 = compute_checkbox_rect(ctx, pkg, P.id, tile_x, tile_y, tile_w, tile_h)
  cb_rects[P.id] = {x1, y1, x2, y2}
  
  ImGui.SetCursorScreenPos(ctx, x1, y1)
  ImGui.PushID(ctx, 'cb_visual_' .. P.id)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, CONFIG.checkbox.padding_x, CONFIG.checkbox.padding_y)
  ImGui.Checkbox(ctx, '##enable', pkg.active[P.id] == true)
  ImGui.PopStyleVar(ctx)
  ImGui.PopID(ctx)
end

function TileRenderer.mosaic(ctx, dl, theme, P, tile_x, tile_y, tile_w)
  if not theme or not theme.color_from_key then return end
  
  local cell_size = math.min(
    CONFIG.mosaic.max_size,
    math.floor((tile_w - CONFIG.mosaic.padding * 2 - (CONFIG.mosaic.count - 1) * CONFIG.mosaic.gap) / CONFIG.mosaic.count)
  )
  local total_width = cell_size * CONFIG.mosaic.count + (CONFIG.mosaic.count - 1) * CONFIG.mosaic.gap
  local mosaic_x = tile_x + math.floor((tile_w - total_width) / 2)
  local mosaic_y = tile_y + CONFIG.mosaic.y_offset
  
  local preview_keys = P.meta and P.meta.mosaic or { P.keys_order[1], P.keys_order[2], P.keys_order[3] }
  for i = 1, math.min(CONFIG.mosaic.count, #preview_keys) do
    local key = preview_keys[i]
    if key then
      local col = theme.color_from_key(key:gsub("%.%w+$", ""))
      local cx = mosaic_x + (i - 1) * (cell_size + CONFIG.mosaic.gap)
      local cy = mosaic_y
      
      Draw.rect_filled(dl, cx, cy, cx + cell_size, cy + cell_size, col, CONFIG.mosaic.rounding)
      Draw.rect(dl, cx, cy, cx + cell_size, cy + cell_size, 
                CONFIG.mosaic.border_color, CONFIG.mosaic.rounding, CONFIG.mosaic.border_thickness)
      
      local label = key:sub(1, 3):upper()
      Draw.centered_text(ctx, label, cx, cy, cx + cell_size, cy + cell_size, 0xFFFFFFFF)
    end
  end
end

function TileRenderer.footer(ctx, dl, pkg, P, tile_x, tile_y, tile_w, tile_h)
  local footer_y = tile_y + tile_h - CONFIG.footer.height
  Draw.rect_filled(dl, tile_x, footer_y, tile_x + tile_w, tile_y + tile_h, CONFIG.colors.footer.gradient, 0)
  
  local name = P.meta and P.meta.name or P.id
  local is_active = pkg.active[P.id] == true
  local name_color = is_active and CONFIG.colors.text.active or CONFIG.colors.text.inactive
  Draw.text(dl, tile_x + 10, footer_y + 7, name_color, name)
  
  local count = 0
  for _ in pairs(P.assets or {}) do count = count + 1 end
  local count_text = string.format('%d assets', count)
  Draw.text_right(ctx, tile_x + tile_w - 10, footer_y + 7, CONFIG.colors.text.secondary, count_text)
end

local function draw_package_tile(ctx, pkg, theme, P, rect, state, settings, custom_state)
  local dl = ImGui.GetWindowDrawList(ctx)
  local x1, y1, x2, y2 = rect[1], rect[2], rect[3], rect[4]
  local tile_w, tile_h = x2 - x1, y2 - y1
  
  local is_active = pkg.active[P.id] == true
  local is_selected = state.selected
  local is_hovered = state.hover
  
  custom_state.animator:track(P.id, 'hover', is_hovered and 1.0 or 0.0, CONFIG.animation.speed_hover)
  custom_state.animator:track(P.id, 'active', is_active and 1.0 or 0.0, CONFIG.animation.speed_active)
  
  local hover_factor = custom_state.animator:get(P.id, 'hover')
  local active_factor = custom_state.animator:get(P.id, 'active')
  
  local bg_active = Motion.color_lerp(CONFIG.colors.bg.inactive, CONFIG.colors.bg.active, active_factor)
  local bg_final = Motion.color_lerp(bg_active, CONFIG.colors.bg.hover_tint, hover_factor * CONFIG.colors.bg.hover_influence)
  
  local base_color = get_tile_base_color(pkg, P)
  
  TileRenderer.background(dl, rect, bg_final, is_selected and 0 or hover_factor)
  TileRenderer.border(dl, rect, base_color, is_selected, is_active, is_hovered)
  TileRenderer.order_badge(ctx, dl, pkg, P, x1, y1)
  TileRenderer.conflicts(ctx, dl, pkg, P, x1, y1, tile_w)
  TileRenderer.checkbox(ctx, pkg, P, custom_state.checkbox_rects, x1, y1, tile_w, tile_h)
  TileRenderer.mosaic(ctx, dl, theme, P, x1, y1, tile_w)
  TileRenderer.footer(ctx, dl, pkg, P, x1, y1, tile_w, tile_h)
end

function M.create(pkg, settings, theme)
  local custom_state = {
    checkbox_rects = {},
    animator = TileAnim.new(CONFIG.animation.speed_hover),
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
    
    on_reorder = function(new_keys)
      pkg.order = new_keys
      if settings then settings:set('pkg_order', pkg.order) end
    end,
    
    on_select = function(selected_keys) end,
    
    on_right_click = function(key, selected_keys)
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
    
    on_double_click = function(key)
      mm_window.open = true
      mm_window.pkgId = key
      mm_search = ""
      mm_multi = {}
    end,
    
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
        
        tooltip(ctx, pkg.active[id] and "Disable package" or "Enable package")
        ImGui.PopID(ctx)
      end
    end,
  })
  
  return {
    grid = grid,
    custom_state = custom_state,
    config = CONFIG,
    
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

function M.draw_micromanage_window(ctx, pkg, settings)
  if not mm_window.open or not mm_window.pkgId then return end
  
  local P = nil
  for _, package in ipairs(pkg.index) do
    if package.id == mm_window.pkgId then
      P = package
      break
    end
  end
  
  if not P then
    mm_window.open = false
    return
  end
  
  local title = string.format("Package • %s — Micro-manage##mmw-%s", P.meta.name or P.id, P.id)
  if ImGui.Begin(ctx, title) then
    ImGui.Text(ctx, P.path or "(package)")
    ImGui.Separator(ctx)
    
    ImGui.SetNextItemWidth(ctx, 220)
    local ch_s, new_q = ImGui.InputText(ctx, 'Search##mm', mm_search or '')
    if ch_s then mm_search = new_q end
    ImGui.SameLine(ctx)
    if ImGui.Button(ctx, 'Close##mm') then 
      mm_window.open = false
      mm_window.pkgId = nil
    end
    
    if ImGui.Button(ctx, 'Select all##mm') then
      for _, k in ipairs(P.keys_order) do 
        if (mm_search == '' or k:find(mm_search, 1, true)) then 
          mm_multi[k] = true 
        end 
      end
    end
    ImGui.SameLine(ctx)
    if ImGui.Button(ctx, 'Clear selection##mm') then 
      mm_multi = {} 
    end
    
    ImGui.Separator(ctx)
    
    local tbl_flags = ImGui.TableFlags_Borders | ImGui.TableFlags_RowBg | ImGui.TableFlags_ScrollY
    if ImGui.BeginTable(ctx, 'mm_table##' .. P.id, 3, tbl_flags) then
      ImGui.TableSetupScrollFreeze(ctx, 0, 1)
      ImGui.TableSetupColumn(ctx, 'Sel', ImGui.TableColumnFlags_WidthFixed, 36)
      ImGui.TableSetupColumn(ctx, 'Asset')
      ImGui.TableSetupColumn(ctx, 'Status', ImGui.TableColumnFlags_WidthFixed, 80)
      ImGui.TableHeadersRow(ctx)
      
      for _, key in ipairs(P.keys_order) do
        if (mm_search == '' or key:find(mm_search, 1, true)) then
          ImGui.TableNextRow(ctx)
          
          ImGui.TableSetColumnIndex(ctx, 0)
          local sel = mm_multi[key] == true
          local c1, v1 = ImGui.Checkbox(ctx, '##sel-' .. key, sel)
          if c1 then mm_multi[key] = v1 end
          
          ImGui.TableSetColumnIndex(ctx, 1)
          ImGui.Text(ctx, key)
          
          ImGui.TableSetColumnIndex(ctx, 2)
          ImGui.TextDisabled(ctx, "Active")
        end
      end
      
      ImGui.EndTable(ctx)
    end
  end
  ImGui.End(ctx)
end

return M