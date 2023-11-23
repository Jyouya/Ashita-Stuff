local abilities = T {
    'Manafont',
    'Elemental Seal',
    'Mana Wall',
    'Cascade',
    'Enmity Douse',
    'Manawell',
    'Subtle Sorcery'
};

local status = T {
    ['Manafont'] = 47,
    ['Elemental Seal'] = 79,
    ['Mana Wall'] = 437,
    ['Cascade'] = 598,
    ['Manawell'] = 229,
    ['Subtle Sorcery'] = 493
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
