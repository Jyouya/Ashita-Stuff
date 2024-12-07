local GUI = require('J-GUI');
local functions = require('J-GUI/functions');
GUI.ctx.forceReload(); -- Required since user scripts are loaded AFTER addon has already loaded.

functions.addResourcePath(AshitaCore:GetInstallPath() .. 'config\\addons\\luashitacast\\assets\\');

local settings = {
    fastcast = 0.8,
    minimumBuffer = 0.1,
    packetDelay = 0.25,
};

local M = require('J-Mode');
local setCombine = require('common.setCombine');
local predicates = require('common.J-Predicates')(settings);



local profile, sets = gFunc.LoadFile('common/J-Cast.lua')(settings);

local gear = require('Jyouya-gear');

local maxHP = require('common.maxHP');

do -- Max HP Manual overrides for augmented gear
    maxHP.override('Rawhide Gloves', 75);
    maxHP.override('Gelatinous Ring +1', 135);
    maxHP.override(gear.Carmine_Legs_PathA, 130);
    maxHP.override(gear.Carmine_Feet_PathD, 95);
    maxHP.override(gear.Lustratio_Feet_PathD, 72);
end

local defaultMaxHP = 0;
local function willDropHP(_, set)
    return maxHP(set) < defaultMaxHP;
end

do -- Modes
    settings.Main = M { description = 'Main Hand', 'Epeolatry', 'Lionheart', 'Aettir' };
    settings.Sub = M { description = 'Off Hand', 'Utu Grip', 'Mensch Strap +1' };

    settings.Engaged = M { description = 'Accuracy Mode', 'Normal', 'Mid', 'High' };
    settings.Weaponskill = M { description = 'Weaponskill Mode', 'Damage', 'Balanced', 'Tank' };

    settings.Defense = M { description = 'Defense Mode', 'Turtle', 'Hybrid', 'DD' };
    settings.Turtle = M { description = 'Turtle Submode', 'Balanced', 'Max HP' };
    settings.Hybrid = M { description = 'Hybrid Submode', 'Inqartata' };
    settings.DD = M { description = 'DD Submode', 'Damage', 'DT' };

    settings.Rules = T {}
    settings.Rules.Engaged = T {}
    settings.Rules.Engaged:insert(T {
        test = function() return true; end,
        key = function() return settings.Defense.value end,
    });

    settings.Rules.Engaged:insert(T {
        test = function() return settings.Defense.value == 'Turtle' end,
        key = function() return settings.Turtle.value end
    });

    settings.Rules.Engaged:insert(T {
        test = function() return settings.Defense.value == 'Hybrid' end,
        key = function() return settings.Hybrid.value end
    });

    settings.Rules.Engaged:insert(T {
        test = function() return settings.Defense.value == 'DD' end,
        key = function() return settings.DD.value end
    });

    settings.Rules.Precast = T {}
    settings.Rules.Precast:insert(T {
        test = function()
            local base;
            if (gData.GetPlayer().Status == 'Engaged') then
                base = 'Engaged';
            else
                base = 'Idle';
            end
            local defaultSet = profile.getSet(base)
            defaultMaxHP = maxHP(defaultSet);
            return false;
        end
    });
end

do -- GUI
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
            color = T { 255, 0, 0 },
            animated = true,
            expandDirection = GUI.ENUM.DIRECTION.DOWN,
            _width = 120,
            isFixedWidth = true,
        });

        dropdown.variable = variable;

        view:addView(
            GUI.Label:new({ value = label or variable.description }),
            dropdown
        );

        return view;
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

    local buttons = GUI.Container:new({
        layout = GUI.Container.LAYOUT.GRID,
        gridRows = GUI.Container.LAYOUT.AUTO,
        gridCols = 2,
        fillDirection = GUI.Container.LAYOUT.VERTICAL,
        gridGap = 4,
        padding = { x = 0, y = 0 },
        draggable = true,
    });

    local lacUI = GUI.Container:new({
        layout = GUI.Container.LAYOUT.GRID,
        gridRows = GUI.Container.LAYOUT.AUTO,
        gridCols = 1,
        fillDirection = GUI.Container.LAYOUT.VERTICAL,
        gridGap = 8,
        padding = { x = 0, y = 0 },
        draggable = true,
        _x = 1560,
        _y = 350,
    });

    GUI.ctx.addView(lacUI);

    buttons:addView(mainSelector, subSelector);
    lacUI:addView(
        buttons,
        dropdownFactory(settings.Defense, 'Engaged Mode'),
        dropdownFactory(settings.Turtle),
        dropdownFactory(settings.Hybrid),
        dropdownFactory(settings.DD),
        dropdownFactory(settings.Engaged),
        dropdownFactory(settings.Weaponskill)
    );
    mainSelector.variable = settings.Main;
    subSelector.variable = settings.Sub;
