local GUI = require('J-GUI');
local functions = require('J-GUI/functions');
local VStack = require('J-GUI.VStack');
GUI.ctx.forceReload(); -- Required since user scripts are loaded AFTER addon has already loaded.

functions.addResourcePath(AshitaCore:GetInstallPath() .. 'config\\addons\\luashitacast\\assets\\');

local settings = {
    fastcast = 0.3,
    minimumBuffer = 0.1,
    packetDelay = 0.25,
};

local gear = require('Jyouyaya-gear');

local M = require('J-Mode');
local setCombine = require('common.setCombine');
local predicates = require('common.J-Predicates')(settings);

local onSubJobChange = require('events.jobChange').onSubJobChange;
local onAction = require('events.action');

local profile, sets = gFunc.LoadFile('common/J-Cast.lua')(settings);
local haste = require('common.J-Haste');

do
    settings.Main = M {
        description = 'Main Hand',
        gear.Rostam_A,
        gear.Rostam_B,
        'Naegling',
        'Tauret',
        'Fettering Blade',
    };

    settings.Main.on_change:register(function(m)
        if tostring(m.value) == tostring(settings.Sub.value) then
            settings.Sub:cycle();
        end
    end);

    settings.Sub = M {
        description = 'Off Hand',
        'Nusku Shield'
    };
    settings.Sub.on_change:register(function(m)
        if tostring(m.value) == tostring(settings.Main.value) then
            settings.Sub:cycle();
        end
    end);

    local function subOptions()
        local subJob = gData.GetPlayer().SubJob

        if subJob == 'NIN' or subJob == 'DNC' then
            settings.Sub:options(
                'Tauret',
                'Blurred Knife +1',
                'Nusku Shield',
                gear.Rostam_A,
                gear.Rostam_B,
                'Fettering Blade'
            );
        else
            settings.Sub:options('Nusku Shield');
        end
    end
    subOptions();
    onSubJobChange:register(subOptions);

    settings.Range = M {
        description = 'Ranged Weapon',
        'Death Penalty',
        'Armageddon',
        'Fomalhaut',
        'Anarchy +2'
    };

    settings.Quickdraw = M {
        description = 'Quick Draw Mode',
        'Damage',
        'STP',
        'Accuracy'
    };

    settings.Accuracy = M {
        description = 'Accuracy Mode',
        'Normal',
        'Mid',
        'High'
    };

    settings.RangedAttackMode = M {
        description = 'Ranged Attack Mode',
        'STP',
        'Damage'
    };

    settings.RangedAccuracy = M {
        description = 'Ranged Accuracy Mode',
        'Normal',
        'Mid',
        'High',
    };

    settings.DualWieldMode = M {
        description = 'Dual Wield Mode',
        'Auto',
        'Manual'
    };

    settings.DualWieldLevel = M {
        description = 'Dual Wield Level',
        '0',  -- /nin haste samba
        '9',  -- /dnc haste samba
        '11', -- /nin capped ma haste
        '21', -- /dnc capped ma haste
        '31', -- /nin mid ma haste
        '41', -- /dnc mid ma haste
        '42', -- /nin low ma haste
        '49', -- /nin no ma haste
        '52', -- /dnc low ma haste
        '59'  -- /dnc no ma haste
    };

    settings.RollGear = M(true, 'Swap Weapons to Roll');

    local itemIdMemo = setmetatable({}, {
        __index = function(t, k)
            t[k] = AshitaCore:GetResourceManager():GetItemByName(k, 2);
            return t[k];
        end
    });

    local function dwTest()
        local sub = settings.Sub.value
        if (type(sub) == 'table') then
            sub = sub.Name;
        end
        local res = itemIdMemo[sub];
        local player = gData.GetPlayer();

        local subJob = player.SubJob;
        return ((subJob == 'NIN' or subJob == 'DNC') and res.Slots == 3);
    end

    local function dwKey()
        if (settings.DualWieldMode.value == 'Auto') then
            local dwNeeded = haste.dwNeeded;
            local dwLevel = math.max(unpack(settings.DualWieldLevel));

            for _, dw in ipairs(settings.DualWieldLevel) do
                local dwNumber = tonumber(dw);
                if (dwNumber < dwLevel and dwNumber >= dwNeeded) then
                    dwLevel = dwNumber;
                end
            end
            settings.DualWieldLevel:set(tostring(dwLevel));
        end
        return 'DW' .. tostring(settings.DualWieldLevel.value);
    end

    settings.Rules = T {
        Engaged = T {},
        Idle = T {},
        Midshot = T {},
    }

    settings.Rules.Engaged:append({
        test = dwTest,
        key = dwKey
    });

    settings.Rules.Idle:append({
        test = dwTest,
        key = dwKey
    });

    settings.Rules.Engaged:append({
        test = function() return true; end,
        key = function(_, breadcrumbs)
            for i = settings.Accuracy.index, 1, -1 do
                if sets:hasSet(breadcrumbs, settings.Accuracy[i]) then
                    return settings.Accuracy[i];
                end
            end
        end
    });

    settings.Rules.Midshot:append({
        test = function() return true; end,
        key = function() return settings.RangedAttackMode.value; end
    });


    settings.Quickdraw1 = M {
        ['description'] = 'Primary Quickdraw Element',
        'Fire',
        'Earth',
        'Water',
        'Wind',
        'Ice',
        'Thunder',
        'Light',
        'Dark'
    };

    settings.Quickdraw2 = M {
        ['description'] = 'Secondary Quickdraw Element',
        'Fire',
        'Earth',
        'Water',
        'Wind',
        'Ice',
        'Thunder',
        'Light',
        'Dark'
    };

    settings.Quickdraw2:set('Dark');

    settings.TreasureHunter = M(true, 'Treasure Hunter')
