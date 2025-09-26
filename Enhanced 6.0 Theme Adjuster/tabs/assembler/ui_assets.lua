-- tabs/assembler/ui_assets.lua
-- Assets gallery (popup picker, stale-handle fix) scanning under /Assembler/Assets/
-- CHANGE: expose M.on_leave(core) to drop popups + clear image handles on tab switch.

local M = {}

local SEP = package.config:sub(1,1)
local function join(a,b) return (a:sub(-1)==SEP) and (a..b) or (a..SEP..b) end
local function flag(f) return (type(f)=="function") and f() or 0 end
local function tooltip(ctx, text) if reaper.ImGui_IsItemHovered(ctx) then reaper.ImGui_SetTooltip(ctx, text or "") end end

local function sorted_keys(t)
  local k = {}
  for key in pairs(t or {}) do k[#k+1] = key end
  table.sort(k, function(a,b) return tostring(a):lower() < tostring(b):lower() end)
  return k
end

-- UI-only state
local active_popup = nil

local function get_roots(theme)
  local roots = {}
  local dir = theme.prepare_images(false)
  if dir then roots[#roots+1] = join(join(dir, 'Assembler'), 'Assets') end
  return roots
end

local function refresh_variants(core)
  local assembler = core.deps.assembler
  local theme     = core.deps.theme
  local cache     = core.cache
  local assets    = core.assets

  assets.variants = assembler.scan_variants(get_roots(theme)) or {}
  assets.elements = sorted_keys(assets.variants)

  if cache and cache.clear then
    cache:clear()
    if cache.begin_frame then cache:begin_frame() end
  end
  collectgarbage('collect')
end

local function open_gallery_popup(ctx, core, el)
  local cache = core.cache
  if cache then
    cache:clear()
    cache:begin_frame()
  end
  active_popup = el
  reaper.ImGui_OpenPopup(ctx, 'Gallery##' .. el)
end

local function close_gallery_popup(core)
  local cache = core.cache
  if cache then
    cache:clear()
    cache:begin_frame()
  end
  active_popup = nil
  collectgarbage('collect')
end

local function element_thumbnail_path(core, el)
  local assets = core.assets
  if assets.selections[el] and assets.selections[el].path then
    return assets.selections[el].path
  end
  local list = assets.variants[el]
  if not list or not list[1] then return nil end
  return list[1].path
end

local function draw_element_card(ctx, core, el)
  local assets = core.assets
  local cache  = core.cache

  local chosen = element_thumbnail_path(core, el)
  if chosen and chosen ~= "" then
    if assets.show_original_sizes then
      cache:draw_original(ctx, chosen)
    else
      cache:draw_thumb(ctx, chosen, assets.card)
    end
  else
    reaper.ImGui_Dummy(ctx, assets.card, assets.card)
  end

  local tip = "Click to choose variant"
  if assets.selections[el] and assets.selections[el].path then
    tip = assets.selections[el].path:match("[^\\/]+$") or assets.selections[el].path
  elseif chosen then
    tip = (chosen:match("[^\\/]+$") or chosen) .. " (default)"
  end
  tooltip(ctx, tip)

  if reaper.ImGui_IsItemClicked(ctx) then
    open_gallery_popup(ctx, core, el)
  end

  -- Popup contents
  if reaper.ImGui_BeginPopup(ctx, 'Gallery##' .. el) then
    reaper.ImGui_Text(ctx, 'Choose variant for: ' .. el)
    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_SetNextItemWidth(ctx, 140)

    local assets_grid = assets.grid
    local changed, new_sz = reaper.ImGui_SliderInt(ctx, 'Cell', assets_grid, 64, 192)
    if changed then
      assets.grid = new_sz
      local s = core.deps.settings
      if s then s:set('grid_size', assets.grid) end
    end

    reaper.ImGui_SameLine(ctx)
    local ch_gal, new_gal = reaper.ImGui_Checkbox(ctx, 'Original sizes', assets.gallery_original_sizes)
    if ch_gal then
      assets.gallery_original_sizes = new_gal
      local s = core.deps.settings
      if s then s:set('gallery_original_sizes', assets.gallery_original_sizes) end
    end

    reaper.ImGui_Separator(ctx)

    local list  = assets.variants[el] or {}
    local avail = select(1, reaper.ImGui_GetContentRegionAvail(ctx)) or 0
    local cols  = math.max(1, math.floor(avail / (assets.grid + 12)))
    if assets.gallery_original_sizes then cols = math.max(1, math.floor(avail / 180)) end

    local tbl_flags = flag(reaper.ImGui_TableFlags_NoBordersInBody) | flag(reaper.ImGui_TableFlags_SizingStretchSame)

    local clicked_variant = nil
    local should_close = false

    if reaper.ImGui_BeginTable(ctx, 'grid##' .. el, cols, tbl_flags) then
      for idx, v in ipairs(list) do
        if (idx - 1) % cols == 0 then reaper.ImGui_TableNextRow(ctx) end
        reaper.ImGui_TableNextColumn(ctx)

        if assets.gallery_original_sizes then
          cache:draw_original(ctx, v.path)
        else
          cache:draw_thumb(ctx, v.path, assets.grid)
        end

        tooltip(ctx, (v.name or "?") .. '.png')

        if reaper.ImGui_IsItemClicked(ctx) then
          clicked_variant = v
          should_close = true
        end

        reaper.ImGui_PushTextWrapPos(ctx, reaper.ImGui_GetCursorPosX(ctx) + assets.grid)
        reaper.ImGui_Text(ctx, v.name or "?")
        reaper.ImGui_PopTextWrapPos(ctx)
      end
      reaper.ImGui_EndTable(ctx)
    end

    if clicked_variant then
      assets.selections[el] = { path = clicked_variant.path, dest = (el or "element") .. ".png" }
      core.deps.assembler.save_selections(assets.selections)
    end

    reaper.ImGui_Separator(ctx)

    if reaper.ImGui_Button(ctx, 'Clear selection') then
      assets.selections[el] = nil
      core.deps.assembler.save_selections(assets.selections)
      should_close = true
    end

    reaper.ImGui_SameLine(ctx)
    if reaper.ImGui_Button(ctx, 'Close') then
      should_close = true
    end

    if should_close then
      reaper.ImGui_CloseCurrentPopup(ctx)
      close_gallery_popup(core)
    end

    reaper.ImGui_EndPopup(ctx)
  else
    if active_popup == el then
      close_gallery_popup(core)
    end
  end
end

function M.draw(ctx, core)
  local assembler = core.deps.assembler
  local theme     = core.deps.theme
  local settings  = core.deps.settings
  local assets    = core.assets
  local cache     = core.cache

  if cache and cache.begin_frame then cache:begin_frame() end

  -- toolbar
  if reaper.ImGui_Button(ctx, 'Apply / Repack Theme') then
    core.try("apply_theme", function()
      local info = theme.get_theme_info()
      local status, dir = theme.get_status()
      local tinfo
      if status == 'direct' then
        tinfo = { mode='direct', ui_dir=dir, themes_dir=info.themes_dir, theme_name=info.theme_name }
      elseif status == 'linked-ready' or status == 'zip-ready' then
        tinfo = { mode='zip', cache_dir=dir, themes_dir=info.themes_dir, theme_name=info.theme_name }
      else
        reaper.ShowMessageBox('No image source. Link a .ReaperThemeZip first.', 'Assembler', 0)
        return
      end
      local ok, msg = assembler.apply(tinfo, assets.selections)
      reaper.ShowMessageBox(ok and ('Success: '..(msg or 'done')) or ('Failed: '..tostring(msg)), 'Assembler', 0)
    end)
  end

  reaper.ImGui_SameLine(ctx)
  if reaper.ImGui_Button(ctx, 'Rescan Assembler Folder') then
    refresh_variants(core) -- scans /Assembler/Assets/
  end

  reaper.ImGui_SameLine(ctx)
  reaper.ImGui_SetNextItemWidth(ctx, 160)
  local ch, new_card = reaper.ImGui_SliderInt(ctx, 'Card size', assets.card, 64, 192)
  if ch then
    assets.card = new_card
    if settings then settings:set('card_size', assets.card) end
  end

  reaper.ImGui_SameLine(ctx)
  local ch2, new_orig = reaper.ImGui_Checkbox(ctx, 'Original sizes', assets.show_original_sizes)
  if ch2 then
    assets.show_original_sizes = new_orig
    if settings then settings:set('show_original_sizes', assets.show_original_sizes) end
  end

  reaper.ImGui_Separator(ctx)

  if #assets.elements == 0 then
    reaper.ImGui_Text(ctx, 'No elements found in Assembler/Assets.')
    reaper.ImGui_BulletText(ctx, 'Expected: <theme>/ui_img/Assembler/Assets/<element>/<variant>.png')
    return
  end

  local avail = select(1, reaper.ImGui_GetContentRegionAvail(ctx)) or 0
  local cols = math.max(1, math.floor(avail / (assets.card + 24)))
  if assets.show_original_sizes then cols = math.max(1, math.floor(avail / 180)) end

  local tbl_flags = flag(reaper.ImGui_TableFlags_NoBordersInBody) | flag(reaper.ImGui_TableFlags_SizingStretchSame)

  if reaper.ImGui_BeginTable(ctx, 'cards', cols, tbl_flags) then
    for i, el in ipairs(assets.elements) do
      if (i - 1) % cols == 0 then reaper.ImGui_TableNextRow(ctx) end
      reaper.ImGui_TableNextColumn(ctx)
      draw_element_card(ctx, core, el)
    end
    reaper.ImGui_EndTable(ctx)
  end
end

-- NEW: called by the shell when leaving this tab
function M.on_leave(core)
  -- close popups & invalidate any stale ImGui_Image handles
  active_popup = nil
  if core.cache and core.cache.clear then
    core.cache:clear()
    if core.cache.begin_frame then core.cache:begin_frame() end
  end
end

return M
