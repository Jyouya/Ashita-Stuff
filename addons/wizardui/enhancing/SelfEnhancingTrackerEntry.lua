local Button = require('J-GUI/Button');
local text = require('J-GUI/text');
local functions = require('J-GUI/functions');
local d3d = require('d3d8');
local ffi = require('ffi');

local drawBox = require('enhancing.menuEntryBorderBox');
local drawBorderBox = require('J-GUI/borderBox');

local SelfEnhancingTrackerEntry = Button:new();

function SelfEnhancingTrackerEntry:getWidth()
    return self.parent:getWidth();
end

function SelfEnhancingTrackerEntry:getHeight()
    return 24;
end

function SelfEnhancingTrackerEntry:getIconTexture()
end

do
    local rect = ffi.new('RECT', { 0, 0, 32, 32 });
    -- Default texture rect
    function SelfEnhancingTrackerEntry:getStatusIconRect()
        return rect;
    end
end

do
    local vec_size = ffi.new('D3DXVECTOR2', { 16.0, 16.0, });
    function SelfEnhancingTrackerEntry:getStatusIconSize()
        return vec_size;
    end
end

function SelfEnhancingTrackerEntry:getIconOpacity()
    return 1.0;
end

function SelfEnhancingTrackerEntry:getIconTint()
    return 0xFFFFFFFF;
end

local white = T { 255, 255, 255 };
function SelfEnhancingTrackerEntry:getColor()
    return self.color or white;
end

function SelfEnhancingTrackerEntry:getText()
    return '';
end

do
    local vec_scale = ffi.new('D3DXVECTOR2', { 1.0, 1.0, });
    local vec_position = ffi.new('D3DXVECTOR2', { 0, 0, });

    function SelfEnhancingTrackerEntry:draw(last)
        -- print('debug');
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

        pos.x = pos.x + 4;
        pos.y = pos.y - 2;

        self:drawStatusIcon(pos);

        pos.x = pos.x + 19;
        pos.y = pos.y + 7;

        self:drawText(pos);
    end

    function SelfEnhancingTrackerEntry:drawStatusIcon(pos)
        local iconTex = self:getStatusIconTexture();

        if (not iconTex) then return; end

        local opacity = self:getIconOpacity();
        local tint = self:getIconTint();

        local rect = self:getStatusIconRect();
        local size = self:getStatusIconSize();

        vec_scale.x = size.x / rect.right * self.ctx.vec_scale.x;
        vec_scale.y = size.y / rect.bottom * self.ctx.vec_scale.y;

        vec_position.x = pos.x;
        vec_position.y = pos.y + ((26 - size.y) / 2) * self.ctx.vec_scale.y;

        local alpha = bit.rshift(0xFF000000, 24) * opacity;
        local color = bit.lshift(math.min(alpha, 255), 24) + bit.band(tint, 0xFFFFFF);

        -- Debug, uncomment to show icon borders
        -- drawBorderBox(self.ctx, vec_position.x, vec_position.y, 32 * vec_scale.x, 32 * vec_scale.y, T { 255, 255, 255 },
        --     1.0, 0xF);
        self.ctx.sprite:Draw(iconTex, rect, vec_scale, nil, 0.0, vec_position, color);
    end

    function SelfEnhancingTrackerEntry:drawText(pos)
        local str = self:getText();
        text.write(pos.x, pos.y, 1, str);
    end
end



function SelfEnhancingTrackerEntry:new(options)
    options = options or {};

    return setmetatable(options, { __index = SelfEnhancingTrackerEntry });
end

return SelfEnhancingTrackerEntry;
