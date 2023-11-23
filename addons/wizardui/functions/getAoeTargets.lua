local party = require('tracker').party;

-- TODO: confirm these values
local ranges = {
    [0] = 1,
    [2] = 3.4,
    [3] = 4.47273,
    [4] = 5.76,
    [5] = 6.88889,
    [6] = 7.8,
    [7] = 8.4,
    [8] = 10.0,
    [9] = 12.4,
    [10] = 14.5,
    [11] = 16.4,
    [12] = 20.4,
    [13] = 24.9
}

local function getAoeTargets(spell, targetIndex)
    local partyIndex = -1;
    for i = 1, 18 do
        if (party[i].targetIndex == targetIndex) then
            partyIndex = i;
            break;
        end
    end

    local range2 = ranges[spell.AreaRange] ^ 2;

    -- Target is in party.
    local entity = AshitaCore:GetMemoryManager():GetEntity()
    if (partyIndex > 0 and partyIndex < 7) then
        local anchorX = entity:GetLocalPositionX(targetIndex);
        local anchorY = entity:GetLocalPositionY(targetIndex);
        local anchorZ = entity:GetLocalPositionZ(targetIndex);


        local targets = T { partyIndex };
        for i = 1, 6 do
            if (i ~= partyIndex) then
                local memberIndex = party[i].targetIndex;
                local memberX = entity:GetLocalPositionX(memberIndex);
                local memberY = entity:GetLocalPositionY(memberIndex);
                local memberZ = entity:GetLocalPositionZ(memberIndex);

                local dist2 = (anchorX - memberX) ^ 2 + (anchorY - memberY) ^ 2 - (anchorZ - memberZ) ^ 2;

                if (dist2 < range2) then
                    targets:insert(i);
                end
            end
        end

        return targets;
    end

    return T {};

    -- TODO: Add alliance support with sch stuff
end

return getAoeTargets;
