local GUI = require('J-GUI');
local functions = require('J-GUI/functions');
GUI.ctx.forceReload();

functions.addResourcePath(AshitaCore:GetInstallPath() .. 'config\\addons\\luashitacast\\assets\\');

local M = require('J-Mode');

local settings = {
    fastcast = 0,
    minimumBuffer = 0.1,
    packetDelay = 0.25,
};

print(AshitaCore:GetInstallPath());
local profile, sets = gFunc.LoadFile('common/J-Cast.lua')(settings);

-- You need to use this instead of gFunc.Combine
local function setCombine(...)
    local res = T {};
    for _, set in ipairs({ ... }) do
        for k, v in pairs(set) do
            res[k] = v;
        end
    end
    return res;
end

-- Put your weapons in here
settings.Main = M { description = 'Main Hand',
    'Amanomurakumo',
    'Soboro Sukehiro',
    'Leviathan\'s Couse'
};

settings.Range = M { description = 'Ranged Weapon',
    'Auto',
    'Yoichinoyumi',
};

settings.Ammo = M { description = 'Ranged Weapon',
    'Rune Arrow',
};


-- * Change the expandDirection to your choice of UP, DOWN, LEFT, RIGHT
local mainSelector = GUI.ItemSelector:new({
    color = T { 255, 0, 0 },
    animated = true,
    expandDirection = GUI.ENUM.DIRECTION.LEFT,
});

local rangeSelector = GUI.ItemSelector:new({
    color = T { 255, 0, 0 },
    animated = true,
    expandDirection = GUI.ENUM.DIRECTION.LEFT,
});

local ammoSelector = GUI.ItemSelector:new({
    color = T { 255, 0, 0 },
    animated = true,
    expandDirection = GUI.ENUM.DIRECTION.LEFT,
    hidden = true,
});

-- * Set _x and _y to where you want the ui to be.  You can click and drag, but it doesn't save yet
local lacUI = GUI.Container:new({
    layout = GUI.Container.LAYOUT.GRID,
    gridRows = GUI.Container.LAYOUT.AUTO,
    gridCols = 2,
    fillDirection = GUI.Container.LAYOUT.HORIZONTAL,
    gridGap = 4,
    padding = { x = 2, y = 2 },
    draggable = true,
    _x = 1560,
    _y = 350,
});
GUI.ctx.addView(lacUI);

lacUI:addView(
    mainSelector,
    rangeSelector,
    GUI.View:new(), -- Empty view for padding
    ammoSelector);

mainSelector.variable = settings.Main;
rangeSelector.variable = settings.Range;
ammoSelector.variable = settings.Ammo;

settings.Range.on_change:register(function(m)
    if (m.value == 'Auto') then
        ammoSelector.hidden = true;
    else
        ammoSelector.hidden = false;
    end
end);


-- ================= --
-- Your sets go here --
-- ================= --

sets.Engaged = {};

sets.Idle = {};

sets.SIRD = {};

sets.Resting = {};

sets.Weaponskill = {};

-- You can define ws (and engaged) sets by the weapon type
sets.Weaponskill_Archery = setCombine(sets.Weaponskill, {
    -- Make sure to put arrows in this set
});

sets.Preshot = {};

sets.Preshot_Throwing = {
    Ammo = 'Pebble'
};

sets.Midshot = {};

sets.Precast = {};
-- You can define sets by spell category
sets.Precast_Utsusemi = {};

sets.Midcast = {};


-- ============================ --
-- Don't change below this line --
-- ============================ --

profile.Sets = sets;

profile.Packer = {};

return profile;
