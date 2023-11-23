local functions = require('J-GUI/functions');

local textures = T {};
local getTexForJob = function(job)
    local jobString = AshitaCore:GetResourceManager():GetString("jobs.names_abbr", job);
    if (not textures[jobString] and job > 0) then
        local path = string.format(
            '%s/assets/jobs/FFXIV/%s.png',
            addon.path,
            string.lower(jobString));
        textures[jobString] = functions.loadAssetTexture(path);
    end
    return textures[jobString];
end

return getTexForJob;