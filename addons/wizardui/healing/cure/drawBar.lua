local corner;
local ffi = require('ffi');
local d3d = require('d3d8');
local math = require('math');

local functions = require('J-GUI/functions');

local side;
local center;

local vec_position = ffi.new('D3DXVECTOR2', { 0, 0, });
local rot_center = ffi.new('D3DXVECTOR2', { 0, 0, });

local corner_rect = ffi.new('RECT', { 0, 0, 2, 2, });

local function drawLeftBar(ctx, x, y, w, h, color, opacity)
    corner = corner or functions.loadAssetTexture('box-corner.png');
    side = side or functions.loadAssetTexture('box-side.png');
    center = center or functions.loadAssetTexture('box-center-white.png');
    opacity = opacity or ctx.background_opacity;

    x = math.floor(x);
    y = math.floor(y);
    w = math.ceil(w);
    h = math.ceil(h);

    -- print(x,y,w,h);

    color = d3d.D3DCOLOR_ARGB(opacity * 255, table.unpack(color));

    -- Side rect
    local tb_rect = ffi.new('RECT', { 0, 0, w - 2, 2 });

    local lr_rect = ffi.new('RECT', { 0, 0, h - 4, math.min(2, w) });

    local center_rect = ffi.new('RECT', { 0, 0, w - 2, h - 4 });

    rot_center.x = 0.0;
    rot_center.y = 0.0;

    vec_position.x = x;
    vec_position.y = y;

    if (w > 2) then
        -- Top Left
        if (w > 1) then
            ctx.sprite:Draw(corner, corner_rect, ctx.vec_scale, rot_center, 0.0, vec_position, color);
        end

        -- Top
        vec_position.x = x + 2 ;
        ctx.sprite:Draw(side, tb_rect, ctx.vec_scale, rot_center, 0.0, vec_position, color);

        -- Center
        vec_position.y = y + 2 ;
        ctx.sprite:Draw(center, center_rect, ctx.vec_scale, rot_center, 0.0, vec_position, color);

        -- Bottom
        vec_position.x = x + w ;
        vec_position.y = y + h ;
        ctx.sprite:Draw(side, tb_rect, ctx.vec_scale, rot_center, math.pi, vec_position, color);

        -- Bottom Left
        vec_position.x = x;
        if (w > 1) then
            ctx.sprite:Draw(corner, corner_rect, ctx.vec_scale, rot_center, math.pi / 2, vec_position, color);
        end
    end

    -- Left
    vec_position.x = x
    vec_position.y = y + (h - 2) ;
    ctx.sprite:Draw(side, lr_rect, ctx.vec_scale, rot_center, math.pi / 2, vec_position, color);
end

local function drawCenterBar(ctx, x, y, w, h, color, opacity)
    side = side or functions.loadAssetTexture('box-side.png');
    center = center or functions.loadAssetTexture('box-center-white.png');
    opacity = opacity or ctx.background_opacity;

    x = math.floor(x);
    y = math.floor(y);
    w = math.ceil(w);
    h = math.ceil(h);

    color = d3d.D3DCOLOR_ARGB(opacity * 255, table.unpack(color));

    local tb_rect = ffi.new('RECT', { 0, 0, w, 2 });
    local center_rect = ffi.new('RECT', { 0, 0, w, h - 4 });

    -- Top
    vec_position.x = x;
    vec_position.y = y;
    ctx.sprite:Draw(side, tb_rect, ctx.vec_scale, rot_center, 0.0, vec_position, color);

    -- Center
    vec_position.y = vec_position.y + 2 ;
    ctx.sprite:Draw(center, center_rect, ctx.vec_scale, rot_center, 0.0, vec_position, color);

    -- Bottom
    vec_position.x = x + w ;
    vec_position.y = y + h ;
    ctx.sprite:Draw(side, tb_rect, ctx.vec_scale, rot_center, math.pi, vec_position, color);
end

