local event = require('event');

local zoneChange = require('events.zoneChange');

local buffGain = event:new();
local buffLoss = event:new();

-- TODO: Initialize from memory
local buffs = T {};

local ignoreNext = false;
zoneChange:register(function()
    ignoreNext = true;
end);

ashita.events.register('packet_in', 'buffChange_packet_in', function(e)
    if (e.id ~= 0x063) then return; end

    -- Check the subtype
    local type = ashita.bits.unpack_be(e.data_raw, 32, 8);
    if (type ~= 0x09) then return; end

    -- Ignore first packet after zone
    if (ignoreNext) then
        ignoreNext = false;
        return;
    end

    local packetBuffs = T {};
    for i = 1, 32 do
        local buff = struct.unpack('<H', e.data, 0x07 + 2 * i)
        packetBuffs:insert(buff);
    end

    local newBuffs = T {};

    for _, buffId in ipairs(packetBuffs) do
        if (buffId ~= 0 and buffId ~= 255) then
            newBuffs[buffId] = (newBuffs[buffId] or 0) + 1;
        end
    end

    for buffId, count in pairs(newBuffs) do
        if (not buffs[buffId] or buffs[buffId < count]) then
            for i = 1, count - (buffs[buffId] or 0) do
                buffGain:trigger(buffId);
            end
        end
    end

    for buffId, count in pairs(buffs) do
        if (not newBuffs[buffId] or newBuffs[buffId] < count) then
            for i = 1, count - (newBuffs[buffId] or 0) do
                -- Trigger once per buff instance, not per ID
                buffLoss:trigger(buffId);
            end
        end
        buffs[buffId] = nil;
    end

    for buffId, count in pairs(newBuffs) do
        buffs[buffId] = count;
    end
end);

return { buffs = buffs, buffGain = buffGain, buffLoss = buffLoss };
