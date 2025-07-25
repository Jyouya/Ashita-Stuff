addon.name    = 'J-Roller Enhanced';
addon.author  = 'Jyouya - Additions by Palmer (Zodiarchy @ Asura)';
addon.version = '2.0';
addon.desc    = 'The ultimate Corsair auto-roller with advanced features';

require('table');
local Q = require('Queue');
local M = require('J-Mode');
local GUI = require('J-GUI');
local chat = require('chat');
local getAbilityRecasts = require('getAbilityRecasts')
local buffLoss = require('events.buffChange').buffLoss;

local functions = require('J-GUI/functions');
functions.addResourcePath(addon.path .. '\\assets\\');

local zoneChange = require('events.zoneChange');

local libSettings = require('settings');

local defaultSettings = T {
    x = 200,
    y = 200,
    rolls = {
        'Wizard\'s Roll',
        'Warlock\'s Roll',
    },
    -- Enhanced AshitaRoller features
    engaged = false,        -- Only roll while engaged
    crooked2 = true,       -- Use Crooked Cards on roll 2
    randomdeal = true,     -- Use Random Deal
    oldrandomdeal = false, -- Use Random Deal for Snake/Fold vs Crooked
    partyalert = false,    -- Alert party before rolling
    gamble = false,        -- Gamble for double 11s when bust immune
    bustrecovery = true,   -- Prioritize Random Deal for bust recovery over Phantom Roll cooldown
    hasSnakeEye = true,    -- true = enabled, false = disabled
    hasFold = true,        -- true = enabled, false = disabled
};

local settings = libSettings.load(defaultSettings);

local fuzzyNames = require('FuzzyNames');
local rollsByName = require('actions').rollsByName;
local rollsByParam = require('actions').rollsByParam;
local cities = require('cities');
local presets = require('presets');

local rollQ = Q {};
local pending = false;
local timeout = nil;

local rollNum = 0;
local rollWindow = nil;
local activeRolls = T { 0, 0 };

local currentRoll;
local globalCooldown = 0;
local lastActive = 0;

local waiting = false;
local asleep = true;

local recasts = T {};

-- Job detection and merit abilities
local mainjob = nil;
local subjob = nil;
local hasSnakeEye = false;
local hasFold = false;
local once = false;  -- Roll once mode

-- Advanced rolling variables (from AshitaRoller)
local lastRoll = 0;
local rollCrooked = false;
local roll1RollTime = 0;
local roll2RollTime = 0;

local enabled = M(false, 'Enabled');
local randomDeal = M(true, 'Use Random Deal')

local rolls = require('rolls');

rolls[1]:set(settings.rolls[1]);
rolls[2]:set(settings.rolls[2]);

local function saveRolls(slot)
    return function(m)
        settings.rolls[slot] = m.value;
        libSettings.save();
    end
end
rolls[1].on_change:register(saveRolls(1));
rolls[2].on_change:register(saveRolls(2));

ashita.events.register('load', 'jroller_gui_load', function()
    local UI = GUI.Container:new({
        layout = GUI.Container.LAYOUT.GRID,
        girdRows = 3,
        gridCols = 2,
        fillDirection = GUI.Container.LAYOUT.HORIZONTAL,
        gridGap = 10,
        padding = { x = 10, y = 10 },
        draggable = true,
        _x = settings.x,
        _y = settings.y,
        _width = 320,
        _height = 120,
        onDragFinish = function(view)
            local pos = view:getPos();
            settings.x = pos.x;
            settings.y = pos.y;
            libSettings.save();
        end
    });

    GUI.ctx.addView(UI);

        UI:addView(
        GUI.ToggleButton:new({
            variable = enabled,
            activeColor = T { 0, 55, 255 },
            inactiveColor = T { 255, 0, 0 },
            activeTextureFile = 'On.png',
            inactiveTextureFile = 'Off.png'
        }),
        GUI.Label:new({
            getValue = function()
                local status = asleep and 'Sleeping' or rollQ:peek() and rollQ:peek().en or 'Idle';
                if enabled.value and status == 'Idle' then
                    status = 'Enabled';
                end
                return 'Status: ' .. status;
            end
        }),

        GUI.Label:new({ value = 'Roll 1' }),
        GUI.Dropdown:new({
            color = T { 0, 55, 255 },
            animated = true,
            expandDirection = GUI.ENUM.DIRECTION.DOWN,
            _width = 140,
            isFixedWidth = true,
            variable = rolls[1]
        }),
        GUI.Label:new({ value = 'Roll 2' }),
        GUI.Dropdown:new({
            color = T { 0, 55, 255 },
            animated = true,
            expandDirection = GUI.ENUM.DIRECTION.DOWN,
            _width = 140,
            isFixedWidth = true,
            variable = rolls[2],
            disabled = function()
                return subjob == 17;
            end,
            getValue = function()
                if subjob == 17 then
                    return 'N/A (Sub COR)';
                else
                    return rolls[2].value;
                end
            end
        })
    );
end)

