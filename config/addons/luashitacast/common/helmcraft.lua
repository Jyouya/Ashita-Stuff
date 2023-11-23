local M = require('J-Mode');
local GUI = require('J-GUI');
local functions = require('J-GUI/functions');


local tradeBody = T {
    Fishing = 'Fsh. Tunica',
    ChocoboDigging = 'Choc. Jack Coat',
    HELM = 'Field Tunica',
};
local textures = T {};
local function getTexture(self, tradecraft)
    if (textures[tradecraft] or tradecraft == 'None') then
        return textures[tradecraft];
    end

    -- Load the crafting textures from assets
    local path = AshitaCore:GetInstallPath() .. 'config\\addons\\luashitacast\\assets\\32px-' .. tradecraft .. '.png';
    local handle = io.open(path, 'r');
    if (handle ~= nil) then
        handle.close();
        textures[tradecraft] = functions.loadAssetTexture(path);
        return textures[tradecraft];
    end

    if (tradeBody[tradecraft]) then
        local item = AshitaCore:GetResourceManager():GetItemByName(tradeBody[tradecraft], 0);

        if (item) then
            local itemId = item.Id;
            textures[tradecraft] = functions.loadItemTexture(itemId);
        end
    end

    return textures[tradecraft];
end

return function(settings, sets)
    settings.HELMCraft = M {
        'None',
        'HELM',
        'ChocoboDigging',
        'Fishing',
        'Woodworking',
        'Smithing',
        'Goldsmithing',
        'Clothcraft',
        'Leathercraft',
        'Bonecraft',
        'Alchemy',
        'Cooking'
    };
    settings.Rules = settings.Rules or T {};
    settings.Rules.Idle = settings.Rules.Idle or T {};
    settings.Rules.Idle:insert({
        test = function() return settings.HELMCraft.value ~= 'None' end,
        key = function() return settings.HELMCraft.value end
    });

    settings.Idle = settings.Idle or M { 'Default' };
    settings.Idle:options(table.unpack(settings.Idle), 'HELMCraft');

    local prevIdleMode
    settings.HELMCraft.on_change:register(function(m)
        if (m.value ~= 'None' and settings.Idle.value ~= 'HELMCraft') then
            prevIdleMode = settings.Idle.value;
            settings.Idle:set('HELMCraft');
        elseif (m.value == 'None') then
            settings.Idle:set(prevIdleMode);
        end
    end);

    sets.Idle_HELMCraft_HELM = {
        Body = 'Field Tunica',
        Hands = 'Field Gloves',
        Legs = 'Field Hose',
        Feet = 'Field Boots',
    };

    -- ! Add crafting sets here

    local HELMCraftUI = GUI.Container:new({
        layout = GUI.Container.LAYOUT.GRID,
        gridRows = GUI.Container.LAYOUT.AUTO,
        gridCols = 2,
        fillDirection = GUI.Container.LAYOUT.VERTICAL,
        gridGap = 4,
        padding = { x = 2, y = 2 },
        draggable = true,
        _x = 800,
        _y = 350,
    });
    GUI.ctx.addView(HELMCraftUI);

    local HELMCraftSelector = GUI.ItemSelector:new({
        color = T { 0, 255, 80 },
        animated = true,
        expandDirection = GUI.ENUM.DIRECTION.DOWN,
        getTexture = getTexture,
        variable = settings.HELMCraft,
        draggable = true,
    });

    HELMCraftUI:addView(HELMCraftSelector);
end
