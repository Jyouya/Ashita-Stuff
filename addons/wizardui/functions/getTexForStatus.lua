local functions = require('J-GUI/functions');

local textures = T {};

local function getTexForStatus(status)
    if (textures[status]) then
        return function()
            return textures[status];
        end
    end

    local statusId;
    if (type(status)) == 'string' then
        status = string.lower(status);

        local resourceManager = AshitaCore:GetResourceManager();
        local id = 0;
        while (not statusId and id < 700) do
            id = id + 1;
            local str = resourceManager:GetString('buffs.names', id);
            -- if (string.sub(str, 1, 5) == 'Block') then
            --     print(str)
            -- end
            if (str and status == string.lower(str)) then
                statusId = id;
            end
        end
    else
        statusId = status;
    end
    return function()
        local tex = textures[status];
        if (not tex) then
            local iconPath = nil;
            local supportsAlpha = false;
            T { '.png', '.jpg', '.jpeg', '.bmp' }:forieach(function(ext, _)
                if (iconPath ~= nil) then
                    return;
                end

                supportsAlpha = ext == '.png';
                iconPath = AshitaCore:GetInstallPath() ..
                    'addons\\HXUI\\assets\\status\\XIView\\' .. tostring(statusId) .. ext;
                local handle = io.open(iconPath, 'r');
                if (handle ~= nil) then
                    handle.close();
                else
                    iconPath = nil;
                end
            end);

            if (iconPath) then
                if (supportsAlpha) then
                    tex = functions.loadAssetTexture(iconPath);
                else
                    tex = functions.loadAssetTextureTransparent(iconPath);
                end
            else
                tex = functions.loadStatusTexture(statusId);
            end

            textures[status] = tex;
        end
        return tex;
    end
end

return getTexForStatus;