local function actionComplete()
    local act = rollQ:pop();

    pending = false;
    timeout = nil;
    globalCooldown = os.time();

    -- If we just started a new roll, do some setup
    if (act.en:contains(' Roll')) then
        rollWindow = os.time() + 45;
        activeRolls[2] = activeRolls[1];
        activeRolls[1] = os.time();

        currentRoll = act.en;
    end
end

-- Update job information and merit abilities
local function updateJobInfo()
    local player = GetPlayerEntity();
    if not player then return; end
    
    local playerMgr = AshitaCore:GetMemoryManager():GetPlayer();
    if not playerMgr then return; end
    
    mainjob = playerMgr:GetMainJob();
    subjob = playerMgr:GetSubJob();
    
    -- Use manual merit ability settings
    hasSnakeEye = settings.hasSnakeEye;
    hasFold = settings.hasFold;
end

local function message(text)
    print(chat.header(addon.name):append(chat.message(text)));
end

-- ? Maybe strip this down, since it's only used to specifically check for
-- ? Buffs in english
local function hasBuff(matchBuff)
    local buffs = AshitaCore:GetMemoryManager():GetPlayer():GetBuffs();
    if (type(matchBuff) == 'string') then
        local matchText = string.lower(matchBuff);
        for _, buff in pairs(buffs) do
            local buffString = AshitaCore:GetResourceManager():GetString("buffs.names", buff)
            if (buffString) then
                
                buffString = string.lower(buffString);
                if (buffString == matchText) then
                    return true;
                end
            end
        end
    elseif (type(matchBuff) == 'number') then
        for _, buff in pairs(buffs) do
            if (buff == matchBuff) then
                return true;
            end
        end
    end
    return false;
end

-- Amnesia, Impairment, Petrification, Stun, dead, charm, terror, sleep
local function isIncapacitated()
    return hasBuff(16)
        or hasBuff(261)
        or hasBuff(7)
        or hasBuff(10)
        or hasBuff(0)
        or hasBuff(14)
        or hasBuff(28)
        or hasBuff(2);
end

local wakeUp;

local function sleep()
    asleep = true
    lastActive = os.time();
    ashita.tasks.once(10, function()
        if (os.time() >= lastActive + 10) then
            wakeUp();
        end
    end);
end