end

do -- Sets
    sets.Idle = {
        Ammo = 'Staunch Tathlum +1',
        Head = 'Turms Cap +1',
        Body = 'Runeist Coat +3',
        Hands = 'Turms Mittens +1',
        Legs = 'Eri. Leg Guards +1',
        Feet = 'Erilaz Greaves +1',
        Neck = 'Futhark Torque +2',
        Waist = 'Flume Belt +1',
        Ear1 = 'Genmei Earring',
        Ear2 = 'Odnowa Earring +1',
        Ring1 = 'Moonlight Ring',
        Ring2 = 'Gelatinous Ring +1',
        Back = gear.Ogma_Tank,
        swaps = {
            {
                test = function() return settings.Sub.value == 'Mensch Strap +1' end,
                Feet = 'Turms Leggings +1'
            },
            {
                test = function() return settings.Turtle.value == 'Max HP' end,
                Hands = 'Regal Gauntlets',
                Feet = 'Turms Leggings +1',
                Ear1 = 'Odnowa Earring',
            },
            {
                test = function()
                    return settings.Sub.value == 'Mensch Strap +1'
                        and settings.Turtle.value == 'Max HP'
                end,
                Back = 'Moonlight Cape'
            }
        }
    };

    sets.Engaged_Turtle = {
        Ammo = 'Yamarang',
        Head = 'Turms Cap +1',
        Body = 'Runeist Coat +3',
        Hands = 'Turms Mittens +1',
        Legs = 'Eri. Leg Guards +1',
        Feet = 'Turms Leggings +1',
        Neck = 'Futhark Torque +2',
        Waist = 'Flume Belt +1',
        Ear1 = 'Ethereal Earring',
        Ear2 = 'Odnowa Earring +1',
        Ring1 = 'Defending Ring',
        Ring2 = 'Gelatinous Ring +1',
        Back = gear.Ogma_Tank,
        swaps = {
            {
                test = function() return settings.Sub.value == 'Utu Grip' end,
                Ear1 = 'Genmei Earring',
            },
            {
                test = function() return settings.Turtle.value == 'Max HP' end,
                Ammo = 'Staunch Tathlum +1',
                Body = 'Futhark Coat +3',
                Ear1 = 'Odnowa Earring',
                Ring1 = { Name = 'Moonlight Ring', Priority = 15 },
                Ring2 = { Name = 'Gelatinous Ring +1', Priority = 15 },
            },
            {
                test = function()
                    return settings.Sub.value == 'Mensch Strap +1'
                        and settings.Turtle.value == 'Max HP'
                end,
                Head = 'Fu. Bandeau +3'
            }
        }
    };

    sets.Engaged_Hybrid = {
        Ammo = 'Staunch Tathlum +1',
        Head = 'Aya. Zucchetto +2',
        Body = 'Ayanmo Corazza +2',
        Hands = 'Turms Mittens +1',
        Legs = 'Meg. Chausses +2',
        Feet = 'Turms Leggings +1',
        Neck = 'Futhark Torque +2',
        Waist = 'Ioskeha Belt +1',
        Ear1 = 'Telos Earring',
        Ear2 = { Name = 'Sherida Earring', Priority = 15 },
        Ring1 = 'Defending Ring',
        Ring2 = 'Moonlight Ring',
        Back = gear.Ogma_Acc,
        swaps = {
            {
                test = function()
                    return settings.Main.value == 'Epeolatry'
                        and gData.GetBuffCount('Aftermath: Lv.3')
                end,
                Ammo = 'Yamarang',
                Body = 'Futhark Coat +3',
            }
        }
    };

    sets.Engaged_DD = {
        Ammo = 'Yamarang',
        Head = 'Dampening Tam',
        Body = 'Tu. Harness +1',
        Hands = gear.Adhemar_Hands_PathA,
        Legs = 'Samnuha Tights',
        Feet = gear.Herc_Feet_TA,
        Neck = 'Ainia Collar',
        Waist = 'Ioskeha Belt +1', -- Windbuffet +1
        Ear1 = 'Dedition Earring',
        Ear2 = 'Sherida Earring',
        Ring1 = 'Epona\'s Ring',
        Ring2 = 'Niqmaddu Ring',
        Back = gear.Ogma_Acc,
        swaps = {
            {
                test = function() return settings.Engaged.value == 'Mid' end,
                Neck = 'Anu Torque',
                Ear1 = 'Telos Earring',
            },
            {
                test = function() return settings.Engaged.value == 'High' end,
                Legs = 'Meg. Chausses +2'
            }
        }
    };

    sets.Engaged_DD_Epeolatry_AM3 = {
        Ammo = 'Yamarang',
        Head = 'Aya. Zucchetto +2',
        Body = 'Tu. Harness +1',
        Hands = gear.Adhemar_Hands_PathA,
        Legs = 'Samnuha Tights',
        Feet = gear.Carmine_Feet_PathD,
        Neck = 'Ainia Collar',
        Waist = 'Kentarch Belt +1',
        Ear1 = 'Dedition Earring',
        Ear2 = 'Sherida Earring',
        Ring1 = { Name = 'Moonlight Ring', Priority = 15 },
        Ring2 = 'Niqmaddu Ring',
        Back = gear.Ogma_Acc,
    };

    sets.Engaged_DD_DT = {
        Ammo = 'Staunch Tathlum +1',
        Head = 'Aya. Zucchetto +2', -- Adhemar bonnet Path D
        Body = 'Tu. Harness +1',
        Hands = gear.Adhemar_Hands_PathA,
        Legs = 'Meg. Chausses +2',
        Feet = gear.Herc_Feet_TA,
        Neck = 'Futhark Torque +2',
        Waist = 'Ioskeha Belt +1',
        Ear1 = 'Telos Earring',
        Ear2 = 'Sherida Earring',
        Ring1 = { Name = 'Moonlight Ring', Priority = 15 },
        Ring2 = { Name = 'Moonlight Ring', Priority = 15 },
        Back = gear.Ogma_Acc,
        swaps = {
            {
                test = function()
                    return settings.Main.value == 'Epeolatry'
                        and gData.GetBuffCount('Aftermath: Lv.3')
                end,
                Ammo = 'Yamarang',
                Legs = 'Samnuha Tights',
                Feet = gear.Carmine_Feet_PathD,
                Waist = 'Kentarch Belt +1'
            }
        }
    };


    sets.Precast = {
        Ammo = 'Impatiens',
        Head = { Name = 'Rune. Bandeau +3', Priority = 14 },
        Body = { Name = 'Runeist Coat +3', Priority = 15 },
        Hands = 'Leyline Gloves',
        Legs = 'Aya. Cosciales +2',
        Feet = 'Erilaz Greaves +1',
        Neck = { Name = 'Futhark Torque +2', Priority = 15 },
        Waist = { Name = 'Kasiri Belt', Priority = 15 },
        Ear1 = 'Loquac. Earring',
        Ear2 = { Name = 'Odnowa Earring +1', Priority = 15 },
        Ring1 = 'Kishar Ring',
        Ring2 = { Name = 'Gelatinous Ring +1', Priority = 15 },
        Back = gear.Ogma_FC,
        swaps = {
            {
                test = predicates.p_or(
                    predicates.buff_active('Fast Cast'),
                    predicates.magic_skill('Enhancing Magic')
                ),
                Legs = 'Futhark Trousers +3'
            },
            {
                test = predicates.p_and(
                    predicates.magic_skill('Enhancing Magic'),
                    predicates.p_not(predicates.buff_active('Fast Cast'))
                ),
                Waist = 'Siegel Sash'
            },
            {
                test = predicates.p_and(
                    predicates.buff_active('Fast Cast'),
                    predicates.magic_skill('Enhancing Magic'),
                    willDropHP
                ),
                Hands = 'Regal Gaunglets',
            },
            { -- Drop 4 fastcast for 110 HP
                test = willDropHP,
                Ring1 = { Name = 'Moonlight Ring', Priority = 15 }
            },
            { -- Drop 2 fastcast to convert 100 HP
                test = willDropHP,
                Ear1 = { Name = 'Odnowa Earring', Priority = 15 },
            }
        }
    };

    sets.Enmity = {
        Ammo = 'Staunch Tathlum +1',
        Head = 'Halitus Helm',
        Body = 'Emet Harness +1',
        Hands = 'Kurys Gloves',
        Legs = 'Eri. Leg Guards +1',
        Feet = 'Erilaz Greaves +1',
        Neck = 'Moonlight Necklace',
        Waist = { Name = 'Kasiri Belt', Priority = 15 },
        Ear1 = { Name = 'Cryptic Earring', Priority = 14 },
        Ear2 = { Name = 'Odnowa Earring +1', Priority = 15 },
        Ring1 = 'Defending Ring',
        Ring2 = { Name = 'Eihwaz Ring', Priority = 13 },
        Back = gear.Ogma_Enmity,
        swaps = {
            {
                test = willDropHP,
                Ring1 = { Name = 'Moonlight Ring', Priority = 15 },
                Ring2 = { Name = 'Gelatinous Ring +1', Priority = 15 },
            }
        }
    };

    sets.SIRD = {
        Ammo = 'Staunch Tathlum +1',
        Head = 'Fu. Bandeau +3',
        Body = 'Taeon Tabard',
        Hands = 'Rawhide Gloves',
        Legs = gear.Carmine_Legs_PathD,
        Feet = 'Taeon Boots',
        Neck = 'Moonlight Necklace',
        Waist = 'Audumbla Sash',
        Ear1 = 'Halasz Earring',
        Ear2 = { Name = 'Odnowa Earring +1', Priority = 15 },
        Ring1 = { Name = 'Defending Ring', Priority = 0 },
        Ring2 = { Name = 'Gelatinous Ring +1', Priority = 15 },
        Back = gear.Ogma_Enmity,
        swaps = {
            {
                test = willDropHP,
                Hands = 'Regal Gauntlets'
            },
            {
                test = willDropHP,
                Ring1 = 'Moonlight Ring'
            },
        }
    };

    sets.Midcast = {
        Ammo = 'Staunch Tathlum +1',
        Head = 'Rune. Bandeau +3',
        Body = { Name = 'Futhark Coat +3', Priority = 0 },
        Hands = 'Leyline Gloves',
        Legs = 'Aya. Cosciales +2',
        Feet = 'Erilaz Greaves +1',
        Neck = { Name = 'Moonlight Necklace', Priority = 1 },
        Waist = 'Audumbla Sash',
        Ear1 = { Name = 'Genmei Earring', Priority = 0 },
        Ear2 = 'Odnowa Earring +1',
        Ring1 = 'Defending Ring',
        Ring2 = { Name = 'Gelatinous Ring +1', Priority = 15 },
        Back = gear.Ogma_FC,
        swaps = {
            {
                test = predicates.action_name('Aquaveil'),
                Main = 'Nibiru Faussar',
                swapManagedWeapons = predicates.always_true
            },
            {
                test = predicates.magic_skill('Enhancing Magic'),
                Head = 'Erilaz Galea +1',
                Hands = 'Regal Gauntlets',
                Legs = 'Futhark Trousers +3',
            },
            {
                test = willDropHP,
                Ring1 = { name = 'Moonlight Ring', priority = 15 },
            },
            {
                test = willDropHP,
                Ear1 = { name = 'Odnowa Earring', priority = 15 },
            },
            {
                test = predicates.p_and(willDropHP, function() return settings.Sub == 'Mensch Strap +1'; end),
                Feet = 'Turms Leggings +1'
            },
            {
                test = willDropHP,
                Hands = 'Regal Gauntlets'
            },
        }
    };

    sets.Midcast_Regen = {
        Ammo = 'Staunch Tathlum +1',
        Head = { Name = 'Erilaz Galea +1', Priority = 0 },
        Body = { Name = 'Futhark Coat +3', Priority = 0 },
        Hands = { Name = 'Regal Gauntlets', Priority = 15 },
        Legs = { Name = 'Futhark Trousers +3', Priority = 15 },
        Feet = 'Erilaz Greaves +1',
        Neck = { Name = 'Sacro Gorget', Priority = 0 },
        Waist = 'Sroda Belt',
        Ear1 = 'Genmei Earring',
        Ear2 = 'Odnowa Earring +1',
        Ring1 = { Name = 'Moonlight Ring', Priority = 15 },
        Ring2 = { Name = 'Gelatinous Ring +1', Priority = 15 },
        Back = gear.Ogma_FC,
        swaps = {
            {
                test = willDropHP,
                Ear1 = { Name = 'Odnowa Earring', Priority = 15 },
            },
        }
    };

    sets.Midcast_Stoneskin = {
        Ammo = 'Staunch Tathlum +1',
        Head = { Name = 'Fu. Bandeau +3', Priority = 0 },
        Body = { Name = 'Futhark Coat +3', Priority = 0 },
        Hands = { Name = 'Runeist Mitons +3', Priority = 15 },
        Legs = { Name = 'Futhark Trousers +3', Priority = 15 },
        Feet = 'Erilaz Greaves +1',
        Neck = { Name = 'Moonlight Necklace', Priority = 0 },
        Waist = 'Siegel Sash',
        Ear1 = { Name = 'Odnowa Earring', Priority = 15 },
        Ear2 = 'Odnowa Earring +1',
        Ring1 = { Name = 'Defending Ring', Priority = 0, },
        Ring2 = { Name = 'Gelatinous Ring +1', Priority = 15 },
        Back = gear.Ogma_FC,
        swaps = {
            {
                test = willDropHP,
                Ring1 = { Name = 'Moonlight Ring', Priority = 15 },
            },
            {
                test = willDropHP,
                Hands = { Name = 'Regal Gauntlets', Priority = 15 },
            },
        }
    };

    sets.Midcast_Spikes = {
        Ammo = 'Staunch Tathlum +1',
        Head = { Name = 'Erilaz Galea +1', Priority = 0 },
        Body = { Name = 'Futhark Coat +3', Priority = 0 },
        Hands = { Name = 'Regal Gauntlets', Priority = 15 },
        Legs = { Name = 'Futhark Trousers +3', Priority = 15 },
        Feet = 'Erilaz Greaves +1',
        Neck = { Name = 'Moonlight Necklace', Priority = 0 },
        Waist = 'Audumbla Sash',
        Ear1 = { Name = 'Genmei Earring', Priority = 0 },
        Ear2 = 'Odnowa Earring +1',
        Ring1 = { Name = 'Defending Ring', Priority = 0, },
        Ring2 = { Name = 'Gelatinous Ring +1', Priority = 15 },
        Back = gear.Ogma_Lunge,
        swaps = {
            {
                test = willDropHP,
                Ring1 = { Name = 'Odnowa Earring', Priority = 15 },
            },
            {
                test = willDropHP,
                Ring1 = { Name = 'Moonlight Ring', Priority = 15 },
            },
        }
    };

    sets.Midcast_Barspell = {
        Ammo = 'Staunch Tathlum +1',
        Head = { Name = 'Erilaz Galea +1', Priority = 0 },
        Body = { Name = 'Futhark Coat +3', Priority = 0 },
        Hands = 'Runeist Mitons +3',
        Legs = gear.Carmine_Legs_PathD,
        Feet = 'Erilaz Greaves +1',
        Neck = { Name = 'Moonlight Necklace', Priority = 0 },
        Waist = 'Audumbla Sash',
        Ear1 = { Name = 'Odnowa Earring', Priority = 15 },
        Ear2 = 'Odnowa Earring +1',
        Ring1 = { Name = 'Moonlight Ring', Priority = 15 },
        Ring2 = { Name = 'Gelatinous Ring +1', Priority = 15 },
        Back = gear.Ogma_FC
    };

    sets.Midcast_DivineMagic = {
        Ammo = 'Staunch Tathlum +1',
        Head = { Name = 'Rune. Bandeau +3', Priority = 15 },
        Body = { Name = 'Runeist Coat +3', Priority = 15 },
        Hands = { Name = 'Runeist Mitons +3', Priority = 15 },
        Legs = { Name = 'Rune. Trousers +1', Priority = 13 },
        Feet = 'Runeist Bottes +3',
        Neck = { Name = 'Moonlight Necklace', Priority = 0 },
        Waist = 'Audumbla Sash',
        Ear1 = 'Digni. Earring',
        Ear2 = { Name = 'Odnowa Earring +1', Priority = 15 },
        Ring1 = { Name = 'Defending Ring', Priority = 0 },
        Ring2 = { Name = 'Gelatinous Ring +1', Priority = 15 },
        Back = gear.Ogma_FC,
        swaps = {
            {
                test = willDropHP,
                Ring1 = { Name = 'Moonlight Ring', Priority = 15 },
            },
        }
    };

    sets.Midcast_Phalanx = {
        Ammo = 'Staunch Tathlum +1',
        Head = { Name = 'Fu. Bandeau +3', Priority = 0 },
        Body = { Name = 'Taeon Tabard', Priority = 0 },
        Hands = 'Taeon Gloves',
        Legs = 'Taeon Tights',
        Feet = 'Taeon Boots',
        Neck = { Name = 'Moonlight Necklace', Priority = 0 },
        Waist = 'Audumbla Sash',
        Ear1 = { Name = 'Odnowa Earring', Priority = 15 },
        Ear2 = 'Odnowa Earring +1',
        Ring1 = { Name = 'Defending Ring', Priority = 0, },
        Ring2 = { Name = 'Gelatinous Ring +1', Priority = 15 },
        Back = gear.Ogma_FC,
        swaps = {
            {
                test = willDropHP,
                Ring1 = { Name = 'Moonlight Ring', Priority = 15 },
            },
        }
    };

    sets.Midcast_Flash = sets.Enmity;
    sets.Midcast_Foil = sets.Enmity;

    sets.Midcast_Stun = sets.Enmity;
    sets.Midcast_Poisonga = sets.SIRD;
    sets.Midcast_Jettatura = sets.SIRD;
    sets.Midcast_GeistWall = sets.SIRD;
    sets.Midcast_SheepSong = sets.SIRD;
    sets.Midcast_BlankGaze = sets.SIRD;

    sets.Weaponskill_Resolution = {
        Ammo = 'Knobkierrie',
        Head = 'Lustratio Cap +1',
        Body = 'Lustratio Harness +1',
        Hands = 'Meg. Gloves +2',
        Legs = 'Samnuha Tights',
        Feet = gear.Lustratio_Feet_PathD,
        Neck = 'Fotia Gorget',
        Waist = 'Fotia Belt',
        Ear1 = 'Moonshade Earring',
        Ear2 = 'Sherida Earring',
        Ring1 = 'Regal Ring',
        Ring2 = 'Niqmaddu Ring',
        Back = gear.Ogma_Reso,
        swaps = {
            {
                test = settings.Engaged:equals('Mid'),
                Legs = 'Meg. Chausses +2',
            },
            {
                test = settings.Engaged:equals('High'),
                Ammo = 'Seeth. Bomblet',
            },
            {
                test = settings.Weaponskill:equals('Balanced'),
                Body = gear.Adhemar_Body_PathB,
                Legs = 'Meg. Chausses +2',
            },
            {
                test = settings.Weaponskill:equals('High'),
                Body = 'Meg. Cuirie +2',
                Legs = 'Meg. Chausses +2',
                Ring1 = { Name = 'Moonlight Ring', Priority = 15 },
            },
            {
                test = predicates.p_and(
                    settings.Weaponskill:equals('Balanced'),
                    settings.Engaged:equals('Mid')
                ),
                Body = gear.Adhemar_Body_PathB,
                Legs = 'Meg. Chausses +2',
                Ring2 = { Name = 'Moonlight Ring', Priority = 15 },
            },
            {
                test = predicates.p_and(
                    predicates.time_between(6.00, 18.00),
                    predicates.etp_gt(3000)
                ),
                Ear1 = 'Ishvara Earring'
            },
            {
                test = predicates.p_and(
                    predicates.time_between(18.01, 5.99),
                    predicates.etp_gt(3000)
                ),
                Ear1 = 'Lugra Earring +1',
            }
        }
    };

    sets.Weaponskill = sets.Weaponskill_Resolution;

    sets.Weaponskill_Dimidiation = {
        Ammo = 'Knobkierrie',
        Head = gear.Herc_Head_Dimi,
        Body = gear.Herc_Body_Dimi,
        Hands = 'Meghanada Gloves +2',
        Legs = 'Lustratio Subligar +1',
        Feet = 'Lustratio Leggings +1',
        Neck = 'Fotia Gorget',
        Waist = 'Fotia Belt',
        Ear1 = 'Moonshade Earring',
        Ear2 = 'Sherida Earring',
        Ring1 = 'Ilabrat Ring',
        Ring2 = 'Niqmaddu Ring',
        Back = gear.Ogma_Dimidi,
        swaps = {
            {
                test = predicates.p_and(
                    settings.Weaponskill:equals('Damage'),
                    settings.Engaged:equals('High')
                ),
                Head = 'Runeist Bandeau +3',
                Body = 'Meg. Cuirie +2'
            },
            {
                test = settings.Weaponskill:equals('Balanced'),
                Head = 'Lustratio Cap +1',
                Neck = 'Caro Necklace',
                Waist = 'Grunfeld Rope',
            },
            {
                test = settings.Weaponskill:equals('Tanky'),
                Head = 'Meghanada Visor +2',
                Body = 'Futhark Coat +3',
                Ring2 = 'Regal Ring',
            },
            {
                test = predicates.etp_gt(3000),
                Ear1 = 'Ishvara Earring'
            }
        }
    };

    sets.JA_Gambit = setCombine(sets.Enmity, { Hands = 'Runeist Mittons +3' });
    sets.JA_Rayke = setCombine(sets.Enimty, { Hands = 'Futhark Boots +3' });

    sets.JA_Vallation = setCombine(sets.Enmity, {
        Body = 'Runeist Coat +3', Legs = 'Futhark Trousers +3' });
    sets.JA_Valiance = sets.JA_Vallation;

    sets.JA_OneForAll = sets.Enmity;
    sets.JA_Liement = setCombine(sets.Enmity, { Body = 'Futhark Coat +3' });
    sets.JA_Battuta = setCombine(sets.Enmity, { Head = 'Fu. Bandeau +3' });
    sets.JA_Pflug = setCombine(sets.Enmity, { Feet = 'Runeist Bottes +3' });

    sets.JA_Swordplay = { Hands = 'Futhark Mitons +3' };
    sets.JA_ElementalSforzo = { Body = 'Futhark Coat +3' };
    sets.JA_VivaciousPulse = { Head = 'Erilaz Galea +1' };
    sets.JA_Embolden = { Back = 'Evasionist\'s Cape' };

    sets.JA_Provoke = sets.Enmity;
    sets.JA_Warcry = sets.Enmity;
    sets.JA_AnimatedFlourish = sets.Enmity;

    local function get_runes()
        return {
            Fire    = gData.GetBuffCount('Ignis'),
            Earth   = gData.GetBuffCount('Tellus'),
            Water   = gData.GetBuffCount('Unda'),
            Wind    = gData.GetBuffCount('Flabra'),
            Ice     = gData.GetBuffCount('Gelus'),
            Thunder = gData.GetBuffCount('Sulpor'),
            Light   = gData.GetBuffCount('Lux'),
            Dark    = gData.GetBuffCount('Tenebrae')
        };
    end

    local function lunge_hachirin()
        local element;
        local count = 0;
        for k, v in pairs(get_runes()) do
            if (v > count) then
                element = k;
                count = v;
            end
        end
        predicates.hachirin({ Element = element });
    end

    sets.JA_Lunge = {
        Ammo = 'Seeth. Bomblet +1',
        Head = gear.Herc_Head_MAB,
        Body = 'Samnuha Coat',
        Hands = 'Leyline Gloves',
        Legs = 'Augury Cuisses +1',
        Feet = gear.Herc_Feet_MAB,
        Neck = 'Eddy Necklace',
        Waist = 'Eschan Stone',
        Ear1 = 'Crematio Earring',
        Ear2 = 'Friomisi Earring',
        Ring1 = 'Locus Ring',
        Ring2 = 'Mujin Band',
        Back = gear.Ogma_Lunge,
        swaps = {
            {
                test = lunge_hachirin,
                waist = 'Hachirin Obi'
            },
            -- {
            --     test = predicates.orpheus,
            --     waist = 'Orpheus Sash'
            -- }
        },
    };

    sets.JA_Swipe = sets.JA_Lunge;

    sets.Item = sets.Idle;

    sets.Item_HolyWater = {
        Neck = 'Nicander\'s Necklace',
        Ring1 = 'Purity Ring'
    }
end

return profile;
