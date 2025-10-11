-- ReArkitekt/ColorPalette/app/gui.lua
-- Main GUI orchestrator for Color Palette (Frameless Edition)

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local Colors = require('ReArkitekt.core.colors')
local Draw = require('ReArkitekt.gui.draw')
local ColorGrid = require('ReArkitekt.ColorPalette.widgets.color_grid')
local Controller = require('ReArkitekt.ColorPalette.app.controller')
local Sheet = require('ReArkitekt.gui.widgets.overlay.sheet')

local M = {}

local GUI = {}
GUI.__index = GUI

function M.create(State, settings, overlay_manager)
  local gui = setmetatable({
    State = State,
    settings = settings,
    overlay = overlay_manager,
    color_grid = ColorGrid.new(),
    controller = Controller.new(),
    
    -- Drag-to-move state
    drag_state = {
      mouse_down = false,
      down_time = 0,
      threshold = 0.25,  -- 250ms to start dragging
      is_dragging = false,
      start_pos = {x = 0, y = 0},
      window_start_pos = {x = 0, y = 0},
    },
  }, GUI)
  
  return gui
end

function GUI:open_settings()
  self.overlay:push({
    id = "color_palette_settings",
    use_viewport = true,
    close_on_scrim = true,
    esc_to_close = true,
    render = function(ctx, alpha, bounds)
      Sheet.render(ctx, alpha, bounds, function(ctx, w, h, alpha)
        self:draw_settings_content(ctx, w, h, alpha)
      end, {
        title = "Color Palette Settings",
        width = 0.5,
        height = 0.75,
      })
    end,
  })
end

