local abilities = T {
    'Blood Weapon',
    'Arcane Circle',
    'Last Resort',
    'Weapon Bash',
    'Souleater',
    'Consume Mana',
    'Dark Seal',
    'Diabolic Eye',
    'Nether Void',
    'Arcane Crest',
    'Scarlet Delirium',
    'Soul Enslavement',
};

local status = T {
    ['Blood Weapon'] = 51,
    ['Arcane Circle'] = 75,
    ['Last Resort'] = 64,
    ['Souleater'] = 63,
    ['Consume Mana'] = 599,
    ['Dark Seal'] = 345,
    ['Diabolic Eye'] = 346,
    ['Nether Void'] = 439,
    ['Arcane Crest'] = 464,
    ['Scarlet Delirium'] = 479,
    ['Soul Enslavement'] = 497,
    ['Weapon Bash'] = 10
};

local target = T {
    ['Weapon Bash'] = '<t>',
    ['Arcane Crest'] = '<t>',
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
