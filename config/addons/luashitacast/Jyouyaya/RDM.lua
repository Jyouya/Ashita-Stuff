local GUI = require('J-GUI');
local functions = require('J-GUI/functions');
GUI.ctx.forceReload(); -- Required since user scripts are loaded AFTER addon has already loaded.

functions.addResourcePath(AshitaCore:GetInstallPath() .. 'config\\addons\\luashitacast\\assets\\');

local M = require('J-Mode');

local settings = {
    fastcast = 0.3,
    minimumBuffer = 0.1,
    packetDelay = 0.25,
};
local profile, sets = gFunc.LoadFile('common/J-Cast.lua')(settings);

-- local isTargetTagged = gFunc.LoadFile('common/isTargetTagged.lua');

-- gFunc.LoadFile('common/helmcraft.lua')(settings, sets);

settings.Main = M { description = 'Main Hand', 'Auto', 'Buzzard Tuck', 'Acid Baselard', 'Centurion\'s Sword',
    'Solid Wand' };
local subs = T { 'Acid Baselard', 'Centurion\'s Sword', 'Solid Wand' };
settings.Sub = M { description = 'Off Hand', subs:unpack() };

settings.Enspell1 = M { description = 'Main Enspell',
    'Enfire', 'Enwater', 'Enthunder', 'Enstone', 'Enaero', 'Enblizzard', };

local enspells = T {
    Enstone = 97,
    Enaero = 96,
    Enblizzard = 95,
    Enfire = 94,
    Enwater = 99,
    Enthunder = 98,
};

profile.commands['enspell'] = function(args)
    if (args[1] == '1') then
        AshitaCore:GetChatManager():QueueCommand(-1, ('/ma %s <me>'):format(settings.Enspell1.value));
    elseif (args[1] == '2') then
        AshitaCore:GetChatManager():QueueCommand(-1, ('/ma %s <me>'):format(settings.Enspell2.value));
    end
end

-- Debug block
-- do
--     local item = AshitaCore:GetResourceManager():GetItemByName('Centurion\'s Sword', 0);
--     print(item.Skill)
--     print(item.Slots)
-- end

local function itemType(item)
    item = AshitaCore:GetResourceManager():GetItemByName(item, 0);
    if (item.Skill == 1) then
        return 'h2h';
    elseif (item.Slots == 3) then
        return '1h';
    elseif (item.Slots == 1) then
        return '2h';
    elseif (item.Slots == 2) then
        return item.Type == 5 and 'shield' or 'grip';
    end
end

local function setCombine(...)
    local res = T {};
    for _, set in ipairs({ ... }) do
        for k, v in pairs(set) do
            res[k] = v;
        end
    end
    return res;
end

local function packSub()
    local finalSubs
    local subJob = gData.GetPlayer().SubJob;
    if (subJob == 'NIN' or subJob == 'DNC') then
        finalSubs = subs;
    else
        finalSubs = T {};
        for _, item in ipairs(subs) do
            if (itemType(item) == 'shield') then
                finalSubs:insert(item);
            end
        end
    end
    -- for _, v in ipairs(finalSubs) do
    --     print(v);
    -- end
    settings.Sub:options(finalSubs:unpack());
end

-- This layers new gear onto the queued midcast gear.
local function changeMidcast(set)
    for k, v in pairs(set) do
        gState.DelayedEquip.Set[k] = v;
    end
end

packSub();

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

local mainSelector = GUI.ItemSelector:new({
    color = T { 255, 0, 0 },
    animated = true,
    expandDirection = GUI.ENUM.DIRECTION.LEFT,
});

local subSelector = GUI.ItemSelector:new({
    color = T { 255, 0, 0 },
    animated = true,
    expandDirection = GUI.ENUM.DIRECTION.LEFT,
});

