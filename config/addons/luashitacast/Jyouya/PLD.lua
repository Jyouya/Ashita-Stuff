local GUI = require('J-GUI');
local functions = require('J-GUI/functions');
GUI.ctx.forceReload();

local gear = require('Jyouya-gear');

functions.addResourcePath(AshitaCore:GetInstallPath() .. 'config\\addons\\luashitacast\\assets\\');

local action = require('common.events.action');

local slots = T {
    Main = true,
    Sub = true,
    Range = true,
    Ammo = true,
    Head = true,
    Neck = true,
    Ear1 = true,
    Ear2 = true,
    Body = true,
    Hands = true,
    Ring1 = true,
    Ring2 = true,
    Back = true,
    Waist = true,
    Legs = true,
    Feet = true
}

local function validateItem(item)
    if type(item) == 'table' then
        item = item.Name
    end
    if (item == 'displaced' or item == 'remove') then
        return true
    end

    return item and AshitaCore:GetResourceManager():GetItemByName(item, 2);
end

local function validateSet(t)
    for k, v in pairs(t) do
        if (slots[k]) then
            if (not validateItem(v)) then
                if (type(v) == 'table') then
                    print('table item:')
                    for l, w in pairs(v) do
                        print('k: ' .. tostring(l) .. ', v: ' .. tostring(w));
                    end
                else
                    print(v);
                end
            end
        elseif type(v) == 'table' then
            validateSet(v);
        end
    end
end

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
    'Sakpata\'s Sword',
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
    'Balanced',
    'Kite',
    'Block',
    'Meva',
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

local function dropdownFactory(variable, label)
    return GUI.Container:new({
        layout = GUI.Container.LAYOUT.GRID,
        gridRows = GUI.Container.LAYOUT.AUTO,
        gridCols = 1,
        fillDirection = GUI.Container.LAYOUT.VERTICAL,
        gridGap = 2,
        padding = { x = 0, y = 0 },
        draggable = true,
    }):addView(
        GUI.Label:new({ value = label or variable.description }),
        GUI.Dropdown:new({
            color = T { 0xFF, 0x66, 0x33 },
            animated = true,
            expandDirection = GUI.ENUM.DIRECTION.DOWN,
            _width = 130,
            isFixedWidth = true,
            variable = variable
        })
    );
end

local function itemSelectorFactory(variable, texture)
    return GUI.ItemSelector:new({
        color = T { 0xFF, 0x66, 0x33 },
        animated = true,
        expandDirection = GUI.ENUM.DIRECTION.LEFT,
        variable = variable,
        lookupTexture = texture
    });
end

