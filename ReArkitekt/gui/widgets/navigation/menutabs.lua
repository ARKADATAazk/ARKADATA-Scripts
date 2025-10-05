-- ReArkitekt/gui/widgets/menutabs.lua
-- Equal-width menu tabs for ReaImGui 0.9+

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local M = {}
M.__index = M

local DEFAULTS = {
  style = {
    height  = 30,
    pad_h   = 16,
    pad_v   = 10,
    text_offset_y = 0,
    spacing_after = 4,

    active_indicator_height = 1,
    active_indicator_inset  = 0.12,
    active_indicator_min_px = 8,
    active_indicator_max_px = 48,
  },
  colors = {
    bg_active   = 0x242424FF,
    bg_clicked  = 0x2A2A2AFF,
    bg_hovered  = 0x202020FF,
    bg_inactive = 0x1A1A1AFF,
    border      = 0x000000FF,
    active_indicator = 0x41E0A3FF,
    text_active = 0xFFFFFFFF,
    text_inact  = 0xBBBBBBE0,
    text_disabled = 0x888888A0,
  }
}

local function deepcopy(t)
  if type(t) ~= 'table' then return t end
  local o = {}
  for k,v in pairs(t) do o[k] = deepcopy(v) end
  return o
end

local function snap(v) return math.floor((v or 0) + 0.5) end

local function apply_defaults(opts)
  local o = {}
  o.items = (opts and opts.items) or {}
  o.active = opts and opts.active or (o.items[1] and (o.items[1].id or o.items[1].label))
  o.style  = deepcopy(DEFAULTS.style)
  o.colors = deepcopy(DEFAULTS.colors)
  if opts and opts.style  then for k,v in pairs(opts.style)  do o.style[k]  = v end end
  if opts and opts.colors then for k,v in pairs(opts.colors) do o.colors[k] = v end end
  o.on_change = opts and opts.on_change
  return o
end

function M.new(opts)
  local self = setmetatable({}, M)
  opts = apply_defaults(opts or {})
  self.items    = opts.items
  self.active   = opts.active
  self.style    = opts.style
  self.colors   = opts.colors
  self.on_change= opts.on_change
  self._active_index = 1

  if self.active then
    for i,it in ipairs(self.items) do
      if (it.id or it.label) == self.active then
        self._active_index = i
        break
      end
    end
  elseif self.items[1] then
    self._active_index = 1
    self.active = (self.items[1].id or self.items[1].label)
  else
    self._active_index = 0
    self.active = nil
  end
  return self
end

function M:set_items(items, active_id)
  self.items = items or {}
  if active_id then
    self:set_active(active_id)
  else
    if self.items[1] then
      self._active_index = 1
      self.active = (self.items[1].id or self.items[1].label)
    else
      self._active_index = 0
      self.active = nil
    end
  end
end

function M:set_active(id_or_index)
  local idx
  if type(id_or_index) == 'number' then
    if id_or_index >= 1 and id_or_index <= #self.items then idx = id_or_index end
  else
    for i,it in ipairs(self.items) do
      if (it.id or it.label) == id_or_index then idx = i break end
    end
  end
  if not idx then return end
  local new_id = (self.items[idx].id or self.items[idx].label)
  if new_id == self.active then return end
  self._active_index = idx
  self.active = new_id
  if self.on_change then pcall(self.on_change, self.active, self._active_index) end
end

local function calc_indicator_inset_px(style, tab_px_w)
  local inset = style.active_indicator_inset or 0
  local px
  if inset > 0 and inset <= 0.5 then
    px = tab_px_w * inset
  else
    px = inset
  end
  local min_px = style.active_indicator_min_px or 0
  local max_px = style.active_indicator_max_px or math.huge
  if px < min_px then px = min_px end
  if px > max_px then px = max_px end
  if px > tab_px_w * 0.49 then px = tab_px_w * 0.49 end
  return snap(px)
end

