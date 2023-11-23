local FilteredContainer = require('J-GUI/FilteredContainer');
local functions = require('J-GUI/functions');
local text = require('J-GUI/text');
local d3d = require('d3d8');
local ffi = require('ffi');

local drawBorderBox = require('J-GUI/borderBox');

local BuffMenu = FilteredContainer:new();

local white = d3d.D3DCOLOR_ARGB(255, 255, 255, 255);

function BuffMenu:getWidth()
    return self._width;
end

function BuffMenu:getHeight()
    local res = 30; -- Height of chrome

    for _, child in ipairs(self.children) do
        res = res + child:getHeight();
    end
    return res;
end

-- Assume this is only called on visible children
function BuffMenu:getChildPos(child)
    local pos = self:getPos();

    pos.y = pos.y + 6 + (24 * self:_indexOfChild(child));

    return pos;
end

function BuffMenu:_indexOfChild(child)
    for i, c in ipairs(self.children) do
        if (child == c) then
            return i;
        end
    end
    return -1;
end

function BuffMenu:onMouseExit(e)
    FilteredContainer.onMouseExit(self, e);
    if (self.pressed) then
        self.pressed = false;
        self.ctx.blockNextMouseUp = true;
    end
end

-- function BuffMenu.filterChildren(children)
--     local res = T {};
--     for _, child in ipairs(children) do
--         if ((not child.shouldDisplay) or child:shouldDisplay()) then
--             res:insert(child);
--         end
--     end
--     return res;
-- end

function BuffMenu:getChromeColor()
    return self.color or T { 255, 255, 255 };
end

function BuffMenu:getIconTexture()
end

function BuffMenu:getIconOpacity()
    return 1.0;
end

function BuffMenu:getIconTint()
    return white;
end

function BuffMenu:getTitle()
    return '';
end

function BuffMenu:drawTitle(pos)
    local str = self:getTitle();
    text.write(pos.x, pos.y, 1, str);
end

do
    local rect = ffi.new('RECT', { 0, 0, 32, 32 });
    -- Default texture rect
    function BuffMenu:getIconRect()
        return rect;
    end
end

do
    local vec_size = ffi.new('D3DXVECTOR2', { 24.0, 24.0, });
    function BuffMenu:getIconSize()
        return vec_size;
    end
end

-- Linear search for element of array
local function indexOfChild(table, child)
    for i, v in ipairs(table) do
        if (v == child) then return i; end
    end
    return -1;
end


-- Corner masks for boxes
local ROUND_TOP_FLAT_BOTTOM = 12;
local ROUND_TOP_ROUND_BOTTOM = 0;
local FLAT_TOP_ROUND_BOTTOM = 3;
do
    local vec_scale = ffi.new('D3DXVECTOR2', { 1.0, 1.0, });
    local vec_position = ffi.new('D3DXVECTOR2', { 0, 0, });

    function BuffMenu:draw()
        if (self:getHidden()) then return; end
        local oldFilteredChildren = self.children or {};

        self.children = self:filterChildren();
        if (not self.expanded) then
            -- Ensure children in the previous list maintain their position
            for i, child in ipairs(oldFilteredChildren) do
                local oldIndex = indexOfChild(oldFilteredChildren, child);

                -- child is still being shown, but is not in the correct place
                if (oldIndex < i) then
                    self.children[i] = self.children[oldIndex];
                    self.children[oldIndex] = child;
                end
            end
            -- else
            --     self._filteredChildren = self.children;
        end

        local chromeColor = self:getChromeColor()

        local pos = self:getPos();

        -- Draw the chrome box
        drawBorderBox(
            self.ctx,
            pos.x, pos.y,
            self:getWidth(), 30,
            chromeColor,
            self.pressed and 1.0 or self.ctx.background_opacity,
            #self.children > 0 and ROUND_TOP_FLAT_BOTTOM or ROUND_TOP_ROUND_BOTTOM
        );

        self:drawIcon(pos);
        local iconSize = self:getIconSize();

        pos.x = pos.x + (iconSize.x + 6) * self.ctx.vec_scale.x;
        pos.y = pos.y + 9 * self.ctx.vec_scale.y;

        self:drawTitle(pos);

        -- ? Can I get away with not supporting z-sorting here?
        for i, child in ipairs(self.children) do
            child:draw(i == #self.children);
        end

        -- for _, child in ipairs(functions.zSort(self._filteredChildren:copy())) do
        --     child:draw();
        -- end
    end

    function BuffMenu:drawIcon(pos)
        local iconTex = self:getIconTexture();

        if (not iconTex) then return; end

        local opacity = self:getIconOpacity();
        local tint = self:getIconTint();

        local rect = self:getIconRect();
        local size = self:getIconSize();

        vec_scale.x = size.x / rect.right * self.ctx.vec_scale.x;
        vec_scale.y = size.y / rect.bottom * self.ctx.vec_scale.y;

        vec_position.x = pos.x + ((24 - size.x) / 2 + 3) * self.ctx.vec_scale.x;
        vec_position.y = pos.y + ((24 - size.y) / 2 + 3) * self.ctx.vec_scale.y;

        local alpha = bit.rshift(0xFF000000, 24) * opacity;
        local color = bit.lshift(math.min(alpha, 255), 24) + bit.band(tint, 0xFFFFFF);

        self.ctx.sprite:Draw(iconTex, rect, vec_scale, nil, 0.0, vec_position, color);
    end
end

function BuffMenu:isDraggable(e)
    return true;
end

-- Handle mouse events in the window chrome
function BuffMenu:_handleMouse(e)
    switch(e.message, {
        -- Left Button Down
        [513] = (function()
            self.pressed = true;
            e.blocked = true;
        end),
        -- Left Button Up
        [514] = (function()
            -- ? Don't think we need to have an on click event for chrome.
            -- if (self.pressed) then
            --     self:onClick(e);
            -- end
            self.pressed = false;
            self.expanded = not self.expanded;
            e.blocked = true;
        end)
    });
end

function BuffMenu:onMouse(e)
    local pos = self:getPos();

    -- Click is on the chrome
    if (functions.testBounds(e.x, e.y, { pos.x, pos.y, pos.x + self:getWidth(), pos.y + 30 })) then
        self:_handleMouse(e);
    else
        FilteredContainer.onMouse(self, e);
    end
end

BuffMenu.expanded = true;

function BuffMenu:new(options)
    options = options or {};

    options.children = options.children or T {};
    options._children = options._children or T {};

    return setmetatable(options, {
        __index = BuffMenu,
        __tostring = function() return "BuffMenu" end
    });
end

return BuffMenu;
