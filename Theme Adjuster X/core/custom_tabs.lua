-- core/custom_tabs.lua
-- Enhanced tab strip with animations and proper styling

local Draw = require('gui.draw')

local M = {}

function M.draw(ctx, tabs, active_idx, fonts, height, on_switch)
  local dl = ImGui.GetWindowDrawList(ctx)
  local win_w = select(1, ImGui.GetContentRegionAvail(ctx)) or 0
  local cursor_x, cursor_y = ImGui.GetCursorScreenPos(ctx)
  
  -- Tab colors
  local TAB_ACTIVE_BG = 0x242424FF
  local TAB_INACTIVE_BG = 0x1A1A1AFF
  local TAB_HOVER_BG = 0x202020FF
  local TAB_BORDER = 0x000000FF
  local TAB_TEXT_ACTIVE = 0xFFFFFFFF
  local TAB_TEXT_INACTIVE = 0xBBBBBB6D
  
  -- Calculate tab widths
  local tab_count = #tabs
  local tab_width = win_w / tab_count
  
  ImGui.PushFont(ctx, fonts.tabs.face)
  
  local active_tab_rect = nil
  
  for i, tab in ipairs(tabs) do
    local x1 = Draw.snap(cursor_x + (i-1) * tab_width)
    local x2 = Draw.snap(cursor_x + i * tab_width)
    local y1 = Draw.snap(cursor_y)
    local y2 = Draw.snap(cursor_y + height)
    
    -- Hit test
    ImGui.SetCursorScreenPos(ctx, x1, y1)
    ImGui.InvisibleButton(ctx, "##tab"..i, x2-x1, y2-y1)
    
    local is_hovered = ImGui.IsItemHovered(ctx)
    local is_clicked = ImGui.IsItemClicked(ctx)
    local is_active = (i == active_idx)
    
    if is_clicked then
      on_switch(i)
    end
    
    -- Background
    local bg_color = is_active and TAB_ACTIVE_BG or
                     is_hovered and TAB_HOVER_BG or
                     TAB_INACTIVE_BG
    
    Draw.rect_filled(dl, x1, y1, x2, y2, bg_color, 0)
    
    -- Borders
    Draw.line(dl, x1, y1, x2, y1, TAB_BORDER, 1)  -- top
    if i > 1 then
      Draw.line(dl, x1, y1, x1, y2, TAB_BORDER, 1)  -- left
    end
    if i == tab_count then
      Draw.line(dl, x2, y1, x2, y2, TAB_BORDER, 1)  -- right
    end
    
    -- Bottom border for inactive tabs
    if not is_active then
      Draw.line(dl, x1, y2, x2, y2, TAB_BORDER, 1)
    else
      active_tab_rect = {x1 = x1, x2 = x2, y = y2}
    end
    
    -- Tab text
    local text = tab.id or "Tab " .. i
    local text_color = is_active and TAB_TEXT_ACTIVE or TAB_TEXT_INACTIVE
    Draw.centered_text(ctx, text, x1, y1, x2, y2, text_color)
  end
  
  -- Active tab underline continuation
  if active_tab_rect then
    local bottom_y = Draw.snap(cursor_y + height)
    
    -- Lines to left and right of active tab
    if active_tab_rect.x1 > cursor_x then
      Draw.line(dl, cursor_x, bottom_y, active_tab_rect.x1 - 1, bottom_y, TAB_BORDER, 1)
    end
    if active_tab_rect.x2 < cursor_x + win_w then
      Draw.line(dl, active_tab_rect.x2 + 1, bottom_y, cursor_x + win_w, bottom_y, TAB_BORDER, 1)
    end
    
    -- Active tab bottom fill
    Draw.rect_filled(dl, active_tab_rect.x1, bottom_y - 1, active_tab_rect.x2, bottom_y + 1, TAB_ACTIVE_BG, 0)
  end
  
  ImGui.SetCursorScreenPos(ctx, Draw.snap(cursor_x), Draw.snap(cursor_y + height))
  ImGui.PopFont(ctx)
end

return M