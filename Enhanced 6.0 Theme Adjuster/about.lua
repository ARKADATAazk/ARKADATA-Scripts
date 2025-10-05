-- core/about.lua
-- About dialog for Enhanced 6.0 Theme Adjuster

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local M = {}

function M.create(theme)
  local style = require('style')
  local C = (style and style.palette) or {}
  
  local state = {
    is_open = false,
    ctx = nil,
    fonts = nil,
    parent_x = 0,
    parent_y = 0,
    parent_w = 800,
    parent_h = 600,
  }
  
  local function get_version_info()
    return {
      app_name    = 'Enhanced 6.0 Theme Adjuster',
      app_version = '1.0',
    }
  end
  
  local function draw_window(ctx)
    if not state.is_open then return end
    
    local v = get_version_info()
    
    local win_w, win_h = 480, 320
    ImGui.SetNextWindowSize(ctx, win_w, win_h, ImGui.Cond_Always)
    
    local center_x = state.parent_x + (state.parent_w - win_w) / 2
    local center_y = state.parent_y + (state.parent_h - win_h) / 2
    ImGui.SetNextWindowPos(ctx, center_x, center_y, ImGui.Cond_Appearing)
    
    local flags = (ImGui.WindowFlags_NoCollapse and ImGui.WindowFlags_NoCollapse or 0)
    if ImGui.WindowFlags_NoResize then
      flags = flags | ImGui.WindowFlags_NoResize
    end
    if ImGui.WindowFlags_TopMost then
      flags = flags | ImGui.WindowFlags_TopMost
    end
    if ImGui.WindowFlags_NoScrollbar then
      flags = flags | ImGui.WindowFlags_NoScrollbar
    end
    
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding, 20, 20)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 8, 7)
    
    if state.fonts and state.fonts.title then
      ImGui.PushFont(ctx, state.fonts.title.face)
    end
    
    local visible, open = ImGui.Begin(ctx, 'About##aboutdlg', true, flags)
    
    if state.fonts and state.fonts.title then
      ImGui.PopFont(ctx)
    end
    
    ImGui.PopStyleVar(ctx, 1)
    state.is_open = open
    
    if visible then
      if state.fonts and state.fonts.default then
        ImGui.PushFont(ctx, state.fonts.default.face)
      end
      
      ImGui.PushStyleColor(ctx, ImGui.Col_Text, C.teal or 0x41E0A3FF)
      ImGui.Text(ctx, v.app_name)
      ImGui.PopStyleColor(ctx, 1)
      
      ImGui.Text(ctx, ('Version %s'):format(v.app_version))
      
      ImGui.Dummy(ctx, 0, 12)
      ImGui.Separator(ctx)
      ImGui.Dummy(ctx, 0, 12)
      
      ImGui.Text(ctx, 'By ARKADATA (Pierre Daunis)')
      
      ImGui.Dummy(ctx, 0, 8)
      
      ImGui.TextWrapped(ctx, 
        'Inspired by WhiteTie\'s Theme Adjuster and Theme Assembler.')
      
      ImGui.Dummy(ctx, 0, 8)
      
      ImGui.TextWrapped(ctx,
        'Made for reARK theme with ReaperTip in mind (rtconfig by FeedTheCat).')
      
      ImGui.Dummy(ctx, 0, 8)
      
      ImGui.TextWrapped(ctx,
        'Works with any REAPER Theme 6.0 variation. Feel free to adapt the code to fit your needs and use it as a baseline to build your own theme assembler.')
      
      ImGui.Dummy(ctx, 0, 12)
      ImGui.Separator(ctx)
      ImGui.Dummy(ctx, 0, 12)
      
      ImGui.TextWrapped(ctx,
        'Licensed under CC BY-NC-SA 4.0 International License.')
      ImGui.TextWrapped(ctx,
        'Free to use and modify with attribution for non-commercial purposes.')
      
      ImGui.Dummy(ctx, 0, 16)
      
      local btn_w = 80
      local avail_w = select(1, ImGui.GetContentRegionAvail(ctx)) or 0
      ImGui.SetCursorPosX(ctx, (avail_w - btn_w) / 2 + 20)
      
      if ImGui.Button(ctx, 'Close##aboutdlg', btn_w, 0) then
        state.is_open = false
      end
      
      ImGui.Dummy(ctx, 0, 0)
      
      if state.fonts and state.fonts.default then
        ImGui.PopFont(ctx)
      end
      
      ImGui.End(ctx)
    end
    
    ImGui.PopStyleVar(ctx, 1)
  end
  
  local function show(ctx, use_window, fonts, parent_x, parent_y, parent_w, parent_h)
    if use_window then
      state.ctx = ctx
      state.fonts = fonts
      state.parent_x = parent_x or 0
      state.parent_y = parent_y or 0
      state.parent_w = parent_w or 800
      state.parent_h = parent_h or 600
      state.is_open = true
    end
  end
  
  local function draw(ctx)
    if state.is_open and state.ctx then
      draw_window(ctx)
    end
  end
  
  local function is_open()
    return state.is_open
  end
  
  local function close()
    state.is_open = false
  end
  
  return {
    show     = show,
    draw     = draw,
    is_open  = is_open,
    close    = close,
  }
end

return M