end

sets.Idle = {
    Ammo = 'remove',
    Head = 'Malignance Chapeau',
    Body = 'Malignance Tabard',
    Hands = 'Malignance Gloves',
    Legs = 'Malignance Tights',
    Feet = 'Malignance Boots',
    Neck = 'Loricate Torque +1',
    Ear1 = 'Odnowa Earring +1',
    Ear2 = 'Etiolation Earring',
    Ring1 = 'Defending Ring',
    Ring2 = 'Gelatinous Ring +1',
    Back = gear.Camulus_Snapshot,
    Waist = 'Flume Belt'
};

sets.JA = {};

sets.JA_SnakeEye = { Legs = 'Lanun Trews' };
sets.JA_WildCard = { Feet = 'Lanun Bottes +3' };
sets.JA_RandomDeal = { Body = 'Lanun Frac +3' };
sets.JA_Fold = {
    swaps = {
        {
            test = function() return gData.GetBuffCount('Bust') == 2 end,
            Hands = 'Lanun Gants +3'
        }
    }
};

sets.JA_CorsairRoll = {
    main = gear.Rostam_C,
    range = 'Compensator',
    Head = 'Lanun Tricorne +3',
    Body = 'Malignance Tabard',
    Hands = 'Chasseur\'s Gants +1',
    Legs = 'Desultor Tassets',
    Feet = 'Malignance Boots',
    Neck = 'Regal Necklace',
    Ear1 = 'Genmei Earring',
    Ear2 = 'Etiolation Earring',
    Ring1 = 'Luzaf\'s Ring',
    Ring2 = 'Gelatinous Ring +1',
    Back = gear.Camulus_Snapshot,
    Waist = 'Flume Belt',
    swapManagedWeapons = function()
        local am3 = settings.Main.value == 'Armageddon'
            and gData.GetBuffCount('Aftermath: Lv.3') > 0;
        return not am3 and settings.RollGear.value;
    end
};

sets.JA_DoubleUp = { Ring1 = 'Lufaz\'s Ring' };
sets.JA_CastersRoll = setCombine(sets.JA_CorsairRoll, {
    Legs = 'Chas. Culottes +1',
});
sets.JA_CoursersRoll = setCombine(sets.JA_CorsairRoll, {
    Feet = 'Chasseur\'s Bottes +1',
});
sets.JA_BlitzersRoll = setCombine(sets.JA_CoursersRoll, {
    Head = 'Chasseur\'s Tricorne +1',
});
sets.JA_TacticiansRoll = setCombine(sets.JA_CorsairRoll, {
    Body = 'Chasseur\'s Frac +1',
});
sets.JA_AlliesRoll = setCombine(sets.JA_CorsairRoll, {
    Hands = 'Chasseur\'s Gants +1',
});

