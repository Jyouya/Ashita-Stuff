local d3d8dev    = require('d3d8').get_device();
local ffi        = require('ffi');
local C          = ffi.C;

local helpers    = require('helpers');
local getTexture = helpers.getTexture;

ffi.cdef [[
    #pragma pack(1)
    struct VertFormatFFFUFF
    {
        float x;
        float y;
        float z;
        unsigned int diffuse;
        float u;
        float v;
    };
]]

local vertFormatMask = bit.bor(C.D3DFVF_XYZ, C.D3DFVF_DIFFUSE, C.D3DFVF_TEX1);
local vertFormat     = ffi.new('struct VertFormatFFFUFF');

local function buildUnitCircle(steps)
    local points = T {
        { 0, 0, 0, 0, 0.5, 0 },
    };

    local interval = 1 / steps;
    for i = 0, steps do
        local theta = 2 * math.pi * i * interval;
        points:insert({
            math.cos(theta),
            0,
            math.sin(theta),
            0,
            i * interval,
            0
        });
    end

    local res = T {};
    for _, p in ipairs(points) do
        res:insert(ffi.new('struct VertFormatFFFUFF', p));
    end

    return res;
end

-- local function buildTransformMatrix(x, y, z, r)
--     return ffi.new('D3DXMATRIX', {
--         r, 0, 0, 0,
--         0, r, 0, 0,
--         0, 0, r, 0,
--         x, y, z, r
--     });
-- end

local function transformVertex(v, x, y, z, r, c)
    return ffi.new('struct VertFormatFFFUFF', {
        r * v.x + x,
        r * v.y + y,
        r * v.z + z,
        c,
        v.u,
        v.v
    });
end

local unitCircle = buildUnitCircle(100);

local function transformCircle(x, y, z, r, c)
    local points = T {};
    for i, point in ipairs(unitCircle) do
        points[i] = transformVertex(point, x, y, z, r, c);
    end
    return points;
end

local _, vertexBuffer = d3d8dev:CreateVertexBuffer(
    200 * ffi.sizeof(vertFormat),
    C.D3DUSAGE_WRITEONLY,
    vertFormatMask,
    C.D3DPOOL_MANAGED);


local mat4Identity = ffi.new('D3DMATRIX', {
    1, 0, 0, 0,
    0, 1, 0, 0,
    0, 0, 1, 0,
    0, 0, 0, 1
});

local tex;
local function drawCircle(x, y, z, r, c, t)
    local mesh = transformCircle(x, y, z, r, c);

    mesh[1].v = t;
    for i = 2, #mesh do
        mesh[i].v = t - 1;
    end

    local _, ptr = vertexBuffer:Lock(0, 0, 0);
    local vdata = ffi.cast('struct VertFormatFFFUFF*', ptr);

    for i, point in ipairs(mesh) do
        vdata[i - 1] = point;
    end

    vertexBuffer:Unlock();

    -- print(vdata[1].diffuse)

    tex = tex or getTexture(addon.path .. 'assets/tex.png');

    d3d8dev:SetTransform(C.D3DTS_WORLD, mat4Identity);

    d3d8dev:SetVertexShader(vertFormatMask);

    d3d8dev:SetStreamSource(0, vertexBuffer, ffi.sizeof(vertFormat));
    d3d8dev:SetTexture(0, tex);

    d3d8dev:SetTextureStageState(0, C.D3DTSS_COLOROP, C.D3DTOP_MODULATE);
    d3d8dev:SetTextureStageState(0, C.D3DTSS_COLORARG1, C.D3DTA_TEXTURE);
    d3d8dev:SetTextureStageState(0, C.D3DTSS_COLORARG2, C.D3DTA_DIFFUSE);
    d3d8dev:SetTextureStageState(0, C.D3DTSS_ALPHAOP, C.D3DTOP_MODULATE);
    d3d8dev:SetTextureStageState(0, C.D3DTSS_ALPHAARG1, C.D3DTA_TEXTURE);
    d3d8dev:SetTextureStageState(0, C.D3DTSS_ALPHAARG2, C.D3DTA_DIFFUSE);

    -- d3d8dev:SetTextureStageState(0, C.D3DTSS_COLOROP, C.D3DTOP_SELECTARG1);
    -- d3d8dev:SetTextureStageState(0, C.D3DTSS_COLORARG1, C.D3DTA_DIFFUSE);
    -- d3d8dev:SetTextureStageState(0, C.D3DTSS_COLORARG2, C.D3DTA_DIFFUSE);
    -- d3d8dev:SetTextureStageState(0, C.D3DTSS_ALPHAOP, C.D3DTOP_SELECTARG1);
    -- d3d8dev:SetTextureStageState(0, C.D3DTSS_ALPHAARG1, C.D3DTA_DIFFUSE);
    -- d3d8dev:SetTextureStageState(0, C.D3DTSS_ALPHAARG2, C.D3DTA_DIFFUSE);

    d3d8dev:SetTextureStageState(0, C.D3DTSS_ADDRESSU, C.D3DTADDRESS_WRAP);
    d3d8dev:SetTextureStageState(0, C.D3DTSS_ADDRESSV, C.D3DTADDRESS_WRAP);

    d3d8dev:SetRenderState(C.D3DRS_LIGHTING, 0);
    d3d8dev:SetRenderState(C.D3DRS_ZENABLE, 0);
    d3d8dev:SetRenderState(C.D3DRS_ALPHABLENDENABLE, 1);
    d3d8dev:SetRenderState(C.D3DRS_SRCBLEND, C.D3DBLEND_SRCALPHA);
    d3d8dev:SetRenderState(C.D3DRS_DESTBLEND, C.D3DBLEND_INVSRCALPHA);

    d3d8dev:DrawPrimitive(C.D3DPT_TRIANGLEFAN, 0, 100);
end

return drawCircle;
