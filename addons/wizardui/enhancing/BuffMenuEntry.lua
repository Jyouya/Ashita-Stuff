local Container = require('J-GUI/Container');
local View = require('J-GUI/View');
local CheckBox = require('J-GUI/CheckBox');
local text = require('J-GUI/text');
local functions = require('J-GUI/functions');
local d3d = require('d3d8');
local ffi = require('ffi');
local M = require('J-Mode');

local drawBorderBox = require('J-GUI/borderBox');
local drawBox = require('enhancing.menuEntryBorderBox');

local white = T { 255, 255, 255 };

local BuffMenuEntry = Container:new();

function BuffMenuEntry:onMouseExit(e)
    Container.onMouseExit(self, e);
    if (self.pressed) then
        self.pressed = false;
        self.ctx.blockNextMouseUp = true;
    end
end

function BuffMenuEntry:getWidth()
    return self.parent:getWidth();
end

function BuffMenuEntry:getHeight()
    return 24;
end

-- Only supports a single child
function BuffMenuEntry:getChildPos()
    local pos = self:getPos();
    pos.x = pos.x + 3;
    pos.y = pos.y + 4;
    return pos;
end

function BuffMenuEntry:getIconTexture()
end

do
    local rect = ffi.new('RECT', { 0, 0, 64, 64 });
    -- Default texture rect
    function BuffMenuEntry:getIconRect()
        return rect;
    end
end

do
    local vec_size = ffi.new('D3DXVECTOR2', { 22.0, 22.0, });
    function BuffMenuEntry:getIconSize()
        return vec_size;
    end
end

function BuffMenuEntry:getIconOpacity()
    return 1.0;
end

function BuffMenuEntry:getIconTint()
    return 0xFFFFFFFF;
end

function BuffMenuEntry:getColor()
    return self.color or white;
end

function BuffMenuEntry:getText()
    return '';
end

-- Corner masks for boxes
local ROUND_TOP_FLAT_BOTTOM = 12;
local ROUND_TOP_ROUND_BOTTOM = 0;
local FLAT_TOP_ROUND_BOTTOM = 3;
local FLAT_TOP_FLAT_BOTTOM = 15;
do
    local vec_scale = ffi.new('D3DXVECTOR2', { 1.0, 1.0, });
    local vec_position = ffi.new('D3DXVECTOR2', { 0, 0, });

    function BuffMenuEntry:draw(last)
        local color = self:getColor();

        local pos = self:getPos();

        -- Draw the box
        drawBox(
            self.ctx,
            pos.x, pos.y,
            self:getWidth(), 24,
            color,
            self.pressed and 1.0 or self.ctx.background_opacity,
            last
        );

        if (self.parent.expanded) then
            -- print(self);
            local child = self.children[1];
            child:draw();
            pos.x = pos.x + 17;
        end
        pos.x = pos.x + 4;
        pos.y = pos.y - 1;

        self:drawIcon(pos);

        pos.x = pos.x + 19;
        pos.y = pos.y + 6;

        self:drawText(pos);
    end

    function BuffMenuEntry:drawIcon(pos)
        local iconTex = self:getIconTexture();

        if (not iconTex) then return; end

        local opacity = self:getIconOpacity();
        local tint = self:getIconTint();

        local rect = self:getIconRect();
        local size = self:getIconSize();

        vec_scale.x = size.x / rect.right * self.ctx.vec_scale.x;
        vec_scale.y = size.y / rect.bottom * self.ctx.vec_scale.y;

        vec_position.x = pos.x + ((16 - size.x) / 2) * self.ctx.vec_scale.x;
        vec_position.y = pos.y + ((26 - size.y) / 2) * self.ctx.vec_scale.y;

        local alpha = bit.rshift(0xFF000000, 24) * opacity;
        local color = bit.lshift(math.min(alpha, 255), 24) + bit.band(tint, 0xFFFFFF);

        -- Debug, uncomment to show icon borders
        -- drawBorderBox(self.ctx, vec_position.x, vec_position.y, 64 * vec_scale.x, 64 * vec_scale.y, T { 255, 255, 255 },
        -- 1.0, 0xF);
        self.ctx.sprite:Draw(iconTex, rect, vec_scale, nil, 0.0, vec_position, color);
    end

    function BuffMenuEntry:drawText(pos)
        local str = self:getText();
        local nameWidth = text.size(1, str);
        -- print(self.expanded);
        local maxNameWidth = 100 - (self.parent.expanded and 18 or 0);
        while (nameWidth > maxNameWidth) do
            -- print('debug');
            str = str:sub(1, #str - 2);
            str = str .. '\n'; -- \n is ellipsis in font 1, don't ask.
            nameWidth = text.size(1, str);
        end
        text.write(pos.x, pos.y, 1, str);
    end
end

function BuffMenuEntry:isTracked()
    return self._variable.value;
end

function BuffMenuEntry:onClick(e)
end

function BuffMenuEntry:onMouse(e)
    local clickedChild;

    for _, view in ipairs(self.children) do
        if (view.onMouse) then
            if (functions.testBounds(e.x, e.y, view:getClickableBounds())) then
                if (not (clickedChild and view:getZ() < clickedChild:getZ())) then
                    clickedChild = view;
                end
            end
        end
    end

    if (clickedChild) then
        return clickedChild:onMouse(e);
    end

    -- Handle mouse events that don't go to children
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

function BuffMenuEntry:new(options)
    options = options or {};

    options.children = T {};

    options._variable = options._variable or M(false);

    local buffMenuEntry = setmetatable(options, { __index = BuffMenuEntry });

    buffMenuEntry:addView(CheckBox:new({ variable = options._variable }));

    return buffMenuEntry
end

return BuffMenuEntry;