function GUI:draw_settings_content(ctx, w, h, alpha)
  local padding = 20
  local preview_height = 180
  local content_height = h - preview_height - padding * 2
  
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding, padding, padding)
  ImGui.BeginChild(ctx, "##settings_content", w - padding * 2, content_height, ImGui.ChildFlags_None, ImGui.WindowFlags_NoScrollbar)
  
  if ImGui.BeginTabBar(ctx, "##settings_tabs") then
    
    if ImGui.BeginTabItem(ctx, "Colors") then
      ImGui.Spacing(ctx)
      
      local cfg = self.State.get_palette_config()
      
      -- Hue
      ImGui.SetNextItemWidth(ctx, w - padding * 4 - 80)
      local changed, new_hue = ImGui.SliderDouble(ctx, "Hue Offset", cfg.hue, 0.0, 1.0, "%.2f")
      if changed then
        self.State.update_palette_hue(new_hue)
      end
      
      ImGui.Spacing(ctx)
      
      -- Saturation Range
      ImGui.Text(ctx, "Saturation Range:")
      ImGui.SetNextItemWidth(ctx, w - padding * 4 - 80)
      local sat_changed, sat1 = ImGui.SliderDouble(ctx, "##sat1", cfg.sat[1], 0.0, 1.0, "Top: %.2f")
      ImGui.SetNextItemWidth(ctx, w - padding * 4 - 80)
      local sat_changed2, sat2 = ImGui.SliderDouble(ctx, "##sat2", cfg.sat[2], 0.0, 1.0, "Bottom: %.2f")
      
      if sat_changed or sat_changed2 then
        self.State.update_palette_sat({sat1, sat2})
      end
      
      ImGui.Spacing(ctx)
      
      -- Luminance Range
      ImGui.Text(ctx, "Luminance Range:")
      ImGui.SetNextItemWidth(ctx, w - padding * 4 - 80)
      local lum_changed, lum1 = ImGui.SliderDouble(ctx, "##lum1", cfg.lum[1], 0.0, 1.0, "Top: %.2f")
      ImGui.SetNextItemWidth(ctx, w - padding * 4 - 80)
      local lum_changed2, lum2 = ImGui.SliderDouble(ctx, "##lum2", cfg.lum[2], 0.0, 1.0, "Bottom: %.2f")
      
      if lum_changed or lum_changed2 then
        self.State.update_palette_lum({lum1, lum2})
      end
      
      ImGui.Spacing(ctx)
      
      -- Grey column checkbox
      local grey_changed, include_grey = ImGui.Checkbox(ctx, "Include grey column", cfg.include_grey)
      if grey_changed then
        self.State.update_palette_grey(include_grey)
      end
      
      ImGui.Spacing(ctx)
      ImGui.Spacing(ctx)
      
      -- Reset button
      if ImGui.Button(ctx, "Restore Default Colors", 160, 28) then
        self.State.restore_default_colors()
      end
      
      ImGui.EndTabItem(ctx)
    end
    
    if ImGui.BeginTabItem(ctx, "Size") then
      ImGui.Spacing(ctx)
      
      local cfg = self.State.get_palette_config()
      
      -- Columns
      ImGui.SetNextItemWidth(ctx, 120)
      local cols_changed, new_cols = ImGui.InputInt(ctx, "Columns", cfg.cols, 1, 5)
      if cols_changed then
        new_cols = math.max(1, math.min(30, new_cols))
        self.State.update_palette_size(new_cols, nil)
      end
      
      -- Rows
      ImGui.SetNextItemWidth(ctx, 120)
      local rows_changed, new_rows = ImGui.InputInt(ctx, "Rows", cfg.rows, 1, 5)
      if rows_changed then
        new_rows = math.max(1, math.min(10, new_rows))
        self.State.update_palette_size(nil, new_rows)
      end
      
      -- Spacing
      ImGui.SetNextItemWidth(ctx, 120)
      local spacing_changed, new_spacing = ImGui.InputInt(ctx, "Spacing (px)", cfg.spacing, 1, 5)
      if spacing_changed then
        new_spacing = math.max(0, math.min(10, new_spacing))
        self.State.update_palette_spacing(new_spacing)
      end
      
      ImGui.Spacing(ctx)
      ImGui.Spacing(ctx)
      
      -- Reset button
      if ImGui.Button(ctx, "Restore Default Sizes", 160, 28) then
        self.State.restore_default_sizes()
      end
      
      ImGui.EndTabItem(ctx)
    end
    
    if ImGui.BeginTabItem(ctx, "Options") then
      ImGui.Spacing(ctx)
      
      local auto_close = self.State.get_auto_close()
      local set_children = self.State.get_set_children()
      
      local changed, new_val = ImGui.Checkbox(ctx, "Auto-close after applying color", auto_close)
      if changed then
        self.State.set_auto_close(new_val)
      end
      
      ImGui.Spacing(ctx)
      
      changed, new_val = ImGui.Checkbox(ctx, "Set children tracks", set_children)
      if changed then
        self.State.set_children(new_val)
      end
      
      ImGui.Spacing(ctx)
      ImGui.Separator(ctx)
      ImGui.Spacing(ctx)
      
      ImGui.TextWrapped(ctx, "Shortcuts:")
      ImGui.BulletText(ctx, "Right-click anywhere to open settings")
      ImGui.BulletText(ctx, "Ctrl+S to toggle settings")
      ImGui.BulletText(ctx, "Ctrl+Z to undo")
      ImGui.BulletText(ctx, "ESC to close (if auto-close enabled)")
      
      ImGui.EndTabItem(ctx)
    end
    
    if ImGui.BeginTabItem(ctx, "About") then
      ImGui.Spacing(ctx)
      ImGui.TextWrapped(ctx, "Color Palette Tool")
      ImGui.Spacing(ctx)
      ImGui.TextWrapped(ctx, "A discrete, frameless color palette for REAPER. ReArkitekt port of Rodilab's Color Palette script.")
      ImGui.Spacing(ctx)
      ImGui.Separator(ctx)
      ImGui.Spacing(ctx)
      ImGui.TextWrapped(ctx, "Click any color to apply it to selected tracks.")
      ImGui.TextWrapped(ctx, "Adjust colors, size, and layout in real-time.")
      ImGui.Spacing(ctx)
      ImGui.EndTabItem(ctx)
    end
    
    ImGui.EndTabBar(ctx)
  end
  
  ImGui.EndChild(ctx)
  ImGui.PopStyleVar(ctx)
  
  -- Draw separator line
  local dl = ImGui.GetWindowDrawList(ctx)
  local separator_y = ImGui.GetCursorScreenPos(ctx)
  local win_x, _ = ImGui.GetCursorScreenPos(ctx)
  Draw.line(dl, win_x, separator_y, win_x + w - padding * 2, separator_y, 0x404040AA, 1.0)
  
  ImGui.Spacing(ctx)
  ImGui.Spacing(ctx)
  
  -- Live preview section with background
  local preview_label_y = ImGui.GetCursorPosY(ctx)
  ImGui.Text(ctx, "Live Preview:")
  ImGui.Spacing(ctx)
  
  -- Draw subtle background for preview area
  local preview_x, preview_y = ImGui.GetCursorScreenPos(ctx)
  local preview_w = w - padding * 2
  local preview_content_h = preview_height - 50
  
  -- Background rect
  Draw.rect_filled(dl, preview_x - 8, preview_y - 8, preview_x + preview_w + 8, preview_y + preview_content_h + 8, 0x00000033, 6)
  Draw.rect(dl, preview_x - 8, preview_y - 8, preview_x + preview_w + 8, preview_y + preview_content_h + 8, 0x404040AA, 6, 1)
  
  ImGui.BeginChild(ctx, "##palette_preview", preview_w, preview_content_h, ImGui.ChildFlags_None, ImGui.WindowFlags_NoScrollbar)
  
  local palette_colors = self.State.get_palette_colors()
  local palette_config = self.State.get_palette_config()
  
  -- Draw palette without interaction
  self:draw_palette_preview(ctx, palette_colors, palette_config)
  
  ImGui.EndChild(ctx)
