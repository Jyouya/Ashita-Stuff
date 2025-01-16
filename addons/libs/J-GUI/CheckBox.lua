require('common');
local ffi = require('ffi');
local d3d = require('d3d8');

local functions = require('J-GUI/functions');

local View = require('J-GUI/View');
local drawBorderBox = require('J-GUI/borderBox');

local CheckBox = View:new();

CheckBox.draggable = true;

CheckBox._width = 14;
CheckBox._height = 14;

function CheckBox:onMouseExit(e)
    if (self.pressed) then
        self.pressed = false;
        self.ctx.blockNextMouseUp = true;
    end
end

function CheckBox:onMouse(e)
    switch(e.message, {
        -- Left Button Down
        [513] = (function()
            self.pressed = true;
            e.blocked = true;
        end),
        -- Left Button Up
        [514] = (function()
            if (self.pressed) then
                self:toggle();
            end
            self.pressed = false;
            e.blocked = true;
        end)
    });
end

CheckBox.color = T { 255, 255, 255 };

function CheckBox:getColor()
    return self.color;
end

local dot;

function CheckBox:toggle()
    return self.variable:set(not self:getValue());
end

function CheckBox:getValue()
    return self.variable.value;
end

function CheckBox:draw()
    if (self.hidden) then return; end

    local pos = self:getPos();
    -- print(pos.x, pos.y)

    drawBorderBox(self.ctx, pos.x, pos.y, self:getWidth(), self:getHeight(), self:getColor(),
        self.ctx.background_opacity);

    if (self:getValue()) then
        self:drawMarker(pos);
    end
end

local vec_position = ffi.new('D3DXVECTOR2', { 0, 0, });
local vec_scale = ffi.new('D3DXVECTOR2', { 0, 0 });
function CheckBox:drawMarker(pos)
    dot = dot or functions.loadAssetTexture('dot.png');

    local rect = ffi.new('RECT', { 0, 0, 8, 8 });

    vec_position.x = pos.x + 2;
    vec_position.y = pos.y + 2;

    vec_scale.x = self.ctx.vec_scale.x * 1.25;
    vec_scale.y = self.ctx.vec_scale.y * 1.25;

    self.ctx.sprite:Draw(dot, rect, vec_scale, nil, 0.0, vec_position, 0xFFFFFFFF);
end

function CheckBox:new(options)
    options = options or {};

    return setmetatable(options, {
        __index = CheckBox,
        __tostring = function() return "CheckBox" end
    });
end

return CheckBox;
