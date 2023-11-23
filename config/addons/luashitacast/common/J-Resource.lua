local ac = AshitaCore;

local rm = ac:GetResourceManager();

local overrides = T {};

local function mergeSpell(spell)
    local overrideSpell = overrides[spell.Id];

    if (overrideSpell) then
        local newSpell = {
            Index = spell.Index,
            Type = spell.Type,
            Element = spell.Element,
            Targets = spell.Target,
            Skill = spell.Skill,
            ManaCost = spell.ManaCost,
            CastTime = overrideSpell.CastTime or spell.CastTime,
            RecastDelay = spell.RecastDelay,
            LevelRequired = spell.LevelRequired,
            Id = spell.Id,
            ListIconNQ = spell.ListIconNQ,
            ListIconHQ = spell.ListIconHQ,
            Requirements = spell.Requirements,
            Range = spell.Range,
            AreaRange = spell.AreaRange,
            AreaShapeType = spell.AreaShapeType,
            CursorTargetType = spell.CursorTargetType,
            Unknown0000 = spell.Unknown0000,
            AreaFlags = spell.AreaFlags,
            Unknown0001 = spell.Unknown0001,
            Unknown0002 = spell.Unknown0002,
            Unknown0003 = spell.Unknown0003,
            Unknown0004 = spell.Unknown0004,
            JobPointMask = spell.JobPointMask,
            Unknown0005 = spell.Unknown0005,

            Name = spell.Name,
            Description = spell.Description
        };

        return newSpell;
    end

    return spell;
end

local resourceManager = {
    GetAbilityById = function(_, ...) return rm:GetAbilityById(...) end,
    GetAbilityByName = function(_, ...) return rm:GetAbilityByName(...) end,
    GetAbilityByTimerId = function(_, ...) return rm:GetAbilityByTimerId(...) end,

    GetSpellById = function(_, ...)
        return mergeSpell(rm:GetSpellById(...));
    end,
    GetSpellByName = function(_, ...)
        return mergeSpell(rm:GetSpellByName(...));
    end,

    GetItemById = function(_, ...) return rm:GetItemById(...) end,
    GetItemByName = function(_, ...) return rm:GetItemByName(...) end,

    GetSTatusIconByIndex = function(_, ...) return rm:GetSTatusIconByIndex(...) end,
    GetStatusIconById = function(_, ...) return rm:GetStatusIconById(...) end,

    GetString = function(_, ...) return rm:GetString(...) end,
    GetStringLength = function(_, ...) return rm:GetStringLength(...) end,

    GetTexture = function(_, ...) return rm:GetTexture(...) end,
    GetTextureInfo = function(_, ...) return rm:GetTextureInfo(...) end,

    GetFilePath = function(_, ...) return rm:GetFilePath(...) end,
    GetAbilityRange = function(_, ...) return rm:GetAbilityRange(...) end,
    GetAbilityType = function(_, ...) return rm:GetAbilityType(...) end,
    GetSpellRange = function(_, ...) return rm:GetSpellRange(...) end,
};

AshitaCore = {
    GetHandle = function() return ac:GetHandle() end,
    GetInstallPath = function() return ac:GetInstallPath() end,
    GetDirect3DDevice = function() return ac:GetDirect3DDevice() end,
    GetProperties = function() return ac:GetProperties() end,
    GetChatManager = function() return ac:GetChatManager() end,
    GetGuiManager = function() return ac:GetGUIManager() end,
    GetInputManager = function() return ac:GetInputManager() end,
    GetMemoryManager = function() return ac:GetMemoryManager() end,
    GetOffsetManager = function() return ac:GetOffsetManager() end,
    GetPacketManager = function() return ac:GetPacketManager() end,
    GetPluginManager = function() return ac:GetPluginManager() end,
    GetPolPluginManager = function() return ac:GetPolPluginManager() end,
    GetPointerManager = function() return ac:GetPointerManager() end,
    GetPrimitiveManager = function() return ac:GetPrimitiveManager() end,
    GetResourceManager = function()
        return resourceManager
    end,
};

return overrides;
