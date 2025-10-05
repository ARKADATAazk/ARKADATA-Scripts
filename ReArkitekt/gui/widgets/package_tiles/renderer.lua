-- ReArkitekt/gui/widgets/package_tiles/renderer.lua
-- Package tile rendering module

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local Draw = require('ReArkitekt.gui.draw')
local MarchingAnts = require('ReArkitekt.gui.fx.marching_ants')
local Colors = require('ReArkitekt.core.colors')

local M = {}

M.CONFIG = {
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

M.TileRenderer = {}

function M.TileRenderer.background(dl, rect, bg_color, hover_factor)
  local x1, y1, x2, y2 = rect[1], rect[2], rect[3], rect[4]
  
  if M.CONFIG.tile.hover_shadow.enabled and hover_factor > 0.01 then
    local shadow_alpha = math.floor(hover_factor * M.CONFIG.tile.hover_shadow.max_alpha)
    local shadow_col = (0x000000 << 8) | shadow_alpha
    for i = M.CONFIG.tile.hover_shadow.max_offset, 1, -1 do
      Draw.rect_filled(dl, x1 - i, y1 - i + 2, x2 + i, y2 + i + 2, shadow_col, M.CONFIG.tile.rounding)
    end
  end
  
  Draw.rect_filled(dl, x1, y1, x2, y2, bg_color, M.CONFIG.tile.rounding)
end

function M.TileRenderer.border(dl, rect, base_color, is_selected, is_active, is_hovered)
  local x1, y1, x2, y2 = rect[1], rect[2], rect[3], rect[4]
  
  if is_selected then
    local ant_color
    if M.CONFIG.selection.ant_color then
      ant_color = M.CONFIG.selection.ant_color
    else
      ant_color = Colors.generate_marching_ants_color(
        base_color,
        M.CONFIG.selection.brightness_factor,
        M.CONFIG.selection.saturation_factor
      )
    end
    
    MarchingAnts.draw(
      dl, x1 + 0.5, y1 + 0.5, x2 - 0.5, y2 - 0.5,
      ant_color, M.CONFIG.colors.border.thickness, M.CONFIG.tile.rounding,
      M.CONFIG.selection.ant_dash, M.CONFIG.selection.ant_gap, M.CONFIG.selection.ant_speed
    )
  else
    local border_color
    
    if is_hovered then
      if M.CONFIG.colors.border.hover then
        border_color = M.CONFIG.colors.border.hover
      else
        border_color = Colors.generate_active_border(base_color, 0.6, 1.8)
      end
    elseif is_active then
      if M.CONFIG.colors.border.active then
        border_color = M.CONFIG.colors.border.active
      else
        border_color = Colors.generate_active_border(base_color, 0.7, 1.6)
      end
    else
      if M.CONFIG.colors.border.inactive then
        border_color = M.CONFIG.colors.border.inactive
      else
        border_color = Colors.generate_border(base_color, 0.2, 0.8)
      end
    end
    
    Draw.rect(dl, x1, y1, x2, y2, border_color, M.CONFIG.tile.rounding, M.CONFIG.colors.border.thickness)
  end
end

function M.TileRenderer.order_badge(ctx, dl, pkg, P, tile_x, tile_y)
  local order_index = 0
  for i, pid in ipairs(pkg.order) do
    if pid == P.id then
      order_index = i
      break
    end
  end
  
  local badge = '#' .. tostring(order_index)
  local bw, bh = ImGui.CalcTextSize(ctx, badge)
  
  local x1 = tile_x + M.CONFIG.badge.margin
  local y1 = tile_y + M.CONFIG.badge.margin
  local x2 = x1 + bw + M.CONFIG.badge.padding_x
  local y2 = y1 + bh + M.CONFIG.badge.padding_y
  
  local is_active = pkg.active[P.id] == true
  local bg = is_active and M.CONFIG.colors.badge.bg_active or M.CONFIG.colors.badge.bg_inactive
  
  Draw.rect_filled(dl, x1, y1, x2, y2, bg, M.CONFIG.badge.rounding)
  Draw.centered_text(ctx, badge, x1, y1, x2, y2, M.CONFIG.colors.badge.text)
  
  ImGui.SetCursorScreenPos(ctx, x1, y1)
  ImGui.InvisibleButton(ctx, '##ordtip-' .. P.id, x2 - x1, y2 - y1)
  if ImGui.IsItemHovered(ctx) then
    ImGui.SetTooltip(ctx, "Overwrite priority")
  end
end

function M.TileRenderer.conflicts(ctx, dl, pkg, P, tile_x, tile_y, tile_w)
  local conflicts = pkg:conflicts(true)
  local conf_count = conflicts[P.id] or 0
  if conf_count == 0 then return end
  
  local text = string.format('%d conflicts', conf_count)
  local tw, th = ImGui.CalcTextSize(ctx, text)
  local x = tile_x + math.floor((tile_w - tw) / 2)
  local y = tile_y + M.CONFIG.badge.margin
  
  Draw.text(dl, x, y, M.CONFIG.colors.text.conflict, text)
  
  ImGui.SetCursorScreenPos(ctx, x, y)
  ImGui.InvisibleButton(ctx, '##conftip-' .. P.id, tw, th)
  if ImGui.IsItemHovered(ctx) then
    ImGui.SetTooltip(ctx, "Conflicting Assets in Packages\n(autosolved through Overwrite Priority)")
  end
end

function M.TileRenderer.checkbox(ctx, pkg, P, cb_rects, tile_x, tile_y, tile_w, tile_h)
  local order_index = 0
  for i, pid in ipairs(pkg.order) do
    if pid == P.id then
      order_index = i
      break
    end
  end
  
  local badge = '#' .. tostring(order_index)
  local _, bh = ImGui.CalcTextSize(ctx, badge)
  local size = math.max(M.CONFIG.checkbox.min_size, math.floor(bh + 2))
  
  local x2 = tile_x + tile_w - M.CONFIG.checkbox.margin
  local y1 = tile_y + M.CONFIG.checkbox.margin
  local x1 = x2 - size
  local y2 = y1 + size
  
  cb_rects[P.id] = {x1, y1, x2, y2}
  
  ImGui.SetCursorScreenPos(ctx, x1, y1)
  ImGui.PushID(ctx, 'cb_visual_' .. P.id)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, M.CONFIG.checkbox.padding_x, M.CONFIG.checkbox.padding_y)
  ImGui.Checkbox(ctx, '##enable', pkg.active[P.id] == true)
  ImGui.PopStyleVar(ctx)
  ImGui.PopID(ctx)
