local ffi = require('ffi');
local d3d = require('d3d8');

local View = require('J-GUI/View');
local Button = require('J-GUI/Button');
local drawBorderBox = require('J-GUI/borderBox');
local functions = require('J-GUI/functions');
local text = require('J-GUI/text');

-- local drawBar = require('healing.cure.drawBar');

local HPBar = Button:new();

function HPBar:getHP()
    return 0;
end

function HPBar:getHPP()
    return 0;
end

function HPBar:getCureHPP()
    return 0;
end

function HPBar:getMP()
    return 0;
end

function HPBar:getMPP()
    return 0;
end

function HPBar:getName()
    return '';
end

function HPBar:getDistance()
    return -1;
end

function HPBar:getRaiseData()
end

function HPBar:getEnmityIndicatorOpacity()
end

function HPBar:getBarHeight()
    return self.barHeight or 8;
end

function HPBar:getHeight()
    return 24 + self:getBarHeight();
end

function HPBar:getJobIconTex()
end

do
    local rect = ffi.new('RECT', { 0, 0, 64, 64 });
    -- Default texture rect
    function HPBar:getJobIconRect()
        return rect;
    end
end

do
    local vec_size = ffi.new('D3DXVECTOR2', { 32.0, 32.0, });
    function HPBar:getJobIconSize()
        return vec_size;
    end
end

function HPBar:getIconOpacity()
    return 1.0;
end

function HPBar:getIconTint()
    return 0xFFFFFFFF;
end

do
    local targetColor = 0xFF78C6ED;
    local subTargetColor = 0xFFEDE578;
    local bothColor = 0xFF78ED88;
    local aoeColor = 0xFFE13ED2;

    local highlightTex;
    local rect = ffi.new('RECT', 0, 0, 346, 108);
    local vec_position = ffi.new('D3DXVECTOR2', { 0, 0 });
    local scale = ffi.new('D3DXVECTOR2', { 1.0, 1.0 });

    function HPBar:drawTargetHighlight(pos)
        local isTarget = self:getIsTarget();
        local isSubtarget = self:getIsSubtarget();
        local isAoeTarget = self:getIsAoeTarget();

        if (not (isTarget or isSubtarget or isAoeTarget)) then
            return;
        end
        local color;
        if (isAoeTarget) then
            color = aoeColor;
        elseif (isTarget and isSubtarget) then
            color = bothColor;
        elseif (isTarget) then
            color = targetColor;
        elseif (isSubtarget) then
            color = subTargetColor;
        end

        highlightTex = highlightTex or functions.loadAssetTexture(addon.path .. 'assets/Selector.png');
        scale.x = (self:getWidth() + 4) / 346;
        scale.y = (self:getHeight() + 4) / 108;

        vec_position.x = pos.x - 2;
        vec_position.y = pos.y - 2;

        self.ctx.sprite:Draw(highlightTex, rect, scale, nil, 0.0, vec_position, color);
    end
end

local hpColor = d3d.D3DCOLOR_ARGB(0.8 * 255, 242, 140, 140);
local mpColor = 0xffd1d28e;
local cureHpColor = T { 204, 118, 118 };
local white = T { 255, 255, 255 };
local bar;

local rect = ffi.new('RECT', { 0, 0, 1, 1 });
local vec_position = ffi.new('D3DXVECTOR2', { 0, 0 });
local hp_scale = ffi.new('D3DXVECTOR2', { 1, 1 });
local hp2_scale = ffi.new('D3DXVECTOR2', { 1, 1 });

local mp_scale = ffi.new('D3DXVECTOR2', { 1.0, 1.0 });

