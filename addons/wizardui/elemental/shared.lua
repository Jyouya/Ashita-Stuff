local functions = require('J-GUI/functions');


local ELEMENTAL_COLOR = T {
    FIRE = T { 92.9, 11.0, 14.1 },
    EARTH = T { 100.0, 69.8, 15.3 },
    WATER = T { 0.0, 63.5, 91.0 },
    WIND = T { 13.3, 69.4, 29.8 },
    ICE = T { 60.0, 85.1, 91.8 },
    LIGHTNING = T { 63.9, 28.6, 64.3 },
    LIGHT = T { 100.0, 100.0, 100.0 },
    DARK = T { 40.0, 40.0, 40.0 }
}:map(function(color)
    return color:map(function(value)
        return 2.55 * value;
    end)
end);

local ELEMENTAL_SPELL = T {
    FIRE = 'Fire',
    EARTH = 'Stone',
    WATER = 'Water',
    WIND = 'Aero',
    ICE = 'Blizzard',
    LIGHTNING = 'Thunder'
};

local getTexForElement;
do
    local textures = T {};
    getTexForElement = function(element)
        return function()
            if (not textures[element]) then
                textures[element] = functions.loadAssetTexture(
                    string.format(
                        '%s/assets/weather/el%s_c.png',
                        addon.path,
                        string.lower(element)));
            end
            return textures[element];
        end
    end
end

local function hasSpell(spell)
    local player = AshitaCore:GetMemoryManager():GetPlayer();
    if (not player:HasSpell(spell.Index)) then
        return false;
    end

    local spellLevel = spell.LevelRequired[player:GetMainJob() + 1];
    local jobLevel;

    if (spellLevel == -1) then
        spellLevel = spell.LevelRequired[player:GetSubJob() + 1];
        if (spellLevel == -1) then
            return false;
        end
        jobLevel = player:GetSubJobLevel();
    else
        jobLevel = player:GetMainJobLevel();
    end


    return jobLevel >= spellLevel;
end

local ROMAN_NUMERALS = T {
    [1] = 'I',
    [2] = 'II',
    [3] = 'III',
    [4] = 'IV',
    [5] = 'V',
    [6] = 'VI',
    [7] = 'VII',
    [8] = 'VIII',
    [9] = 'IX',
    [10] = 'X'
}

return {
    ELEMENTAL_COLOR = ELEMENTAL_COLOR,
    ELEMENTAL_SPELL = ELEMENTAL_SPELL,
    ROMAN_NUMERALS = ROMAN_NUMERALS,
    getTexForElement = getTexForElement,
    hasSpell = hasSpell,
}
