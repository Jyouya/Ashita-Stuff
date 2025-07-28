-- ImGui interface module for J-Roller Enhanced
local imgui = require('imgui');

-- ImGui constants
local ImGuiCond_FirstUseEver = ImGuiCond_FirstUseEver or 2;
local ImGuiWindowFlags_AlwaysAutoResize = ImGuiWindowFlags_AlwaysAutoResize or 64;
local ImGuiTreeNodeFlags_DefaultOpen = ImGuiTreeNodeFlags_DefaultOpen or 32;

local ImGuiInterface = {};

-- Initialize the ImGui interface
function ImGuiInterface.new(dependencies)
    local self = {
        -- Dependencies from main module
        settings = dependencies.settings,
        libSettings = dependencies.libSettings,
        enabled = dependencies.enabled,
        rolls = dependencies.rolls,
        message = dependencies.message,
        updateJobInfo = dependencies.updateJobInfo,
        applyPreset = dependencies.applyPreset,
        once = dependencies.once,
        setOnce = dependencies.setOnce,
        
        -- State variables
        showImGuiMenu = { dependencies.settings.showImGuiMenu },
        imguiFirstRun = true,
        
        -- Job info (updated from main)
        mainjob = nil,
        subjob = nil,
        hasSnakeEye = false,
        hasFold = false,
        
        -- Status info (updated from main)
        asleep = true,
        rollQ = nil,
        rollWindow = nil,
        pending = false,
    };
    
    setmetatable(self, { __index = ImGuiInterface });
    return self;
end

-- Update job and status information from main module
function ImGuiInterface:updateState(state)
    self.mainjob = state.mainjob;
    self.subjob = state.subjob;
    self.hasSnakeEye = state.hasSnakeEye;
    self.hasFold = state.hasFold;
    self.asleep = state.asleep;
    self.rollQ = state.rollQ;
    self.rollWindow = state.rollWindow;
    self.pending = state.pending;
end

-- Toggle the ImGui menu visibility
function ImGuiInterface:toggleMenu()
    self.showImGuiMenu[1] = not self.showImGuiMenu[1];
    self.settings.showImGuiMenu = self.showImGuiMenu[1];
    self.libSettings.save();
    return self.showImGuiMenu[1];
end

-- Render basic controls section
function ImGuiInterface:renderBasicControls()
    if imgui.CollapsingHeader('Basic Controls', ImGuiTreeNodeFlags_DefaultOpen) then
        
        -- Enable/Disable
        local enabledValue = { self.enabled.value };
        if imgui.Checkbox('Auto-Rolling Enabled', enabledValue) then
            self.enabled:set(enabledValue[1]);
        end
        
        imgui.Separator();
        
        -- Current Mode Display
        self.updateJobInfo();
        local modeText = '';
        if self.mainjob == 17 then
            modeText = 'Mode: Main Job COR (Full Features)';
        elseif self.subjob == 17 then
            modeText = 'Mode: Sub Job COR (Single Roll Only)';
        else
            modeText = 'Mode: Not COR (No Rolling Available)';
        end
        imgui.TextColored({ 0.7, 0.9, 1.0, 1.0 }, modeText);
        
        imgui.Separator();
        
        -- Roll Selection
        imgui.Text('Roll 1:');
        imgui.SameLine();
        imgui.SetNextItemWidth(200);
        if imgui.BeginCombo('##roll1', self.rolls[1].value) then
            for _, rollName in ipairs(self.rolls[1]) do
                local isSelected = (self.rolls[1].value == rollName);
                if imgui.Selectable(rollName, isSelected) then
                    self.rolls[1]:set(rollName);
                end
                if isSelected then
                    imgui.SetItemDefaultFocus();
                end
            end
            imgui.EndCombo();
        end
        
        imgui.Text('Roll 2:');
        imgui.SameLine();
        imgui.SetNextItemWidth(200);
        
        if self.subjob == 17 then
            imgui.Text('N/A (Sub COR)');
        else
            if imgui.BeginCombo('##roll2', self.rolls[2].value) then
                for _, rollName in ipairs(self.rolls[2]) do
                    local isSelected = (self.rolls[2].value == rollName);
                    if imgui.Selectable(rollName, isSelected) then
                        self.rolls[2]:set(rollName);
                    end
                    if isSelected then
                        imgui.SetItemDefaultFocus();
                    end
                end
                imgui.EndCombo();
            end
        end
        
        imgui.Separator();
        
                 -- Once Mode
         if imgui.Button('Roll Once') then
             self.message('Will roll until both rolls are up, then stop.');
             self.setOnce(true);
             self.enabled:set(true);
         end
         imgui.SameLine();
         imgui.TextColored({ 0.7, 0.7, 0.7, 1.0 }, '(?)');
         if imgui.IsItemHovered() then
             imgui.SetTooltip('Roll both rolls once then automatically stop.\nUseful for quick buffs without continuous rolling.');
         end
    end
