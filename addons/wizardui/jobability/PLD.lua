local abilities = T {
    'Invincible',
    'Holy Circle',
    'Shield Bash',
    'Sentinel',
    'Cover',
    'Rampart',
    'Majesty',
    'Fealty',
    'Chivalry',
    'Divine Emblem',
    'Sepulcher',
    'Palisade',
    'Intervene',
};

local status = T {
    ['Invincible'] = 50,
    ['Holy Circle'] = 74,
    ['Sentinel'] = 62,
    ['Cover'] = 114,
    -- ['Rampart'] = 93,
    ['Majesty'] = 621,
    ['Fealty'] = 344,
    ['Divine Emblem'] = 438,
    ['Sepulcher'] = 463,
    ['Palisade'] = 478,
    ['Intervene'] = 496
};

local target = T {
    ['Cover'] = '<stpc>',
    ['Intervene'] = '<t>',
    ['Sepulcher'] = '<t>'
};

local abilityTable = T {};

for i, v in ipairs(abilities) do
    local ability = AshitaCore:GetResourceManager():GetAbilityByName(v, 0);
    local res = T {};
    res.resource = ability;
    res.tex = status[v];
    res.target = target[v] or '<me>';

    abilityTable[i] = res;
end

return abilityTable;
