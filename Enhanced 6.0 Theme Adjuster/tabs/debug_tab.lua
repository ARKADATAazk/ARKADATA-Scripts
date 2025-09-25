-- tabs/debug_tab.lua – Debug tab with streamlined theme integration
local lifecycle_ok, lifecycle = pcall(require, 'lifecycle')
if not lifecycle_ok then
  reaper.ShowMessageBox('core/lifecycle.lua not found.', 'Debug', 0)
  return { create = function() return { draw=function() end } end }
end

local ic_ok, ImageCache = pcall(require, 'image_cache')
if not ic_ok then
  reaper.ShowMessageBox('core/image_cache.lua not found.', 'Debug', 0)
  return { create = function() return { draw=function() end } end }
end

local theme = require('theme')
local style = require('style')
local C     = style and style.palette or {}

local M = {}

local function flag(f) return (type(f)=="function") and f() or 0 end

local function text_color(ctx, col_u32, s)
  if reaper.ImGui_TextColored and pcall(reaper.ImGui_TextColored, ctx, col_u32, s) then return end
  if reaper.ImGui_PushStyleColor and reaper.ImGui_Col_Text then
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), col_u32)
    reaper.ImGui_Text(ctx, s)
    reaper.ImGui_PopStyleColor(ctx, 1)
  else
    reaper.ImGui_Text(ctx, s)
  end
end

local function set_if_changed(cur, new)
  if new ~= cur then return new, true end
  return cur, false
end

