-- Pulled from statustimers - Copyright (c) 2022 Heals
-- Pulled from HXUI
-------------------------------------------------------------------------------
-- imports
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- local state
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- local constants
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- local functions
-------------------------------------------------------------------------------

local ptrPartyBuffs = ashita.memory.find('FFXiMain.dll', 0, 'B93C0000008D7004BF????????F3A5', 9, 0);
ptrPartyBuffs = ashita.memory.read_uint32(ptrPartyBuffs);

-- Call once at plugin load and keep reference to table
local function ReadPartyBuffsFromMemory()
    local ptrPartyBuffs = ashita.memory.read_uint32(AshitaCore:GetPointerManager():Get('party.statusicons'));
    local partyBuffTable = {};
    for memberIndex = 0, 4 do
        local memberPtr = ptrPartyBuffs + (0x30 * memberIndex);
        local playerId = ashita.memory.read_uint32(memberPtr);
        if (playerId ~= 0) then
            local buffs = {};
            local empty = false;
            for buffIndex = 0, 31 do
                if empty then
                    buffs[buffIndex + 1] = -1;
                else
                    local highBits = ashita.memory.read_uint8(memberPtr + 8 + (math.floor(buffIndex / 4)));
                    local fMod = math.fmod(buffIndex, 4) * 2;
                    highBits = bit.lshift(bit.band(bit.rshift(highBits, fMod), 0x03), 8);
                    local lowBits = ashita.memory.read_uint8(memberPtr + 16 + buffIndex);
                    local buff = highBits + lowBits;
                    if buff == 255 then
                        empty = true;
                        buffs[buffIndex + 1] = -1;
                    else
                        buffs[buffIndex + 1] = buff;
                    end
                end
            end
            partyBuffTable[playerId] = buffs;
        end
    end
    return partyBuffTable;
end
local partyBuffs = ReadPartyBuffsFromMemory();

-------------------------------------------------------------------------------
-- exported functions
-------------------------------------------------------------------------------
local statusHandler = {};

-- return a table of status ids for a party member based on server id.
---@param server_id number the party memer or target server id to check
---@return table status_ids a list of the targets status ids or nil
statusHandler.get_member_status = function(server_id)
    return partyBuffs[server_id];
end

--Call with incoming packet 0x076
statusHandler.ReadPartyBuffsFromPacket = function(e)
    local partyBuffTable = {};
    for i = 0, 4 do
        local memberOffset = 0x04 + (0x30 * i) + 1;
        local memberId = struct.unpack('L', e.data, memberOffset);
        if memberId > 0 then
            local buffs = {};
            local empty = false;
            for j = 0, 31 do
                if empty then
                    buffs[j + 1] = -1;
                else
                    --This is at offset 8 from member start.. memberoffset is using +1 for the lua struct.unpacks
                    local highBits = bit.lshift(ashita.bits.unpack_be(e.data_raw, memberOffset + 7, j * 2, 2), 8);
                    local lowBits = struct.unpack('B', e.data, memberOffset + 0x10 + j);
                    local buff = highBits + lowBits;
                    if (buff == 255) then
                        buffs[j + 1] = -1;
                        empty = true;
                    else
                        buffs[j + 1] = buff;
                    end
                end
            end
            partyBuffTable[memberId] = buffs;
        end
    end
    partyBuffs = partyBuffTable;
end

return statusHandler;
