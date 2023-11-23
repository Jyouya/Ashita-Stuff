local GUI = require('J-GUI');
local d3d = require('d3d8');
local settings = require('settings');
local functions = require('J-GUI/functions');

local statusHandler = require('tracker').statusHandler;
local party = require('tracker').party;
local castHandler = require('tracker').castHandler;

local BuffMenu = require('enhancing.BuffMenu');
local BuffMenuEntry = require('enhancing.BuffMenuEntry');

local getTexForSpell = require('functions.getTexForSpell');
local getTexForJob = require('functions.getTexForJob');
local canCastSpell = require('functions.canCastSpell');
local desaturate = require('functions.desaturate');
local drawRangeIndicator = require('functions.drawRangeIndicator');
local drawRecastIndicator = require('functions.drawRecastIndicator');

local hasSpell = require('elemental.shared').hasSpell;
local elementalColors = require('elemental.shared').ELEMENTAL_COLOR;

local buffColors = require('enhancing.buffColors');

local enhancingMagic = require('enhancing.enhancingMagic');

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

local trackedSpells = T {};
local availableSpells = T {};
GUI.ctx.prerender:register(function()
    local recast = AshitaCore:GetMemoryManager():GetRecast();
    local playerMp = AshitaCore:GetMemoryManager():GetParty():GetMemberMP(0);

    availableSpells = T {};
    for buff, spell in pairs(trackedSpells) do
        local spellData = T { available = 0 };
        if (hasSpell(spell)) then
            local spellRecast = recast:GetSpellTimer(spell.Index);

            if (spellData.recast == nil) then
                spellData.recast = spellRecast;
                local recastDelay = castHandler.getRecastForSpell(spell.Index);
                spellData.recastRatio = spellRecast / recastDelay;
            end

            local mpCost = spell.ManaCost;

            if (spellRecast == 0 and playerMp >= mpCost) then
                spellData.available = 1;
            end
        end
        availableSpells[buff] = spellData;
    end
end);

local function getChromeColor(spellName)
    local color = buffColors[spellName];
    if (not color) then
        local spell = trackedSpells[spellName];
        color = elementalColors[elements[spell.Element]];
    end
    return function()
        local finalColor = color;
        local spellData = availableSpells[spellName];
        if (spellData.available == 0) then
            finalColor = desaturate(color, 0.8);
        end

        return finalColor;
    end
end

local function getIconOpacity(spellName)
    return function()
        local spellData = availableSpells[spellName];
        return (spellData.available == 0) and 0.3 or 1.0;
    end
end


local getJobIconTex;
do
    local textures = T {};
    getJobIconTex = function(partyIndex)
        return function()
            local member = party[partyIndex];
            if (member.active == 0) then return; end
            local job = member.mainJob;
            return getTexForJob(job);
        end
    end
end

local function getPartyMemberColor(partyIndex, buff)
    return function(buffMenuEntry)
        local member = party[partyIndex];
        if (not member or member.active == 0) then
            return T { 80.0, 80.0, 80.0 };
        end

        if (buffMenuEntry:isTracked() and not member.buffs[buff]) then
            return T { 255.0, 100.0, 100.0 };
        else
            return T { 160.0, 160.0, 160.0 };
        end
    end
end

local function getPartyMemberName(partyIndex)
    return function()
        local member = party[partyIndex];
        if (member.active == 0) then
            return '';
        end
        return member and member.name or '';
    end
end

local function shouldDisplayPartyMember(partyIndex, buff)
    return function(buffMenuEntry)
        if (buffMenuEntry.parent.expanded) then
            return party[partyIndex];
        else
            local member = party[partyIndex];
            return buffMenuEntry:isTracked() and member and not member.buffs[buff] and member.active == 1;
        end
    end
end


local function onMenuEntryClick(partyIndex, buff)
    return function()
        local spellData = trackedSpells[buff];
        local spellName = spellData.Name[3];
        local targetName = party[partyIndex].name;

        AshitaCore:GetChatManager():QueueCommand(-1, ('/ma "%s" %s'):format(spellName, targetName))
    end
end

local function draw(spellName)
    return function(self)
        BuffMenu.draw(self);

        local ratio = availableSpells[spellName].recastRatio;
        if (ratio and ratio > 0 and not self:getHidden()) then
            drawRecastIndicator(self.ctx, self:getPos(), ratio,
                availableSpells[spellName].recast, self:getWidth(), self:getHeight());
        end
    end
end

local function drawBuffMenuEntry(partyIndex)
    return function(self)
        BuffMenuEntry.draw(self);

        if (partyIndex > 0 and self._isHovered) then
            self.ctx.sprite:End();
            drawRangeIndicator(party[partyIndex].targetIndex, 20);
            self.ctx.sprite:Begin();
        end
    end
end


--[[
* @param s - settings object
* @param spellName
* @return BuffMenu
]]
--
local function buffMenuFactory(s, spellName)
    local tiers = enhancingMagic[spellName];

    -- Get resource data for the highest tier of the spell we can cast.
    local spell = AshitaCore:GetResourceManager():GetSpellByName(spellName, 2);
    for _, name in ipairs(tiers) do
        if (canCastSpell(name)) then
            spell = AshitaCore:GetResourceManager():GetSpellByName(name, 2);
            break;
        end
    end

    trackedSpells[spellName] = spell;


    if (not s.enhancing[spellName]) then
        s.enhancing[spellName] = T {
            visible = true,
            x = 500,
            y = 500,
        };
    end


    local menu = BuffMenu:new({
        getIconTexture = getTexForSpell(spellName),
        getChromeColor = getChromeColor(spellName),
        getTitle = function() return spellName; end,
        getIconOpacity = getIconOpacity(spellName),
        draggable = true,
        onDragFinish = function(view)
            local pos = view:getPos();
            s.enhancing[spellName].x = pos.x;
            s.enhancing[spellName].y = pos.y;
            settings.save();
        end,
        getHidden = function()
            return not s.enhancing[spellName].visible;
        end,
        draw = draw(spellName),
        _width = 122,
        _x = s.enhancing[spellName].x,
        _y = s.enhancing[spellName].y
    });

    for i = 1, 6 do
        local menuEntry = BuffMenuEntry:new({
            getIconTexture = getJobIconTex(i),
            -- getIconOpacity -- ? Always 1.0?
            getColor = getPartyMemberColor(i, string.lower(spellName)),
            getText = getPartyMemberName(i),
            shouldDisplay = shouldDisplayPartyMember(i, string.lower(spellName)),
            onClick = onMenuEntryClick(i, spellName),
            draw = drawBuffMenuEntry(i),
        });

        menu:addView(menuEntry);
    end

    return menu;
end

return buffMenuFactory;
