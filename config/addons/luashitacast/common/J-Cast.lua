local spellMap = gFunc.LoadFile('common/J-Map.lua');
local tempPetMap = gFunc.LoadFile('common/J-PetMap.lua');
local petMap = {};
for k, v in pairs(tempPetMap) do
    petMap[k] = v;
    petMap[k..'\0'] = v;
end

require('sugar');

return function(settings)
    local profile = {};
    local sets = {};
    profile.OnLoad = function()
        -- gSettings.AllowAddSet = true;
    end

    profile.OnUnload = function()
    end


    profile.commands = T {};
    profile.HandleCommand = function(args)
        local cmd = table.remove(args, 1);
        if (profile.commands[cmd]) then
            profile.commands[cmd](args);
        end
    end

    local function setCombine(...)
        local res = T {};
        for _, set in ipairs({ ... }) do
            for k, v in pairs(set) do
                res[k] = v;
            end
        end
        return res;
    end


    local function equip(set)
        if (set) then
            gFunc.EquipSet(gFunc.Combine(set, {}));
        end
    end

    local function interimEquip(set)
        if (set) then
            gFunc.InterimEquipSet(gFunc.Combine(set, {}));
        end
    end

    local function pascalCase(string)
        string = string or "";
        local res = "";
        local caps = true;
        for i = 1, #string do
            local c = string:sub(i, i);
            if (c == '_' or c == ' ' or c == ':') then
                caps = true;
            elseif (c ~= '\'') then
                if (caps) then
                    c = c:upper();
                    caps = false;
                end
                res = res .. c;
            end
        end
        return res;
    end

    local function buildSetName(breadcrumbs, ...)
        local len = #breadcrumbs;
        if (len == 0) then return ''; end
        local res = breadcrumbs[1];
        for i = 2, len do
            res = res .. '_' .. breadcrumbs[i];
        end
        for _, v in ipairs({ ... }) do
            if v then
                res = res .. '_' .. v;
            end
        end
        return res;
    end

    local function EvaluateItem(item, level)
        if type(item) == 'string' then
            local resource = AshitaCore:GetResourceManager():GetItemByName(item, 0);
            if (resource ~= nil) then
                return (level >= resource.Level);
            end
        elseif type(item) == 'table' then
            if type(item.Level) == 'number' then
                return (level >= item.Level);
            else
                local resource = AshitaCore:GetResourceManager():GetItemByName(item.Name, 0);
                if (resource ~= nil) then
                    return (level >= resource.Level);
                end
            end
        end
        return false;
    end

    local function syncCombine(...)
        local level = AshitaCore:GetMemoryManager():GetPlayer():GetMainJobLevel();

        local res = T {};
        for _, set in ipairs({ ... }) do
            for k, v in pairs(set) do
                if (type(v) ~= 'string' or EvaluateItem(v, level)) then
                    res[k] = v;
                end
            end
        end
        return res;
    end


    local function levelSyncSet(set)
        local level = AshitaCore:GetMemoryManager():GetPlayer():GetMainJobLevel();
        local newSet = {};
        for slotName, slotEntries in pairs(set) do
            if (gData.Constants.EquipSlots[slotName] ~= nil) then
                if type(slotEntries) == 'string' then
                    newSet[slotName] = slotEntries;
                elseif type(slotEntries) == 'table' then
                    if slotEntries[1] == nil then
                        newSet[slotName] = slotEntries;
                    else
                        for _, potentialEntry in ipairs(slotEntries) do
                            if EvaluateItem(potentialEntry, level) then
                                newSet[slotName] = potentialEntry;
                                break;
                            end
                        end
                    end
                end
            else
                newSet[slotName] = slotEntries;
            end
        end
        return newSet;
    end

    local function copySet(set)
        local res = {};
        for k, v in pairs(set) do
            res[k] = v;
        end
        return res;
    end

    function sets:hasSet(breadcrumbs, ...)
        local keystart = buildSetName(breadcrumbs, ...);
        for k, _ in pairs(self) do
            if (string.sub(k, 1, string.len(keystart)) == keystart) then
                return true;
            end
        end
    end

    function sets:match(breadcrumbs)
        local breadcrumbsCopy = { table.unpack(breadcrumbs) }
        for _, _ in ipairs(breadcrumbsCopy) do
            if (sets[buildSetName(breadcrumbsCopy)]) then
                return sets[buildSetName(breadcrumbsCopy)];
            end
            table.remove(breadcrumbsCopy);
        end
    end

    local function getSet(base, isPetAction)
        local breadcrumbs = T { base };
        local action = isPetAction and gData.GetPetAction() or gData.GetAction();

        local category;

        if (action) then
            action.Map = (isPetAction and petMap or spellMap)[action.Name];
            local name = pascalCase(action.Name);
            local type = pascalCase(action.Type);
            local skill = pascalCase(action.Skill);

            if (sets:hasSet(breadcrumbs, action.Name)) then
                breadcrumbs:insert(action.Name);
                category = action.Name;
            elseif (sets:hasSet(breadcrumbs, name)) then
                breadcrumbs:insert(name);
                category = name;
            elseif (action.Map and sets:hasSet(breadcrumbs, action.Map)) then
                breadcrumbs:insert(action.Map);
                category = action.Map;
            elseif (sets:hasSet(breadcrumbs, action.Type)) then
                breadcrumbs:insert(action.Type);
                category = action.Type;
            elseif (sets:hasSet(breadcrumbs, type)) then
                breadcrumbs:insert(type);
                category = type;
            elseif (sets:hasSet(breadcrumbs, action.Skill)) then
                breadcrumbs:insert(action.Skill);
                category = action.Skill;
            elseif (sets:hasSet(breadcrumbs, skill)) then
                breadcrumbs:insert(skill);
                category = skill;
            end
        end

        local mainHand = settings.Main and settings.Main.value;
        local offHand = settings.Sub and settings.Sub.value;
        if (mainHand and sets:hasSet(breadcrumbs, mainHand)) then
            breadcrumbs:insert(mainHand);

            if (offHand and sets:hasSet(breadcrumbs, offHand)) then
                breadcrumbs:insert(offHand);
            end
        end

        local range = settings.Range and settings.Range.value;
        if (range and sets:hasSet(breadcrumbs, range)) then
            breadcrumbs:insert(range);
        end

        local aftermathLevel = 0;
        if (gData.GetBuffCount('Aftermath: Lv.3')) then
            aftermathLevel = 3;
        elseif (gData.GetBuffCount('Aftermath: Lv.2')) then
            aftermathLevel = 2;
        elseif (gData.GetBuffCount('Aftermath: Lv.1') or gData.GetBuffCount('Aftermath')) then
            aftermathLevel = 1;
        end

        if (aftermathLevel == 3 and sets:hasSet(breadcrumbs, 'AM3')) then
            breadcrumbs:insert('AM3');
        elseif (aftermathLevel >= 2 and sets:hasSet(breadcrumbs, 'AM2')) then
            breadcrumbs:insert('AM2');
        elseif (aftermathLevel >= 1) then
            if (sets:hasSet(breadcrumbs, 'AM1')) then
                breadcrumbs:insert('AM1');
            elseif (sets:hasSet(breadcrumbs, 'AM')) then
                breadcrumbs:insert('AM');
            end
        end

        -- Option for event (Midcast/Engaged/etc)
        local baseSetting = settings[base] and settings[base].value;
        if (sets:hasSet(breadcrumbs, baseSetting)) then
            breadcrumbs:insert(baseSetting);
        end

        -- Option for spell category (Cure/MndEnfeeble/EnhancingMagic)
        local spellSetting = settings[category] and settings[category].value;
        if (sets:hasSet(breadcrumbs, spellSetting)) then
            breadcrumbs:insert(spellSetting);
        end

        -- Do user defined rules or whatever
        if (settings.Rules and settings.Rules[base]) then
            for _, rule in ipairs(settings.Rules[base]) do
                if rule.test(action) then
                    local key = type(rule.key) == 'function' and rule.key(action) or rule.key;
                    if (sets:hasSet(breadcrumbs, key)) then
                        breadcrumbs:insert(key);
                    end
                end
            end
        end

        if (not sets:match(breadcrumbs)) then return end -- No gear needs to be swapped
        local finalSet = sets:match(breadcrumbs);
        local equipSet = copySet(finalSet);              -- Shallow copy the set, for some reason

        -- Do swaps
        if (equipSet.swaps) then
            for _, swap in ipairs(equipSet.swaps) do
                if (swap.test(action)) then
                    finalSet = syncCombine(finalSet, swap);
                end
            end
        end

        finalSet = levelSyncSet(finalSet);

        -- If a set specifies that pet actions take precedence, see if we have pet gear to equipo
        if (finalSet.petPriority and gData.GetPetAction()) then
            local petSet = getSet('Pet', true);

            if (petSet) then
                return petSet;
            end
        end

        if (mainHand or range) then
            local swapManagedWeapons = finalSet.swapManagedWeapons;
            if (not (swapManagedWeapons and swapManagedWeapons())) then
                if (mainHand) then
                    finalSet = setCombine(finalSet, { Main = mainHand });
                end

                if (offHand) then
                    finalSet = setCombine(finalSet, { Sub = offHand });
                end

                if (range and range ~= 'Auto') then
                    finalSet = setCombine(finalSet, { Range = range });
                    local ammo = settings.Ammo.value;
                    if (ammo and ammo ~= 'Auto') then
                        finalSet = setCombine(finalSet, { Ammo = ammo });
                    end
                end
            end
        end
        -- print(buildSetName(breadcrumbs));
        return finalSet;
    end

    profile.HandleDefault = function()
        local player = gData.GetPlayer();
        local petAction = gData.GetPetAction();
        local petSet = petAction and getSet('Pet', true);

        if (player.Status == 'Engaged') then
            equip(petSet or getSet('Engaged'));
        elseif (player.Status == 'Resting') then
            equip(petSet or getSet('Resting'));
        else
            equip(petSet or getSet('Idle'));
        end
    end

    profile.HandleAbility = function() -- JA
        equip(getSet('JA'));
    end

    profile.HandleItem = function()
        equip(getSet('Item'));
    end

    profile.HandlePrecast = function()
        equip(getSet('Precast'));
    end

    profile.HandleMidcast = function()
        local set = getSet('Midcast');

        local castTime = set and set.CastTime or gData.GetAction().CastTime;

        local castDelay = ((castTime * (1 - settings.fastcast)) / 1000) - settings.minimumBuffer;
        if (castDelay >= settings.packetDelay) then
            gFunc.SetMidDelay(castDelay);
            interimEquip(getSet('SIRD'));
        end

        equip(set);
    end

    -- TODO: Make test cases for preshot/midshot and test them
    profile.HandlePreshot = function()
        equip(getSet('Preshot'));
    end

    profile.HandleMidshot = function()
        equip(getSet('Midshot'));
    end

    profile.HandleWeaponskill = function()
        equip(getSet('Weaponskill'));
    end

    return profile, sets;
end
