local GUI = require('J-GUI');
local Button = require('J-GUI/Button');
local text = require('J-GUI/text');

local settings = require('settings');
local ffi = require('ffi');

local getTexForStatus = require('functions.getTexForStatus');
local desaturate = require('functions.desaturate');
local canCastSpell = require('functions.canCastSpell');
local drawRecastIndicator = require('functions.drawRecastIndicator');
local getAoeTargets = require('functions.getAoeTargets');

local colors = require('elemental.shared').ELEMENTAL_COLOR;
local hasSpell = require('elemental.shared').hasSpell;
local ROMAN_NUMERALS = require('elemental.shared').ROMAN_NUMERALS;

local enhancingMagic = require('enhancing.enhancingMagic');
local selfBuffCategories = require('enhancing.selfBuffCategories');

local castHandler = require('tracker').castHandler;
local party = require('tracker').party;

local hoveredSpell;

local trackedSpells = T {};

local availableSpells = T {};
GUI.ctx.prerender:register(function()
    local recast = AshitaCore:GetMemoryManager():GetRecast();
    local playerMp = AshitaCore:GetMemoryManager():GetParty():GetMemberMP(0);

    availableSpells = T {};
    for status, spell in pairs(trackedSpells) do
        local res = T { available = 0 };
        if (hasSpell(spell)) then
            local spellRecast = recast:GetSpellTimer(spell.Index);

            res.recast = spellRecast;
            local recastDelay = castHandler.getRecastForSpell(spell.Index);
            res.recastRatio = spellRecast / recastDelay;
            local mpCost = spell.ManaCost;

            if (spellRecast == 0 and playerMp >= mpCost) then
                res.available = 1;
            end
        end
        availableSpells[status] = res;
    end

    if (hoveredSpell) then
        local aoeTargets = getAoeTargets(
            trackedSpells[hoveredSpell],
            party[1].targetIndex
        );

        for _, partyIndex in ipairs(aoeTargets) do
            party[partyIndex].isAoeTarget = true;
        end
    end
end);

local getTextureSize;
do
    local vec_size = ffi.new('D3DXVECTOR2', { 24.0, 24.0, });
    getTextureSize = function()
        return vec_size;
    end
end

local elements = T {
    [0] = 'FIRE',
    [1] = 'ICE',
    [2] = 'WIND',
    [3] = 'EARTH',
    [4] = 'LIGHTNING',
    [5] = 'WATER',
    [6] = 'LIGHT',
    [7] = 'DARK'
};

local function onMouseEnter(status)
    return function()
        hoveredSpell = status
    end
end

local function onMouseExit(status)
    return function(self, e)
        GUI.Button.onMouseExit(self, e);
        hoveredSpell = nil;
    end
end

local function getColor(status)
    local spell = AshitaCore:GetResourceManager():GetSpellByName(status, 2);
    local element = elements[spell.Element];
    local color = colors[element];
    return function()
        local spellData = availableSpells[status];
        local finalColor = color;
        if (spellData.available == 0) then
            finalColor = desaturate(color, 0.8);
        end
        return finalColor;
    end
end

local tierOffset = T { 5, 2, 0, 1, 3 };
local function drawTex(status, tier)
    return function(button, pos)
        Button.drawTex(button, pos); -- Draw the status texture

        local spellData = availableSpells[status];

        if (spellData.available == 0 or tier == 0) then return; end
        local str = ROMAN_NUMERALS[tier];

        text.write(pos.x + 20 + tierOffset[tier], pos.y + 20, 1, str);
    end
end

local function getTextureOpacity(status)
    return function()
        local spellData = availableSpells[status];
        return (spellData.available == 0) and 0.3 or (1.0 - 0.5 * (spellData.applied and 1 or 0));
    end
end

local function onClick(status, spellName)
    return function()
        local spellData = availableSpells[status];

        if (spellData.available == 0) then
            return;
        end

        AshitaCore:GetChatManager():QueueCommand(-1, ('/ma "%s" <me>'):format(spellName));
    end
end

local function draw(status)
    return function(button)
        GUI.Button.draw(button);

        local ratio = availableSpells[status].recastRatio;
        if (ratio and ratio > 0) then
            drawRecastIndicator(button.ctx, button:getPos(), ratio,
                availableSpells[status].recast);
        end
    end
end

local aliasStatus = T {
    Baramnesra = 'Baramnesia',
    Barpoisonra = 'Barpoison',
    Barsleepra = 'Barsleep',
    Barpetra = 'Barpetrify',
    Barsilencera = 'Barsilence',
    Barparalyzra = 'Barparalyze',
    Barblindra = 'Barblind',

    Barfira = 'Barfire',
    Barwatera = 'Barwater',
    Barthundra = 'Barthunder',
    Barstonra = 'Barstone',
    Baraera = 'Baraero',
    Barblizzara = 'Barblizzard',

    Protectra = 'Protect',
    Shellra = 'Shell',

    Adloquium = 'Regain',
    Crusade = 'Enmity Boost',
    Temper = 'Multi Strikes',

    ['Boost-STR'] = 'STR Boost',
    ['Boost-MND'] = 'MND Boost',
    ['Boost-DEX'] = 'DEX Boost',
    ['Boost-VIT'] = 'VIT Boost',
    ['Boost-AGI'] = 'AGI Boost',
    ['Boost-INT'] = 'INT Boost',
    ['Boost-CHR'] = 'CHR Boost',

    ['Gain-STR'] = 'STR Boost',
    ['Gain-MND'] = 'MND Boost',
    ['Gain-DEX'] = 'DEX Boost',
    ['Gain-VIT'] = 'VIT Boost',
    ['Gain-AGI'] = 'AGI Boost',
    ['Gain-INT'] = 'INT Boost',
    ['Gain-CHR'] = 'CHR Boost',
};