local function doNewRoll()
    updateJobInfo(); -- Make sure we have current job info
    

    
    -- Allow rolling in town (restriction removed)

    -- Do not roll if disabled, or incapacitated
    if (not enabled.value or isIncapacitated()) then
        return;
    end

    -- Do not roll while hidden
    if (hasBuff('sneak') or hasBuff('invisible')) then
        return;
    end
    
    -- Don't roll if not COR
    if not (mainjob == 17 or subjob == 17) then
        return;
    end
    
    -- Check engaged only setting
    if settings.engaged then
        local player = GetPlayerEntity();
        if not player or player.Status ~= 1 then -- 1 = engaged
            return;
        end
    end
    
    -- Handle 'once' mode - check if we have both rolls (or just one for sub-COR)
    if once then
        local haveRoll1 = hasBuff(rolls[1].value);
        local haveRoll2 = hasBuff(rolls[2].value);
        
        if subjob == 17 then
            -- Sub-COR only gets one roll
            if haveRoll1 then
                message('Once mode: Roll complete (Sub-COR)');
                once = false;
                return;
            end
        else
            -- Main COR gets both rolls
            if haveRoll1 and haveRoll2 then
                message('Once mode: Both rolls complete');
                once = false;
                return;
            end
        end
    end

    -- Enhanced bust handling with priority options
    if (hasBuff('Bust')) then
        if settings.bustrecovery and settings.randomdeal and recasts[196] == 0 then
            -- Prioritize Random Deal for instant recovery
            rollQ:push(rollsByName['Random Deal']);
            return;
        elseif (hasFold and recasts[198] == 0) then
            -- Use Fold if available
            rollQ:push(rollsByName['Fold']);
            return;
        elseif (settings.randomdeal and recasts[196] < 30) then
            -- Fallback to Random Deal if coming off cooldown soon
            rollQ:push(rollsByName['Random Deal']);
            return;
        end
        -- If no bust recovery options available, wait for Phantom Roll cooldown
        sleep();
        return;
    end



    -- Check phantom roll recast first
    if recasts[193] > 10 then
        sleep();
        return;
    end

    -- Enhanced Random Deal logic
    if settings.randomdeal and mainjob == 17 and recasts[196] == 0 then
        if settings.oldrandomdeal then
            -- Old mode: Reset Snake Eye/Fold
            if (hasSnakeEye and recasts[197] > 0) or (hasFold and recasts[198] > 0) then
                rollQ:push(rollsByName['Random Deal']);
                return;
            end
        else
            -- New mode: Reset Crooked Cards
            if recasts[96] > 0 and recasts[193] == 0 then
                rollQ:push(rollsByName['Random Deal']);
                return;
            end
        end
    end

    -- Party alert before rolling
    if settings.partyalert and not hasBuff(rolls[1].value) and not hasBuff(rolls[2].value) then
        AshitaCore:GetChatManager():QueueCommand(-1, '/p Rolling in 8 seconds, stay close <call12>');
    end

    -- Roll priority: Roll 1 first, then Roll 2 (unless sub-COR)
    
    if (not hasBuff(rolls[1].value)) then
        -- Track roll time and crooked status for advanced logic
        roll1RollTime = os.time();
        rollCrooked = false;
        
        -- Use Crooked Cards if available and level 95+
        if mainjob == 17 and AshitaCore:GetMemoryManager():GetPlayer():GetMainJobLevel() >= 95 and recasts[96] == 0 then
            rollCrooked = true;
            rollQ:push(rollsByName['Crooked Cards']);
        end
        rollQ:push(rollsByName[rolls[1].value]);
    elseif (subjob ~= 17 and not (hasBuff(rolls[2].value) or hasBuff('Bust'))) then
        -- Track roll time and crooked status for advanced logic
        roll2RollTime = os.time();
        rollCrooked = false;
        
        -- Roll 2 only if main COR (sub-COR gets only one roll)
        if settings.crooked2 and mainjob == 17 and AshitaCore:GetMemoryManager():GetPlayer():GetMainJobLevel() >= 95 and recasts[96] == 0 then
            rollCrooked = true;
            rollQ:push(rollsByName['Crooked Cards']);
        end
        rollQ:push(rollsByName[rolls[2].value]);
    else
        sleep();
    end
end


local function doubleUpFactory(rollData)
    local action = rollsByName['Double-Up']:copy();
    action.param = rollData.param;
    return action;
end

