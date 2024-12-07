local GUI = require('J-GUI');
local functions = require('J-GUI/functions');
GUI.ctx.forceReload();

local gear = require('Jyouya-gear');

functions.addResourcePath(AshitaCore:GetInstallPath() .. 'config\\addons\\luashitacast\\assets\\');

local action = require('common.events.action');


local settings = {
    fastcast = 0,
    minimumBuffer = 0.1,
    packetDelay = 0.25,
};
local profile, sets = gFunc.LoadFile('common/J-Cast.lua')(settings);
local predicates = require('common.J-Predicates')(settings);

local p_and = predicates.p_and;
local p_not = predicates.p_not;
local p_or = predicates.p_or;

local M = require('J-Mode');

settings.Main = M {
    description = 'Main Hand',
    'Burtgang',
    'Naegling',
    'Malignance Sword',
    'Malevolence',
    'Auto'
};

local subs = T {
    'Ochain',
    'Aegis',
    'Srivasta',
    'Duban',
    'Priwen',
    'Blurred Shield +1',
    'Utu Grip',
    'Auto'
};
settings.Sub = M { description = 'Off Hand', subs:unpack() };

-- TODO: Rebuild subs when main changes

-- ? I don't know what this was supposed to do
settings.Wizard = M(false);

settings.CombatMode = M {
    description = 'Combat Mode',
    'Default',
    'Odyssey',
    'Sortie',
    'DD'
}

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

local jse = T {
    af = T {
        Head = 'Rev. Coronet +1',
        Body = 'Rev. Surcoat +2',
        Hands = 'Rev. Gauntlets +2',
        Legs = 'Rev. Breeches +2',
        Feet = 'Rev. Leggings +2',
    },
    relic = T {
        Head = 'Cab. Coronet +1',
        Body = 'Cab. Surcoat +1',
        Hands = 'Cab. Gauntlets +1',
        Legs = 'Cab. Breeches +1',
        Feet = 'Cab. Leggings +1',
    },
    empy = T {
        Head = 'Chev. Armet +1',
        Body = 'Chev. Cuirass +1',
        Hands = 'Chev. Gauntlets +1',
        Legs = 'Chev. Cuisses +1',
        Feet = 'Chev. Sabatons +1'
    }
}
local lastActive = 0; -- Last time player was in combat.
local combatTargets = T {};

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

                combatTargets[target.Id] = lastActive;
                return;
            end
        end
    end
end);

local function enemyCount(enemies)
    return function()
        local count = 0;
        for id, active in pairs(combatTargets) do
            if (os.clock() > active + 5) then
                combatTargets[id] = nil;
            else
                count = count + 1;
            end
        end

        return count >= enemies;
    end
end

local function outOfCombat()
    return os.clock() > lastActive + 5;
end

print(gear.Souveran_Legs_PathC)

local outOfCombatIdle = p_and(
    outOfCombat,
    function() return gData.GetPlayer().Status == 'Idle' end
)

sets.Phalanx_Received = T {
    Sub = 'Priwen',
    Hands = gear.Souveran_Hands_PathC, -- Path D
    Feet = gear.Souveran_Feet_PathD,
    -- Back = 'Weard Mantle',

}

sets.Idle = {
    Ammo = 'Staunch Tathlum +1',
    Head = 'Hjarrandi Helm',
    Body = gear.Souveran_Body_PathC, -- Path D for refresh
    Hands = gear.Souveran_Hands_PathC,
    Legs = gear.Souveran_Legs_PathC,
    Feet = jse.af.Feet,
    Neck = 'Unmoving Collar +1',
    Waist = 'Creed Baudrier',
    Ear1 = 'Tuisto Earring',
    Ear2 = 'Odnowa Earring +1',
    Ring1 = 'Gelatinous Ring +1',
    Ring2 = 'Defending Ring',
    Back = gear.Rudianos_Tank,
    swaps = {
        {
            -- Idle Refresh gear
            test = outOfCombatIdle,
            Head = 'Displaced',
            Body = 'Respite Cloak',
            Neck = 'Vim Torque +1',
            Hands = 'Regal Gauntlets',
            Waist = 'Fucho-no-Obi',
        },
        {
            -- Pro/shell gear
            test = p_and(outOfCombatIdle,
                p_not(p_and(predicates.buff_active('Protect'),
                    predicates.buff_active('Shell')))),
            Ring2 = 'Sheltered Ring'
        },
        {
            -- Phalanx gear
            test = p_and(outOfCombatIdle,
                p_not(predicates.buff_active('Phalanx'))),
            sets.Phalanx_Received:unpack()
        },
        {
            -- Cover is active
            test = function() return gData.GetBuffCount('Cover') > 0 end,
            Head = jse.af.Head,
            Body = jse.relic.Body
        },
        -- {
        --     test = function() return gData.GetBuffCount('Sleep') > 0 end,
        --     Neck = 'Opo-opo Necklace'
        -- }
    }
};

sets.Engaged = {
    Ammo = 'Staunch Tathlum +1',
    Head = 'Hjarrandi Helm',
    Body = gear.Souveran_Body_PathC,
    Hands = gear.Souveran_Hands_PathD,
    Legs = gear.Souveran_Legs_PathC,
    Feet = jse.af.Feet,
    Neck = 'Unmoving Collar +1',
    Waist = 'Sailfi Belt +1',
    Ear1 = 'Tuisto Earring',
    Ear2 = 'Odnowa Earring +1',
    Ring1 = 'Gelatinous Ring +1',
    Ring2 = 'Defending Ring',
    Back = gear.Rudianos_Tank,
    swaps = {
        {
            test = function() return gData.GetBuffCount('Cover') > 0 end,
            Head = jse.af.Head,
        }
    }
};

