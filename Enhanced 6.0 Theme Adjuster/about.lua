-- core/about.lua
-- About dialog for Enhanced 6.0 Theme Adjuster

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
    reaper.ImGui_SetNextWindowSize(ctx, win_w, win_h, reaper.ImGui_Cond_Always())
    
    local center_x = state.parent_x + (state.parent_w - win_w) / 2
    local center_y = state.parent_y + (state.parent_h - win_h) / 2
    reaper.ImGui_SetNextWindowPos(ctx, center_x, center_y, reaper.ImGui_Cond_Appearing())
    
    local flags = (reaper.ImGui_WindowFlags_NoCollapse and reaper.ImGui_WindowFlags_NoCollapse() or 0)
    if reaper.ImGui_WindowFlags_NoResize then
      flags = flags | reaper.ImGui_WindowFlags_NoResize()
    end
    if reaper.ImGui_WindowFlags_TopMost then
      flags = flags | reaper.ImGui_WindowFlags_TopMost()
    end
    if reaper.ImGui_WindowFlags_NoScrollbar then
      flags = flags | reaper.ImGui_WindowFlags_NoScrollbar()
    end
    
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowPadding(), 20, 20)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(), 8, 7)
    
    if state.fonts and state.fonts.title then
      reaper.ImGui_PushFont(ctx, state.fonts.title.face, state.fonts.title.size)
    end
    
    local visible, open = reaper.ImGui_Begin(ctx, 'About##aboutdlg', true, flags)
    
    if state.fonts and state.fonts.title then
      reaper.ImGui_PopFont(ctx)
    end
    
    reaper.ImGui_PopStyleVar(ctx, 1)
    state.is_open = open
    
    if visible then
      if state.fonts and state.fonts.default then
        reaper.ImGui_PushFont(ctx, state.fonts.default.face, 12)
      end
      
      reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), C.teal or 0x41E0A3FF)
      reaper.ImGui_Text(ctx, v.app_name)
      reaper.ImGui_PopStyleColor(ctx, 1)
      
      reaper.ImGui_Text(ctx, ('Version %s'):format(v.app_version))
      
      reaper.ImGui_Dummy(ctx, 0, 12)
      reaper.ImGui_Separator(ctx)
      reaper.ImGui_Dummy(ctx, 0, 12)
      
      reaper.ImGui_Text(ctx, 'By ARKADATA (Pierre Daunis)')
      
      reaper.ImGui_Dummy(ctx, 0, 8)
      
      reaper.ImGui_TextWrapped(ctx, 
        'Inspired by WhiteTie\'s Theme Adjuster and Theme Assembler.')
      
      reaper.ImGui_Dummy(ctx, 0, 8)
      
      reaper.ImGui_TextWrapped(ctx,
        'Made for reARK theme with ReaperTip in mind (rtconfig by FeedTheCat).')
      
      reaper.ImGui_Dummy(ctx, 0, 8)
      
      reaper.ImGui_TextWrapped(ctx,
        'Works with any REAPER Theme 6.0 variation. Feel free to adapt the code to fit your needs and use it as a baseline to build your own theme assembler.')
      
      reaper.ImGui_Dummy(ctx, 0, 12)
      reaper.ImGui_Separator(ctx)
      reaper.ImGui_Dummy(ctx, 0, 12)
      
      reaper.ImGui_TextWrapped(ctx,
        'Licensed under CC BY-NC-SA 4.0 International License.')
      reaper.ImGui_TextWrapped(ctx,
        'Free to use and modify with attribution for non-commercial purposes.')
      
      reaper.ImGui_Dummy(ctx, 0, 16)
      
      local btn_w = 80
      local avail_w = select(1, reaper.ImGui_GetContentRegionAvail(ctx)) or 0
      reaper.ImGui_SetCursorPosX(ctx, (avail_w - btn_w) / 2 + 20)
      
      if reaper.ImGui_Button(ctx, 'Close##aboutdlg', btn_w, 0) then
        state.is_open = false
      end
      
      reaper.ImGui_Dummy(ctx, 0, 0)
      
      if state.fonts and state.fonts.default then
        reaper.ImGui_PopFont(ctx)
      end
      
      reaper.ImGui_End(ctx)
    end
    
    reaper.ImGui_PopStyleVar(ctx, 1)
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