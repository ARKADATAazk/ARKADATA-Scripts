-- ReArkitekt/gui/widgets/package_tiles/micromanage.lua
-- Package micromanagement window for fine-grained asset control

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local M = {}

local state = {
  open = false,
  pkg_id = nil,
  search = "",
  multi_selection = {},
}

-- Open the micromanage window for a specific package
function M.open(pkg_id)
  state.open = true
  state.pkg_id = pkg_id
  state.search = ""
  state.multi_selection = {}
end

-- Close the micromanage window
function M.close()
  state.open = false
  state.pkg_id = nil
end

-- Check if window is open
function M.is_open()
  return state.open
end

-- Get current package ID
function M.get_package_id()
  return state.pkg_id
end

-- Draw the micromanage window
function M.draw_window(ctx, pkg, settings)
  if not state.open or not state.pkg_id then return end
  
  local P = nil
  for _, package in ipairs(pkg.index) do
    if package.id == state.pkg_id then
      P = package
      break
    end
  end
  
  if not P then
    M.close()
    return
  end
  
  local title = string.format("Package • %s — Micro-manage##mmw-%s", P.meta.name or P.id, P.id)
  if ImGui.Begin(ctx, title) then
    ImGui.Text(ctx, P.path or "(package)")
    ImGui.Separator(ctx)
    
    -- Search and close button
    ImGui.SetNextItemWidth(ctx, 220)
    local ch_s, new_q = ImGui.InputText(ctx, 'Search##mm', state.search or '')
    if ch_s then state.search = new_q end
    ImGui.SameLine(ctx)
    if ImGui.Button(ctx, 'Close##mm') then 
      M.close()
    end
    
    -- Selection controls
    if ImGui.Button(ctx, 'Select all##mm') then
      for _, k in ipairs(P.keys_order) do 
        if (state.search == '' or k:find(state.search, 1, true)) then 
          state.multi_selection[k] = true 
        end 
      end
    end
    ImGui.SameLine(ctx)
    if ImGui.Button(ctx, 'Clear selection##mm') then 
      state.multi_selection = {} 
    end
    
    ImGui.Separator(ctx)
    
    -- Asset table
    local tbl_flags = ImGui.TableFlags_Borders | ImGui.TableFlags_RowBg | ImGui.TableFlags_ScrollY
    if ImGui.BeginTable(ctx, 'mm_table##' .. P.id, 3, tbl_flags) then
      ImGui.TableSetupScrollFreeze(ctx, 0, 1)
      ImGui.TableSetupColumn(ctx, 'Sel', ImGui.TableColumnFlags_WidthFixed, 36)
      ImGui.TableSetupColumn(ctx, 'Asset')
      ImGui.TableSetupColumn(ctx, 'Status', ImGui.TableColumnFlags_WidthFixed, 80)
      ImGui.TableHeadersRow(ctx)
      
      for _, key in ipairs(P.keys_order) do
        if (state.search == '' or key:find(state.search, 1, true)) then
          ImGui.TableNextRow(ctx)
          
          ImGui.TableSetColumnIndex(ctx, 0)
          local sel = state.multi_selection[key] == true
          local c1, v1 = ImGui.Checkbox(ctx, '##sel-' .. key, sel)
          if c1 then state.multi_selection[key] = v1 end
          
          ImGui.TableSetColumnIndex(ctx, 1)
          ImGui.Text(ctx, key)
          
          ImGui.TableSetColumnIndex(ctx, 2)
          ImGui.TextDisabled(ctx, "Active")
        end
      end
      
      ImGui.EndTable(ctx)
    end
  end
  ImGui.End(ctx)
end

-- Reset state (useful for cleanup)
function M.reset()
  state.open = false
  state.pkg_id = nil
  state.search = ""
  state.multi_selection = {}
end

return M