local getEnspellTexture;
do
    local textures = T {};
    getEnspellTexture = function(_, spellName)
        local statusId = enspells[spellName];
        local tex = textures[statusId];
        local iconPath = nil;
        local supportsAlpha = false;
        if (not tex) then
            T { '.png', '.jpg', '.jpeg', '.bmp' }:forieach(function(ext, _)
                if (iconPath ~= nil) then
                    return;
                end

                supportsAlpha = ext == '.png';
                iconPath = AshitaCore:GetInstallPath() ..
                    'addons\\HXUI\\assets\\status\\XIView\\' .. tostring(statusId) .. ext;
                local handle = io.open(iconPath, 'r');
                if (handle ~= nil) then
                    handle.close();
                else
                    iconPath = nil;
                end
            end);

            if (iconPath) then
                if (supportsAlpha) then
                    tex = functions.loadAssetTexture(iconPath);
                else
                    tex = functions.loadAssetTextureTransparent(iconPath);
                end
            else
                tex = functions.loadStatusTexture(statusId);
            end

            textures[statusId] = tex;
        end
        return tex;
    end
end

local enspellSelector = GUI.ItemSelector:new({
    color = T { 255, 0, 0 },
    animated = true,
    expandDirection = GUI.ENUM.DIRECTION.LEFT,
    getTexture = getEnspellTexture,
});



local lacUI = GUI.Container:new({
    layout = GUI.Container.LAYOUT.GRID,
    gridRows = GUI.Container.LAYOUT.AUTO,
    gridCols = 2,
    fillDirection = GUI.Container.LAYOUT.VERTICAL,
    gridGap = 4,
    padding = { x = 2, y = 2 },
    draggable = true,
    _x = 1560,
    _y = 350,
});
GUI.ctx.addView(lacUI);

lacUI:addView(mainSelector, subSelector, enspellSelector);

mainSelector.variable = settings.Main;
subSelector.variable = settings.Sub;
enspellSelector.variable = settings.Enspell1;

settings.Main.on_change:register(function(m)
    if (m.value == 'Auto') then
        subSelector.hidden = true;
    else
        subSelector.hidden = false;
    end
end);
subSelector.hidden = true;

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

local elementalStaff;
elementalStaff = T {
    test = function(action)
        elementalStaff.Main = staves[action.Element];
        return AshitaCore:GetMemoryManager():GetPlayer():GetMainJobLevel() >= 51;
    end,
    Sub = 'displaced',
};

sets.Engaged = {
    Ammo = 'Sweet Sachet',
    Head = 'Empress Hairpin',
    Body = { 'Cerise Doublet', 'Wonder Kaftan' },
    Hands = { 'Warlock\'s Gloves', 'Wonder Mitts', 'Ryl.Ftm. Gloves' },
    Legs = 'Wonder Braccae',
    Feet = 'Wonder Clomps',
    Neck = 'Spike Necklace',
    Waist = { 'Swift Belt', 'Warrior\'s Belt +1', },
    Ear1 = 'Beetle Earring +1',
    Ear2 = 'Beetle Earring +1',
    Ring1 = 'Balance Ring',
    Ring2 = 'Balance Ring',
    Back = 'Wolf Mantle +1',
    swaps = {
        {
            test = function() return gData.GetPlayer().MPP < 30; end,
            Body = 'Vermillion Cloak',
            Head = 'Vermillion Cloak',
        }
    }
};

sets.Idle = setCombine(sets.Engaged, {
    Main = 'Terra\'s Staff',
    Ammo = 'Sweet Sachet',
    Feet = { 'Warlock\'s Boots', 'Wonder Clomps' },
    Head = { 'Vermillion Cloak', 'Empress Hairpin' },
    Body = { 'Vermillion Cloak', 'Warlock\'s Tabard', 'Wonder Kaftan' },
    Hands = { 'Warlock\'s Gloves', 'Wonder Mitts' },
    Legs = { 'Warlock\'s Tights', 'Wonder Braccae' },
    Neck = 'Justice Badge',
    Waist = 'Warrior\'s Belt +1',
    Ear1 = 'Morion Earring',
    Ear2 = 'Morion Earring',
    Ring1 = 'Stamina Ring',
    Ring2 = 'Stamina Ring',
    swapManagedWeapons = swapAutoOnly,
});

sets.Resting = setCombine(sets.Idle, {
    Main = { 'Pluto\'s Staff', 'Pilgrim\'s Wand' },
    Legs = 'Baron\'s Slops',
    Neck = 'Checkered Scarf',
    swapManagedWeapons = function()
        return gData.GetPlayer().MPP < 0.3 or swapIfLowTP();
    end,
});

