require('common');
local ffi = require('ffi');
local d3d = require('d3d8');

local functions = require('J-GUI/functions');

local ENUM = require('J-GUI/enum');
local DIRECTION = ENUM.DIRECTION;

local View = require('J-GUI/View');
local drawBorderBox = require('J-GUI/borderBox');


local ItemSelector = View:new();

ItemSelector.draggable = true; -- Default setting

ItemSelector._texture = T {};
ItemSelector._expanded = false;
ItemSelector.animationTime = 0.1;
ItemSelector.expandDirection = ENUM.DIRECTION.DOWN

function ItemSelector:onMouseExit(e)
    if (self.pressed) then
        self.pressed = false;
        self.ctx.blockNextMouseUp = true;
    end
end

-- Default function to get value of mode-type variable
function ItemSelector:getValue()
    if (not self.variable) then
        return;
    end

    return self.variable.value;
end

-- Default function to set value
function ItemSelector:setValue(index)
    -- self.variable._track._current = index;
    self.variable:set_index(index);
end

function ItemSelector:getOptions()
    return self.variable;
end

function ItemSelector:getTexture(value)
    local tex = self._texture[value];
    if (not tex) then
        tex = self:lookupTexture(value);
        self._texture[value] = tex;
    end
    return tex;
end

function ItemSelector:lookupTexture(value)
    if (type(value) == 'table') then
        value = value.Name;
    end

    local item = AshitaCore:GetResourceManager():GetItemByName(value, 0);
    -- for k, v in pairs(item) do print('k: '..k..', v: '..v); end
    if (item) then
        return functions.loadItemTexture(item.Id);
    end

    return functions.loadAssetTexture(value .. '.png');
end

function ItemSelector:getZ()
    return self._z + (self._expanded and 1000 or 0);
end

do
    local rect = ffi.new('RECT', { 0, 0, 32, 32 });
    local vec_position = ffi.new('D3DXVECTOR2', { 0, 0, });
    local white = d3d.D3DCOLOR_ARGB(255, 255, 255, 255);

    function ItemSelector:_drawAnimating(pos, scale)
        local options = self:getOptions();
        local width, height;
        if (self.expandDirection == DIRECTION.DOWN or self.expandDirection == DIRECTION.UP) then
            height = #options * 34 * scale + 38;
            -- 6 + 34 * #options + 32
            width = 38;
        else
            height = 38;
            width = #options * 34 * scale + 38;
        end

        if (self.expandDirection == DIRECTION.UP) then
            pos.y = pos.y - height + 38;
        elseif (self.expandDirection == DIRECTION.LEFT) then
            pos.x = pos.x - width + 38;
        end

        drawBorderBox(self.ctx, pos.x, pos.y, width, height, self.color,
            math.max(scale, self.ctx.background_opacity));

        for i, option in ipairs(self:getOptions()) do
            local tex = self:getTexture(option);
            local color = d3d.D3DCOLOR_ARGB(255 * scale, 255, 255, 255);
            if (tex) then
                if (self.expandDirection == DIRECTION.UP) then
                    vec_position.x = pos.x + 3 * self.ctx.vec_scale.x;
                    vec_position.y = pos.y + (34 * (i - 1) + 3) * self.ctx.vec_scale.y * scale;
                elseif (self.expandDirection == DIRECTION.RIGHT) then
                    vec_position.x = pos.x + (34 * i + 3) * self.ctx.vec_scale.x * scale;
                    vec_position.y = pos.y + 3 * self.ctx.vec_scale.y;
                elseif (self.expandDirection == DIRECTION.DOWN) then
                    vec_position.x = pos.x + 3 * self.ctx.vec_scale.x;
                    vec_position.y = pos.y + (34 * i + 3) * self.ctx.vec_scale.y * scale;
                else
                    vec_position.x = pos.x + (34 * (i - 1) + 3) * self.ctx.vec_scale.x * scale;
                    vec_position.y = pos.y + 3 * self.ctx.vec_scale.y;
                end

                self.ctx.sprite:Draw(tex, rect, self.ctx.vec_scale, nil, 0.0, vec_position, color);
            end
        end
        return width, height;
    end

    function ItemSelector:draw()
        if (self.hidden) then return; end
        -- print('debug');
        -- local x = self:getX();
        -- local y = self:getY();
        local pos = self:getPos();

        if (self._animating and os.clock() >= self._animationStart + self.animationTime) then
            self._animating = false;
        end

        if (not self._expanded) then
            if (not self._animating) then
                drawBorderBox(self.ctx, pos.x, pos.y, 38, 38, self.color);
            else
                local scale;

                if (self._animating) then
                    scale = 1 - math.min(os.clock() - self._animationStart, self.animationTime) / self.animationTime;
                else
                    scale = 0;
                end

                local width, height = self:_drawAnimating(pos, scale);

                if (self.expandDirection == DIRECTION.LEFT) then
                    pos.x = pos.x + width - 38;
                elseif (self.expandDirection == DIRECTION.UP) then
                    pos.y = pos.y + height - 38;
                end
            end
        else
            local scale;

            if (self._animating) then
                scale = math.min(os.clock() - self._animationStart, self.animationTime) / self.animationTime;
            else
                scale = 1;
            end

            local width, height = self:_drawAnimating(pos, scale);

            if (self.expandDirection == DIRECTION.LEFT) then
                pos.x = pos.x + width - 38;
            elseif (self.expandDirection == DIRECTION.UP) then
                pos.y = pos.y + height - 38;
            end
        end

        local value = self:getValue();
        if (not value) then return; end
        local tex = self:getTexture(value);
        vec_position.x = pos.x + 3 * self.ctx.vec_scale.x;
        vec_position.y = pos.y + 3 * self.ctx.vec_scale.y;

        self.ctx.sprite:Draw(tex, rect, self.ctx.vec_scale, nil, 0.0, vec_position, white);
    end
