require('common');
local GUI = require('J-GUI');

return function(...)
    local vstack = GUI.Container:new({
        layout = GUI.Container.LAYOUT.GRID,
        girdRows = GUI.Container.LAYOUT.AUTO,
        gridCols = 1,
        fillDirection = GUI.Container.LAYOUT.VERTICAL,
        gridGap = 8,
        padding = { x = 0, y = 0 },
        draggable = true,
    });

    vstack:addView(...);
    return vstack;
end
