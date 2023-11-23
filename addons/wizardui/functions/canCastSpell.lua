local function canCastSpell(spellName)
    local player = AshitaCore:GetMemoryManager():GetPlayer();

    local spell = AshitaCore:GetResourceManager():GetSpellByName(spellName, 2);

    local spellLevel = spell.LevelRequired[player:GetMainJob() + 1];
    local jobLevel;

    if (spellName == 'Frazzle') then
        print(spellLevel);
    end
    if (spellLevel == -1) then
        spellLevel = spell.LevelRequired[player:GetSubJob() + 1];
        jobLevel = player:GetSubJobLevel();
    else
        jobLevel = player:GetMainJobLevel();
    end

    return (spellLevel > 0 and spellLevel <= jobLevel);
end

return canCastSpell;
