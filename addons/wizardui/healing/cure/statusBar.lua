local ffi = require('ffi');

local View = require('J-GUI/View');
local functions = require('J-GUI/functions');
local drawBorderBox = require('J-GUI/borderBox');

local getTexForStatus = require('functions.getTexForStatus');

local StatusBar = View:new();

function StatusBar:getBuffs()
    return {};
end

function StatusBar:getDebuffs()
    return {};
end

local buffColor = T { 146, 175, 91 };
local debuffColor = T { 237, 120, 120 };
local white = T { 255, 255, 255 };

local vec_position = ffi.new('D3DXVECTOR2', { 0, 0 });
local scale = ffi.new('D3DXVECTOR2', { 13 / 32, 13 / 32 });
local rect = ffi.new('RECT', { 0, 0, 32, 32 });
local bgrect = ffi.new('RECT', { 0, 0, 15, 20 });
local bgscale = ffi.new('D3DXVECTOR2', { 17 / 15, 18 / 20 });

local buffIconTex;
local debuffIconTex;
local textures = T {};
function StatusBar:drawIcon(x, y, buff, isDebuff)
    local iconTex, yOffset;
    if (isDebuff) then
        debuffIconTex = debuffIconTex or functions.loadAssetTexture(addon.path .. 'assets/DebuffIcon.png');
        iconTex = debuffIconTex;
        yOffset = 2;
    else
        buffIconTex = buffIconTex or functions.loadAssetTexture(addon.path .. 'assets/BuffIcon.png')
        iconTex = buffIconTex;
        yOffset = 4;
    end

    vec_position.x = x;
    vec_position.y = y;
    self.ctx.sprite:Draw(iconTex, bgrect, bgscale, nil, 0.0, vec_position, 0xFFFFFFFF);

    textures[buff] = textures[buff] or getTexForStatus(buff)();
    vec_position.x = x + 2;
    vec_position.y = y + yOffset;
    self.ctx.sprite:Draw(textures[buff], rect, scale, nil, 0.0, vec_position, 0xFFFFFFFF);
end

function StatusBar:draw()
    local pos = self:getPos();
    local width = self:getWidth();

    local offset = width;
    local debuffs = self:getDebuffs();
    for _, debuff in ipairs(debuffs) do
        offset = offset - 17;
        self:drawIcon(pos.x + offset, pos.y + 16, debuff.name, true);
    end

    offset = width;
    local buffs = self:getBuffs();
    for _, debuff in ipairs(buffs) do
        offset = offset - 17;
        self:drawIcon(pos.x + offset, pos.y - 2, debuff, false);
    end
end

function StatusBar:new(options)
    return setmetatable(options, { __index = StatusBar });
end

return StatusBar;