function HPBar:draw()
    local pos = self:getPos();
    local height = self:getBarHeight();
    local width = self:getWidth() - 33;
    local hp = self:getHP();
    local hpp = self:getHPP() / 100;
    local cureHpp = self:getCureHPP() / 100;

    local mp = self:getMP();
    local mpp = self:getMPP() / 100;

    local tp = self:getTP();


    self:drawEnmityIndicator(pos);

    self:drawJobIcon(pos);

    local x, y;
    x = pos.x + 33 * self.ctx.vec_scale.x;

    -- Start HP Bar
    y = pos.y + (13 - height / 2) * self.ctx.vec_scale.y;

    bar = bar or functions.loadAssetTexture('box-center-white.png');

    drawBorderBox(self.ctx, x, y, width, height, white);

    hp_scale.x = math.ceil(hpp * (width - 4)) * self.ctx.vec_scale.x;
    hp_scale.y = (height - 4) * self.ctx.vec_scale.y;

    hp2_scale.x = math.ceil(cureHpp * (width - 4)) * self.ctx.vec_scale.x;
    hp2_scale.y = hp_scale.y;

    vec_position.x = x + 2 * self.ctx.vec_scale.x;
    vec_position.y = y + 2 * self.ctx.vec_scale.x;

    if (hp_scale.x + hp2_scale.x > (width - 4) * self.ctx.vec_scale.x) then
        hp2_scale.x = (width - 4) * self.ctx.vec_scale.x - hp_scale.x;
    end

    self.ctx.sprite:Draw(bar, rect, hp_scale, nil, 0.0, vec_position, hpColor);

    if (hp2_scale.x > 0) then
        local opacity = 153 * (math.sin(3 * os.clock()) + 1.3) / 2;
        local color = d3d.D3DCOLOR_ARGB(opacity, cureHpColor:unpack());
        vec_position.x = vec_position.x + hp_scale.x;
        self.ctx.sprite:Draw(bar, rect, hp2_scale, nil, 0.0, vec_position, color);
    end
    -- End HP Bar

    -- Start MP Bar
    local mpHeight = height * 3 / 4 + 1;
    local mpWidth = width - 33;
    x = pos.x + 66;
    y = pos.y + (13 + height / 2) * self.ctx.vec_scale.y;
    drawBorderBox(self.ctx, x, y, mpWidth, mpHeight, white);

    mp_scale.x = math.ceil(mpp * (mpWidth - 4));
    mp_scale.y = mpHeight - 4;

    vec_position.x = x + 2;
    vec_position.y = y + 2;

    self.ctx.sprite:Draw(bar, rect, mp_scale, nil, 0.0, vec_position, mpColor);
    -- End MP Bar

    -- Start Name
    x = pos.x + 33;
    y = pos.y;
    text.write(x, y, 1, self:getName());
    text.write(x, y, 1, self:getName());
    -- End Name

    -- Start HP
    -- y = pos.y + (5 + height) * self.ctx.vec_scale.y;
    y = pos.y + 1;
    x = pos.x + (33 + width - text.size(1, tostring(hp))) * self.ctx.vec_scale.x;
    local color;
    if (hpp > 0.75) then
        color = 0xFFFFFFFF;
    elseif (hpp > 0.50) then
        color = 0xFFD4D76B;
    elseif (hpp > 0.25) then
        color = 0xFFFFC282;
    else
        color = 0xFFFF8282;
    end
    text.write(
        x,
        y,
        1,
        tostring(hp),
        0xFFFFFFFF
    );
    text.write(
        x,
        y,
        1,
        tostring(hp),
        color
    );
    -- End HP

    -- Start MP
    y = pos.y + 5 + height + mpHeight;
    x = pos.x + (33 + width - text.size(1, tostring(mp)));

    text.write(
        x,
        y,
        1,
        tostring(mp)
    );
    text.write(
        x,
        y,
        1,
        tostring(mp)
    );
    -- End MP

    -- Start TP
    -- y = pos.y + height + 5 + mpHeight;
    x = pos.x + 33;
    local tint = tp >= 1000 and 0xFF00FF00 or 0xFFFFFFFF;
    text.write(
        x,
        y,
        1,
        tostring(tp),
        tint
    );
    text.write(
        x,
        y,
        1,
        tostring(tp),
        tint
    );
    -- End TP

    -- Start Distance
    x = pos.x + 33 + width + 5;
    local distance = self:getDistance();
    if (distance >= 0) then
        text.write(
            x,
            y,
            1,
            string.format('%.1f', distance)
        );
        text.write(
            x,
            y,
            1,
            string.format('%.1f', distance)
        );
    end
    -- End Distance


    self:drawTargetHighlight(pos);


    -- if HP is 0, draw raise overlay
    local raiseData = self:getRaiseData();
    if (raiseData) then
        -- y = pos.y;
        -- x = pos.x;
        self:drawRaiseOverlay(pos, raiseData);
    end
end

do
    local vec_scale = ffi.new('D3DXVECTOR2', { 1.0, 1.0, });
    local red = T { 255, 100, 100 };
    function HPBar:drawEnmityIndicator(pos)
        local opacity = self:getEnmityIndicatorOpacity();
        if (opacity == 0) then return; end

        local size = self:getJobIconSize();

        drawBorderBox(self.ctx, pos.x, pos.y, size.x, size.y, red, opacity);
    end

    function HPBar:drawJobIcon(pos)
        local iconTex = self:getJobIconTex();

        if (not iconTex) then return; end

        local opacity = self:getIconOpacity();
        local tint = self:getIconTint();

        local rect = self:getJobIconRect();
        local size = self:getJobIconSize();

        vec_scale.x = size.x / rect.right * self.ctx.vec_scale.x;
        vec_scale.y = size.y / rect.bottom * self.ctx.vec_scale.y;

        vec_position.x = pos.x + ((32 - size.x) / 2) * self.ctx.vec_scale.x;
        vec_position.y = pos.y + ((32 - size.y) / 2) * self.ctx.vec_scale.y;

        local alpha = bit.rshift(0xFF000000, 24) * opacity;
        local color = bit.lshift(math.min(alpha, 255), 24) + bit.band(tint, 0xFFFFFF);

        -- Debug, uncomment to show icon borders
        -- drawBorderBox(self.ctx, vec_position.x, vec_position.y, 64 * vec_scale.x, 64 * vec_scale.y, T { 255, 255, 255 },
        --     1.0, 0xF);
        self.ctx.sprite:Draw(iconTex, rect, vec_scale, nil, 0.0, vec_position, color);
    end

    function HPBar:drawRaiseOverlay(pos, data)
        local width = self:getWidth() + 39 * self.ctx.vec_scale.x;
        local height = self:getHeight() + 2 * self.ctx.vec_scale.y;

        drawBorderBox(self.ctx, pos.x - self.ctx.vec_scale.x, pos.y - self.ctx.vec_scale.y, width, height, data.color);

        pos.y = pos.y + (16 - 7 * #data.text) * self.ctx.vec_scale.y;
        pos.x = pos.x + 3 * self.ctx.vec_scale.x;

        for row, line in ipairs(data.text) do
            text.write(pos.x, pos.y + 14 * (row - 1) * self.ctx.vec_scale.y, 1, line);
            text.write(pos.x, pos.y + 14 * (row - 1) * self.ctx.vec_scale.y, 1, line);
        end
    end
end

function HPBar:new(options)
    options = options or {};
    return setmetatable(options, {
        __index = HPBar,
        __tostring = function() return "HPBar" end
    });
end

return HPBar;
