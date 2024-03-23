local ffi = require('ffi');
local C = ffi.C;
local d3d = require('d3d8');
local d3d8dev = d3d.get_device();

local GUI = require('J-GUI');

local BezierSpline = T {};

function BezierSpline:new(options)
    options = options or {};
    options.controlPoints = options.controlPoints or {};

    options.knotValues = options.knotValues or {};

    -- Default knot interval of 1 if unspecified
    if (#options.controlPoints > 0 and #options.knotValues == 0) then
        for i = 0, #options.controlPoints / 4 do
            options.knotValues[i + 1] = i;
        end
    end


    for i, v in ipairs(options.knotValues) do
        options.knotValues[i] = v / options.knotValues[#options.knotValues];
    end

    options._coefficients = T {};
    for i = 1, #options.knotValues - 1 do
        local P0, P1, P2, P3 = table.unpack(options.controlPoints, i * 4 - 3, i * 4);

        local res = T {};
        res.D = { P0[1], P0[2] };
        res.C = { -3 * P0[1] + 3 * P1[1], -3 * P0[2] + 3 * P1[2] };
        res.B = { 3 * P0[1] - 6 * P1[1] + 3 * P2[1], 3 * P0[2] - 6 * P1[2] + 3 * P2[2] };
        res.A = { -1 * P0[1] + 3 * P1[1] - 3 * P2[1] + P3[1], -1 * P0[2] + 3 * P1[2] - 3 * P2[2] + P3[2] };

        local derivative = T {};
        derivative.A = { -3 * P0[1] + 9 * P1[1] - 9 * P2[1] + 3 * P3[1], -3 * P0[2] + 9 * P1[2] - 9 * P2[2] + 3 * P3[2] };
        derivative.B = { 6 * P0[1] - 12 * P1[1] + 6 * P2[1], 6 * P0[2] - 12 * P1[2] + 6 * P2[2] };
        derivative.C = { -3 * P0[1] + 3 * P1[1], -3 * P0[2] + 3 * P1[2] };
        res.derivative = derivative;
        options._coefficients[i] = res;
    end

    return setmetatable(options, { __index = BezierSpline });
end

function BezierSpline:_getKnotIndex(t)
    local iStart, iEnd, iMid = 1, #self.knotValues, 0;
    -- Keep us from going out of bounds;
    if (t >= self.knotValues[iEnd]) then
        -- print(iEnd);
        return iEnd;
    end

    while iStart <= iEnd do
        iMid = math.floor((iStart + iEnd) / 2);
        local knot = self.knotValues[iMid];
        local nextKnot = self.knotValues[iMid + 1];
        if (t >= knot and t < nextKnot) then
            return iMid;
        elseif (knot >= t) then
            iEnd = iMid - 1;
        else
            iStart = iMid + 1;
        end
    end
end

local function normalize(vec2)
    local u = (vec2[1] ^ 2 + vec2[2] ^ 2) ^ (-0.5);
    return { vec2[1] * u, vec2[2] * u };
end

function BezierSpline:getPoint(t)
    if (t > 1) then
        t = 1;
    elseif (t < 0) then
        t = 0;
    end
    local knotIndex = self:_getKnotIndex(t);
    if (not knotIndex) then
        print(t)
    end

    if (knotIndex == #self.knotValues) then
        local c = self._coefficients[knotIndex - 1];
        local d = c.derivative;
        return self.controlPoints[#self.controlPoints],
            normalize({
                -(d.A[2] + d.B[2] + d.C[2]),
                d.A[1] + d.B[1] + d.C[1],
            });
    end

    local knotValue = self.knotValues[knotIndex];
    local nextKnotValue = self.knotValues[knotIndex + 1];

    local knotInterval = nextKnotValue - knotValue;

    local u = (t - knotValue) / knotInterval;

    local c = self._coefficients[knotIndex];
    local d = c.derivative;

    local point = {
        c.A[1] * u ^ 3 + c.B[1] * u ^ 2 + c.C[1] * u + c.D[1],
        c.A[2] * u ^ 3 + c.B[2] * u ^ 2 + c.C[2] * u + c.D[2],
    };
    local normal = normalize({
        -(d.A[2] * u ^ 2 + d.B[2] * u + d.C[2]),
        d.A[1] * u ^ 2 + d.B[1] * u + d.C[1],
    });

    return point, normal;
end

local function getTexture(path)
    local texture_ptr = ffi.new('IDirect3DTexture8*[1]');
    if (C.D3DXCreateTextureFromFileA(d3d8dev, path, texture_ptr) ~= C.S_OK) then
        return nil;
    end

    return d3d.gc_safe_release(ffi.cast('IDirect3DBaseTexture8*', texture_ptr[0]));
end

ffi.cdef [[
    #pragma pack(1)
    struct VertFormatFFFFUFF
    {
        float x;
        float y;
        float z;
        float rhw;
        unsigned int diffuse;
        float u;
        float v;
    };
]]
local vertFormat      = ffi.new('struct VertFormatFFFFUFF');
local vertFormatFVF   = bit.bor(C.D3DFVF_XYZRHW, C.D3DFVF_DIFFUSE, C.D3DFVF_TEX1);
local _, vertexBuffer = d3d8dev:CreateVertexBuffer(
    1000 * ffi.sizeof(vertFormat),
    C.D3DUSAGE_WRITEONLY,
    vertFormatFVF,
    C.D3DPOOL_MANAGED);

local defaultTex;
function BezierSpline:draw(ctx, t1, t2, segments, thickness, color, tex, translation)
    local points = T {};
    local normals = T {};
    thickness = (thickness or 1) / 2;
    local segmentLength = (t2 - t1) / segments;
    local previousNormal;

    -- for i = 0, 40 do
    --     local point, normal = self:getPoint(i / 40);

    --     GUI.text.write(
    --         800, 210 + 16 * i, 1, string.format('%.2f, (%.1f, %.1f), (%.1f, %.1f)',
    --             i / 40, point[1], point[2], normal[1], normal[2]
    --         ));
    -- end

    tex = tex or defaultTex;
    if (not tex) then
        defaultTex = getTexture(AshitaCore:GetInstallPath() .. 'addons\\libs\\J-GUI\\assets\\box-center-white.png');
        tex = defaultTex;
    end

    local xOffset = translation.x;
    local yOffset = translation.y;
    for i = 0, segments do
        local point, normal = self:getPoint(t1 + i * segmentLength);

        point[1] = point[1] + xOffset;
        point[2] = point[2] + yOffset;


        -- Draw straight lines in a single segment
        if (previousNormal and normal[1] == previousNormal[1] and normal[2] == previousNormal[2] and #points > 1) then
            points[#points] = point;
            normals[#normals] = normal;
        else
            points:insert(point);
            normals:insert(normal);
            previousNormal = normal;
        end
    end

    ctx.sprite:End();

    local vertices = T {};

    for i, point in ipairs(points) do
        local nx = normals[i][1] * thickness;
        local ny = normals[i][2] * thickness;
        local u = (i - 1) / #points;
        vertices:insert({ point[1] + nx, point[2] + ny, 1, 1, color, u, 0 });
        vertices:insert({ point[1] - nx, point[2] - ny, 1, 1, color, u, 1 });
    end

    local _, ptr = vertexBuffer:Lock(0, 0, 0);
    local vdata = ffi.cast('struct VertFormatFFFFUFF*', ptr);

    for i, vertex in ipairs(vertices) do
        if (i > 999) then
            print(i, #vertices);
            break;
        end
        vdata[i - 1] = ffi.new('struct VertFormatFFFFUFF', vertex);
    end

    vertexBuffer:Unlock();

    -- print(vdata[0].x, vdata[0].y)

    d3d8dev:SetStreamSource(0, vertexBuffer, ffi.sizeof(vertFormat));

    d3d8dev:SetTexture(0, tex);

    d3d8dev:SetVertexShader(bit.bor(C.D3DFVF_XYZRHW, C.D3DFVF_DIFFUSE, C.D3DFVF_TEX1));

    d3d8dev:SetTextureStageState(0, C.D3DTSS_COLOROP, C.D3DTOP_MODULATE);
    d3d8dev:SetTextureStageState(0, C.D3DTSS_COLORARG1, C.D3DTA_TEXTURE);
    d3d8dev:SetTextureStageState(0, C.D3DTSS_COLORARG2, C.D3DTA_DIFFUSE);
    d3d8dev:SetTextureStageState(0, C.D3DTSS_ALPHAOP, C.D3DTOP_MODULATE);
    d3d8dev:SetTextureStageState(0, C.D3DTSS_ALPHAARG1, C.D3DTA_TEXTURE);
    d3d8dev:SetTextureStageState(0, C.D3DTSS_ALPHAARG1, C.D3DTA_DIFFUSE);

    d3d8dev:SetRenderState(C.D3DRS_LIGHTING, 0);
    d3d8dev:SetRenderState(C.D3DRS_ZENABLE, 0);
    d3d8dev:SetRenderState(C.D3DRS_ALPHABLENDENABLE, 1);
    d3d8dev:SetRenderState(C.D3DRS_SRCBLEND, C.D3DBLEND_SRCALPHA);
    d3d8dev:SetRenderState(C.D3DRS_DESTBLEND, C.D3DBLEND_INVSRCALPHA);

    d3d8dev:DrawPrimitive(C.D3DPT_TRIANGLESTRIP, 0, #vertices - 2);

    ctx.sprite:Begin();
end

return { BezierSpline = BezierSpline };
