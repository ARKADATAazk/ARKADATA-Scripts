-- tabs/assembler/packages_mm.lua

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local M = {}

local function ensure_excl_table(core, pkgId)
  core.pkg.excl[pkgId] = core.pkg.excl[pkgId] or {}
  return core.pkg.excl[pkgId]
end

local function draw_core(ctx, core, P, mm)
  ImGui.SetNextItemWidth(ctx, 220)
  local ch_s, new_q = ImGui.InputText(ctx, 'Search##mm', mm.search or '')
  if ch_s then mm.search = new_q end
  ImGui.SameLine(ctx)
  if ImGui.Button(ctx, 'Close##mm') then mm.open=false; mm.pkgId=nil end

  local excl = ensure_excl_table(core, P.id)
  if ImGui.Button(ctx, 'Select all##mm') then
    for _,k in ipairs(P.keys_order) do if (mm.search=='' or k:find(mm.search,1,true)) then mm.multi[k]=true end end
  end
  ImGui.SameLine(ctx)
  if ImGui.Button(ctx, 'Clear selection##mm') then mm.multi = {} end
  ImGui.SameLine(ctx)
  if ImGui.Button(ctx, 'Include selected') then
    for key,sel in pairs(mm.multi) do if sel then excl[key]=nil end end
    if core.deps.settings then core.deps.settings:set('pkg_exclusions', core.pkg.excl) end
  end
  ImGui.SameLine(ctx)
  if ImGui.Button(ctx, 'Exclude selected') then
    for key,sel in pairs(mm.multi) do if sel then excl[key]=true end end
    if core.deps.settings then core.deps.settings:set('pkg_exclusions', core.pkg.excl) end
  end
  ImGui.SameLine(ctx)
  if ImGui.Button(ctx, 'Pin selected to this package') then
    for key,sel in pairs(mm.multi) do if sel then core.pkg.pins[key]=P.id end end
    if core.deps.settings then core.deps.settings:set('pkg_pins', core.pkg.pins) end
  end

  local flags = core.bor(core.flags.TBL_BORDERS, core.flags.TBL_ROWBG, core.flags.TBL_STRETCH)
  if ImGui.BeginTable(ctx, 'mm_table##'..P.id, 4, flags) then
    ImGui.TableSetupColumn(ctx, 'Sel',     core.flags.COL_WIDTH_FIXED, 36)
    ImGui.TableSetupColumn(ctx, 'Include', core.flags.COL_WIDTH_FIXED, 70)
    ImGui.TableSetupColumn(ctx, 'Key')
    ImGui.TableSetupColumn(ctx, 'Pinned Provider', core.flags.COL_WIDTH_FIXED, 180)
    ImGui.TableHeadersRow(ctx)

    for _, key in ipairs(P.keys_order) do
      if (mm.search=='' or key:find(mm.search,1,true)) then
        ImGui.TableNextRow(ctx)

        ImGui.TableSetColumnIndex(ctx, 0)
        local sel = mm.multi[key] == true
        local c1, v1 = ImGui.Checkbox(ctx, '##sel-'..key, sel); if c1 then mm.multi[key] = v1 end

        ImGui.TableSetColumnIndex(ctx, 1)
        local included = excl[key] ~= true
        local c2, v2 = ImGui.Checkbox(ctx, '##inc-'..key, included)
        if c2 then
          if v2 then excl[key] = nil else excl[key] = true end
          if core.deps.settings then core.deps.settings:set('pkg_exclusions', core.pkg.excl) end
        end

        ImGui.TableSetColumnIndex(ctx, 2)
        ImGui.Text(ctx, key)

        ImGui.TableSetColumnIndex(ctx, 3)
        local current = core.pkg.pins[key] or '(none)'
        local preview = (current=='(none)') and '(none)' or current
        if ImGui.BeginCombo(ctx, '##pin-'..key, preview) then
          if ImGui.Selectable(ctx, '(none)', current=='(none)') then
            core.pkg.pins[key]=nil
            if core.deps.settings then core.deps.settings:set('pkg_pins', core.pkg.pins) end
          end
          for _, PP in ipairs(core.pkg.index) do
            if PP.assets[key] then
              local sel2 = (current == PP.id)
              if ImGui.Selectable(ctx, PP.id, sel2) then
                core.pkg.pins[key]=PP.id
                if core.deps.settings then core.deps.settings:set('pkg_pins', core.pkg.pins) end
              end
            end
          end
          ImGui.EndCombo(ctx)
        end
      end
    end
    ImGui.EndTable(ctx)
  end
end

function M.draw_window(ctx, core, mm)
  if not (mm and mm.open and mm.pkgId) then return end
  local map = {}; for _,P in ipairs(core.pkg.index) do map[P.id]=P end
  local P = map[mm.pkgId]; if not P then mm.open=false; mm.pkgId=nil; return end
  local title = ("Package • %s – Micro-manage##mmw-%s"):format(P.meta.name or P.id, P.id)
  if ImGui.Begin(ctx, title) then
    ImGui.Text(ctx, P.path or "(mock package)")
    ImGui.Separator(ctx)
    draw_core(ctx, core, P, mm)
  end
  ImGui.End(ctx)
end

return M
