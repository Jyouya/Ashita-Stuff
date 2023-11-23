local GUI = require('J-GUI');
-- Is there a more elegant way to use code from another addon?
-- Something like windower5 services
local debuffHandler = require('hxui.debuffhandler');
local statusHandler = require('hxui.statushandler');
local castHandler = require('castHandler');
local wheelHandler = require('wheelHandler');
require('hxui.helpers');

-- Track our packets
ashita.events.register('packet_in', 'packet_in_tracker_cb', function(e)
    if (e.id == 0x0028) then
        -- print(AshitaCore:GetMemoryManager():GetTarget():GetActionTargetActive())
        local actionPacket = ParseActionPacket(e);

        if actionPacket then
            debuffHandler.HandleActionPacket(actionPacket);
            castHandler.HandleActionPacket(actionPacket);
            wheelHandler.HandleActionPacket(actionPacket);
        end
    elseif (e.id == 0x00A) then
        debuffHandler.HandleZonePacket(e);
    elseif (e.id == 0x0029) then
        local messagePacket = ParseMessagePacket(e.data);
        if (messagePacket) then
            debuffHandler.HandleMessagePacket(messagePacket);
            castHandler.HandleMessagePacket(messagePacket);
        end
    elseif (e.id == 0x076) then
        statusHandler.ReadPartyBuffsFromPacket(e);
    end
end);

local party = T {};
GUI.ctx.prerender:register(function()
    local p = AshitaCore:GetMemoryManager():GetParty();
    for i = 0, 5 do
        local member = T {};
        member.active = p:GetMemberIsActive(i);
        member.serverId = p:GetMemberServerId(i);
        member.index = p:GetMemberTargetIndex(i);
        member.mainJob = p:GetMemberMainJob(i);
        member.name = p:GetMemberName(i);
        member.targetIndex = p:GetMemberTargetIndex(i);
        member.mp = p:GetMemberMP(i);
        member.hp = p:GetMemberHP(i);
        member.tp = p:GetMemberTP(i);
        member.hpp = p:GetMemberHPPercent(i);
        member.mpp = p:GetMemberMPPercent(i);
        member.zone = p:GetMemberZone(i);

        -- print(member.hpp);

        local buffs
        if (i == 0) then
            -- local player = AshitaCore:GetMemoryManager():GetPlayer()
            -- buffs = player:GetBuffs();
            -- member.hp = player.GetHP()
            buffs = AshitaCore:GetMemoryManager():GetPlayer():GetBuffs();
        else
            buffs = statusHandler.get_member_status(member.serverId);
        end

        member.rawBuffs = buffs;

        member.buffs = {};
        if (buffs) then
            for _, v in ipairs(buffs) do
                local buffName = AshitaCore:GetResourceManager():GetString('buffs.names', v);
                if (buffName) then
                    member.buffs[string.lower(buffName)] = true;
                else
                    -- print(v);
                end
            end
        end
        party[i + 1] = member;
    end
end);



return {
    debuffHandler = debuffHandler,
    statusHandler = statusHandler,
    castHandler = castHandler,
    wheelHandler = wheelHandler,
    party = party
};
