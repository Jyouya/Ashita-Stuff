local ffi = require('ffi');

local GUI = require('J-GUI');
local functions = require('J-GUI/functions');

local canCastSpell = require('functions.canCastSpell');
local getTexForJob = require('functions.getTexForJob');
local getTexForSpell = require('functions.getTexForSpell');
local drawBlueBorder = require('functions.drawBlueBorder');
local getIndexFromId = require('functions.getIndexFromId');
local drawRecastIndicator = require('functions.drawRecastIndicator');
local drawRangeIndicator = require('functions.drawRangeIndicator');
local getAoeTargets = require('functions.getAoeTargets');

local hasSpell = require('elemental.shared').hasSpell;

local nas = require('healing.nas');
local HPBar = require('healing.cure.HPBar');
local CastBar = require('healing.cure.CastBar');
local StatusBar = require('healing.cure.StatusBar');

local tracker = require('tracker');
local party = tracker.party;
local castHandler = tracker.castHandler;

local bufftable = require('hxui.bufftable');

local trackedSpells = T {
    cure = T {},
    curaga = T {},
    raise = T {}
};

local availableSpells = T {
    cure = T {},
    curaga = T {},
    raise = T {}
};

local curesKnown = 0;
local curePotency = T {};
local curagaPotency = T {};

local recommendedCure = T {};

local function getHP(partyIndex)
    return function()
        return party[partyIndex].hp;
    end
end

local function getHPP(partyIndex)
    return function()
        return party[partyIndex].hpp;
    end
end

local function getMP(partyIndex)
    return function()
        return party[partyIndex].mp;
    end
end

local function getMPP(partyIndex)
    return function()
        return party[partyIndex].mpp;
    end
end

local function getTP(partyIndex)
    return function()
        return party[partyIndex].tp;
    end
end

local function getName(partyIndex)
    return function()
        return party[partyIndex].name;
    end
end

local getJobIconTex;
do
    getJobIconTex = function(partyIndex)
        return function()
            local member = party[partyIndex];
            if (member.active == 0) then return; end
            local job = member.mainJob;
            return getTexForJob(job);
        end
    end
end

local function targetMember(partyIndex)
    return function()
        AshitaCore:GetMemoryManager():GetTarget():SetTarget(party[partyIndex].targetIndex, false);
    end
end

local getCureTexSize;
do
    local vec_size = ffi.new('D3DXVECTOR2', { 26.0, 26.0, });
    getCureTexSize = function()
        return vec_size;
    end
end

local function getCureTexOpacity(partyIndex, tier)
    return function()
        return (availableSpells.cure[tier].available == 0) and 0.3 or 1.0;
    end
end

local function getCuragaTexOpacity(partyIndex, tier)
    return function()
        return (availableSpells.curaga[tier].available == 0) and 0.3 or 1.0;
    end
end

local function getRaiseTexOpacity(partyIndex, tier)
    return function()
        local spellData = trackedSpells.raise[tier];
        local mpCost = spellData.ManaCost;
        return (party[1].mp < mpCost or availableSpells.raise[tier].available == 0) and 0.3 or 1.0;
    end
end


local hoveredCure = T { 0, 0, 0, 0, 0, 0 };


local function cureButtonMouseExit(partyIndex)
    return function(self, e)
        GUI.Button.onMouseExit(self, e);
        hoveredCure[partyIndex] = 0;
    end
end

local function cureButtonMouseEnter(partyIndex, tier)
    return function(self)
        -- GUI.Button.onMouseEnter(self);
        hoveredCure[partyIndex] = tier;
    end
end

local hoveredCuraga = T {
    target = nil,
    tier = nil,
};
local function curagaButtonMouseEnter(partyIndex, tier)
    return function(self)
        hoveredCuraga.target = party[partyIndex].targetIndex;
        hoveredCuraga.tier = tier;
    end
end

local function curagaButtonMouseExit(partyIndex)
    return function(self, e)
        GUI.Button.onMouseExit(self, e)
        hoveredCuraga.target = nil;
        hoveredCuraga.tier = nil;
    end
end

