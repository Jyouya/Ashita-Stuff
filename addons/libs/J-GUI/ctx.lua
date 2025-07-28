require('common');
local event     = require('event');
local functions = require('J-GUI/functions');

local d3d       = require('d3d8');
local ffi       = require('ffi');

local C         = ffi.C;
local d3d8dev   = d3d.get_device();

ffi.cdef [[
    short GetAsyncKeyState(int vKey);
]]

local user32 = ffi.load("user32");

local VK_SHIFT = 0x10;


local ctx = {
    children = T {},
    vec_position = ffi.new('D3DXVECTOR2', { 0, 0, }),
    vec_scale = ffi.new('D3DXVECTOR2', { 1.0, 1.0, }),
    background_color = T { 255, 255, 255 }, -- RGB
    background_opacity = 0.7,
    _drag = T {
        shiftDown = false,
        isDragging = false,
        draggedView = nil, -- noop, but here so I remember that this table can have this.
        dragX = 0,
        dragY = 0
    },
    prerender = event:new()
};

function ctx.reset()
    ctx.children = T {};
    ctx.vec_position = ffi.new('D3DXVECTOR2', { 0, 0, });
    ctx.scale = 1.0;
    ctx.background_color = T { 255, 255, 255 }; -- RGB
    ctx.background_opacity = 0.7;
    ctx._drag = T {
        shiftDown = false,
        isDragging = false,
        draggedView = nil, -- noop, but here so I remember that this table can have this.
        dragX = 0,
        dragY = 0
    };
end

function ctx.isKeyPressed(vKey)
    -- Check the high bit of the return value
    return bit.band(user32.GetAsyncKeyState(vKey), 0x8000) ~= 0;
end

function ctx.addView(view)
    view.parent = ctx;
    view:setCtx(ctx);

    ctx.children:insert(view);
end

function ctx.removeView(view)
    for i, v in ipairs(ctx.children) do
        if v == view then
            table.remove(ctx.children, i)
            break
        end
    end
end

-- function ctx:getChildX(child)
--     return child._x;
-- end

-- function ctx:getChildY(child)
--     return child._y;
-- end

function ctx:getChildPos(child)
    return { x = child._x, y = child._y };
end

function ctx.dragView(_, view, x, y)
    view._x = x;
    view._y = y;
end

local prevClickedChild;
ashita.events.register('mouse', 'mouse_cb', function(e)
    -- Test if click is inside a child
    if (ctx.isKeyPressed(VK_SHIFT)) then
        switch(e.message, {
            [512] = (function()
                if (ctx._drag.isDragging) then
                    ctx._drag.draggedView:drag(e.x - ctx._drag.dragX, e.y - ctx._drag.dragY);
                end
            end),
            [513] = (function()
                -- Test if we're inside a dragable window
                local clickedChild;
                for _, view in ipairs(ctx.children) do
                    if (functions.testBounds(e.x, e.y, view:getBounds())) then
                        if (not (clickedChild and view:getZ() < clickedChild:getZ()) and view:isDraggable(e)) then
                            clickedChild = view;
                        end
                    end
                end
                if (clickedChild) then
                    ctx._drag.isDragging = true;
                    local pos = clickedChild:getPos();
                    ctx._drag.dragX = e.x - pos.x;
                    ctx._drag.dragY = e.y - pos.y;
                    ctx._drag.draggedView = clickedChild;

                    e.blocked = true;
                end
            end),
            [514] = (function()
                if (ctx._drag.isDragging) then
                    ctx._drag.isDragging = false;
                    if (ctx._drag.draggedView) then
                        ctx._drag.draggedView:onDragFinish();
                    end
                    ctx._drag.draggedView = nil;
                    e.blocked = true;
                end
            end)
        });
    end

    if (ctx.blockNextMouseUp and e.message == 514) then
        ctx.blockNextMouseUp = false;
        e.blocked = true;
        return;
    end

    -- Handle mouse event if we're not dragging
    if (not ctx._drag.isDragging and not e.blocked) then
        local clickedChild;

        for _, view in ipairs(ctx.children) do
            if (view.onMouse) then
                if (functions.testBounds(e.x, e.y, view:getClickableBounds())) then
                    -- print(_);
                    if (not (clickedChild and view:getZ() < clickedChild:getZ())) then
                        clickedChild = view;
                    end
                end
            end
        end

        if (clickedChild ~= prevClickedChild) then
            if (prevClickedChild) then
                prevClickedChild._isHovered = false;
                if (prevClickedChild.onMouseExit) then
                    prevClickedChild:onMouseExit(e);
                end
            end
            if (clickedChild) then
                clickedChild._isHovered = true;
                if (clickedChild.onMouseEnter) then
                    clickedChild:onMouseEnter(e);
                end
            end
            prevClickedChild = clickedChild;
        end

        if (clickedChild) then
            return clickedChild:onMouse(e);
        end
    end
end);

ashita.events.register('key', 'key_shift_callback_ctx', function(e)
    -- Key: VK_SHIFT
    if (e.wparam == 0x10) then
        ctx._drag.shiftDown = not (bit.band(e.lparam, bit.lshift(0x8000, 0x10)) == bit.lshift(0x8000, 0x10));

        if (not ctx._drag.shiftDown) then
            ctx._drag.isDragging = false;
        end
        return;
    end
end);

ashita.events.register('d3d_present', 'present_cb', function()
    ctx.prerender:trigger();

    if (ctx.sprite == nil) then return; end
    -- Insertion sort.  Should be fast.
    ctx.children = functions.zSort(ctx.children);

    -- print('before');
    ctx.sprite:Begin();

    for _, view in ipairs(ctx.children) do
        view:draw();
    end
    ctx.sprite:End();
end);

local scaledDraw;
do
    -- local scaledRect = ffi.new('RECT', { 0, 0, 0, 0 });
    local scaledScale = ffi.new('D3DXVECTOR2', { 0, 0 });
    local scaledPosition = ffi.new('D3DXVECTOR2', { 0, 0 });
    local defaultScale = ffi.new('D3DXVECTOR2', { 1, 1 });

    function scaledDraw(_, tex, rect, scale, rot_center, rotation, position, color)
        scale = scale or defaultScale;
        local s = ctx.scale;

        scaledScale.x = scale.x * s;
        scaledScale.y = scale.y * s;

        scaledPosition.x = position.x * s;
        scaledPosition.y = position.y * s;

        ctx._sprite:Draw(tex, rect, scaledScale, rot_center, rotation, scaledPosition, color);
    end
end

function ctx.forceReload()
    ctx.reset();
    local sprite_ptr = ffi.new('ID3DXSprite*[1]');
    if (C.D3DXCreateSprite(d3d8dev, sprite_ptr) ~= C.S_OK) then
        error('failed to make sprite obj');
    end

    ctx.sprite = d3d.gc_safe_release(ffi.cast('ID3DXSprite*', sprite_ptr[0]));

    -- ctx.sprite = {
    --     Draw = scaledDraw,
    --     Begin = function() ctx._sprite:Begin() end,
    --     End = function() ctx._sprite:End() end
    -- };

    -- local line_ptr = ffi.new('ID3DXLine*[1]');
    -- if (C.D3DXCreateLine(d3d8dev, line_ptr) ~= C.S_OK) then
    --     error('failed to make line obj');
    -- end

    -- ctx.line = d3d.gc_safe_release(ffi.cast('ID3DXLine*', line_ptr[0]));
end

ashita.events.register('load', 'load_cb', function()
    ctx.forceReload();
end);



ashita.events.register('unload', 'unload_cb', function()
    ctx.sprite = nil;
end);


return ctx;
