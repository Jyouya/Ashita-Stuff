local profileSettings;

local predicate_factory = {}

-- predicate_factory.etp_gt = function(n)
--     return function() return false; end
-- end

function predicate_factory.always_true() return true; end

function predicate_factory.always_false() return false; end

function predicate_factory.distance_gt(dist)
    return function(action)
        return action.Target.Distance +
            AshitaCore:GetMemoryManager():GetEntity():GetModelSize(action.Target.Index) > dist
    end
end

function predicate_factory.distance_gte(dist)
    return function(action)
        return action.Target.Distance +
            AshitaCore:GetMemoryManager():GetEntity():GetModelSize(action.Target.Index) >= dist
    end
end

function predicate_factory.distance_lt(dist)
    return function(action)
        return action.Target.Distance +
            AshitaCore:GetMemoryManager():GetEntity():GetModelSize(action.Target.Index) < dist
    end
end

function predicate_factory.distance_lte(dist)
    return function(action)
        return action.Target.Distance +
            AshitaCore:GetMemoryManager():GetEntity():GetModelSize(action.Target.Index) <= dist
    end
end

do
    local opposing_element = {
        Fire = 'Water',
        Ice = 'Fire',
        Wind = 'Ice',
        Earth = 'Wind',
        Thunder = 'Earth',
        Water = 'Thunder',
        Light = 'Dark',
        Dark = 'Light'
    }
    local function hachirin_bonus_tier(action)
        local action_element = action and action.Element;
        local env = gData.GetEnvironment();
        local bonus = 0;

        local intensity = 2 - gData.GetWeather() % 2;

        if env.WeatherElement == action_element then
            bonus = intensity
        elseif env.WeatherElement == opposing_element[action_element] then
            bonus = -intensity
        end

        if env.DayElement == action_element then
            bonus = bonus + 1
        elseif env.DayElement == opposing_element[action_element] then
            bonus = bonus - 1
        end
        return bonus
    end

    local function elemental_bonus_tier(action)
        local action_element = action and action.element;
        local bonus = 0;
        local env = gData.GetEnvironment();

        if env.WeatherElement == action_element then
            bonus = 2 - gData.GetWeather() % 2;
        end

        if env.DayElement == action_element then
            bonus = bonus + 1;
        end
        return bonus;
    end

    function predicate_factory.hachirin_bonus(level)
        level = level or 1
        return function(action) return hachirin_bonus_tier(action) >= level end
    end

    function predicate_factory.hachirin(action)
        local bonus = hachirin_bonus_tier(action)
        return bonus >= 2 or (bonus > 0 and action.Target.Distance > 7)
    end

    function predicate_factory.orpheus(action)
        return hachirin_bonus_tier(action) < 2 and action.Target.Distance <= 7
    end

    function predicate_factory.elemental_obi_bonus(level)
        level = level or 1
        return function(action)
            return elemental_bonus_tier(action) >= level
        end
    end

    function predicate_factory.orpheus_ele(action)
        return elemental_bonus_tier(action) < 2 and action.Target.Distance <= 7
    end

    function predicate_factory.elemental_obi(action)
        local bonus = elemental_bonus_tier(action)
        return bonus >= 2 or (bonus > 0 and action.Target.Distance > 7)
    end
end

function predicate_factory.tp_gte(tp)
    return function(action) return action.Player.TP >= tp end
end

function predicate_factory.time_between(start_time, end_time)
    if end_time < start_time then
        return function()
            local timestamp = gData.GetTimestamp();
            local time = timestamp.hour + (timestamp.minute / 100);
            return time <= end_time or time >= start_time
        end
    else
        return function()
            local timestamp = gData.GetTimestamp();
            local time = timestamp.hour + (timestamp.minute / 100);
            return time >= start_time and time <= end_time
        end
    end
end

function predicate_factory.buff_active(...)
    local n = select('#', ...);

    if n == 0 then
        error('buff_active requires at least one buff name');
    elseif n == 1 then
        local buff = select(1, ...);
        return function() return gData.GetBuffCount(buff) > 0; end
    else
        local buffs = { ... };
        return function()
            for _, buff in ipairs(buffs) do
                if not gData.GetBuffCount(buff) > 0 then return false; end
            end
            return true;
        end
    end
end

function predicate_factory.equipped(slot, item_name)
    return function()
        return gData.GetEquipment()[slot].Name == item_name;
    end
end

function predicate_factory.hpp_lt(value)
    return function(action) return action.Player.HPP < value end
end

function predicate_factory.hpp_lte(value)
    return function(action) return action.Player.HPP <= value end
end

function predicate_factory.hpp_gt(value)
    return function(action) return action.Player.HPP > value end
end

function predicate_factory.hpp_gte(value)
    return function(action) return action.Player.HPP >= value end
end

function predicate_factory.hp_lt(value)
    return function(action) return action.Player.HP < value end
end

function predicate_factory.hp_lte(value)
    return function(action) return action.Player.HP <= value end
end

function predicate_factory.hp_gt(value)
    return function(action) return action.Player.HP > value end
end

function predicate_factory.hp_gte(value)
    return function(action) return action.Player.HP >= value end
end

function predicate_factory.mpp_lt(value)
    return function(action) return action.Player.MPP < value end
end

function predicate_factory.mpp_lte(value)
    return function(action) return action.Player.MPP <= value end
end

function predicate_factory.mpp_gt(value)
    return function(action) return action.Player.MPP > value end
end

function predicate_factory.mpp_gte(value)
    return function(action) return action.Player.MPP >= value end
end

function predicate_factory.mp_lt(value)
    return function(action) return action.Player.MP < value end
end

function predicate_factory.mp_lte(value)
    return function(action) return action.Player.MP <= value end
end

function predicate_factory.mp_gt(value)
    return function(action) return action.Player.MP > value end
end

function predicate_factory.mp_gte(value)
    return function(action) return action.Player.MP >= value end
end

function predicate_factory.p_and(...)
    local args = { ... }
    return function(...)
        for _, fn in ipairs(args) do if not fn(...) then return false end end
        return true
    end
end

function predicate_factory.p_or(...)
    local args = { ... }
    return function(...)
        for _, fn in ipairs(args) do if fn(...) then return true end end
        return false
    end
end

function predicate_factory.p_not(fn)
    return function(...)
        return not fn(...)
    end
end

function predicate_factory.magic_skill(skill)
    return function(action)
        return action.Skill == skill;
    end
end

function predicate_factory.action_name(name)
    return function(action)
        return action.Name == name;
    end
end

return function(settings)
    profileSettings = settings;
    predicate_factory.etp_gt = require('common.J-TPBonus')(settings);

    return predicate_factory;
end