local ctrlPressed;
ashita.events.register('key', 'key_ctrl_callback', function(e)
    -- Key: VK_CONTROL
    if (e.wparam == 0x11) then
        ctrlPressed = not (bit.band(e.lparam, bit.lshift(0x8000, 0x10)) == bit.lshift(0x8000, 0x10));
    end
end);

local function shouldDisplayCures(partyIndex)
    return function()
        return party[partyIndex].hp > 0 and not ctrlPressed;
    end
end

local function shouldDisplayCuragas(partyIndex)
    return function()
        return party[partyIndex].hp > 0 and ctrlPressed;
    end
end

local function shouldDisplayRaises(partyIndex)
    return function()
        return party[partyIndex].hp == 0;
    end
end

local spellSuffix = T {
    '',
    ' II',
    ' III',
    ' IV',
    ' V',
    ' VI'
};
GUI.ctx.prerender:register(function()
    local recast = AshitaCore:GetMemoryManager():GetRecast();
    local playerMp = AshitaCore:GetMemoryManager():GetParty():GetMemberMP(0);

    for _, category in ipairs({ 'cure', 'curaga', 'raise' }) do
        availableSpells[category] = T {};
        for tier, spell in pairs(trackedSpells[category]) do
            local spellData = T { available = 0 };
            if (hasSpell(spell)) then
                local spellRecast = recast:GetSpellTimer(spell.Index);

                if (spellData.recast == nil) then
                    local recastDelay = castHandler.getRecastForSpell(spell.Index);
                    spellData.recast = spellRecast;
                    spellData.recastRatio = spellRecast / recastDelay;
                end

                local mpCost = spell.ManaCost;

                if (spellRecast == 0 and playerMp >= mpCost) then
                    spellData.available = 1;
                end
            end
            availableSpells[category][tier] = spellData;
        end
    end

    -- Find recommended cure for each member
    for i = 1, 6 do
        local member = party[i];
        if (member and member.active == 1) then
            recommendedCure[i] = 0;
            local missingHP = 100 * member.hp / member.hpp - member.hp;

            -- add 5% for overheal tolerance
            missingHP = missingHP * 1.05;
            for j = 1, curesKnown do
                -- for j, potency in ipairs(curePotency) do
                if (availableSpells.cure[j] ~= 0) then
                    if (curePotency[j] > missingHP) then
                        break;
                    else
                        recommendedCure[i] = j;
                    end
                end
            end
        end
    end


    if (hoveredCuraga.target) then
        local aoeTargets = getAoeTargets(
            trackedSpells.curaga[hoveredCuraga.tier],
            hoveredCuraga.target
        );

        for _, partyIndex in ipairs(aoeTargets) do
            party[partyIndex].isAoeTarget = true;
        end
    end
end);

local function getIsAoeTarget(partyIndex)
    return function()
        return party[partyIndex].isAoeTarget;
    end
end

local raises = T {
    [12] = 'Raise',
    [13] = 'Raise II',
    [140] = 'Raise III',
    [494] = 'Arise',
    [264] = 'Tractor',
    [265] = 'Tractor II',
};

local pendingRaises = T {};

tracker.castHandler.spellCompletion:register(function(castData)
    if (raises[castData.spellId]) then
        local targetId = castData.targetId
        for partyIndex, member in ipairs(party) do
            if (targetId == member.serverId) then
                pendingRaises[partyIndex] = raises[castData.spellId];
                return;
            end
        end
    end
end);

local red = T { 255, 127, 127 };
local green = T { 127, 255, 127 };
local blue = T { 127, 127, 255 };

