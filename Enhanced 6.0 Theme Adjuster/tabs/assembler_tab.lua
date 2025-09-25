-- tabs/assembler_tab.lua
-- Assembler tab with gfx_image_cache + reaper_img_handler for 9-slice 3-state rendering

local lifecycle_ok, lifecycle = pcall(require, 'lifecycle')
if not lifecycle_ok then
  reaper.ShowMessageBox('core/lifecycle.lua not found.', 'Assembler', 0)
  return { create = function() return { draw=function() end } end }
end

local gfx_cache_ok, GfxImageCache = pcall(require, 'gfx_image_cache')
if not gfx_cache_ok then
  reaper.ShowMessageBox('core/gfx_image_cache.lua not found.', 'Assembler', 0)
  return { create = function() return { draw=function() end } end }
end

local asm_ok, assembler = pcall(require, 'assembler')
if not asm_ok then
  reaper.ShowMessageBox('assembler.lua not found.', 'Assembler', 0)
  return { create = function() return { draw=function() end } end }
end

local rih_ok, RIH = pcall(require, 'reaper_img_handler')
if not rih_ok then
  reaper.ShowMessageBox('reaper_img_handler.lua not found.', 'Assembler', 0)
  return { create = function() return { draw=function() end } end }
end

local SEP = package.config:sub(1,1)
local function join(a,b) return (a:sub(-1)==SEP) and (a..b) or (a..SEP..b) end
local function flag(f) return (type(f)=="function") and f() or 0 end

