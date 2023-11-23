local settings = require('settings');

local debuffHandler = require('tracker').debuffHandler;
local castHandler = require('tracker').castHandler;

local Targetbar = require('targetbar.Targetbar');
local dispel = require('targetbar.dispel');
local CastBar = require('healing.cure.CastBar');

local getIndexFromId = require('functions.getIndexFromId');

local bufftable = require('hxui.bufftable');

local GUI = require('J-GUI');

local function getHPP()
    local targetIndex = AshitaCore:GetMemoryManager():GetTarget():GetTargetIndex(0);

    if (targetIndex) then
        return AshitaCore:GetMemoryManager():GetEntity():GetHPPercent(targetIndex) / 100;
    else
        return 0;
    end
end

local function getName()
    local targetIndex = AshitaCore:GetMemoryManager():GetTarget():GetTargetIndex(0);

    if (targetIndex) then
        return AshitaCore:GetMemoryManager():GetEntity():GetName(targetIndex);
    else
        return 0;
    end
end

local colors = {
    player = 0xFFFFFFFF,
    party = 0xFF00FFFF,
    npc = 0xFF66FF66,
    unclaimed = 0xFFFFFF66,
    partyClaimed = 0xFFFF6666,
    otherClaimed = 0xFFFF66FF
}
local function getClaimColor()
    local targetIndex = AshitaCore:GetMemoryManager():GetTarget():GetTargetIndex(0);

    if (targetIndex) then
        local spawnFlags = AshitaCore:GetMemoryManager():GetEntity():GetSpawnFlags(targetIndex);
        if (bit.band(spawnFlags, 1) == 1) then
            local party = AshitaCore:GetMemoryManager():GetParty();
            for i = 0, 17 do
                if (party:GetMemberIsActive(i) == 1) then
                    if (party:GetMemberTargetIndex(i) == targetIndex) then
                        return colors.party;
                    end
                end
            end
            return colors.player;
        elseif (bit.band(spawnFlags, 2) == 2) then
            return colors.npc;
        else
            local entMgr = AshitaCore:GetMemoryManager():GetEntity();
            local claimStatus = entMgr:GetClaimStatus(targetIndex);
            local claimId = bit.band(claimStatus, 0xFFFF);

            if (claimId == 0) then
                return colors.unclaimed;
            else
                local party = AshitaCore:GetMemoryManager():GetParty();
                for i = 0, 17 do
                    if (party:GetMemberIsActive(i) == 1) then
                        if (party:GetMemberServerId(i) == claimId) then
                            return colors.partyClaimed;
                        end
                    end
                end
                return colors.otherClaimed;
            end
        end
    else
        return colors.player;
    end
end

local function getDistance()
    local targetIndex = AshitaCore:GetMemoryManager():GetTarget():GetTargetIndex(0);

    if (targetIndex) then
        return math.sqrt(AshitaCore:GetMemoryManager():GetEntity():GetDistance(targetIndex));
    else
        return 0;
    end
end

local function getBuffIds()
    local targetIndex = AshitaCore:GetMemoryManager():GetTarget():GetTargetIndex(0);

    if (targetIndex) then
        local serverId = AshitaCore:GetMemoryManager():GetEntity():GetServerId(targetIndex);
        local debuffs = debuffHandler.GetActiveDebuffs(serverId);

        if (not debuffs) then
            return {};
        end

        local res = T {};
        for k, _ in pairs(debuffs) do
            res:insert(k);
        end
        return res;
    else
        return {};
    end
end

local function getIsBuffed()
    local targetIndex = AshitaCore:GetMemoryManager():GetTarget():GetTargetIndex(0);

    if (targetIndex) then
        local serverId = AshitaCore:GetMemoryManager():GetEntity():GetServerId(targetIndex);
        local debuffs = debuffHandler.GetActiveDebuffs(serverId);

        if (not debuffs) then
            return false;
        end


        for k, _ in pairs(debuffs) do
            if (bufftable.IsBuff(k)) then
                return true
            end
        end
    end
end

local function getSpellName()
    local targetIndex = AshitaCore:GetMemoryManager():GetTarget():GetTargetIndex(0);

    if (targetIndex) then
        local serverId = AshitaCore:GetMemoryManager():GetEntity():GetServerId(targetIndex);

        local cast = castHandler.getCastByCaster(serverId);
        if (cast) then
            return cast.spellName;
        end
    end

    return '';
end

local function getTargetName()
    local targetIndex = AshitaCore:GetMemoryManager():GetTarget():GetTargetIndex(0);

    if (targetIndex) then
        local serverId = AshitaCore:GetMemoryManager():GetEntity():GetServerId(targetIndex);

        local cast = castHandler.getCastByCaster(serverId);
        if (cast) then
            local targetOfTargetIndex = getIndexFromId(cast.targetId);

            return AshitaCore:GetMemoryManager():GetEntity():GetName(targetOfTargetIndex);
        end
    end

    return '';
end

local function getFillRatio()
    local targetIndex = AshitaCore:GetMemoryManager():GetTarget():GetTargetIndex(0);

    if (targetIndex) then
        local serverId = AshitaCore:GetMemoryManager():GetEntity():GetServerId(targetIndex);
        local cast = castHandler.getCastByCaster(serverId);

        if (cast) then
            if (cast.castTime > 0) then
                return (os.clock() - cast.startTime) / cast.castTime;
            else
                return 1;
            end
        end
    end
    return 0;
end


local function setup(s)
    s.targetbar = s.targetbar or T { x = 800, y = 200, visible = true };
    local targetbarUI = GUI.FilteredContainer:new({
        layout = GUI.Container.LAYOUT.GRID,
        gridRows = 1,
        gridColumns = 3,
        fillDirection = GUI.Container.LAYOUT.HORIZONTAL,
        gridGap = 4,
        padding = { x = 0, y = 0 },
        draggable = true,
        onDragFinish = function(view)
            local pos = view:getPos();
            s.targetbar.x = pos.x;
            s.targetbar.y = pos.y;
            settings.save();
        end,
        getHidden = function()
            local targetIndex = AshitaCore:GetMemoryManager():GetTarget():GetTargetIndex(0);
            return targetIndex == 0 or not s.targetbar.visible;
        end,
        _x = s.targetbar.x,
        _y = s.targetbar.y
    });

    local dispelButton = dispel('Dispel');
    dispelButton.getIsBuffed = getIsBuffed;
    targetbarUI:addView(dispelButton);

    local finaleButton = dispel('Magic Finale');
    finaleButton.getIsBuffed = getIsBuffed;
    targetbarUI:addView(finaleButton);

    targetbarUI:addView(Targetbar:new({
        getHPP = getHPP,
        getName = getName,
        getClaimColor = getClaimColor,
        getDistance = getDistance,
        getBuffIds = getBuffIds,
        _width = 200,
        _barHeight = 10,
        draggable = true
    }));

    targetbarUI:addView(CastBar:new({
        getSpellName = getSpellName,
        getTargetName = getTargetName,
        getFillRatio = getFillRatio,
    }));

    GUI.ctx.addView(targetbarUI);
end

return { setup = setup };
