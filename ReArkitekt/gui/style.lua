-- style.lua
-- Shared style helpers for ReaImGui
-- Exports:
--   M.PushMyStyle(ctx) / M.PopMyStyle(ctx)
--   M.palette   -> named colors (0xRRGGBBAA)
--   M.with_alpha(col, a) -> same color with new alpha (0..255)

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local ImGui = require 'imgui' '0.9'

local M = {}

-- ---------- Palette ----------
-- NOTE: ReaImGui expects colors as 0xRRGGBBAA (alpha in the lowest byte).
local C = {
  -- Core
  white      = 0xFFFFFFFF,
  black      = 0x000000FF,

  -- Teals / brand (uses your values)
  teal       = 0x41E0A3FF,  -- bright teal (links, accents)
  teal_dark  = 0x008F6FCC,  -- darker/hover teal
  red        = 0xE04141FF,  -- errors, active red accents
  yellow     = 0xE0B341FF,  -- warnings

  -- Greys (light -> dark)
  grey_84    = 0xD6D6D6FF,
  grey_60    = 0x999999FF,
  grey_52    = 0x858585FF,
  grey_48    = 0x7A7A7AFF,
  grey_40    = 0x666666FF,
  grey_35    = 0x595959FF,
  grey_31    = 0x4F4F4FFF,
  grey_30    = 0x4D4D4DFF,
  grey_27    = 0x454545FF,  -- ADDED (used for TabSelectedOverline)
  grey_25    = 0x404040FF,
  grey_20    = 0x333333FF,
  grey_18    = 0x2E2E2EFF,
  grey_15    = 0x262626FF,
  grey_14    = 0x242424FF,  -- window bg
  grey_10    = 0x1A1A1AFF,
  grey_09    = 0x171717FF,
  grey_08    = 0x141414FF,
  grey_07    = 0x121212FF,
  grey_06    = 0x0F0F0FFF,
  grey_05    = 0x0B0B0BFF,

  -- Extras
  border_strong = 0x000000FF,
  border_soft   = 0x000000DD,
  scroll_bg     = 0x05050587,
  tree_lines    = 0x6E6E8080,
}

-- Small helper to replace alpha (0..255) while keeping RGB
function M.with_alpha(col, a)
  return (col & 0xFFFFFF00) | (a & 0xFF)
end

-- expose palette for other modules
M.palette = C

