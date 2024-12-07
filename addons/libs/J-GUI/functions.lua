local ffi = require('ffi');
local d3d = require('d3d8');

local functions = {};

functions.testBounds = function(x, y, box)
    return ((x >= box[1]) and (x <= box[3]) and (y >= box[2]) and (y <= box[4]));
end

local C = ffi.C;
local d3d8dev = d3d.get_device();




functions._resourcePaths = T { AshitaCore:GetInstallPath() .. 'addons\\libs\\J-GUI\\assets\\' };
functions.addResourcePath = function(resourcePath)
    functions._resourcePaths:insert(resourcePath)
end


functions.resolvePath = function(path)
    -- print('path: ' .. path);
    if (ashita.fs.exists(path)) then
        return path;
    end


    for _, resourcePath in ipairs(functions._resourcePaths) do
        -- TODO: Proper path join so no / edge cases
        local assetPath = resourcePath .. path;
        -- print(assetPath);
        if (ashita.fs.exists(assetPath)) then
            return assetPath;
        end
    end
end

functions.loadAssetTexture = function(path)
    path = functions.resolvePath(path);

    -- print('path2: ' .. (path or ''))
    if (not path) then
        return nil;
    end

    local texture_ptr = ffi.new('IDirect3DTexture8*[1]');
    if (C.D3DXCreateTextureFromFileA(d3d8dev, path, texture_ptr) ~= C.S_OK) then
        return nil;
    end

    return d3d.gc_safe_release(ffi.cast('IDirect3DTexture8*', texture_ptr[0]));
end

functions.loadAssetTextureTransparent = function(path, transparentColor)
    transparentColor = transparentColor == nil and 0xFF000000 or transparentColor;
    path = functions.resolvePath(path);

    -- print('path2: ' .. (path or ''))
    if (not path) then
        return nil;
    end

    local texture_ptr = ffi.new('IDirect3DTexture8*[1]');
    if (C.D3DXCreateTextureFromFileExA(d3d8dev,
            path,
            0xFFFFFFFF, 0xFFFFFFFF,
            1, 0,
            ffi.C.D3DFMT_A8R8G8B8, ffi.C.D3DPOOL_MANAGED,
            ffi.C.D3DX_DEFAULT, ffi.C.D3DX_DEFAULT,
            0xFF000000, nil, nil, texture_ptr) ~= C.S_OK) then
        return nil;
    end

    return d3d.gc_safe_release(ffi.cast('IDirect3DTexture8*', texture_ptr[0]));
end

functions.loadItemTexture = function(itemid)
    if (T { nil, 0, -1, 65535 }:hasval(itemid)) then
        return nil;
    end

    local item = AshitaCore:GetResourceManager():GetItemById(itemid);
    if (item == nil) then return nil end
    ;

    local texture_ptr = ffi.new('IDirect3DTexture8*[1]');
    if (C.D3DXCreateTextureFromFileInMemoryEx(d3d8dev, item.Bitmap, item.ImageSize, 0xFFFFFFFF, 0xFFFFFFFF, 1, 0, C.D3DFMT_A8R8G8B8, C.D3DPOOL_MANAGED, C.D3DX_DEFAULT, C.D3DX_DEFAULT, 0xFF000000, nil, nil, texture_ptr) ~= C.S_OK) then
        return nil;
    end

    return d3d.gc_safe_release(ffi.cast('IDirect3DTexture8*', texture_ptr[0]));
end

-- load a status icon from the games own resources and return a texture pointer
---@param statusId number the status id to load the icon for
---@return ffi.cdata* texture_ptr the loaded texture object or nil on error
functions.loadStatusTexture = function(statusId)
    if (statusId == nil or statusId < 0 or statusId > 0x3FF) then
        return nil;
    end

    local icon = AshitaCore:GetResourceManager():GetStatusIconByIndex(statusId);
    if (icon ~= nil) then
        local dx_texture_ptr = ffi.new('IDirect3DTexture8*[1]');
        if (ffi.C.D3DXCreateTextureFromFileInMemoryEx(d3d8dev, icon.Bitmap, icon.ImageSize, 0xFFFFFFFF, 0xFFFFFFFF, 1, 0, ffi.C.D3DFMT_A8R8G8B8, ffi.C.D3DPOOL_MANAGED, ffi.C.D3DX_DEFAULT, ffi.C.D3DX_DEFAULT, 0xFF000000, nil, nil, dx_texture_ptr) == ffi.C.S_OK) then
            return d3d.gc_safe_release(ffi.cast('IDirect3DTexture8*', dx_texture_ptr[0]));
        end
    end
    return nil;
end

functions.combineBounds = function(...)
    local boxes = { ... };
    local len = #boxes;
    if (len < 2) then
        return boxes[1];
    end
    local res = boxes[1];
    for i = 2, len do
        res = {
            math.min(res[1], boxes[i][1]),
            math.min(res[2], boxes[i][2]),
            math.max(res[3], boxes[i][3]),
            math.max(res[4], boxes[i][4])
        }
    end
    return res;
end


-- Special case of insertion sort
functions.zSort = function(views)
    local len = #views;
    for j = 2, len do
        local key = views[j];
        local i = j - 1;
        while i > 0 and views[i]:getZ() > key:getZ() do
            views[i + 1] = views[i];
            i = i - 1;
        end
        views[i + 1] = key;
    end
    return views;
end

return functions;
