-- Command handler module for J-Roller Enhanced
local fuzzyNames = require('FuzzyNames');
local presets = require('presets');

local CommandHandler = {};

-- Initialize the command handler
function CommandHandler.new(dependencies)
    local self = {
        -- Dependencies from main module
        settings = dependencies.settings,
        libSettings = dependencies.libSettings,
        enabled = dependencies.enabled,
        rolls = dependencies.rolls,
        message = dependencies.message,
        updateJobInfo = dependencies.updateJobInfo,
        applyPreset = dependencies.applyPreset,
        setOnce = dependencies.setOnce,
        imguiInterface = dependencies.imguiInterface,

        -- Command lists
        startCommands = {'start', 'go', 'on', 'enable'},
        stopCommands = {'stop', 'quit', 'off', 'disable'},

        -- State variables (updated from main)
        mainjob = nil,
        subjob = nil,
        hasSnakeEye = false,
        hasFold = false,
        once = false
    };

    setmetatable(self, {__index = CommandHandler});
    return self;
end

-- Update state information from main module
function CommandHandler:updateState(state)
    self.mainjob = state.mainjob;
    self.subjob = state.subjob;
    self.hasSnakeEye = state.hasSnakeEye;
    self.hasFold = state.hasFold;
    self.once = state.once;
end

-- Helper function to check if table contains value
local function tableContains(table, value)
    for _, v in ipairs(table) do if v == value then return true; end end
    return false;
end

-- Set a roll using fuzzy name matching
function CommandHandler:setRoll(slot, text)
    local name = (function(inputText)
        local bestMatch = nil;
        local bestMatchLength = 0;

        -- First pass: look for exact matches
        for k, v in pairs(fuzzyNames) do
            for _, j in ipairs(v) do
                if inputText == j then
                    return k; -- Exact match always wins
                end
            end
        end

        -- Second pass: look for longest startswith match
        for k, v in pairs(fuzzyNames) do
            for _, j in ipairs(v) do
                if inputText:startswith(j) and string.len(j) > bestMatchLength then
                    bestMatch = k;
                    bestMatchLength = string.len(j);
                end
            end
        end

        return bestMatch;
    end)(text:lower());

    if (name) then
        if (self.rolls[slot].value == name) then
            self.message(('Roll %i is currently: %s'):format(slot,
                                                             self.rolls[slot]
                                                                 .value));
            -- Nothing needs to be done
            return;
        end

        if (self.rolls[slot % 2 + 1].value == name) then
            self.rolls[slot % 2 + 1]:set(self.rolls[slot].value);
        end

        self.message(('Roll %i set to %s'):format(slot, name));
        self.rolls[slot]:set(name);
        -- wakeUp will be called by main module
    else
        self.message(('Roll %i is currently: %s'):format(slot,
                                                         self.rolls[slot].value));
    end
end

-- Handle status display command
function CommandHandler:handleStatus()
    self.updateJobInfo();
    if self.enabled.value then
        self.message('Automatic Rolling is ON.');
    else
        self.message('Automatic Rolling is OFF.');
    end

    if self.mainjob == 17 then
        self.message('Mode: Main Job COR (Full Features)');
    elseif self.subjob == 17 then
        self.message('Mode: Sub Job COR (Limited Features - Single Roll Only)');
    else
        self.message('Mode: Not COR (No Rolling Available)');
    end

    self.message('Roll 1: ' .. self.rolls[1].value);
    if self.subjob == 17 then
        self.message('Roll 2: DISABLED (Sub COR only allows one roll)');
    else
        self.message('Roll 2: ' .. self.rolls[2].value);
    end
end

-- Handle debug command
function CommandHandler:handleDebug()
    self.updateJobInfo();
    self.message('=== Debug Info ===');
    self.message('Main Job: ' .. tostring(self.mainjob));
    self.message('Sub Job: ' .. tostring(self.subjob));
    self.message('Snake Eye Enabled: ' .. tostring(self.hasSnakeEye));
    self.message('Fold Enabled: ' .. tostring(self.hasFold));
    self.message('Settings Snake Eye: ' .. tostring(self.settings.hasSnakeEye));
    self.message('Settings Fold: ' .. tostring(self.settings.hasFold));
end

