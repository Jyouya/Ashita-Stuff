-- ? Do I need to scale these parameters to [0,1]?
local function desaturate(color, f)
    local r,g, b = color[1], color[2], color[3]
    -- print(r,g,b,f);
    local L = 0.3 * r + 0.6 * g + 0.1 * b;
    return T {
        r + f * (L - r),
        g + f * (L - g),
        b + f * (L - b)
    };
end

return desaturate;