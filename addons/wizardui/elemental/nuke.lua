require('common');

local ffi = require('ffi');
local GUI = require('J-GUI');

local shared = require('elemental.shared');

local desaturate = require('functions.desaturate');
local drawYellowBorder = require('functions.drawYellowBorder');
local drawRangeIndicator = require('functions.drawRangeIndicator');
local drawRecastIndicator = require('functions.drawRecastIndicator');

local wheel = require('tracker').wheelHandler;
local castHandler = require('tracker').castHandler;

local getTextureSize;
do
    local vec_size = ffi.new('D3DXVECTOR2', { 24.0, 24.0, });
    getTextureSize = function()
        return vec_size;
    end
end

local getRect16;
do
    local rect = ffi.new('RECT', { 0, 0, 16, 16 });
    getRect16 = function()
        return rect;
    end
end

local singleTargetElementalSpells = T {
    FIRE = T {},
    EARTH = T {},
    WATER = T {},
    WIND = T {},
    ICE = T {},
    LIGHTNING = T {},
};

for element, v in pairs(singleTargetElementalSpells) do
    local baseSpellName = shared.ELEMENTAL_SPELL[element];
    local tiers = T { ' V', ' IV', ' III', ' II', '', };
    for i, suffix in ipairs(tiers) do
        local spellName = baseSpellName .. suffix;
        local spell = AshitaCore:GetResourceManager():GetSpellByName(spellName, 2);
        v[i] = spell;
    end
end


-- ? Can we account for haste this way?
-- TODO: Hook action packets to get the exact recast at time of cast completion?


-- Highest level spell available
-- Recast on highest level spell known

-- Calculate what elemental spells are available prerender
local availableSpells = T {};
GUI.ctx.prerender:register(function()
    local recast = AshitaCore:GetMemoryManager():GetRecast();
    local playerMp = AshitaCore:GetMemoryManager():GetParty():GetMemberMP(0);

    availableSpells = T {};

    for element, spells in pairs(singleTargetElementalSpells) do
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
                        res.available = 6 - i;
                        return res
                    end
                end
            end
            return res
        end)();
        -- if (availableSpells[element].recastRatio > 0) then
        --     print(availableSpells[element].recastRatio);
        -- end
    end
end);

local function getTextureOpacity(element)
    return function()
        local spellData = availableSpells[element];
        -- return 1.0
        return (spellData.available == 0) and 0.3 or 1.0;
    end
end
local tierOffset = T { 5, 2, 0, 1, 3 };
local white = T { 255, 255, 255 };
local function drawTex(element)
    return function(self, pos)
        GUI.Button.drawTex(self, pos); -- Draw the element texture

        local spellData = availableSpells[element];
        local tier = spellData.available;

        if (tier == 0) then return; end
        local str = shared.ROMAN_NUMERALS[tier];

        GUI.text.write(pos.x + 20 + tierOffset[tier], pos.y + 20, 1, str);

        if (spellData.nextWheel) then
            drawYellowBorder(
                self.ctx,
                pos.x - 1,
                pos.y - 1,
                self:getWidth() + 2,
                self:getHeight() + 2,
                white,
                0.8);
        end
    end
end

local spellSuffix = T { '', ' II', ' III', ' IV', ' V' }
local function onClick(element)
    return function()
        local spellData = availableSpells[element];

        if (spellData.available == 0) then
            return;
        end
        local spellName = shared.ELEMENTAL_SPELL[element] .. spellSuffix[spellData.available];

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

local function singleTargetElementalButtonFactory(element)
    return GUI.Button:new({
        getColor = getColor(element),
        getTexture = shared.getTexForElement(element),
        getTextureSize = getTextureSize,
        getRect = getRect16,
        getTextureOpacity = getTextureOpacity(element),
        drawTex = drawTex(element),
        onClick = onClick(element),
        draw = draw(element)
    });
end

return singleTargetElementalButtonFactory;
