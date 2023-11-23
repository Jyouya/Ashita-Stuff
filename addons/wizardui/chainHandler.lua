--[[
* chainHandler is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* chainHandler is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with Ashita.  If not, see <https://www.gnu.org/licenses/>.
--]]


-- This uses a ton of code from Chains

local skills = require('skillchains.skills');
local event = require('event');

local burstOpen = event:new();
local burstClose = event:new();

local regex =
'(?:Liquefaction|Scission|Reverberation|Induration|Impaction|Detonation|Transfixion|Compression|Fragmentation|Fusion|Gravitation|Distortion|Light|Darkness)(?=(,|$|\\. WSC))';


-- Update WS properties from DAT
for k, v in pairs(skills[3]) do
    local ability = AshitaCore:GetResourceManager():GetAbilityByName(v.en, 2);
    local match = ashita.regex.search(ability.Description[1], regex);
    if (match) then
        skills[3][k].skillchain = table.map(match, function(m)
            return m[1];
        end);
    end
end

local petMessageTypes = T {
    110, -- '<user> uses <ability>. <target> takes <amount> damage.'
    317  -- 'The <player> uses .. <target> takes .. points of damage.'
};

local playerID;
--=============================================================================
-- event: load
-- desc: Event called when the addon is being loaded.
--=============================================================================
ashita.events.register('load', 'skillchain_load_playerID_cb', function()
    playerID = AshitaCore:GetMemoryManager():GetParty():GetMemberServerId(0);
end);

local SkillPropNames = T {
    [1] = 'Light',
    [2] = 'Darkness',
    [3] = 'Gravitation',
    [4] = 'Fragmentation',
    [5] = 'Distortion',
    [6] = 'Fusion',
    [7] = 'Compression',
    [8] = 'Liquefaction',
    [9] = 'Induration',
    [10] = 'Reverberation',
    [11] = 'Transfixion',
    [12] = 'Scission',
    [13] = 'Detonation',
    [14] = 'Impaction',
    [15] = 'Radiance',
    [16] = 'Umbra'
};

local MessageTypes = T {
    2,   -- '<caster> casts <spell>. <target> takes <amount> damage'
    --100, -- 'The <player> uses ..' -- Causes Super Jump to match as Spinning Axe if enabled
    110, -- '<user> uses <ability>. <target> takes <amount> damage.'
    --161, -- Additional effect: <number> HP drained from <target>.
    --162, -- Additional effect: <number> MP drained from <target>.
    185, -- 'player uses, target takes 10 damage. DEFAULT'
    187, -- '<user> uses <skill>. <amount> HP drained from <target>'
    317, -- 'The <player> uses .. <target> takes .. points of damage.'
    --529, -- '<user> uses <ability>. <target> is chainbound.',
    802  -- 'The <user> uses <skill>. <number> HP drained from <target>.'
}

--=============================================================================
-- Return true if another player belongs to the player's alliance.
---@param id number ServerId
---@return boolean
--=============================================================================
local function isPlayerInAlliance(id)
    local pParty = AshitaCore:GetMemoryManager():GetParty();

    for i = 0, 17 do
        if pParty:GetMemberIsActive(i) == 1 and pParty:GetMemberServerId(i) == id then
            return true
        end
    end

    return false
end

--=============================================================================
-- Return true if a pet belongs to the player's alliance.
---@param id number ServerId
---@return boolean
--=============================================================================
local function isPetInAlliance(id)
    local pParty = AshitaCore:GetMemoryManager():GetParty();
    local pEntity = AshitaCore:GetMemoryManager():GetEntity();

    for i = 0, 17 do
        if pParty:GetMemberIsActive(i) == 1 then
            local playerIndex = pParty:GetMemberTargetIndex(i);
            local petIndex = pEntity:GetPetTargetIndex(playerIndex);
            if pEntity:GetServerId(petIndex) == id then
                return true;
            end
        end
    end

    return false
end