end

-- Render quick presets section
function ImGuiInterface:renderQuickPresets()
    if imgui.CollapsingHeader('Quick Presets', ImGuiTreeNodeFlags_DefaultOpen) then
        
        -- Combat Presets
        imgui.TextColored({ 1.0, 0.8, 0.6, 1.0 }, 'Combat:');
        if imgui.Button('TP (SAM+FTR)') then self.applyPreset('tp'); end
        imgui.SameLine();
        if imgui.Button('Accuracy (SAM+HUN)') then self.applyPreset('acc'); end
        imgui.SameLine();
        if imgui.Button('WS (CHA+FTR)') then self.applyPreset('ws'); end
        
        if imgui.Button('Melee (SAM+CHA)') then self.applyPreset('melee'); end
        
        imgui.Separator();
        
        -- Magic Presets
        imgui.TextColored({ 0.8, 0.6, 1.0, 1.0 }, 'Magic:');
        if imgui.Button('Nuke (WIZ+WAR)') then self.applyPreset('nuke'); end
        imgui.SameLine();
        if imgui.Button('Magic (WIZ+WAR)') then self.applyPreset('magic'); end
        imgui.SameLine();
        if imgui.Button('Burst (WIZ+WAR)') then self.applyPreset('burst'); end
        
        imgui.Separator();
        
        -- Pet Presets
        imgui.TextColored({ 0.6, 1.0, 0.8, 1.0 }, 'Pet:');
        if imgui.Button('Pet (COM+BEA)') then self.applyPreset('pet'); end
        imgui.SameLine();
        if imgui.Button('Pet Phy (COM+BEA)') then self.applyPreset('petphy'); end
        
        if imgui.Button('Pet Acc (COM+DRA)') then self.applyPreset('petacc'); end
        imgui.SameLine();
        if imgui.Button('Pet Nuke (PUP+COM)') then self.applyPreset('petnuke'); end
        
        imgui.Separator();
        
        -- Utility Presets
        imgui.TextColored({ 1.0, 1.0, 0.6, 1.0 }, 'Utility:');
        if imgui.Button('EXP (COR+DAN)') then self.applyPreset('exp'); end
        imgui.SameLine();
        if imgui.Button('Speed (BOL+BOL)') then self.applyPreset('speed'); end
    end
end

