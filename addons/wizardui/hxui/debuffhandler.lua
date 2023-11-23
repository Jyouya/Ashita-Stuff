-- GNU Licensed by mousseng's XITools repository [https://github.com/mousseng/xitools]
require('common');
require('hxui.helpers');
local buffTable = require('hxui.bufftable');

local debuffHandler =
    T {
        -- All enemies we have seen take a debuff
        enemies = T {},
    };

-- TO DO: Audit these messages for which ones are actually useful
local statusOnMes = T { 160, 164, 166, 186, 194, 203, 205, 230, 236, 266, 267, 268, 269, 237, 271, 272, 277, 278, 279, 280, 319, 320, 375, 412, 645, 754, 755, 804 };
local statusOffMes = T { 206, 64, 159, 168, 204, 206, 321, 322, 341, 342, 343, 344, 350, 378, 531, 647, 805, 806 };
local deathMes = T { 6, 20, 97, 113, 406, 605, 646 };
local spellDamageMes = T { 2, 252, 264, 265 };

local enspells = T {
    [100] = 94,
    [101] = 95,
    [102] = 96,
    [103] = 97,
    [104] = 98,
    [105] = 99,

    [310] = 274,
    [311] = 288,

    [312] = 277,
    [313] = 278,
    [314] = 279,
    [315] = 280,
    [316] = 281,
    [317] = 282,

    [855] = 274,
    [856] = 288,
}

local function ApplyMessage(debuffs, action)
    if (action == nil) then
        return;
    end

    local now = os.time()

    for _, target in pairs(action.Targets) do
        for _, ability in pairs(target.Actions) do
            -- Set up our state
            local spell = action.Param
            local message = ability.Message

            if (debuffs[target.Id] == nil) then
                debuffs[target.Id] = T {};
            end

            -- Bio and Dia
            if action.Type == 4 and spellDamageMes:contains(message) then
                local expiry = nil

                if spell == 23 or spell == 33 or spell == 230 then
                    expiry = now + 60
                elseif spell == 24 or spell == 231 then
                    expiry = now + 120
                elseif spell == 25 or spell == 232 then
                    expiry = now + 150
                end

                if spell == 23 or spell == 24 or spell == 25 or spell == 33 then
                    -- Cancel bio when dia lands
                    debuffs[target.Id][134] = expiry
                    debuffs[target.Id][135] = nil
                elseif spell == 230 or spell == 231 or spell == 232 then
                    -- Cancel dia when bio lands
                    debuffs[target.Id][134] = nil
                    debuffs[target.Id][135] = expiry
                end
            elseif action.Type == 4 and enspells[spell] then
                -- Make enspells cancel other enspells, set duration to 3 minutes
                for _, buffId in pairs(enspells) do
                    debuffs[target.Id][buffId] = nil
                end
                debuffs[target.Id][enspells[spell]] = 180
            elseif statusOnMes:contains(message) then
                -- Regular debuffs
                local buffId = ability.Param or (action.Type == 4 and buffTable.GetBuffIdBySpellId(spell) or nil);
                if (buffId == nil) then
                    return
                end

                if spell == 58 or spell == 80 then                                       -- para/para2
                    debuffs[target.Id][buffId] = now + 120
                elseif spell == 56 or spell == 79 then                                   -- slow/slow2
                    debuffs[target.Id][buffId] = now + 180
                elseif spell == 216 then                                                 -- gravity
                    debuffs[target.Id][buffId] = now + 120
                elseif spell == 254 or spell == 276 then                                 -- blind/blind2
                    debuffs[target.Id][buffId] = now + 180
                elseif spell == 59 or spell == 359 then                                  -- silence/ga
                    debuffs[target.Id][buffId] = now + 120
                elseif spell == 253 or spell == 259 or spell == 273 or spell == 274 then -- sleep/2/ga/2
                    debuffs[target.Id][buffId] = now + 90
                elseif spell == 258 or spell == 362 then                                 -- bind
                    debuffs[target.Id][buffId] = now + 60
                elseif spell == 252 then                                                 -- stun
                    debuffs[target.Id][buffId] = now + 5
                elseif spell <= 229 and spell >= 220 then                                -- poison/2
                    debuffs[target.Id][buffId] = now + 120
                    -- Elemental debuffs
                elseif spell == 239 then          -- shock
                    debuffs[target.Id][buffId] = now + 120
                    debuffs[target.Id][133] = nil -- overwrites drown
                elseif spell == 238 then          -- rasp
                    debuffs[target.Id][buffId] = now + 120
                    debuffs[target.Id][132] = nil -- overwrites shock
                elseif spell == 237 then          -- choke
                    debuffs[target.Id][buffId] = now + 120
                    debuffs[target.Id][131] = nil -- overwrites rasp
                elseif spell == 236 then          -- frost
                    debuffs[target.Id][buffId] = now + 120
                    debuffs[target.Id][130] = nil -- overwrites choke
                elseif spell == 235 then          -- burn
                    debuffs[target.Id][buffId] = now + 120
                    debuffs[target.Id][129] = nil -- overwrites frost
                elseif spell == 240 then          -- drown
                    debuffs[target.Id][buffId] = now + 120
                    debuffs[target.Id][128] = nil -- overwrites Burn
                else                              -- Handle unknown status effect @ 5 minutes
                    debuffs[target.Id][buffId] = now + 300;
                end
            elseif statusOffMes:contains(message) then
                -- print('debug');
                -- print(ability.Param);
                -- print(action.Param)
                if action.Type == 6 then
                    debuffs[target.Id][ability.Param] = nil;
                else
                    debuffs[target.Id][ability.Param] = nil;
                end
            end
        end
    end
end

local function ClearMessage(debuffs, basic)
    -- if we're tracking a mob that dies, reset its status
    if deathMes:contains(basic.message) and debuffs[basic.target] then
        debuffs[basic.target] = nil
    elseif statusOffMes:contains(basic.message) then
        if debuffs[basic.target] == nil then
            return
        end

        -- Clear the buffid that just wore off
        if (basic.param ~= nil) then
            debuffs[basic.target][basic.param] = nil;
        end
    end
end

debuffHandler.HandleActionPacket = function(e)
    ApplyMessage(debuffHandler.enemies, e);
end

debuffHandler.HandleZonePacket = function(e)
    debuffHandler.enemies = {};
end

debuffHandler.HandleMessagePacket = function(e)
    ClearMessage(debuffHandler.enemies, e);
end

debuffHandler.GetActiveDebuffs = function(serverId)
    if (debuffHandler.enemies[serverId] == nil) then
        return nil;
    end
    local returnTable = {};
    for k, v in pairs(debuffHandler.enemies[serverId]) do
        if (v ~= 0 and v > os.time()) then
            returnTable[k] = k;
        end
    end
    return returnTable;
end

return debuffHandler;
