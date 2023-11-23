local ffi = require('ffi');
local functions = require('J-GUI/functions');

local fonts = T {
    [1] = { -- 12 px high font
        path = 'font.png',
        spacing = -1,
        map = (T {
            -- { x, y, w, h }
            [' '] = { 0, 0, 9, 12 },
            ['!'] = { 12, 0, 6, 12 },
            ['"'] = { 21, 0, 7, 12 },
            ['#'] = { 30, 0, 10, 12 },
            ['$'] = { 40, 0, 10, 12 },
            ['%'] = { 50, 0, 10, 12 },
            ['&'] = { 60, 0, 10, 12 },
            ['\''] = { 73, 0, 4, 12 },
            ['('] = { 81, 0, 5, 12 },
            [')'] = { 94, 0, 5, 12 },
            ['*'] = { 100, 0, 10, 12 },
            ['+'] = { 111, 0, 10, 12 },
            [','] = { 2, 13, 5, 12 },
            ['-'] = { 11, 13, 8, 12 },
            ['.'] = { 23, 13, 4, 12 },
            ['/'] = { 30, 13, 9, 12 },
            ['0'] = { 40, 13, 9, 12 },
            ['1'] = { 51, 13, 7, 12 },
            ['2'] = { 61, 13, 8, 12 },
            ['3'] = { 70, 13, 9, 12 },
            ['4'] = { 80, 13, 9, 12 },
            ['5'] = { 91, 13, 8, 12 },
            ['6'] = { 101, 13, 8, 12 },
            ['7'] = { 111, 13, 8, 12 },
            ['8'] = { 0, 26, 9, 12 },
            ['9'] = { 10, 26, 8, 12 },
            [':'] = { 19, 26, 4, 12 },
            [';'] = { 24, 26, 5, 12 },
            ['<'] = { 30, 26, 8, 12 },
            ['='] = { 39, 26, 8, 12 },
            ['>'] = { 48, 26, 8, 12 },
            ['?'] = { 56, 26, 9, 12 },
            ['@'] = { 66, 26, 9, 12 },
            ['A'] = { 77, 26, 9, 12 },
            ['B'] = { 87, 26, 9, 12 },
            ['C'] = { 97, 26, 9, 12 },
            ['D'] = { 107, 26, 9, 12 },
            ['\n'] = { 117, 26, 9, 12 }, -- …
            ['E'] = { 0, 39, 9, 12 },
            ['F'] = { 10, 39, 9, 12 },
            ['G'] = { 20, 39, 9, 12 },
            ['H'] = { 31, 39, 9, 12 },
            ['I'] = { 42, 39, 6, 12 },
            ['J'] = { 48, 39, 9, 12 },
            ['K'] = { 58, 39, 9, 12 },
            ['L'] = { 69, 39, 9, 12 },
            ['M'] = { 80, 39, 9, 12 },
            ['N'] = { 91, 39, 9, 12 },
            ['O'] = { 102, 39, 9, 12 },
            ['P'] = { 113, 39, 9, 12 },
            ['Q'] = { 0, 52, 9, 12 },
            ['R'] = { 11, 52, 10, 12 },
            ['S'] = { 22, 52, 9, 12 },
            ['T'] = { 31, 52, 9, 12 },
            ['U'] = { 41, 52, 9, 12 },
            ['V'] = { 52, 52, 10, 12 },
            ['W'] = { 63, 52, 9, 12 },
            ['X'] = { 76, 52, 9, 12 },
            ['Y'] = { 88, 52, 9, 12 },
            ['Z'] = { 99, 52, 9, 12 },
            ['['] = { 114, 52, 6, 12 },
            ['\\'] = { 1, 65, 10, 12 },
            [']'] = { 13, 65, 6, 12 },
            ['^'] = { 21, 65, 8, 12 },
            ['_'] = { 31, 65, 8, 12 },
            ['`'] = { 42, 65, 5, 12 },
            ['a'] = { 49, 65, 8, 12 },
            ['b'] = { 58, 65, 9, 12 },
            ['c'] = { 68, 65, 9, 12 },
            ['d'] = { 78, 65, 9, 12 },
            ['e'] = { 89, 65, 9, 12 },
            ['f'] = { 99, 65, 7, 12 },
            ['g'] = { 107, 65, 9, 14 },
            ['h'] = { 0, 78, 9, 12 },
            ['i'] = { 10, 78, 5, 12 },
            ['j'] = { 16, 78, 8, 14 },
            ['k'] = { 25, 78, 9, 12 },
            ['l'] = { 35, 78, 6, 12 },
            ['m'] = { 42, 78, 9, 12 },
            ['n'] = { 56, 78, 9, 12 },
            ['o'] = { 66, 78, 9, 12 },
            ['p'] = { 76, 78, 9, 14 },
            ['q'] = { 87, 78, 9, 14 },
            ['r'] = { 98, 78, 7, 12 },
            ['s'] = { 106, 79, 9, 11 },
            ['©'] = { 117, 78, 10, 12 },
            ['t'] = { 0, 91, 6, 12 },
            ['u'] = { 7, 91, 9, 12 },
            ['v'] = { 17, 92, 9, 11 },
            ['w'] = { 27, 91, 9, 12 },
            ['x'] = { 39, 91, 9, 12 },
            ['y'] = { 50, 91, 9, 14 },
            ['z'] = { 60, 91, 8, 12 },
            ['{'] = { 70, 92, 8, 12 },
            ['}'] = { 92, 92, 8, 12 },
            ['○'] = { 100, 91, 10, 12 },
            ['△'] = { 110, 91, 10, 12 }, -- Why is this character not monospace in vscode
            ['□'] = { 0, 104, 10, 12 },
            ['×'] = { 10, 104, 9, 12 },
            ['|'] = { 2, 116, 4, 12 },
            ['~'] = { 8, 116, 10, 12 }


        }):map(function(bounds)
            local x = bounds[1];
            local y = bounds[2];
            local w = bounds[3];
            local h = bounds[4];
            return {
                w = w,
                h = h,
                rect = ffi.new('RECT', { x, y, x + w, y + h })
            };
        end)
    },
    [2] = { -- 24 px high font
        path = 'font.png',
        spacing = -3,
        map = (T {
            -- { x, y, w, h }
            ['/'] = { 1, 128, 14, 26 },
            ['0'] = { 16, 130, 18, 24 },
            ['1'] = { 38, 130, 13, 24 },
            ['2'] = { 54, 130, 19, 24 },
            ['3'] = { 75, 130, 18, 24 },
            ['4'] = { 94, 130, 18, 24 },
            ['5'] = { 114, 130, 18, 24 },
            ['6'] = { 134, 130, 17, 24 },
            ['7'] = { 156, 130, 16, 24 },
            ['8'] = { 173, 130, 18, 24 },
            ['9'] = { 193, 130, 17, 24 },
            ['A'] = { 211, 130, 19, 24 },
            ['B'] = { 234, 130, 19, 24 },
            ['C'] = { 3, 154, 18, 24 },
            ['D'] = { 24, 154, 21, 24 },
            ['E'] = { 47, 154, 19, 24 },
            ['F'] = { 67, 154, 19, 24 },
            ['G'] = { 88, 154, 19, 24 },
            ['H'] = { 110, 154, 21, 24 },
            ['I'] = { 133, 154, 12, 24 },
            ['J'] = { 146, 154, 18, 24 },
            ['K'] = { 165, 154, 20, 24 },
            ['L'] = { 186, 154, 16, 24 },
            ['M'] = { 205, 154, 22, 24 },
            ['N'] = { 232, 154, 21, 24 },
            ['O'] = { 3, 178, 19, 24 },
            ['P'] = { 25, 178, 19, 24 },
            ['Q'] = { 48, 178, 19, 25 },
            ['R'] = { 69, 178, 20, 24 },
            ['S'] = { 92, 178, 19, 24 },
            ['T'] = { 115, 178, 17, 24 },
            ['U'] = { 133, 178, 20, 24 },
            ['V'] = { 157, 178, 19, 24 },
            ['W'] = { 178, 178, 22, 24 },
            ['X'] = { 204, 178, 20, 24 },
            ['Y'] = { 226, 178, 19, 24 },
            ['Z'] = { 1, 202, 19, 24 },

            ['a'] = { 21, 202, 16, 24 },
            ['b'] = { 40, 202, 17, 24 },
            ['c'] = { 61, 203, 16, 24 },
            ['d'] = { 81, 202, 18, 24 },
            ['e'] = { 101, 202, 16, 24 },
            ['f'] = { 120, 202, 13, 24 },
            ['g'] = { 134, 202, 18, 28 },
            ['h'] = { 155, 202, 17, 24 },
            ['i'] = { 173, 202, 12, 24 },
            ['j'] = { 185, 202, 15, 28 },
            ['k'] = { 201, 202, 18, 24 },
            ['l'] = { 219, 202, 12, 24 },
            ['m'] = { 232, 202, 21, 24 },
            ['n'] = { 1, 226, 17, 24 },
            ['o'] = { 22, 226, 17, 24 },
            ['p'] = { 41, 226, 18, 28 },
            ['q'] = { 64, 227, 17, 28 },
            ['r'] = { 83, 226, 14, 24 },
            ['s'] = { 99, 226, 15, 24 },
            ['t'] = { 118, 226, 12, 24 },
            ['u'] = { 132, 230, 18, 24 },
            ['v'] = { 153, 226, 16, 24 },
            ['w'] = { 171, 230, 19, 24 },
            ['x'] = { 192, 230, 18, 24 },
            ['y'] = { 211, 226, 18, 28 },
            ['z'] = { 229, 226, 18, 24 },

            [' '] = { 163, 106, 13, 24 },
            ['.'] = { 139, 106, 8, 24 },


        }):map(function(bounds)
            local x = bounds[1];
            local y = bounds[2];
            local w = bounds[3];
            local h = bounds[4];
            return {
                w = w,
                h = h,
                rect = ffi.new('RECT', { x, y, x + w, y + h })
            };
        end)
    }
};

