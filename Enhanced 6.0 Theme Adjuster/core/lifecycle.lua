-- core/lifecycle.lua
-- Generic lifecycle manager for any UI view (tab, panel, popup...).
-- Handles per-frame resets and cleanup for registered resources.
package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'
local M = {}

-- ResourceGroup: tracks resources & callbacks for a single view/scope.
local Group = {}
Group.__index = Group

-- Create a new lifecycle group.
function M.new()
  return setmetatable({
    _resources = {},     -- array of { obj } where obj has :begin_frame() / :clear()
    _children  = {},     -- child groups (for nested scopes, e.g., popups)
    _on_show   = nil,    -- optional fn()
    _on_hide   = nil,    -- optional fn()
    _begin     = nil,    -- optional fn()
  }, Group)
end

-- Register any resource that implements :begin_frame() and/or :clear()
function Group:register(resource)
  if resource then table.insert(self._resources, resource) end
  return resource
end

-- Create a child group (use for modals/popups or subviews).
function Group:child()
  local g = M.new()
  table.insert(self._children, g)
  return g
end

-- Optional hooks
function Group:on_show(fn)     self._on_show = fn;  return self end
function Group:on_hide(fn)     self._on_hide = fn;  return self end
function Group:begin_frame(fn) self._begin   = fn;  return self end

-- Lifecycle entry points
function Group:call_on_show()
  if self._on_show then pcall(self._on_show) end
end

function Group:call_begin_frame()
  -- reset budgets on all resources
  for _, r in ipairs(self._resources) do
    if r.begin_frame then pcall(r.begin_frame, r) end
  end
  -- children first (e.g., nested scopes want their budgets reset too)
  for _, c in ipairs(self._children) do c:call_begin_frame() end
  -- custom per-frame work last
  if self._begin then pcall(self._begin) end
end

function Group:call_on_hide()
  -- Clear children first
  for _, c in ipairs(self._children) do c:call_on_hide() end
  self._children = {}
  -- Then clear our own resources
  for _, r in ipairs(self._resources) do
    if r.clear then pcall(r.clear, r) end
  end
  if self._on_hide then pcall(self._on_hide) end
  collectgarbage('collect')
end

-- Export a “view” object compatible with your app’s tab/panel API.
-- draw_fn(ctx, state) is required; hooks are wired to this lifecycle group.
function Group:export(draw_fn)
  return {
    draw        = draw_fn,
    on_show     = function() self:call_on_show() end,
    on_hide     = function() self:call_on_hide() end,
    begin_frame = function() self:call_begin_frame() end,
  }
end

return M
