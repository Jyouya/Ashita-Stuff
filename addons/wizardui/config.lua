require('common');
local imgui = require('imgui');
local GUI = require('J-GUI');

local jobSettings;
local updateSettings;

local showConfig = { false };
local config = {};

local debuffStrings = T {


    ["str down"] = "STR Down",
    ["threnody"] = "Threnody",
    ["bio"] = "Bio",
    ["max mp down"] = "Max MP Down",
    ["mnd down"] = "MND Down",
    ["agi down"] = "AGI Down",
    ["frost"] = "Frost",
    ["helix"] = "Helix",
    ["lullaby"] = "Lullaby",
    ["magic atk down"] = "Magic Atk Down",
    ["evasion down"] = "Evasion Down",
    ["disease"] = "Disease",
    ["bind"] = "Bind",
    ["plague"] = "Plague",
    ["shock"] = "Shock",
    ["magic acc down"] = "Magic Acc Down",
    ["curse"] = "Curse",
    ["max hp down"] = "Max HP Down",
    ["vit down"] = "VIT Down",
    ["burn"] = "Burn",
    ["int down"] = "INT Down",
    ["weight"] = "Weight",
    ["elegy"] = "Elegy",
    ["requiem"] = "Requiem",
    ["accuracy down"] = "Accuracy Down",
    ["silence"] = "Silence",
    ["addle"] = "Addle",
    ["sleep"] = "Sleep",
    ["dia"] = "Dia",
    ["slow"] = "Slow",
    ["flash"] = "Flash",
    ["paralysis"] = "Paralysis",
    ["petrification"] = "Petrification",
    ["poison"] = "Poison",
    ["max tp down"] = "Max TP Down",
    ["doom"] = "Doom",
    ["rasp"] = "Rasp",
    ["drown"] = "Drown",
    ["choke"] = "Choke",
    ["chr down"] = "CHR Down",
    ["attack down"] = "Attack Down",
    ["blindness"] = "Blindness",
    ["dex down"] = "DEX Down",
};

local newEnhancingEntry = T { "" };