function M.create(theme_mod, settings)
  local T = theme_mod or theme
  local L = lifecycle.new()

  -- State
  local s = {
    img_dir      = nil,
    list         = {},
    total        = 0,
    preview_px   = (settings and settings:get('preview_px', 96)) or 96,
    page_size    = (settings and settings:get('page_size', 120)) or 120,
    page_index   = (settings and settings:get('page_index', 1)) or 1,
    recursive    = (settings and settings:get('recursive', false)) or false,
    filter       = (settings and settings:get('filter', "")) or "",
    want_preload = {},
  }

  local thumbs = L:register( ImageCache.new({ budget = 48 }) )

  local function page_bounds()
    local N = #s.list
    if N == 0 then return 0, -1 end
    local a = (s.page_index-1) * s.page_size + 1
    local b = math.min(a + s.page_size - 1, N)
    return a, b
  end

  local function fetch_list()
    if not s.img_dir then
      s.list, s.total = {}, 0
      s.page_index = 1
      return
    end
    local prefetch_count = math.max(1, s.page_size) * 10
    local list, total = T.sample_images(s.img_dir, prefetch_count, {
      recursive = s.recursive,
      filter    = s.filter
    })
    s.list  = list  or {}
    s.total = total or 0
    if s.page_index < 1 then s.page_index = 1 end
    if thumbs then thumbs:clear() end
    s.want_preload = {}
    collectgarbage('collect')
  end

  -- Auto-detect on tab show
  L:on_show(function()
    if not s.img_dir then
      s.img_dir = T.prepare_images(false)
      if s.img_dir then fetch_list() end
    end
  end)

  -- Toolbar
  local function toolbar(ctx)
    -- Status display
    local status, dir, zip_name = T.get_status()
    if status == 'direct' and dir then
      text_color(ctx, C.teal or 0x41E0A3FF, ('READY - Direct: %s'):format(dir))
    elseif (status == 'linked-ready' or status == 'zip-ready') and dir then
      local msg = zip_name and ('READY - ZIP Cache: %s'):format(zip_name) or ('READY - ZIP Cache: %s'):format(dir)
      text_color(ctx, C.yellow or 0xE0B341FF, msg)
    elseif status == 'linked-needs-build' then
      local msg = zip_name and ('LINKED - Build needed: %s'):format(zip_name) or 'LINKED - Build cache to continue'
      text_color(ctx, C.yellow or 0xE0B341FF, msg)
    elseif status == 'needs-link' then
      text_color(ctx, C.red or 0xE04141FF, 'NOT LINKED - Pick a .ReaperThemeZip to continue')
    else
      text_color(ctx, C.red or 0xE04141FF, 'ERROR - Check theme status')
    end

    -- Controls (only trigger fetch when inputs that affect listing change)
    local changed

    reaper.ImGui_SetNextItemWidth(ctx, 140)
    changed, s.preview_px = reaper.ImGui_SliderInt(ctx, 'Preview size', s.preview_px, 48, 256)
    if changed and settings then settings:set('preview_px', s.preview_px) end

    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_SetNextItemWidth(ctx, 160)
    local new_ps
    changed, new_ps = reaper.ImGui_SliderInt(ctx, 'Items per page', s.page_size, 24, 600)
    local ps_changed
    s.page_size, ps_changed = set_if_changed(s.page_size, new_ps or s.page_size)
    if ps_changed and settings then settings:set('page_size', s.page_size) end

    reaper.ImGui_SameLine(ctx)
    local rec_changed; rec_changed, s.recursive = reaper.ImGui_Checkbox(ctx, 'Recursive', s.recursive)
    if rec_changed and settings then settings:set('recursive', s.recursive) end

    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_SetNextItemWidth(ctx, 200)
    local flt_changed
    local new_filter; flt_changed, new_filter = reaper.ImGui_InputText(ctx, 'Filter', s.filter)
    local filter_changed
    s.filter, filter_changed = set_if_changed(s.filter, new_filter or s.filter)
    if filter_changed and settings then settings:set('filter', s.filter) end

    if (ps_changed or rec_changed or filter_changed) and s.img_dir then
      s.page_index = 1
      fetch_list()
    end

    -- Paging + info
    local shown = #s.list
    local pages = math.max(1, math.ceil((shown>0 and shown or 1)/math.max(1, s.page_size)))
    if s.page_index > pages then s.page_index = pages end

    reaper.ImGui_BulletText(ctx, ('Dir: %s'):format(s.img_dir or '—'))
    reaper.ImGui_BulletText(ctx, ('Listed: %d / Total PNGs: %d — Page %d / %d'):format(
      shown, s.total, s.page_index, pages
    ))

    if reaper.ImGui_Button(ctx, '<< Prev') then
      s.page_index = math.max(1, s.page_index - 1)
      if settings then settings:set('page_index', s.page_index) end
      if thumbs then thumbs:clear() end
    end
    reaper.ImGui_SameLine(ctx)
    if reaper.ImGui_Button(ctx, 'Next >>') then
      s.page_index = math.min(pages, s.page_index + 1)
      if settings then settings:set('page_index', s.page_index) end
      if thumbs then thumbs:clear() end
    end

    reaper.ImGui_SameLine(ctx)
    if reaper.ImGui_Button(ctx, 'Preload page') and shown>0 then
      local a,b = page_bounds()
      for i=a,b do local p=s.list[i]; if p then s.want_preload[p]=true end end
    end
    reaper.ImGui_SameLine(ctx)
    if reaper.ImGui_Button(ctx, 'Unload page') and shown>0 then
      s.want_preload = {}
      if thumbs then thumbs:clear() end
      collectgarbage('collect')
    end
  end

  -- Grid
  local function grid(ctx)
    local shown = #s.list
    if shown == 0 then return end

    local cell  = math.max(48, s.preview_px)
    local avail = select(1, reaper.ImGui_GetContentRegionAvail(ctx))
    local cols  = math.max(1, math.floor(avail / (cell + 12)))
    local tbl_flags = flag(reaper.ImGui_TableFlags_NoBordersInBody) | flag(reaper.ImGui_TableFlags_SizingStretchSame)

    if reaper.ImGui_BeginTable(ctx, 'img_grid', cols, tbl_flags) then
      local a,b = page_bounds()
      local idx = 0
      for i=a,b do
        local path = s.list[i]; if not path then break end
        if idx % cols == 0 then reaper.ImGui_TableNextRow(ctx) end
        reaper.ImGui_TableNextColumn(ctx)

        if s.want_preload[path] then
          thumbs:draw_thumb(ctx, path, cell)
          s.want_preload[path] = nil
        else
          thumbs:draw_thumb(ctx, path, cell)
        end

        if reaper.ImGui_IsItemHovered(ctx) then
          local name = path:match("[^\\/]+$") or path
          reaper.ImGui_SetTooltip(ctx, name)
        end

        local name = path:match("[^\\/]+$") or path
        reaper.ImGui_Text(ctx, name)

        idx = idx + 1
      end
      reaper.ImGui_EndTable(ctx)
    end
  end

  return L:export(function(ctx, _state)
    -- Theme info
    local info = T.get_theme_info()
    reaper.ImGui_Text(ctx, 'Theme:')
    reaper.ImGui_SameLine(ctx); reaper.ImGui_Text(ctx, info.theme_name or 'Unknown')
    reaper.ImGui_BulletText(ctx, ('Path: %s'):format(info.theme_path or '—'))
    reaper.ImGui_BulletText(ctx, ('Type: %s'):format(info.theme_ext or '—'))
    reaper.ImGui_BulletText(ctx, ('REAPER: %s'):format(info.reaper_ver or '—'))

    reaper.ImGui_Separator(ctx)
    
    if reaper.ImGui_Button(ctx, 'Rescan Images##dbg') then
      if thumbs then thumbs:clear() end
      s.want_preload = {}
      s.img_dir = T.prepare_images(true)
      if s.img_dir then fetch_list() end
    end
    
    reaper.ImGui_SameLine(ctx)
    
    if reaper.ImGui_Button(ctx, 'Reload Theme in REAPER##dbg') then
      T.reload_theme_in_reaper()
      if thumbs then thumbs:clear() end
      s.want_preload = {}
      s.list, s.total = {}, 0
      s.img_dir = T.prepare_images(false)
      if s.img_dir then fetch_list() end
    end

    reaper.ImGui_Separator(ctx)
    toolbar(ctx)
    grid(ctx)
  end)
end

return M