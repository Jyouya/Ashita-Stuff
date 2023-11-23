local functions = require('J-GUI/functions');

local d3d = require('d3d8');
local ffi = require('ffi');
local math = require('math');

local corner, side;

local corner_rect = ffi.new('RECT', { 0, 0, 4, 4 });
local vec_position = ffi.new('D3DXVECTOR2', { 0, 0, });
local rot_center = ffi.new('D3DXVECTOR2', { 0, 0, });

local function drawBlueBorder(ctx, x, y, w, h, color, opacity)
    corner = corner or functions.loadAssetTexture('blue-box-corner.png');
    side = side or functions.loadAssetTexture('blue-box-side.png');

    x = math.floor(x);
    y = math.floor(y);
    w = math.ceil(w);
    h = math.ceil(h);

    color = type(color) == 'table' and
        d3d.D3DCOLOR_ARGB((opacity or ctx.background_opacity) * 255,
            (color or ctx.background_color):unpack())
        or color;

    local tb_rect = ffi.new('RECT', { 0, 0, w - 8, 3 });

    local lr_rect = ffi.new('RECT', { 0, 0, h - 8, 3 });

    rot_center.x = 0.0;
    rot_center.y = 0.0;

    -- Top Left Corner?
    vec_position.x = x;
    vec_position.y = y;
    ctx.sprite:Draw(corner, corner_rect, ctx.vec_scale, rot_center, 0.0, vec_position, color);

    -- Top Side?
    vec_position.x = vec_position.x + 4 ;
    ctx.sprite:Draw(side, tb_rect, ctx.vec_scale, rot_center, 0.0, vec_position, color);

    -- Top Right Corner?
    vec_position.x = vec_position.x + (w - 4) ;
    ctx.sprite:Draw(corner, corner_rect, ctx.vec_scale, rot_center, -math.pi / 2, vec_position, color);

    -- Right Side?
    vec_position.y = vec_position.y + 4 ;
    ctx.sprite:Draw(side, lr_rect, ctx.vec_scale, rot_center, -math.pi / 2, vec_position, color);

    -- Bottom Right Corner?
    vec_position.y = vec_position.y + (h - 4) ;
    ctx.sprite:Draw(corner, corner_rect, ctx.vec_scale, rot_center, math.pi, vec_position, color);

    -- Bottom Side?
    vec_position.x = vec_position.x - 4 ;
    ctx.sprite:Draw(side, tb_rect, ctx.vec_scale, rot_center, math.pi, vec_position, color);

    -- Bottom Left Corner?
    vec_position.x = vec_position.x - (w - 4) ;
    ctx.sprite:Draw(corner, corner_rect, ctx.vec_scale, rot_center, math.pi / 2, vec_position, color);

    -- Left Side?
    vec_position.y = vec_position.y - 4 ;
    ctx.sprite:Draw(side, lr_rect, ctx.vec_scale, rot_center, math.pi / 2, vec_position, color);
end

return drawBlueBorder;
