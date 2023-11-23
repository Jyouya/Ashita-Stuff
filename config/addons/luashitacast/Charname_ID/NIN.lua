local settings = {
    fastcast = 0,
    minimumBuffer = 0.1,
    packetDelay = 0.25,
};
local profile, sets = gFunc.LoadFile('common/J-Cast.lua')(settings);

sets.Idle = {
    Head = 'Empress Hairpin',
    Body = 'Federation Gi',
    Hands = 'Federation Tekko',
    Legs = 'Republic Subligar',
    Feet = 'Fed. Kyahan',
    Neck = 'Spike Necklace',
    Waist = 'Warrior\'s Belt +1',
    Ear1 = 'Silver Earring +1',
    Ear2 = 'Silver Earring +1',
    Ring1 = 'Balance Ring',
    Ring2 = 'Balance Ring',
    Back = 'Nomad\'s Mantle +1',
};

-- Get nomad cape, dodge earrings
sets.Engaged = {
    Head = 'Empress Hairpin',
    Body = 'Federation Gi',
    Hands = 'Federation Tekko',
    Legs = 'Republic Subligar',
    Feet = 'Fed. Kyahan',
    Neck = 'Spike Necklace',
    Waist = 'Warrior\'s Belt +1',
    Ear1 = 'Silver Earring +1',
    Ear2 = 'Silver Earring +1',
    Ring1 = 'Balance Ring',
    Ring2 = 'Balance Ring',
    Back = 'Nomad\'s Mantle +1',
};

sets.Preshot = {
    Ammo = 'Juji Shuriken'
};

sets.Midshot = {
    Head = 'Empress Hairpin',
    Body = 'Federation Gi',
    Hands = 'Federation Tekko',
    Legs = 'Republic Subligar',
    Feet = 'Fed. Kyahan',
    Neck = 'Spike Necklace',
    Waist = 'Warrior\'s Belt +1',
    Ear1 = 'Silver Earring +1',
    Ear2 = 'Silver Earring +1',
    Ring1 = 'Beetle Ring +1',
    Ring2 = 'Beetle Ring +1',
}


sets.Resting = {};
sets.Midcast = {
};
sets.Midcast_ElementalNinjutsu = {
    Head = 'Erd. Headband',
    Ring1 = 'Eremite\'s Ring',
    Ring2 = 'Eremite\'s Ring',
    Ear1 = 'Morion Earring',
    Ear2 = 'Morion Earring',
    Ammo = 'Sweet Sachet',
    CastTime = 2000,
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
};

sets.Weaponskill_Marksmanship = {
    Head = 'Empress Hairpin',
    Body = 'Beetle Harness +1',
    Hands = 'Beetle Mittens +1',
    Legs = 'Beetle Subligar +1',
    Feet = 'Beetle Leggings +1',
    Neck = 'Spike Necklace',
    Waist = 'Warrior\'s Belt +1',
    Ear1 = 'Silver Earring +1',
    Ear2 = 'Silver Earring +1',
    Ring1 = 'Beetle Ring +1',
    Ring2 = 'Beetle Ring +1',
};

sets.Weaponskill_Throwing = {
    Head = 'Empress Hairpin',
    Body = 'Beetle Harness +1',
    Hands = 'Beetle Mittens +1',
    Legs = 'Beetle Subligar +1',
    Feet = 'Beetle Leggings +1',
    Neck = 'Spike Necklace',
    Waist = 'Warrior\'s Belt +1',
    Ear1 = 'Silver Earring +1',
    Ear2 = 'Silver Earring +1',
    Ring1 = 'Beetle Ring +1',
    Ring2 = 'Beetle Ring +1',
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
