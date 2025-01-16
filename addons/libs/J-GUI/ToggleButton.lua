require('common');
local functions = require('J-GUI/functions');

local Button = require('J-GUI/Button');

local ToggleButton = Button:new();

function ToggleButton:getValue()
    return self.variable and self.variable.value
end

function ToggleButton:setValue(value)
    if (self.variable) then
        self.variable:set(value);
    end
end

function ToggleButton:toggle()
    self:setValue(not self:getValue());
end

function ToggleButton:onClick(e)
    self:toggle();
end

function ToggleButton:getColor()
    return self:getValue() and self.activeColor or self.inactiveColor;
end

function ToggleButton:getTexture()
    return self:getValue() and self:getActiveTexture() or self:getInactiveTexture();
end

local textures = T {};

function ToggleButton:getActiveTexture()
    if (not self.activeTextureFile) then return; end

    if (textures[self.activeTextureFile]) then
        return textures[self.activeTextureFile];
    end

    textures[self.activeTextureFile] = functions.loadAssetTexture(self.activeTextureFile);
    return textures[self.activeTextureFile];
end

function ToggleButton:getInactiveTexture()
    if (not self.inactiveTextureFile) then return; end

    if (textures[self.inactiveTextureFile]) then
        return textures[self.inactiveTextureFile];
    end

    textures[self.inactiveTextureFile] = functions.loadAssetTexture(self.inactiveTextureFile);
    return textures[self.inactiveTextureFile];
end

function ToggleButton:draw()
    Button.draw(self);
end

function ToggleButton:new(options)
    options = options or {};

    return setmetatable(options, {
        __index = ToggleButton,
        __tostring = function() return "ToggleButton" end
    });
end

return ToggleButton;
