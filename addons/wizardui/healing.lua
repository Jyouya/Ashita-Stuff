local GUI = require('J-GUI');
local settings = require('settings');
local canCastSpell = require('functions.canCastSpell');

local setupStatusRemoval = require('healing.statusRemoval');
local partyEntry = require('healing.cure.partyEntry');

local function setup(s)
    setupStatusRemoval(s);

    -- if (canCastSpell('Cure')) then
        local partyUI = GUI.FilteredContainer:new({
            layout = GUI.Container.LAYOUT.GRID,
            gridRows = 6,
            gridColumns = 1,
            fillDirection = GUI.Container.LAYOUT.VERTICAL,
            gridGap = 4,
            padding = { x = 0, y = 0 },
            draggable = true,
            onDragFinish = function(view)
                local pos = view:getPos();
                s.healing.partyFrame.x = pos.x;
                s.healing.partyFrame.y = pos.y;
                settings.save();
            end,
            getHidden = function()
                return not s.healing.partyFrame.visible;
            end,
            _x = s.healing.partyFrame.x,
            _y = s.healing.partyFrame.y
        });
        for i = 1, 6 do
            partyUI:addView(partyEntry(s, i));
        end
        GUI.ctx.addView(partyUI);
    -- end
end

return { setup = setup };
