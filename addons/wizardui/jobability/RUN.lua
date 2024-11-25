local runes = T {
    'Ignis',
    'Tellus',
    'Unda',
    'Flabra',
    'Gelus',
    'Sulpor',
    'Lux',
    'Tenebrae',
    'Vivacious Pulse',
}

local wards = T {
    'Vallation',
    'Pflug',
    'Valiance',
    'Battuta',
    'Liement',
    'One for All',
    'Swordplay',
    'Embolden',
    'Elemental Sforzo'
}

local effusions = T {
    'Swipe',
    'Lunge',
    'Rayke',
    'Gambit',
    'Odyllic Subterfuge'
}

local status = T {
    ['Ignis'] = 523,
    ['Gelus'] = 524,
    ['Flabra'] = 525,
    ['Tellus'] = 526,
    ['Sulpor'] = 527,
    ['Unda'] = 528,
    ['Lux'] = 529,
    ['Tenebrae'] = 530,
    ['Vallation'] = 531,
    ['Valiance'] = 535,
    ['Gambit'] = 536,
    ['Rayke'] = 571,
    ['Swordplay'] = 532,
    ['One for All'] = 538,
    ['Embolden'] = 534,
}

local runeTable = T {};

for i, v in ipairs(runes) do
    local ability = AshitaCore:GetResourceManager():GetAbilityByName(v, 0);
    local res = T {};
    res.resource = ability;
    res.tex = status[v];
    res.target = '<me>';

    runeTable[i] = res;
end

local wardTable = T {};

for i, v in ipairs(wards) do
    local ability = AshitaCore:GetResourceManager():GetAbilityByName(v, 0);
    local res = T {};
    res.resource = ability;
    res.tex = status[v];
    res.target = '<me>';

    wardTable[i] = res;
end

local effusionTable = T {};

for i, v in ipairs(effusions) do
    local ability = AshitaCore:GetResourceManager():GetAbilityByName(v, 0);
    local res = T {};
    res.resource = ability;
    res.tex = status[v];
    res.target = '<t>';

    effusionTable[i] = res;
end

return T {
    runeTable,
    wardTable,
    effusionTable,
    hasSubcategories = true
};

