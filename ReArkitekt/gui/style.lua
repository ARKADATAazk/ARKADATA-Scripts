-- style.lua
-- Shared style helpers for ReaImGui

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'
local colors = require 'colors'

local M = {}
local hexrgb = colors.hexrgb

local C = {
  white         = hexrgb("#FFFFFF"),
  black         = hexrgb("#000000"),
  teal          = hexrgb("#41E0A3FF"),
  teal_dark     = hexrgb("#008F6FCC"),
  red           = hexrgb("#E04141FF"),
  yellow        = hexrgb("#E0B341FF"),
  grey_84       = hexrgb("#D6D6D6FF"),
  grey_60       = hexrgb("#999999FF"),
  grey_52       = hexrgb("#858585FF"),
  grey_48       = hexrgb("#7A7A7AFF"),
  grey_40       = hexrgb("#666666FF"),
  grey_35       = hexrgb("#595959FF"),
  grey_31       = hexrgb("#4F4F4FFF"),
  grey_30       = hexrgb("#4D4D4DFF"),
  grey_27       = hexrgb("#454545FF"),
  grey_25       = hexrgb("#404040FF"),
  grey_20       = hexrgb("#333333FF"),
  grey_18       = hexrgb("#2E2E2EFF"),
  grey_15       = hexrgb("#262626FF"),
  grey_14       = hexrgb("#242424FF"),
  grey_10       = hexrgb("#1A1A1AFF"),
  grey_09       = hexrgb("#171717FF"),
  grey_08       = hexrgb("#141414FF"),
  grey_07       = hexrgb("#121212FF"),
  grey_06       = hexrgb("#0F0F0FFF"),
  grey_05       = hexrgb("#0B0B0BFF"),
  border_strong = hexrgb("#000000FF"),
  border_soft   = hexrgb("#000000DD"),
  scroll_bg     = hexrgb("#05050587"),
  tree_lines    = hexrgb("#6E6E8080"),
}

function M.with_alpha(col, a)
  return (col & 0xFFFFFF00) | (a & 0xFF)
end

M.palette = C

