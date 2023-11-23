local ffi = require('ffi');
local GUI = require('J-GUI');

local functions = require('J-GUI/functions');

-- local shared = require('elemental.shared');
local hasSpell = require('elemental.shared').hasSpell;
local getTexForElement = require('elemental.shared').getTexForElement;
local ROMAN_NUMERALS = require('elemental.shared').ROMAN_NUMERALS;
local ELEMENTAL_COLOR = require('elemental.shared').ELEMENTAL_COLOR;
local drawYellowBorder = require('functions.drawYellowBorder');
local drawRangeIndicator = require('functions.drawRangeIndicator');
local drawRecastIndicator = require('functions.drawRecastIndicator');

local desaturate = require('functions.desaturate');

local wheel = require('tracker').wheelHandler;
local castHandler = require('tracker').castHandler;

local scrollRect = ffi.new('RECT', { 0, 16, 16, 32 });
local rect16 = ffi.new('RECT', { 0, 0, 16, 16 });


local elements = T {
    [0] = 'FIRE',
    [1] = 'ICE',
    [2] = 'WIND',
    [3] = 'EARTH',
    [4] = 'LIGHTNING',
    [5] = 'WATER',
    [6] = 'LIGHT',
    [7] = 'DARK'
};

local spells = T {};

local tierSuffixes = T {
    ': Ichi',
    ': Ni',
    ': San'
};
do
    local ninSpells = T {
        'Katon',
        'Suiton',
        'Raiton',
        'Doton',
        'Huton',
        'Hyoton'
    };

    for _, baseName in ipairs(ninSpells) do
        for i = 3, 1, -1 do
            local spellName = baseName + tierSuffixes[i];
            local spell = AshitaCore:GetResourceManager():GetSpellByName(spellName, 2);

            if (hasSpell(spell) or i == 1) then
                spells[baseName] = spell
                break;
            end
        end
    end
end


local availableSpells = T {};
GUI.ctx.prerender:register(function()
    local recast = AshitaCore:GetMemoryManager():GetRecast();
    local playerMp = AshitaCore:GetMemoryManager():GetParty():GetMemberMP(0);

    availableSpells = T {};

    for baseName, spell in pairs(spells) do
        local res = T { available = 0 };
        if (hasSpell(spell)) then
            local spellRecast = recast:GetSpellTimer(spell.Index);

            if (res.recast == nil) then
                res.recast = spellRecast;
                local recastDelay = castHandler.getRecastForSpell(spell.Index);
                res.recastRatio = spellRecast / recastDelay;
            end

            local mpCost = spell.ManaCost;

            if (spellRecast == 0 and playerMp >= mpCost) then
                res.available = 1;
            end

            local targetId = AshitaCore:GetMemoryManager():GetTarget():GetServerId(0);
            local nextWheel = wheel.getNextElement(targetId);
            if (nextWheel) then
                if (nextWheel == spell.Element) then
                    res.nextWheel = true;
                end
            end
        end

        availableSpells[baseName] = res;
    end
end);

local function getTier(spell)
    local spellName = spell.Name[3]
    if (spellName:sub(-2) == 'Ni') then
        return 2;
    elseif (spellName:sub(-3) == 'San') then
        return 3;
    else
        return 1;
    end
end

local tierOffset = T { 5, 2, 0, 1 };
local scrollColors = {
    [0] = 0x00d57a7d,
    [1] = 0x007ad5d9,
    [2] = 0x0079d57d,
    [3] = 0x00d5c07e,
    [4] = 0x00d57ada,
    [5] = 0x007b7bdb
};

