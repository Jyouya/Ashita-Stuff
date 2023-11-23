local abilities = T {
    'Benediction',
    'Divine Seal',
    'Afflatus Solace',
    'Afflatus Misery',
    'Martyr',
    'Devotion',
    'Divine Caress',
    'Sacrosanctity',
    'Asylum',
};

local status = T {
    ['Divine Seal'] = 78,
    ['Afflatus Solace'] = 417,
    ['Afflatus Misery'] = 418,
    ['Divine Caress'] = 453,
    ['Sacrosanctity'] = 477,
    ['Asylum'] = 492,
};

local target = T {
    ['Martyr'] = '<t>',
    ['Devotion'] = '<t>'
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
