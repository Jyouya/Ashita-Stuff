require('common');
local ffi = require('ffi');
local d3d = require('d3d8');

local functions = require('J-GUI/functions');

local ENUM = require('J-GUI/enum');
local DIRECTION = ENUM.DIRECTION;

local ItemSelector = require('J-GUI/ItemSelector');
local drawBorderBox = require('J-GUI/borderBox');
local text = require('J-GUI/text')

local Dropdown = ItemSelector:new();

do
    local function textSize(string)
        return text.size(1, string);
    end

    function Dropdown:getWidth()
        if (self.isFixedWidth) then
            if (self._width) then
                return self._width;
            end
        end
        return math.max(self:getOptions():map(textSize):unpack()) + 8;
    end
end

do
    local vec_position = ffi.new('D3DXVECTOR2', { 0, 0, });
    local white = d3d.D3DCOLOR_ARGB(255, 255, 255, 255);

    function Dropdown:_drawAnimating(pos, scale)
        local options = self:getOptions();
        local width, height;

        -- We can only expand up/down
        height = #options * 20 * scale + 20;
        width = self:getWidth();

        if (self.expandDirection == DIRECTION.UP) then
            pos.y = pos.y - height + 18;
        end

        drawBorderBox(self.ctx, pos.x, pos.y, width, height, self.color,
            math.max(scale, self.ctx.background_opacity));

        for i, option in ipairs(self:getOptions()) do
            if (self.expandDirection == DIRECTION.UP) then
                vec_position.x = pos.x + 4 * self.ctx.vec_scale.x;
                vec_position.y = pos.y + (20 * (i - 1) + 4) * self.ctx.vec_scale.y * scale;
            else
                vec_position.x = pos.x + 4 * self.ctx.vec_scale.x;
                vec_position.y = pos.y + (20 * i + 4) * self.ctx.vec_scale.y * scale;
            end

            text.write(vec_position.x, vec_position.y, 1, option);

            if (self:getValue() == option) then
                text.write(vec_position.x, vec_position.y, 1, option);
            end
        end
        return width, height;
    end

    function Dropdown:draw()
        if (self.hidden) then return; end
        local pos = self:getPos();

        if (self._animating and os.clock() >= self._animationStart + self.animationTime) then
            self._animating = false;
        end

        if (not self._expanded) then
            if (not self._animating) then
                drawBorderBox(self.ctx, pos.x, pos.y, self:getWidth(), 20, self.color);
            else
                local scale;

                if (self._animating) then
                    scale = 1 - math.min(os.clock() - self._animationStart, self.animationTime) / self.animationTime;
                else
                    scale = 0;
                end

                local width, height = self:_drawAnimating(pos, scale);

                if (self.expandDirection == DIRECTION.UP) then
                    pos.y = pos.y + height - 20;
                end
            end
        else
            local scale;

            if (self._animating) then
                scale = math.min(os.clock() - self._animationStart, self.animationTime) / self.animationTime;
            else
                scale = 1;
            end

            local _, height = self:_drawAnimating(pos, scale);

            if (self.expandDirection == DIRECTION.UP) then
                pos.y = pos.y + height - 20;
            end
        end

        local value = self:getValue();
        if (not value) then return; end

        vec_position.x = pos.x + 4 * self.ctx.vec_scale.x;
        vec_position.y = pos.y + 4 * self.ctx.vec_scale.y;
        text.write(vec_position.x, vec_position.y, 1, value)
    end
end

function Dropdown:getClickableBounds()
    if (self.hidden) then return { -1, -1, -1, -1 }; end
    if (not self._expanded) then return self:getBounds(); end

    local width, height;
    local options = self:getOptions();

    height = #options * 20 + 20;
    width = self:getWidth();

    local pos = self:getPos();
    if (self.expandDirection == DIRECTION.UP) then
        pos.y = pos.y - height + 20;
    end

    return { pos.x, pos.y, pos.x + width, pos.y + height };
end

function Dropdown:new(options)
    options = options or {};
    options._height = 20;

    return setmetatable(options, { __index = Dropdown });
end

function Dropdown:_indexForMouseEvent(e)
    local bounds = self:getClickableBounds();
    local length = #self:getOptions();
    local index;

    -- Figure out what index was clicked
    if (self.expandDirection == DIRECTION.UP) then
        bounds[4] = bounds[4] - 20;
    else
        bounds[2] = bounds[2] + 20;
    end

    local height = bounds[4] - bounds[2];
    index = math.floor((e.y - bounds[2]) / height * length) + 1;

    return index;
end

return Dropdown
