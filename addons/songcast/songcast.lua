addon.name    = 'songcast';
addon.author  = 'Jyouya';
addon.version = '0.1';
addon.desc    = 'Range indicator for friendly bard songs';

require('common');
local settings = require('settings');

local helpers = require('helpers');
local skillCap = require('skillCap');
local config = require('config');
local s = settings.get();

local casts = require('tracker');

local drawCircle = require('drawCircle');
local drawArc = require('drawArc');

ashita.events.register('load', 'load_cb', function()
    ashita.events.register('d3d_present', 'present_cb', function()
        local party = AshitaCore:GetMemoryManager():GetParty();
        local entity = AshitaCore:GetMemoryManager():GetEntity();

        -- print(entity:GetLookMain(party:GetMemberTargetIndex(0)))

        -- print(AshitaCore:GetMemoryManager():GetEntity():GetLookBody(actorId));

        for i = 0, 5 do
            if (party:GetMemberIsActive(i) == 1) then
                local casterId = party:GetMemberServerId(i);
                local cast = casts[casterId];
                if (cast) then
                    local casterIndex = party:GetMemberTargetIndex(i);
                    local rangedId = entity:GetLookRanged(casterIndex);
                    local bonus = 1;
                    if (rangedId > 0) then
                        local item = AshitaCore:GetResourceManager():GetItemById(rangedId);

                        -- Stringed Instrument Skill
                        if (item and item.Skill == 41) then
                            local casterLevel = party:GetMemberMainJobLevel(i);
                            if (casterLevel <= 0) then
                                -- Use player level in case of anon
                                casterLevel = party:GetMemberMainJobLevel(0);
                            end
                            local baseSkill = skillCap[cast.song.level];
                            local currentSkill = skillCap[casterLevel];

                            bonus = math.clamp(currentSkill / baseSkill, 1, 2);
                        end
                    end

                    local aoeRange = cast.song.range * bonus;
                    if (not s.songs[cast.song.type]) then
                        print(cast.song.type);
                    end
                    local color = bit.lshift(s.alpha * 0xFF, 24) + s.songs[cast.song.type].color;

                    local casterPointer = entity:GetActorPointer(casterIndex);
                    local x, y, z = helpers.getBone(casterPointer, 0);

                    drawCircle(x, z, y, aoeRange, color, (os.clock() / 2) % 1);

                    local rangeSquared = aoeRange ^ 2;

                    if (s.targetLines) then
                        local _, _, zNameplate = helpers.getBone(casterPointer, 2)
                        z = (z + zNameplate) / 2;
                        for j = 0, 5 do
                            if (i ~= j and party:GetMemberIsActive(j) == 1) then
                                local targetIndex = party:GetMemberTargetIndex(j);
                                -- print(targetIndex);

                                local distance = helpers.getEntityDistanceSquared(casterIndex, targetIndex);

                                if (distance < rangeSquared) then
                                    local targetPointer = entity:GetActorPointer(targetIndex);

                                    local x2, y2, z2 = helpers.getBone(targetPointer, 2);
                                    z2 = (ashita.memory.read_float(targetPointer + 0x67C) + z2) / 2;
                                    drawArc(x, y, z, x2, y2, z2, s.lineColor);
                                end
                            end
                        end
                    end
                end
            end
        end




        -- local player = GetPlayerEntity();
        -- if (not player) then return; end
        -- local playerPointer = player.ActorPointer;
        -- local x, y, z = helpers.getBone(playerPointer, 0);

        -- drawCircle(x, z, y, 1, 0x4400cc00, (os.clock() / 2) % 1);
    end);
end);