-- Render advanced settings section
function ImGuiInterface:renderAdvancedSettings()
    if imgui.CollapsingHeader('Advanced Settings') then
        
        -- Combat Settings
        imgui.TextColored({ 1.0, 0.8, 0.6, 1.0 }, 'Combat Options:');
        
                 local engagedValue = { self.settings.engaged };
         if imgui.Checkbox('Only Roll While Engaged', engagedValue) then
             self.settings.engaged = engagedValue[1];
             self.libSettings.save();
         end
         imgui.SameLine();
         imgui.TextColored({ 0.7, 0.7, 0.7, 1.0 }, '(?)');
         if imgui.IsItemHovered() then
             imgui.SetTooltip('Only roll when you are engaged in combat.\nUseful to avoid rolling during downtime.');
         end
         
         local partyalertValue = { self.settings.partyalert };
         if imgui.Checkbox('Alert Party Before Rolling', partyalertValue) then
             self.settings.partyalert = partyalertValue[1];
             self.libSettings.save();
         end
         imgui.SameLine();
         imgui.TextColored({ 0.7, 0.7, 0.7, 1.0 }, '(?)');
         if imgui.IsItemHovered() then
             imgui.SetTooltip('Sends a party message 8 seconds before rolling\nto give party members time to get in range.');
         end
         
         local townmodeValue = { self.settings.townmode };
         if imgui.Checkbox('Town Mode (No Rolling in Cities)', townmodeValue) then
             self.settings.townmode = townmodeValue[1];
             self.libSettings.save();
         end
         imgui.SameLine();
         imgui.TextColored({ 0.7, 0.7, 0.7, 1.0 }, '(?)');
         if imgui.IsItemHovered() then
             imgui.SetTooltip('Prevents rolling when in towns or safe zones.\nUseful to avoid rolling in populated areas.');
         end
        
        imgui.Separator();
        
        -- Ability Usage Settings
        imgui.TextColored({ 0.8, 0.6, 1.0, 1.0 }, 'Ability Usage:');
        
                 local crooked2Value = { self.settings.crooked2 };
                   if imgui.Checkbox('Save Crooked Cards for Roll 2 Only', crooked2Value) then
             self.settings.crooked2 = crooked2Value[1];
             self.libSettings.save();
         end
         imgui.SameLine();
         imgui.TextColored({ 0.7, 0.7, 0.7, 1.0 }, '(?)');
         if imgui.IsItemHovered() then
                           imgui.SetTooltip('ON: Save Crooked Cards for Roll 2 only\nOFF: Normal (use on Roll 1, Random Deal resets for Roll 2)');
         end
         
         local randomdealValue = { self.settings.randomdeal };
         if imgui.Checkbox('Use Random Deal', randomdealValue) then
             self.settings.randomdeal = randomdealValue[1];
             self.libSettings.save();
         end
         imgui.SameLine();
         imgui.TextColored({ 0.7, 0.7, 0.7, 1.0 }, '(?)');
         if imgui.IsItemHovered() then
             imgui.SetTooltip('Enable smart Random Deal usage.\nAutomatically uses Random Deal when beneficial:\n- After bust+fold (resets all abilities)\n- When multiple abilities on cooldown\n- When key abilities need resetting');
         end
         
         local oldrandomdealValue = { self.settings.oldrandomdeal };
         if imgui.Checkbox('Random Deal: Disable Crooked Cards Reset', oldrandomdealValue) then
             self.settings.oldrandomdeal = oldrandomdealValue[1];
             self.libSettings.save();
         end
         imgui.SameLine();
         imgui.TextColored({ 0.7, 0.7, 0.7, 1.0 }, '(?)');
         if imgui.IsItemHovered() then
             imgui.SetTooltip('ON: Never use Random Deal to reset Crooked Cards\nOFF: Normal (will reset Crooked Cards when beneficial)\n\nUse this to preserve Crooked Cards for specific strategies.');
         end
        
        imgui.Separator();
        
        -- Random Deal Priority Configuration
        imgui.TextColored({ 1.0, 0.8, 0.4, 1.0 }, 'Random Deal Priority:');
        imgui.SameLine();
        imgui.TextColored({ 0.7, 0.7, 0.7, 1.0 }, '(?)');
        if imgui.IsItemHovered() then
            imgui.SetTooltip('Random Deal Priority Order:\n\nWhen Random Deal triggers, it checks these abilities\nin order from top to bottom (1 to 2 to 3).\n\nThe FIRST ability found on cooldown will be targeted.\nHigher priority abilities are checked first.\n\nExample: If Crooked Cards is #1 and on cooldown,\nRandom Deal attempts to reset it immediately without\nchecking Snake Eye or Fold.');
        end
        
        -- Priority list with visual styling and arrow controls
        for i = 1, #self.settings.randomDealPriority do
            local item = self.settings.randomDealPriority[i];
            
            -- Create a visual frame around each item
            imgui.PushStyleColor(ImGuiCol_ChildBg, { 0.15, 0.15, 0.15, 1.0 });
            if item == 'Crooked Cards' then
                imgui.PushStyleColor(ImGuiCol_ChildBg, { 0.25, 0.15, 0.35, 1.0 }); -- Dark purple
            elseif item == 'Snake Eye' then
                imgui.PushStyleColor(ImGuiCol_ChildBg, { 0.35, 0.25, 0.15, 1.0 }); -- Dark gold
            elseif item == 'Fold' then
                imgui.PushStyleColor(ImGuiCol_ChildBg, { 0.15, 0.25, 0.35, 1.0 }); -- Dark blue
            end
            
            if imgui.BeginChild('priority_item_' .. i, { 250, 25 }, false, ImGuiWindowFlags_NoScrollbar) then
                -- Priority number
                imgui.Text(tostring(i) .. '.');
                imgui.SameLine();
                
                -- Up arrow button (disabled for first item)
                if i == 1 then
                    imgui.PushStyleColor(ImGuiCol_Button, { 0.2, 0.2, 0.2, 0.5 });
                    imgui.PushStyleColor(ImGuiCol_ButtonHovered, { 0.2, 0.2, 0.2, 0.5 });
                    imgui.PushStyleColor(ImGuiCol_ButtonActive, { 0.2, 0.2, 0.2, 0.5 });
                    imgui.Button('^##up' .. i);
                    imgui.PopStyleColor(3);
                else
                    if imgui.Button('^##up' .. i) then
                        -- Swap with item above
                        local temp = self.settings.randomDealPriority[i-1];
                        self.settings.randomDealPriority[i-1] = item;
                        self.settings.randomDealPriority[i] = temp;
                        self.libSettings.save();
                    end
                end
                imgui.SameLine();
                
                -- Down arrow button (disabled for last item)
                if i == #self.settings.randomDealPriority then
                    imgui.PushStyleColor(ImGuiCol_Button, { 0.2, 0.2, 0.2, 0.5 });
                    imgui.PushStyleColor(ImGuiCol_ButtonHovered, { 0.2, 0.2, 0.2, 0.5 });
                    imgui.PushStyleColor(ImGuiCol_ButtonActive, { 0.2, 0.2, 0.2, 0.5 });
                    imgui.Button('v##down' .. i);
                    imgui.PopStyleColor(3);
                else
                    if imgui.Button('v##down' .. i) then
                        -- Swap with item below
                        local temp = self.settings.randomDealPriority[i+1];
                        self.settings.randomDealPriority[i+1] = item;
                        self.settings.randomDealPriority[i] = temp;
                        self.libSettings.save();
                    end
                end
                imgui.SameLine();
                
                -- Item name with appropriate text color
                local textColor = { 1.0, 1.0, 1.0, 1.0 }; -- Bright white
                if item == 'Crooked Cards' then
                    textColor = { 1.0, 0.8, 1.0, 1.0 }; -- Light purple
                elseif item == 'Snake Eye' then
                    textColor = { 1.0, 0.9, 0.5, 1.0 }; -- Light yellow
                elseif item == 'Fold' then
                    textColor = { 0.5, 0.8, 1.0, 1.0 }; -- Light blue
                end
                imgui.TextColored(textColor, item);
                
                imgui.EndChild();
            end
            imgui.PopStyleColor(1);
            
            -- Add some spacing between items
            if i < #self.settings.randomDealPriority then
                imgui.Spacing();
            end
        end
        
        imgui.Separator();
        
        -- Advanced Rolling Options
        imgui.TextColored({ 1.0, 0.6, 0.6, 1.0 }, 'Advanced Rolling:');
        
        local gambleValue = { self.settings.gamble };
        if imgui.Checkbox('Gamble Mode (Aggressive Double 11s)', gambleValue) then
            self.settings.gamble = gambleValue[1];
            self.libSettings.save();
        end
        imgui.SameLine();
        imgui.TextColored({ 0.7, 0.7, 0.7, 1.0 }, '(?)');
        if imgui.IsItemHovered() then
            imgui.SetTooltip('Aggressively targets 11 on Roll 1, then exploits bust immunity\nto guarantee 11 on Roll 2. Will fold/reset non-11 rolls.');
        end
        
                 local bustimmunityValue = { self.settings.bustimmunity };
         if imgui.Checkbox('Exploit Bust Immunity', bustimmunityValue) then
             self.settings.bustimmunity = bustimmunityValue[1];
             self.libSettings.save();
         end
         imgui.SameLine();
         imgui.TextColored({ 0.7, 0.7, 0.7, 1.0 }, '(?)');
         if imgui.IsItemHovered() then
             imgui.SetTooltip('When Roll 1 is 11, be more aggressive on Roll 2\nsince you cannot bust. Disable for scenarios where\nyou need Roll 2 immediately regardless of quality.');
         end
         
         local safemodeValue = { self.settings.safemode };
         if imgui.Checkbox('Safe Mode (Ultra-Conservative)', safemodeValue) then
             self.settings.safemode = safemodeValue[1];
             self.libSettings.save();
         end
         imgui.SameLine();
         imgui.TextColored({ 0.7, 0.7, 0.7, 1.0 }, '(?)');
         if imgui.IsItemHovered() then
             imgui.SetTooltip('Ultra-conservative mode: only double up on rolls 1-5.\nSimilar to subjob COR behavior. Overrides other settings.');
         end
        

    end
