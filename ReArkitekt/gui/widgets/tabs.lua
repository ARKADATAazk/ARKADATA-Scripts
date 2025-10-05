-- ReArkitekt/gui/widgets/tabs.lua
-- Lightweight pill tabs with underline + keyboard navigation.
-- API:
--   local Tabs = require('ReArkitekt.gui.widgets.tabs')
--   local t = Tabs.new('id', { items={ {id='a',label='A'}, ... }, initial='a', on_change=function(id) end, style={height=34, round=8, underline=true} })
--   local active = t:draw(ctx, app)

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local M = {}
M.__index = M

local function default(v, d) if v==nil then return d else return v end end

function M.new(id, opts)
  assert(type(id)=='string', 'tabs id must be string')
  opts = opts or {}
  local self = setmetatable({}, M)
  self.id = id
  self.items = opts.items or {}
  self.index = 1
  self.active = opts.initial or (self.items[1] and self.items[1].id) or nil
  if opts.initial then
    for i,it in ipairs(self.items) do if it.id == opts.initial then self.index = i; break end end
  end
  self.on_change = opts.on_change
  self.style = {
    height    = default(opts.style and opts.style.height, 34),
    round     = default(opts.style and opts.style.round, 8),
    underline = default(opts.style and opts.style.underline, true),
    spacing   = default(opts.style and opts.style.spacing, 6),
    pad_h     = default(opts.style and opts.style.pad_h, 12),
  }
  return self
end

local function is_key_pressed(ctx, key)
  return ImGui.IsKeyPressed(ctx, key, false)
end

function M:set_items(items, active_id)
  self.items = items or {}
  if active_id then self:set_active(active_id) end
end

function M:set_active(id)
  if id == self.active then return end
  self.active = id
  for i,it in ipairs(self.items) do if it.id == id then self.index = i; break end end
  if self.on_change then pcall(self.on_change, id) end
end

function M:draw(ctx, app)
  local dl = ImGui.GetWindowDrawList(ctx)
  local curx, cury = ImGui.GetCursorScreenPos(ctx)
  local h = self.style.height
  local round = self.style.round
  local spacing = self.style.spacing
  local pad_h = self.style.pad_h

  ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameRounding(), round)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding(), pad_h, (h-20)/2) -- approx vertical centering
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing(), spacing, 0)

  local start_x = ImGui.GetCursorPosX(ctx)
  local start_y = ImGui.GetCursorPosY(ctx)

  local active_rect = nil

  for i, it in ipairs(self.items) do
    ImGui.PushID(ctx, it.id or i)

    local label = it.label or it.id or ('Tab '..i)
    local is_active = (self.active == it.id)
    if is_active then
      ImGui.PushStyleColor(ctx, ImGui.Col_Button(), ImGui.GetStyleColorVec4(ctx, ImGui.Col_Header()))
      ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered(), ImGui.GetStyleColorVec4(ctx, ImGui.Col_HeaderHovered()))
      ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive(), ImGui.GetStyleColorVec4(ctx, ImGui.Col_HeaderActive()))
    else
      ImGui.PushStyleColor(ctx, ImGui.Col_Button(), ImGui.GetStyleColorVec4(ctx, ImGui.Col_FrameBg()))
      ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered(), ImGui.GetStyleColorVec4(ctx, ImGui.Col_FrameBgHovered()))
      ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive(), ImGui.GetStyleColorVec4(ctx, ImGui.Col_FrameBgActive()))
    end

    local pressed = ImGui.Button(ctx, label, 0, h)
    local x1, y1 = ImGui.GetItemRectMin(ctx)
    local x2, y2 = ImGui.GetItemRectMax(ctx)

    ImGui.PopStyleColor(ctx, 3)

    if pressed then self:set_active(it.id) end

    if is_active then active_rect = {x1=x1,y1=y1,x2=x2,y2=y2} end

    if i < #self.items then ImGui.SameLine(ctx) end
    ImGui.PopID(ctx)
  end

  if self.style.underline and active_rect then
    local ux1 = active_rect.x1 + 6
    local ux2 = active_rect.x2 - 6
    local uy  = active_rect.y2 - 2
    local col = ImGui.GetColorU32(ctx, ImGui.Col_CheckMark())
    ImGui.DrawList_AddLine(dl, ux1, uy, ux2, uy, col, 2.0)
  end

  -- Keyboard nav (when window has focus)
  if ImGui.IsWindowFocused(ctx, ImGui.FocusedFlags_ChildWindows()) then
    local left  = is_key_pressed(ctx, ImGui.Key_LeftArrow())
    local right = is_key_pressed(ctx, ImGui.Key_RightArrow())
    local home  = is_key_pressed(ctx, ImGui.Key_Home())
    local endk  = is_key_pressed(ctx, ImGui.Key_End())

    if left or right or home or endk then
      local idx = self.index
      if left  then idx = math.max(1, idx-1) end
      if right then idx = math.min(#self.items, idx+1) end
      if home  then idx = 1 end
      if endk  then idx = #self.items end
      local new = self.items[idx] and self.items[idx].id
      if new then self:set_active(new) end
    end
  end

  ImGui.PopStyleVar(ctx, 3)

  return self.active
end

return M
