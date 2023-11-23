local abilities = T {
    'Chainspell',
    'Convert',
    'Composure',
    'Saboteur',
    'Spontaneity',
    'Stymie',
};

local status = T {
    Chainspell = 48,
    Composure = 419,
    Saboteur = 454,
    Spontaneity = 230,
    Stymie = 494,
};

local abilityTable = T {};

for i, v in ipairs(abilities) do
    local ability = AshitaCore:GetResourceManager():GetAbilityByName(v, 0);
    local res = T {};
    res.resource = ability;
    res.tex = status[v];
    res.target = '<me>';

    abilityTable[i] = res;
end

return abilityTable;
