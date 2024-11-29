local event = require('event');

local hasteChange = event:new();

local packetsIncoming = T {};

local onSubJobChange = require('events.jobChange').onSubJobChange;

local onBuffGain = require('events.buffChange').buffGain;
local onBuffLoss = require('events.buffChange').buffLoss;
local buffactive = require('events.buffChange').buffs;
local onAction = require('events.action');

local jobDW = 0;
local function updateJobDW()
    local mainJob = gData.GetPlayer().MainJob;
    local subJob = gData.GetPlayer().SubJob;

    if (mainJob) == 'NIN' then
        jobDW = 35;
    elseif (mainJob == 'DNC') then
        jobDW = 35
    elseif (mainJob == 'THF') then
        jobDW = 30;
    elseif (subJob == 'NIN') then
        jobDW = 25;
    elseif (subJob == 'DNC') then
        jobDW = 15;
    end
end
updateJobDW();
onSubJobChange:register(updateJobDW);

local gearHaste = 256;
local function setGearHaste(haste) gearHaste = haste; end

local hasteLevel = 0;
onBuffGain:register(function(buffId)
    if (buffId == 33) then -- haste
        hasteChange:trigger(true);
    elseif (buffId == 228 or buffId == 214 or buffId == 604 or buffId == 580) then
        hasteChange:trigger(true);
    end
end);

onBuffLoss:register(function(buffId)
    if (buffId == 33) then -- haste
        hasteLevel = 0;
        hasteChange:trigger(true);
    elseif (buffId == 228 or buffId == 214 or buffId == 604 or buffId == 580) then
        hasteChange:trigger(true);
    end
end);

local marches = T { 'Honor March', 'Victory March', 'Advancing March' }
local marchHaste = {
    ['Honor March'] = 261, -- 174 without marcato
    ['Victory March'] = 293,
    ['Advancing March'] = 194
};

local function getMaHaste()
    local maHaste = 0;
    -- Haste/Haste2
    if (buffactive[33]) then
        maHaste = maHaste + (hasteLevel == 2 and 307 or 150);
    end

    -- Assume bards are playing optimal marches
    for i = 1, buffactive[214] or 0 do
        maHaste = maHaste + marchHaste[marches[i]];
    end

    if (buffactive[604]) then -- Mighty Guard
        maHaste = maHaste + 150;
    end

    if (buffactive[580]) then -- indi/geo haste
        maHaste = maHaste + 300;
    end

    return maHaste;
end

local hasteSambaTime = 0;
local hasteSambaPotency = 51;
local function expireHasteSamba()
    if (os.time() - hasteSambaTime >= 10) then hasteChange:trigger(); end
end

local function getJaHaste()
    local jaHaste = 0;
    jaHaste = jaHaste + ((os.time() - hasteSambaTime < 10) and hasteSambaPotency or 0)

    local mainJob = gData.GetPlayer().MainJob;

    local myIndex = AshitaCore:GetMemoryManager():GetParty():GetMemberTargetIndex(0);
    local petIndex = AshitaCore:GetMemoryManager():GetEntity():GetPetTargetIndex(myIndex);

    if (mainJob == 'DRG' and petIndex > 0 and AshitaCore:GetMemoryManager():GetEntity():GetHPPercent(petIndex) > 0) then
        jaHaste = jaHaste + 101;
    end

    return jaHaste;
end

local function getTotalHaste()
    local jaHaste = getJaHaste();
    local maHaste = getMaHaste();
    local embravaHaste = buffactive[228] and 266 or 0;

    jaHaste = jaHaste <= 256 and jaHaste or 256;
    maHaste = maHaste <= 448 and maHaste or 448;

    local total = gearHaste + jaHaste + maHaste + embravaHaste;
    return total <= 819 and total or 819;
end

local function getDwNeeded()
    return math.ceil((1 - (0.2 / ((1024 - getTotalHaste()) / 1024))) * 100 - jobDW)
end

local partyFromPacket = T {};

packetsIncoming[0x0DD] = function(e)
    local id = struct.unpack('L', e.data, 0x04 + 0x01);
    local mainJob = struct.unpack('B', e.data, 0x22 + 0x01);
    local subJob = struct.unpack('B', e.data, 0x24 + 0x01);

    partyFromPacket[id] = {
        id = id,
        mainJob = mainJob,
        subJob = subJob
    };
