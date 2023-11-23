local spells = T {};
do
    local spellNames = T {
        ['Katon: Ichi'] = 5,
        ['Katon: Ni'] = 5,
        ['Katon: San'] = 5,
        ['Flare'] = 5,
        ['Flare II'] = 5,

        ['Suiton: Ichi'] = 4,
        ['Suiton: Ni'] = 4,
        ['Suiton: San'] = 4,
        ['Flood'] = 4,
        ['Flood II'] = 4,

        ['Raiton: Ichi'] = 3,
        ['Raiton: Ni'] = 3,
        ['Raiton: San'] = 3,
        ['Burst'] = 3,
        ['Burst II'] = 3,

        ['Doton: Ichi'] = 2,
        ['Doton: Ni'] = 2,
        ['Doton: San'] = 2,
        ['Quake'] = 2,
        ['Quake II'] = 2,

        ['Huton: Ichi'] = 1,
        ['Huton: Ni'] = 1,
        ['Huton: San'] = 1,
        ['Tornado'] = 1,
        ['Tornado II'] = 1,

        ['Hyoton: Ichi'] = 0,
        ['Hyoton: Ni'] = 0,
        ['Hyoton: San'] = 0,
        ['Freeze'] = 0,
        ['Freeze II'] = 0
    };

    for k, v in pairs(spellNames) do
        local spellData = AshitaCore:GetResourceManager():GetSpellByName(k, 2);
        spells[spellData.Index] = v;
    end
end

local targets = T {};

local function handleActionPacket(actionPacket)
    if (actionPacket.Type == 4) then
        for _, target in ipairs(actionPacket.Targets) do
            for _, action in ipairs(target.Actions) do
                if (spells[actionPacket.Param]) then
                    targets[target.Id] = {
                        element = spells[actionPacket.Param],
                        time = os.clock(),
                    };
                end
            end
        end
    end
end

local function getNextElement(targetId)
    local target = targets[targetId];
    if (target) then
        -- Remove entry if debuff has expired
        if (os.clock() - target.time > 10) then
            targets[targetId] = nil;
            return;
        end
        return target.element
    end
end

return T {
    HandleActionPacket = handleActionPacket,
    getNextElement = getNextElement
};
