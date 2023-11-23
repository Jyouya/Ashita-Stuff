local settings = require('settings');
local imgui = require('imgui');

local defaultSettings = T {
    alpha = 0x44 / 0xFF,
    targetLines = false,
    lineColor = 0xFF00FF66,
    songs = T {
        ['Requiem'] = T {
            color = 0x666633,
            display = false,
        },
        ['Lullaby'] = T {
            color = 0x333366,
            display = false,
        },
        ['Elegy'] = T {
            color = 0x99330,
            display = false,
        },
        ['Paeon'] = T {
            color = 0x0066CC, -- Blue
            display = true,
        },
        ['Ballad'] = T {
            color = 0x009900, -- Green
            display = true,
        },
        ['Minne'] = T {
            color = 0xCCCC00, -- Yellow
            display = true,
        },
        ['Minuet'] = T {
            color = 0xCC3333, -- Red
            display = true,
        },
        ['Madrigal'] = T {
            color = 0x9933CC, -- Purple
            display = true,
        },
        ['Prelude'] = T {
            color = 0xB8F3BD, -- Light Green
            display = false,
        },
        ['Mambo'] = T {
            color = 0x00CC00, -- Between ballad and prelude
            display = true,
        },
        ['Aubade'] = T {
            color = 0xA098C0, -- Light Blue
            display = true,
        },
        ['Pastoral'] = T {
            color = 0xA098C0, -- Light Blue
            display = true,
        },
        ['Hum'] = T {
            color = 0xA098C0, -- Light Blue
            display = true,
        },
        ['Fantasia'] = T {
            color = 0xA098C0, -- Light Blue
            display = true,
        },
        ['Operetta'] = T {
            color = 0xA098C0, -- Light Blue
            display = true,
        },
        ['Capriccio'] = T {
            color = 0xA098C0, -- Light Blue
            display = true,
        },
        ['Serenade'] = T {
            color = 0xA098C0, -- Light Blue
            display = true,
        },
        ['Round'] = T {
            color = 0xA098C0, -- Light Blue
            display = true,
        },
        ['Gavotte'] = T {
            color = 0xA098C0, -- Light Blue
            display = true,
        },
        ['Fugue'] = T {
            color = 0xA098C0, -- Light Blue
            display = true,
        },
        ['Rhapsody'] = T {
            color = 0xA098C0, -- Light Blue
            display = true,
        },
        ['Aria'] = T {
            color = 0xA098C0, -- Light Blue
            display = true,
        },
        ['March'] = T {
            color = 0x0099CC, -- Cerulean
            display = true,
        },
        ['Etude'] = T {
            color = 0x998366, -- Tan
            display = false,
        },
        ['Carol'] = T {
            color = 0x996600, -- Orange
            display = true,
        },
        ['Threnody'] = T {
            color = 0x006633, -- Dark Green
            display = false,
        },
        ['Hymnus'] = T {
            color = 0xD0B878, -- Gold
            display = false,
        },
        ['Mazurka'] = T {
            color = 0xEFD94B, -- Chocobo Yellow
            display = true,
        },
        ['Sirvente'] = T {
            color = 0xFF6666, -- Salmon
            display = true,
        },
        ['Dirge'] = T {
            color = 0x669999, -- Cadet Blue
            display = false,
        },
        ['Scherzo'] = T {
            color = 0x99CCCC, -- Teal
            display = true,
        },
        ['Nocturne'] = T {
            color = 0xA098C0, -- Light Blue
            display = true,
        },
        ['Finale'] = T {
            color = 0xA098C0, -- Light Blue
            display = true,
        },
    }
};

local s = settings.load(defaultSettings);

local showConfig = { false };
local config = T {};

config.drawWindow = function()
    if (showConfig[1]) then
        imgui.PushStyleColor(ImGuiCol_WindowBg, { 0, 0.06, .16, .9 });
        imgui.PushStyleColor(ImGuiCol_TitleBg, { 0, 0.06, .16, .7 });
        imgui.PushStyleColor(ImGuiCol_TitleBgActive, { 0, 0.06, .16, .9 });
        imgui.PushStyleColor(ImGuiCol_TitleBgCollapsed, { 0, 0.06, .16, .5 });
        imgui.PushStyleColor(ImGuiCol_Header, { 0, 0.06, .16, .7 });
        imgui.PushStyleColor(ImGuiCol_HeaderHovered, { 0, 0.06, .16, .9 });
        imgui.PushStyleColor(ImGuiCol_HeaderActive, { 0, 0.06, .16, 1 });
        imgui.PushStyleColor(ImGuiCol_FrameBg, { 0, 0.06, .16, 1 });
        imgui.SetNextWindowSize({ 400, 150 }, ImGuiCond_FirstUseEver);

        if (imgui.Begin(('Songcast Config'):fmt(addon.version), showConfig, bit.bor(ImGuiWindowFlags_NoSavedSettings))) then
            imgui.BeginChild("Config Options", { 0, 0 }, true);

            imgui.EndChild();
        end
        imgui.PopStyleColor(8);
        imgui.End();
    end
end

ashita.events.register('command', 'command_cb', function(e)
    -- Parse the command arguments
    local command_args = e.command:lower():args()
    if table.contains({ '/songcast' }, command_args[1]) then
        -- Toggle the config menu
        showConfig[1] = not showConfig[1];
        e.blocked = true;
    end
end);

ashita.events.register('d3d_present', 'config_cb', function()
    config.drawWindow();
end);

return config;