sets.JA_CorsairShot_Damage = {
    Head = gear.Herc_Head_Wildfire,
    Body = 'Lanun Frac +3',
    Hands = 'Carmine Fin. Ga. +1',
    Legs = gear.Herc_Legs_Leaden,
    Feet = 'Lanun Bottes +3',
    Neck = 'Baetyl Pendant',
    Ear1 = 'Moonshade Earring',
    Ear2 = 'Friomisi Earring',
    Ring1 = 'Dingir Ring',
    Ring2 = 'Ilabrat Ring',
    Back = gear.Camulus_QuickdrawDamage,
    Waist = 'Eschan Stone',
    swaps = {
        { test = predicates.orpheus,  Waist = 'Orpheus\'s Sash' },
        { test = predicates.hachirin, Waist = 'Hachirin-no-Obi' }
    }
};

sets.JA_CorsairShot_STP = {
    Ammo = 'Living Bullet',
    Head = 'Malignance Chapeau',
    Body = 'Malignance Tabard',
    Hands = 'Malignance Gloves',
    Legs = 'Malignance Tights',
    Feet = 'Malignance Boots',
    Neck = 'Iskur Gorget',
    Ear1 = 'Enervating Earring',
    Ear2 = 'Telos Earring',
    Ring1 = 'Chirich Ring +1',
    Ring2 = 'Ilabrat Ring',
    Waist = 'Kentarch Belt +1',
    Back = gear.Camulus_rSTP
};

sets.JA_CorsairShot_Accuracy = {
    Ammo = 'Devastating Bullet',
    Head = 'Malignance Chapeau',
    Body = 'Malignance Tabard',
    Hands = 'Malignance Gloves',
    Legs = 'Malignance Tights',
    Feet = 'Malignance Boots',
    Ear1 = 'Gwati Earring',
    Ear2 = 'Digni. Earring',
    Ring1 = 'Rahab Ring',
    Ring2 = 'Regal Ring',
    Waist = 'K. Kachina Belt +1',
    Neck = 'Comm. Charm +2',
    Back = gear.Camulus_QuickdrawDamage
};

sets.JA_LightShot = sets.JA_CorsairShot_Accuracy;
sets.JA_DarkShot = sets.JA_CorsairShot_Accuracy;

sets.Precast = {
    Head = gear.Carmine_Head_PathD,
    Body = 'Malignance Tabard',
    Hands = 'Leyline Gloves',
    Legs = 'Malignance Tights',
    Feet = gear.Carmine_Feet_PathD,
    Neck = 'Baetyl Pendant',
    Ear1 = 'Loquac. Earring',
    Ear2 = 'Odnowa Earring +1',
    Ring1 = 'Rahab Ring',
    Ring2 = 'Kishar Ring',
    Back = gear.Camulus_Fastcast
};

sets.Precast_Utsusemi = setCombine(sets.Precast, {
    Neck = 'Magoraga Beads',
    Body = 'Passion Jacket'
});