sets.Resting = sets.Idle;

sets.Precast = {
    Ammo = 'Sapience Orb',
    Head = gear.Carmine_Head_PathD, -- 14
    Body = jse.af.Body,             -- 5
    Hands = 'Leyline Gloves',       -- 8
    Legs = 'Enif Cosciales',
    Feet = gear.Carmine_Feet_PathD, -- 8
    Ear1 = 'Enchntr. Earring +1',
    Ear2 = 'Loquac. Earring',       -- 2
    Ring1 = 'Kishar Ring',          -- 4
    Ring2 = 'Prolix Ring',          -- 2
    Neck = 'Baetyl Pendant',        -- 4
    Back = gear.Rudianos_FC_Midcast
}

sets.Midcast = {
    Head = { 'Gallant Coronet', 'Irn.Msk. Armet' },
    Body = { 'Gallant Surcoat', 'Parade Cuirass', 'Wonder Kaftan' },
    Hands = 'Gallant Gauntlets',
    Legs = 'Wonder Braccae',
    Feet = 'Gallant Leggings',
    Waist = 'Swift Belt',
    Back = gear.Rudianos_FC_Midcast
};

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

-- Stack vit/mnd for duration
-- sets.JA_Cover = setCombine(sets.Idle, {
--     Head = { 'Gallant Coronet', 'Irn.Msk. Armet' },   -- Mnd 3
--     Body = { 'Gallant Surcoat', 'Wonder Kaftan' },    -- Vit 4
--     Hands = { 'Engineer\'s Gloves', 'Eisenhentzes' }, -- Vit 1
--     Legs = { 'Wonder Braccae', 'Eisendiechlings' },   -- Vit 2 Mnd 2
--     Feet = 'Eisenschuhs',                             -- Vit 2
--     Neck = 'Justice Badge',                           -- Mnd 3
--     Waist = 'Warrior\'s Blet +1',                     -- Vit 3
--     Ring1 = { 'Phalanx Ring', 'Stamina Ring' },       -- Vit 2
--     Ring2 = { 'Phalanx Ring', 'Stamina Ring' },       -- Vit 2
--     Back = 'Mercen. Mantle',
-- });



sets.Enmity = {
    Head = 'Loess Barbuta +1',
    Body = gear.Souveran_Body_PathC,
    Hands = gear.Souveran_Hands_PathC,
    Legs = gear.Souveran_Legs_PathC,
    Feet = gear.Eschite_Feet_PathA,
    Neck = 'Moonlight Necklace',
    Waist = 'Creed Baudrier',
    Ear1 = 'Tuisto Earring',
    Ear2 = 'Odnowa Earring +1',
    Ring1 = 'Eiwhaz Ring',
    Ring2 = 'Petrov Ring'
};

sets.SIRD = setCombine(sets.Enmity, {
    Head = gear.Souveran_Head_PathD,
    Ammo = 'Staunch Tathlum +1',
    Waist = 'Audumbla Sash',
    Neck = 'Moonlight Necklace',
})

sets.Midcast = sets.Enmity;

sets.Midcast_Flash = {
    Main = 'Burtgang',
    Sub = 'Srivatsa',
    Ammo = 'Sapience Orb',
    Head = gear.Carmine_Head_PathD,
    Body = gear.Souveran_Body_PathC,
    Hands = gear.Souveran_Hands_PathC,
    Legs = gear.Souveran_Legs_PathC,
    Feet = gear.Carmine_Feet_PathD,
    Neck = 'Moonlight Necklace',
    Waist = 'Creed Baudrier',
    Ear1 = 'Tuisto Earring',
    Ear2 = 'Cryptic Earring',
    Ring1 = 'Eiwhaz Ring',
    Ring2 = 'Petrov Ring',
    Back = gear.Rudianos_Tank,
    swaps = {
        {
            test = enemyCount(3),
            Ammo = 'Staunch Tathlum +1',
            Waist = 'Audumbla Sash',
            -- SIRD gear
        }
    }

};

sets.Midcast_Cure = {
    Ammo = 'Egoist\'s Tathlum',
    Head = 'Loess Barbuta +1',
    Body = gear.Souveran_Body_PathC,
    Hands = 'Macabre Gaunt. +1',
    Legs = gear.Souveran_Legs_PathC,
    Feet = jse.empy.Feet,
    Neck = 'Sacro Gorget',
    Waist = 'Creed Baudrier',
    Ear1 = 'Tuisto Earring',
    Ear2 = 'Cryptic Earring',
    Ring1 = 'Eiwhaz Ring',
    Ring2 = 'Gelatinous Ring +1',
    Back = gear.Rudianos_Cure,
    swaps = {
        {
            test = enemyCount(3),
            Ammo = 'Staunch Tathlum +1',
            Waist = 'Audumbla Sash',
            Neck = 'Moonlight Necklace',
            -- SIRD gear

        }
    }
};

sets.Midcast_Jettatura = sets.Flash;
sets.Midcast_SheepSong = sets.Flash;
sets.Midcast_GeistWall = sets.Flash;

sets.JA_HolyCircle = setCombine(sets.Enmity, {
    Feet = jse.af.Feet,
});

sets.JA_Provoke = sets.Enmity;
sets.JA_Sentinel = setCombine(sets.Enmity, {
    Feet = jse.relic.Feet
});
sets.JA_Rampart = setCombine(sets.Enmity, {
    Head = jse.relic.Head
});

-- TODO: Macc set
sets.JA_ShieldBash = setCombine(sets.Enmity, {
    Hands = jse.relic.Hands
});

sets.JA_Invincible = setCombine(sets.Enmity, {
    Legs = jse.relic.Legs
});


profile.Sets = sets;

profile.Packer = {
};


return profile;
