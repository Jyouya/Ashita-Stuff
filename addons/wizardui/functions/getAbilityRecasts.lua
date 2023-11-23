local function getAbilityRecasts()
    local recastManager = AshitaCore:GetMemoryManager():GetRecast();
    local res = T {};
    for i = 0, 31 do
        local id = recastManager:GetAbilityTimerId(i);
        if (not res[id]) then 
            res[id] = recastManager:GetAbilityTimer(i);
        end
    end

    return res
end

return getAbilityRecasts;
