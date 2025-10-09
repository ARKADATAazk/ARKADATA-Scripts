-- ReArkitekt/gui/widgets/overlay/manager.lua
-- Modal overlay stack + scrim + focus/escape handling
package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local Draw   = require('ReArkitekt.gui.draw')
local Colors = require('ReArkitekt.core.colors')
local Style  = require('ReArkitekt.gui.style')
local OverlayConfig = require('ReArkitekt.gui.widgets.overlay.config')

local M = {}
M.__index = M

local function create_alpha_tracker(speed)
  return {
    current = 0.0,
    target = 0.0,
    speed = speed or 8.0,
    set_target = function(self, t) 
      self.target = t 
    end,
    update = function(self, dt)
      local diff = self.target - self.current
      if math.abs(diff) < 0.005 then
        self.current = self.target
      else
        local alpha = 1.0 - math.exp(-self.speed * dt)
        self.current = self.current + diff * alpha
      end
    end,
    value = function(self) 
      return math.max(0.0, math.min(1.0, self.current))
    end
  }
end

function M.new()
  local self = setmetatable({}, M)
  self.stack = {}
  return self
end

function M:push(opts)
  assert(opts and opts.id and opts.render, "overlay requires id + render()")
  
  local overlay = {
    id = opts.id,
    render = opts.render,
    on_close = opts.on_close,
    close_on_scrim = (opts.close_on_scrim ~= false),
    esc_to_close = (opts.esc_to_close ~= false),
    alpha = create_alpha_tracker(12),
  }
  table.insert(self.stack, overlay)
end

function M:pop(id)
  if #self.stack == 0 then return end
  local top = self.stack[#self.stack]
  if not id or id == top.id then
    if top.on_close then pcall(top.on_close) end
    table.remove(self.stack)
  else
    for i=#self.stack,1,-1 do
      if self.stack[i].id == id then
        local it = table.remove(self.stack, i)
        if it.on_close then pcall(it.on_close) end
        break
      end
    end
  end
end

function M:is_active()
  return #self.stack > 0
end

function M:render(ctx, dt)
  if #self.stack == 0 then return end

  for i,ov in ipairs(self.stack) do
    local target = (i == #self.stack) and 1.0 or 0.6
    ov.alpha:set_target(target)
    ov.alpha:update(dt or (1/60))
  end

  local top = self.stack[#self.stack]
  local alpha_val = top.alpha:value()
  
  local parent_x, parent_y = ImGui.GetWindowPos(ctx)
  local parent_w, parent_h = ImGui.GetWindowSize(ctx)
  
  ImGui.SetNextWindowPos(ctx, parent_x, parent_y)
  ImGui.SetNextWindowSize(ctx, parent_w, parent_h)
  
  local window_flags = ImGui.WindowFlags_NoTitleBar
                     | ImGui.WindowFlags_NoResize
                     | ImGui.WindowFlags_NoMove
                     | ImGui.WindowFlags_NoScrollbar
                     | ImGui.WindowFlags_NoScrollWithMouse
                     | ImGui.WindowFlags_NoCollapse
                     | ImGui.WindowFlags_NoNavFocus
                     | ImGui.WindowFlags_NoDocking
                     | ImGui.WindowFlags_NoBackground
  
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding, 0, 0)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowBorderSize, 0)
  ImGui.PushStyleColor(ctx, ImGui.Col_WindowBg, 0x00000000)
  
  Style.PushMyStyle(ctx)
  
  local visible = ImGui.Begin(ctx, "##modal_overlay_" .. top.id, true, window_flags)
  
  if visible then
    local dl = ImGui.GetWindowDrawList(ctx)
    local x, y = ImGui.GetWindowPos(ctx)
    local w, h = ImGui.GetWindowSize(ctx)
    
    local config = OverlayConfig.get()
    local scrim_opacity = math.floor(255 * config.scrim.opacity * alpha_val)
    local scrim_color = Colors.with_alpha(config.scrim.color, scrim_opacity)
    Draw.rect_filled(dl, x, y, x+w, y+h, scrim_color, 0)
    
    ImGui.SetCursorScreenPos(ctx, x, y)
    ImGui.InvisibleButton(ctx, '##scrim', w, h)
    local clicked_scrim = ImGui.IsItemClicked(ctx)
    
    if top.esc_to_close and ImGui.IsKeyPressed(ctx, ImGui.Key_Escape) then
      self:pop()
    elseif clicked_scrim and top.close_on_scrim then
      self:pop()
    else
      top.render(ctx, alpha_val, {x=x, y=y, w=w, h=h, dl=dl})
    end
  end
  
  ImGui.End(ctx)
  
  Style.PopMyStyle(ctx)
  ImGui.PopStyleColor(ctx)
  ImGui.PopStyleVar(ctx, 2)
end

return M