local event = require('event');
local getAbilityRecasts = require('functions.getAbilityRecasts');

local casts = T {};
local targets = T {};

local spellRecasts = T {};
local abilityRecasts = T {};
local castId = 0;

local recastDelay = T {};
local abilityRecastDelay = T {};

local spellCompletion = event:new();

local spellInterruptMes = T { 16, 106, 29, 84 };

local lastAttacked = T {};

local function handleActionPacket(actionPacket)
    if (#actionPacket.Targets > 0 and bit.band(actionPacket.UserId, 0xFF000000) ~= 0) then
        lastAttacked[actionPacket.Targets[1].Id] = os.clock();
    end
    local actorId = actionPacket.UserId;
    for _, target in ipairs(actionPacket.Targets) do
        for _, action in ipairs(target.Actions) do
            -- actor starts casting spell on target
            if (actionPacket.Type == 8 and actionPacket.Param == 24931) then -- Starts casting spell
                if (not target.Id) then return; end
                local spellData = AshitaCore:GetResourceManager():GetSpellById(action.Param);
                if (not spellData) then return; end
                castId = castId + 1;
                local castTime = spellData.CastTime * 0.25;
                local startTime = os.clock();

                casts[actorId] = T {
                    actorId = actorId,
                    actorIndex = actionPacket.UserIndex,
                    targetId = target.Id,
                    spellGroup = actionPacket.SpellGroup,
                    spellId = action.Param,
                    spellName = spellData.Name[3],
                    startTime = startTime,
                    castId = castId,
                    castTime = castTime,
                    expiry = startTime + castTime + 1,
                };

                -- print(action.Param, os.clock());

                targets[target.Id] = targets[target.Id] or T {};
                targets[target.Id][castId] = casts[actorId];
            else
                if (actionPacket.Type == 4) then
                    spellRecasts[target.Id] = spellRecasts[target.Id] or T {};
                    spellRecasts[target.Id][actionPacket.Param] = os.clock() + actionPacket.Recast;

                    -- print(actionPacket.Param, os.clock())

                    -- print(actionPacket.UserId, GetPlayerEntity().ServerId);
                    local player = GetPlayerEntity();

                    if (player and actionPacket.UserId == player.ServerId) then
                        recastDelay[actionPacket.Param] = actionPacket.Recast * 60;
                    end

                    local castData = casts[actionPacket.UserId];
                    if (castData) then
                        spellCompletion:trigger(castData);
                        targets[target.Id] = targets[target.Id] or T {}
                        targets[target.Id][castData.castId] = nil
                    end
                elseif (actionPacket.Type == 6) then
                    abilityRecasts[actorId] = abilityRecasts[actorId] or T {};
                    abilityRecasts[actorId][action.Param] = os.clock() + actionPacket.Recast;
                    local player = GetPlayerEntity();

                    if (player and actionPacket.UserId == player.ServerId) then
                        recastDelay[action.Param] = actionPacket.Recast * 60;
                    end
                end
                casts[actionPacket.UserId] = nil;
            end
        end
    end
end

local function handleMessagePacket(messagePacket)
    if (spellInterruptMes:contains(messagePacket.message)) then
        local actorId = messagePacket.sender;
        local targetId = messagePacket.target;
        local cast = casts[actorId];
        if (cast) then
            casts[actorId] = nil;
            targets[targetId][cast.castId] = nil;
        end
    end
end

-- Returns castData
local function getCastByCaster(casterId)
    local castData = casts[casterId];
    if (not castData) then return; end
    if (os.clock() > castData.expiry) then
        casts[casterId] = nil;
        targets[castData.targetId][castData.castId] = nil;
    end
    return casts[casterId];
end

-- Returns unordered table of castData
local function getCastsByTarget(targetId)
    if (not targets[targetId]) then
        return nil;
    end
    for k, castData in pairs(targets[targetId]) do
        if (os.clock() > castData.expiry) then
            casts[castData.actorId] = nil;
            targets[targetId][k] = nil;
        end
    end

    local res = T {};
    for k, v in pairs(targets[targetId]) do
        res:insert(v);
    end
    return res;
end

local function getLastAttacked(serverId)
    return lastAttacked[serverId] or 0;
end


local observedRecast = setmetatable({}, { __index = function() return 0; end });
local function getRecastForSpell(spellId)
    if (recastDelay[spellId]) then
        return recastDelay[spellId];
    else
        local spell = AshitaCore:GetResourceManager():GetSpellById(spellId);
        local recast = AshitaCore:GetMemoryManager():GetRecast():GetSpellTimer(spell.Index);

        -- print(recast);
        if (recast > observedRecast[spellId]) then
            observedRecast[spellId] = recast;
            return recast
        else
            return observedRecast[spellId];
        end
    end
end

local abilityObservedRecast = setmetatable({}, { __index = function() return 0; end });
local function getRecastForAbility(abilityId)
    if (abilityRecastDelay[abilityId]) then
        return abilityRecastDelay[abilityId];
    else
        local ability = AshitaCore:GetResourceManager():GetAbilityById(abilityId);
        -- Slightly less efficient than doing it here and exiting early, but we only call this at most once per cast
        local recast = getAbilityRecasts()[ability.RecastTimerId];
        -- for k, v in pairs(getAbilityRecasts()) do
        --     print(k,v)
        -- end

        if (recast and recast > abilityObservedRecast[abilityId]) then
            abilityObservedRecast[abilityId] = recast;
            return recast;
        else
            return abilityObservedRecast[abilityId];
        end
    end
end

return T {
    HandleActionPacket = handleActionPacket,
    HandleMessagePacket = handleMessagePacket,
    getCastByCaster = getCastByCaster,
    getCastsByTarget = getCastsByTarget,
    getLastAttacked = getLastAttacked,
    getRecastForSpell = getRecastForSpell,
    getRecastForAbility = getRecastForAbility,
    spellCompletion = spellCompletion
};
