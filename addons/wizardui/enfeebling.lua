local GUI = require('J-GUI');
local settings = require('settings');

local combat = require('enfeebling.combat');

local canCastSpell = require('functions.canCastSpell');

local function setup(s)
    local enfeeblingUI = GUI.Container:new({
        layout = GUI.Container.LAYOUT.GRID,
        gridRows = GUI.Container.LAYOUT.AUTO,
        gridCols = 1,
        fillDirection = GUI.Container.LAYOUT.HORIZONTAL,
        gridGap = 4,
        padding = { x = 2, y = 2 },
        draggable = true,
        onDragFinish = function(view)
            local pos = view:getPos();
            s.enfeebling.x = pos.x;
            s.enfeebling.y = pos.y;
            settings.save();
        end,
        getHidden = function()
            return not s.enfeebling.visible;
        end,
        _x = s.enfeebling.x,
        _y = s.enfeebling.y
    });
    GUI.ctx.addView(enfeeblingUI);

    local row1 = GUI.Container:new({
        layout = GUI.Container.LAYOUT.GRID,
        gridRows = 1,
        gridCols = GUI.Container.LAYOUT.AUTO,
        fillDirection = GUI.Container.LAYOUT.HORIZONTAL,
        draggable = true,
        gridGap = 4,
        padding = { x = 2, y = 2 },
    });

    -- Dia/Bio
    if (canCastSpell('Dia')) then
        row1:addView(combat.tieredEnfeeble('Dia', 3));
    end
    if (canCastSpell('Bio')) then
        row1:addView(combat.tieredEnfeeble('Bio', 3));
    end

    -- Frazzle/Distract
    -- if (canCastSpell('Frazzle')) then
    --     row1:addView(combat.tieredEnfeeble('Frazzle', 3));
    -- end
    -- if (canCastSpell('Distract')) then
    --     row1:addView(combat.tieredEnfeeble('Distract', 3));
    -- end

    -- Other single target
    if (canCastSpell('Gravity')) then
        row1:addView(combat.tieredEnfeeble('Gravity', 2));
    end
    if (canCastSpell('Paralyze')) then
        row1:addView(combat.tieredEnfeeble('Paralyze', 2));
    end
    if (canCastSpell('Slow')) then
        row1:addView(combat.tieredEnfeeble('Slow', 2));
    end
    if (canCastSpell('Blind')) then
        row1:addView(combat.tieredEnfeeble('Blind', 2));
    end
    if (canCastSpell('Silence')) then
        row1:addView(combat.tieredEnfeeble('Silence', 1));
    end
    if (canCastSpell('Poison')) then
        row1:addView(combat.tieredEnfeeble('Poison', 2));
    end
    if (canCastSpell('Addle')) then
        row1:addView(combat.tieredEnfeeble('Addle', 2));
    end

    if (#row1.children > 0) then
        enfeeblingUI:addView(row1);
    end

    local row2 = GUI.Container:new({
        layout = GUI.Container.LAYOUT.GRID,
        gridRows = 1,
        gridCols = GUI.Container.LAYOUT.AUTO,
        fillDirection = GUI.Container.LAYOUT.HORIZONTAL,
        draggable = true,
        gridGap = 4,
        padding = { x = 2, y = 2 },
    });

    local disengageEnfeebles = T {};
    if (canCastSpell('Sleep')) then
        disengageEnfeebles:insert(combat.tieredEnfeeble('Sleep', 3));
    end
    if (canCastSpell('Repose')) then
        disengageEnfeebles:insert(combat.tieredEnfeeble('Repose', 1));
    end
    if (canCastSpell('Bind')) then
        disengageEnfeebles:insert(combat.tieredEnfeeble('Bind', 3));
    end
    if (canCastSpell('Break')) then
        disengageEnfeebles:insert(combat.tieredEnfeeble('Break', 3));
    end

    local aoeEnfeebles = T {};
    if (canCastSpell('Sleepga')) then
        aoeEnfeebles:insert(combat.tieredAoeEnfeeble('Sleep', 2));
    end
    if (canCastSpell('Breakga')) then
        aoeEnfeebles:insert(combat.tieredAoeEnfeeble('Break', 1));
    end
    if (canCastSpell('Diaga')) then
        aoeEnfeebles:insert(combat.tieredAoeEnfeeble('Dia', 1));
    end
    if (canCastSpell('Poisonga')) then
        aoeEnfeebles:insert(combat.tieredAoeEnfeeble('Poison', 1));
    end

    row2:addView(disengageEnfeebles:unpack());

    local padding = #row1.children - #disengageEnfeebles - #aoeEnfeebles;
    if (padding > 0) then
        for i = 1, padding do
            row2:addView(GUI.View:new({ _width = 38, _height = 38 }));
        end
    end

    row2:addView(aoeEnfeebles:unpack());


    if (#row2.children > 0) then
        enfeeblingUI:addView(row2);
    end
end


return { setup = setup };
