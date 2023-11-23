local ffi     = require('ffi');
local d3d     = require('d3d8');
local C       = ffi.C;

local d3d8dev = d3d.get_device();

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
local vertFormat      = ffi.new('struct VertFormatFFFUFF');
local vertFormatFVF   = bit.bor(C.D3DFVF_XYZ, C.D3DFVF_DIFFUSE, C.D3DFVF_TEX1);

local _, vertexBuffer = d3d8dev:CreateVertexBuffer(
    4 * ffi.sizeof(vertFormat),
    C.D3DUSAGE_WRITEONLY,
    vertFormatFVF,
    C.D3DPOOL_MANAGED);

local mat4Identity    = ffi.new('D3DMATRIX', {
    1, 0, 0, 0,
    0, 1, 0, 0,
    0, 0, 1, 0,
    0, 0, 0, 1
});

local function getTexture(path)
    local texture_ptr = ffi.new('IDirect3DTexture8*[1]');
    if (C.D3DXCreateTextureFromFileA(d3d8dev, path, texture_ptr) ~= C.S_OK) then
        return nil;
    end

    return d3d.gc_safe_release(ffi.cast('IDirect3DBaseTexture8*', texture_ptr[0]));
end

local function normalize(vec3)
    local u = (vec3[1] ^ 2 + vec3[2] ^ 2 + vec3[3] ^ 2) ^ (-0.5);
    return { vec3[1] * u, vec3[2] * u, vec3[3] * u };
end

local arrowTex;
local function drawArrow(x1, y1, z1, x2, y2, z2, color)
    local _, ptr = vertexBuffer:Lock(0, 0, 0);
    local vdata = ffi.cast('struct VertFormatFFFUFF*', ptr);

    local d = normalize({ x2 - x1, 0, z2 - z1 });

    local dx = d[1] + x1;
    local dz = d[3] + z1;

    local sx1 = (d[1] - d[3]) / 2 + x1;
    local sz1 = (d[3] + d[1]) / 2 + z1;

    local sx2 = (d[1] + d[3]) / 2 + x1;
    local sz2 = (d[3] - d[1]) / 2 + z1;

    vdata[0] = ffi.new('struct VertFormatFFFUFF', { x1, y1, z1, color, 1, 0 });
    vdata[1] = ffi.new('struct VertFormatFFFUFF', { sx1, y1, sz1, color, 1, 1 });
    vdata[2] = ffi.new('struct VertFormatFFFUFF', { sx2, y1, sz2, color, 0, 0 });
    vdata[3] = ffi.new('struct VertFormatFFFUFF', { dx, y1, dz, color, 0, 1 });

    -- print(vdata[0].x)

    vertexBuffer:Unlock();

    arrowTex = arrowTex or getTexture(addon.path .. 'assets/triangle.png');

    d3d8dev:SetStreamSource(0, vertexBuffer, ffi.sizeof(vertFormat));

    d3d8dev:SetTexture(0, arrowTex);

    d3d8dev:SetTransform(C.D3DTS_WORLD, mat4Identity);

    d3d8dev:SetTextureStageState(0, C.D3DTSS_COLOROP, C.D3DTOP_MODULATE);
    d3d8dev:SetTextureStageState(0, C.D3DTSS_COLORARG1, C.D3DTA_TEXTURE);
    d3d8dev:SetTextureStageState(0, C.D3DTSS_COLORARG2, C.D3DTA_DIFFUSE);
    d3d8dev:SetTextureStageState(0, C.D3DTSS_ALPHAOP, C.D3DTOP_MODULATE);
    d3d8dev:SetTextureStageState(0, C.D3DTSS_ALPHAARG1, C.D3DTA_TEXTURE);
    d3d8dev:SetTextureStageState(0, C.D3DTSS_ALPHAARG2, C.D3DTA_DIFFUSE);

    d3d8dev:SetRenderState(C.D3DRS_LIGHTING, 0);
    d3d8dev:SetRenderState(C.D3DRS_ZENABLE, 0);
    d3d8dev:SetRenderState(C.D3DRS_ALPHABLENDENABLE, 1);
    d3d8dev:SetRenderState(C.D3DRS_SRCBLEND, C.D3DBLEND_SRCALPHA);
    d3d8dev:SetRenderState(C.D3DRS_DESTBLEND, C.D3DBLEND_INVSRCALPHA);

    d3d8dev:SetVertexShader(vertFormatFVF);

    d3d8dev:DrawPrimitive(C.D3DPT_TRIANGLESTRIP, 0, 2);
end

return drawArrow;