function M:draw(ctx)
  local items = self.items
  local n = #items
  if n == 0 then return nil, 0 end

  local curx, cury = ImGui.GetCursorScreenPos(ctx)
  local h = self.style.height

  local win_x, _ = ImGui.GetWindowPos(ctx)
  local win_w = select(1, ImGui.GetWindowSize(ctx))
  local content_x1 = win_x
  local content_x2 = win_x + win_w

  -- Store the cursor X offset to restore padding after drawing
  local cursor_offset_x = curx - win_x

  local x = snap(content_x1)
  local y = snap(cury)
  local w = snap(content_x2 - content_x1)
  local dl = ImGui.GetWindowDrawList(ctx)

  local edges = {}
  for i = 0, n do
    edges[i] = snap(x + (w * i) / n)
  end

  local active_rect = nil
  local c = self.colors

  for i = 1, n do
    local it = items[i]
    local label = (it.label or it.id or ("Tab "..i))
    local disabled = (it.disabled == true)

    local x1 = edges[i-1]
    local x2 = edges[i]
    local y1 = y
    local y2 = snap(y + h)
    local tab_w = (x2 - x1)

    ImGui.SetCursorScreenPos(ctx, x1, y1)
    local _pressed = ImGui.InvisibleButton(ctx, "##tab"..i, tab_w, y2 - y1, ImGui.ButtonFlags_None or 0)

    local hovered = ImGui.IsItemHovered(ctx)
    local held    = ImGui.IsItemActive(ctx)
    local active  = (self._active_index == i)

    if not disabled and _pressed then
      self:set_active(i)
      active = (self._active_index == i)
    end

    local bg = (disabled and c.bg_inactive)
            or (active   and c.bg_active)
            or (held     and c.bg_clicked)
            or (hovered  and c.bg_hovered)
            or c.bg_inactive
    ImGui.DrawList_AddRectFilled(dl, x1, y1, x2, y2, bg, 0)

    local bc = c.border
    ImGui.DrawList_AddLine(dl, x1, y1, x2, y1, bc, 1)
    if i > 1 then
      ImGui.DrawList_AddLine(dl, x1, y1, x1, y2, bc, 1)
    end
    if i == n then
      ImGui.DrawList_AddLine(dl, x2, y1, x2, y2, bc, 1)
    end

    if not active then
      ImGui.DrawList_AddLine(dl, x1, y2, x2, y2, bc, 1)
    else
      active_rect = {x1=x1, x2=x2, y=y2, w=tab_w}
    end

    local PAD_H = self.style.pad_h
    local tw, th = ImGui.CalcTextSize(ctx, label)
    local usable_w = tab_w - (PAD_H * 2)
    local ty = snap(y1 + (h - th) * 0.5 + (self.style.text_offset_y or 0))
    local tc = disabled and c.text_disabled or (active and c.text_active or c.text_inact)

    if tw <= usable_w then
      local tx = snap(x1 + (tab_w - tw) * 0.5)
      ImGui.DrawList_AddText(dl, tx, ty, tc, label)
    else
      local tx = snap(x1 + PAD_H)
      local clip_x1 = snap(x1 + PAD_H)
      local clip_x2 = snap(x2 - PAD_H)
      ImGui.DrawList_PushClipRect(dl, clip_x1, y1, clip_x2, y2, true)
      ImGui.DrawList_AddText(dl, tx, ty, tc, label)
      ImGui.DrawList_PopClipRect(dl)
    end
  end

  if active_rect then
    local bottom_y = snap(y + h)
    local left_edge  = edges[0]
    local right_edge = edges[n]
    local bc = self.colors.border

    if active_rect.x1 > left_edge then
      ImGui.DrawList_AddLine(dl, left_edge, bottom_y, active_rect.x1 - 1, bottom_y, bc, 1)
    end
    if active_rect.x2 < right_edge then
      ImGui.DrawList_AddLine(dl, active_rect.x2 + 1, bottom_y, right_edge, bottom_y, bc, 1)
    end

    local indicator_h = self.style.active_indicator_height
    local inset_px    = calc_indicator_inset_px(self.style, active_rect.w)
    local ix1 = snap(active_rect.x1 + inset_px)
    local ix2 = snap(active_rect.x2 - inset_px)
    if ix2 > ix1 then
      local iy = snap(bottom_y - indicator_h)
      ImGui.DrawList_AddRectFilled(dl, ix1, iy, ix2, bottom_y, self.colors.active_indicator)
    end
  end

  ImGui.SetCursorScreenPos(ctx, win_x + cursor_offset_x, y + h)

  if self.style.spacing_after and self.style.spacing_after > 0 then
    ImGui.Dummy(ctx, 1, self.style.spacing_after)
  end

  if ImGui.IsWindowFocused(ctx, ImGui.FocusedFlags_ChildWindows or 0) then
    local left  = ImGui.IsKeyPressed(ctx, ImGui.Key_LeftArrow  or 0, false)
    local right = ImGui.IsKeyPressed(ctx, ImGui.Key_RightArrow or 0, false)
    local home  = ImGui.IsKeyPressed(ctx, ImGui.Key_Home       or 0, false)
    local kend  = ImGui.IsKeyPressed(ctx, ImGui.Key_End        or 0, false)
    if left  then self:set_active(math.max(1, self._active_index - 1)) end
    if right then self:set_active(math.min(n, self._active_index + 1)) end
    if home  then self:set_active(1) end
    if kend  then self:set_active(n) end
  end

  return self.active, self._active_index
end

return M