local function snakeEye()
    -- Skip Snake Eye logic for sub-COR
    if subjob == 17 or not hasSnakeEye then
        return false;
    end
    
    local current = rollsByName[currentRoll];
    local snakeEyesActive = hasBuff('Snake Eye');
    local luckyNum = current.lucky;
    local unluckyNum = current.unlucky;

    if (snakeEyesActive) then
        if (not waiting) then
            globalCooldown = os.time() + 1;
            return 'wait'
        end
        waiting = false;
        rollQ:push(doubleUpFactory(current));
        return true;
    end

    -- Advanced Snake Eye logic from AshitaRoller
    if recasts[197] == 0 then
        -- Gamble mode with bust immunity
        if settings.gamble and lastRoll == 11 then
            if rollNum == 10 or (rollNum == (luckyNum - 1) and rollCrooked) then
                rollQ:push(rollsByName['Snake Eye']);
                rollQ:push(doubleUpFactory(current));
                return true;
            end
        else
            -- Normal Snake Eye usage
            if rollNum == 10 or (rollNum == (luckyNum - 1) and (not settings.gamble or rollCrooked)) then
                rollQ:push(rollsByName['Snake Eye']);
                rollQ:push(doubleUpFactory(current));
                return true;
            elseif (not hasFold or recasts[198] > 0 or (rollCrooked and not settings.gamble)) and rollNum == unluckyNum then
                rollQ:push(rollsByName['Snake Eye']);
                rollQ:push(doubleUpFactory(current));
                return true;
            elseif rollNum + 1 ~= unluckyNum and os.time() - roll1RollTime < 240 and os.time() - roll2RollTime < 240 then
                -- End-game optimization: use Snake Eye if next roll won't be unlucky
                rollQ:push(rollsByName['Snake Eye']);
                rollQ:push(doubleUpFactory(current));
                return true;
            end
        end
        
        -- Fallback to Random Deal if Snake Eye conditions not met
        if settings.randomdeal and recasts[196] == 0 and randomDeal.value then
            rollQ:push(rollsByName['Random Deal']);
            return true;
        end
    end
    
    return false;
end

local function finishRoll()
    message('Finished rolling: ' .. currentRoll .. ' final roll: ' .. rollNum);
    lastRoll = rollNum;
    rollWindow = nil;
end;

-- Advanced double-up logic from AshitaRoller
local function shouldDoubleUp()
    local current = rollsByName[currentRoll];
    local rollID = current.param;
    local luckyNum = current.lucky;
    local unluckyNum = current.unlucky;
    
    -- Sub-COR simplified strategy: double up if roll < 5
    if subjob == 17 then
        if rollNum < 5 then
            return true, "Sub-COR: Roll < 5";
        end
        return false, "Sub-COR: Roll >= 5, stopping";
    end
    
    -- Main COR advanced strategy (from AshitaRoller)
    if mainjob == 17 then
        -- Gamble mode: if last roll was 11 (bust immune), be aggressive
        if settings.gamble and lastRoll == 11 then
            if hasSnakeEye and recasts[197] == 0 and (rollNum == 10 or (rollNum == (luckyNum - 1) and rollCrooked)) then
                return false, "Gamble: Using Snake Eye for 11 or crooked lucky";
            else
                return true, "Gamble: Immune to bust, rolling for double 11";
            end
        else
            -- Normal strategy
            if hasSnakeEye and recasts[197] == 0 and (rollNum == 10 or (rollNum == (luckyNum - 1) and (not settings.gamble or rollCrooked))) then
                return false, "Using Snake Eye for lucky or 11";
            elseif hasSnakeEye and recasts[197] == 0 and (not hasFold or recasts[198] > 0 or (rollCrooked and not settings.gamble)) and rollNum == unluckyNum then
                return false, "Using Snake Eye to remove unlucky";
            elseif hasFold and recasts[198] == 0 and (not rollCrooked or settings.gamble) then
                return true, "Safe to risk: have Fold and roll not crooked";
            elseif rollNum < 6 then
                return true, "Roll < 6, continuing";
            elseif hasSnakeEye and recasts[197] == 0 and rollNum + 1 ~= unluckyNum and 
                   os.time() - roll1RollTime < 240 and os.time() - roll2RollTime < 240 then
                return false, "End-game Snake Eye: rollNum+1 not unlucky, Snake Eye available";
            else
                return false, "Stopping: conditions not met";
            end
        end
    end
    
    return false, "Unknown job configuration";
end

local function doubleUp()
    local shouldDouble, reason = shouldDoubleUp();
    if shouldDouble then
        local current = rollsByName[currentRoll];
        rollQ:push(doubleUpFactory(current));
        return true;
    end
    return false;
end



