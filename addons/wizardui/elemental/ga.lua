local ffi = require('ffi');
local shared = require('elemental.shared');
local GUI = require('J-GUI');
local desaturate = require('functions.desaturate');
local drawYellowBorder = require('functions.drawYellowBorder');
local drawRangeIndicator = require('functions.drawRangeIndicator');
local drawRecastIndicator = require('functions.drawRecastIndicator');

local wheel = require('tracker').wheelHandler;
local castHandler = require('tracker').castHandler;

local gaSpells = T {
    FIRE = T {},
    EARTH = T {},
    WATER = T {},
    WIND = T {},
    ICE = T {},
    LIGHTNING = T {},
};

local baseSpellNames = {
    FIRE = 'Fira',
    EARTH = 'Stone',
    WATER = 'Water',
    WIND = 'Aero',
    ICE = 'Blizza',
    LIGHTNING = 'Thunda'
};

for element, v in pairs(gaSpells) do
    local baseSpellName = baseSpellNames[element];
    local tiers = T { 'ja', 'ga III', 'ga II', 'ga', }
    for i, suffix in ipairs(tiers) do
        local spellName = baseSpellName .. suffix;
        local spell = AshitaCore:GetResourceManager():GetSpellByName(spellName, 2);
        v[i] = spell;
    end
end

local observedRecast = T {};

local availableSpells = T {};
GUI.ctx.prerender:register(function()
    local recast = AshitaCore:GetMemoryManager():GetRecast();
    local playerMp = AshitaCore:GetMemoryManager():GetParty():GetMemberMP(0);


    availableSpells = T {};

    for element, spells in pairs(gaSpells) do
        availableSpells[element] = (function()
            local res = T { available = 0 };
            for i, spell in ipairs(spells) do
                if (shared.hasSpell(spell)) then
                    local spellRecast = recast:GetSpellTimer(spell.Index);

                    if (res.recast == nil) then
                        res.recast = spellRecast;
                        local recastDelay = castHandler.getRecastForSpell(spell.Index);
                        res.recastRatio = spellRecast / recastDelay;
                    end

                    local mpCost = spell.ManaCost;

                    local targetId = AshitaCore:GetMemoryManager():GetTarget():GetServerId(0);
                    if (wheel.getNextElement(targetId) == spell.Element) then
                        res.nextWheel = true;
                    end

                    if (spellRecast == 0 and playerMp >= mpCost) then
                        res.available = 5 - i;
                        return res
                    end
                end
            end
            return res
        end)();
    end
end);

local function getTextureOpacity(element)
    return function()
        local spellData = availableSpells[element];
        return (spellData.available == 0) and 0.3 or 1.0;
    end
end

local tierOffset = T { 5, 2, 0, 1 };
local drawAoeElement;
local white = T { 255, 255, 255 };
do
    local vec_position = ffi.new('D3DXVECTOR2', { 0, 0, });
    local vec_scale = ffi.new('D3DXVECTOR2', { 1.0, 1.0, });
    local rect = ffi.new('RECT', { 0, 0, 16, 16 });
    drawAoeElement = function(element)
        return function(button, pos)
            -- print('debug');
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

            local spellData = availableSpells[element];
            local tier = spellData.available;

            if (tier == 0) then return; end
            local str;
            if (tier == 4) then
                str = 'ja';
            else
                str = shared.ROMAN_NUMERALS[tier];
            end

            GUI.text.write(pos.x + 20 + tierOffset[tier], pos.y + 20, 1, str);

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

local spellSuffix = T { 'ga', 'ga II', 'ga III', 'ja' }
local function onClick(element)
    return function()
        local spellData = availableSpells[element];
        local tier = spellData.available;

        if (tier == 0) then
            return;
        end
        local spellName = baseSpellNames[element] .. spellSuffix[tier];

        AshitaCore:GetChatManager():QueueCommand(-1, ('/ma "%s" <t>'):format(spellName));
    end
end

local function getColor(element)
    return function()
        local color = shared.ELEMENTAL_COLOR[element];
        local spellData = availableSpells[element];
        if (spellData.available == 0) then
            color = desaturate(color, 0.8);
        end
        return color;
    end
end

local function draw(element)
    return function(self)
        GUI.Button.draw(self);

        local ratio = availableSpells[element].recastRatio;
        if (ratio and ratio > 0) then
            drawRecastIndicator(self.ctx, self:getPos(), ratio,
                availableSpells[element].recast);
        end

        local targetIndex = AshitaCore:GetMemoryManager():GetTarget():GetTargetIndex(0);
        if (targetIndex > 0 and self._isHovered) then
            self.ctx.sprite:End();
            drawRangeIndicator(targetIndex, 21);
            self.ctx.sprite:Begin();
        end
    end
end

local function aoeElementalButtonFactory(element)
    return GUI.Button:new({
        getColor = getColor(element),
        getTexture = shared.getTexForElement(element),
        drawTex = drawAoeElement(element),
        getTextureOpacity = getTextureOpacity(element),
        onClick = onClick(element),
        draw = draw(element)
    });
end

return aoeElementalButtonFactory;
