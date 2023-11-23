local GUI = require('J-GUI');
local settings = require('settings');

local nuke = require('divine.divineNuke');

local canCastSpell = require('functions.canCastSpell');

local function setup(s)
    local divineUI = GUI.Container:new({
        layout = GUI.Container.LAYOUT.GRID,
        gridRows = 1,
        gridCols = GUI.Container.LAYOUT.AUTO,
        fillDirection = GUI.Container.LAYOUT.HORIZONTAL,
        gridGap = 4,
        padding = { x = 2, y = 2 },
        draggable = true,
        onDragFinish = function(view)
            local pos = view:getPos();
            s.divine.x = pos.x;
            s.divine.y = pos.y;
            settings.save();
        end,
        getHidden = function()
            return not s.divine.visible;
        end,
        _x = s.divine.x,
        _y = s.divine.y
    });
    GUI.ctx.addView(divineUI);

    if (canCastSpell('Holy')) then
        divineUI:addView(nuke('Holy', 2));
    end

    if (canCastSpell('Banish')) then
        divineUI:addView(nuke('Banish', 3));
    end

    if (canCastSpell('Banishga')) then
        divineUI:addView(nuke('Banishga', 2, true));
    end
end

return { setup = setup };
