local GUI = require('J-GUI');
local settings = require('settings');

local elementalNinjutsu = require('ninjutsu.elementalNinjutsu');

local canCastSpell = require('functions.canCastSpell');

local function setup(s)
    local ninjutsuUI = GUI.Container:new({
        layout = GUI.Container.LAYOUT.GRID,
        gridRows = GUI.Container.LAYOUT.AUTO,
        gridCols = 6,
        fillDirection = GUI.Container.LAYOUT.HORIZONTAL,
        gridGap = 4,
        padding = { x = 2, y = 2 },
        draggable = true,
        onDragFinish = function(view)
            local pos = view:getPos();
            s.ninjutsu.elemental.x = pos.x;
            s.ninjutsu.elemental.y = pos.y;
            settings.save();
        end,
        getHidden = function()
            return not s.ninjutsu.elemental.visible;
        end,
        _x = s.ninjutsu.elemental.x,
        _y = s.ninjutsu.elemental.y
    });

    GUI.ctx.addView(ninjutsuUI);

    ninjutsuUI:addView(elementalNinjutsu('Katon'));
    ninjutsuUI:addView(elementalNinjutsu('Suiton'));
    ninjutsuUI:addView(elementalNinjutsu('Raiton'));
    ninjutsuUI:addView(elementalNinjutsu('Doton'));
    ninjutsuUI:addView(elementalNinjutsu('Huton'));
    ninjutsuUI:addView(elementalNinjutsu('Hyoton'));
end

return { setup = setup };