local function rollStrategy()
    recasts = getAbilityRecasts();

    -- If we do not have an open window/are satisfied with the current number
    if (not rollWindow) then
        return doNewRoll();
    end

    if (rollNum == 11 or rollNum == rollsByName[currentRoll].lucky) then
        rollWindow = nil;

        -- TODO: can we start planning the next roll here?
        return;
    end

    local snakeEyeResult = snakeEye();

    if (snakeEyeResult == 'wait') then
        waiting = true;
        return;
    end

    if (not snakeEyeResult) then
        if (not doubleUp()) then
            -- If we decide not to double up, close the roll
            finishRoll()
        end
    end
end

local function doNext()
    recasts = getAbilityRecasts();

    local cd = recasts[rollQ:peek().id];

    local abilityName = rollQ:peek().en;

    if (abilityName == nil) then
        message('Ability Name nil');
        return;
    end

    if (cd == 0) then
        local command = ('/ja "%s" <me>'):format(abilityName);
        message('command: ' .. command);
        AshitaCore:GetChatManager():QueueCommand(-1, command);
        pending = true;
        timeout = os.time();
    elseif ((rollWindow and os.time() + cd > rollWindow)
            or (not rollWindow and cd > 10)) then
        rollQ = Q {};
        rollStrategy()
    end
end

local function actionTimeout()
    rollQ = Q {};
    rollStrategy();
    pending = false;
    timeout = nil;
end

local function mainLoop()
    updateJobInfo(); -- Update job info regularly
    
    if (not enabled.value) then
        return;
    end
    
    -- Wake up if we're enabled but asleep
    if asleep then
        asleep = false;
    end

    local now = os.time();
    


    if (now - globalCooldown < 1.5) then
        return;
    end

    if (pending and now - timeout > 5) then
        actionTimeout();
    end

    if (rollWindow and rollWindow < os.time()) then
        rollQ = Q {};
        pending = false;
        finishRoll();
    end

    if (rollQ:isEmpty()) then
        rollStrategy();
    elseif (not pending) then
        doNext();
    end
end

wakeUp = function()
    if (asleep) then
        asleep = false;
    end
end

-- Start the main loop when addon loads
ashita.events.register('d3d_present', 'roller_main_loop', mainLoop);

local ignoreIds = T { 177, 178, 96, 133 };

ashita.events.register('packet_in', 'roller_action_cb', function(e)
    if (e.id ~= 0x0028) then return; end

    -- Filter JAs
    local category = ashita.bits.unpack_be(e.data_raw, 0, 82, 4);
    if (category ~= 6) then return; end

    -- Determine if we did the action
    local actorId = ashita.bits.unpack_be(e.data_raw, 0, 40, 32);
    if (actorId ~= GetPlayerEntity().ServerId) then return; end

    -- Determine if action is rolling related
    local param = ashita.bits.unpack_be(e.data_raw, 0, 86, 16);

    -- print('param: ' .. param)
    -- print('pending param: ' .. rollQ:peek().param);
    -- print('pending: ' .. (pending and 'true' or 'false'));
    ---@diagnostic disable-next-line: need-check-nil
    if (not rollsByParam[param]) then return; end

    if (pending and rollQ:peek() and param == rollQ:peek().param) then
        -- If the action matches the top of the queue, action complete
        message('action complete: ' .. rollQ:peek().en);
        actionComplete();
    elseif (not rollQ:isEmpty()) then
        -- If the action does not match, cleare queue and restrategize
        rollQ = Q {};
        rollStrategy();
    end

    if (ignoreIds:contains(param)) then return; end

    -- Update roll number
    rollNum = ashita.bits.unpack_be(e.data_raw, 0, 213, 17);
    message('Rolled: ' .. tostring(rollNum));

    -- Start over if we busted
    if (rollNum == 12) then -- Bust
        finishRoll();
        rollQ = Q {};
        rollStrategy();
    end
end);

local startCommands = T { 'start', 'go', 'on', 'enable' };
local stopCommands = T { 'stop', 'quit', 'off', 'disable' };