end

function M.TileRenderer.mosaic(ctx, dl, theme, P, tile_x, tile_y, tile_w)
  if not theme or not theme.color_from_key then return end
  
  local cell_size = math.min(
    M.CONFIG.mosaic.max_size,
    math.floor((tile_w - M.CONFIG.mosaic.padding * 2 - (M.CONFIG.mosaic.count - 1) * M.CONFIG.mosaic.gap) / M.CONFIG.mosaic.count)
  )
  local total_width = cell_size * M.CONFIG.mosaic.count + (M.CONFIG.mosaic.count - 1) * M.CONFIG.mosaic.gap
  local mosaic_x = tile_x + math.floor((tile_w - total_width) / 2)
  local mosaic_y = tile_y + M.CONFIG.mosaic.y_offset
  
  local preview_keys = P.meta and P.meta.mosaic or { P.keys_order[1], P.keys_order[2], P.keys_order[3] }
  for i = 1, math.min(M.CONFIG.mosaic.count, #preview_keys) do
    local key = preview_keys[i]
    if key then
      local col = theme.color_from_key(key:gsub("%.%w+$", ""))
      local cx = mosaic_x + (i - 1) * (cell_size + M.CONFIG.mosaic.gap)
      local cy = mosaic_y
      
      Draw.rect_filled(dl, cx, cy, cx + cell_size, cy + cell_size, col, M.CONFIG.mosaic.rounding)
      Draw.rect(dl, cx, cy, cx + cell_size, cy + cell_size, 
                M.CONFIG.mosaic.border_color, M.CONFIG.mosaic.rounding, M.CONFIG.mosaic.border_thickness)
      
      local label = key:sub(1, 3):upper()
      Draw.centered_text(ctx, label, cx, cy, cx + cell_size, cy + cell_size, 0xFFFFFFFF)
    end
  end
end

function M.TileRenderer.footer(ctx, dl, pkg, P, tile_x, tile_y, tile_w, tile_h)
  local footer_y = tile_y + tile_h - M.CONFIG.footer.height
  Draw.rect_filled(dl, tile_x, footer_y, tile_x + tile_w, tile_y + tile_h, M.CONFIG.colors.footer.gradient, 0)
  
  local name = P.meta and P.meta.name or P.id
  local is_active = pkg.active[P.id] == true
  local name_color = is_active and M.CONFIG.colors.text.active or M.CONFIG.colors.text.inactive
  Draw.text(dl, tile_x + 10, footer_y + 7, name_color, name)
  
  local count = 0
  for _ in pairs(P.assets or {}) do count = count + 1 end
  local count_text = string.format('%d assets', count)
  Draw.text_right(ctx, tile_x + tile_w - 10, footer_y + 7, M.CONFIG.colors.text.secondary, count_text)
end

return M