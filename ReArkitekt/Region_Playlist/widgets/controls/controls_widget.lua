-- ReArkitekt/features/region_playlist/controls_widget.lua
-- Transport and quantize controls widget

local M = {}

local BUTTON_SIZE = 32
local BUTTON_GAP = 8
local QUANTIZE_WIDTH = 120

function M.draw_transport_controls(ctx, bridge, x, y)
  local ImGui = require 'imgui' '0.10'
  
  ImGui.SetCursorScreenPos(ctx, x, y)
  
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameRounding, 4)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing, BUTTON_GAP, 0)
  
  local state = bridge:get_state()
  local is_playing = state.is_playing
  
  -- Previous button
  if ImGui.Button(ctx, "◀◀", BUTTON_SIZE, BUTTON_SIZE) then
    bridge:prev()
  end
  
  ImGui.SameLine(ctx)
  
  -- Play/Pause button
  local play_label = is_playing and "⏸" or "▶"
  if ImGui.Button(ctx, play_label, BUTTON_SIZE, BUTTON_SIZE) then
    if is_playing then
      bridge:stop()
    else
      bridge:play()
    end
  end
  
  ImGui.SameLine(ctx)
  
  -- Stop button
  if ImGui.Button(ctx, "⏹", BUTTON_SIZE, BUTTON_SIZE) then
    bridge:stop()
  end
  
  ImGui.SameLine(ctx)
  
  -- Next button
  if ImGui.Button(ctx, "▶▶", BUTTON_SIZE, BUTTON_SIZE) then
    bridge:next()
  end
  
  ImGui.PopStyleVar(ctx, 2)
  
  local consumed_width = (BUTTON_SIZE * 4) + (BUTTON_GAP * 3)
  return consumed_width
end

function M.draw_quantize_selector(ctx, bridge, x, y, width)
  local ImGui = require 'imgui' '0.10'
  
  ImGui.SetCursorScreenPos(ctx, x, y)
  
  local state = bridge:get_state()
  local current_mode = state.quantize_mode or "none"
  
  local modes = {
    { id = "none", label = "End of Region" },
    { id = "beat", label = "Next Beat (1/4)" },
    { id = "bar",  label = "Next Bar" },
    { id = "grid", label = "Current Grid" },
  }
  
  local current_label = "End of Region"
  for _, mode in ipairs(modes) do
    if mode.id == current_mode then
      current_label = mode.label
      break
    end
  end
  
  ImGui.SetNextItemWidth(ctx, width or QUANTIZE_WIDTH)
  if ImGui.BeginCombo(ctx, "##quantize", current_label, 0) then
    for _, mode in ipairs(modes) do
      local is_selected = (mode.id == current_mode)
      if ImGui.Selectable(ctx, mode.label, is_selected, 0) then
        bridge:set_quantize_mode(mode.id)
      end
      
      if is_selected then
        ImGui.SetItemDefaultFocus(ctx)
      end
    end
    ImGui.EndCombo(ctx)
  end
  
  return width or QUANTIZE_WIDTH
end

function M.draw_playback_info(ctx, bridge, x, y, width)
  local ImGui = require 'imgui' '0.10'
  
  local state = bridge:get_state()
  local current_rid = bridge:get_current_rid()
  
  if not current_rid then
    ImGui.SetCursorScreenPos(ctx, x, y)
    ImGui.Text(ctx, "No region selected")
    return
  end
  
  local region = bridge.engine:get_region_by_rid(current_rid)
  if not region then return end
  
  ImGui.SetCursorScreenPos(ctx, x, y)
  
  local progress = bridge:get_progress() or 0
  local time_remaining = bridge:get_time_remaining()
  
  local info_text = string.format("%d/%d: %s", 
    state.playlist_pointer, 
    #state.playlist_order, 
    region.name
  )
  
  if time_remaining then
    info_text = info_text .. string.format(" (%.1fs)", time_remaining)
  end
  
  ImGui.Text(ctx, info_text)
  
  if state.is_playing and progress > 0 then
    ImGui.SetCursorScreenPos(ctx, x, y + 20)
    ImGui.ProgressBar(ctx, progress, width, 4)
  end
end

function M.draw_complete_controls(ctx, bridge, x, y, available_width)
  local transport_width = M.draw_transport_controls(ctx, bridge, x, y)
  
  local quantize_x = x + transport_width + 16
  local quantize_width = M.draw_quantize_selector(ctx, bridge, quantize_x, y + 4, 140)
  
  local info_x = x + transport_width + quantize_width + 32
  local info_width = available_width - (info_x - x)
  M.draw_playback_info(ctx, bridge, info_x, y + 6, info_width)
  
  return 40
end

return M