function M.PushMyStyle(ctx)
  -- === StyleVars (31 active, 5 commented) ===
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_Alpha,                       1)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_DisabledAlpha,               0)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding,               8, 8)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowRounding,              0)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowBorderSize,            1)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowMinSize,               32, 32)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowTitleAlign,            0, 0.5)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_ChildRounding,               0)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_ChildBorderSize,             1)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_PopupRounding,               0)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_PopupBorderSize,             1)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding,                4, 2)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameRounding,               0)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameBorderSize,             1)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing,                 8, 4)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemInnerSpacing,            4, 4)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_IndentSpacing,               22)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_CellPadding,                 4, 2)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_ScrollbarSize,               14)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_ScrollbarRounding,           0)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_GrabMinSize,                 12)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_GrabRounding,                0)
  -- ImGui.PushStyleVar(ctx, ImGui.StyleVar_ImageBorderSize,             1)  -- Doesn't exist in 0.9
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_TabRounding,                 0)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_TabBorderSize,               1)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_TabBarBorderSize,            1)
  -- ImGui.PushStyleVar(ctx, ImGui.StyleVar_TabBarOverlineSize,          1)  -- Doesn't exist in 0.9
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_TableAngledHeadersAngle,     0.401426)
  -- ImGui.PushStyleVar(ctx, ImGui.StyleVar_TableAngledHeadersTextAlign, 0.5, 0)  -- Doesn't exist in 0.9
  -- ImGui.PushStyleVar(ctx, ImGui.StyleVar_TreeLinesSize,               1)  -- Doesn't exist in 0.9
  -- ImGui.PushStyleVar(ctx, ImGui.StyleVar_TreeLinesRounding,           0)  -- Doesn't exist in 0.9
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_ButtonTextAlign,             0.5, 0.51)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_SelectableTextAlign,         0, 0)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_SeparatorTextBorderSize,     3)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_SeparatorTextAlign,          0, 0.5)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_SeparatorTextPadding,        20, 3)

  -- === Colors (54 active, 6 commented) ===
  local A = M.with_alpha
  ImGui.PushStyleColor(ctx, ImGui.Col_Text,                      C.white)
  ImGui.PushStyleColor(ctx, ImGui.Col_TextDisabled,              0x848484FF)
  ImGui.PushStyleColor(ctx, ImGui.Col_WindowBg,                  C.grey_14)
  ImGui.PushStyleColor(ctx, ImGui.Col_ChildBg,                   0x0D0D0D00)
  ImGui.PushStyleColor(ctx, ImGui.Col_PopupBg,                   A(C.grey_08, 0xF0))
  ImGui.PushStyleColor(ctx, ImGui.Col_Border,                    C.border_soft)
  ImGui.PushStyleColor(ctx, ImGui.Col_BorderShadow,              0x00000000)
  ImGui.PushStyleColor(ctx, ImGui.Col_FrameBg,                   A(C.grey_06, 0x8A))
  ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgHovered,            A(C.grey_08, 0x66))
  ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgActive,             A(C.grey_18, 0xAB))
  ImGui.PushStyleColor(ctx, ImGui.Col_TitleBg,                   C.grey_06)
  ImGui.PushStyleColor(ctx, ImGui.Col_TitleBgActive,             C.grey_08)
  ImGui.PushStyleColor(ctx, ImGui.Col_TitleBgCollapsed,          0x00000082)
  ImGui.PushStyleColor(ctx, ImGui.Col_MenuBarBg,                 C.grey_14)
  ImGui.PushStyleColor(ctx, ImGui.Col_ScrollbarBg,               C.scroll_bg)
  ImGui.PushStyleColor(ctx, ImGui.Col_ScrollbarGrab,             0x585858FF)
  ImGui.PushStyleColor(ctx, ImGui.Col_ScrollbarGrabHovered,      0x696969FF)
  ImGui.PushStyleColor(ctx, ImGui.Col_ScrollbarGrabActive,       0x828282FF)
  ImGui.PushStyleColor(ctx, ImGui.Col_CheckMark,                 0x42FAAAFF)
  ImGui.PushStyleColor(ctx, ImGui.Col_SliderGrab,                0x00FFA7FF)
  ImGui.PushStyleColor(ctx, ImGui.Col_SliderGrabActive,          C.red)
  ImGui.PushStyleColor(ctx, ImGui.Col_Button,                    A(C.grey_05, 0x66))
  ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered,             C.grey_20)
  ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive,              C.grey_18)
  ImGui.PushStyleColor(ctx, ImGui.Col_Header,                    0x0000004F)
  ImGui.PushStyleColor(ctx, ImGui.Col_HeaderHovered,             C.teal_dark)
  ImGui.PushStyleColor(ctx, ImGui.Col_HeaderActive,              0x42FAD6FF)
  ImGui.PushStyleColor(ctx, ImGui.Col_Separator,                 C.black)
  ImGui.PushStyleColor(ctx, ImGui.Col_SeparatorHovered,          0x1ABF9FC7)
  ImGui.PushStyleColor(ctx, ImGui.Col_SeparatorActive,           0x1ABF9AFF)
  ImGui.PushStyleColor(ctx, ImGui.Col_ResizeGrip,                0x35353533)
  ImGui.PushStyleColor(ctx, ImGui.Col_ResizeGripHovered,         0x262626AB)
  ImGui.PushStyleColor(ctx, ImGui.Col_ResizeGripActive,          0x202020F2)
  -- ImGui.PushStyleColor(ctx, ImGui.Col_InputTextCursor,           C.white)  -- Doesn't exist in 0.9
  ImGui.PushStyleColor(ctx, ImGui.Col_TabHovered,                0x42FA8FCC)
  ImGui.PushStyleColor(ctx, ImGui.Col_Tab,                       0x000000DC)
  ImGui.PushStyleColor(ctx, ImGui.Col_TabActive,                 C.grey_08)  -- was TabSelected
  -- ImGui.PushStyleColor(ctx, ImGui.Col_TabSelectedOverline,       C.grey_27)  -- Doesn't exist in 0.9
  ImGui.PushStyleColor(ctx, ImGui.Col_TabUnfocused,              0x11261FF8)  -- was TabDimmed
  ImGui.PushStyleColor(ctx, ImGui.Col_TabUnfocusedActive,        0x236C42FF)  -- was TabDimmedSelected
  -- ImGui.PushStyleColor(ctx, ImGui.Col_TabDimmedSelectedOverline, 0x80808000)  -- Doesn't exist in 0.9
  ImGui.PushStyleColor(ctx, ImGui.Col_DockingPreview,            0x42FAAAB3)
  ImGui.PushStyleColor(ctx, ImGui.Col_DockingEmptyBg,            C.grey_20)
  ImGui.PushStyleColor(ctx, ImGui.Col_PlotLines,                 0x9C9C9CFF)
  ImGui.PushStyleColor(ctx, ImGui.Col_PlotLinesHovered,          0xFF6E59FF)
  ImGui.PushStyleColor(ctx, ImGui.Col_PlotHistogram,             0xE6B300FF)
  ImGui.PushStyleColor(ctx, ImGui.Col_PlotHistogramHovered,      0xFF9900FF)
  ImGui.PushStyleColor(ctx, ImGui.Col_TableHeaderBg,             C.grey_05)
  ImGui.PushStyleColor(ctx, ImGui.Col_TableBorderStrong,         C.border_strong)
  ImGui.PushStyleColor(ctx, ImGui.Col_TableBorderLight,          C.grey_07)
  ImGui.PushStyleColor(ctx, ImGui.Col_TableRowBg,                0x0000000A)
  ImGui.PushStyleColor(ctx, ImGui.Col_TableRowBgAlt,             0xB0B0B00F)
  -- ImGui.PushStyleColor(ctx, ImGui.Col_TextLink,                  C.teal)  -- Doesn't exist in 0.9
  ImGui.PushStyleColor(ctx, ImGui.Col_TextSelectedBg,            0x41E0A366)
  -- ImGui.PushStyleColor(ctx, ImGui.Col_TreeLines,                 C.tree_lines)  -- Doesn't exist in 0.9
  ImGui.PushStyleColor(ctx, ImGui.Col_DragDropTarget,            0xFFFF00E6)
  -- ImGui.PushStyleColor(ctx, ImGui.Col_NavCursor,                 0x00EB7EFF)  -- Doesn't exist in 0.9
  ImGui.PushStyleColor(ctx, ImGui.Col_NavWindowingHighlight,     0xFFFFFFB3)
  ImGui.PushStyleColor(ctx, ImGui.Col_NavWindowingDimBg,         0xCCCCCC33)
  ImGui.PushStyleColor(ctx, ImGui.Col_ModalWindowDimBg,          0xCCCCCC59)
end

function M.PopMyStyle(ctx)
  -- 54 colors (60 original - 6 commented)
  -- 31 style vars (36 original - 5 commented)
  ImGui.PopStyleColor(ctx, 54)
  ImGui.PopStyleVar(ctx, 31)
end

return M