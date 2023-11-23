local taggedMobs = T {};

local function ParseActionPacket(e)
    local bitData;
    local bitOffset;
    local maxLength = e.size * 8;
    local function UnpackBits(length)
        if ((bitOffset + length) >= maxLength) then
            maxLength = 0; --Using this as a flag since any malformed fields mean the data is trash anyway.
            return 0;
        end
        local value = ashita.bits.unpack_be(bitData, 0, bitOffset, length);
        bitOffset = bitOffset + length;
        return value;
    end

    local actionPacket = T {};
    bitData = e.data_raw;
    bitOffset = 40;
    actionPacket.UserId = UnpackBits(32);
    -- actionPacket.UserIndex = GetIndexFromId(actionPacket.UserId); --Many implementations of this exist, or you can comment it out if not needed.  It can be costly.
    local targetCount = UnpackBits(6);
    --Unknown 4 bits
    bitOffset = bitOffset + 4;
    actionPacket.Type = UnpackBits(4);
    actionPacket.Id = UnpackBits(32);
    actionPacket.Recast = UnpackBits(32);

    actionPacket.Targets = T {};
    if (targetCount > 0) then
        for i = 1, targetCount do
            local target = T {};
            target.Id = UnpackBits(32);
            local actionCount = UnpackBits(4);
            target.Actions = T {};
            if (actionCount > 0) then
                for j = 1, actionCount do
                    local action = {};
                    action.Reaction = UnpackBits(5);
                    action.Animation = UnpackBits(12);
                    action.SpecialEffect = UnpackBits(7);
                    action.Knockback = UnpackBits(3);
                    action.Param = UnpackBits(17);
                    action.Message = UnpackBits(10);
                    action.Flags = UnpackBits(31);

                    local hasAdditionalEffect = (UnpackBits(1) == 1);
                    if hasAdditionalEffect then
                        local additionalEffect = {};
                        additionalEffect.Damage = UnpackBits(10);
                        additionalEffect.Param = UnpackBits(17);
                        additionalEffect.Message = UnpackBits(10);
                        action.AdditionalEffect = additionalEffect;
                    end

                    local hasSpikesEffect = (UnpackBits(1) == 1);
                    if hasSpikesEffect then
                        local spikesEffect = {};
                        spikesEffect.Damage = UnpackBits(10);
                        spikesEffect.Param = UnpackBits(14);
                        spikesEffect.Message = UnpackBits(10);
                        action.SpikesEffect = spikesEffect;
                    end

                    target.Actions:append(action);
                end
            end
            actionPacket.Targets:append(target);
        end
    end

    return actionPacket;
end

-- This includes npcs, but it's fine.
local function isMob(id)
    return bit.band(id, 0xFF000000) ~= 0;
end

local function onAction(e)
    local playerEntity = GetPlayerEntity();
    local playerId;
    if (playerEntity) then
        playerId = playerEntity.ServerId;
    else
        return;
    end
    local actorId = ashita.bits.unpack_be(e.data_raw, 0, 40, 32);

    -- We only care about actions done by the player
    if (actorId ~= playerId) then
        return;
    end

    local targetCount = ashita.bits.unpack_be(e.data_raw, 0, 76, 6);

    -- We only care about actions with targets
    -- if (targetCount == 0) then
    --     return;
    -- end

    local actionPacket = ParseActionPacket(e);

    for _, target in ipairs(actionPacket.Targets) do
        if (isMob(target.Id)) then
            taggedMobs[target.Id] = os.clock();
        end
    end
end

local deathMes = T { 6, 20, 97, 113, 406, 605, 646 };
local function onMessage(e)
    local message = struct.unpack('i2', e.data, 0x18 + 1);
    if (deathMes:contains(message)) then
        local target = struct.unpack('i4', e.data, 0x08 + 1);
        taggedMobs[target] = nil;
    end
end

-- Clear tagged mob table on zone
local function onZone(e)
    taggedMobs = T {};
end

-- Call this function to determine if the current target/subtarget has been tagged by you
local function isTargetTagged()
    local targetManager = AshitaCore:GetMemoryManager():GetTarget();
    local isSubTargetActive = targetManager:GetIsSubTargetActive();

    local targetId = targetManager:GetServerId(isSubTargetActive == 1 and 1 or 0);

    local tagged = taggedMobs[targetId];

    return tagged and os.clock() - tagged < 550;
end

ashita.events.register('packet_in', 'packet_in_th_cb', function(e)
    if (e.id == 0x28) then
        onAction(e);
    elseif (e.id == 0x29) then
        onMessage(e);
    elseif (e.id == 0x0A or e.id == 0x0B) then
        onZone(e);
    end
end);

return isTargetTagged;
