local Container = require('J-GUI/Container');

local FilteredContainer = Container:new();

function FilteredContainer:filterChildren()
    local res = T {};
    for _, child in ipairs(self._children) do
        if ((not child.shouldDisplay) or child:shouldDisplay()) then
            res:append(child);
        elseif (child._isHovered) then
            child:onMouseExit();
        end
    end
    return res;
end

function FilteredContainer:draw()
    self.children = self:filterChildren();
    Container.draw(self);
end

function FilteredContainer:addView(...)
    for _, view in ipairs({ ... }) do
        view.parent = self;
        view:setCtx(self.ctx);
        self._children:append(view);
    end
end

function FilteredContainer:setCtx(ctx)
    self.ctx = ctx;
    for _, child in ipairs(self._children) do
        child:setCtx(ctx);
    end
end

function FilteredContainer:new(options)
    options = options or {};
    options.children = options.children or T {};
    options._children = options._children or T {};

    return setmetatable(options, { 
        __index = FilteredContainer,
        __tostring = function() return "FilteredContainer" end
    });
end

return FilteredContainer;