do
    local playerId = AshitaCore:GetMemoryManager():GetParty():GetMemberServerId(0);
    local flurryLevel
    onAction:register(function(data_raw, unpackAction)
        local category = ashita.bits.unpack_be(data_raw, 0, 82, 4);
        if (category ~= 4) then return; end

        local targetId = ashita.bits.unpack_be(data_raw, 0, 150, 32);
        if (targetId ~= playerId) then return; end

        local param = ashita.bits.unpack_be(data_raw, 0, 86, 16);
        if (flurryLevel ~= 2 and param == 845) then
            flurryLevel = 1;
        elseif param == 846 then
            flurryLevel = 2;
        end
    end);

    sets.Preshot = {
        Head = 'Taeon Chapeau',
        Neck = 'Commodore Charm +2',
        Body = 'Laksa. Frac +3',
        Hands = 'Carmine Fin. Ga. +1',
        Legs = 'Laksa. Trews +3', -- 15
        Feet = 'Meg. Jam. +2',
        Back = gear.Camulus_Snapshot,
        Waist = 'Impulse Belt',
        swaps = {
            {
                test = predicates.buff_active(581),
                Legs = gear.Adhemar_Legs_PathD,
                Waist = 'Yemaya Belt'
            },
            {
                test = function()
                    return predicates.p_and(
                        predicates.buff_active(581),
                        function() return flurryLevel == 2 end
                    )
                end,
                Head = 'Chass. Tricorne +1',
                Feet = 'Pursuer\'s Gaiters'
            }
        }
    };

    sets.Weaponskill = {};
    sets.Weaponskill_LastStand = {
        Ammo = 'Chrono Bullet',
        Head = 'Lanun Tricorne +3',
        Body = 'Laksa. Frac +3',
        Hands = 'Meg. Gloves +2',
        Legs = 'Meg. Chausses +2',
        Feet = 'Lanun Bottes +3',
        Neck = 'Fotia Gorget',
        Waist = 'Fotia Belt',
        Ear1 = 'Moonshade Earring',
        Ear2 = 'Ishvara Earring',
        Ring1 = 'Dingir Ring',
        Ring2 = 'Regal Ring',
        Back = gear.Camulus_LastStand,
        swaps = {
            {
                test = predicates.etp_gt(2850),
                Ear1 = 'Telos Earring'
            },
            {
                test = function() return settings.Accuracy.index >= 2; end,
                Neck = 'Iskur Gorget',
            },
            {
                test = function() return settings.Accuracy.index >= 3; end,
                Ring2 = 'Hajduk Ring +1',
                Waist = 'K. Kachina Belt',
            }
        }
    };

    sets.Weaponskill_LeadenSalute = {
        Ammo = 'Living Bullet',
        Head = 'Pixie Hairpin +1',
        Body = 'Lanun Frac +3',
        Hands = gear.Herc_Hands_Leaden,
        Legs = gear.Herc_Legs_Leaden,
        Feet = 'Lanun Bottes +3',
        Neck = 'Comm. Charm +2',
        Ear1 = 'Moonshade Earring',
        Ear2 = 'Friomisi Earring',
        Ring1 = 'Dingir Ring',
        Ring2 = 'Archon Ring',
        Waist = 'Eschan Stone',
        Back = gear.Camulus_LeadenSalute,
        swaps = {
            { test = predicates.orpheus,      Waist = 'Orpheus\'s Sash' },
            { test = predicates.hachirin,     Waist = 'Hachirin-no-Obi' },
            { test = predicates.etp_gt(2800), Ear1 = 'Hecate\'s Earring' }
        }
    };

    sets.Weaponskill_Wildfire = {
        Ammo = 'Living Bullet',
        Head = gear.Herc_Head_Wildfire,
        Body = 'Lanun Frac +3',
        Hands = gear.Herc_Hands_Leaden,
        Legs = gear.Herc_Legs_Leaden,
        Feet = 'Lanun Bottes +3',
        Neck = 'Comm. Charm +2',
        Ear1 = 'Hecate\'s Earring',
        Ear2 = 'Friomisi Earring',
        Ring1 = 'Dingir Ring',
        Ring2 = 'Regal Ring',
        Waist = 'Eschan Stone',
        Back = gear.Camulus_LeadenSalute,
        swaps = {
            { test = predicates.orpheus,  Waist = 'Orpheus\'s Sash' },
            { test = predicates.hachirin, Waist = 'Hachirin-no-Obi' }
        }
    };

    sets.Weaponskill_HotShot = {
        Ammo = 'Living bullet',
        Head = gear.Herc_Head_Wildfire,
        Body = 'Lanun Frac +3',
        Hands = gear.Herc_Hands_Leaden,
        Legs = gear.Herc_Legs_Leaden,
        Feet = 'Lanun Bottes +3',
        Neck = 'Comm. Charm +2',
        Ear1 = 'Moonshade Earring',
        Ear2 = 'Friomisi Earring',
        Ring1 = 'Dingir Ring',
        Ring2 = 'Ilabrat Ring',
        Waist = 'Fotia Belt',
        Back = gear.Camulus_LeadenSalute,
        swaps = {
            { test = predicates.orpheus,  Waist = 'Orpheus\'s Sash' },
            { test = predicates.hachirin, Waist = 'Hachirin-no-Obi' }
        }
    };

    sets.Weaponskill_Evisceration = {
        Head = 'Adhemar Bonnet +1',
        Body = 'Abnoba Kaftan',
        Hands = 'Mummu Wrists +2',
        Legs = 'Samnuha Tights',
        Feet = 'Mummu Gamash. +2',
        Neck = 'Fotia Gorget',
        Waist = 'Fotia Belt',
        Ear1 = 'Moonshade Earring',
        Ear2 = 'Odr Earring',
        Ring1 = 'Mummu Ring',
        Ring2 = 'Regal Ring',
        Back = gear.Camulus_DA,
        {
            test = function() return settings.Accuracy.index >= 2; end,
            Head = 'Mummu Bonnet +2',
            Body = 'Mummu Jacket +2'
        },
    };

    sets.Weaponskill_SavageBlade = {
        Head = gear.Herc_Head_Savage,
        Body = 'Laksa. Frac +3',
        Hands = 'Meg. Gloves +2',
        Legs = gear.Herc_Legs_Savage,
        Feet = 'Lanun Bottes +3',
        Neck = 'Comm. Charm +2',
        Waist = 'Sailfi Belt +1',
        Ear1 = 'Moonshade Earring',
        Ear2 = 'Ishvara Earring',
        Ring1 = 'Regal Ring',
        Ring2 = 'Rufescent Ring',
        Back = gear.Camulus_Savage,
        swaps = { { test = predicates.etp_gt(2800), Ear1 = 'Telos Earring' } }
    };

    sets.Weaponskill_Requiescat = {
        Head = 'Adhemar Bonnet +1',
        Body = 'Adhemar Jacket +1',
        Hands = 'Meg. Gloves +2',
        Legs = 'Meg. Chausses +2',
        Feet = gear.Herc_Feet_TA,
        Neck = 'Fotia Gorget',
        Waist = 'Fotia Belt',
        Ear1 = 'Moonshade Earring',
        Ear2 = 'Telos Earring',
        Ring1 = 'Regal Ring',
        Ring2 = 'Rufescent Ring',
        Back = gear.Camulus_DA
    };

    sets.Weaponskill_AeolianEdge = {
        Ammo = 'Living Bullet',
        Head = gear.Herc_Head_Wildfire,
        Body = 'Lanun Frac +3',
        Hands = gear.Herc_Hands_Leaden,
        Legs = gear.Herc_Legs_Leaden,
        Feet = 'Lanun Bottes +3',
        Neck = 'Comm. Charm +2',
        Waist = 'Orpheus\'s Sash',
        Ear1 = 'Moonshade Earring',
        Ear2 = 'Friomisi Earring',
        Ring1 = 'Dingir Ring',
        Ring2 = 'Ilabrat Ring', -- Empanada Ring
        Back = gear.Camulus_AeolianEdge
    };

    sets.Midshot = {};

    sets.Midshot_Damage = {
        Ammo = 'Chrono Bullet',
        Head = 'Malignance Chapeau',
        Body = 'Malignance Tabard',
        Hands = 'Malignance Gloves',
        Legs = 'Malignance Tights',
        Feet = 'Malignance Boots',
        Neck = 'Iskur Gorget',
        Ear1 = 'Enervating Earring',
        Ear2 = 'Telos Earring',
        Ring1 = 'Dingir Ring',
        Ring2 = 'Ilabrat Ring',
        Waist = 'Yemaya Belt',
        Back = gear.Camulus_rSTP,
        swaps = {
            {
                test = predicates.buff_active('Triple Shot'),
                Head = 'Oshosi Mask +1',
                Body = 'Chasseur\'s Frac +1',
                Hands = 'Lanun Gants +3',
                Legs = 'Osh. Trousers +1',
                Feet = 'Osh. Leggings +1'
            },
            {
                test = function() return settings.RangedAccuracy.index > 1 end,
                Ring1 = 'Hajduk Ring +1',
                Waist = 'K. Kachina Belt +1',
            },
            {
                test = function() return settings.RangedAccuracy.index > 2 end,
                Ring2 = 'Regal Ring',
            }
        }
    };

    sets.Midshot_STP = {
        Ammo = 'Devastating Bullet',
        Head = 'Malignance Chapeau',
        Body = 'Malignance Tabard',
        Hands = 'Malignance Gloves',
        Legs = 'Malignance Tights',
        Feet = 'Malignance Boots',
        Neck = 'Iskur Gorget',
        Ear1 = 'Dedition Earring',
        Ear2 = 'Telos Earring',
        Ring1 = 'Chirich Ring +1',
        Ring2 = 'Ilabrat Ring',
        Waist = 'Yemaya Belt',
        Back = gear.Camulus_rSTP,
        swaps = {
            {
                test = predicates.buff_active('Triple Shot'),
                Head = 'Oshosi Mask +1',
                Body = 'Chasseur\'s Frac +1',
                Hands = 'Lanun Gants +3',
                Legs = 'Osh. Trousers +1',
                Feet = 'Osh. Leggings +1'
            }
        }
    };

    sets.Midshot_Armageddon_Damage = sets.Midshot_Damage;
    sets.Midshot_Armageddon_STP = sets.Midshot_STP;

    sets.Midshot_Armageddon_AM3 = {
        Ammo = 'Chrono Bullet',
        Head = 'Meghanada Visor +2',
        Body = 'Meghanada Cuirie +2',
        Hands = 'Mummu Wrists +2',
        Legs = 'Darraigner\'s Brais',
        Feet = 'Oshosi Leggings +1',
        Neck = 'Iskur Gorget',
        Waist = 'K. Kachina Belt +1', -- Gerdr Belt +1
        Ear1 = 'Odr Earring',
        Ear2 = 'Telos Earring',
        Ring1 = 'Mummu Ring',
        Ring2 = 'Begrudging Ring',
        Back = gear.Camulus_AM3,
        swaps = {
            { -- True shot
                test = predicates.p_and(
                    predicates.distance_gte(5.5),
                    predicates.distance_lte(7.5)
                ),
                Body = 'Nisroch Jerkin',
                Legs = 'Osh. Trousers + 1'
            },
            {
                test = predicates.buff_active('Triple Shot'),
                Head = 'Oshosi Mask +1',
                Body = 'Chasseur\'s Frac +1',
                Hands = 'Lanun Gants +3',
                Legs = 'Osh. Trousers +1',
                Feet = 'Osh. Leggings +1'
            }
        }
    };

    sets.Engaged = {
        Head = 'Malignance Chapeau',
        Body = 'Malignance Tabard',
        Hands = 'Malignance Gloves',
        Legs = 'Samnuha Tights',
        Feet = 'Malignance Boots',
        Neck = 'Iskur Gorget',
        Ear1 = 'Cessance Earring',
        Ear2 = 'Telos Earring',
        Ring1 = 'Chirich Ring +1',
        Ring2 = 'Epona\'s Ring',
        Back = gear.Camulus_DA,
        Waist = 'Windbuffet Belt +1',
        swaps = {
            {
                test = function()
                    return settings.Accuracy.index > 1
                end,
                Waist = 'Kentarch Belt +1',
                Neck = 'Combatant\'s Torque'
            }, {
            test = function()
                return settings.Accuracy.index > 2
            end,
            Legs = 'Malignance Tights'
        }
        }
    };

    sets.Engaged_DW9 = setCombine(sets.Engaged, {
        -- Waist =  'Gerdr Belt +1',
        Ear1 = 'Suppanomimi',
        Ear2 = 'Eabani Earring', -- ! remove when we get Gerdr +1
        swaps = {
            {                    -- Accuracy swapping rule
                test = function()
                    return settings.Accuracy.index > 1
                end,
                Neck = "Combatant's Torque"
            }, {
            test = function()
                return settings.Accuracy.index > 2
            end,
            Legs = "Malignance Tights"
        }
        }
    });

    sets.Engaged_DW11 = setCombine(sets.Engaged, {
        Waist = 'Reiki Yotai',
        Ear1 = { name = 'Eabani Earring', priority = 15 }
    });

    sets.Engaged_DW21 = setCombine(sets.Engaged_DW11, { Back = gear.Camulus_DW });

    sets.Engaged_DW31 = setCombine(sets.Engaged_DW11, {
        Body = 'Adhemar Jacket +1',
        Feet = 'Taeon Boots',
        right_ear = 'Suppanomimi'
    });

    sets.Engaged_DW41 = setCombine(sets.Engaged_DW31, { Back = gear.Camulus_DW });

    sets.Engaged_DW42 = setCombine(sets.Engaged_DW31, {
        Hands = "Floral Gauntlets",
        Legs = "Carmine Cuisses +1",
        swaps = {
            { -- Accuracy swapping rule
                test = function()
                    return settings.Accuracy.index > 1
                end,
                Neck = "Combatant's Torque"
            }
        }
    });

    sets.Engaged_DW49 = setCombine(sets.Engaged_DW42, {
        -- This set would need a DW augged herc helm, and I'm not about to do that
    })

    sets.Engaged_DW52 = setCombine(sets.Engaged_DW42, { Back = gear.Camulus_DW })

    sets.Engaged_DW59 = setCombine(sets.Engaged_DW49, { Back = gear.Camulus_DW })

    sets.TreasureHunter = {
        Hands = "Volte Bracers",
        Legs = gear.Herc_Legs_TreasureHunter,
        Waist = "Chaac Belt"
    };
