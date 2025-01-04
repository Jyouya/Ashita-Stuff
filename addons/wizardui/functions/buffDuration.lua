local INFINITE_DURATION = 0x7FFFFFFF
REALUTCSTAMP_ID = addon.name .. ':realutcstamp'

local pm = AshitaCore:GetPointerManager()
if (pm:Get(REALUTCSTAMP_ID) == 0) then
    pm:Add(REALUTCSTAMP_ID, 'FFXiMain.dll', '8B0D????????8B410C8B49108D04808D04808D04808D04C1C3', 2, 0)
end

local function get_utcstamp()
    local ptr = AshitaCore:GetPointerManager():Get(REALUTCSTAMP_ID)
    -- double dereference the pointer to get the correct address
    ptr = ashita.memory.read_uint32(ptr)
    ptr = ashita.memory.read_uint32(ptr)
    -- the utcstamp is at offset 0x0C
    return ashita.memory.read_uint32(ptr + 0x0C)
end

local function GetBuffDuration(raw_duration)

    if (raw_duration == INFINITE_DURATION) then
            return -1;
        end

        local vana_base_stamp = 0x3C307D70;
        --get the time since vanadiel epoch
        local offset = get_utcstamp() - vana_base_stamp;
        --multiply it by 60 to create like terms
        local comparand = offset * 60;
        --get actual time remaining
        local real_duration = raw_duration - comparand;
        --handle the triennial spillover..
        while (real_duration < -2147483648) do
            real_duration = real_duration + 0xFFFFFFFF;
        end

        if real_duration < 1 then
            return 0;
        else
            --convert to seconds..
            return math.ceil(real_duration * 100/6);
        end

        return 0
end

local function GetStatusEffectByName(effect_en)
    local buffs = AshitaCore:GetMemoryManager():GetPlayer():GetBuffs()

    local effect = string.lower(effect_en)
    for x = 1, 31 do
        if buffs[x] ~= -1 then
            if effect == string.lower(AshitaCore:GetResourceManager():GetString('buffs.names', buffs[x])) then
                return x
            end
        end
    end
    return nil
end



-- returns time in seconds (60.5 = 60 and a half seconds)
local function GetRemainingDurationOfStatusEffect(effect_en)

    local effect = GetStatusEffectByName(effect_en)

    if effect then
        return (GetBuffDuration(AshitaCore:GetMemoryManager():GetPlayer():GetStatusTimers()[effect]) / 1000)
    end

    return 0
end

return function(vanatime)
    return GetBuffDuration(vanatime) / 1000;
end