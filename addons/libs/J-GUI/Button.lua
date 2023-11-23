require('common');
local ffi = require('ffi');
local d3d = require('d3d8');

local functions = require('J-GUI/functions');

local ENUM = require('J-GUI/enum');

local View = require('J-GUI/View');
local drawBorderBox = require('J-GUI/borderBox');

local Button = View:new();
Button.draggable = true;
Button._texture = T {};

function Button:onMouse(e)
    switch(e.message, {
        -- Left Button Down
        [513] = (function()
            self.pressed = true;
            e.blocked = true;
        end),
        -- Left Button Up
        [514] = (function()
            if (self.pressed) then
                self:onClick(e);
            end
            self.pressed = false;
            e.blocked = true;
        end)
    });
end

function Button:onMouseExit(e)
    if (self.pressed) then
        self.pressed = false;
        self.ctx.blockNextMouseUp = true;
    end
end

function Button:onClick(e)
    -- Empty.  Override this on button instances
end

function Button:getTexture()
    -- Empty.  Override this on button instances
end

do
    local white = d3d.D3DCOLOR_ARGB(255, 255, 255, 255);
    function Button:getTextureTint()
        return white;
    end
end

do
    local vec_size = ffi.new('D3DXVECTOR2', { 32.0, 32.0, });
    function Button:getTextureSize()
        return vec_size;
    end
end

function Button:getTextureOpacity()
    return 1.0;
end

function Button:getColor()
    return self.color;
end

function Button:getWidth()
    return self._width;
end

function Button:getHeight()
    return self._height;
end

do
    local vec_position = ffi.new('D3DXVECTOR2', { 0, 0, });

    local vec_scale = ffi.new('D3DXVECTOR2', { 1.0, 1.0, });

    function Button:draw()
        if (self.hidden) then return; end

        local pos = self:getPos();

        drawBorderBox(
            self.ctx,
            pos.x,
            pos.y,
            self:getWidth(),
            self:getHeight(),
            self:getColor(),
            self.pressed and 1.0 or self.ctx.background_opacity);


        -- vec_position.x = pos.x + 3 * self.ctx.vec_scale.x;
        -- vec_position.y = pos.y + 3 * self.ctx.vec_scale.y;

        self:drawTex(pos);
    end

    function Button:drawTex(pos)
        local tex = self:getTexture();

        if (not tex) then return; end

        local rect = self:getRect();
        local size = self:getTextureSize();
        local width = self:getWidth();
        local height = self:getHeight();

        vec_scale.x = size.x / rect.right * self.ctx.vec_scale.x;
        vec_scale.y = size.y / rect.bottom * self.ctx.vec_scale.y;

        vec_position.x = pos.x + (((width - 6) - size.x) / 2 + 3) * self.ctx.vec_scale.x;
        vec_position.y = pos.y + (((height - 6) - size.y) / 2 + 3) * self.ctx.vec_scale.y;

        local tint = self:getTextureTint();

        local alpha = bit.rshift(0xFF000000, 24) * self:getTextureOpacity();

        local color = bit.lshift(math.min(alpha, 255), 24) + bit.band(tint, 0xFFFFFF);

        self.ctx.sprite:Draw(tex, rect, vec_scale, nil, 0.0, vec_position, color);
    end
end


function Button:isDraggable(e)
    return self.parent.draggable;
end

Button._width = 38;
Button._height = 38;

function Button:new(options)
    options = options or {};

    return setmetatable(options, {
        __index = Button,
        __tostring = function() return "Button" end
    });
end

return Button;
