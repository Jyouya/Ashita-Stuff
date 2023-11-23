local functions = require('J-GUI/functions');
local getTexForSpell;
do
    local textures = T {};
    getTexForSpell = function(spell)
        return function()
            if (not textures[spell]) then
                textures[spell] = functions.loadAssetTexture(
                    string.format(
                        '%s/assets/spells/%s.png',
                        addon.path,
                        string.lower(spell)));
            end
            return textures[spell];
        end
    end
end

return getTexForSpell;