--=============================================================================
---Return action property table with aeonic property added
---@param action table Action information
---@param actor integer Actor ID
---@return table propertyTable Updated property table
--=============================================================================
local GetAeonicProperty = function(action, actor)
    local propertyTable = table.copy(action.skillchain);

    if action.aeonic and (action.weapon or chains.forceAeonic > 0) and actor == playerID and GetAftermathLevel() > 0 then
        local main = GetEquipment().Main;
        local range = GetEquipment().Range;
        local validMain = action.weapon == (main and main.Name) or chains.forceAeonic > 0;
        local validRange = action.weapon == (range and range.Name);
        if validMain or validRange then
            table.insert(propertyTable, 1, action.aeonic);
        end
    end

    return propertyTable;
end

--=============================================================================
-- Return equipment data
---@return table equipTable Current equipment information
--=============================================================================
-- based on code from LuAshitacast by Thorny
--=============================================================================
-- Combined gData.GetEquipment and gEquip.GetCurrentEquip
--=============================================================================
local GetEquipment = function()
    local inventoryManager = AshitaCore:GetMemoryManager():GetInventory();
    local equipTable = {};

    for k, v in pairs(EquipSlotNames) do
        local equippedItem = inventoryManager:GetEquippedItem(k - 1);
        local index = bit.band(equippedItem.Index, 0x00FF);
        local eqEntry = {};
        if (index == 0) then
            eqEntry.Container = 0;
            eqEntry.Item = nil;
        else
            eqEntry.Container = bit.band(equippedItem.Index, 0xFF00) / 256;
            eqEntry.Item = inventoryManager:GetContainerItem(eqEntry.Container, index);
            if (eqEntry.Item.Id == 0) or (eqEntry.Item.Count == 0) then
                eqEntry.Item = nil;
            end
        end
        if (type(eqEntry) == 'table') and (eqEntry.Item ~= nil) then
            local resource = AshitaCore:GetResourceManager():GetItemById(eqEntry.Item.Id);
            if (resource ~= nil) then
                local singleTable = {};
                singleTable.Container = eqEntry.Container;
                singleTable.Item = eqEntry.Item;
                singleTable.Name = resource.Name[1];
                singleTable.Resource = resource;
                equipTable[v] = singleTable;
            end
        end
    end

    return equipTable;
end

-- store list of valid player/pet skills
-- * capture bluskill on 0x44 packet or first GetSkillchains call
-- * capture wepskill on 0xAC packet or first GetSkillchains call
-- * capture petskill on 0xAC packet or first GetSkillchains call
-- * capture schskill on load
local actionTable = T {
    schskill = skills.immanence,
};

-- store per player buff information
-- * player/buff added through action packet
-- * buff deleted through action packet when used or through presentevent on timeout
-- * player deleted through present event when no buff active
local playerTable = T {
};

-- store per target information on properties and duration
-- * target added through action packet
-- * target deleted through present event on timeout
local targetTable = T {
};