local text = {};

local textures = T {};

local vec_scale = ffi.new('D3DXVECTOR2', { 1.0, 1.0, });
local vec_position = ffi.new('D3DXVECTOR2', { 0, 0, });
local white = 0xFFFFFFFF;

function text.write(x, y, fontIndex, str, tint, scale)
    str = str or '';
    vec_scale.x = scale or 1;
    vec_scale.y = scale or 1;
    tint = tint or white
    local font = fonts[fontIndex];
    for i = 1, #str do
        local c = str:sub(i, i)
        local char = font.map[c];
        if (not char) then
            print(c);
        end

        if (not textures[font]) then
            textures[font] = functions.loadAssetTexture(font.path);
        end

        local tex = textures[font];
        vec_position.x = x;
        vec_position.y = y;

        x = x + (char.w + font.spacing) * vec_scale.x;

        text.ctx.sprite:Draw(tex, char.rect, vec_scale, nil, 0.0, vec_position, tint)
    end
end

function text.write2(x, y, str, tint, scale)
    str = str or '';
    tint = tint or white
    scale = scale or 1;
    for i = 1, #str do
        local font = fonts[2];
        local c = str:sub(i, i)
        local char = font.map[c];
        local scale2 = scale;

        if (not char) then
            font = fonts[1];
            scale2 = 2 * scale;
            char = font.map[c];
        end

        vec_scale.x = scale2;
        vec_scale.y = scale2;


        if (not textures[font]) then
            textures[font] = functions.loadAssetTexture(font.path);
        end

        local tex = textures[font];
        vec_position.x = x;
        vec_position.y = y;

        x = x + (char.w + font.spacing) * vec_scale.x;

        text.ctx.sprite:Draw(tex, char.rect, vec_scale, nil, 0.0, vec_position, tint)
    end
end

function text.size(fontIndex, str, scale)
    str = str or '';
    scale = scale or 1;
    local font = fonts[fontIndex];
    local w = 0;
    for i = 1, #str do
        local c = str:sub(i, i)
        local char = font.map[c];
        if (not char) then
            print(c);
        end
        -- if (not char) then
        --     print(c);
        -- else
        w = w + (char.w + font.spacing) * scale;
        -- end
    end
    return w - font.spacing;
end

function text.size2( str, scale)
    str = str or '';
    scale = scale or 1;
    local font = fonts[2];
    local w = 0;
    for i = 1, #str do
        local scale2 = scale;
        local c = str:sub(i, i)
        local char = font.map[c];

        if (not char) then
            font = fonts[1];
            scale2 = 2 * scale;
            char = font.map[c];
        end

        -- if (not char) then
        --     print(c);
        -- else
        w = w + (char.w + font.spacing) * scale2;
        -- end
    end
    return w - font.spacing;
end

return text
