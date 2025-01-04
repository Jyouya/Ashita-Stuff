local party = require('tracker').party;
local GUI = require('J-GUI');
local settings = require('settings');

local hasSpell = require('elemental.shared').hasSpell;

local BuffMenu = require('enhancing.BuffMenu');

local getTexForStatus = require('functions.getTexForStatus');
local getTexForSpell = require('functions.getTexForSpell');
local getTexForJob = require('functions.getTexForJob');
local canCastSpell = require('functions.canCastSpell');
local drawRangeIndicator = require('functions.drawRangeIndicator');
local drawRecastIndicator = require('functions.drawrecastIndicator');

local DebuffMenuEntry = require('healing.DebuffMenuEntry');
local nas = require('healing.nas');

local bufftable = require('hxui.bufftable');

local castHandler = require('tracker').castHandler;

local trackedStatus = T {};
local trackedNas = T {};
local menu;

local needsNa = T {};
local availableSpells = T {};

GUI.ctx.prerender:register(function()
    needsNa = T {};
    -- Kinda gross, Could cut out some loops with a hash table
    -- But I need the na spells to be sorted by priority
    availableSpells = T {};
    for _, naSpell in ipairs(trackedNas) do
        for i, member in ipairs(party) do
            if (member.active == 1) then
                for _, debuff in ipairs(naSpell.debuffs) do
                    if (trackedStatus[debuff] and member.buffs[debuff]) then
                        -- print('debug');
                        needsNa:insert(T {
                            status = debuff,
                            spellName = naSpell.spellName,
                            partyIndex = i
                        });
                        break;
                    end
                end
            end
        end

        local recast = AshitaCore:GetMemoryManager():GetRecast();
        local playerMp = AshitaCore:GetMemoryManager():GetParty():GetMemberMP(0);

        local spell = naSpell.spell;
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
        availableSpells[naSpell.spellName] = spellData;
    end

    for i, data in ipairs(needsNa) do
        local entry
        if (i > #menu._children) then
            entry = DebuffMenuEntry:new()
            menu:addView(entry);
        end
        entry = entry or menu._children[i];
        local member = party[data.partyIndex];

        entry.getJobIconTexture = function()
            return getTexForJob(member.mainJob);
        end

        entry.getStatusIconTexture = getTexForStatus(data.status);

        entry.getColor = function()
            if (availableSpells[data.spellName].available == 1) then
                return T { 255.0, 100.0, 100.0 };
            else
                return T { 160.0, 160.0, 160.0 };
            end
        end

        entry.getText = function()
            return member.name;
        end

        entry.onClick = function()
            AshitaCore:GetChatManager():QueueCommand(-1, ('/ma "%s" %s'):format(data.spellName, member.name))
        end

        entry.shouldDisplay = function()
            return true;
        end

        entry.draw = function(self)
            DebuffMenuEntry.draw(self);

            local ratio = availableSpells[data.spellName].recastRatio;
            if (ratio and ratio > 0) then
                drawRecastIndicator(self.ctx, self:getPos(), ratio,
                    availableSpells[data.spellName].recast, self:getWidth(), self:getHeight());
            end

            if (data.partyIndex > 0 and self._isHovered) then
                self.ctx.sprite:End();
                drawRangeIndicator(member.targetIndex, 20);
                self.ctx.sprite:Begin();
            end
        end
    end

    -- print(#needsNa);
    -- print(#menu.children);

    if (#menu._children > #needsNa) then
        for i = #needsNa + 1, #menu._children do
            menu._children[i].shouldDisplay = function()
                -- print('debug');
                return false;
            end
        end
    end
end);

local function getTitle()
    return 'Status';
end

local function setupStatusRemovalMenu(s)
    -- for k, v in pairs(s.healing.status.trackedStatus) do
    --     trackedStatus[string.lower(k)] = v;
    -- end
    trackedStatus = s.healing.status.trackedStatus;

    for _, na in ipairs(nas) do
        if (canCastSpell(na.spellName)) then
            trackedNas:insert(na);
        end
    end

    menu = BuffMenu:new({
        getIconTexture = getTexForSpell('Erase'),
        getTitle = getTitle,
        draggable = true,
        onDragFinish = function(view)
            local pos = view:getPos();
            s.healing.status.x = pos.x;
            s.healing.status.y = pos.y;
            settings.save();
        end,
        getHidden = function()
            return not (#trackedNas > 0 and s.healing.status.visible);
        end,
        _width = 122,
        _x = s.healing.status.x,
        _y = s.healing.status.y
    });

    GUI.ctx.addView(menu);
end

return setupStatusRemovalMenu;
