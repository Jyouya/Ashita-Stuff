local GUI = require('J-GUI');
local settings = require('settings');

local hasSpell = require('elemental.shared').hasSpell;

local BuffMenu = require('enhancing.BuffMenu');

local getTexForStatus = require('functions.getTexForStatus');
local getTexForSpell = require('functions.getTexForSpell');
local buffDuration = require('functions.buffDuration');
local canCastSpell = require('functions.canCastSpell')

local aliasStatus = require('enhancing.spellToStatus');

local drawRecastIndicator = require('functions.drawrecastIndicator');

local SelfEnhancingTrackerEntry = require('enhancing.SelfEnhancingTrackerEntry')

local castHandler = require('tracker').castHandler;

local trackedBuffs = T {};
local menu;

local availableSpells = T {};

GUI.ctx.prerender:register(function()
    local buffs = T {};

    -- buff durations.  From ttimers
    local playMgr = AshitaCore:GetMemoryManager():GetPlayer();
    local ids = playMgr:GetStatusIcons();
    local durations = playMgr:GetStatusTimers();
    for i = 1, 32 do
        if ids[i] and ids[i] ~= 255 then
            local name = AshitaCore:GetResourceManager():GetString('buffs.names', ids[i]);
            buffs[name] = buffDuration(durations[i]);
        end
    end

    local displayedBuffs = T {};
    for spellName, tracked in pairs(trackedBuffs) do
        if (tracked) then
            local buffName = aliasStatus[spellName];

            -- print(buffs[buffName]);
            if (canCastSpell(spellName) and ((buffs[buffName] or 0) < 30)) then
                displayedBuffs:append({
                    status = buffName,
                    spellName = spellName,
                    duration = buffs[buffName] or 0
                });
            end
        end
    end


    -- Kinda gross, Could cut out some loops with a hash table
    -- But I need the na spells to be sorted by priority
    availableSpells = T {};
    for _, buff in ipairs(displayedBuffs) do
        local recast = AshitaCore:GetMemoryManager():GetRecast();
        local playerMp = AshitaCore:GetMemoryManager():GetParty():GetMemberMP(0);

        local spell = AshitaCore:GetResourceManager():GetSpellByName(buff.spellName, 2);
        local spellData = T { available = 0 };
        if (hasSpell(spell)) then
            local spellRecast = recast:GetSpellTimer(spell.Index);

            if (spellData.recast == nil) then
                spellData.recast = spellRecast;
                local recastDelay = castHandler.getRecastForSpell(spell.Index);
                spellData.recastRatio = spellRecast / recastDelay;
            end

            local mpCost = spell.ManaCost;

            if (spellRecast == 0 and playerMp >= mpCost) then
                spellData.available = 1;
            end
        end
        availableSpells[buff.spellName] = spellData;
    end

    for i, data in ipairs(displayedBuffs) do
        local entry
        if (i > #menu.children) then
            entry = SelfEnhancingTrackerEntry:new()
            menu:addView(entry);
        end
        entry = entry or menu.children[i];

        entry.getStatusIconTexture = getTexForStatus(data.status);

        entry.getColor = function()
            if (availableSpells[data.spellName].available == 1) then
                local t = data.duration / 30;

                local g = 100 + t * (255 - 100); -- lerp

                -- Start at yellow, and go to red as duration decreases
                return T { 255.0, g, 100.0 };
            else
                return T { 160.0, 160.0, 160.0 };
            end
        end

        entry.getText = function()
            return data.spellName;
        end

        entry.onClick = function()
            AshitaCore:GetChatManager():QueueCommand(-1, ('/ma "%s" <me>'):format(data.spellName));
        end

        entry.shouldDisplay = function()
            return true;
        end

        entry.draw = function(self)
            SelfEnhancingTrackerEntry.draw(self);

            local ratio = availableSpells[data.spellName].recastRatio;
            if (ratio and ratio > 0) then
                drawRecastIndicator(self.ctx, self:getPos(), ratio,
                    availableSpells[data.spellName].recast, self:getWidth(), self:getHeight());
            end
        end
    end

    -- print(#needsNa);
    -- print(#menu.children);

    if (#menu.children > #displayedBuffs) then
        for i = #displayedBuffs + 1, #menu.children do
            menu.children[i].shouldDisplay = function()
                -- print('debug');
                return false;
            end
        end
    end
end);

local function getTitle()
    return 'Buffs';
end

local function setupSelfEnhancingTracker(s)
    -- for k, v in pairs(s.healing.status.trackedStatus) do
    --     trackedStatus[string.lower(k)] = v;
    -- end
    trackedBuffs = s.selfEnhancing2.trackedBuffs;

    menu = BuffMenu:new({
        getIconTexture = getTexForSpell('Protect'),
        getTitle = getTitle,
        draggable = true,
        getHidden = function()
            return not s.selfEnhancing2.visible
        end,
        onDragFinish = function(view)
            local pos = view:getPos();
            s.selfEnhancing2.x = pos.x;
            s.selfEnhancing2.y = pos.y;
            settings.save();
        end,
        _width = 122,
        _x = s.selfEnhancing2.x,
        _y = s.selfEnhancing2.y
    });

    GUI.ctx.addView(menu);
end

return { setup = setupSelfEnhancingTracker };
