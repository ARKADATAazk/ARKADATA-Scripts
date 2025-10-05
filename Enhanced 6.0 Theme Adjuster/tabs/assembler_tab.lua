-- tabs/assembler_tab.lua
-- Subtabs in a child + sticky bottom footer with centered "Assemble" button.
-- No custom styles applied; child scrollbars disabled (ImGui 0.9/0.10 compatible).

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local lifecycle_ok, lifecycle = pcall(require, 'lifecycle')
if not lifecycle_ok then
  reaper.ShowMessageBox('core/lifecycle.lua not found.', 'Assembler', 0)
  return { create = function() return { draw=function() end } end }
end

local ic_ok, ImageCache = pcall(require, 'image_cache')
if not ic_ok then
  reaper.ShowMessageBox('core/image_cache.lua not found.', 'Assembler', 0)
  return { create = function() return { draw=function() end } end }
end

local asm_ok, assembler = pcall(require, 'assembler')
if not asm_ok then
  reaper.ShowMessageBox('assembler.lua not found.', 'Assembler', 0)
  return { create = function() return { draw=function() end } end }
end

local theme_ok, theme = pcall(require, 'theme')
if not theme_ok then
  reaper.ShowMessageBox('core/theme.lua not found.', 'Assembler', 0)
  return { create = function() return { draw=function() end } end }
end

local core_mod_ok, core_mod = pcall(require, 'tabs.assembler.core')
if not core_mod_ok then
  reaper.ShowMessageBox('tabs/assembler/core.lua not found.', 'Assembler', 0)
  return { create = function() return { draw=function() end } end }
end

local ui_packages_ok, ui_packages = pcall(require, 'tabs.assembler.ui_packages')
if not ui_packages_ok then
  reaper.ShowMessageBox('tabs/assembler/ui_packages.lua not found.', 'Assembler', 0)
  return { create = function() return { draw=function() end } end }
end

local ui_assets_ok, ui_assets = pcall(require, 'tabs.assembler.ui_assets')
if not ui_assets_ok then
  reaper.ShowMessageBox('tabs/assembler/ui_assets.lua not found.', 'Assembler', 0)
  return { create = function() return { draw=function() end } end }
end

-- ---------- ImGui 0.9/0.10 compatibility ----------
local HAS_CHILD_FLAGS = (ImGui.ChildFlags_None ~= nil)

local function BeginChildCompat(ctx, id, w, h, want_border, window_flags)
  if HAS_CHILD_FLAGS then
    local child_flags = want_border and (ImGui.ChildFlags_Border) or 0
    return ImGui.BeginChild(ctx, id, w, h, child_flags, window_flags or 0)
  else
    return ImGui.BeginChild(ctx, id, w, h, want_border and true or false, window_flags or 0)
  end
end
-- --------------------------------------------------

local function clog(fmt, ...) reaper.ShowConsoleMsg(("[Assembler] "..fmt.."\n"):format(...)) end

-- Footer spacing (vertical padding around the button)
local FOOTER_PAD_V = 6   -- was 8; trimmed a bit

local M = {}