local scrollTex;
local drawNinjutsu;
local stringTex;
do
    local vec_position = ffi.new('D3DXVECTOR2', { 0, 0, });
    local vec_scale = ffi.new('D3DXVECTOR2', { 1.0, 1.0, });
    local scrollScale = ffi.new('D3DXVECTOR2', { 1.5, 1.5 });
    local white = T { 255, 255, 255 };

    function drawNinjutsu(baseName)
        local eleTex;
        local element = elements[spells[baseName].Element];
        local baseScrollColor = scrollColors[spells[baseName].Element];
        local tier = getTier(spells[baseName]);

        local str = ROMAN_NUMERALS[tier];
        local strOffset = tierOffset[tier];
        return function(button, pos)
            scrollTex = scrollTex or functions.loadAssetTexture(addon.path .. 'assets/magicon.png');
            stringTex = stringTex or functions.loadAssetTexture(addon.path .. 'assets/ninjutsu.png');

            eleTex = eleTex or functions.loadAssetTexture(string.format(
                '%s/assets/weather/el%s.png',
                addon.path,
                string.lower(element)));

            if (not (scrollTex and stringTex and eleTex)) then
                return;
            end

            local tint = button:getTextureTint();
            local alpha = bit.rshift(0xFF000000, 24) * button:getTextureOpacity();
            alpha = bit.lshift(math.min(alpha, 255), 24);
            local color = alpha + bit.band(tint, 0xFFFFFF);

            vec_position.x = pos.x + 7;
            vec_position.y = pos.y + 7;

            -- Draw the scroll
            button.ctx.sprite:Draw(scrollTex, scrollRect, scrollScale, nil, 0.0, vec_position, color);

            local scrollColor = bit.bor(
                bit.band(baseScrollColor, 0x00FFFFFF),
                alpha
            );

            vec_position.x = pos.x + 10;
            vec_position.y = pos.y + 10;

            -- Draw the colored band around the scroll
            button.ctx.sprite:Draw(stringTex, rect16, scrollScale, nil, 0.0, vec_position, scrollColor);


            vec_position.y = pos.y + 4;
            vec_position.x = pos.x + 3;

            -- Draw the weather sprite
            button.ctx.sprite:Draw(eleTex, rect16, vec_scale, nil, 0.0, vec_position, color);

            local spellData = availableSpells[baseName];

            if (spellData.available > 0) then
                GUI.text.write(pos.x + 20 + strOffset, pos.y + 20, 1, str);
            end

            if (spellData.nextWheel) then
                drawYellowBorder(
                    button.ctx,
                    pos.x - 1,
                    pos.y - 1,
                    button:getWidth() + 2,
                    button:getHeight() + 2,
                    white,
                    0.8);
            end
        end
    end
end

local function getTextureOpacity(baseName)
    return function()
        local spellData = availableSpells[baseName];
        return (spellData.available == 0) and 0.3 or 1.0;
    end
end

local function onClick(baseName)
    return function()
        if (availableSpells[baseName].available == 0) then
            return;
        end
        AshitaCore:GetChatManager():QueueCommand(-1, ('/ma "%s" <t>'):format(spells[baseName].Name[3]));
    end
end

local function getColor(baseName)
    local element = elements[spells[baseName].Element];
    return function()
        local color = ELEMENTAL_COLOR[element];
        if (spells[baseName].available == 0) then
            color = desaturate(color, 0.8);
        end
        return color;
    end
end

local function draw(baseName)
    return function(self)
        GUI.Button.draw(self);

        local ratio = availableSpells[baseName].recastRatio;
        if (ratio and ratio > 0) then
            drawRecastIndicator(self.ctx, self:getPos(), availableSpells[baseName].recastRatio,
                availableSpells[baseName].recast);
        end

        local targetIndex = AshitaCore:GetMemoryManager():GetTarget():GetTargetIndex(0);
        if (targetIndex > 0 and self._isHovered) then
            self.ctx.sprite:End();
            drawRangeIndicator(targetIndex, 17);
            self.ctx.sprite:Begin();
        end
    end
end

local function elementalNinjutsuFactory(baseName)
    -- local spell = spells[baseName];
    return GUI.Button:new({
        getColor = getColor(baseName),
        onClick = onClick(baseName),
        drawTex = drawNinjutsu(baseName),
        getTextureOpacity = getTextureOpacity(baseName),
        draw = draw(baseName)
    });
end


return elementalNinjutsuFactory;