local function sorted_keys(t)
  local k = {}
  for key in pairs(t or {}) do k[#k+1] = key end
  table.sort(k, function(a,b) return tostring(a):lower() < tostring(b):lower() end)
  return k
end

local function tooltip(ctx, text)
  if reaper.ImGui_IsItemHovered(ctx) then
    reaper.ImGui_SetTooltip(ctx, text or "")
  end
end

local M = {}

function M.create(theme, settings)
  local L = lifecycle.new()

  local selections   = assembler.load_selections() or {}
  local variants     = {}
  local elements     = {}

  local card_size           = (settings and settings:get('card_size', 112)) or 112
  local grid_size           = (settings and settings:get('grid_size', 96))  or 96
  local show_original_sizes = (settings and settings:get('show_original_sizes', false)) or false

  local cache = L:register( GfxImageCache.new({ budget = 96 }) )
  RIH.attach_cache(cache)

  local function get_roots()
    local roots = {}
    local dir = theme.prepare_images(false)
    if dir then roots[#roots+1] = join(dir, 'Assembler') end
    return roots
  end

  local function refresh_variants()
    variants = assembler.scan_variants(get_roots()) or {}
    elements = sorted_keys(variants)
    RIH.clear()
    if cache and cache.clear then cache:clear() end
    collectgarbage('collect')
  end

  refresh_variants()

  local function element_thumbnail_path(el)
    if selections[el] and selections[el].path then return selections[el].path end
    local list = variants[el]
    if not list or not list[1] then return nil end
    return list[1].path
  end

  local function draw_card_image(ctx, path, size, state)
    if not path or path=="" then
      reaper.ImGui_Dummy(ctx, size or 16, size or 16)
      return
    end
    RIH.img(ctx, path, size or card_size, state or 0)
  end

  local function draw_native_image(ctx, path, state)
    if not path or path=="" then
      reaper.ImGui_Dummy(ctx, 16, 16)
      return
    end
    RIH.img_native(ctx, path, state or 0)
  end

  local function open_popup(ctx, el)
    reaper.ImGui_OpenPopup(ctx, 'Gallery##asm_' .. el)
  end

  local function draw_element_card(ctx, el)
    local list   = variants[el] or {}
    local chosen = element_thumbnail_path(el)

    if show_original_sizes and chosen and chosen ~= "" then
      draw_native_image(ctx, chosen, 0)
    else
      draw_card_image(ctx, chosen, card_size, 0)
    end

    local tip = "default (no override)"
    if selections[el] and selections[el].path then
      tip = selections[el].path:match("[^\\/]+$") or selections[el].path
    elseif chosen then
      tip = chosen:match("[^\\/]+$") or chosen
    end
    tooltip(ctx, tip)

    if reaper.ImGui_IsItemClicked(ctx) then
      open_popup(ctx, el)
    end

    if reaper.ImGui_BeginPopup(ctx, 'Gallery##asm_' .. el) then
      reaper.ImGui_Text(ctx, 'Choose variant for: ' .. el)
      reaper.ImGui_SameLine(ctx)
      reaper.ImGui_SetNextItemWidth(ctx, 140)
      local changed, new_sz = reaper.ImGui_SliderInt(ctx, 'Cell', grid_size, 64, 192)
      if changed then
        grid_size = new_sz
        if settings then settings:set('grid_size', grid_size) end
        RIH.clear()
      end
      reaper.ImGui_Separator(ctx)

      local avail = select(1, reaper.ImGui_GetContentRegionAvail(ctx)) or 0
      local cols  = math.max(1, math.floor(avail / (grid_size + 12)))
      local tbl_flags = flag(reaper.ImGui_TableFlags_NoBordersInBody) | flag(reaper.ImGui_TableFlags_SizingStretchSame)

      local should_close_popup = false
      local clicked_variant = nil
      
      local table_began = reaper.ImGui_BeginTable(ctx, 'grid##' .. el, cols, tbl_flags)
      if table_began then
        local table_ok, table_err = pcall(function()
          local idx = 0
          for _, v in ipairs(list) do
            if idx % cols == 0 then reaper.ImGui_TableNextRow(ctx) end
            reaper.ImGui_TableNextColumn(ctx)

            draw_card_image(ctx, v.path, grid_size, 0)
            tooltip(ctx, (v.name or '?') .. '.png')

            if reaper.ImGui_IsItemClicked(ctx) then
              clicked_variant = v
              should_close_popup = true
            end

            reaper.ImGui_PushTextWrapPos(ctx, reaper.ImGui_GetCursorPosX(ctx) + grid_size)
            reaper.ImGui_Text(ctx, v.name or "?")
            reaper.ImGui_PopTextWrapPos(ctx)

            idx = idx + 1
          end
        end)
        
        reaper.ImGui_EndTable(ctx)
        
        if not table_ok then
          reaper.ImGui_Text(ctx, "Grid error: " .. tostring(table_err))
        end
      end
      
      if clicked_variant then
        selections[el] = { path = clicked_variant.path, dest = (el or "element") .. ".png" }
        assembler.save_selections(selections)
        RIH.clear()
      end

      reaper.ImGui_Separator(ctx)
      if reaper.ImGui_Button(ctx, 'Clear selection') then
        selections[el] = nil
        assembler.save_selections(selections)
        should_close_popup = true
        RIH.clear()
      end
      reaper.ImGui_SameLine(ctx)
      if reaper.ImGui_Button(ctx, 'Close') then
        should_close_popup = true
      end
      
      if should_close_popup then
        reaper.ImGui_CloseCurrentPopup(ctx)
      end

      reaper.ImGui_EndPopup(ctx)
    end
  end

  return L:export(function(ctx, _state)
    if cache and cache.begin_frame then cache:begin_frame() end

    if reaper.ImGui_Button(ctx, 'Apply / Repack Theme') then
      local info = theme.get_theme_info()
      local status, dir = theme.get_status()
      local tinfo
      if status == 'direct' then
        tinfo = { mode='direct', ui_dir=dir, themes_dir=info.themes_dir, theme_name=info.theme_name }
      elseif status == 'linked-ready' or status == 'zip-ready' then
        tinfo = { mode='zip', cache_dir=dir, themes_dir=info.themes_dir, theme_name=info.theme_name }
      else
        reaper.ShowMessageBox('No image source. Link a .ReaperThemeZip first (use status bar or Debug tab).', 'Assembler', 0)
        return
      end
      local ok, msg = assembler.apply(tinfo, selections)
      reaper.ShowMessageBox(ok and ('OK: '..(msg or 'done')) or ('Failed: '..tostring(msg)), 'Assembler', 0)
    end

    reaper.ImGui_SameLine(ctx)
    if reaper.ImGui_Button(ctx, 'Rescan Assembler Folder') then
      refresh_variants()
    end

    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_SetNextItemWidth(ctx, 160)
    local ch1, new_card = reaper.ImGui_SliderInt(ctx, 'Card size', card_size, 96, 192)
    if ch1 then
      card_size = new_card
      if settings then settings:set('card_size', card_size) end
      RIH.clear()
    end

    reaper.ImGui_SameLine(ctx)
    local ch2, new_flag = reaper.ImGui_Checkbox(ctx, 'Show original image sizes', show_original_sizes)
    if ch2 then
      show_original_sizes = new_flag
      if settings then settings:set('show_original_sizes', show_original_sizes) end
      RIH.clear()
    end

    reaper.ImGui_Separator(ctx)

    if #elements == 0 then
      reaper.ImGui_Text(ctx, 'No elements found in theme Assembler folder.')
      reaper.ImGui_BulletText(ctx, 'Expected: <theme>/ui_img/Assembler/<element>/<variant>.png')
      return
    end

    local avail = select(1, reaper.ImGui_GetContentRegionAvail(ctx)) or 0
    local cols  = math.max(1, math.floor(avail / (card_size + 24)))
    local tbl_flags = flag(reaper.ImGui_TableFlags_NoBordersInBody) | flag(reaper.ImGui_TableFlags_SizingStretchSame)

    local main_table_began = reaper.ImGui_BeginTable(ctx, 'cards', cols, tbl_flags)
    if main_table_began then
      local main_ok, main_err = pcall(function()
        for i, el in ipairs(elements) do
          if (i-1) % cols == 0 then reaper.ImGui_TableNextRow(ctx) end
          reaper.ImGui_TableNextColumn(ctx)
          draw_element_card(ctx, el)
        end
      end)
      
      reaper.ImGui_EndTable(ctx)
      
      if not main_ok then
        reaper.ImGui_Text(ctx, "Main grid error: " .. tostring(main_err))
      end
    end
  end)
end

return M