-- static information on skillchains
local chainInfo = T {
    Radiance      = T { level = 4, burst = T { 'Fire', 'Wind', 'Lightning', 'Light' } },
    Umbra         = T { level = 4, burst = T { 'Earth', 'Ice', 'Water', 'Dark' } },
    Light         = T { level = 3, burst = T { 'Fire', 'Wind', 'Lightning', 'Light' },
        aeonic = T { level = 4, skillchain = 'Radiance' },
        Light  = T { level = 4, skillchain = 'Light' },
    },
    Darkness      = T { level = 3, burst = T { 'Earth', 'Ice', 'Water', 'Dark' },
        aeonic   = T { level = 4, skillchain = 'Umbra' },
        Darkness = T { level = 4, skillchain = 'Darkness' },
    },
    Gravitation   = T { level = 2, burst = T { 'Earth', 'Dark' },
        Distortion    = T { level = 3, skillchain = 'Darkness' },
        Fragmentation = T { level = 2, skillchain = 'Fragmentation' },
    },
    Fragmentation = T { level = 2, burst = T { 'Wind', 'Lightning' },
        Fusion     = T { level = 3, skillchain = 'Light' },
        Distortion = T { level = 2, skillchain = 'Distortion' },
    },
    Distortion    = T { level = 2, burst = T { 'Ice', 'Water' },
        Gravitation = T { level = 3, skillchain = 'Darkness' },
        Fusion      = T { level = 2, skillchain = 'Fusion' },
    },
    Fusion        = T { level = 2, burst = T { 'Fire', 'Light' },
        Fragmentation = T { level = 3, skillchain = 'Light' },
        Gravitation   = T { level = 2, skillchain = 'Gravitation' },
    },
    Compression   = T { level = 1, burst = T { 'Darkness' },
        Transfixion = T { level = 1, skillchain = 'Transfixion' },
        Detonation  = T { level = 1, skillchain = 'Detonation' },
    },
    Liquefaction  = T { level = 1, burst = T { 'Fire' },
        Impaction = T { level = 2, skillchain = 'Fusion' },
        Scission  = T { level = 1, skillchain = 'Scission' },
    },
    Induration    = T { level = 1, burst = T { 'Ice' },
        Reverberation = T { level = 2, skillchain = 'Fragmentation' },
        Compression   = T { level = 1, skillchain = 'Compression' },
        Impaction     = T { level = 1, skillchain = 'Impaction' },
    },
    Reverberation = T { level = 1, burst = T { 'Water' },
        Induration = T { level = 1, skillchain = 'Induration' },
        Impaction  = T { level = 1, skillchain = 'Impaction' },
    },
    Transfixion   = T { level = 1, burst = T { 'Light' },
        Scission      = T { level = 2, skillchain = 'Distortion' },
        Reverberation = T { level = 1, skillchain = 'Reverberation' },
        Compression   = T { level = 1, skillchain = 'Compression' },
    },
    Scission      = T { level = 1, burst = T { 'Earth' },
        Liquefaction  = T { level = 1, skillchain = 'Liquefaction' },
        Reverberation = T { level = 1, skillchain = 'Reverberation' },
        Detonation    = T { level = 1, skillchain = 'Detonation' },
    },
    Detonation    = T { level = 1, burst = T { 'Wind' },
        Compression = T { level = 2, skillchain = 'Gravitation' },
        Scission    = T { level = 1, skillchain = 'Scission' },
    },
    Impaction     = T { level = 1, burst = T { 'Lightning' },
        Liquefaction = T { level = 1, skillchain = 'Liquefaction' },
        Detonation   = T { level = 1, skillchain = 'Detonation' },
    },
};

