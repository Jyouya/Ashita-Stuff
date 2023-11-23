local GUI = require('J-GUI');
local settings = require('settings');

local nuke = require('elemental.nuke');
local ga = require('elemental.ga');
local enfeeble = require('elemental.enfeeble');

local canCastSpell = require('functions.canCastSpell');

--[[
* Loads elemental ui
*
* @param {settings} s - The settings object returned by settings.load().
--]]
local function setup(s)
    local elementalUI = GUI.Container:new({
        layout = GUI.Container.LAYOUT.GRID,
        gridRows = GUI.Container.LAYOUT.AUTO,
        gridCols = 6,
        fillDirection = GUI.Container.LAYOUT.HORIZONTAL,
        gridGap = 4,
        padding = { x = 2, y = 2 },
        draggable = true,
        onDragFinish = function(view)
            local pos = view:getPos();
            s.elemental.x = pos.x;
            s.elemental.y = pos.y;
            settings.save();
        end,
        getHidden = function()
            return not s.elemental.visible;
        end,
        _x = s.elemental.x,
        _y = s.elemental.y
    });
    GUI.ctx.addView(elementalUI);
    if (canCastSpell('Stone')) then
        -- Single Target
        elementalUI:addView(nuke('FIRE'));
        elementalUI:addView(nuke('WATER'));
        elementalUI:addView(nuke('LIGHTNING'));
        elementalUI:addView(nuke('EARTH'));
        elementalUI:addView(nuke('WIND'));
        elementalUI:addView(nuke('ICE'));
    end

    if (canCastSpell('Stonega')) then
        elementalUI:addView(ga('FIRE'));
        elementalUI:addView(ga('WATER'));
        elementalUI:addView(ga('LIGHTNING'));
        elementalUI:addView(ga('EARTH'));
        elementalUI:addView(ga('WIND'));
        elementalUI:addView(ga('ICE'));
    end

    if (canCastSpell('Shock')) then
        elementalUI:addView(enfeeble('FIRE'));
        elementalUI:addView(enfeeble('WATER'));
        elementalUI:addView(enfeeble('LIGHTNING'));
        elementalUI:addView(enfeeble('EARTH'));
        elementalUI:addView(enfeeble('WIND'));
        elementalUI:addView(enfeeble('ICE'));
    end
end


return { setup = setup };