local function setRoll(slot, text)
    local name = (function(inputText)
        for k, v in pairs(fuzzyNames) do
            for _, j in ipairs(v) do
                if inputText:startswith(j) then
                    return k
                end
            end
        end
    end)(text:lower());

    if (name) then
        if (rolls[slot].value == name) then
            message(('Roll %i is currently: %s'):format(slot, rolls[slot].value));
            -- Nothing needs to be done
            return;
        end

        if (rolls[slot % 2 + 1].value == name) then
            rolls[slot % 2 + 1]:set(rolls[slot].value);
        end

        message(('Roll %i set to %s'):format(slot, name));
        rolls[slot]:set(name);
        wakeUp();
    else
        message(('Roll %i is currently: %s'):format(slot, rolls[slot].value));
    end
end

-- Apply a preset roll combination
local function applyPreset(presetName)
    local preset = presets[presetName:lower()];
    if preset then
        rolls[1]:set(preset[1]);
        rolls[2]:set(preset[2]);
        message(('Preset "%s" applied: %s + %s'):format(presetName, preset[1], preset[2]));
        wakeUp();
        return true;
    end
    return false;
end

enabled.on_change:register(function()
    rollQ = Q {};
    -- Clear any pending actions when toggling
    pending = false;
    timeout = nil;
end);

