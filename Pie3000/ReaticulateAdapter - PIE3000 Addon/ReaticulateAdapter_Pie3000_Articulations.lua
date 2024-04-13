--@noindex
--NoIndex: true

local r = reaper
local pie_path = r.GetResourcePath() .. "/Scripts/Sexan_Scripts/Pie3000/"
local getinfo = debug.getinfo(1, 'S');
local script_path = getinfo.source:match [[^@?(.*[\/])[^\/]-$]];

package.path = pie_path .. "?.lua;"
require('PieUtils') -- Assuming this module is correctly placed and accessible

package.path = script_path .. "?.lua;"

require('ReaticulateAdapter') -- Assuming this module is correctly placed and accessible

package.path = pie_path .. "?.lua;"

local CONTEXTS = {
    [1] = "arrange",
    [2] = "arrangeempty",
    [3] = "^arrange", -- ALL ARRANGE
    [4] = "tcp",
    [5] = "tcpfxparm",
    [6] = "tcpempty",
    [7] = "^tcp", -- ALL TCP
    [8] = "mastertcp",
    [9] = "mastertcpfxparm",
    [10] = "^mastertcp", -- ALL MASTER TCP
    [11] = "mcp",
    [12] = "mcpfxlist",
    [13] = "mcpsendlist",
    [14] = "^mcp", -- ALL MCP
    [15] = "mastermcp",
    [16] = "mastermcpfxlist",
    [17] = "mastermcpsendlist",
    [18] = "mastermcpempty",
    [19] = "^mastermcp", -- ALL MASTER MCP
    [20] = "envelope",
    [21] = "envcp",
    [22] = "^env", -- ALL ENV
    [23] = "item",
    [24] = "itemmidi",
    [25] = "^item", -- ALL ITEMS
    [26] = "trans",
    [27] = "ruler",
    [28] = "rulerregion_lane",
    [29] = "rulermarker_lane",
    [30] = "rulertempo_lane",
    [31] = "^ruler", -- ALL RULER
    [32] = "midi",
    [33] = "midipianoroll",
    [34] = "miditracklist",
    [35] = "midiruler",
    [36] = "midilane",
    [37] = "^midi", -- ALL MIDI
    [38] = "plugin",
    [39] = "spacer",
    [40] = "mediaexplorer",
}



STANDALONE_PIE = ReaticulateAdapter("Main")
--CONTEXT_LIMIT = CONTEXTS[37]



if STANDALONE_PIE then
    require('Sexan_Pie3000')
else
    r.ShowConsoleMsg("Menu does not exist")
end




function R3000_PostArticulationEvent(tbl)
    ARGUMENTS = tbl.argument
    dofile(script_path .. "/functions/ReaticulateAdapter_post_articulation_event.lua")
    ARGUMENTS = nil
end


function R3000_SwitchBank(tbl)
    ARGUMENTS = tbl.argument
    dofile(script_path .. "/functions/ReaticulateAdapter_switch_channel.lua")
    ARGUMENTS = nil
end