end

function GUI:draw_palette_preview(ctx, colors, config)
  if not colors or #colors == 0 then
    ImGui.Text(ctx, "No colors to display")
    return
  end
  
  local cols = config.cols or 15
  local spacing = config.spacing or 1
  
  -- Calculate tile size for preview
  local avail_w, avail_h = ImGui.GetContentRegionAvail(ctx)
  local rows = math.ceil(#colors / cols)
  local total_spacing_w = (cols - 1) * spacing
  local total_spacing_h = (rows - 1) * spacing
  local tile_w = math.floor((avail_w - total_spacing_w) / cols)
  local tile_h = math.floor((avail_h - total_spacing_h) / rows)
  local tile_size = math.min(tile_w, tile_h)
  tile_size = math.max(tile_size, 16)
  
  local rounding = 3
  local origin_x, origin_y = ImGui.GetCursorScreenPos(ctx)
  local dl = ImGui.GetWindowDrawList(ctx)
  
  -- Draw all color tiles (no interaction in preview)
  for i, color in ipairs(colors) do
    local col_idx = (i - 1) % cols
    local row_idx = math.floor((i - 1) / cols)
    
    local x = origin_x + col_idx * (tile_size + spacing)
    local y = origin_y + row_idx * (tile_size + spacing)
    
    local x1, y1 = x, y
    local x2, y2 = x + tile_size, y + tile_size
    
    local fill_color = color
    local border_color = Colors.with_alpha(color, 0xFF)
    
    -- Draw tile
    Draw.rect_filled(dl, x1, y1, x2, y2, fill_color, rounding)
    Draw.rect(dl, x1, y1, x2, y2, border_color, rounding, 1)
  end
end

function GUI:handle_shortcuts(ctx)
  local ctrl = ImGui.IsKeyDown(ctx, ImGui.Mod_Ctrl)
  local s_pressed = ImGui.IsKeyPressed(ctx, ImGui.Key_S, false)
  
  if ctrl and s_pressed then
    self:open_settings()
    return false
  end
  
  local z_pressed = ImGui.IsKeyPressed(ctx, ImGui.Key_Z, false)
  if ctrl and z_pressed then
    reaper.Undo_DoUndo2(0)
    return false
  end
  
  local esc_pressed = ImGui.IsKeyPressed(ctx, ImGui.Key_Escape, false)
  if esc_pressed and self.State.get_auto_close() then
    return true
  end
  
  return false
end

function GUI:update_drag_state(ctx)
  local ds = self.drag_state
  local current_time = reaper.time_precise()
  
  -- Check if mouse is down
  local is_mouse_down = ImGui.IsMouseDown(ctx, 0)
  
  if is_mouse_down and not ds.mouse_down then
    -- Mouse just pressed
    ds.mouse_down = true
    ds.down_time = current_time
    ds.is_dragging = false
    ds.start_pos.x, ds.start_pos.y = ImGui.GetMousePos(ctx)
    ds.window_start_pos.x, ds.window_start_pos.y = ImGui.GetWindowPos(ctx)
  elseif ds.mouse_down and is_mouse_down then
    -- Mouse held down
    local held_time = current_time - ds.down_time
    
    if held_time >= ds.threshold and not ds.is_dragging then
      -- Start dragging after threshold
      ds.is_dragging = true
    end
    
    if ds.is_dragging then
      -- Update window position while dragging
      local mx, my = ImGui.GetMousePos(ctx)
      local dx = mx - ds.start_pos.x
      local dy = my - ds.start_pos.y
      
      ImGui.SetWindowPos(ctx, 
        ds.window_start_pos.x + dx, 
        ds.window_start_pos.y + dy)
    end
  elseif not is_mouse_down and ds.mouse_down then
    -- Mouse released
    ds.mouse_down = false
  end
  
  return ds.is_dragging
end

function GUI:draw_drag_feedback(ctx)
  local ds = self.drag_state
  
  if not ds.mouse_down or ds.is_dragging then
    return
  end
  
  -- Calculate progress toward drag threshold
  local current_time = reaper.time_precise()
  local held_time = current_time - ds.down_time
  local progress = math.min(held_time / ds.threshold, 1.0)
  
  if progress > 0.1 and progress < 1.0 then
    -- Draw subtle feedback indicator
    local mx, my = ImGui.GetMousePos(ctx)
    local dl = ImGui.GetWindowDrawList(ctx)
    local radius = 20
    local thickness = 3
    
    -- Draw arc showing progress
    local segments = math.floor(progress * 32)
    if segments > 0 then
      local arc_color = Colors.with_alpha(0xFFFFFFFF, math.floor(progress * 120))
      
      for i = 0, segments do
        local angle1 = -math.pi / 2 + (i / 32) * math.pi * 2 * progress
        local angle2 = -math.pi / 2 + ((i + 1) / 32) * math.pi * 2 * progress
        local x1 = mx + math.cos(angle1) * radius
        local y1 = my + math.sin(angle1) * radius
        local x2 = mx + math.cos(angle2) * radius
        local y2 = my + math.sin(angle2) * radius
        Draw.line(dl, x1, y1, x2, y2, arc_color, thickness)
      end
    end
  end
end

function GUI:draw(ctx)
  local should_close = self:handle_shortcuts(ctx)
  if should_close then
    return false
  end
  
  -- Update drag state
  local is_dragging = self:update_drag_state(ctx)
  
  local palette_colors = self.State.get_palette_colors()
  local palette_config = self.State.get_palette_config()
  
  -- Detect right-click anywhere in window
  local window_w, window_h = ImGui.GetWindowSize(ctx)
  
  ImGui.SetCursorPos(ctx, 0, 0)
  ImGui.InvisibleButton(ctx, "##window_right_click", window_w, window_h)
  
  if ImGui.IsItemClicked(ctx, 1) then
    self:open_settings()
  end
  
  -- Reset cursor for grid drawing
  ImGui.SetCursorPos(ctx, 0, 0)
  
  -- Draw color grid (disable interaction if we're dragging or in drag threshold)
  local allow_interaction = not is_dragging and not self.drag_state.mouse_down
  local clicked_color = self.color_grid:draw(ctx, palette_colors, palette_config, allow_interaction)
  
  -- Draw drag feedback overlay
  self:draw_drag_feedback(ctx)
  
  -- Apply color only if we got a valid click (not during/after drag)
  if clicked_color then
    local target_type = "Tracks"
    local action_type = self.State.get_action_type()
    local set_children = self.State.get_set_children()
    
    self.controller:apply_color(clicked_color, target_type, action_type, set_children)
    
    if self.State.get_auto_close() then
      return false
    end
  end
  
  return true
end

return M