local ffi = require('ffi');

local d3d = require('d3d8');

local View = require('J-GUI/View');
local functions = require('J-GUI/functions');
local drawBorderBox = require('J-GUI/borderBox');
local text = require('J-GUI/text');

local getTexForStatus = require('functions.getTexForStatus');

local Targetbar = View:new();

function Targetbar:getWidth()
    return 200;
end

function Targetbar:getHeight()
    return 30 + self:getBarHeight();
end

function Targetbar:getBarHeight()
    return self.barHeight or 9;
end

function Targetbar:getClaimColor()
    return 0xFFFFFFFF;
end

function Targetbar:isDraggable(e)
    return self.parent.draggable;
end

local buffTex = T {};

local hpColor = d3d.D3DCOLOR_ARGB(0.8 * 255, 242, 140, 140);
local white = T { 255, 255, 255 };
local bar;

local rect = ffi.new('RECT', { 0, 0, 1, 1 });
local vec_position = ffi.new('D3DXVECTOR2', { 0, 0 });
local hp_scale = ffi.new('D3DXVECTOR2', { 1, 1 });

local buffRect = ffi.new('RECT', { 0, 0, 32, 32 });
local buffScale = ffi.new('D3DXVECTOR2', { 20 / 32, 20 / 32 });
function Targetbar:draw()
    -- print(self:isDraggable());
    local pos = self:getPos();
    local width = self:getWidth();
    local height = self:getBarHeight();

    local hpp = self:getHPP();
    local name = self:getName();
    local claimColor = self:getClaimColor();
    local distance = self:getDistance();

    local buffIds = self:getBuffIds();

    bar = bar or functions.loadAssetTexture('box-center-white.png');

    -- Start HP Bar
    drawBorderBox(self.ctx, pos.x, pos.y + 14, width, height, white);

    hp_scale.x = math.ceil(hpp * (width - 4));
    hp_scale.y = height - 4;

    vec_position.x = pos.x + 2;
    vec_position.y = pos.y + 16;

    self.ctx.sprite:Draw(bar, rect, hp_scale, nil, 0.0, vec_position, hpColor);
    -- End HP Bar

    -- Start Name
    local x, y = pos.x, pos.y;
    text.write2(x, y, name, 0xFFFFFFFF, 0.65);
    text.write2(x, y, name, claimColor, 0.65);
    -- End Name

    -- Start HPP
    local hppText = tostring(hpp * 100); -- .. '%';
    x = x + width - text.size2(hppText, 0.65);
    y = y + 10 + height + 3;
    text.write2(x, y, hppText, 0xFFFFFFFF, 0.65);
    text.write2(x, y, hppText, 0xFFFFFFFF, 0.65);
    -- End HPP

    -- Start Distance
    local distanceText = string.format('%.1f', distance);
    x = pos.x + width - text.size2(distanceText, 0.65);
    y = pos.y;
    text.write2(x, y, distanceText, 0xFFFFFFFF, 0.65);
    text.write2(x, y, distanceText, 0xFFFFFFFF, 0.65);
    -- End Distance

    -- Start Buffs
    vec_position.x = pos.x;
    vec_position.y = pos.y + height + 13;
    for i, buffId in ipairs(buffIds) do
        buffTex[buffId] = buffTex[buffId] or
            getTexForStatus(AshitaCore:GetResourceManager():GetString('buffs.names', buffId))();

        vec_position.x = pos.x + 22 * (i - 1);
        self.ctx.sprite:Draw(buffTex[buffId], buffRect, buffScale, nil, 0.0, vec_position, 0xFFFFFFFF);
    end
    -- End Buffs
end

function Targetbar:new(options)
    options = options or {};
    return setmetatable(options, { __index = Targetbar });
end

return Targetbar;
