local GUI = require('J-GUI');
local functions = require('J-GUI/functions');
GUI.ctx.forceReload();

functions.addResourcePath(AshitaCore:GetInstallPath() .. 'config\\addons\\luashitacast\\assets\\');

local action = gFunc.LoadFile('common/action');

local settings = {
    fastcast = 0,
    minimumBuffer = 0.1,
    packetDelay = 0.25,
};
local profile, sets = gFunc.LoadFile('common/J-Cast.lua')(settings);

local M = require('J-Mode');

settings.Main = M {
    description = 'Main Hand',
    'Espadon +1',
    'Bastard Sword +1',
    'Time Hammer',
    'Glorious Sword',
    'Terra\'s Staff',
    'Auto'
};

local subs = T {
    'R.K. Army Shield'
};
settings.Sub = M { description = 'Off Hand', subs:unpack() };

-- TODO: Rebuild subs when main changes

settings.Wizard = M(false);

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
local swapIfLowTP = function() return gData.GetPlayer().TP < 150 or settings.Main.value == 'Auto'; end
local defaultSwap = function()
    if (settings.Main.value == 'Auto') then
        return true;
    end
end

local mainSelector = GUI.ItemSelector:new({
    color = T { 0, 0x66, 0xFF },
    animated = true,
    expandDirection = GUI.ENUM.DIRECTION.LEFT,
});

local subSelector = GUI.ItemSelector:new({
    color = T { 0, 0x66, 0xFF },
    animated = true,
    expandDirection = GUI.ENUM.DIRECTION.LEFT,
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
    _y = 350
});
GUI.ctx.addView(lacUI);

lacUI:addView(mainSelector, subSelector);

mainSelector.variable = settings.Main;
subSelector.variable = settings.Sub;

local function itemType(item)
    item = AshitaCore:GetResourceManager():GetItemByName(item, 0);
    if (not item) then return; end
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

local prevSub = T {

};