end

-- Render merit abilities section
function ImGuiInterface:renderMeritAbilities()
    if imgui.CollapsingHeader('Merit Abilities') then
        
        imgui.TextColored({ 0.6, 1.0, 1.0, 1.0 }, 'Manual Merit Ability Control:');
        
                 local hasSnakeEyeValue = { self.settings.hasSnakeEye };
         if imgui.Checkbox('Snake Eye Enabled', hasSnakeEyeValue) then
             self.settings.hasSnakeEye = hasSnakeEyeValue[1];
             self.libSettings.save();
         end
         imgui.SameLine();
         imgui.TextColored({ 0.7, 0.7, 0.7, 1.0 }, '(?)');
         if imgui.IsItemHovered() then
             imgui.SetTooltip('Snake Eye: Sets next roll to 11.\nUsed for getting lucky numbers or avoiding unlucky.');
         end
         
         local hasFoldValue = { self.settings.hasFold };
         if imgui.Checkbox('Fold Enabled', hasFoldValue) then
             self.settings.hasFold = hasFoldValue[1];
             self.libSettings.save();
         end
         imgui.SameLine();
         imgui.TextColored({ 0.7, 0.7, 0.7, 1.0 }, '(?)');
         if imgui.IsItemHovered() then
             imgui.SetTooltip('Fold: Removes current roll without affecting others.\nUsed for bust recovery or removing bad rolls.');
         end
        
        imgui.Separator();
        imgui.TextColored({ 0.8, 0.8, 0.8, 1.0 }, 'Note: These override auto-detection.');
    end
