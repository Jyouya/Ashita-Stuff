local GUI = require('J-GUI');
local Button = require('J-GUI/Button');

local settings = require('settings');
local ffi = require('ffi');

local getTexForStatus = require('functions.getTexForStatus');
local getTexForAbility = require('functions.getTexForAbility');
local desaturate = require('functions.desaturate');
local drawRecastIndicator = require('functions.drawRecastIndicator');
local getAbilityRecasts = require('functions.getAbilityRecasts');

local castHandler = require('tracker').castHandler;

local colors = require('elemental.shared').ELEMENTAL_COLOR;

local jobAbilities = require('jobability.jobs');

local trackedAbilities = T {};
local availableAbilities = T {};
GUI.ctx.prerender:register(function()
    local playerMp = AshitaCore:GetMemoryManager():GetParty():GetMemberMP(0);
    local player = AshitaCore:GetMemoryManager():GetPlayer();

    availableAbilities = T {};

    local recasts = getAbilityRecasts();
    for _, ability in ipairs(trackedAbilities) do
        if (player:HasAbility(ability.resource.Id)) then
            local res = T { available = 0 };
            local abilityRecast = recasts[ability.resource.RecastTimerId]

            res.recast = abilityRecast;

            local recastDelay = castHandler.getRecastForAbility(ability.resource.Id);

            if (recastDelay) then
                res.recastRatio = abilityRecast / recastDelay;
            else
                res.recastRatio = 0;
            end

            if (abilityRecast == 0) then
                res.available = 1;
            end

            availableAbilities[ability.resource.Name[1]] = res;
        end
    end
end);

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
local function getColor(ability)
    local element = elements[ability.resource.Element] or 'LIGHT';
    local color = colors[element];
    local abilityName = ability.resource.Name[1];
    return function()
        -- print(abilityName);
        -- print(AshitaCore:GetMemoryManager():GetPlayer():HasAbility(ability.resource.Id))
        local abilityData = availableAbilities[abilityName];
        local finalColor = color;
        if (abilityData.available == 0) then
            finalColor = desaturate(color, 0.8);
        end
        return finalColor;
    end
end

local function getTexForSpell(ability)
    if (ability.tex) then
        return getTexForStatus(ability.tex);
    else
        return getTexForAbility(ability.resource.Name[1]);
    end
end

local getTextureSize;
do
    local vec_size = ffi.new('D3DXVECTOR2', { 24.0, 24.0, });
    getTextureSize = function()
        return vec_size;
    end
end

local function getTextureOpacity(ability)
    local abilityName = ability.resource.Name[1];
    return function()
        local abilityData = availableAbilities[abilityName];

        return (abilityData.available == 0) and 0.3 or 1.0;
    end
end

local function draw(ability)
    local abilityName = ability.resource.Name[1];
    return function(self)
        GUI.Button.draw(self);

        local ratio = availableAbilities[abilityName].recastRatio;
        if (ratio and ratio > 0) then
            drawRecastIndicator(self.ctx, self:getPos(), ratio,
                availableAbilities[abilityName].recast)
        end

        -- if (trackedAbilities[ability].target == '<t>') then
        --     local targetIndex = AshitaCore:GetMemoryManager():GetTarget():GetTargetIndex(0);
        --     if (targetIndex > 0 and self._isHovered) then
        --         self.ctx.sprite:End();
        --         drawRangeIndicator(targetIndex, 20);
        --         self.ctx.sprite:Begin();
        --     end
        -- end
    end
end

local function onClick(ability)
    local abilityName = ability.resource.Name[1];
    return function()
        local abilityData = availableAbilities[abilityName];

        if (abilityData.available == 0) then
            return;
        end

        AshitaCore:GetChatManager():QueueCommand(-1, ('/ja "%s" %s'):format(abilityName, ability.target));
    end
end

local function shouldDisplay(ability)
    return function()
        return AshitaCore:GetMemoryManager():GetPlayer():HasAbility(ability.resource.Id);
    end
end

local function abilityButtonFactory(ability)
    return Button:new({
        getColor = getColor(ability),
        getTexture = getTexForSpell(ability),
        getTextureSize = getTextureSize,
        getTextureOpacity = getTextureOpacity(ability),
        draw = draw(ability),
        onClick = onClick(ability),
        shouldDisplay = shouldDisplay(ability)
    });
end


local function setup(s)
    local jobAbilityUI = GUI.FilteredContainer:new({
        layout = GUI.Container.LAYOUT.GRID,
        gridRows = 1,
        gridCols = GUI.Container.LAYOUT.AUTO,
        fillDirection = GUI.Container.LAYOUT.HORIZONTAL,
        gridGap = 4,
        padding = { x = 0, y = 0 },
        draggable = true,
        onDragFinish = function(view)
            local pos = view:getPos();
            s.jobAbility.x = pos.x;
            s.jobAbility.y = pos.y;
            settings.save();
        end,
        getHidden = function()
            return not s.jobAbility.visible;
        end,
        _x = s.jobAbility.x,
        _y = s.jobAbility.y
    });
    GUI.ctx.addView(jobAbilityUI);

    local mainJob = AshitaCore:GetMemoryManager():GetPlayer():GetMainJob();
    mainJob = AshitaCore:GetResourceManager():GetString('jobs.names_abbr', mainJob);

    local subJob = AshitaCore:GetMemoryManager():GetPlayer():GetSubJob();
    subJob = AshitaCore:GetResourceManager():GetString('jobs.names_abbr', subJob);

    local mainJA = jobAbilities[mainJob] or T {};
    local subJA = jobAbilities[subJob] or T {};

    for _, ability in ipairs(mainJA) do
        trackedAbilities:insert(ability);
        jobAbilityUI:addView(abilityButtonFactory(ability));
    end

    for _, ability in ipairs(subJA) do
        trackedAbilities:insert(ability);
        jobAbilityUI:addView(abilityButtonFactory(ability));
    end
end

return { setup = setup };