function M.PushMyStyle(ctx)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_Alpha, 1)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_DisabledAlpha, 0)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding, 8, 8)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowRounding, 0)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowBorderSize, 1)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowMinSize, 32, 32)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowTitleAlign, 0, 0.5)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_ChildRounding, 0)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_ChildBorderSize, 1)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_PopupRounding, 0)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_PopupBorderSize, 1)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 4, 2)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameRounding, 0)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameBorderSize, 1)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing, 8, 4)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemInnerSpacing, 4, 4)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_IndentSpacing, 22)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_CellPadding, 4, 2)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_ScrollbarSize, 12)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_ScrollbarRounding, 4)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_GrabMinSize, 30)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_GrabRounding, 4)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_TabRounding, 0)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_TabBorderSize, 1)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_TabBarBorderSize, 1)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_TableAngledHeadersAngle, 0.401426)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_ButtonTextAlign, 0.5, 0.51)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_SelectableTextAlign, 0, 0)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_SeparatorTextBorderSize, 3)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_SeparatorTextAlign, 0, 0.5)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_SeparatorTextPadding, 20, 3)

  local A = M.with_alpha
  ImGui.PushStyleColor(ctx, ImGui.Col_Text, C.white)
  ImGui.PushStyleColor(ctx, ImGui.Col_TextDisabled, hexrgb("#848484FF"))
  ImGui.PushStyleColor(ctx, ImGui.Col_WindowBg, C.grey_14)
  ImGui.PushStyleColor(ctx, ImGui.Col_ChildBg, hexrgb("#0D0D0D00"))
  ImGui.PushStyleColor(ctx, ImGui.Col_PopupBg, A(C.grey_08, 0xF0))
  ImGui.PushStyleColor(ctx, ImGui.Col_Border, C.border_soft)
  ImGui.PushStyleColor(ctx, ImGui.Col_BorderShadow, hexrgb("#00000000"))
  ImGui.PushStyleColor(ctx, ImGui.Col_FrameBg, A(C.grey_06, 0x8A))
  ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgHovered, A(C.grey_08, 0x66))
  ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgActive, A(C.grey_18, 0xAB))
  ImGui.PushStyleColor(ctx, ImGui.Col_TitleBg, C.grey_06)
  ImGui.PushStyleColor(ctx, ImGui.Col_TitleBgActive, C.grey_08)
  ImGui.PushStyleColor(ctx, ImGui.Col_TitleBgCollapsed, hexrgb("#00000082"))
  ImGui.PushStyleColor(ctx, ImGui.Col_MenuBarBg, C.grey_14)
  ImGui.PushStyleColor(ctx, ImGui.Col_ScrollbarBg, hexrgb("#00000000"))
  ImGui.PushStyleColor(ctx, ImGui.Col_ScrollbarGrab, hexrgb("#4A4A4AFF"))
  ImGui.PushStyleColor(ctx, ImGui.Col_ScrollbarGrabHovered, hexrgb("#5A5A5AFF"))
  ImGui.PushStyleColor(ctx, ImGui.Col_ScrollbarGrabActive, hexrgb("#6A6A6AFF"))
  ImGui.PushStyleColor(ctx, ImGui.Col_CheckMark, hexrgb("#42FAAAFF"))
  ImGui.PushStyleColor(ctx, ImGui.Col_SliderGrab, hexrgb("#00FFA7FF"))
  ImGui.PushStyleColor(ctx, ImGui.Col_SliderGrabActive, C.red)
  ImGui.PushStyleColor(ctx, ImGui.Col_Button, A(C.grey_05, 0x66))
  ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, C.grey_20)
  ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive, C.grey_18)
  ImGui.PushStyleColor(ctx, ImGui.Col_Header, hexrgb("#0000004F"))
  ImGui.PushStyleColor(ctx, ImGui.Col_HeaderHovered, C.teal_dark)
  ImGui.PushStyleColor(ctx, ImGui.Col_HeaderActive, hexrgb("#42FAD6FF"))
  ImGui.PushStyleColor(ctx, ImGui.Col_Separator, C.black)
  ImGui.PushStyleColor(ctx, ImGui.Col_SeparatorHovered, hexrgb("#1ABF9FC7"))
  ImGui.PushStyleColor(ctx, ImGui.Col_SeparatorActive, hexrgb("#1ABF9AFF"))
  ImGui.PushStyleColor(ctx, ImGui.Col_ResizeGrip, C.grey_18)
  ImGui.PushStyleColor(ctx, ImGui.Col_ResizeGripHovered, C.grey_18)
  ImGui.PushStyleColor(ctx, ImGui.Col_ResizeGripActive, C.grey_20)
  ImGui.PushStyleColor(ctx, ImGui.Col_TabHovered, hexrgb("#42FA8FCC"))
  ImGui.PushStyleColor(ctx, ImGui.Col_Tab, hexrgb("#000000DC"))
  ImGui.PushStyleColor(ctx, ImGui.Col_TabActive, C.grey_08)
  ImGui.PushStyleColor(ctx, ImGui.Col_TabUnfocused, hexrgb("#11261FF8"))
  ImGui.PushStyleColor(ctx, ImGui.Col_TabUnfocusedActive, hexrgb("#236C42FF"))
  ImGui.PushStyleColor(ctx, ImGui.Col_DockingPreview, hexrgb("#42FAAAB3"))
  ImGui.PushStyleColor(ctx, ImGui.Col_DockingEmptyBg, C.grey_20)
  ImGui.PushStyleColor(ctx, ImGui.Col_PlotLines, hexrgb("#9C9C9CFF"))
  ImGui.PushStyleColor(ctx, ImGui.Col_PlotLinesHovered, hexrgb("#FF6E59FF"))
  ImGui.PushStyleColor(ctx, ImGui.Col_PlotHistogram, hexrgb("#E6B300FF"))
  ImGui.PushStyleColor(ctx, ImGui.Col_PlotHistogramHovered, hexrgb("#FF9900FF"))
  ImGui.PushStyleColor(ctx, ImGui.Col_TableHeaderBg, C.grey_05)
  ImGui.PushStyleColor(ctx, ImGui.Col_TableBorderStrong, C.border_strong)
  ImGui.PushStyleColor(ctx, ImGui.Col_TableBorderLight, C.grey_07)
  ImGui.PushStyleColor(ctx, ImGui.Col_TableRowBg, hexrgb("#0000000A"))
  ImGui.PushStyleColor(ctx, ImGui.Col_TableRowBgAlt, hexrgb("#B0B0B00F"))
  ImGui.PushStyleColor(ctx, ImGui.Col_TextSelectedBg, hexrgb("#41E0A366"))
  ImGui.PushStyleColor(ctx, ImGui.Col_DragDropTarget, hexrgb("#FFFF00E6"))
  ImGui.PushStyleColor(ctx, ImGui.Col_NavWindowingHighlight, hexrgb("#FFFFFFB3"))
  ImGui.PushStyleColor(ctx, ImGui.Col_NavWindowingDimBg, hexrgb("#CCCCCC33"))
  ImGui.PushStyleColor(ctx, ImGui.Col_ModalWindowDimBg, hexrgb("#CCCCCC59"))
end

function M.PopMyStyle(ctx)
  ImGui.PopStyleColor(ctx, 54)
  ImGui.PopStyleVar(ctx, 31)
end

return M