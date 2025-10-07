-- ReArkitekt/gui/widgets/controls/dropdown.lua
-- Mousewheel-friendly dropdown/combobox widget

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local M = {}

local DEFAULTS = {
  width = 110,
  height = 24,
  bg_color = 0x252525FF,
  bg_hover_color = 0x303030FF,
  bg_active_color = 0x3A3A3AFF,
  text_color = 0xCCCCCCFF,
  text_hover_color = 0xFFFFFFFF,
  border_color = 0x353535FF,
  border_hover_color = 0x454545FF,
  rounding = 4,
  padding_x = 8,
  padding_y = 4,
  arrow_size = 4,
  arrow_color = 0x999999FF,
  arrow_hover_color = 0xEEEEEEFF,
  enable_mousewheel = true,
}

local Dropdown = {}
Dropdown.__index = Dropdown

function M.new(opts)
  opts = opts or {}
  
  local dropdown = setmetatable({
    id = opts.id or "dropdown",
    label = opts.label or "",
    tooltip = opts.tooltip,
    options = opts.options or {},
    current_value = opts.current_value,
    sort_direction = opts.sort_direction or "asc",
    on_change = opts.on_change,
    on_direction_change = opts.on_direction_change,
    
    config = {},
    
    hover_alpha = 0,
  }, Dropdown)
  
  for k, v in pairs(DEFAULTS) do
    dropdown.config[k] = (opts.config and opts.config[k] ~= nil) and opts.config[k] or v
  end
  
  return dropdown
end

function Dropdown:get_current_index()
  if not self.current_value then return 1 end
  
  for i, opt in ipairs(self.options) do
    local value = type(opt) == "table" and opt.value or opt
    if value == self.current_value then
      return i
    end
  end
  
  return 1
end

function Dropdown:get_display_text()
  if not self.current_value then
    return self.options[1] and (type(self.options[1]) == "table" and self.options[1].label or tostring(self.options[1])) or ""
  end
  
  for _, opt in ipairs(self.options) do
    local value = type(opt) == "table" and opt.value or opt
    local label = type(opt) == "table" and opt.label or tostring(opt)
    if value == self.current_value then
      return label
    end
  end
  
  return ""
end