end

local membersHasteSamba = T {};
do
    local playerId;
    ashita.events.register('load', 'j-haste_player_id_cb', function()
        playerId = AshitaCore:GetMemoryManager():GetParty():GetMemberServerId(0);
    end);

    local function isTarget(action)
        for _, target in ipairs(action.Targets) do
            if (target.Id == playerId) then
                return true
            end
        end
        return false;
    end

    local function addMarch(march)
        for i = 1, 3 do
            if (marches[i] == march) then
                marches:remove(i)
                marches:insert(1, march)
                break
            end
        end
    end

    local mobHasteDazePotency = T {};
    onAction:register(function(data_raw, unpackAction)
        local category = ashita.bits.unpack_be(data_raw, 0, 82, 4);

        if (category == 4) then
            local action = unpackAction();
            if (isTarget(action)) then
                local param = action.Param;

                if (param == 57 and hasteLevel ~= 2) then
                    hasteLevel = 1;
                    hasteChange:trigger();
                elseif (param == 511) then
                    hasteLevel = 2;
                    hasteChange:trigger()
                elseif (param == 417) then
                    addMarch('Honor March');
                    hasteChange:trigger();
                elseif (param == 420) then
                    addMarch('Victory March');
                    hasteChange:trigger();
                elseif (param == 419) then
                    addMarch('Advancing March');
                    hasteChange:trigger();
                end
            end
        elseif (category == 1) then
            local actorId = ashita.bits.unpack_be(data_raw, 0, 40, 32);
            local targetId = ashita.bits.unpack_be(data_raw, 0, 150, 32);
            if (actorId == playerId) then
                local action = unpackAction();

                local meleeAttack = action.Targets[1].Actions[1];

                if (meleeAttack.hasAdditionalEffect == 1
                        and bit.band(meleeAttack.AdditionalEffect.Damage, 0x3F) == 23) then
                    local update;
                    if (os.time() - hasteSambaTime >= 10) then
                        update = true;
                    end

                    hasteSambaTime = os.time();
                    local newPotency = mobHasteDazePotency[targetId] or 51;
                    if (hasteSambaPotency ~= newPotency) then
                        update = true;
                    end

                    hasteSambaPotency = newPotency;

                    if (update) then
                        hasteChange:trigger();
                    end
                    ashita.tasks.once(10, expireHasteSamba)
                end
            end

            if (membersHasteSamba[actorId]) then
                if (partyFromPacket[actorId] and partyFromPacket[actorId].mainJob == 'DNC') then
                    mobHasteDazePotency[targetId] = 101;
                else
                    mobHasteDazePotency[targetId] = 51;
                end
            end
        end
    end)
end

packetsIncoming[0x076] = function(e)
    for k = 0, 4 do
        local id = struct.unpack('L', e.data, k * 0x30 + 0x05);
        if id ~= 0 then
            local hasteSamba = false
            for i = 1, 32 do
                -- Credit: Byrth, GearSwap
                local buff = struct.unpack('B', e.data, (k * 48 + 5 + 16 + i - 1)) + 256 *
                    (math.floor(
                        struct.unpack('B', e.data,
                            k * 48 + 5 + 8 +
                            math.floor((i - 1) / 4)) / 4 ^
                        ((i - 1) % 4)) % 4)

                if buff == 370 then -- Haste Samba
                    hasteSamba = true
                    break
                end
            end

            if hasteSamba then
                membersHasteSamba[id] = true
            else
                membersHasteSamba[id] = false
            end
        end
    end
end

ashita.events.register('packet_in', 'j-haste_packet_cb', function(e)
    if (packetsIncoming[e.id]) then
        packetsIncoming[e.id](e);
    end
end);

return setmetatable({}, {
    dwNeeded = { get = getDwNeeded },
    totalHaste = { get = getTotalHaste },
    gearHaste = { set = setGearHaste },
    onChange = hasteChange,

    __index = function(self, key)
        local v = getmetatable(self)[key]
        return v and v.get and v.get() or v
    end,
    __newindex = function(self, i, v)
        local prop = getmetatable(self)[i]
        if prop.set then prop.set(v) end
    end
});