sets.Weaponskill = {
    Head = 'Mrc.Cpt. Headgear',
    Body = 'Wonder Kaftan',
    Hands = { 'Wonder Mitts', 'Ryl.Ftm. Gloves' },
    Legs = 'Wonder Braccae',
    Feet = 'Wonder Clomps',
    Neck = 'Spike Necklace',
    Waist = 'Brave Belt',
    Ear1 = 'Beetle Earring +1',
    Ear2 = 'Beetle Earring +1',
    Ring1 = 'Courage Ring',
    Ring2 = 'Courage Ring',
};

sets.Weaponskill_Dagger = setCombine(sets.Weaponskill, {
    Head = 'Empress Hairpin',
});

sets.Precast = {
    Head = 'Warlock\'s Chapeau'
};

sets.Midcast_Cure = {
    Main = { 'Apollo\'s Staff', 'Solid Wand', 'Yew Wand +1' },
    Head = { 'Warlock\'s Chapeau', 'Traveler\'s Hat' },
    Body = { 'Wonder Kaftan', 'Baron\'s Saio' },
    Hands = 'Devotee\'s Mitts',
    Legs = { 'Warlock\'s Tights', 'Magic Cuisses', 'Wonder Braccae' },
    Feet = 'Warlock\'s Boots',
    Neck = 'Justice Badge',
    Waist = { 'Swift Belt', 'Friar\'s Rope' },
    Ring1 = 'Saintly Ring',
    Ring2 = 'Saintly Ring',
    Back = 'White Cape +1',
    swapManagedWeapons = defaultSwap, -- Never Swap
};

sets.Midcast_EnhancingMagic = {
    Head = 'Warlock\'s Chapeau',
    Body = 'Glamor Jupon',
    Legs = 'Warlock\'s Tights',
    Waist = 'Swift Belt',
};

sets.Midcast_EnspellTierOne = setCombine(sets.Midcast_EnhancingMagic, {
    Main = 'Buzzard Tuck',
    swapManagedWeapons = alwaysSwap,
});

sets.Midcast_MndEnfeeble = {
    Main = 'Fencing Degen',
    Head = 'Traveler\'s Hat',
    Body = { 'Warlock\'s Tabard', 'Glamor Jupon', 'Wonder Kaftan', 'Baron\'s Saio' },
    Hands = 'Devotee\'s Mitts',
    Legs = { 'Warlock\'s Tights', 'Magic Cuisses', 'Wonder Braccae' },
    Feet = 'Warlock\'s Boots',
    Neck = 'Justice Badge',
    Waist = 'Friar\'s Rope',
    Ring1 = 'Saintly Ring',
    Ring2 = 'Saintly Ring',
    Back = 'White Cape +1',
    swapManagedWeapons = defaultSwap,
    swaps = {
        { test = canDW, Sub = 'Solid Wand', },
        elementalStaff,
    }
};

sets.Midcast_MndEnfeebleScaling = {
    Main = 'Fencing Degen',
    Head = 'Traveler\'s Hat',
    Body = { 'Wonder Kaftan', 'Baron\'s Saio' },
    Hands = 'Devotee\'s Mitts',
    Legs = { 'Warlock\'s Tights', 'Magic Cuisses', 'Wonder Braccae' },
    Feet = 'Warlock\'s Boots',
    Neck = 'Justice Badge',
    Waist = 'Friar\'s Rope',
    Ring1 = 'Saintly Ring',
    Ring2 = 'Saintly Ring',
    Back = 'White Cape +1',
    swapManagedWeapons = defaultSwap,
    swaps = {
        { test = canDW, Sub = 'Solid Wand', },
        elementalStaff,
    }
};