end

-- Render status and debug section
function ImGuiInterface:renderStatusDebug()
    if imgui.CollapsingHeader('Status & Debug') then
        
        -- Current Status
        imgui.TextColored({ 0.6, 1.0, 0.6, 1.0 }, 'Current Status:');
        local status = self.asleep and 'Sleeping' or self.rollQ:peek() and self.rollQ:peek().en or 'Idle';
        if self.enabled.value and status == 'Idle' then
            status = 'Enabled';
        end
        imgui.Text('Status: ' .. status);
        
        imgui.Text('Roll 1: ' .. self.rolls[1].value);
        if self.subjob == 17 then
            imgui.Text('Roll 2: DISABLED (Sub COR)');
        else
            imgui.Text('Roll 2: ' .. self.rolls[2].value);
        end
        
        imgui.Separator();
        
        -- Debug Info
        imgui.TextColored({ 1.0, 0.8, 0.6, 1.0 }, 'Debug Information:');
        imgui.Text('Main Job: ' .. tostring(self.mainjob));
        imgui.Text('Sub Job: ' .. tostring(self.subjob));
        imgui.Text('Snake Eye Available: ' .. tostring(self.hasSnakeEye));
        imgui.Text('Fold Available: ' .. tostring(self.hasFold));
        imgui.Text('Roll Window: ' .. tostring(self.rollWindow or 'None'));
        imgui.Text('Pending Action: ' .. tostring(self.pending));
        
        if imgui.Button('Show Debug in Chat') then
            self.updateJobInfo();
            self.message('=== Debug Info ===');
            self.message('Main Job: ' .. tostring(self.mainjob));
            self.message('Sub Job: ' .. tostring(self.subjob));
            self.message('Snake Eye Enabled: ' .. tostring(self.hasSnakeEye));
            self.message('Fold Enabled: ' .. tostring(self.hasFold));
            self.message('Settings Snake Eye: ' .. tostring(self.settings.hasSnakeEye));
            self.message('Settings Fold: ' .. tostring(self.settings.hasFold));
        end
    end
