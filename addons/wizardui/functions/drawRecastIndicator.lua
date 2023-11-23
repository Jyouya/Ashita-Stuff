local BezierSpline = require('J-GUI.spline').BezierSpline;
local d3d = require('d3d8');

local controlPoints = {
    -- Top
    { 19,   0 },
    { 26.5, 0 },
    { 26.5, 0 },
    { 34,   0 },

    -- Corner
    { 34,   0 },
    { 36,   0 },
    { 38,   2 },
    { 38,   4 },

    -- Right
    { 38,   4 },
    { 38,   19 },
    { 38,   19 },
    { 38,   34 },

    -- Corner
    { 38,   34 },
    { 38,   36 },
    { 36,   38 },
    { 34,   38 },

    -- Bottom
    { 34,   38 },
    { 19,   38 },
    { 19,   38 },
    { 4,    38 },

    -- Corner
    { 4,    38 },
    { 2,    38 },
    { 0,    36 },
    { 0,    34 },

    -- Left
    { 0,    34 },
    { 0,    19 },
    { 0,    19 },
    { 0,    4 },

    -- Corner
    { 0,    4 },
    { 0,    2 },
    { 2,    0 },
    { 4,    0 },

    -- Top
    { 4,    0 },
    { 11.5, 0 },
    { 11.5, 0 },
    { 19,   0 }
};

-- local debug = T {
--     -- Top 1
--     { width / 2,               0 },
--     { (width - 4) * 3 / 4 - 2, 0 },
--     { (width - 4) * 3 / 4 - 2, 0 },
--     { width - 4,               0 },

--     -- Corner
--     { width - 4,               0 },
--     { width - 2,               0 },
--     { width,                   2 },
--     { width,                   4 },

--     -- Right
--     { width,                   4 },
--     { width,                   height / 2 },
--     { width,                   height / 2 },
--     { width,                   height - 4 },

--     -- Corner
--     { width,                   height - 4 },
--     { width,                   height - 2 },
--     { width - 2,               height },
--     { width - 4,               height },

--     -- Bottom
--     { width - 4,               height },
--     { width / 2,               height },
--     { width / 2,               height },
--     { 4,                       height },

--     -- Corner
--     { 4,                       height },
--     { 2,                       height },
--     { 0,                       height - 2 },
--     { 0,                       height - 4 },

--     -- Left
--     { 0,                       height - 4 },
--     { 0,                       height / 2 },
--     { 0,                       height / 2 },
--     { 0,                       4 },

--     -- Corner
--     { 0,                       4 },
--     { 0,                       2 },
--     { 2,                       0 },
--     { 4,                       0 },

--     -- Top 2
--     { 4,                       0 },
--     { (width - 4) / 4 + 2,     0 },
--     { (width - 4) / 4 + 2,     0 },
--     { width / 2,               0 }
-- };

-- local controlPoints = {

--     { 19,   0 },
--     { 41.8, 0 },
--     { 38,   -3.8 },
--     { 38,   19 },

--     { 38,   19 },
--     { 38,   41.8 },
--     { 41.8, 38 },
--     { 19,   38 },

--     { 19,   38 },
--     { -3.8, 38 },
--     { 0,    41.8 },
--     { 0,    19 },

--     { 0,    19 },
--     { 0,    -3.8 },
--     { -3.8, 0 },
--     { 19,   0 }
-- };

local knotValues = {
    0,
    0.4,
    0.6,
    1.4,
    1.6,
    2.4,
    2.6,
    3.4,
    3.6,
    4.0
};

-- local knotValues = {
--     0,
--     1,
--     2,
--     3,
--     4
-- };

-- local spline = BezierSpline:new({
--     controlPoints = controlPoints,
--     knotValues = knotValues
-- });

-- 0xAADADF20 -- Yellow
-- 0xAA20DF20 -- Green
-- 0xAADA201A -- Red

local splines = T {};
local function drawRecastIndicator(ctx, pos, ratio, recast, width, height)    
    width = width or 38;
    height = height or 38;

    splines[width] = splines[width] or T {};
    if (not splines[width][height]) then
        local xScale = (width - 4) / 34;
        local yScale = (height - 4) / 34;

        local newPoints = T {
            -- Top 1
            { width / 2,               0 },
            { (width - 4) * 3 / 4 - 2, 0 },
            { (width - 4) * 3 / 4 - 2, 0 },
            { width - 4,               0 },

            -- Corner
            { width - 4,               0 },
            { width - 2,               0 },
            { width,                   2 },
            { width,                   4 },

            -- Right
            { width,                   4 },
            { width,                   height / 2 },
            { width,                   height / 2 },
            { width,                   height - 4 },

            -- Corner
            { width,                   height - 4 },
            { width,                   height - 2 },
            { width - 2,               height },
            { width - 4,               height },

            -- Bottom
            { width - 4,               height },
            { width / 2,               height },
            { width / 2,               height },
            { 4,                       height },

            -- Corner
            { 4,                       height },
            { 2,                       height },
            { 0,                       height - 2 },
            { 0,                       height - 4 },

            -- Left
            { 0,                       height - 4 },
            { 0,                       height / 2 },
            { 0,                       height / 2 },
            { 0,                       4 },

            -- Corner
            { 0,                       4 },
            { 0,                       2 },
            { 2,                       0 },
            { 4,                       0 },

            -- Top 2
            { 4,                       0 },
            { (width - 4) / 4 + 2,     0 },
            { (width - 4) / 4 + 2,     0 },
            { width / 2,               0 }
        };

        local newKnots = T { 0 };
        for i = 1, #knotValues - 1 do
            -- knotIntervals[i] =

            local knotInterval = knotValues[i + 1] - knotValues[i];

            if (i % 4 == 1) then
                knotInterval = knotInterval * xScale;
            elseif (i % 4 == 3) then
                knotInterval = knotInterval * yScale;
            end

            newKnots:insert(newKnots[i] + knotInterval);
        end

        splines[width][height] = BezierSpline:new({
            controlPoints = newPoints,
            knotValues = newKnots
        });
    end

    local spline = splines[width][height];

    local color;
    if (recast > 1800) then
        color = T { 0xDA, 0x20, 0x1A };
    elseif (recast > 600) then
        local t = (recast - 600) / 1200;

        local r = 0xDA;
        local g = 0xDF + (0x20 - 0xDF) * t;
        local b = 0x20 + (0x1A - 0x20) * t;
        color = T { r, g, b };
    else
        local t = recast / 600;
        local r = 0x20 + (0xDA - 0x20) * t;
        local g = 0xDF;
        local b = 0x20;
        color = T { r, g, b };
    end

    local segments = (2 * width + 2 * height) * 3 / 4 * (1 - ratio) + 1;

    spline:draw(ctx, 0, 1 - ratio, segments, 3.0, d3d.D3DCOLOR_ARGB(0xAA, color:unpack()), nil, pos);
end

return drawRecastIndicator;
