addon.name    = 'stepdown';
addon.author  = 'Jyouya';
addon.version = '1.0';
addon.desc    = 'Spell Stepdown command for macros';


require('common');
local spellName;
do
    local gaSpellName;
    do
        local suffix = T { '', ' II', ' III', ' IV', };
        gaSpellName = function(baseSpell, level)
            if (level > 5) then level = 5; end
            if (level == 5) then
                return baseSpell:sub(1, #baseSpell - 2) .. 'ja';
            else
                return baseSpell .. suffix[level];
            end
        end
    end

    local ninSpellName;
    do
        local suffix = T { ': Ichi', ': Ni', ': San' };
        ninSpellName = function(baseSpell, level)
            if (level > 3) then level = 3; end
            return baseSpell .. suffix[level];
        end
    end

    local function isNinjutsu(baseSpell)
        local resource = AshitaCore:GetResourceManager();

        return resource:GetSpellByName(ninSpellName(baseSpell, 1), 2);
    end

    local suffix = T { '', ' II', ' III', ' IV', ' V', ' VI' };
    spellName = function(baseSpell, level)
        if (baseSpell:sub(-2) == 'ga') then
            return gaSpellName(baseSpell, level);
        elseif (isNinjutsu(baseSpell)) then
            return ninSpellName(baseSpell, level);
        end
        if (level > 6) then level = 6; end
        return baseSpell .. suffix[level];
    end
end

local function stepdown(baseSpell, maxLevel, targetString)
    if (type(baseSpell) ~= 'string') then return end
    if (type(maxLevel) ~= 'number') then return end

    baseSpell = baseSpell:lower()

    local recast = AshitaCore:GetMemoryManager():GetRecast();
    local resource = AshitaCore:GetResourceManager();
    local playerMp = AshitaCore:GetMemoryManager():GetParty():GetMemberMP(0);

    -- Iterate over spells
    for i = maxLevel, 1, -1 do
        local name = spellName(baseSpell, i);
        local spell = resource:GetSpellByName(name, 2);

        local spellRecast = recast:GetSpellTimer(spell.Index);
        local mpCost = spell.ManaCost;

        if (spellRecast == 0 and playerMp >= mpCost) then
            print(('casting %s'):format(name));
            AshitaCore:GetChatManager():QueueCommand(-1, ('/ma "%s" %s'):format(name, targetString or '<t>'));
            return
        end
    end
end

ashita.events.register('command', 'command_cb', function(e)
    local commandArgs = e.command:lower():args();
    print(commandArgs[3]);
    if (commandArgs[1] == '/stepdown') then
        stepdown(commandArgs[2], tonumber(commandArgs[3]), commandArgs[4])
    end
end)