local function drawRightBar(ctx, x, y, w, h, color, opacity)
    corner = corner or functions.loadAssetTexture('box-corner.png');
    side = side or functions.loadAssetTexture('box-side.png');
    center = center or functions.loadAssetTexture('box-center-white.png');
    opacity = opacity or ctx.background_opacity;

    x = math.floor(x);
    y = math.floor(y);
    w = math.ceil(w);
    h = math.ceil(h);

    color = d3d.D3DCOLOR_ARGB(opacity * 255, table.unpack(color));

    -- Side rect
    local tb_rect = ffi.new('RECT', { 0, 0, w - 2, 2 });

    local lr_rect = ffi.new('RECT', { 0, 0, h - 4, math.min(w, 2) });

    local center_rect = ffi.new('RECT', { 0, 0, w - 2, h - 4 });

    rot_center.x = 0.0;
    rot_center.y = 0.0;

    vec_position.x = x;
    vec_position.y = y;
    if (w > 2) then
        -- Top
        ctx.sprite:Draw(side, tb_rect, ctx.vec_scale, rot_center, 0.0, vec_position, color);

        -- Top Right
        vec_position.x = vec_position.x + w ;
        ctx.sprite:Draw(corner, corner_rect, ctx.vec_scale, rot_center, -math.pi / 2, vec_position, color);

        -- Right
        vec_position.y = vec_position.y + 2 ;
        ctx.sprite:Draw(side, lr_rect, ctx.vec_scale, rot_center, -math.pi / 2, vec_position, color);

        -- Bottom Right
        vec_position.y = vec_position.y + (h - 2) ;
        ctx.sprite:Draw(corner, corner_rect, ctx.vec_scale, rot_center, math.pi, vec_position, color);

        -- Bottom
        vec_position.x = x + (w - 2) ;
        ctx.sprite:Draw(side, tb_rect, ctx.vec_scale, rot_center, math.pi, vec_position, color);

        -- Center
        vec_position.y = y + 2 ;
        vec_position.x = x;
        ctx.sprite:Draw(center, center_rect, ctx.vec_scale, rot_center, 0.0, vec_position, color);
    else
        -- Top Right
        if (w > 1) then
            ctx.sprite:Draw(corner, corner_rect, ctx.vec_scale, rot_center, -math.pi / 2, vec_position, color);
        end

        -- Right
        vec_position.y = y + 2 ;
        ctx.sprite:Draw(side, lr_rect, ctx.vec_scale, rot_center, -math.pi / 2, vec_position, color);

        -- Bottom Right
        vec_position.y = y + (h - 2) ;
        if (w > 1) then
            ctx.sprite:Draw(corner, corner_rect, ctx.vec_scale, rot_center, math.pi, vec_position, color);
        end
    end
end

local function drawEmptyBox(ctx, x, y, w, h, background_color, opacity, corner_mask, white)
    corner_mask = corner_mask or 0;

    corner = corner or functions.loadAssetTexture('box-corner.png');
    side = side or functions.loadAssetTexture('box-side.png');
    center = center or functions.loadAssetTexture('box-center.png');

    x = math.floor(x);
    y = math.floor(y);
    w = math.ceil(w);
    h = math.ceil(h);
    -- print(corner);

    local color = d3d.D3DCOLOR_ARGB((opacity or ctx.background_opacity) * 255,
        (background_color or ctx.background_color):unpack());

    -- Side rect
    local tb_rect = ffi.new('RECT', { 0, 0, w - 4, 2 });

    local lr_rect = ffi.new('RECT', { 0, 0, h - 4, 2 });

    -- local center_rect = ffi.new('RECT', { 0, 0, w - 4, h - 4 });

    rot_center.x = 0.0;
    rot_center.y = 0.0;

    -- Top Left Corner?
    vec_position.x = x;
    vec_position.y = y;
    ctx.sprite:Draw(bit.band(corner_mask, 1) > 0 and square or corner, corner_rect, ctx.vec_scale, rot_center, 0.0,
        vec_position, color);

    -- Top Side?
    vec_position.x = vec_position.x + 2 ;
    ctx.sprite:Draw(side, tb_rect, ctx.vec_scale, rot_center, 0.0, vec_position, color);

    -- Top Right Corner?
    vec_position.x = vec_position.x + (w - 2) ;
    ctx.sprite:Draw(bit.band(corner_mask, 2) > 0 and square or corner, corner_rect, ctx.vec_scale, rot_center,
        -math.pi / 2,
        vec_position, color);

    -- Right Side?
    vec_position.y = vec_position.y + 2 ;
    ctx.sprite:Draw(side, lr_rect, ctx.vec_scale, rot_center, -math.pi / 2, vec_position, color);

    -- Bottom Right Corner?
    vec_position.y = vec_position.y + (h - 2) ;
    ctx.sprite:Draw(bit.band(corner_mask, 4) > 0 and square or corner, corner_rect, ctx.vec_scale, rot_center, math.pi,
        vec_position, color);

    -- Bottom Side?
    vec_position.x = vec_position.x - 2 ;
    ctx.sprite:Draw(side, tb_rect, ctx.vec_scale, rot_center, math.pi, vec_position, color);

    -- Bottom Left Corner?
    vec_position.x = vec_position.x - (w - 2) ;
    ctx.sprite:Draw(bit.band(corner_mask, 8) > 0 and square or corner, corner_rect, ctx.vec_scale, rot_center,
        math.pi / 2,
        vec_position, color);

    -- Left Side?
    vec_position.y = vec_position.y - 2 ;
    ctx.sprite:Draw(side, lr_rect, ctx.vec_scale, rot_center, math.pi / 2, vec_position, color);
end


return {
    left = drawLeftBar,
    center = drawCenterBar,
    right = drawRightBar,
    empty = drawEmptyBox,
};