function M.create(theme_mod, settings)
  local L = lifecycle.new()
  local cache = L:register(ImageCache.new({ budget = 128 }))

  local core = core_mod.new({
    lifecycle   = L,
    image_cache = cache,
    assembler   = assembler,
    theme       = theme,
    settings    = settings,
  })

  local current_tab, last_tab = 'PACKAGES', 'PACKAGES'
  local tab_transition_alpha, tab_transition_target = 1.0, 1.0

  local function on_tab_switched()
    if core.cache and core.cache.clear then
      core.cache:clear()
      if core.cache.begin_frame then core.cache:begin_frame() end
    end
    if ui_assets.on_leave then pcall(ui_assets.on_leave, core) end
    if ui_packages.on_leave then pcall(ui_packages.on_leave, core) end
    clog("tab switch -> reset image cache + notified UIs")
    tab_transition_alpha, tab_transition_target = 0.0, 1.0
  end

  L:on_show(function()
    core.try("on_show", function()
      core.assets:rescan()
      core.pkg:scan()
    end)
  end)

  L:begin_frame(function()
    if cache and cache.begin_frame then cache:begin_frame() end
    if tab_transition_alpha < tab_transition_target then
      tab_transition_alpha = math.min(tab_transition_target, tab_transition_alpha + 0.08)
    end
  end)

  L:on_hide(function()
    core.try("on_hide", function()
      if cache and cache.clear then cache:clear() end
      if ui_packages.on_leave then pcall(ui_packages.on_leave, core) end
      if ui_assets.on_leave then pcall(ui_assets.on_leave, core) end
    end)
  end)

  local function do_assemble()
    local ok = false
    if core.assembler then
      if type(core.assembler.assemble) == 'function' then core.assembler.assemble(core); ok = true
      elseif type(core.assembler.apply) == 'function' then core.assembler.apply(core); ok = true
      elseif type(core.assembler.apply_theme) == 'function' then core.assembler.apply_theme(core); ok = true
      end
    end
    if not ok then reaper.ShowMessageBox('Assemble: no backend hooked yet (mock).', 'Assembler', 0) end
  end

  return L:export(function(ctx)
    -- Compute dynamic footer height from current frame height so there is no slack
    local frame_h = ImGui.GetFrameHeight(ctx) or 0
    local footer_h = frame_h + FOOTER_PAD_V * 2
    local avail_w = select(1, ImGui.GetContentRegionAvail(ctx)) or 0
    local avail_h = select(2, ImGui.GetContentRegionAvail(ctx)) or 0
    local child_h = math.max(0, avail_h - footer_h)

    -- Disable scrollbars in the child region
    local NO_SCROLL = ImGui.WindowFlags_NoScrollbar | ImGui.WindowFlags_NoScrollWithMouse

    if BeginChildCompat(ctx, 'assembler_content', -1, child_h, false, NO_SCROLL) then
      if ImGui.BeginTabBar(ctx, 'assembler_subtabs') then
        if ImGui.BeginTabItem(ctx, '📦 PACKAGES') then
          current_tab = 'PACKAGES'
          if last_tab ~= current_tab then on_tab_switched(); last_tab = current_tab end
          ImGui.PushStyleVar(ctx, ImGui.StyleVar_Alpha, tab_transition_alpha)
          core.try("draw_packages", function() ui_packages.draw(ctx, core) end)
          ImGui.PopStyleVar(ctx)
          ImGui.EndTabItem(ctx)
        end

        if ImGui.BeginTabItem(ctx, '🎨 ASSETS') then
          current_tab = 'ASSETS'
          if last_tab ~= current_tab then on_tab_switched(); last_tab = current_tab end
          ImGui.PushStyleVar(ctx, ImGui.StyleVar_Alpha, tab_transition_alpha)
          core.try("draw_assets", function() ui_assets.draw(ctx, core) end)
          ImGui.PopStyleVar(ctx)
          ImGui.EndTabItem(ctx)
        end

        ImGui.EndTabBar(ctx)
      end
    end
    ImGui.EndChild(ctx)

    -- Sticky footer with centered "Assemble" (default styles)
    local footer_x1, footer_y1 = ImGui.GetCursorScreenPos(ctx)
    local dl = ImGui.GetWindowDrawList(ctx)
    local region_w = select(1, ImGui.GetContentRegionAvail(ctx)) or avail_w
    local footer_x2 = footer_x1 + region_w

    -- hairline separator
    ImGui.DrawList_AddLine(dl, footer_x1, footer_y1 + 0.5, footer_x2, footer_y1 + 0.5, 0x00000055, 1)

    -- Split the exact space around the button so there’s no extra gap
    local top_pad = math.max(0, math.floor((footer_h - frame_h) / 2))
    local bot_pad = math.max(0, footer_h - frame_h - top_pad)

    ImGui.Dummy(ctx, 1, top_pad)

    local label = 'Assemble'
    local tw = select(1, ImGui.CalcTextSize(ctx, label)) or 0
    local approx_btn_w = tw + 32
    local center_x = math.max(0, (region_w - approx_btn_w) // 2)
    ImGui.SetCursorPosX(ctx, ImGui.GetCursorPosX(ctx) + center_x)

    if ImGui.Button(ctx, label) then core.try("assemble", do_assemble) end

    ImGui.Dummy(ctx, 1, bot_pad)
  end)
end

return M
