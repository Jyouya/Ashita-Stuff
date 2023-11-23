local settings = {
    fastcast = 0,
    minimumBuffer = 0.1,
    packetDelay = 0.25,
};
local profile, sets = gFunc.LoadFile('common/J-Cast.lua')(settings);

sets.Idle = {
    Body = 'Eisenbrust',
    Legs = 'Eisendiechlings',
    Feet = 'Eisenschuhs',
};

sets.Engaged = {
    Head = 'Empress Hairpin',
    Body = 'Wonder Kaftan',
    Hands = 'Wonder Mitts',
    Legs = 'Wonder Braccae',
    Feet = 'Wonder Clomps',
    Neck = 'Spike Necklace',
    Waist = 'Brave Belt',
    Ear1 = 'Beetle Earring +1',
    Ear2 = 'Beetle Earring +1',
    Ring1 = 'Balance Ring',
    Ring2 = 'Balance Ring',
};

sets.Resting = {};
sets.Midcast = {
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