end

function ItemSelector:getClickableBounds()
    if (self.hidden) then return { -1, -1, -1, -1 }; end
    if (not self._expanded) then return self:getBounds(); end

    local width, height;
    local options = self:getOptions();
    if (self.expandDirection == DIRECTION.DOWN or self.expandDirection == DIRECTION.UP) then
        height = #options * 34 + 38;
        width = 38;
    else
        height = 38;
        width = #options * 34 + 38;
    end

    local pos = self:getPos();
    if (self.expandDirection == DIRECTION.UP) then
        pos.y = pos.y - height + 38;
    elseif (self.expandDirection == DIRECTION.LEFT) then
        pos.x = pos.x - width + 38;
    end

    return { pos.x, pos.y, pos.x + width, pos.y + height };
end

function ItemSelector:new(options)
    options = options or {};
    options._width = 38;
    options._height = 38;

    return setmetatable(options, { __index = ItemSelector });
end

function ItemSelector:_indexForMouseEvent(e)
    local bounds = self:getClickableBounds();
    local length = #self:getOptions();
    local index;

    -- Figure out what index was clicked
    if (self.expandDirection == DIRECTION.UP) then
        bounds[4] = bounds[4] - 38;
    elseif (self.expandDirection == DIRECTION.RIGHT) then
        bounds[1] = bounds[1] + 38;
    elseif (self.expandDirection == DIRECTION.DOWN) then
        bounds[2] = bounds[2] + 38;
    else
        bounds[3] = bounds[3] - 38;
    end


    if (self.expandDirection == DIRECTION.RIGHT or self.expandDirection == DIRECTION.LEFT) then
        local width = bounds[3] - bounds[1];
        index = math.floor((e.x - bounds[1]) / width * length) + 1;
    else
        local height = bounds[4] - bounds[2];
        index = math.floor((e.y - bounds[2]) / height * length) + 1;
    end

    return index;
end

function ItemSelector:onMouse(e)
    switch(e.message, {
        -- Mouse Move
        [512] = (function()

        end),
        -- Left Button Down
        [513] = (function()
            self.pressed = true;
            e.blocked = true;
        end),
        -- Left Button Up
        [514] = (function()
            if (not self.pressed) then
                return;
            end
            self.pressed = false;
            if (functions.testBounds(e.x, e.y, self:getBounds())) then
                self._expanded = not self._expanded;

                if (self.animated) then
                    if (self._animating) then
                        self._animationStart = os.clock() * 2 - self._animationStart - self.animationTime;
                    else
                        self._animationStart = os.clock();
                    end

                    self._animating = true;
                end

                e.blocked = true;
                return;
            end

            local index = self:_indexForMouseEvent(e);
            self:setValue(index);
            if (self.animated) then
                self._animating = true;
                self._animationStart = os.clock();
            end
            self._expanded = false;

            e.blocked = true;
        end)
    });
end

function ItemSelector:isDraggable(e)
    return self.parent.draggable;
end

return ItemSelector;
