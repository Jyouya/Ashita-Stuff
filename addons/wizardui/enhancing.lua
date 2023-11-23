local GUI = require('J-GUI');
-- local settings = require('settings');
local canCastSpell = require('functions.canCastSpell');

local buffMenuFactory = require('enhancing.buffMenuFactory');

local function setup(s)
    for buff, settings in pairs(s.enhancing) do
        if (canCastSpell(buff)) then
            local buffUI = buffMenuFactory(s, buff);
            GUI.ctx.addView(buffUI);
        end
    end
end

return { setup = setup };
