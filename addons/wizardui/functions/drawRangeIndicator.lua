local d3d = require('d3d8');
local drawArrow = require('functions.drawArrow');

local function getBone(actorPointer, bone)
    local x = ashita.memory.read_float(actorPointer + 0x678);
    local y = ashita.memory.read_float(actorPointer + 0x680);
    local z = ashita.memory.read_float(actorPointer + 0x67C);

    local skeletonBaseAddress = ashita.memory.read_uint32(actorPointer + 0x6B8);

    local skeletonOffsetAddress = ashita.memory.read_uint32(skeletonBaseAddress + 0x0C);

    local skeletonAddress = ashita.memory.read_uint32(skeletonOffsetAddress);

    local boneCount = ashita.memory.read_uint16(skeletonAddress + 0x32);
    -- print(boneCount);

    local bufferPointer = skeletonAddress + 0x30;
    local skeletonSize = 0x04;
    local boneSize = 0x1E;

    local generatorsAddress = bufferPointer + skeletonSize + boneSize * boneCount + 4;

    return x + ashita.memory.read_float(generatorsAddress + (bone * 0x1A) + 0x0E + 0x0),
        y + ashita.memory.read_float(generatorsAddress + (bone * 0x1A) + 0x0E + 0x8),
        z + ashita.memory.read_float(generatorsAddress + (bone * 0x1A) + 0x0E + 0x4)
end

local function drawRangeIndicator(targetIndex, spellRange)
    if (targetIndex <= 0) then return; end

    local entity = AshitaCore:GetMemoryManager():GetEntity();

    local player = GetPlayerEntity();
    if (not player) then return; end
    local playerPointer = player.ActorPointer;
    local targetPointer = entity:GetActorPointer(targetIndex);

    local x1, y1, z1 = getBone(playerPointer, 0);
    local x2, y2, z2 = getBone(targetPointer, 0);

    local distance = math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2 + (z1 - z2) ^ 2);
    local dDistance = spellRange - distance

    if (dDistance < 4) then
        local color;
        local alpha = 0xFF;
        if (dDistance < 0) then
            color = T { 0xDA, 0x20, 0x1A };
        elseif (dDistance < 1) then
            local t = 1 - dDistance;

            local r = 0xDA;
            local g = 0xDF + (0x20 - 0xDF) * t;
            local b = 0x20 + (0x1A - 0x20) * t;
            color = T { r, g, b };
        elseif dDistance < 2 then
            local t = math.max(2 - dDistance, 0);
            local r = 0x20 + (0xDA - 0x20) * t;
            local g = 0xDF;
            local b = 0x20;
            color = T { r, g, b };
        else
            local t = (4 - dDistance) / 2;
            alpha = 0xAA * t;
            color = T { 0x20, 0xDF, 0x20 };
        end

        drawArrow(x1, z1, y1, x2, z2, y2, d3d.D3DCOLOR_ARGB(alpha, color:unpack()));
    end
end

return drawRangeIndicator;