ashita.events.register('command', 'command_cb', function(e)
    local args = e.command:args();
    if (#args == 0 or not args[1]:any('/roller')) then
        return;
    end

    args:remove(1);

    -- Block all related commands..
    e.blocked = true;

    local cmd = args[1] or '';
    if cmd then 
        cmd = cmd:lower(); 
        args:remove(1);
    end

    -- Handle no command or status display
    if not cmd or cmd == '' or cmd == 'status' or cmd == 'rolls' then
        updateJobInfo();
        if enabled.value then
            message('Automatic Rolling is ON.');
        else
            message('Automatic Rolling is OFF.');
        end
        
        if mainjob == 17 then
            message('Mode: Main Job COR (Full Features)');
        elseif subjob == 17 then
            message('Mode: Sub Job COR (Limited Features - Single Roll Only)');
        else
            message('Mode: Not COR (No Rolling Available)');
        end
        
        message('Roll 1: ' .. rolls[1].value);
        if subjob == 17 then
            message('Roll 2: DISABLED (Sub COR only allows one roll)');
        else
            message('Roll 2: ' .. rolls[2].value);
        end
        return;
    end

    -- Start/Stop commands
    if (startCommands:contains(cmd)) then
        message('Rolling enabled.');
        enabled:set(true);
    elseif (stopCommands:contains(cmd)) then
        message('Rolling disabled.');
        enabled:set(false);
        once = false; -- Reset once mode
        
    -- Preset commands
    elseif presets[cmd] then
        applyPreset(cmd);
        
    -- Roll setting commands
    elseif (cmd == 'roll1') then
        if (#args > 0) then
            setRoll(1, args:concat(' '));
        else
            message(('Roll 1 is currently: %s'):format(rolls[1].value));
        end
    elseif (cmd == 'roll2') then
        if (#args > 0) then
            setRoll(2, args:concat(' '));
        else
            message(('Roll 2 is currently: %s'):format(rolls[2].value));
        end
        
    -- Settings commands
    elseif (cmd == 'engaged') then
        local arg = args[1] and args[1]:lower();
        if not arg then
            settings.engaged = not settings.engaged;
        elseif arg == 'on' or arg == 'true' then
            settings.engaged = true;
        elseif arg == 'off' or arg == 'false' then
            settings.engaged = false;
        end
        message('Engaged Only: ' .. (settings.engaged and 'On' or 'Off'));
        libSettings.save();
        
    elseif (cmd == 'crooked2') then
        local arg = args[1] and args[1]:lower();
        if arg == 'on' then
            settings.crooked2 = true;
        elseif arg == 'off' then
            settings.crooked2 = false;
        end
        message('Crooked Cards on Roll 2: ' .. (settings.crooked2 and 'On' or 'Off'));
        libSettings.save();
        
    elseif (cmd == 'randomdeal') then
        local arg = args[1] and args[1]:lower();
        if arg == 'on' then
            settings.randomdeal = true;
        elseif arg == 'off' then
            settings.randomdeal = false;
        end
        message('Random Deal: ' .. (settings.randomdeal and 'On' or 'Off'));
        libSettings.save();
        
    elseif (cmd == 'oldrandomdeal') then
        local arg = args[1] and args[1]:lower();
        if arg == 'on' then
            settings.oldrandomdeal = true;
        elseif arg == 'off' then
            settings.oldrandomdeal = false;
        end
        local mode = settings.oldrandomdeal and 'Fold/Snake Eye' or 'Crooked Cards';
        message('Random Deal Mode: ' .. mode);
        libSettings.save();
        
    elseif (cmd == 'partyalert') then
        local arg = args[1] and args[1]:lower();
        if arg == 'on' then
            settings.partyalert = true;
        elseif arg == 'off' then
            settings.partyalert = false;
        end
        message('Party Alert: ' .. (settings.partyalert and 'On' or 'Off'));
        libSettings.save();
        
    elseif (cmd == 'gamble') then
        local arg = args[1] and args[1]:lower();
        if arg == 'on' then
            settings.gamble = true;
        elseif arg == 'off' then
            settings.gamble = false;
        end
        message('Gamble Mode: ' .. (settings.gamble and 'On' or 'Off'));
        libSettings.save();
        
    elseif (cmd == 'bustrecovery') then
        local arg = args[1] and args[1]:lower();
        if arg == 'on' then
            settings.bustrecovery = true;
        elseif arg == 'off' then
            settings.bustrecovery = false;
        end
        message('Bust Recovery Priority: ' .. (settings.bustrecovery and 'Random Deal First' or 'Fold First'));
        libSettings.save();
        
    elseif (cmd == 'once') then
        message('Will roll until both rolls are up, then stop.');
        once = true;
        
    elseif (cmd == 'snakeeye') then
        local arg = args[1] and args[1]:lower();
        if arg == 'on' then
            settings.hasSnakeEye = true;
        elseif arg == 'off' then
            settings.hasSnakeEye = false;
        else
            updateJobInfo();
            message('Snake Eye: ' .. (hasSnakeEye and 'Enabled' or 'Disabled'));
            return;
        end
        message('Snake Eye: ' .. (settings.hasSnakeEye and 'Enabled' or 'Disabled'));
        libSettings.save();
        
    elseif (cmd == 'fold') then
        local arg = args[1] and args[1]:lower();
        if arg == 'on' then
            settings.hasFold = true;
        elseif arg == 'off' then
            settings.hasFold = false;
        else
            updateJobInfo();
            message('Fold: ' .. (hasFold and 'Enabled' or 'Disabled'));
            return;
        end
        message('Fold: ' .. (settings.hasFold and 'Enabled' or 'Disabled'));
        libSettings.save();
        
    elseif (cmd == 'debug') then
        updateJobInfo();
        message('=== Debug Info ===');
        message('Main Job: ' .. tostring(mainjob));
        message('Sub Job: ' .. tostring(subjob));
        message('Snake Eye Enabled: ' .. tostring(hasSnakeEye));
        message('Fold Enabled: ' .. tostring(hasFold));
        message('Settings Snake Eye: ' .. tostring(settings.hasSnakeEye));
        message('Settings Fold: ' .. tostring(settings.hasFold));
    elseif (cmd == 'help') then
        message('=== J-Roller Enhanced Commands ===');
        message('/roller - Show status');
        message('/roller start/stop - Enable/disable rolling');
        message('/roller roll1/roll2 <name> - Set roll');
        message('/roller <preset> - Apply preset (tp, acc, ws, nuke, pet, etc.)');
        message('/roller engaged on/off - Only roll while engaged');
        message('/roller crooked2 on/off - Use Crooked Cards on roll 2');
        message('/roller randomdeal on/off - Use Random Deal');
        message('/roller partyalert on/off - Alert party before rolling');
        message('/roller gamble on/off - Gamble for double 11s');
        message('/roller bustrecovery on/off - Prioritize Random Deal for bust recovery');
        message('/roller once - Roll both rolls once then stop');
        message('/roller snakeeye/fold on/off - Merit ability settings');
        message('/roller debug - Show debug information');
    else
        message('Unknown command: ' .. cmd .. '. Use /roller help for commands.');
    end
end)

buffLoss:register(wakeUp);
zoneChange:register(function()
    enabled:set(false);
    sleep();
end)

-- TODO: Zone change and lose buff events
