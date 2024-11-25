require('common');

local View = require('J-GUI/View');
local text = require('J-GUI/text')

local Label = View:new();

Label.draggable = true;

function Label:draw()
    if (self.hidden) then return; end

    local pos = self:getPos();

    local value = self:getValue();

    text.write(pos.x, pos.y, 1, value);
    text.write(pos.x, pos.y, 1, value);
end

function Label:getValue()
    return self.variable and self.variable.value or self.value;
end

do
    local function textSize(string)
        return text.size(1, string);
    end

    function Label:getWidth()
        if (self.isFixedWidth) then
            if (self._width) then
                return self._width;
            end
        end
        return text.size(1, self:getValue());
    end
end

function Label:new(options)
    options = options or {};
    options._height = 12;

    return setmetatable(options, { __index = Label });
end

return Label;
