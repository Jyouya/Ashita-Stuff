local settings = {
    fastcast = 0.0,
    minimumBuffer = 0.1,
    packetDelay = 0.25,
};
local profile, sets = gFunc.LoadFile('common/J-Cast.lua')(settings);

sets.Idle = {
    Main = 'Yew Wand +1',
    Sub = 'Yew Wand +1',
    Ammo = 'Sweet Sachet',
    Head = { 'Seer\'s Crown +1', 'Baron\'s Chapeau' },
    Body = 'Baron\'s Saio',
    Hands = 'Mycophile Cuffs',
    Legs = 'Mage\'s Slacks',
    Feet = 'Wonder Clomps',
    Neck = 'Black Neckerchief',
    Waist = 'Shaman\'s Belt',
    Ring1 = 'Stamina Ring',
    Ring2 = 'Stamina Ring'
};

sets.Resting = gFunc.Combine(sets.Idle, {
    Main = 'Pilgrim\'s Wand',
    Body = 'Seer\'s Tunic',
    Legs = 'Baron\'s Slops',
    -- swapManagedWeapons = function() return true end,
});


sets.Midcast_IntEnfeeble = {
    Main = 'Yew Wand +1',
    Sub = 'Yew Wand +1',
    Ammo = 'Sweet Sachet',
    Head = { 'Seer\'s Crown +1', 'Baron\'s Chapeau' },
    Body = 'Baron\'s Saio',
    Hands = 'Mycophile Cuffs',
    Legs = 'Mage\'s Slacks',
    Neck = 'Black Neckerchief',
    Waist = 'Shaman\'s Belt',
    Ear1 = 'Morion Earring',
    Ear2 = 'Morion Earring',
    Ring1 = 'Eremite\'s Ring',
    Ring2 = 'Eremite\'s Ring',
    Back = 'Black Cape +1'
};

sets.Midcast_IntEnfeebleScaling = {
    Main = 'Yew Wand +1',
    Sub = 'Yew Wand +1',
    Ammo = 'Sweet Sachet',
    Head = { 'Seer\'s Crown +1', 'Baron\'s Chapeau' },
    Body = 'Baron\'s Saio',
    Hands = 'Mycophile Cuffs',
    Legs = 'Mage\'s Slacks',
    Neck = 'Black Neckerchief',
    Waist = 'Shaman\'s Belt',
    Ear1 = 'Morion Earring',
    Ear2 = 'Morion Earring',
    Ring1 = 'Eremite\'s Ring',
    Ring2 = 'Eremite\'s Ring',
    Back = 'Black Cape +1',
};

sets.Midcast_ElementalMagic = {
    Main = 'Yew Wand +1',
    Sub = 'Yew Wand +1',
    Ammo = 'Sweet Sachet',
    Head = { 'Seer\'s Crown +1', 'Baron\'s Chapeau' },
    Body = 'Baron\'s Saio',
    Hands = 'Mycophile Cuffs',
    Legs = 'Mage\'s Slacks',
    Neck = 'Black Neckerchief',
    Waist = 'Shaman\'s Belt',
    Ear1 = 'Morion Earring',
    Ear2 = 'Morion Earring',
    Ring1 = 'Eremite\'s Ring',
    Ring2 = 'Eremite\'s Ring',
    Back = 'Black Cape +1',
};

sets.SIRD = gFunc.Combine(sets.Idle, {
    Waist = 'Heko obi +1',
});

profile.Sets = sets;

profile.Packer = {};

return profile;
