local ctx = require('J-GUI/ctx');
local text = require('J-GUI/text');

text.ctx = ctx;

local GUI = {
    ctx = ctx,
    text = text,
    View = require('J-GUI/View'),
    Container = require('J-GUI/Container'),
    FilteredContainer = require('J-GUI/FilteredContainer'),
    ItemSelector = require('J-GUI/ItemSelector'),
    Button = require('J-GUI/Button'),
    ENUM = require('J-GUI/enum')
};

return GUI;
