local settings = {
    fastcast = 0,
    minimumBuffer = 0.1,
    packetDelay = 0.25,
};
local profile, sets = gFunc.LoadFile('common/J-Cast.lua')(settings);

sets.Idle = {

};

sets.Engaged = {

};

sets.Midcast = {

};

sets.SIRD = {

};

sets.Weaponskill = {

};

sets.Midcast_DarkMagic = {

};

sets.Midcast_ElementalMagic = {

};

profile.Sets = sets;

profile.Packer = {};

return profile;