-- Handle help command
function CommandHandler:handleHelp()
    self.message('=== J-Roller Enhanced Commands ===');
    self.message('/roller - Show status');
    self.message('/roller start/stop - Enable/disable rolling');
    self.message('/roller roll1/roll2 <name> - Set roll');
    self.message(
        '/roller <preset> - Apply preset (tp, acc, ws, nuke, pet, etc.)');
    self.message('/roller engaged on/off - Only roll while engaged');
    self.message('/roller crooked2 on/off - Save Crooked Cards for roll 2 only');
    self.message('/roller randomdeal on/off - Smart Random Deal usage');
    self.message('/roller oldrandomdeal on/off - Disable Crooked Cards reset');
    self.message('/roller partyalert on/off - Alert party before rolling');
    self.message('/roller gamble on/off - Aggressive mode for double 11s');
    self.message('/roller bustimmunity on/off - Exploit bust immunity');
    self.message('/roller safemode on/off - Ultra-conservative mode');
    self.message('/roller townmode on/off - Prevent rolling in towns');
    self.message('/roller rollwithbust on/off - Allow Roll 2 when busted');
    self.message(
        '/roller smartsnakeeye on/off - Smart end-rotation Snake Eye optimization');

    self.message('/roller once - Roll both rolls once then stop');
    self.message('/roller resetpriority - Reset Random Deal priority to default');
    self.message('/roller snakeeye/fold on/off - Merit ability settings');
    self.message('/roller menu - Toggle ImGui settings menu');
    self.message('/roller debug - Show debug information');
end

-- Handle setting toggle commands
function CommandHandler:handleSettingToggle(setting, arg, onMessage, offMessage)
    local value;
    if not arg then
        value = not self.settings[setting];
    elseif arg == 'on' or arg == 'true' then
        value = true;
    elseif arg == 'off' or arg == 'false' then
        value = false;
    else
        value = self.settings[setting]; -- No change
    end

    self.settings[setting] = value;
    self.message(value and onMessage or offMessage);
    self.libSettings.save();
    return value;
end

-- Handle merit ability commands (with query support)
function CommandHandler:handleMeritAbility(ability, arg)
    local settingKey = 'has' .. ability;
    local displayName = ability;

    if arg == 'on' then
        self.settings[settingKey] = true;
        self.message(displayName .. ': Enabled');
        self.libSettings.save();
    elseif arg == 'off' then
        self.settings[settingKey] = false;
        self.message(displayName .. ': Disabled');
        self.libSettings.save();
    else
        -- Query current status
        self.updateJobInfo();
        local currentValue = (ability == 'SnakeEye') and self.hasSnakeEye or
                                 self.hasFold;
        self.message(displayName .. ': ' ..
                         (currentValue and 'Enabled' or 'Disabled'));
    end
end