-- List of AoE spells that have single target versions
local aoeSpells = T {};
do
    local spells = T {
        'Protectra',
        'Shellra',
        'Baramnesra',
        'Barpoisonra',
        'Barsleepra',
        'Barpetra',
        'Barsilencera',
        'Barparalyzra',
        'Barblindra',
        'Barfira',
        'Barwatera',
        'Barthundra',
        'Barstonra',
        'Baraera',
        'Barblizzara',
        'Boost-STR',
        'Boost-MND',
        'Boost-DEX',
        'Boost-VIT',
        'Boost-AGI',
        'Boost-INT',
        'Boost-CHR'
    };

    for _, v in ipairs(spells) do
        aoeSpells[v] = true;
    end
end

local drawAoE;
do
    local vec_position = ffi.new('D3DXVECTOR2', { 0, 0, });
    local vec_scale = ffi.new('D3DXVECTOR2', { 0.5, 0.5, });
    local rect = ffi.new('RECT', { 0, 0, 32, 32 });
    drawAoE = function(status, tier)
        return function(button, pos)
            local tex = button:getTexture();

            if (not tex) then return; end

            local tint = button:getTextureTint();
            local alpha = bit.rshift(0xFF000000, 24) * button:getTextureOpacity();
            local color = bit.lshift(math.min(alpha, 255), 24) + bit.band(tint, 0xFFFFFF);

            vec_position.x = pos.x + 15 * button.ctx.vec_scale.x;
            vec_position.y = pos.y + 7 * button.ctx.vec_scale.y;

            button.ctx.sprite:Draw(tex, rect, vec_scale, nil, 0.0, vec_position, color);

            vec_position.x = vec_position.x - 8 * button.ctx.vec_scale.x;
            vec_position.y = vec_position.y + 8 * button.ctx.vec_scale.y;

            button.ctx.sprite:Draw(tex, rect, vec_scale, nil, 0.0, vec_position, color);

            local spellData = availableSpells[status];

            if (spellData.available == 0 or tier == 0) then return; end
            local str = ROMAN_NUMERALS[tier];

            text.write(pos.x + 20 + tierOffset[tier], pos.y + 20, 1, str);
        end
    end
end


local function buttonFactory(status)
    local spellName = status;
    local spells = enhancingMagic[status];
    local spellTier = 0;
    local spell = AshitaCore:GetResourceManager():GetSpellByName(status, 2);
    if (#spells > 1) then
        for i, v in ipairs(spells) do
            if (canCastSpell(v) and hasSpell(spell)) then
                spellName = v;
                spellTier = #spells - i + 1;
                spell = AshitaCore:GetResourceManager():GetSpellByName(spellName, 2);
                break;
            end
        end
    end

    trackedSpells[status] = spell;

    local alias = aliasStatus[status] or status;

    if (aoeSpells[status]) then
        return Button:new({
            getColor = getColor(status),
            getTexture = getTexForStatus(alias),
            getTextureSize = getTextureSize,
            getTextureOpacity = getTextureOpacity(status),
            onMouseEnter = onMouseEnter(status),
            onMouseExit = onMouseExit(status),
            drawTex = drawAoE(status, spellTier),
            onClick = onClick(status, spellName),
            draw = draw(status)
        });
    else
        return Button:new({
            getColor = getColor(status),
            getTexture = getTexForStatus(alias),
            getTextureSize = getTextureSize,
            getTextureOpacity = getTextureOpacity(status),
            drawTex = drawTex(status, spellTier),
            onClick = onClick(status, spellName),
            draw = draw(status)
        });
    end
end

local function rowFactory(category, s)
    local row = GUI.Container:new({
        layout = GUI.Container.LAYOUT.GRID,
        gridRows = 1,
        gridCols = GUI.Container.LAYOUT.AUTO,
        fillDirection = GUI.Container.LAYOUT.HORIZONTAL,
        draggable = true,
        gridGap = 4,
        padding = { x = 0, y = 0 },
        shouldDisplay = function()
            return s.selfEnhancing[category];
        end
    });
    local statuses = selfBuffCategories[category];
    for _, status in ipairs(statuses) do
        if (canCastSpell(status)) then
            row:addView(buttonFactory(status));
        end
    end

    return row;
end

local categories = T {
    'Misc',
    'Enspell',
    'Enspell II',
    'Boost',
    'Gain',
    'Barelementra',
    'Barelement',
    'Barstatusra',
    'Barstatus',
    'Spikes',
};
local function setup(s)
    local buffUI = GUI.FilteredContainer:new({
        layout = GUI.Container.LAYOUT.GRID,
        gridRows = GUI.Container.LAYOUT.AUTO,
        gridCols = 1,
        fillDirection = GUI.Container.LAYOUT.HORIZONTAL,
        gridGap = 4,
        padding = { x = 0, y = 0 },
        draggable = true,
        onDragFinish = function(view)
            local pos = view:getPos();
            s.selfEnhancing.x = pos.x;
            s.selfEnhancing.y = pos.y;
            settings.save();
        end,
        getHidden = function()
            return not s.selfEnhancing.visible;
        end,
        _x = s.selfEnhancing.x,
        _y = s.selfEnhancing.y
    });
    GUI.ctx.addView(buffUI);
    for _, category in ipairs(categories) do
        if (s.selfEnhancing[category]) then
            local row = rowFactory(category, s);
            if (#row.children > 0) then
                buffUI:addView(row);
            end
        end
    end
end

return { setup = setup };
