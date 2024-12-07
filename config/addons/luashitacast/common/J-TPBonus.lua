local action = require('common.events.action');
local encoding = require('encoding');
local ws_skill = require('common.WS-Map');
local profileSettings;

local subJobChange = require('events.jobChange').onSubJobChange;

local function S(t) 
    local res = T { }
    for _, v in ipairs(t) do
        res[v] = v;
    end
    return res;
end

local aeonic_weapons = S {
    "God Hands", "Aeneas", "Sequence", "Lionheart", "Ruinator", "Chango",
    "Anguta", "Trishula", "Heishi Shorinken", "Dojikiri Yasutsuna",
    "Tishtrya", "Khatvanga", "Fail-Not", "Fomalhaut"
}

local magian_weapons = S {
    "Barracudas +2", "Sphyras", "Fusetto +2", "Centovente", "Machaera +2",
    "Thibron", "Kalavejs +2", "Kauriraris", "Renaud's Axe +2", "Fernagu",
    "Sumeru +2", "Tavatimsa", "Reckoning +2", "Basanizo", "Stingray +2",
    "Sixgill", "Uzura +2", "Hitaki", "Keitonotachi +2", "Kantonotachi",
    "Makhila +2", "Ukaldi", "Sedikutchi +2", "Muruga", "Sparrowhawk +1",
    "Accipiter", "Anarchy +2", "Ataktos"
}

local warcry_source = 0
action:register(function(data_raw, unpackAction)
    local category = ashita.bits.unpack_be(data_raw, 0, 82, 4);
    local param = ashita.bits.unpack_be(data_raw, 0, 86, 16);

    if (category == 6 and param == 32) then
        local actionPacket = unpackAction();
        for _, target in ipairs(actionPacket.Targets) do
            if (target.Id == GetPlayerEntity().ServerId) then
                warcry_source = actionPacket.UserId;
            end
        end
    end
end);

-- Listen to party update packets to track the main job of party members
local member_jobs = {}
ashita.events.register('packet_in', 'tpbonus_packet_in_cb', function(e)
    if (e.id == 0x0dd) then
        local id = struct.unpack('L', e.data, 0x04 + 0x01);
        member_jobs[id] = struct.unpack('B', e.data, 0x22 + 0x01);
    end
end);


local fencer_tp_bonus = { [0] = 0, 200, 300, 400, 450, 500, 550, 600, 630 }
local function etp_gt(tp, gear_fencer)
    local job_fencer = 0
    local jp_tp_bonus = 0
    do
        local pPlayer = AshitaCore:GetMemoryManager():GetPlayer()
        
        local _mainJob = pPlayer:GetMainJob();
        local mainJob = AshitaCore:GetResourceManager():GetString("jobs.names_abbr", _mainJob);
        if (type(mainJob) == 'string') then
            mainJob = encoding:ShiftJIS_To_UTF8(mainJob:trimend('\x00'));
        end
        
        local _subJob = pPlayer:GetSubJob();
        local subJob = AshitaCore:GetResourceManager():GetString("jobs.names_abbr", _subJob);
        if (type(subJob) == 'string') then
            subJob = encoding:ShiftJIS_To_UTF8(subJob:trimend('\x00'));
        end
        
        if mainJob == 'WAR' then
            job_fencer = 5
            jp_tp_bonus = 230
        elseif mainJob == 'BST' then
            job_fencer = 3
            jp_tp_bonus = 230
        elseif mainJob == 'BRD' then
            job_fencer = 2
            jp_tp_bonus = 0
        elseif subJob == 'WAR' then
            if (pPlayer:getSubJobLevel() >= 58) then
                job_fencer = 2
            else
                job_fencer = 1
            end
            jp_tp_bonus = 0
        else
            job_fencer = 0
            jp_tp_bonus = 0
        end
    end
    
    gear_fencer = gear_fencer or 0
    
    return function(spell)
        local etp = AshitaCore:GetMemoryManager():GetParty():GetMemberTP(0);
        local player = AshitaCore:GetMemoryManager():GetPlayer();
        
        
        local main = profileSettings.Main and profileSettings.Main.value
        if (type(main) == 'table') then main = main.Name; end
        local sub = profileSettings.Sub and profileSettings.Sub.value
        if (type(sub) == 'table') then sub = sub.Name; end
        local range = profileSettings.Range and profileSettings.Range.value
        if (type(range) == 'table') then range = range.Name; end

        if spell.skill == 'Marksmanship' or spell.skill == 'Archery' then
            if aeonic_weapons[range] then
                etp = etp + 500
            end
        elseif aeonic_weapons[main] then
            etp = etp + 500
        end
        if magian_weapons[main] or magian_weapons[range] or
            magian_weapons[sub] then
            etp = etp + 1000
        end

        if (gData.GetBuffCount('Warcry')) then
            if warcry_source == GetPlayerEntity().ServerId and player:GetMainJob() == 1 then
                etp = etp + 500;
            else
                local party = AshitaCore:GetMemoryManager():GetParty();
                for i = 0, 5 do
                    if (party:GetMemberIsActive(i) == 1) then
                        local id = party:GetMemberServerId(i);
                        if (id == warcry_source) then
                            if member_jobs[id] == 1 then -- WAR
                                etp = etp + 350; -- 50 + 20 per merit
                                break;
                            end
                        end
                    end
                end
            end
        end



        local mainRes = main and AshitaCore:GetResourceManager():GetItemByName(main, 2);
        
        -- if player is single wielding a 1h weapon
        if main and bit.band(mainRes.Slots, 2) == 0 then
            local subRes = sub and AshitaCore:GetResourceManager():GetItemByName(sub, 2);
            if not subRes or subRes.Slots == 2 then
                etp = etp +
                    fencer_tp_bonus[math.min(job_fencer + gear_fencer,
                        8)] + jp_tp_bonus
            end
        end

        -- Shiva?
        if gData.GetBuffCount('TP Bonus') then etp = etp + 250 end

        return etp > tp
    end
end


return function(settings)
    profileSettings = settings;
    return etp_gt;
end