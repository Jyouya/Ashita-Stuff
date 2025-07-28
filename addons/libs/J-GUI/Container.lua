require('common');
local functions = require('J-GUI/functions');

local View = require('J-GUI/View');

local Container = View:new();


Container.LAYOUT = {
    GRID = 1,
    AUTO = -1,
    HORIZONTAL = 0,
    VERTICAL = 1
}

Container.layout = Container.LAYOUT.GRID;
Container.gridRows = 2;
Container.gridCols = Container.LAYOUT.AUTO;
Container.fillDirection = Container.LAYOUT.HORIZONTAL
Container.gridGap = 4;
Container.padding = { x = 0, y = 0 }

function Container:getChildPos(child)
    local pos = self:getPos();
    -- print(pos.x, pos.y);


    -- Grid layout
    if (self.layout == Container.LAYOUT.GRID) then
        local i = self:_indexOfChild(child) - 1;
        local row, col;
        if (self.fillDirection == Container.LAYOUT.HORIZONTAL) then
            col = i % self:_gridColCount() + 1;
            row = math.floor(i / self:_gridColCount()) + 1;
        else
            col = math.floor(i / self:_gridRowCount()) + 1;
            row = i % self:_gridRowCount() + 1;
        end

        -- Only need to iterate if we're not in the first column
        pos.x = pos.x + self.padding.x;
        if (col > 1) then
            for j = 1, col - 1 do
                pos.x = pos.x + self:_gridColWidth(j) + self.gridGap;
            end
        end

        pos.y = pos.y + self.padding.y;
        if (row > 1) then
            for j = 1, row - 1 do
                pos.y = pos.y + self:_gridRowHeight(j) + self.gridGap;
            end
        end

        -- print(pos.x, pos.y);

        return pos;
    end

    -- TODO: Flex layout?
end

function Container:_gridRowCount()
    if (self.gridRows ~= Container.LAYOUT.AUTO) then
        return self.gridRows or 1;
    end
    if (self.gridCols == Container.LAYOUT.AUTO) then
        error('J-GUI: Grid must have at least one fixed dimension');
    end
    return math.ceil(#self.children / self.gridCols);
end

function Container:_gridColCount()
    if (self.gridCols ~= Container.LAYOUT.AUTO) then
        return self.gridCols or 1;
    end
    if (self.gridRows == Container.LAYOUT.AUTO) then
        error('J-GUI: Grid must have at least one fixed dimension');
    end
    return math.ceil(#self.children / self.gridRows);
end

function Container:_gridColWidth(col)
    local res = 0;
    local colCount = self:_gridColCount();
    for i, child in ipairs(self.children) do
        if ((i - 1) % colCount == (col - 1)) then
            res = math.max(res, child:getWidth());
        end
    end
    return res;
end

function Container:_gridRowHeight(row)
    local res = 0;
    local rowCount = self:_gridRowCount();
    for i, child in ipairs(self.children) do
        if ((i - 1) % rowCount == (row - 1)) then
            res = math.max(res, child:getHeight());
        end
    end
    return res;
end

function Container:_indexOfChild(child)
    for i, c in ipairs(self.children) do
        if (child == c) then
            return i;
        end
    end
end

function Container:getWidth()
    if (self.layout == Container.LAYOUT.GRID) then
        local res = 0;
        local colCount = self:_gridColCount();
        for col = 1, colCount do
            res = res + self:_gridColWidth(col);
        end
        res = res + (colCount - 1) * self.gridGap;
        return res;
    end
    -- TODO: Other layout types
end

function Container:getHeight()
    if (self.layout == Container.LAYOUT.GRID) then
        local res = 0;
        local rowCount = self:_gridRowCount();
        for row = 1, rowCount do
            res = res + self:_gridRowHeight(row);
        end
        res = res + (rowCount - 1) * self.gridGap;
        return res;
    end
    -- TODO: Other layout types
end

function Container:getClickableBounds()
    if (self:getHidden()) then
        return T { -1, -1, -1, -1 };
    end
    local bounds = self:getBounds();

    for _, child in ipairs(self.children) do
        if (not child:getHidden()) then
            bounds = functions.combineBounds(bounds, child:getClickableBounds());
        end
    end

    return bounds;
end

function Container:addView(...)
    for _, view in ipairs({ ... }) do
        view.parent = self;
        view:setCtx(self.ctx);
        self.children:insert(view);
    end

    return self;
end

function Container:draw()
    if (self:getHidden()) then return; end
    for _, child in ipairs(functions.zSort(self.children:copy())) do
        child:draw();
    end
end

function Container:onMouse(e)
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

    -- print(clickedChild, prevClickedChild);
    if (clickedChild ~= self.prevClickedChild) then
        if (self.prevClickedChild) then
            self.prevClickedChild._isHovered = false;
            if (self.prevClickedChild.onMouseExit) then
                self.prevClickedChild:onMouseExit(e);
            end
        end
        if (clickedChild) then
            clickedChild._isHovered = true;
            if (clickedChild.onMouseEnter) then
                clickedChild:onMouseEnter(e);
            end
        end
        self.prevClickedChild = clickedChild;
    end

    if (clickedChild) then
        return clickedChild:onMouse(e);
    end
end

function Container:onMouseExit(e)
    if (self.prevClickedChild) then
        self.prevClickedChild._isHovered = false;
        if (self.prevClickedChild.onMouseExit) then
            self.prevClickedChild:onMouseExit(e);
        end
        self.prevClickedChild = nil;
    end
end

function Container:isDraggable(e)
    local clickedChild;

    for _, view in ipairs(self.children) do
        if (functions.testBounds(e.x, e.y, view:getBounds())) then
            if (not (clickedChild and view:getZ() < clickedChild:getZ())) then
                clickedChild = view;
            end
        end
    end

    return clickedChild and clickedChild:isDraggable(e) or View.isDraggable(self, e);

    -- if (clickedChild) then
    --     return clickedChild:isDraggable(e);
    -- else
    --     return self.draggable or false;
    -- end
end

function Container:getZ()
    local res = self._z;
    for _, child in ipairs(self.children) do
        res = math.max(res, child:getZ());
    end
    return res;
end

function Container:setCtx(ctx)
    self.ctx = ctx;
    for _, child in ipairs(self.children) do
        child:setCtx(ctx);
    end
end

-- function Container:dragView(x,y) end;

function Container:new(options)
    options = options or T {};
    options.children = options.children or T {};
    return setmetatable(options or {}, {
        __index = Container,
        __tostring = function() return "Container" end
    });
end

return Container;
