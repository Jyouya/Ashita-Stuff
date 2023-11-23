-- Enfeebles that diminish enemy combat abilities

require('common');
local getTexForSpell = require('functions.getTexForSpell');
local drawRangeIndicator = require('functions.drawRangeIndicator');
local drawRecastIndicator = require('functions.drawRecastIndicator');
local desaturate = require('functions.desaturate');
local drawYellowBorder = require('functions.drawYellowBorder');

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

local getTextureSize;
do
    local vec_size = ffi.new('D3DXVECTOR2', { 24.0, 24.0, });
    getTextureSize = function()
        return vec_size;
    end
end


local tieredSpells = T {};
local availableSpells = T {};
GUI.ctx.prerender:register(function()
    local recast = AshitaCore:GetMemoryManager():GetRecast();
    local playerMp = AshitaCore:GetMemoryManager():GetParty():GetMemberMP(0);

    availableSpells = T {};
    for enfeeble, spells in pairs(tieredSpells) do
        -- if (enfeeble == 'Diaga') then print('sanity check'); end
        availableSpells[enfeeble] = (function()
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
                        if (wheel.getNextElement(targetId) == spell.Element) then
                            res.nextWheel = true;
                        end

                        return res;
                    end
                end
            end
            return res
        end)();
    end

    local target = AshitaCore:GetMemoryManager():GetTarget();

    local targetDebuffs = tracker.debuffHandler.GetActiveDebuffs(target:GetServerId(0)) or {};

    -- print(#tracker.debuffHandler.enemies);
    for spellCategory, spell in pairs(tieredSpells) do
        local buffId = bufftable.GetBuffIdBySpellId(spell[1].Index);

        if (targetDebuffs[buffId]) then
            availableSpells[spellCategory].applied = true;

            -- Link bio and dia statuses
            if (buffId == 134 and availableSpells.Bio) then
                availableSpells.Bio.applied = true;
            elseif (buffId == 135 and availableSpells.Dia) then
                availableSpells.Dia.applied = true;
            end
        end
    end
end);

local function getTextureOpacity(enfeeble)
    return function()
        local spellData = availableSpells[enfeeble];

        return (spellData.available == 0) and 0.3 or (1.0 - 0.5 * (spellData.applied and 1 or 0));
    end
end

local white = T { 255, 255, 255 };
local tierOffset = T { 5, 2, 0 };
local function drawTex(enfeeble)
    return function(button, pos)
        GUI.Button.drawTex(button, pos); -- Draw the enfeeble texture

        local spellData = availableSpells[enfeeble];
        local tier = spellData.available;

        if (tier == 0) then return; end
        local str = ROMAN_NUMERALS[tier];

        GUI.text.write(pos.x + 20 + tierOffset[tier], pos.y + 20, 1, str);

        if (spellData.nextWheel and not spellData.applied) then
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

local drawAoE;
do
    local vec_position = ffi.new('D3DXVECTOR2', { 0, 0, });
    local vec_scale = ffi.new('D3DXVECTOR2', { 0.5, 0.5, });
    local rect = ffi.new('RECT', { 0, 0, 32, 32 });
    drawAoE = function(enfeeble)
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

            local spellData = availableSpells[enfeeble];
            local tier = spellData.available;

            if (tier == 0) then return; end
            local str = ROMAN_NUMERALS[tier];

            GUI.text.write(pos.x + 20 + tierOffset[tier], pos.y + 20, 1, str);

            if (spellData.nextWheel and not spellData.applied) then
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

local spellSuffix = T { '', ' II', ' III' }
local function onClick(enfeeble)
    return function()
        local spellData = availableSpells[enfeeble];

        if (spellData.available == 0) then
            return;
        end
        local spellName = enfeeble .. spellSuffix[spellData.available];

        AshitaCore:GetChatManager():QueueCommand(-1, ('/ma "%s" <t>'):format(spellName));
    end
end

local function getColor(enfeeble, element)
    return function()
        local color = colors[element];
        local spellData = availableSpells[enfeeble];
        if (spellData.available == 0) then
            color = desaturate(color, 0.8);
        end
        return color;
    end
end

local function draw(enfeeble)
    return function(self)
        GUI.Button.draw(self);

        local ratio = availableSpells[enfeeble].recastRatio;
        if (ratio and ratio > 0) then
            drawRecastIndicator(self.ctx, self:getPos(), ratio,
                availableSpells[enfeeble].recast);
        end

        local targetIndex = AshitaCore:GetMemoryManager():GetTarget():GetTargetIndex(0);
        if (targetIndex > 0 and self._isHovered) then
            self.ctx.sprite:End();
            drawRangeIndicator(targetIndex, 20);
            self.ctx.sprite:Begin();
        end
    end
end

local function tieredEnfeeble(enfeeble, tiers)
    local spell = AshitaCore:GetResourceManager():GetSpellByName(enfeeble, 2);
    local element = elements[spell.Element];

    local spells = T {};
    if (tiers >= 3) then
        spells:insert(AshitaCore:GetResourceManager():GetSpellByName(enfeeble .. ' III', 3));
    end

    if (tiers >= 2) then
        spells:insert(AshitaCore:GetResourceManager():GetSpellByName(enfeeble .. ' II', 2));
    end

    spells:insert(spell);

    tieredSpells[enfeeble] = spells;


    return GUI.Button:new({
        -- color = colors[element],
        getColor = getColor(enfeeble, element),
        getTexture = getTexForSpell(enfeeble),
        getTextureSize = getTextureSize,
        getTextureOpacity = getTextureOpacity(enfeeble),
        drawTex = drawTex(enfeeble),
        onClick = onClick(enfeeble),
        draw = draw(enfeeble),
    });
end




local function tieredAoeEnfeeble(enfeeble, tiers)
    local spell = AshitaCore:GetResourceManager():GetSpellByName(enfeeble .. 'ga', 2);
    local element = elements[spell.Element];

    local spells = T {};
    if (tiers >= 3) then
        spells:insert(AshitaCore:GetResourceManager():GetSpellByName(enfeeble .. 'ga III', 2));
    end

    if (tiers >= 2) then
        spells:insert(AshitaCore:GetResourceManager():GetSpellByName(enfeeble .. 'ga II', 2));
    end

    spells:insert(spell);

    tieredSpells[enfeeble .. 'ga'] = spells;


    return GUI.Button:new({
        getColor = getColor(enfeeble, element),
        -- color = colors[element],
        getTexture = getTexForSpell(enfeeble),
        getTextureSize = getTextureSize,
        getTextureOpacity = getTextureOpacity(enfeeble .. 'ga'),
        drawTex = drawAoE(enfeeble .. 'ga'),
        onClick = onClick(enfeeble .. 'ga'),
        draw = draw(enfeeble .. 'ga'),
    });
end

return {
    -- twoTierEnfeeble = twoTierEnfeebleButtonFactory,
    -- threeTierEnfeeble = threeTierEnfeebleButtonFactory
    tieredEnfeeble = tieredEnfeeble,
    tieredAoeEnfeeble = tieredAoeEnfeeble
};