end

-- Render help section
function ImGuiInterface:renderHelp()
    if imgui.CollapsingHeader('Help & Commands') then
        imgui.TextColored({ 1.0, 1.0, 0.6, 1.0 }, 'Chat Commands:');
        imgui.Text('/roller - Show status');
        imgui.Text('/roller start/stop - Enable/disable');
        imgui.Text('/roller roll1/roll2 <n> - Set roll');
        imgui.Text('/roller <preset> - Apply preset');
        imgui.Text('/roller menu - Toggle this menu');
        imgui.Text('/roller help - Show all commands');
        
        if imgui.Button('Show Help in Chat') then
            self.message('=== J-Roller Enhanced Commands ===');
            self.message('/roller - Show status');
            self.message('/roller start/stop - Enable/disable rolling');
            self.message('/roller roll1/roll2 <n> - Set roll');
            self.message('/roller <preset> - Apply preset (tp, acc, ws, nuke, pet, etc.)');
            self.message('/roller engaged on/off - Only roll while engaged');
                         self.message('/roller crooked2 on/off - Save Crooked Cards for roll 2 only');
            self.message('/roller randomdeal on/off - Use Random Deal');
            self.message('/roller partyalert on/off - Alert party before rolling');
                         self.message('/roller gamble on/off - Aggressive mode for double 11s');
             self.message('/roller bustimmunity on/off - Exploit bust immunity');
             self.message('/roller safemode on/off - Ultra-conservative mode');
             self.message('/roller townmode on/off - Prevent rolling in towns');
            self.message('/roller resetpriority - Reset Random Deal priority to default');
    
            self.message('/roller once - Roll both rolls once then stop');
            self.message('/roller snakeeye/fold on/off - Merit ability settings');
            self.message('/roller menu - Toggle ImGui settings menu');
            self.message('/roller debug - Show debug information');
        end
    end
end

-- Main render function
function ImGuiInterface:render()
    if not self.showImGuiMenu[1] then
        return;
    end

    -- Set window position on first run
    if self.imguiFirstRun then
        imgui.SetNextWindowPos({ self.settings.imguiMenuX, self.settings.imguiMenuY }, ImGuiCond_FirstUseEver);
        imgui.SetNextWindowSize({ 420, 600 }, ImGuiCond_FirstUseEver);
        self.imguiFirstRun = false;
    end

    if imgui.Begin('J-Roller Enhanced Settings', self.showImGuiMenu, ImGuiWindowFlags_AlwaysAutoResize) then
        
        self:renderBasicControls();
        self:renderQuickPresets();
        self:renderAdvancedSettings();
        self:renderMeritAbilities();
        self:renderStatusDebug();
        self:renderHelp();
        
        -- Save window position
        local windowPosX, windowPosY = imgui.GetWindowPos();
        if windowPosX ~= self.settings.imguiMenuX or windowPosY ~= self.settings.imguiMenuY then
            self.settings.imguiMenuX = windowPosX;
            self.settings.imguiMenuY = windowPosY;
            self.libSettings.save();
        end
    end
    imgui.End();
end

return ImGuiInterface; 