config.DrawWindow = function()
    if (showConfig[1]) then
        imgui.PushStyleColor(ImGuiCol_WindowBg, { 0, 0.06, .16, .9 });
        imgui.PushStyleColor(ImGuiCol_TitleBg, { 0, 0.06, .16, .7 });
        imgui.PushStyleColor(ImGuiCol_TitleBgActive, { 0, 0.06, .16, .9 });
        imgui.PushStyleColor(ImGuiCol_TitleBgCollapsed, { 0, 0.06, .16, .5 });
        imgui.PushStyleColor(ImGuiCol_Header, { 0, 0.06, .16, .7 });
        imgui.PushStyleColor(ImGuiCol_HeaderHovered, { 0, 0.06, .16, .9 });
        imgui.PushStyleColor(ImGuiCol_HeaderActive, { 0, 0.06, .16, 1 });
        imgui.PushStyleColor(ImGuiCol_FrameBg, { 0, 0.06, .16, 1 });
        imgui.SetNextWindowSize({ 550, 600 }, ImGuiCond_FirstUseEver);
        if (imgui.Begin(("Wizard Config"):fmt(addon.version), showConfig, bit.bor(ImGuiWindowFlags_NoSavedSettings))) then
            imgui.BeginChild("Config Options", { 0, 0 }, true);
            if (imgui.CollapsingHeader("Elemental Magic")) then
                imgui.BeginChild("ElementalSettings", { 0, 40 }, true);
                if (imgui.Checkbox('Enabled', { jobSettings.elemental.visible })) then
                    jobSettings.elemental.visible = not jobSettings.elemental.visible;
                    updateSettings();
                end
                imgui.EndChild();
            end
            if (imgui.CollapsingHeader("Enfeebling Magic")) then
                imgui.BeginChild("EnfeeblingSettings", { 0, 40 }, true);
                if (imgui.Checkbox('Enabled', { jobSettings.enfeebling.visible })) then
                    jobSettings.enfeebling.visible = not jobSettings.enfeebling.visible;
                    updateSettings();
                end
                imgui.EndChild();
            end
            if (imgui.CollapsingHeader("Enhancing Magic Trackers")) then
                imgui.BeginChild("EnhancingTrackerSettings", { 0, 520 }, true);
                for k, v in pairs(jobSettings.enhancing) do
                    if (imgui.Checkbox(k, { v.visible })) then
                        v.visible = not v.visible;
                        updateSettings();
                    end
                end
                imgui.EndChild();
            end

            if (imgui.CollapsingHeader("Self Enhancing Magic")) then
                imgui.BeginChild("SelfEnhancingSettings", { 0, 230 }, true);
                if (imgui.Checkbox('Enabled', { jobSettings.selfEnhancing.visible })) then
                    jobSettings.selfEnhancing.visible = not jobSettings.selfEnhancing.visible;
                    updateSettings();
                end

                for k, v in pairs(jobSettings.selfEnhancing) do
                    if (not (k == 'x' or k == 'y' or k == 'visible')) then
                        if (imgui.Checkbox(k, { v })) then
                            jobSettings.selfEnhancing[k] = not v;
                            updateSettings();
                        end
                    end
                end
                imgui.EndChild();
            end

            if (imgui.CollapsingHeader("Self Enhancing Tracker")) then
                imgui.BeginChild("SelfEnhancingTrackerSettings", { 0, 230 }, true);
                if (imgui.Checkbox('Enabled', { jobSettings.selfEnhancing2.visible })) then
                    jobSettings.selfEnhancing2.visible = not jobSettings.selfEnhancing2.visible;
                    updateSettings();
                end

                local toDelete = nil;

                for k, v in pairs(jobSettings.selfEnhancing2.trackedBuffs) do
                    imgui.PushID(k);
                    if (imgui.Checkbox(k, { v })) then
                        jobSettings.selfEnhancing2.trackedBuffs[k] = not v;
                        updateSettings();
                    end

                    imgui.SameLine();
                    if (imgui.Button('-')) then
                        toDelete = k;
                    end
                    imgui.PopID();
                end

                if (toDelete) then
                    jobSettings.selfEnhancing2.trackedBuffs[toDelete] = nil;
                    updateSettings();
                end

                imgui.Separator(); -- Separate the list from the add entry UI
                imgui.InputText('##NewEntry', newEnhancingEntry, 256);
                imgui.SameLine();
                if (imgui.Button('+')) then
                    local newEntry = newEnhancingEntry[1];
                    if newEntry ~= '' and not jobSettings.selfEnhancing2.trackedBuffs[newEntry] then
                        jobSettings.selfEnhancing2.trackedBuffs[newEntry] = true; -- Add new entry with default state
                        newEnhancingEntry[1] = '';                                            -- Clear the text field
                        updateSettings();
                    end
                end

                imgui.EndChild();
            end

            if (imgui.CollapsingHeader("Curing Magic")) then
                imgui.BeginChild("CuringSettings", { 0, 330 }, true);

                if (imgui.Checkbox('Show Party Frame', { jobSettings.healing.partyFrame.visible })) then
                    jobSettings.healing.partyFrame.visible = not jobSettings.healing.partyFrame.visible;
                    updateSettings();
                end

                if (imgui.Checkbox('Show Cure Buttons', { jobSettings.healing.cure.visible })) then
                    jobSettings.healing.cure.visible = not jobSettings.healing.cure.visible;
                    updateSettings();
                end

                local curePotency = T {
                    { jobSettings.healing.cure.potency[1] },
                    { jobSettings.healing.cure.potency[2] },
                    { jobSettings.healing.cure.potency[3] },
                    { jobSettings.healing.cure.potency[4] },
                    { jobSettings.healing.cure.potency[5] },
                    { jobSettings.healing.cure.potency[6] }
                };

                if (imgui.InputInt('Cure', curePotency[1])) then
                    jobSettings.healing.cure.potency[1] = curePotency[1][1];
                    updateSettings();
                end

                if (imgui.InputInt('Cure II', curePotency[2])) then
                    jobSettings.healing.cure.potency[2] = curePotency[2][1];
                    updateSettings();
                end

                if (imgui.InputInt('Cure III', curePotency[3])) then
                    jobSettings.healing.cure.potency[3] = curePotency[3][1];
                    updateSettings();
                end

                if (imgui.InputInt('Cure IV', curePotency[4])) then
                    jobSettings.healing.cure.potency[4] = curePotency[4][1];
                    updateSettings();
                end

                if (imgui.InputInt('Cure V', curePotency[5])) then
                    jobSettings.healing.cure.potency[5] = curePotency[5][1];
                    updateSettings();
                end

                if (imgui.InputInt('Cure VI', curePotency[6])) then
                    jobSettings.healing.cure.potency[6] = curePotency[6][1];
                    updateSettings();
                end

                local curagaPotency = T {
                    { jobSettings.healing.cure.curagaPotency[1] },
                    { jobSettings.healing.cure.curagaPotency[2] },
                    { jobSettings.healing.cure.curagaPotency[3] },
                    { jobSettings.healing.cure.curagaPotency[4] },
                    { jobSettings.healing.cure.curagaPotency[5] },
                };

                if (imgui.InputInt('Curaga', curagaPotency[1])) then
                    jobSettings.healing.cure.curagaPotency[1] = curagaPotency[1][1];
                    updateSettings();
                end

                if (imgui.InputInt('Curaga II', curagaPotency[2])) then
                    jobSettings.healing.cure.curagaPotency[2] = curagaPotency[2][1];
                    updateSettings();
                end

                if (imgui.InputInt('Curaga III', curagaPotency[3])) then
                    jobSettings.healing.cure.curagaPotency[3] = curagaPotency[3][1];
                    updateSettings();
                end

                if (imgui.InputInt('Curaga IV', curagaPotency[4])) then
                    jobSettings.healing.cure.curagaPotency[4] = curagaPotency[4][1];
                    updateSettings();
                end

                if (imgui.InputInt('Curaga V', curagaPotency[5])) then
                    jobSettings.healing.cure.curagaPotency[5] = curagaPotency[5][1];
                    updateSettings();
                end

                imgui.EndChild();
            end

            if (imgui.CollapsingHeader("Status Removal Magic")) then
                imgui.BeginChild("StatusRemovalSettings", { 0, 1200 }, true);
                if (imgui.Checkbox('Enabled', { jobSettings.healing.status.visible })) then
                    jobSettings.healing.status.visible = not jobSettings.healing.status.visible;
                    updateSettings();
                end

                for k, v in pairs(jobSettings.healing.status.trackedStatus) do
                    if (imgui.Checkbox(debuffStrings[k], { v })) then
                        jobSettings.healing.status.trackedStatus[k] = not v;
                        updateSettings();
                    end
                end
                imgui.EndChild();
            end

            if (imgui.CollapsingHeader("Ninjutsu")) then
                imgui.BeginChild("ElementalNinjutsuSettings", { 0, 100 }, true);
                if (imgui.Checkbox('Elemental Ninjutsu', { jobSettings.ninjutsu.elemental.visible })) then
                    jobSettings.ninjutsu.elemental.visible = not jobSettings.ninjutsu.elemental.visible;
                    updateSettings();
                end
                imgui.EndChild();
            end
        end
        imgui.PopStyleColor(8);
        imgui.End();
    end
end

ashita.events.register('command', 'command_cb', function(e)
    -- Parse the command arguments
    local command_args = e.command:lower():args()
    if table.contains({ '/wizard' }, command_args[1]) then
        -- Toggle the config menu
        showConfig[1] = not showConfig[1];
        e.blocked = true;
    end
end);



local function setup(s, update)
    jobSettings = s;
    updateSettings = update;

    local menu = GUI.View:new({
        _z = 10000,
        draw = function()
            config.DrawWindow();
        end,
        onMouse = function(e)
            e.blocked = true;
        end,
        getBounds = function()
            if (showConfig[1]) then
                return { 0, 0, 10000, 10000 }; -- Disable all other ui while menu is open
            else
                return { 0, 0, 0, 0 }
            end
        end
    });

    GUI.ctx.addView(menu);
end


return { setup = setup };
