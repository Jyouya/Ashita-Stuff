require('common');
local ffi = require('ffi');

local View = {
    _x = 0,
    _y = 0,
    _z = 0,
    _width = 0,
    _height = 0
};

-- function View:getX()
--     if (self.parent) then
--         return self.parent:getChildX(self);
--     end
--     return self._x;
-- end

-- function View:getY()
--     if (self.parent) then
--         return self.parent:getChildY(self);
--     end
--     return self._y;
-- end

function View:getPos()
    if (self.parent) then
        return self.parent:getChildPos(self);
    end
    return { x = self._x, y = self._y };
end

function View:getZ()
    return self._z;
end

function View:getWidth()
    return self._width;
end

function View:getHeight()
    return self._height;
end

function View:getBounds()
    if (self:getHidden()) then return { -1, -1, -1, -1 }; end
    local pos = self:getPos();
    return { pos.x, pos.y, pos.x + self:getWidth(), pos.y + self:getHeight() };
end

function View:getClickableBounds()
    if (self:getHidden()) then return { -1, -1, -1, -1 }; end
    return self:getBounds();
end

function View:getHidden()
    return self.hidden;
end

function View:draw()

end

do -- ? Why is this in view instead of button?
    local rect = ffi.new('RECT', { 0, 0, 32, 32 });
    -- Default texture rect
    function View:getRect()
        return rect;
    end
end

function View:drag(x, y)
    if (self.parent) then
        return self.parent:dragView(self, x, y)
    end
    self._x = x;
    self._y = y;
end

function View:onDragFinish()
end

function View:isDraggable(e)
    return self.draggable or false;
end

function View:setCtx(ctx)
    self.ctx = ctx;
end

function View:new(options)
    return setmetatable(options or {}, { __index = View });
end

return View;
