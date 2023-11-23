local functions = require('J-GUI/functions');
local getTexForAbility;
do
    local textures = T {};
    getTexForAbility = function(ability)
        return function()
            if (not textures[ability]) then
                textures[ability] = functions.loadAssetTexture(
                    string.format(
                        '%s/assets/abilities/%s.png',
                        addon.path,
                        string.lower(ability)));
            end
            return textures[ability];
        end
    end
end

return getTexForAbility;