local function getRaiseData(partyIndex)
    return function()
        if (party[partyIndex].hp > 0) then
            pendingRaises[partyIndex] = nil;
            return;
        end

        if (pendingRaises[partyIndex]) then
            return T {
                color = blue,
                text = { pendingRaises[partyIndex] },
            };
        end

        local raiseData = T {
            text = T {},
        };

        local casts = tracker.castHandler.getCastsByTarget(party[partyIndex].serverId);
        if (not casts or #casts == 0) then return end

        for _, cast in ipairs(casts) do
            local raise = raises[cast.spellId];
            if (raise) then
                local casterName = AshitaCore:GetMemoryManager():GetEntity():GetName(cast.actorIndex);
                raiseData.text:insert(('%s: %s'):format(casterName, raise));
            end
        end
        if (#raiseData.text > 1) then
            raiseData.color = red;
        elseif (#raiseData.text == 1) then
            raiseData.color = green;
        end
        return raiseData;
    end
end

local function getDistance(partyIndex)
    if (partyIndex == 1) then
        return function() return -1; end
    end
    return function()
        local index = party[partyIndex].index;
        local playerIndex = party[1].index;
        local entity = AshitaCore:GetMemoryManager():GetEntity()
        local distance = entity:GetDistance(index);

        local calcDistance = (
                entity:GetLocalPositionX(index) - entity:GetLocalPositionX(playerIndex)) ^ 2
            + (entity:GetLocalPositionY(index) - entity:GetLocalPositionY(playerIndex)) ^ 2

        if (math.abs(distance - calcDistance) < 1) then
            return math.sqrt(distance);
        else
            return -1;
        end
    end
end


local spellTiers = T {
    'I',
    'II',
    'III',
    'IV',
    'V',
    'VI'
};

local function drawCure2(partyIndex, tier)
    return function(self)
        GUI.Button.draw(self);
        local pos = self:getPos();
        local str = spellTiers[tier];
        local textWidth = GUI.text.size(2, str) * 3 / 8; -- Half the final scaled width
        GUI.text.write(pos.x + 16 - textWidth, pos.y + 6, 2, str, nil, 0.75);
        if (availableSpells.curaga[tier].available ~= 0) then
            -- Draw twice for opaque text
            GUI.text.write(pos.x + 16 - textWidth, pos.y + 6, 2, str, nil, 0.75);
        end

        local ratio = availableSpells.curaga[tier].recastRatio;
        if (ratio and ratio > 0) then
            drawRecastIndicator(self.ctx, self:getPos(), ratio,
                availableSpells.curaga[tier].recast, self:getWidth(), self:getHeight());
        end

        if (partyIndex > 0 and self._isHovered) then
            self.ctx.sprite:End();
            drawRangeIndicator(party[partyIndex].targetIndex, 20.5);
            self.ctx.sprite:Begin();
        end
    end
end

local function drawRaise(partyIndex, tier)
    return function(self)
        GUI.Button.draw(self);
        local pos = self:getPos();
        local str = spellTiers[tier];
        local textWidth = GUI.text.size(2, str) * 3 / 8; -- Half the final scaled width
        GUI.text.write(pos.x + 16 - textWidth, pos.y + 6, 2, str, nil, 0.75);
        if (availableSpells.raise[tier].available ~= 0) then
            -- Draw twice for opaque text
            GUI.text.write(pos.x + 16 - textWidth, pos.y + 6, 2, str, nil, 0.75);
        end

        local ratio = availableSpells.raise[tier].recastRatio;
        if (ratio and ratio > 0) then
            drawRecastIndicator(self.ctx, self:getPos(), ratio,
                availableSpells.raise[tier].recast, self:getWidth(), self:getHeight());
        end

        if (partyIndex > 0 and self._isHovered) then
            self.ctx.sprite:End();
            drawRangeIndicator(party[partyIndex].targetIndex, 20.5);
            self.ctx.sprite:Begin();
        end
    end
end



local white = T { 255, 255, 255 };
local function drawCure(partyIndex, tier)
    return function(self)
        GUI.Button.draw(self);
        local pos = self:getPos();
        local str = spellTiers[tier];
        local textWidth = GUI.text.size(2, str) * 3 / 8; -- Half the final scaled width
        GUI.text.write(pos.x + 16 - textWidth, pos.y + 6, 2, str, nil, 0.75);
        if (availableSpells.cure[tier].available ~= 0) then
            -- Draw twice for opaque text
            GUI.text.write(pos.x + 16 - textWidth, pos.y + 6, 2, str, nil, 0.75);
        end

        -- print(party[partyIndex].recommendedCure);
        if (recommendedCure[partyIndex] == tier) then
            drawBlueBorder(self.ctx, pos.x - 1, pos.y - 1, self:getWidth() + 2, self:getHeight() + 2, white, 0.8)
        end

        local ratio = availableSpells.cure[tier].recastRatio;
        if (ratio and ratio > 0) then
            drawRecastIndicator(self.ctx, self:getPos(), ratio,
                availableSpells.cure[tier].recast, self:getWidth(), self:getHeight());
        end

        -- print(self._isHovered);
        if (partyIndex > 0 and self._isHovered) then
            self.ctx.sprite:End();
            drawRangeIndicator(party[partyIndex].targetIndex, 20.5);
            self.ctx.sprite:Begin();
        end
    end
end

local function onCureClick(partyIndex, tier)
    return function()
        local spellData = trackedSpells.cure[tier];
        local spellName = spellData.Name[3];
        local targetName = party[partyIndex].name;
        AshitaCore:GetChatManager():QueueCommand(-1, ('/ma "%s" %s'):format(spellName, targetName))
    end
end

local function onCuragaClick(partyIndex, tier)
    return function()
        local spellData = trackedSpells.curaga[tier];
        local spellName = spellData.Name[3];
        local targetName = party[partyIndex].name;
        AshitaCore:GetChatManager():QueueCommand(-1, ('/ma "%s" %s'):format(spellName, targetName))
    end
end

local function onRaiseClick(partyIndex, tier)
    return function()
        local spellData = trackedSpells.raise[tier];
        local spellName = spellData.Name[3];
        local targetName = party[partyIndex].name;
        AshitaCore:GetChatManager():QueueCommand(-1, ('/ma "%s" %s'):format(spellName, targetName))
    end
end


local function cureButtonFactory(partyIndex, tier)
    local spellName = 'Cure' .. spellSuffix[tier]
    trackedSpells.cure[tier] = AshitaCore:GetResourceManager():GetSpellByName(spellName, 2);
    hoveredCure[partyIndex] = 0;
    return GUI.Button:new({
        _width = 32,
        _height = 32,
        getTexture = getTexForSpell('Cure'),
        getTextureSize = getCureTexSize,
        getTextureOpacity = getCureTexOpacity(partyIndex, tier),
        onMouseExit = cureButtonMouseExit(partyIndex),
        onMouseEnter = cureButtonMouseEnter(partyIndex, tier),
        onClick = onCureClick(partyIndex, tier),
        shouldDisplay = shouldDisplayCures(partyIndex),
        draw = drawCure(partyIndex, tier),
    });
end

local function curagaButtonFactory(partyIndex, tier)
    local spellName = 'Curaga' .. spellSuffix[tier];
    trackedSpells.curaga[tier] = AshitaCore:GetResourceManager():GetSpellByName(spellName, 2);
    hoveredCure[partyIndex] = 0;
    return GUI.Button:new({
        _width = 32,
        _height = 32,
        getTexture = getTexForSpell('Curaga'),
        getTextureSize = getCureTexSize,
        getTextureOpacity = getCuragaTexOpacity(partyIndex, tier),
        onMouseExit = curagaButtonMouseExit(partyIndex),
        onMouseEnter = curagaButtonMouseEnter(partyIndex, tier),
        onClick = onCuragaClick(partyIndex, tier),
        shouldDisplay = shouldDisplayCuragas(partyIndex),
        draw = drawCure2(partyIndex, tier),
    });
end

local function raiseButtonFactory(partyIndex, tier)
    local spellName;
    if (tier == 4) then
        spellName = 'Arise';
    else
        spellName = 'Raise' .. spellSuffix[tier];
    end
    trackedSpells.raise[tier] = AshitaCore:GetResourceManager():GetSpellByName(spellName, 2);
    hoveredCure[partyIndex] = 0;
    return GUI.Button:new({
        _width = 32,
        _height = 32,
        getTexture = getTexForSpell('Raise'),
        getTextureSize = getCureTexSize,
        getTextureOpacity = getRaiseTexOpacity(partyIndex, tier),
        onClick = onRaiseClick(partyIndex, tier),
        shouldDisplay = shouldDisplayRaises(partyIndex),
        draw = drawRaise(partyIndex, tier),
    });
end


local function partyMemberActive(partyIndex)
    if (partyIndex == 1) then
        return function()
            return true;
        end
    end

    return function()
        return party[partyIndex].active == 1 and party[partyIndex].zone == party[1].zone;
    end
end

local function getEnmityIndicatorOpacity(partyIndex)
    return function()
        local lastAttacked = tracker.castHandler.getLastAttacked(party[partyIndex].serverId);

        return math.max(0, math.min(1, 1.3 - (os.clock() - lastAttacked) * 0.1));
    end
end



local function getSpellName(partyIndex)
    return function()
        local cast = tracker.castHandler.getCastByCaster(party[partyIndex].serverId);
        if (cast) then
            return cast.spellName;
        end
        return '';
    end
end

local function getTargetName(partyIndex)
    return function()
        local cast = tracker.castHandler.getCastByCaster(party[partyIndex].serverId);
        if (cast) then
            local targetIndex = getIndexFromId(cast.targetId);

            return AshitaCore:GetMemoryManager():GetEntity():GetName(targetIndex);
        end
        return '';
    end
end

local function getFillRatio(partyIndex)
    return function()
        local cast = tracker.castHandler.getCastByCaster(party[partyIndex].serverId);

        if (cast) then
            return (os.clock() - cast.startTime) / cast.castTime;
        end
        return 0;
    end
end

local function getIsTarget(partyIndex)
    return function()
        local target = AshitaCore:GetMemoryManager():GetTarget():GetServerId(0);
        return target == party[partyIndex].serverId;
    end
end

local function getIsSubtarget(partyIndex)
    return function()
        local subtarget = AshitaCore:GetMemoryManager():GetTarget():GetServerId(1);
        return AshitaCore:GetMemoryManager():GetTarget():GetIsSubTargetActive() and
            (subtarget == party[partyIndex].serverId);
    end
end

local statuses = T {};
for _, na in ipairs(nas) do
    for _, debuff in ipairs(na.debuffs) do
        statuses[debuff] = na.spell;
    end
end
-- local isBuff = T {};
-- for buffId, isDebuff in pairs(bufftable.statusEffects) do
--     local buffName = AshitaCore:GetResourceManager():GetString('buffs.names', buffId);

--     if (buffName) then
--         isBuff[string.lower(buffName)] = isDebuff == 0;
--     end
-- end

local function statusBarFactory(partyIndex)
    local buffs = T {};
    local debuffs = T {};
    local bar = StatusBar:new({
        _width = 0,
        _height = 32,
        getDebuffs = function()
            buffs = T {};
            debuffs = T {};
            for _, buffId in ipairs(party[partyIndex].rawBuffs or {}) do
                if (buffId > -1) then
                    local buffName = AshitaCore:GetResourceManager():GetString('buffs.names', buffId);
                    if (bufftable.statusEffects[buffId] == 0) then
                        buffs:insert(buffName);
                    else
                        debuffs:insert({
                            name = buffName,
                            cleanse = statuses[buffName]
                        });
                    end
                end
            end
            return debuffs;
        end,
        getBuffs = function()
            return buffs;
        end
    });
    return bar;
end




local function partyEntryFactory(s, partyIndex)
    curePotency = s.healing.cure.potency;
    curagaPotency = s.healing.cure.curagaPotency;
    for i = 6, 1, -1 do
        if (canCastSpell('Cure' .. spellSuffix[i])) then
            curesKnown = i;
            break;
        end
    end

    local function getCureHPP()
        return function()
            if (hoveredCure[partyIndex] > 0 or hoveredCuraga.target and party[partyIndex].isAoeTarget) then
                local potency;
                if (hoveredCuraga.target) then
                    potency = curagaPotency[hoveredCuraga.tier];
                else
                    potency = curePotency[hoveredCure[partyIndex]];
                end

                local member = party[partyIndex];
                local memberMaxHP = 100 * member.hp / member.hpp;

                if (party[1].buffs['divine seal']) then
                    potency = potency * 2;
                end

                local cureHpp = potency / memberMaxHP * 100;
                return cureHpp;
            else
                return 0;
            end
        end
    end

    local memberUI = GUI.FilteredContainer:new({
        layout = GUI.Container.LAYOUT.GRID,
        gridRows = 1,
        gridColumns = 3,
        fillDirection = GUI.Container.LAYOUT.HORIZONTAL,
        gridGap = 4,
        padding = { x = 0, y = 0 },
        -- draw = drawIfActive(partyIndex),
        shouldDisplay = partyMemberActive(partyIndex),
        draggable = true,
        _x = s.healing.partyFrame.x,
        _y = s.healing.partyFrame.y
    });

    memberUI:addView(statusBarFactory(partyIndex));


    local cureButtons = GUI.FilteredContainer:new({
        layout = GUI.Container.LAYOUT.GRID,
        gridRows = 1,
        gridColumns = 6,
        gridGap = 2,
        draggable = true,
        padding = { x = 0, y = 0 },
        shouldDisplay = function()
            return s.healing.cure.visible;
        end
    });

    local curesKnown = T {};
    local curagasKnown = T {};
    local raisesKnown = T {};

    if (canCastSpell('Cure')) then
        curesKnown:insert(1);
    end
    if (canCastSpell('Cure II')) then
        curesKnown:insert(2);
    end
    if (canCastSpell('Cure III')) then
        curesKnown:insert(3);
    end
    if (canCastSpell('Cure IV')) then
        curesKnown:insert(4);
    end
    if (canCastSpell('Cure V')) then
        curesKnown:insert(5);
    end
    if (canCastSpell('Cure VI')) then
        curesKnown:insert(6);
    end

    if (canCastSpell('Curaga')) then
        curagasKnown:insert(1);
    end
    if (canCastSpell('Curaga II')) then
        curagasKnown:insert(2);
    end
    if (canCastSpell('Curaga III')) then
        curagasKnown:insert(3);
    end
    if (canCastSpell('Curaga IV')) then
        curagasKnown:insert(4);
    end
    if (canCastSpell('Curaga V')) then
        curagasKnown:insert(5);
    end

    if (canCastSpell('Raise')) then
        raisesKnown:insert(1);
    end
    if (canCastSpell('Raise II')) then
        raisesKnown:insert(2);
    end
    if (canCastSpell('Raise III')) then
        raisesKnown:insert(3);
    end
    if (canCastSpell('Arise')) then
        raisesKnown:insert(4);
    end


    local maxButtons = math.max(#curesKnown, #curagasKnown, #raisesKnown);


    for _ = 1, maxButtons - #curesKnown do
        cureButtons:addView(GUI.View:new({
            shouldDisplay = shouldDisplayCures(partyIndex),
            _width = 32,
            _height = 32,
        }));
    end
    for _, v in ipairs(curesKnown) do
        cureButtons:addView(cureButtonFactory(partyIndex, v));
    end

    for _ = 1, maxButtons - #curagasKnown do
        cureButtons:addView(GUI.View:new({
            shouldDisplay = shouldDisplayCuragas(partyIndex),
            _width = 32,
            _height = 32,
        }));
    end
    for _, v in ipairs(curagasKnown) do
        cureButtons:addView(curagaButtonFactory(partyIndex, v));
    end

    for _ = 1, maxButtons - #raisesKnown do
        cureButtons:addView(GUI.View:new({
            shouldDisplay = shouldDisplayRaises(partyIndex),
            _width = 32,
            _height = 32,
        }));
    end
    for _, v in ipairs(raisesKnown) do
        cureButtons:addView(raiseButtonFactory(partyIndex, v));
    end



    memberUI:addView(cureButtons);

    local hpBar = HPBar:new({
        getHP = getHP(partyIndex),
        getHPP = getHPP(partyIndex),
        getMP = getMP(partyIndex),
        getMPP = getMPP(partyIndex),
        getTP = getTP(partyIndex),
        getName = getName(partyIndex),
        getCureHPP = getCureHPP(),
        getJobIconTex = getJobIconTex(partyIndex),
        getDistance = getDistance(partyIndex),
        onClick = targetMember(partyIndex),
        getRaiseData = getRaiseData(partyIndex),
        getIsTarget = getIsTarget(partyIndex),
        getIsSubtarget = getIsSubtarget(partyIndex),
        getIsAoeTarget = getIsAoeTarget(partyIndex),
        getEnmityIndicatorOpacity = getEnmityIndicatorOpacity(partyIndex),
        _width = 133,
        barHeight = 8,
    });

    memberUI:addView(hpBar);

    local castBar = CastBar:new({
        getSpellName = getSpellName(partyIndex),
        getTargetName = getTargetName(partyIndex),
        getFillRatio = getFillRatio(partyIndex),
    });

    memberUI:addView(castBar);

    return memberUI;
end


return partyEntryFactory;
