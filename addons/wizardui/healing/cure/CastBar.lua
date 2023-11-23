local ffi = require('ffi');

local View = require('J-GUI/View');
local text = require('J-GUI/text');
local functions = require('J-GUI/functions');

local CastBar = View:new();

function CastBar:getSpellName()
    return '';
end

function CastBar:getTargetName()
    return '';
end

function CastBar:getFillRatio()
    return 0;
end

function CastBar:getFillColor()
    return 0xFFFFFF00;
end

function CastBar:getEmptyColor()
    return 0xAAAAAAAA;
end

function CastBar:getWidth()
    return 70 + text.size(1, self:getTargetName());
end

CastBar._height = 32;
function CastBar:getHeight()
    return self._height;
end

do
    local rect = ffi.new('RECT', { 0, 0, 40, 24 });
    local vec_scale = ffi.new('D3DXVECTOR2', { 1.0, 1.0 });
    local vec_position = ffi.new('D3DXVECTOR2', { 0, 0 });
    local arrow;
    function CastBar:draw()
        local fillRatio = math.min(math.max(0, self:getFillRatio()), 1);

        if (fillRatio == 0) then
            return;
        end

        local pos = self:getPos();
        arrow = arrow or functions.loadAssetTexture(
            string.format(
                '%s/assets/arrow-white.png',
                addon.path));

        vec_position.x = pos.x + 15;
        vec_position.y = pos.y + 4;

        local fillWidth = math.floor(fillRatio * 40 + 0.5);

        rect.left = 0;
        rect.right = fillWidth;

        if (fillWidth > 0) then
            self.ctx.sprite:Draw(arrow, rect, vec_scale, nil, 0.0, vec_position, self:getFillColor());
        end

        rect.left = fillWidth;
        rect.right = 40;
        vec_position.x = vec_position.x + fillWidth;

        if (fillWidth < 40) then
            self.ctx.sprite:Draw(arrow, rect, vec_scale, nil, 0.0, vec_position, self:getEmptyColor());
        end

        local spellName = self:getSpellName();
        local spellWidth = text.size(1, spellName);

        text.write(math.floor(pos.x + 35 - spellWidth * 0.5), pos.y, 1, spellName, 0xFFFFFFFF);
        text.write(math.floor(pos.x + 35 - spellWidth * 0.5), pos.y, 1, spellName, 0xFFFFFF00);

        text.write(pos.x + 70, pos.y + 11, 1, self:getTargetName(), 0xFFFFFFFF);
        text.write(pos.x + 70, pos.y + 11, 1, self:getTargetName(), 0xFFFFFF00);
    end
end

function CastBar:new(options)
    local options = options or {};

    return setmetatable(options, { __index = CastBar });
end

return CastBar;
