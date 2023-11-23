local ffi = require('ffi');
local d3d = require('d3d8');
local math = require('math');

local functions = require('J-GUI/functions');

local corner;
local side;
local center;
local square;
local vec_position = ffi.new('D3DXVECTOR2', { 0, 0, });
local rot_center = ffi.new('D3DXVECTOR2', { 0, 0, });

local corner_rect = ffi.new('RECT', { 0, 0, 2, 2, });


local function drawBorderBox(ctx, x, y, w, h, background_color, opacity, rounded)
    corner = corner or functions.loadAssetTexture('box-corner.png');
    side = side or functions.loadAssetTexture('box-side.png');
    center = center or functions.loadAssetTexture('box-center.png');
    square = square or functions.loadAssetTexture('square-corner.png');

    x = math.floor(x);
    y = math.floor(y);
    w = math.ceil(w);
    h = math.ceil(h);
    -- print(corner);

    local color = d3d.D3DCOLOR_ARGB((opacity or ctx.background_opacity) * 255,
        (background_color or ctx.background_color):unpack());

    -- Side rect
    local tb_rect = ffi.new('RECT', { 0, 0, w - 4, 2 });

    local lr_rect = ffi.new('RECT', { 0, 0, h - 2, 2 });

    local center_rect = ffi.new('RECT', { 0, 0, w - 4, h - 2 });

    rot_center.x = 0.0;
    rot_center.y = 0.0;

    -- Top Right Corner?
    vec_position.x = x + w ;
    vec_position.y = y;

    -- Right Side?
    ctx.sprite:Draw(side, lr_rect, ctx.vec_scale, rot_center, -math.pi / 2, vec_position, color);


    -- Bottom Right Corner?
    vec_position.y = vec_position.y + h ;
    ctx.sprite:Draw(rounded and corner or square, corner_rect, ctx.vec_scale, rot_center, math.pi,
        vec_position, color);

    -- Bottom Side?
    vec_position.x = vec_position.x - 2 ;
    ctx.sprite:Draw(side, tb_rect, ctx.vec_scale, rot_center, math.pi, vec_position, color);

    -- Bottom Left Corner?
    vec_position.x = vec_position.x - (w - 2) ;
    ctx.sprite:Draw(rounded and corner or square, corner_rect, ctx.vec_scale, rot_center,
        math.pi / 2,
        vec_position, color);

    -- Left Side?
    vec_position.y = vec_position.y - 2 ;
    ctx.sprite:Draw(side, lr_rect, ctx.vec_scale, rot_center, math.pi / 2, vec_position, color);

    -- -- Center
    vec_position.x = vec_position.x + 2 ;
    vec_position.y = vec_position.y - (h - 2) ;
    ctx.sprite:Draw(center, center_rect, ctx.vec_scale, nil, 0.0, vec_position, color);
end


return drawBorderBox;
