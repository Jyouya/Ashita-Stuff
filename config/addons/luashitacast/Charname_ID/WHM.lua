local settings = {
    fastcast = 0,
    minimumBuffer = 0.1,
    packetDelay = 0.25,
};
local profile, sets = gFunc.LoadFile('common/J-Cast.lua')(settings);


sets.Idle = {
    Sub = 'Frost Shield',
    Body = 'Seer\'s Tunic',
    Feet = 'Wonder Clomps',
    Ear1 = 'Morion Earring',
    Ear2 = 'Morion Earring',
};

sets.Engaged = table.copy(sets.Idle);


sets.Resting = {
    Main = 'Pilgrim\'s Wand',
    Body = 'Seer\'s Tunic',
    Legs = 'Baron\'s Slops',
};
sets.Midcast = {
};
sets.Midcast_Cure = gFunc.Combine(sets.Midcast, {
    Main = 'Solid Wand',
    Neck = 'Justice Badge',
    Head = 'Traveler\'s Hat',
    Body = 'Baron\'s Saio',
    Hands = 'Mycophile Cuffs',
    Legs = 'Wonder Braccae',
    Feet = 'Seer\'s Pumps +1',
    Waist = 'Friar\'s Rope',
    Ring1 = 'Saintly Ring',
    Ring2 = 'Saintly Ring',
    Back = 'White Cape +1',
});

sets.Midcast_EnfeeblingMagic = {
    Ammo = 'Sweet Sachet',
    Main = 'Solid Wand',
    Head = { 'Seer\'s Crown +1', 'Baron\'s Chappeau' },
    Body = 'Baron\'s Saio',
    Hands = 'Mycophile Cuffs',
    Legs = 'Mage\'s Slops',
    Neck = 'Black Neckerchief',
    Waist = 'Shaman\'s Belt',
    Ear1 = 'Morion Earring',
    Ear2 = 'Morion Earring',
    Ring1 = 'Eremite\'s Ring',
    Ring2 = 'Eremite\'s Ring',
    Back = 'Black Cape +1',
};

sets.Midcast_ElementalMagic = {
    Ammo = 'Sweet Sachet',
    Main = 'Solid Wand',
    Head = { 'Seer\'s Crown +1', 'Baron\'s Chappeau' },
    Body = 'Baron\'s Saio',
    Hands = 'Mycophile Cuffs',
    Legs = 'Mage\'s Slops',
    Neck = 'Black Neckerchief',
    Waist = 'Shaman\'s Belt',
    Ear1 = 'Morion Earring',
    Ear2 = 'Morion Earring',
    Ring1 = 'Eremite\'s Ring',
    Ring2 = 'Eremite\'s Ring',
    Back = 'Black Cape +1',
};

sets.Midcast_MndEnfeeble = {
    Main = 'Solid Wand',
    Neck = 'Justice Badge',
    Head = 'Traveler\'s Hat',
    Body = 'Baron\'s Saio',
    Hands = 'Devotee\'s Mitts',
    Legs = 'Wonder Braccae',
    Feet = 'Seer\'s Pumps +1',
    Waist = 'Friar\'s Rope',
    Ring1 = 'Saintly Ring',
    Ring2 = 'Saintly Ring',
    Back = 'White Cape +1',
};

sets.Midcast_MndEnfeebleScaling = {
    Main = 'Solid Wand',
    Neck = 'Justice Badge',
    Head = 'Traveler\'s Hat',
    Body = 'Baron\'s Saio',
    Hands = 'Devotee\'s Mitts',
    Legs = 'Wonder Braccae',
    Feet = 'Seer\'s Pumps +1',
    Waist = 'Friar\'s Rope',
    Ring1 = 'Saintly Ring',
    Ring2 = 'Saintly Ring',
    Back = 'White Cape +1',
};


sets.Weaponskill = {
    Body = 'Wonder Kaftan',
    Hands = 'Wonder Mitts',
    Legs = 'Wonder Braccae',
    Feet = 'Wonder Clomps',
    Neck = 'Spike Necklace',
    Waist = 'Brave Belt',
    Ear1 = 'Beetle Earring +1',
    Ear2 = 'Beetle Earring +1',
    Ring1 = 'Courage Ring',
    Ring2 = 'Courage Ring',
    Back = 'White Cape +1',
};

sets.SIRD = gFunc.Combine(sets.Idle, {
    Waist = 'Heko obi +1',
});

-- Tank set with club skill
sets.Weaponskill_Starlight = gFunc.Combine(sets.Idle, {});
sets['Weaponskill_Shining Strike'] = gFunc.Combine(sets.Weaponskill, {
    Neck = 'Justice Badge'
});

-- Atk bonus, acc penalty, 100% STR
sets.Weaponskill_TrueStrike = gFunc.Combine(sets.Weaponskill, {
    Head = 'Empress Hairpin',
});



profile.Sets = sets;

profile.Packer = {
};


return profile;
