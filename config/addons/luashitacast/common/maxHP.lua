local memo = T {}

local function hpForGear(gear)
    if (memo[gear]) then
        return memo[gear];
    end

    if (type(gear) == 'function') then
        memo[gear] = 0;
        return 0;
    end

    local name;
    local hp = 0;
    if (type(gear) == 'table') then
        name = gear.Name;

        -- Try to account for augment HP
        if (gear.Augment) then
            for _, v in ipairs(gear.Augment) do
                local match = v:match("HP%+(%d+)");
                if (match) then
                    hp = hp + tonumber(match);
                end
            end
        end
    else
        name = gear;
    end

    if (not name) then
        memo[gear] = 0;
        return 0;
    end

    local item = AshitaCore:GetResourceManager():GetItemByName(name, 2);

    if (not item) then
        print('Item not found: ' .. name);
    end
    local description = item.Description[1]; -- JP

    local match = description:match("(^HP%+(%d+))") or description:match("\nHP%+(%d+)")
    if (match) then
        hp = hp + tonumber(match);
    end

    memo[gear] = hp;
    return hp;
end

local function hpForGearSet(_, set)
    local hp = 0;
    for _, gear in pairs(set) do
        hp = hp + hpForGear(gear);
    end
    return hp;
end

local res = T {};

function res.override(key, value)
    if (key == nil) then
        print('Error: Nil passed to maxHP.override');
        return;
    end
    memo[key] = value;
end

setmetatable(res, {
    __call = hpForGearSet
})

return res;