GUI.ctx.addView(GUI.Container:new({
    layout = GUI.Container.LAYOUT.GRID,
    gridRows = GUI.Container.LAYOUT.AUTO,
    gridCols = 1,
    fillDirection = GUI.Container.LAYOUT.VERTICAL,
    gridGap = 4,
    padding = { x = 2, y = 2 },
    draggable = true,
    _x = 1560,
    _y = 350
}):addView(
    GUI.Container:new({
        layout = GUI.Container.LAYOUT.GRID,
        gridRows = GUI.Container.LAYOUT.AUTO,
        gridCols = 2,
        fillDirection = GUI.Container.LAYOUT.VERTICAL,
        gridGap = 4,
        padding = { x = 2, y = 2 },
        draggable = true,
        _x = 1560,
        _y = 350
    }):addView(
        itemSelectorFactory(settings.Main),
        itemSelectorFactory(settings.Sub)
    ),
    dropdownFactory(settings.CombatMode)
))

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
    -- if (settings.Main.value == 'Auto') then
    --     settings.Sub:options();
    -- end

    local finalSubs
    local subJob = gData.GetPlayer().SubJob;
    local canDW = subJob == 'NIN' or subJob == 'DNC'

    finalSubs = T {};
    local mainType = itemType(settings.Main.value) or '1h';
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

    prevSub[mainType] = settings.Sub.value;


    settings.Sub:options(finalSubs:unpack());
    -- if (#finalSubs == 0) then
    --     subSelector.hidden = true;
    -- else
    --     subSelector.hidden = false;
    -- end

    if (prevSub[mainType]) then
        settings.Sub:set(prevSub[mainType]);
    end
end

packSub();
prevSub[itemType(settings.Main.value) or '1h'] = settings.Sub.value;

settings.Main.on_change:register(packSub);

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

local function isMob(id)
    return bit.band(id, 0xFF000000) ~= 0;
end

local jse = T {
    af = T {
        Head = 'Rev. Coronet +1',
        Body = 'Rev. Surcoat +3',
        Hands = 'Rev. Gauntlets +2',
        Legs = 'Rev. Breeches +2',
        Feet = 'Rev. Leggings +3',
    },
    relic = T {
        Head = 'Cab. Coronet +1',
        Body = 'Cab. Surcoat +1',
        Hands = 'Cab. Gauntlets +3',
        Legs = 'Cab. Breeches +1',
        Feet = 'Cab. Leggings +1',
    },
    empy = T {
        Head = 'Chev. Armet +3',
        Body = 'Chev. Cuirass +2',
        Hands = 'Chev. Gauntlets +1',
        Legs = 'Chev. Cuisses +3',
        Feet = 'Chev. Sabatons +2'
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

                combatTargets[actorId] = lastActive;
                return;
            end
        end
    end
end);

local function enemyCount(enemies)
    return function()
        local count = 0;
        for id, active in pairs(combatTargets) do
            if (os.clock() > active + 10) then
                combatTargets[id] = nil;
            else
                count = count + 1;
            end
        end

        return count >= enemies;
    end
end

local function outOfCombat()
    return os.clock() > lastActive + 7;
end

local outOfCombatIdle = p_and(
    outOfCombat,
    function() return gData.GetPlayer().Status == 'Idle' end
);

local function partyMemberHpLt(n)
    return function()
        local partyMgr = AshitaCore:GetMemoryManager():GetParty()
        local entityMgr = AshitaCore:GetMemoryManager():GetEntity()
        for i = 0, 5 do
            if (partyMgr:GetMemberIsActive(n) == 1
                    and partyMgr:GetMemberHP(i) < n
                    and entityMgr:GetDistance(partyMgr:GetMemberIndex(i)) < 625) then
                return true
            end
        end
    end
end

local direSituation = p_or(
    partyMemberHpLt(1000),
    predicates.hpp_lt(50),
    predicates.buff_active('Paralysis')
);

local useSIRD = p_or(enemyCount(3), direSituation);



sets.Phalanx_Received = T {
    Main = 'Sakpata\'s Sword',
    Sub = 'Priwen',
    Hands = gear.Souveran_Hands_PathC, -- Path D
    Legs = 'Sakpata\'s Cuisses',
    Feet = gear.Souveran_Feet_PathD,
    -- Back = 'Weard Mantle',

    swapManagedWeapons = p_and(outOfCombat, settings.Main:equals('Auto'))
}

sets.Idle = {
    Main = 'Burtgang',
    -- Sub = 'Duban',
    Ammo = 'Staunch Tathlum +1',
    Head = { Name = jse.empy.Head, Priority = 15 },
    Body = 'Sakpata\'s Plate',
    Hands = table.merge(gear.Souveran_Hands_PathC, { Priority = 14 }),
    Legs = { Name = jse.empy.Legs, Priority = 14 },
    Feet = jse.af.Feet,
    Neck = { Name = 'Unmoving Collar +1', Priority = 15 },
    Waist = 'Creed Baudrier',
    Ear1 = { Name = 'Tuisto Earring', Priority = 15 },
    Ear2 = { Name = 'Odnowa Earring +1', Priority = 15 },
    Ring1 = { Name = 'Gelatinous Ring +1', Priority = 15 },
    Ring2 = { Name = 'Defending Ring', Priority = 0 },
    Back = gear.Rudianos_Tank,
    swaps = {
        {
            test = settings.CombatMode:equals('Balanced'),
            Hands = 'Sakpata\'s Gauntlets'
        },
        {
            -- Idle Refresh gear
            test = p_and(outOfCombatIdle,
                predicates.mpp_lt(60)),
            Head = 'Displaced',
            Body = 'Respite Cloak',
        },
        {
            -- Idle Refresh gear
            test = p_and(outOfCombatIdle,
                predicates.mpp_lt(80)),
            Neck = 'Vim Torque +1',
            Waist = 'Fucho-no-Obi',
        },
        {
            -- Idle Refresh gear
            test = p_and(outOfCombatIdle,
                predicates.mpp_lt(90)),
            Hands = 'Regal Gauntlets',
        },
        {
            -- Pro/shell gear
            test = p_and(outOfCombatIdle,
                p_not(predicates.buff_active(40))), -- Protect
            Ring2 = 'Sheltered Ring'
        },
        T {
            -- Phalanx gear
            test = p_and(outOfCombatIdle,
                p_not(predicates.buff_active(116))), -- Phalanx
        }:merge(sets.Phalanx_Received),
        {
            -- Cover is active
            test = predicates.buff_active(114), -- Cover
            Head = jse.af.Head,
            Body = jse.relic.Body
        }
    }
};

sets.Engaged = {
    Ammo = 'Staunch Tathlum +1',
    Head = { Name = jse.empy.Head, Priority = 15 },
    Body = 'Sakpata\'s Plate',
    Hands = table.merge(gear.Souveran_Hands_PathC, { Priority = 14 }),
    Legs = { Name = jse.empy.Legs, Priority = 14 },
    Feet = jse.af.Feet,
    Neck = { Name = 'Unmoving Collar +1', Priority = 15 },
    Waist = 'Creed Baudrier',
    Ear1 = { Name = 'Tuisto Earring', Priority = 15 },
    Ear2 = { Name = 'Odnowa Earring +1', Priority = 15 },
    Ring1 = { Name = 'Gelatinous Ring +1', Priority = 15 },
    Ring2 = { Name = 'Defending Ring', Priority = 0 },
    Back = gear.Rudianos_Tank,
    swaps = {
        {
            test = function() return gData.GetBuffCount('Cover') > 0 end,
            Head = jse.af.Head,
        },
        {
            test = settings.CombatMode:equals('DD'),
            Ammo = 'Aurgelmir Orb +1',
            Head = 'Flam. Zucchetto +2',
            Body = 'Dagon Breast.',
            Hands = 'Sakpata\'s Gauntlets',
            Legs = 'Sulev. Cuisses +2',
            Feet = 'Flam. Gambieras +2',
            Neck = 'Lissome Necklace',
            Waist = 'Sailfi Belt +1',
            Ear1 = 'Dedition Earring',
            Ear2 = 'Cessance Earring',
            Ring1 = 'Moonlight Ring',
            Ring2 = 'Moonlight Ring',
        }
    }
};


sets.Resting = sets.Idle;

sets.Precast = {
    Main = 'Sakpata\'s Sword',
    Ammo = 'Sapience Orb',
    Head = gear.Carmine_Head_PathD,               -- 14
    Body = { Name = jse.af.Body, Priority = 15 }, -- 5
    Hands = 'Leyline Gloves',                     -- 8
    -- Legs = 'Enif Cosciales',
    Legs = jse.relic.Legs,
    Feet = jse.empy.Feet,     -- 8
    Ear1 = 'Tuisto Earring',
    Ear2 = 'Loquac. Earring', -- 2
    Ring1 = 'Moonlight Ring',
    Ring2 = 'Kishar Ring',    -- 4
    -- Ring2 = 'Prolix Ring',                        -- 2
    Neck = 'Baetyl Pendant',  -- 4
    Waist = 'Plat. Mog. Belt',
    Back = gear.Rudianos_FC_Midcast
}

sets.Precast_Cure = setCombine(sets.Precast, {
    swaps = {
        {
            test = function()
                if settings.CombatMode.value == 'Kite' then
                    for i = 1,16,1 do
                        gEquip.UnequipSlot(i);
                    end
                end
            end
        }
    }
})

sets.Midcast = {
    Back = gear.Rudianos_FC_Midcast,
    Ring1 = 'Gelatinous Ring +1',
    Ring2 = 'Moonlight Ring',
    Legs = 'Sakpata\'s Cuisses'
};

sets.Midcast_EnhancingMagic = setCombine(sets.Midcast, {
    Sub = 'Ajax +1',
    Hands = 'Regal Gauntlets',
    Body = 'Shab. Cuirass +1',
    Ring1 = 'Moonlight Ring',
    Ring2 = 'Moonlight Ring',
});

sets.Midcast_Stoneskin = setCombine(sets.Midcast_EnhancingMagic, {
    Waist = 'Siegel Sash'
});

sets.Midcast_Aquaveil = setCombine(sets.Midcast_EnhancingMagic, {
    Main = 'Nibiru Faussar',
    Sub = 'Displaced',
    swapManagedWeapons = p_and(
        outOfCombat,
        p_not(predicates.buff_active('Aftermath: Lv.3')),
        predicates.tp_lt(1000)
    )
});

sets.Midcast_Reprisal = {
    Sub = 'Ajax +1',
    Ammo = 'Sapience Orb',
    Head = 'Loess Barbuta +1',
    Body = 'Shab. Cuirass +1',
    Hands = 'Regal Gauntlets',
    Legs = gear.Souveran_Legs_PathC,
    Feet = jse.empy.Feet,
    Ear1 = 'Cryptic Earring',
    Ear2 = 'Odnowa Earring +1',
    Ring1 = 'Gelatinous Ring +1',
    Ring2 = 'Eihwaz Ring',
    Neck = 'Moonlight Necklace',
    Waist = 'Creed Baudrier',
    Back = gear.Rudianos_FC_Midcast,
    swaps = {
        {
            test = useSIRD,
            Head = gear.Souveran_Head_PathC,
            -- Feet = gear.Odyssean_Feet_FC
            Feet = 'Odyssean Greaves',
            Waist = 'Audumbla Sash',
            Ring2 = 'Defending Ring',
            Legs = 'Founder\'s Hose'
        }
    }
};

sets.Midcast_Phalanx = setCombine(sets.Phalanx_Received, {
    Ear1 = 'Mimir Earring',
    Ear2 = 'Odnowa Earring +1',
    Ring1 = 'Moonlight Ring',
    Ring2 = 'Moonlight Ring',

    swaps = {
        {
            test = useSIRD,
            Ammo = 'Staunch Tathlum +1',
            Legs = 'Founder\'s Hose',
            -- Feet = gear.Odyssean_Feet_Phalanx
        }
    }
})

sets.Weaponskill = {
    Ammo = 'Aurgelmir Orb +1',
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

sets.Weaponskill_SavageBlade = {
    Ammo = 'Aurgelmir Orb +1',
    Head = 'Sakpata\'s Helm',
    Body = 'Sakpata\'s Plate',
    Hands = 'Sakpata\'s Gauntlets',
    Legs = 'Sakpata\'s Cuisses',
    Feet = 'Sulev. Leggings +2',
    Neck = 'Kgt. Beads +2',
    Waist = 'Sailfi Belt +1',
    Ear1 = 'Thrud Earring',
    Ear2 = 'Moonshade Earring',
    Ring1 = 'Epaminondas\'s Ring',
    Ring2 = 'Ephramad\'s Ring',
    Back = gear.Rudianos_STR_WSD
}

sets.Weaponskill_Atonement = {
    Ammo = 'Sapience Orb',
    Head = 'Loess Barbuta +1',
    Body = gear.Souveran_Body_PathC,
    Hands = gear.Souveran_Hands_PathC,
    Legs = gear.Souveran_Legs_PathC,
    Feet = gear.Eschite_Feet_PathA,
    Ear1 = 'Moonshade Earring',
    Ear2 = 'Cryptic Earring',
    Ring1 = 'Eihwaz Ring',
    Ring2 = 'Petrov Ring',
    Neck = 'Moonlight Necklace',
    Waist = 'Fotia Belt',
    Back = gear.Rudianos_Tank,
}

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
    Ring1 = 'Eihwaz Ring',
    Ring2 = 'Petrov Ring',
    Back = gear.Rudianos_Tank,
};

sets.SIRD = setCombine(sets.Enmity, {
    Head = gear.Souveran_Head_PathD,
    Ammo = 'Staunch Tathlum +1',
    Waist = 'Audumbla Sash',
    Neck = 'Moonlight Necklace',
    Ear2 = 'Nourish. Earring +1',
    Legs = 'Founder\'s Hose'
});


sets.Midcast = sets.Enmity;

sets.Midcast_Flash = {
    Main = 'Burtgang',
    Sub = 'Srivatsa',
    Ammo = 'Sapience Orb',
    Head = gear.Carmine_Head_PathD,
    Body = jse.af.Body,
    Hands = gear.Souveran_Hands_PathC,
    Legs = gear.Souveran_Legs_PathC,
    Feet = jse.empy.Feet,
    Neck = 'Moonlight Necklace',
    Waist = 'Creed Baudrier',
    Ear1 = 'Tuisto Earring',
    Ear2 = 'Cryptic Earring',
    Ring1 = 'Eihwaz Ring',
    Ring2 = 'Petrov Ring',
    Back = gear.Rudianos_Tank,
    swaps = {
        {
            test = useSIRD,
            Head = gear.Souveran_Head_PathC,
            Ammo = 'Staunch Tathlum +1',
            Waist = 'Audumbla Sash',
            Ear2 = 'Nourish. Earring +1',
            Legs = 'Founder\'s Hose',
            Feet = 'Odyssean Greaves',
            -- SIRD gear
        }
    }
    
};

sets.Midcast_Cure = {
    Ammo = 'Egoist\'s Tathlum',
    Head = { Name = 'Loess Barbuta +1', Priority = 0 },
    Body = gear.Souveran_Body_PathC,
    Hands = 'Macabre Gaunt. +1',
    Legs = table.merge(gear.Souveran_Legs_PathC, { Priority = 15 }),
    Feet = jse.empy.Feet,
    Neck = 'Sacro Gorget',
    Waist = 'Creed Baudrier',
    Ear1 = 'Tuisto Earring',
    Ear2 = 'Cryptic Earring',
    Ring1 = { Name = 'Gelatinous Ring +1', Priority = 15 },
    Ring2 = 'Eihwaz Ring',
    Back = gear.Rudianos_Cure,
    swaps = {
        {
            test = useSIRD,
            Head = gear.Souveran_Head_PathC,
            Ammo = 'Staunch Tathlum +1',
            Waist = 'Audumbla Sash',
            Neck = 'Moonlight Necklace',
            Ear2 = 'Nourish. Earring +1',
            Legs = 'Founder\'s Hose',
            Feet = 'Odyssean Greaves'
            -- SIRD gear
        }
    }
};

sets.Midcast_Jettatura = sets.Midcast_Flash;
sets.Midcast_SheepSong = sets.Midcast_Flash;
sets.Midcast_GeistWall = sets.Midcast_Flash;
sets.Midcast_Banishga = sets.Midcast_Flash;

sets.Midcast_Cocoon = setCombine(sets.SIRD, {
    Hands = 'Regal Gauntlets',
    -- Legs = jse.relic.Legs
});

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
    Hands = jse.relic.Hands,
    Ring1 = 'Apeile Ring +1',
    Ring2 = 'Apeile Ring',
});

sets.JA_Chivalry = setCombine(sets.Enmity, {
    Hands = jse.relic.Hands
})

sets.JA_Invincible = setCombine(sets.Enmity, {
    Ring1 = 'Apeile Ring +1',
    Ring2 = 'Apeile Ring',
    Legs = jse.relic.Legs
});


profile.Sets = sets;

profile.Packer = {
};

validateSet(sets);

return profile;