local function packSub()
    if (settings.Main.value == 'Auto') then
        settings.Sub:options();
    end

    local finalSubs
    local subJob = gData.GetPlayer().SubJob;
    local canDW = subJob == 'NIN' or subJob == 'DNC'

    finalSubs = T {};
    local mainType = itemType(settings.Main.value);
    for _, item in ipairs(subs) do
        local subType = itemType(item);

        -- no subs for h2h
        if (mainType == '2h' and subType == 'grip') then
            finalSubs:insert(item);
        elseif (mainType == '1h') then
            if (subType == 'shield' or canDW and subType == '1h') then
                finalSubs:insert(item);
            end
        end
    end
    settings.Sub:options(finalSubs:unpack());
    if (#finalSubs == 0) then
        subSelector.hidden = true;
    else
        subSelector.hidden = false;
    end

    if (prevSub[settings.Main.value]) then
        settings.Sub:set(prevSub[settings.Main.value]);
    end
end

packSub();
prevSub[settings.Main.value] = settings.Sub.value;

settings.Main.on_change:register(packSub);
settings.Sub.on_change:register(function()
    prevSub[settings.Main.value] = settings.Sub.value;
end);

local hostileActions = T {};
do
    local actions = T {
        1,
        2,
        3,
        14,
        15,
        33,
        42,
        43,
        63,
        67,
        69,
        70,
        75,
        82,
        85,
        106,
        110,
        114,
        119,
        135,
        136,
        137,
        142,
        144,
        156,
        157,
        158,
        185,
        186,
        187,
        188,
        352,
        353,
        354,
        355
    }
    for _, v in ipairs(actions) do
        hostileActions[v] = v;
    end
end

local function GetIndexFromId(id)
    local entMgr = AshitaCore:GetMemoryManager():GetEntity();

    --Shortcut for monsters/static npcs..
    if (bit.band(id, 0x1000000) ~= 0) then
        local index = bit.band(id, 0xFFF);
        if (index >= 0x900) then
            index = index - 0x100;
        end

        if (index < 0x900) and (entMgr:GetServerId(index) == id) then
            return index;
        end
    end

    for i = 1, 0x8FF do
        if entMgr:GetServerId(i) == id then
            return i;
        end
    end

    return 0;
end

local function isMob(id)
    return bit.band(id, 0xFF000000) ~= 0;
end

local lastActive = 0; -- Last time player was in combat.
action:register(function(data_raw, unpackAction)
    local party = AshitaCore:GetMemoryManager():GetParty()
    local playerId = party:GetMemberServerId(0);
    local actorId = ashita.bits.unpack_be(data_raw, 0, 40, 32);

    if (playerId == actorId) then
        local actionPacket = unpackAction();
        -- Action is performed by me
        for _, target in ipairs(actionPacket.Targets) do
            if (isMob(target.Id)) then
                -- Target is a mob
                lastActive = os.clock();
                return;
            end
        end
    elseif (isMob(actorId)) then
        local actionPacket = unpackAction();
        if (not actionPacket) then
            return;
        end

        -- Action is performed by a mob
        for _, target in ipairs(actionPacket.Targets) do
            -- Check if action targets me
            if (target.Id == playerId) then
                lastActive = os.clock();
                return;
            end
        end
    end
end);

local function outOfCombat()
    return os.clock() > lastActive + 5;
end

sets.Idle = {
    Main = 'Terra\'s Staff',
    Ammo = 'Sweet Sachet',
    Head = { 'Gallant Coronet', 'Irn.Msk. Armet', 'Eisenschaller' },
    Body = { 'Gallant Surcoat', 'Parade Cuirass', 'Wonder Kaftan', 'Eisenbrust' },
    Hands = { 'Gallant Gauntlets', 'Engineer\'s Gloves', 'Eisenhentzes' },
    -- Hands = { 'Gallant Gauntlets', 'Wonder Mitts' },
    Legs = { 'Gallant Breeches', 'Wonder Braccae', 'Eisendiechlings' },
    Feet = { 'Gallant Leggings', 'Eisenschuhs' },
    Neck = { 'Parade Gorget', 'Ryl.Sqr. Collar' },
    Waist = 'Warrior\'s Belt +1',
    Ear1 = 'Mercen. Earring',
    Ear2 = { 'Hospitaler Earring', 'Shield Earring' },
    Ring1 = { 'Phalanx Ring', 'Stamina Ring' },
    Ring2 = { 'Phalanx Ring', 'Stamina Ring' },
    Back = 'Wolf Mantle +1',
    swaps = {
        {
            test = outOfCombat,
            Head = { 'Vermillion Cloak', 'Irn.Msk. Armet', 'Eisenschaller' },
            Body = { 'Vermillion Cloak', 'Parade Cuirass', 'Wonder Kaftan', 'Eisenbrust' },
        },
        {
            -- Cover is active
            test = function() return gData.GetBuffCount('Cover') > 0 end,
            Head = 'Gallant Coronet',
        },
        {
            test = function() return gData.GetBuffCount('Sleep') > 0 end,
            Neck = 'Opo-opo Necklace'
        }
    },
    swapManagedWeapons = defaultSwap
};

sets.Engaged = {
    Ammo = 'Sweet Sachet',
    Head = { 'Gallant Coronet', 'Irn.Msk. Armet', 'Eisenschaller' },
    Body = { 'Gallant Surcoat', 'Parade Cuirass', 'Wonder Kaftan', 'Eisenbrust' },
    Hands = { 'Gallant Gauntlets', 'Engineer\'s Gloves', 'Eisenhentzes' },
    -- Hands = { 'Gallant Gauntlets', 'Wonder Mitts' },
    Legs = { 'Gallant Breeches', 'Wonder Braccae', 'Eisendiechlings' },
    Feet = { 'Gallant Leggings', 'Eisenschuhs' },
    Neck = { 'Parade Gorget', 'Ryl.Sqr. Collar' },
    Waist = { 'Swift Belt', 'Warrior\'s Belt +1' },
    Ear1 = 'Mercen. Earring',
    Ear2 = { 'Hospitaler Earring', 'Shield Earring' },
    Ring1 = { 'Phalanx Ring', 'Stamina Ring' },
    Ring2 = { 'Phalanx Ring', 'Stamina Ring' },
    Back = 'Wolf Mantle +1',
    swaps = {
        {
            test = function() return gData.GetBuffCount('Cover') > 0 end,
            Head = 'Gallant Coronet',
        }
    }
};

sets.Resting = {
    -- Main = 'Pluto\'s Staff',
    Ammo = 'Sweet Sachet',
    Head = { 'Vermillion Cloak', 'Irn.Msk. Armet', 'Eisenschaller' },
    Body = { 'Vermillion Cloak', 'Parade Cuirass', 'Brigandine', 'Wonder Kaftan', 'Eisenbrust' },
    Hands = { 'Gallant Gauntlets', 'Engineer\'s Gloves', 'Eisenhentzes' },
    Legs = { 'Gallant Breeches', 'Wonder Braccae', 'Eisendiechlings' },
    Feet = { 'Gallant Leggings', 'Eisenschuhs' },
    Neck = { 'Parade Gorget', 'Ryl.Sqr. Collar' },
    Waist = 'Warrior\'s Belt +1',
    Ear1 = 'Mercen. Earring',
    Ear2 = { 'Hospitaler Earring', 'Shield Earring' },
    Ring1 = { 'Phalanx Ring', 'Stamina Ring' },
    Ring2 = { 'Phalanx Ring', 'Stamina Ring' },
    Back = 'Wolf Mantle +1',
    swapManagedWeapons = function()
        return swapIfLowTP() or settings.Main.value == 'Auto';
    end
};

sets.Midcast = {
    Head = { 'Gallant Coronet', 'Irn.Msk. Armet' },
    Body = { 'Gallant Surcoat', 'Parade Cuirass', 'Wonder Kaftan' },
    Hands = 'Gallant Gauntlets',
    Legs = 'Wonder Braccae',
    Feet = 'Gallant Leggings',
    Waist = 'Swift Belt',
};
sets.Midcast_Cure = setCombine(sets.Midcast, {
    Main = 'Apollo\'s Staff',
    Hands = 'Gallant Gauntlets',
    Legs = { 'Gallant Breeches', 'Wonder Braccae' },
    Neck = 'Justice Badge',
    -- Waist = 'Warrior\'s Belt +1',
    Ear2 = 'Hospitaler Earring',
    Back = 'Mercen. Mantle',
    swapManagedWeapons = defaultSwap
});

sets.Midcast_Holy = setCombine(sets.Midcast, {
    Main = 'Apollo\'s Staff',
    Head = 'Gallant Coronet',
    Body = { 'Gallant Surcoat', 'Wonder Kaftan' },
    Hands = 'Devotee\'s Mitts',
    Legs = 'Magic Cuisses',
    Neck = 'Justice Badge',
    Waist = 'Friar\'s Rope',
    Ear1 = 'Moldavite Earring',
    Ring1 = 'Saintly Ring',
    Ring2 = 'Saintly Ring',
    swapManagedWeapons = swapIfLowTP
});

sets.Midcast_Enlight = setCombine(sets.Midcast, {
    Main = 'Neptune\'s Staff',
    Body = 'Gallant Surcoat',
    swapManagedWeapons = function()
        return gData.GetPlayer().TP < 150;
    end
})

sets.Midcast_BanishII = setCombine(sets.Midcast_Holy, {
    swapManagedWeapons = defaultSwap
});

sets.Midcast_Banish = setCombine(sets.Midcast_Holy, {
    swapManagedWeapons = defaultSwap

});


sets.Weaponskill = {
    Head = 'Gallant Coronet',
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
    Back = 'Mercen. Mantle'
};

sets.SIRD = setCombine(sets.Idle, {
    Waist = 'Heko obi +1',
});

-- Tank set with club skill
sets.Weaponskill_Starlight = setCombine(sets.Idle, {});
sets['Weaponskill_Shining Strike'] = setCombine(sets.Weaponskill, {
    Neck = 'Justice Badge'
});


-- Atk bonus, acc penalty, 100% STR
sets.Weaponskill_TrueStrike = setCombine(sets.Weaponskill, {
    Head = 'Empress Hairpin',
});

-- Stack vit/mnd for duration
sets.JA_Cover = setCombine(sets.Idle, {
    Head = { 'Gallant Coronet', 'Irn.Msk. Armet' },   -- Mnd 3
    Body = { 'Gallant Surcoat', 'Wonder Kaftan' },    -- Vit 4
    Hands = { 'Engineer\'s Gloves', 'Eisenhentzes' }, -- Vit 1
    Legs = { 'Wonder Braccae', 'Eisendiechlings' },   -- Vit 2 Mnd 2
    Feet = 'Eisenschuhs',                             -- Vit 2
    Neck = 'Justice Badge',                           -- Mnd 3
    Waist = 'Warrior\'s Blet +1',                     -- Vit 3
    Ring1 = { 'Phalanx Ring', 'Stamina Ring' },       -- Vit 2
    Ring2 = { 'Phalanx Ring', 'Stamina Ring' },       -- Vit 2
    Back = 'Mercen. Mantle',
});

sets.JA_HolyCircle = setCombine(sets.Idle, {
    Feet = 'Gallant Leggings',
});



sets.Item_Pickaxe = {
    Body = 'Field Tunica',
    Hands = 'Field Gloves',
    Feet = 'Field Boots'
};

sets.Enmity = {
    Head = 'Gallant Coronet',
    Body = { 'Gallant Surcoat', 'Parade Cuirass' },
    Hands = 'Gallant Gauntlets',
    Legs = 'Gallant Breeches',
    Back = 'Mercen. Mantle',
};

sets.Midcast_Flash = setCombine(sets.Midcast, sets.Enmity);
sets.JA_Provoke = sets.Enmity;
sets.JA_Sentinel = sets.Enmity;


profile.Sets = sets;

profile.Packer = {
};


return profile;