function Dropdown:handle_mousewheel(ctx, is_hovered)
  if not self.config.enable_mousewheel or not is_hovered then return false end
  
  local wheel = ImGui.GetMouseWheel(ctx)
  if wheel == 0 then return false end
  
  local current_idx = self:get_current_index()
  local new_idx = current_idx
  
  if wheel > 0 then
    new_idx = math.max(1, current_idx - 1)
  else
    new_idx = math.min(#self.options, current_idx + 1)
  end
  
  if new_idx ~= current_idx then
    local new_opt = self.options[new_idx]
    local new_value = type(new_opt) == "table" and new_opt.value or new_opt
    self.current_value = new_value
    
    if self.on_change then
      self.on_change(new_value)
    end
    
    return true
  end
  
  return false
end

function Dropdown:draw(ctx, x, y)
  local cfg = self.config
  local dl = ImGui.GetWindowDrawList(ctx)
  
  local w = cfg.width
  local h = cfg.height
  
  local x1, y1 = x, y
  local x2, y2 = x + w, y + h
  
  local mx, my = ImGui.GetMousePos(ctx)
  local is_hovered = mx >= x1 and mx < x2 and my >= y1 and my < y2
  
  local target_alpha = is_hovered and 1.0 or 0.0
  local alpha_speed = 12.0
  local dt = ImGui.GetDeltaTime(ctx)
  self.hover_alpha = self.hover_alpha + (target_alpha - self.hover_alpha) * alpha_speed * dt
  self.hover_alpha = math.max(0, math.min(1, self.hover_alpha))
  
  local bg_color = cfg.bg_color
  local text_color = cfg.text_color
  local border_color = cfg.border_color
  local arrow_color = cfg.arrow_color
  
  if self.hover_alpha > 0.01 then
    local function lerp_color(a, b, t)
      local ar = (a >> 24) & 0xFF
      local ag = (a >> 16) & 0xFF
      local ab = (a >> 8) & 0xFF
      local aa = a & 0xFF
      
      local br = (b >> 24) & 0xFF
      local bg = (b >> 16) & 0xFF
      local bb = (b >> 8) & 0xFF
      local ba = b & 0xFF
      
      local r = math.floor(ar + (br - ar) * t)
      local g = math.floor(ag + (bg - ag) * t)
      local b = math.floor(ab + (bb - ab) * t)
      local a = math.floor(aa + (ba - aa) * t)
      
      return (r << 24) | (g << 16) | (b << 8) | a
    end
    
    bg_color = lerp_color(cfg.bg_color, cfg.bg_hover_color, self.hover_alpha)
    text_color = lerp_color(cfg.text_color, cfg.text_hover_color, self.hover_alpha)
    border_color = lerp_color(cfg.border_color, cfg.border_hover_color, self.hover_alpha)
    arrow_color = lerp_color(cfg.arrow_color, cfg.arrow_hover_color, self.hover_alpha)
  end
  
  ImGui.DrawList_AddRectFilled(dl, x1, y1, x2, y2, bg_color, cfg.rounding)
  ImGui.DrawList_AddRect(dl, x1 + 0.5, y1 + 0.5, x2 - 0.5, y2 - 0.5, border_color, cfg.rounding, 0, 1)
  
  local display_text = self:get_display_text()
  
  local dir_indicator = ""
  if self.current_value ~= nil then
    dir_indicator = (self.sort_direction == "asc") and "↑ " or "↓ "
  end
  
  local full_text = dir_indicator .. display_text
  local text_w, text_h = ImGui.CalcTextSize(ctx, full_text)
  local text_x = x1 + cfg.padding_x
  local text_y = y1 + (h - text_h) * 0.5
  
  ImGui.DrawList_AddText(dl, text_x, text_y, text_color, full_text)
  
  local arrow_x = x2 - cfg.padding_x - cfg.arrow_size
  local arrow_y = y1 + h * 0.5
  local arrow_half = cfg.arrow_size
  
  ImGui.DrawList_AddTriangleFilled(dl,
    arrow_x - arrow_half, arrow_y - arrow_half * 0.5,
    arrow_x + arrow_half, arrow_y - arrow_half * 0.5,
    arrow_x, arrow_y + arrow_half * 0.7,
    arrow_color)
  
  ImGui.SetCursorScreenPos(ctx, x1, y1)
  ImGui.InvisibleButton(ctx, self.id .. "_btn", w, h)
  
  local clicked = ImGui.IsItemClicked(ctx, 0)
  local right_clicked = ImGui.IsItemClicked(ctx, 1)
  local wheel_changed = self:handle_mousewheel(ctx, is_hovered)
  
  if right_clicked and self.current_value then
    self.sort_direction = (self.sort_direction == "asc") and "desc" or "asc"
    if self.on_direction_change then
      self.on_direction_change(self.sort_direction)
    end
  end
  
  if is_hovered and self.tooltip then
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding, 6, 4)
    ImGui.SetTooltip(ctx, self.tooltip)
    ImGui.PopStyleVar(ctx)
  end
  
  if clicked then
    ImGui.OpenPopup(ctx, self.id .. "_popup")
  end
  
  local popup_changed = false
  if ImGui.BeginPopup(ctx, self.id .. "_popup") then
    for i, opt in ipairs(self.options) do
      local value
        if type(opt) == "table" then
        value = opt.value  -- Can be nil
        else
        value = opt
        end
      local label = type(opt) == "table" and opt.label or tostring(opt)
      
      local is_selected = value == self.current_value
      
      if ImGui.Selectable(ctx, label, is_selected) then
        self.current_value = value
        if self.on_change then
          self.on_change(value)
        end
        popup_changed = true
      end
      
      if is_selected then
        ImGui.SetItemDefaultFocus(ctx)
      end
    end
    ImGui.EndPopup(ctx)
  end
  
  return clicked or wheel_changed or popup_changed or right_clicked
end

function Dropdown:set_value(value)
  self.current_value = value
end

function Dropdown:get_value()
  return self.current_value
end

function Dropdown:set_direction(direction)
  self.sort_direction = direction
end

function Dropdown:get_direction()
  return self.sort_direction
end

return M