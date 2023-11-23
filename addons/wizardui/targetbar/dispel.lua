local getTexForSpell = require('functions.getTexForSpell');
local drawRangeIndicator = require('functions.drawRangeIndicator');
local drawRecastIndicator = require('functions.drawRecastIndicator');
local desaturate = require('functions.desaturate');
local drawYellowBorder = require('functions.drawYellowBorder');

local ffi = require('ffi');
local GUI = require('J-GUI');

local colors = require('elemental.shared').ELEMENTAL_COLOR;
local hasSpell = require('elemental.shared').hasSpell;

local tracker = require('tracker');
local castHandler = tracker.castHandler;
local statusHandler = tracker.statusHandler;


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

local spells = T {};
local availableSpells = T {};
GUI.ctx.prerender:register(function()
    local recast = AshitaCore:GetMemoryManager():GetRecast();
    local playerMp = AshitaCore:GetMemoryManager():GetParty():GetMemberMP(0);

    availableSpells = T {};

    -- if (enfeeble == 'Diaga') then print('sanity check'); end
    for spellName, spell in pairs(spells) do
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
        end

        availableSpells[spellName] = res;
    end
end);

local function getTextureOpacity(spellName)
    return function()
        local spellData = availableSpells[spellName];

        return (spellData.available == 0) and 0.3 or 1.0;
    end
end

local white = T { 255, 255, 255 };
local function drawTex(spellName)
    return function(self, pos)
        GUI.Button.drawTex(self, pos);

        if (self:getIsBuffed()) then
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


local function draw(spellName)
    return function(self)
        GUI.Button.draw(self);

        local ratio = availableSpells[spellName].recastRatio;
        if (ratio and ratio > 0) then
            drawRecastIndicator(self.ctx, self:getPos(), ratio,
                availableSpells[spellName].recast, self:getWidth(), self:getHeight());
        end

        local targetIndex = AshitaCore:GetMemoryManager():GetTarget():GetTargetIndex(0);
        if (targetIndex > 0 and self._isHovered) then
            self.ctx.sprite:End();
            drawRangeIndicator(targetIndex, 20);
            self.ctx.sprite:Begin();
        end
    end
end

local function onClick(spellName)
    return function()
        local spellData = availableSpells[spellName];

        if (spellData.available == 0) then
            return;
        end

        AshitaCore:GetChatManager():QueueCommand(-1, ('/ma "%s" <t>'):format(spellName));
    end
end

local function getColor(spellName, element)
    return function()
        local color = colors[element];
        local spellData = availableSpells[spellName];
        if (spellData.available == 0) then
            color = desaturate(color, 0.8);
        end
        return color;
    end
end

local function shouldDisplay(spellName)
    local spell = AshitaCore:GetResourceManager():GetSpellByName(spellName, 2);
    return function()
        if (not hasSpell(spell)) then
            return false
        end

        local targetIndex = AshitaCore:GetMemoryManager():GetTarget():GetTargetIndex(0);

        if (targetIndex) then
            local spawnFlags = AshitaCore:GetMemoryManager():GetEntity():GetSpawnFlags(targetIndex);
            if (bit.band(spawnFlags, 1) == 1) then
                -- Player
                local serverId = AshitaCore:GetMemoryManager():GetEntity():GetServerId(targetIndex);
                local buffs = statusHandler.get_member_status(serverId);
                return buffs and buffs.charm;
                -- Return true only if player is charmed
            elseif (bit.band(spawnFlags, 2) == 2) then
                -- NPC
                return false;
            elseif (bit.band(spawnFlags, 0x100) ~= 0) then
                -- Pet
                return false;
            else
                -- Mob
                return true;
            end
        end
    end
end

local function dispelButton(spellName, tier)
    local spell = AshitaCore:GetResourceManager():GetSpellByName(spellName, 2);
    local element = elements[spell.Element];

    spells[spellName] = spell;
    return GUI.Button:new({
        getColor = getColor(spellName, element),
        getTexture = getTexForSpell(spellName),
        getTextureSize = getTextureSize,
        getTextureOpacity = getTextureOpacity(spellName),
        -- drawTex = drawTex(spellName),
        onClick = onClick(spellName),
        drawTex = drawTex(spellName),
        draw = draw(spellName),
        shouldDisplay = shouldDisplay(spellName),
        -- _width = 32,
        -- _height = 32,
    });
end

return dispelButton;
