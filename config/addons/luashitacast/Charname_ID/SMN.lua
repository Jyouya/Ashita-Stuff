local GUI = require('J-GUI');
local functions = require('J-GUI/functions');
GUI.ctx.forceReload(); -- Required since user scripts are loaded AFTER addon has already loaded.

functions.addResourcePath(AshitaCore:GetInstallPath() .. 'config\\addons\\luashitacast\\assets\\');

local M = require('J-Mode');

local settings = {
    fastcast = 0.0,
    minimumBuffer = 0.1,
    packetDelay = 0.25,
};
local profile, sets = gFunc.LoadFile('common/J-Cast.lua')(settings);

local function setCombine(...)
    local res = T {};
    for _, set in ipairs({ ... }) do
        for k, v in pairs(set) do
            res[k] = v;
        end
    end
    return res;
end

local alwaysSwap = function() return true; end
local swapIfLowTP = function() return gData.GetPlayer().TP < 400; end
local canDW = function()
    local subJob = gData.GetPlayer().SubJob;
    return subJob == 'NIN' or subJob == 'DNC';
end

local defaultSwap = function()
    if (settings.Main.value == 'Auto') then
        return true;
    else
        return swapIfLowTP();
    end
end

local swapAutoOnly = function()
    return settings.Main.value == 'Auto';
end

local staves = T {
    Light = 'Apollo\'s Staff',
    Dark = 'Pluto\'s Staff',
    Fire = 'Vulcan\'s Staff',
    Water = 'Neptune\'s Staff',
    Thunder = 'Jupiter\'s Staff',
    Earth = 'Terra\'s Staff',
    Wind = 'Auster\'s Staff',
    Ice = 'Aquilo\'s Staff',
};

local avatarElements = {
    -- Celestial
    ['Ifrit'] = 'Fire',
    ['Titan'] = 'Earth',
    ['Leviathan'] = 'Water',
    ['Garuda'] = 'Wind',
    ['Shiva'] = 'Ice',
    ['Ramuh'] = 'Thunder',
    ['Alexander'] = 'Light',
    ['Odin'] = 'Dark',

    -- Terrestrial
    ['Carbuncle'] = 'Light',
    ['Fenrir'] = 'Dark',
    ['Siren'] = 'Wind',
    ['Diabolos'] = 'Dark',

    -- Other
    ['Cait Sith'] = 'Light',
    ['Atomos'] = 'Dark',

    -- Spirits
    ['Fire Spirit'] = 'Fire',
    ['Air Spirit'] = 'Wind',
    ['Earth Spirit'] = 'Earth',
    ['Thunder Spirit'] = 'Thunder',
    ['Water Spirit'] = 'Water',
    ['Ice Spirit'] = 'Ice',
    ['Light Spirit'] = 'Light',
    ['Dark Spirit'] = 'Dark',
};


local elementalStaff;
elementalStaff = T {
    test = function(action)
        elementalStaff.Main = staves[action.Element];
        return AshitaCore:GetMemoryManager():GetPlayer():GetMainJobLevel() >= 51;
    end,
    Sub = 'displaced',
};
local petStaff;
petStaff = T {
    test = function()
        local pet = gData.GetPet();
        if (not pet) then return; end
        petStaff.Main = staves[avatarElements[pet.Name]];
        return AshitaCore:GetMemoryManager():GetPlayer():GetMainJobLevel() >= 51;
    end,
    Sub = 'displaced'
};

sets.Engaged = {
    swaps = {
        petStaff,
    },
};

sets.Idle = {
    swaps = {
        petStaff,
    }
};

sets.Resting = setCombine(sets.Idle, {
    swaps = {
        petStaff
    }
});

sets.Weaponskill = {
};

sets.Precast = {
};

sets.Midcast_Cure = {
};

sets.SIRD = {
};

profile.Sets = sets;

profile.Packer = {};

return profile;