end

do
    local function getQuickdrawTexture(_, element)
        local item = AshitaCore:GetResourceManager():GetItemByName(element .. ' Card', 0);
        -- for k, v in pairs(item) do print('k: '..k..', v: '..v); end
        if (item) then
            return functions.loadItemTexture(item.Id);
        end

        return functions.loadAssetTexture(element .. ' Shot.png');
    end

    local function dropdownFactory(variable, label)
        local view = GUI.Container:new({
            layout = GUI.Container.LAYOUT.GRID,
            gridRows = GUI.Container.LAYOUT.AUTO,
            gridCols = 1,
            fillDirection = GUI.Container.LAYOUT.VERTICAL,
            gridGap = 2,
            padding = { x = 0, y = 0 },
            draggable = true,
        });

        local dropdown = GUI.Dropdown:new({
            color = T { 255, 55, 175 },
            animated = true,
            expandDirection = GUI.ENUM.DIRECTION.DOWN,
            _width = 130,
            isFixedWidth = true,
        });

        dropdown.variable = variable;

        view:addView(
            GUI.Label:new({ value = label or variable.description }),
            dropdown
        );

        return view;
    end

    local function itemSelectorFactory(variable, texture)
        return GUI.ItemSelector:new({
            color = T { 255, 55, 175 },
            animated = true,
            expandDirection = GUI.ENUM.DIRECTION.LEFT,
            variable = variable,
            lookupTexture = texture
        });
    end

    local function spacer()
        return GUI.View:new();
    end

    local UI = GUI.Container:new({
        layout = GUI.Container.LAYOUT.GRID,
        gridRows = GUI.Container.LAYOUT.AUTO,
        gridCols = 1,
        fillDirection = GUI.Container.LAYOUT.VERTICAL,
        gridGap = 8,
        padding = { x = 0, y = 0 },
        draggable = true,
        _x = 1730,
        _y = 95
    });

    GUI.ctx.addView(UI);

    UI:addView(
        GUI.Container:new({
            layout = GUI.Container.LAYOUT.GRID,
            gridRows = GUI.Container.LAYOUT.AUTO,
            gridCols = 3,
            fillDirection = GUI.Container.LAYOUT.HORIZONTAL,
            gridGap = 8,
            padding = { x = 0, y = 0 },
            draggable = true,
        }):addView(
            itemSelectorFactory(settings.Main),
            spacer(),
            spacer(),
            itemSelectorFactory(settings.Sub),
            spacer(),
            spacer(),
            itemSelectorFactory(settings.Range),
            spacer(),
            spacer(),
            itemSelectorFactory(settings.Quickdraw1, getQuickdrawTexture),
            spacer(),
            spacer(),
            itemSelectorFactory(settings.Quickdraw2, getQuickdrawTexture),
            GUI.ToggleButton:new({
                variable = settings.RollGear,
                activeColor = T { 255, 55, 175 },
                inactiveColor = T { 255, 35, 55 },
                activeTextureFile = 'RollGearOn.png',
                inactiveTextureFile = 'RollGearOff.png',
            }),
            GUI.ToggleButton:new({
                variable = settings.TreasureHunter,
                activeColor = T { 255, 55, 175 },
                inactiveColor = T { 255, 35, 55 },
                activeTextureFile = 'TH On.png',
                inactiveTextureFile = 'TH Off.png'
            })
        ),
        -- Divider?
        dropdownFactory(settings.Accuracy),
        dropdownFactory(settings.RangedAccuracy),
        dropdownFactory(settings.RangedAttackMode),
        dropdownFactory(settings.DualWieldMode),
        dropdownFactory(settings.DualWieldLevel)
    )
end





return profile