local function handleActionPacket(actionPacket)
    local actorId = actionPacket.UserId;
    local target = actionPacket.Targets[1];

    if (not target) then
        return;
    end

    local action = target.Actions[1];

    local category = petMessageTypes:contains(action.Message) and 13 or actionPacket.Type

    local actionSkill = skills[category] and skills[category][bit.band(actionPacket.Id, 0xFFFF)];

    local effectProperty = action.AdditionalEffect and
        SkillPropNames[bit.band(action.AdditionalEffect.Damage, 0x3F)];

    -- exit if actor is not in alliance
    -- We may want to disable this check for multi-alliance content like reeves/einherjar
    if not (isPlayerInAlliance(actorId) or isPetInAlliance(actorId)) then
        return;
    end

    if action and effectProperty then
        local step = (targetTable[target.Id] and targetTable[target.Id].step or 1) + 1
        local delay = actionSkill and actionSkill.delay or 3
        local level = chainInfo[effectProperty].level

        -- Check for Lv.3 -> Lv.3 and bump to Lv.4 for closure
        if level == 3 and targetTable[target.Id] and targetTable[target.Id].property[1] == effectProperty then
            level = 4;
        end
        local closed = level == 4;

        local ts = os.time();

        targetTable[target.Id] = {
            en = actionSkill.en,
            property = { effectProperty },
            ts = ts,
            dur = 8 - step + delay,
            wait = delay,
            step = step,
            closed = closed,
        };

        -- Create events for burst window open/close
        burstOpen:trigger();
        (function()
            -- If there have been no new skillchains in the past 10 seconds
            if (ts == targetTable[target.Id].ts) then
                burstClose:trigger();
            end
        end):once(10);

        -- Check for valid actor skill with valid message - generic first step (excluding chainbound)
        -- Include spells when SCH Immanence or BLU Azure Lore / Chain Affinity is active
        -- Immanence and Chain Affinity buff status cleared on use
    elseif actionSkill and MessageTypes:contains(action.Message) and (actionPacket.Type ~= 4 or (playerTable[actorId])) then
        local delay = actionSkill and actionSkill.delay or 3

        local targetData = targetTable[target.Id];

        -- If we are cancelling an open burst window with this ws, trigger the burstClose event
        if (targetData and targetData.step > 1 and targetData.ts > os.time() - 10) then
            burstClose:trigger();
        end

        targetTable[target.Id] = {
            en = actionSkill.en,
            property = GetAeonicProperty(actionSkill, actorId),
            ts = os.time(),
            dur = 7 + delay,
            wait = delay,
            step = 1,
        };

        -- Check for valid actor skill with chainbound message - chainbound first step
        -- Could be combined with previous first setp check
    elseif actionSkill and (action.Message == 529) then
        local ts = os.time();

        -- Create events for burst window open/close
        burstOpen:trigger();
        (function()
            -- If there have been no new skillchains in the past 10 seconds
            if (ts == targetTable[target.Id].ts) then
                burstClose:trigger();
            end
        end):once(10);
        targetTable[target.Id] = {
            en = actionSkill.en,
            property = actionSkill.skillchain,
            ts = ts,
            dur = 9,
            wait = 2,
            step = 1,
            bound = action.Param,
        };
    end
end


local function handleMessagePacket(data)
    if (struct.unpack('H', data, 0x18 + 1) == 206 and struct.unpack('I', data, 8 + 1) == playerID) then
        local effect = struct.unpack('H', data, 0xC + 1)
        if playerTable[playerID] and playerTable[playerID][effect] then
            playerTable[playerID][effect] = nil;
        end
    end
end

-- 0x0AC
local function handleAbilityPacket(e)
    actionTable.wepskill = T {};
    actionTable.petskill = T {};

    -- Packet contains one bit per ability to indicate if the ability is available
    -- * Byte in packet = floor(abilityID / 8) + 1
    -- * Bit in byte = abilityID % 8
    -- Logic does the following:
    -- * extract byte
    -- * shift bits right to move relavent bit to bit[0]
    -- * mask upper bits and compare to 1 (or >0)
    -- * alt equation: bit.band(bit.rshift(data:byte(math.floor(k/8)+1),(k%8)),0x01) == 1

    -- Weaponskills
    local data = e.data:sub(5);
    for k, v in pairs(skills[3]) do
        if math.floor((data:byte(math.floor(k / 8) + 1) % 2 ^ (k % 8 + 1)) / 2 ^ (k % 8)) == 1 then
            table.insert(actionTable.wepskill, v);
        end
    end

    -- BST/SMN PetSkills - fix: skip if not BST or SMN?
    data = e.data:sub(69);
    for k, v in pairs(skills.playerPet) do
        if math.floor((data:byte(math.floor(k / 8) + 1) % 2 ^ (k % 8 + 1)) / 2 ^ (k % 8)) == 1 then
            table.insert(actionTable.petskill, v);
        end
    end

    -- Reset skillchains on all active targets
    ResetSkillchains();
end

return T {
    HandleActionPacket = handleActionPacket,
    HandleMessagePacket = handleMessagePacket,
    HandleAbilityPacket = handleAbilityPacket,

};
