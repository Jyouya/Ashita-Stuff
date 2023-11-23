require('common');
local getTexForSpell = require('functions.getTexForSpell');
local drawRecastIndicator = require('functions.drawRecastIndicator');
local desaturate = require('functions.desaturate');
local drawRangeIndicator = require('functions.drawRangeIndicator');

local ffi = require('ffi');
local GUI = require('J-GUI');

local colors = require('elemental.shared').ELEMENTAL_COLOR;
local hasSpell = require('elemental.shared').hasSpell;
local ROMAN_NUMERALS = require('elemental.shared').ROMAN_NUMERALS;

local tracker = require('tracker');
local wheel = tracker.wheelHandler;
local castHandler = tracker.castHandler;
local bufftable = require('hxui.bufftable');

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

local tieredSpells = T {};
local availableSpells = T {};
GUI.ctx.prerender:register(function()
    local recast = AshitaCore:GetMemoryManager():GetRecast();
    local playerMp = AshitaCore:GetMemoryManager():GetParty():GetMemberMP(0);

    availableSpells = T {};
    for baseName, spells in pairs(tieredSpells) do
        availableSpells[baseName] = (function()
            local res = T { available = 0 };
            for i, spell in ipairs(spells) do
                if (hasSpell(spell)) then
                    local spellRecast = recast:GetSpellTimer(spell.Index);

                    if (res.recast == nil) then
                        res.recast = spellRecast;
                        local recastDelay = castHandler.getRecastForSpell(spell.Index);
                        res.recastRatio = spellRecast / recastDelay;
                    end

                    local mpCost = spell.ManaCost;
                    if (spellRecast == 0 and playerMp >= mpCost) then
                        res.available = #spells - i + 1;

                        local targetId = AshitaCore:GetMemoryManager():GetTarget():GetServerId(0);

                        return res;
                    end
                end
            end
            return res
        end)();
    end
end);

local getTextureSize;
do
    local vec_size = ffi.new('D3DXVECTOR2', { 24.0, 24.0, });
    getTextureSize = function()
        return vec_size;
    end
end


local function getTextureOpacity(baseName)
    return function()
        local spellData = availableSpells[baseName];

        return (spellData.available == 0) and 0.3 or (1.0 - 0.5 * (spellData.applied and 1 or 0));
    end
end

local tierOffset = T { 5, 2, 0 };
local drawAoE;
do
    local vec_position = ffi.new('D3DXVECTOR2', { 0, 0, });
    local vec_scale = ffi.new('D3DXVECTOR2', { 0.5, 0.5, });
    local rect = ffi.new('RECT', { 0, 0, 32, 32 });
    drawAoE = function(baseName)
        return function(button, pos)
            local tex = button:getTexture();

            if (not tex) then return; end

            local tint = button:getTextureTint();
            local alpha = bit.rshift(0xFF000000, 24) * button:getTextureOpacity();
            local color = bit.lshift(math.min(alpha, 255), 24) + bit.band(tint, 0xFFFFFF);

            vec_position.x = pos.x + 15 * button.ctx.vec_scale.x;
            vec_position.y = pos.y + 7 * button.ctx.vec_scale.y;

            button.ctx.sprite:Draw(tex, rect, vec_scale, nil, 0.0, vec_position, color);

            vec_position.x = vec_position.x - 8 * button.ctx.vec_scale.x;
            vec_position.y = vec_position.y + 8 * button.ctx.vec_scale.y;

            button.ctx.sprite:Draw(tex, rect, vec_scale, nil, 0.0, vec_position, color);

            local spellData = availableSpells[baseName];
            local tier = spellData.available;

            if (tier == 0) then return; end
            local str = ROMAN_NUMERALS[tier];

            GUI.text.write(pos.x + 20 + tierOffset[tier], pos.y + 20, 1, str);
        end
    end
end

local function drawTex(baseName)
    return function(button, pos)
        GUI.Button.drawTex(button, pos);

        local spellData = availableSpells[baseName];
        local tier = spellData.available;

        if (tier == 0) then return; end
        local str = ROMAN_NUMERALS[tier];

        GUI.text.write(pos.x + 20 + tierOffset[tier], pos.y + 20, 1, str);
    end
end

local spellSuffix = T { '', ' II', ' III' }
local function onClick(baseName)
    return function()
        local spellData = availableSpells[baseName];

        if (spellData.available == 0) then
            return;
        end
        local spellName = baseName .. spellSuffix[spellData.available];

        AshitaCore:GetChatManager():QueueCommand(-1, ('/ma "%s" <t>'):format(spellName));
    end
end

local function getColor(baseName, element)
    local color = colors[element];
    return function()
        local spellData = availableSpells[baseName];
        if (spellData.available == 0) then
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
            drawRecastIndicator(self.ctx, self:getPos(), ratio,
                availableSpells[baseName].recast);
        end

        local targetIndex = AshitaCore:GetMemoryManager():GetTarget():GetTargetIndex(0);
        if (targetIndex > 0 and self._isHovered) then
            self.ctx.sprite:End();
            drawRangeIndicator(targetIndex, 20);
            self.ctx.sprite:Begin();
        end
    end
end



local function divineNukeFactory(baseName, tiers, aoe)
    local spell = AshitaCore:GetResourceManager():GetSpellByName(baseName, 2);
    local element = elements[spell.Element];


    local spells = T {};

    if (tiers >= 3) then
        spells:insert(AshitaCore:GetResourceManager():GetSpellByName(baseName .. ' III', 2));
    end

    if (tiers >= 2) then
        spells:insert(AshitaCore:GetResourceManager():GetSpellByName(baseName .. ' II', 2));
    end

    spells:insert(spell);

    tieredSpells[baseName] = spells;

    return GUI.Button:new({
        getColor = getColor(baseName, element),
        getTexture = getTexForSpell(aoe and baseName:sub(1, -2) or baseName),
        getTextureSize = getTextureSize,
        getTextureOpacity = getTextureOpacity(baseName),
        drawTex = aoe and drawAoE(baseName) or drawTex(baseName),
        onClick = onClick(baseName),
        draw = draw(baseName)
    });
end

return divineNukeFactory;