-- Main command processing function
function CommandHandler:processCommand(e)
    local args = e.command:args();
    if (#args == 0 or not args[1]:any('/roller')) then
        return false; -- Not our command
    end

    args:remove(1);

    local cmd = args[1] or '';
    if cmd then
        cmd = cmd:lower();
        args:remove(1);
    end

    -- Handle no command or status display
    if not cmd or cmd == '' or cmd == 'status' or cmd == 'rolls' then
        self:handleStatus();
        return true;
    end

    -- Start/Stop commands
    if tableContains(self.startCommands, cmd) then
        self.message('Rolling enabled.');
        self.enabled:set(true);
        return true;
    elseif tableContains(self.stopCommands, cmd) then
        self.message('Rolling disabled.');
        self.enabled:set(false);
        self.setOnce(false); -- Reset once mode
        return true;

        -- Preset commands
    elseif presets[cmd] then
        self.applyPreset(cmd);
        return true;

        -- Roll setting commands
    elseif cmd == 'roll1' then
        if (#args > 0) then
            self:setRoll(1, args:concat(' '));
        else
            self.message(('Roll 1 is currently: %s'):format(self.rolls[1].value));
        end
        return true;
    elseif cmd == 'roll2' then
        if (#args > 0) then
            self:setRoll(2, args:concat(' '));
        else
            self.message(('Roll 2 is currently: %s'):format(self.rolls[2].value));
        end
        return true;

        -- Settings commands
    elseif cmd == 'engaged' then
        local arg = args[1] and args[1]:lower();
        self:handleSettingToggle('engaged', arg, 'Engaged Only: On',
                                 'Engaged Only: Off');
        return true;

    elseif cmd == 'crooked2' then
        local arg = args[1] and args[1]:lower();
        if arg == 'on' then
            self.settings.crooked2 = true;
        elseif arg == 'off' then
            self.settings.crooked2 = false;
        end
        self.message('Save Crooked for Roll 2 Only: ' ..
                         (self.settings.crooked2 and 'On (Special)' or
                             'Off (Normal)'));
        self.libSettings.save();
        return true;

    elseif cmd == 'randomdeal' then
        local arg = args[1] and args[1]:lower();
        if arg == 'on' then
            self.settings.randomdeal = true;
        elseif arg == 'off' then
            self.settings.randomdeal = false;
        end
        self.message('Random Deal: ' ..
                         (self.settings.randomdeal and 'On' or 'Off'));
        self.libSettings.save();
        return true;

    elseif cmd == 'oldrandomdeal' then
        if args[2] == 'on' then
            self.settings.oldrandomdeal = true;
        elseif args[2] == 'off' then
            self.settings.oldrandomdeal = false;
        end
        local mode = self.settings.oldrandomdeal and
                         'Disabled for Crooked Cards' or 'Smart (All Abilities)';
        self.message('Random Deal Mode: ' .. mode);
        self.libSettings.save();
        return true;

    elseif cmd == 'partyalert' then
        local arg = args[1] and args[1]:lower();
        self:handleSettingToggle('partyalert', arg, 'Party Alert: On',
                                 'Party Alert: Off');
        return true;

    elseif cmd == 'gamble' then
        local arg = args[1] and args[1]:lower();
        self:handleSettingToggle('gamble', arg,
                                 'Gamble Mode: On (Targeting double 11s)',
                                 'Gamble Mode: Off');
        return true;

    elseif cmd == 'bustimmunity' then
        local arg = args[1] and args[1]:lower();
        self:handleSettingToggle('bustimmunity', arg,
                                 'Bust Immunity: On (Exploit when available)',
                                 'Bust Immunity: Off (Always conservative)');
        return true;

    elseif cmd == 'safemode' then
        local arg = args[1] and args[1]:lower();
        self:handleSettingToggle('safemode', arg,
                                 'Safe Mode: On (Ultra-conservative)',
                                 'Safe Mode: Off');
        return true;

    elseif cmd == 'townmode' then
        local arg = args[1] and args[1]:lower();
        self:handleSettingToggle('townmode', arg,
                                 'Town Mode: On (No rolling in cities)',
                                 'Town Mode: Off');
        return true;

    elseif cmd == 'rollwithbust' then
        local arg = args[1] and args[1]:lower();
        self:handleSettingToggle('rollwithbust', arg,
                                 'Roll with Bust: On (Allow Roll 2 when busted)',
                                 'Roll with Bust: Off');
        return true;

    elseif cmd == 'smartsnakeeye' then
        local arg = args[1] and args[1]:lower();
        self:handleSettingToggle('smartsnakeeye', arg,
                                 'Smart Snake Eye: On (Optimize end-rotation)',
                                 'Smart Snake Eye: Off');
        return true;

    elseif cmd == 'resetpriority' then
        self.settings.randomDealPriority = {
            'Crooked Cards', 'Snake Eye', 'Fold'
        };
        self.message(
            'Random Deal priority reset to default: Crooked Cards > Snake Eye > Fold');
        self.libSettings.save();
        return true;

    elseif cmd == 'once' then
        self.message('Will roll until both rolls are up, then stop.');
        self.setOnce(true);
        return true;

    elseif cmd == 'snakeeye' then
        local arg = args[1] and args[1]:lower();
        self:handleMeritAbility('SnakeEye', arg);
        return true;

    elseif cmd == 'fold' then
        local arg = args[1] and args[1]:lower();
        self:handleMeritAbility('Fold', arg);
        return true;

    elseif cmd == 'debug' then
        self:handleDebug();
        return true;

    elseif cmd == 'menu' then
        local shown = self.imguiInterface:toggleMenu();
        self.message('ImGui Menu: ' .. (shown and 'Shown' or 'Hidden'));
        return true;

    elseif cmd == 'help' then
        self:handleHelp();
        return true;

    else
        self.message('Unknown command: ' .. cmd ..
                         '. Use /roller help for commands.');
        return true;
    end
end

return CommandHandler;
