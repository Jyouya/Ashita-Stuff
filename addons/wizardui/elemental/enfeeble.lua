local shared = require('elemental.shared');
local GUI = require('J-GUI');
local tracker = require('tracker');
local bufftable = require('hxui.bufftable');

local wheel = tracker.wheelHandler;
local castHandler = tracker.castHandler;

local desaturate = require('functions.desaturate');
local getTexForStatus = require('functions.getTexForStatus');
local drawYellowBorder = require('functions.drawYellowBorder');
local drawRangeIndicator = require('functions.drawRangeIndicator');
local drawRecastIndicator = require('functions.drawRecastIndicator');

local ELEMENTAL_ENFEEBLE = T {
    FIRE = 'Burn',
    EARTH = 'Rasp',
    WATER = 'Drown',
    WIND = 'Choke',
    ICE = 'Frost',
    LIGHTNING = 'Shock'
}

local spells = ELEMENTAL_ENFEEBLE:map(function(spellName)
    return AshitaCore:GetResourceManager():GetSpellByName(spellName, 2);
end)

local availableSpells;
GUI.ctx.prerender:register(function()
    local recast = AshitaCore:GetMemoryManager():GetRecast();
    local playerMp = AshitaCore:GetMemoryManager():GetParty():GetMemberMP(0);

    availableSpells = T {};

    for element, spell in pairs(spells) do
        local spellRecast = recast:GetSpellTimer(spell.Index);
        local mpCost = spell.ManaCost;

        availableSpells[element] = T {
            recast = spellRecast,
            recastRatio = spellRecast / castHandler.getRecastForSpell(spell.Index),
            available = shared.hasSpell(spell) and spellRecast == 0 and playerMp >= mpCost or 0,
            nextWheel = (wheel.getNextElement(AshitaCore:GetMemoryManager():GetTarget():GetServerId(0)) == spell.Element)
        };
    end

    local target = AshitaCore:GetMemoryManager():GetTarget();

    local targetDebuffs = tracker.debuffHandler.GetActiveDebuffs(target:GetServerId(0)) or {};

    -- print(#tracker.debuffHandler.enemies);
    for spellCategory, spell in pairs(spells) do
        local buffId = bufftable.GetBuffIdBySpellId(spell.Index);

        if (targetDebuffs[buffId]) then
            availableSpells[spellCategory].applied = true;

            -- Link elemental enfeebles to opposing elements
            if (buffId == 132) then -- Shock
                availableSpells.WATER.applied = true;
                availableSpells.EARTH.applied = true;
            elseif (buffId == 131) then -- Rasp
                availableSpells.LIGHTNING.applied = true;
                availableSpells.WIND.applied = true;
            elseif (buffId == 130) then -- Choke
                availableSpells.EARTH.applied = true;
                availableSpells.ICE.applied = true;
            elseif (buffId == 129) then -- Frost
                availableSpells.WIND.applied = true;
                availableSpells.FIRE.applied = true;
            elseif (buffId == 128) then -- Burn
                availableSpells.ICE.applied = true;
                availableSpells.WATER.applied = true;
            elseif (buffId == 133) then -- Drown
                availableSpells.FIRE.applied = true;
                availableSpells.LIGHTNING.applied = true;
            end
        end
    end
end);

local function getTextureOpacity(element)
    return function()
        local spellData = availableSpells[element];
        return (spellData.available == 0) and 0.3 or (1.0 - 0.5 * (spellData.applied and 1 or 0));
    end
end

local function onClick(element)
    return function()
        local spellData = availableSpells[element];

        if (spellData.available == 0) then
            return;
        end
        local spellName = ELEMENTAL_ENFEEBLE[element]

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

local white = T { 255, 255, 255 };
local function drawTex(element)
    return function(button, pos)
        -- super:drawTex(pos);
        GUI.Button.drawTex(button, pos);

        local spellData = availableSpells[element];

        if ((spellData.available ~= 0) and spellData.nextWheel) then
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
            drawRangeIndicator(targetIndex, 20);
            self.ctx.sprite:Begin();
        end
    end
end


local function elementalEnfeebleButtonFactory(element)
    return GUI.Button:new({
        getColor = getColor(element),
        getTexture = getTexForStatus(ELEMENTAL_ENFEEBLE[element]),
        getTextureOpacity = getTextureOpacity(element),
        onClick = onClick(element),
        drawTex = drawTex(element),
        draw = draw(element)
    });
end

return elementalEnfeebleButtonFactory;