sets.Midcast_IntEnfeeble = {
    Main = 'Fencing Degen',
    Ammo = 'Sweet Sachet',
    Head = { 'Warlock\'s Chapeau', 'Baron\'s Chapeau' },
    Body = { 'Warlock\'s Tabard', 'Glamor Jupon', 'Baron\'s Saio' },
    Hands = 'Engineer\'s Mitts',
    Legs = { 'Magic Cuisses', 'Mage\'s Slacks' },
    Feet = 'Warlock\'s Boots',
    Neck = { 'Checkered Scarf', 'Black Neckerchief' },
    Waist = 'Shaman\'s Belt',
    Ear1 = 'Morion Earring',
    Ear2 = 'Morion Earring',
    Ring1 = 'Eremite\'s Ring',
    Ring2 = 'Eremite\'s Ring',
    Back = 'Black Cape +1',
    swapManagedWeapons = defaultSwap,
    swaps = {
        { test = canDW, Sub = 'Solid Wand', },
        elementalStaff,
    }
};

sets.Midcast_IntEnfeebleScaling = {
    Main = 'Fencing Degen',
    Ammo = 'Sweet Sachet',
    Head = { 'Warlock\'s Chapeau', 'Baron\'s Chapeau' },
    Body = 'Baron\'s Saio',
    Hands = 'Engineer\'s Mitts',
    Legs = { 'Magic Cuisses', 'Mage\'s Slacks' },
    Feet = 'Warlock\'s Boots',
    Neck = { 'Checkered Scarf', 'Black Neckerchief' },
    Waist = 'Shaman\'s Belt',
    Ear1 = 'Morion Earring',
    Ear2 = 'Morion Earring',
    Ring1 = 'Eremite\'s Ring',
    Ring2 = 'Eremite\'s Ring',
    Back = 'Black Cape +1',
    swapManagedWeapons = defaultSwap,
    swaps = {
        { test = canDW, Sub = 'Solid Wand' },
        elementalStaff,
    }
};

sets.Midcast_Poison = {
    Main = 'Fencing Degen',
    Ammo = 'Sweet Sachet',
    Head = { 'Warlock\'s Chapeau', 'Baron\'s Chapeau' },
    Body = { 'Warlock\'s Tabard', 'Glamor Jupon', 'Baron\'s Saio' },
    Hands = 'Engineer\'s Mitts',
    Legs = { 'Magic Cuisses', 'Mage\'s Slacks' },
    Feet = 'Warlock\'s Boots',
    Neck = { 'Checkered Scarf', 'Black Neckerchief' },
    Waist = 'Shaman\'s Belt',
    Ear1 = 'Morion Earring',
    Ear2 = 'Morion Earring',
    Ring1 = 'Eremite\'s Ring',
    Ring2 = 'Eremite\'s Ring',
    Back = 'Black Cape +1',
    swapManagedWeapons = defaultSwap,
    swaps = {
        { test = canDW, Sub = 'Solid Wand' },
        elementalStaff,
    }
};

sets.Midcast_ElementalMagic = {
    Main = { 'Solid Wand', 'Yew Wand +1' },
    Ammo = 'Sweet Sachet',
    Head = { 'Warlock\'s Chapeau', 'Baron\'s Chapeau' },
    Body = 'Baron\'s Saio',
    Hands = 'Engineer\'s Mitts',
    Legs = { 'Magic Cuisses', 'Mage\'s Slacks' },
    Feet = 'Warlock\'s Boots',
    Neck = { 'Checkered Scarf', 'Black Neckerchief' },
    Waist = 'Shaman\'s Belt',
    Ear1 = 'Moldavite Earring',
    Ear2 = 'Morion Earring',
    Ring1 = 'Eremite\'s Ring',
    Ring2 = 'Eremite\'s Ring',
    Back = 'Black Cape +1',
    swapManagedWeapons = defaultSwap,
    swaps = {
        { test = canDW, Sub = 'Solid Wand', },
        elementalStaff,
    }
};

-- sets.SIRD = gFunc.Combine(sets.Idle, {
--     Body = 'Warlock\'s Tabard',
--     Waist = 'Heko obi +1',
--     Main = ''
--     -- swapManagedWeapons = function() return false end
-- });
sets.SIRD = {
    Body = 'Warlock\'s Tabard',
    Waist = 'Heko obi +1',
    -- Main = ''
    -- swapManagedWeapons = function() return false end
};

profile.Sets = sets;

profile.Packer = {};

return profile;
