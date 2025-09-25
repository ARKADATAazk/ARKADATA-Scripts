-- style.lua
-- Shared style helpers for ReaImGui
-- Exports:
--   M.PushMyStyle(ctx) / M.PopMyStyle(ctx)
--   M.palette   -> named colors (0xRRGGBBAA)
--   M.with_alpha(col, a) -> same color with new alpha (0..255)

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
  -- === StyleVars (36) ===
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_Alpha(),                       1)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_DisabledAlpha(),               0)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowPadding(),               8, 8)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowRounding(),              0)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowBorderSize(),            1)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowMinSize(),               32, 32)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowTitleAlign(),            0, 0.5)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ChildRounding(),               0)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ChildBorderSize(),             1)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_PopupRounding(),               0)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_PopupBorderSize(),             1)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(),                4, 2)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FrameRounding(),               0)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FrameBorderSize(),             1)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing(),                 8, 4)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemInnerSpacing(),            4, 4)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_IndentSpacing(),               22)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_CellPadding(),                 4, 2)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ScrollbarSize(),               14)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ScrollbarRounding(),           0)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_GrabMinSize(),                 12)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_GrabRounding(),                0)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ImageBorderSize(),             1)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_TabRounding(),                 0)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_TabBorderSize(),               1)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_TabBarBorderSize(),            1)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_TabBarOverlineSize(),          1)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_TableAngledHeadersAngle(),     0.401426)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_TableAngledHeadersTextAlign(), 0.5, 0)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_TreeLinesSize(),               1)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_TreeLinesRounding(),           0)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ButtonTextAlign(),             0.5, 0.51)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_SelectableTextAlign(),         0, 0)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_SeparatorTextBorderSize(),     3)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_SeparatorTextAlign(),          0, 0.5)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_SeparatorTextPadding(),        20, 3)

  -- === Colors (60) ===
  local A = M.with_alpha
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(),                      C.white)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TextDisabled(),              0x848484FF)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_WindowBg(),                  C.grey_14)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ChildBg(),                   0x0D0D0D00)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_PopupBg(),                   A(C.grey_08, 0xF0))
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Border(),                    C.border_soft)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_BorderShadow(),              0x00000000)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(),                   A(C.grey_06, 0x8A))
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgHovered(),            A(C.grey_08, 0x66))
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgActive(),             A(C.grey_18, 0xAB))
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBg(),                   C.grey_06)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBgActive(),             C.grey_08)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBgCollapsed(),          0x00000082)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_MenuBarBg(),                 C.grey_14)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarBg(),               C.scroll_bg)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrab(),             0x585858FF)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrabHovered(),      0x696969FF)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrabActive(),       0x828282FF)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_CheckMark(),                 0x42FAAAFF)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_SliderGrab(),                0x00FFA7FF)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_SliderGrabActive(),          C.red)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(),                    A(C.grey_05, 0x66))
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(),             C.grey_20)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(),              C.grey_18)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Header(),                    0x0000004F)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_HeaderHovered(),             C.teal_dark)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_HeaderActive(),              0x42FAD6FF)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Separator(),                 C.black)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_SeparatorHovered(),          0x1ABF9FC7)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_SeparatorActive(),           0x1ABF9AFF)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ResizeGrip(),                0x35353533)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ResizeGripHovered(),         0x262626AB)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ResizeGripActive(),          0x202020F2)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_InputTextCursor(),           C.white)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TabHovered(),                0x42FA8FCC)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Tab(),                       0x000000DC)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TabSelected(),               C.grey_08)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TabSelectedOverline(),       C.grey_27)  -- now defined
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TabDimmed(),                 0x11261FF8)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TabDimmedSelected(),         0x236C42FF)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TabDimmedSelectedOverline(), 0x80808000)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_DockingPreview(),            0x42FAAAB3)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_DockingEmptyBg(),            C.grey_20)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_PlotLines(),                 0x9C9C9CFF)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_PlotLinesHovered(),          0xFF6E59FF)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_PlotHistogram(),             0xE6B300FF)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_PlotHistogramHovered(),      0xFF9900FF)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TableHeaderBg(),             C.grey_05)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TableBorderStrong(),         C.border_strong)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TableBorderLight(),          C.grey_07)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TableRowBg(),                0x0000000A)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TableRowBgAlt(),             0xB0B0B00F)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TextLink(),                  C.teal)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TextSelectedBg(),            0x41E0A366)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TreeLines(),                 C.tree_lines)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_DragDropTarget(),            0xFFFF00E6)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_NavCursor(),                 0x00EB7EFF)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_NavWindowingHighlight(),     0xFFFFFFB3)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_NavWindowingDimBg(),         0xCCCCCC33)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ModalWindowDimBg(),          0xCCCCCC59)
end

function M.PopMyStyle(ctx)
  reaper.ImGui_PopStyleColor(ctx, 60)
  reaper.ImGui_PopStyleVar(ctx, 36)
end

return M
