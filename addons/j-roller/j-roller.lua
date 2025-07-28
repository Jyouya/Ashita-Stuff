addon.name = 'J-Roller';
addon.author = 'Jyouya - Enhancements by Palmer (Zodiarchy @ Asura)';
addon.version = '2.0';
addon.desc = 'The ultimate Corsair auto-roller with advanced features';

require('table');
local Q = require('Queue');
local M = require('J-Mode');
local GUI = require('J-GUI');
local ffi = require('ffi');
local chat = require('chat');
local getAbilityRecasts = require('getAbilityRecasts')
local buffLoss = require('events.buffChange').buffLoss;

local functions = require('J-GUI/functions');
functions.addResourcePath(addon.path .. '\\assets\\');

local zoneChange = require('events.zoneChange');
local libSettings = require('settings');

-- Load our abstracted modules
local ImGuiInterface = require('interface');
local CommandHandler = require('commands');
local RollingStrategy = require('strategy');
local StateManager = require('state');

-- Load other required modules
local fuzzyNames = require('FuzzyNames');
local rollsByName = require('actions').rollsByName;
local rollsByParam = require('actions').rollsByParam;
local cities = require('cities');
local presets = require('presets');

local defaultSettings = T {
    x = 200,
    y = 200,
    rolls = {'Wizard\'s Roll', 'Warlock\'s Roll'},
    -- Enhanced AshitaRoller features
    engaged = false, -- Only roll while engaged
    crooked2 = false, -- Save Crooked Cards for roll 2 only (vs normal: use on roll 1 + reset)
    randomdeal = true, -- Use Random Deal
    oldrandomdeal = false, -- Use Random Deal for Snake/Fold vs Crooked
    partyalert = false, -- Alert party before rolling
    gamble = false, -- Aggressive mode: target 11 on roll 1, exploit bust immunity for guaranteed double 11s
    bustimmunity = true, -- Exploit bust immunity (11 on roll 1) for aggressive roll 2
    safemode = false, -- Ultra-conservative mode: only double up on rolls 1-5, like subjob COR
    townmode = false, -- Only roll when not in town/safe zones
    rollwithbust = true, -- Allow Roll 2 even when busted (party still benefits)
    smartsnakeeye = true, -- Use Snake Eye for end-of-rotation optimization when it will recharge in time
    hasSnakeEye = true, -- true = enabled, false = disabled
    hasFold = true, -- true = enabled, false = disabled
    -- ImGui window settings
    showImGuiMenu = false, -- Show/hide ImGui menu
    imguiMenuX = 100, -- ImGui window X position
    imguiMenuY = 100, -- ImGui window Y position
    -- Random Deal Priority (1 = highest priority)
    randomDealPriority = {'Crooked Cards', 'Snake Eye', 'Fold'}
};

local settings = libSettings.load(defaultSettings);

-- Core variables
local rollQ = Q {};
local pending = {false};
local timeout = {nil};

local rollNum = {0};
local rollWindow = {nil};
local activeRolls = T {0, 0};

local currentRoll = {nil};
local globalCooldown = {0};
local lastActive = {0};

local waiting = {false};
local asleep = {true};

local recasts = T {};

-- Advanced rolling variables (from AshitaRoller)
local lastRoll = {0};
local rollCrooked = {false};
local roll1RollTime = {0};
local roll2RollTime = {0};

local enabled = M(false, 'Enabled');
local randomDeal = M(true, 'Use Random Deal')
local once = {false};

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

-- Initialize state manager
local stateManager = StateManager.new({settings = settings});

-- Create utility functions using state manager
local message = StateManager.createMessage(addon.name, chat);
local sleepManager = StateManager.createSleepManager(lastActive, asleep);

-- Apply preset function
local applyPreset = StateManager.createPresetApplier(presets, rolls, message,
                                                     sleepManager.wakeUp);

-- Set once mode function
local function setOnce(value)
    once[1] = value;
    if not value then message('Once mode disabled'); end
end

-- Action handlers
local actionComplete = StateManager.createActionCompleteHandler(rollQ,
                                                                rollWindow,
                                                                activeRolls,
                                                                currentRoll,
                                                                globalCooldown);
local finishRoll = StateManager.createFinishRollHandler(message, lastRoll,
                                                        rollWindow, rollNum,
                                                        currentRoll);

-- Initialize rolling strategy
local rollingStrategy = RollingStrategy.new({
    settings = settings,
    rollsByName = rollsByName,
    rollsByParam = rollsByParam,
    rolls = rolls,
    message = message,
    hasBuff = StateManager.hasBuff,
    isIncapacitated = StateManager.isIncapacitated,
    sleep = sleepManager.sleep,
    rollQ = rollQ
});

-- Update roll time tracking
local function updateRollTiming(rollNumber)
    if rollNumber == 1 then
        roll1RollTime[1] = os.time();
        rollCrooked[1] = false;
    elseif rollNumber == 2 then
        roll2RollTime[1] = os.time();
        rollCrooked[1] = false;
    end
end

-- Enhanced roll strategy with state sync
local function rollStrategy()
    stateManager:updateJobInfo();

    -- Sync state with strategy module
    rollingStrategy:updateState({
        mainjob = stateManager.mainjob,
        subjob = stateManager.subjob,
        hasSnakeEye = stateManager.hasSnakeEye,
        hasFold = stateManager.hasFold,
        once = once[1],
        rollWindow = rollWindow[1],
        currentRoll = currentRoll[1],
        rollNum = rollNum[1],
        lastRoll = lastRoll[1],
        rollCrooked = rollCrooked[1],
        roll1RollTime = roll1RollTime[1],
        roll2RollTime = roll2RollTime[1],
        recasts = recasts
    });

    -- Execute strategy
    if rollWindow[1] then
        rollingStrategy:executeRollStrategy(finishRoll);
    else
        local shouldRoll = rollingStrategy:doNewRoll(enabled.value);
        if shouldRoll and once[1] then
            local haveRoll1 = StateManager.hasBuff(rolls[1].value);
            local haveRoll2 = StateManager.hasBuff(rolls[2].value);

            if stateManager.subjob == 17 then
                if haveRoll1 then setOnce(false); end
            else
                if haveRoll1 and haveRoll2 then setOnce(false); end
            end
        end
    end
end

-- Action timeout function
local function actionTimeout()
    rollQ:clear();
    rollStrategy();
    pending[1] = false;
    timeout[1] = nil;
end

-- Action execution function  
local function doNext()
    if rollQ:isEmpty() then return; end

    local recasts = getAbilityRecasts();
    local action = rollQ:peek();

    local cd = recasts[action.id];
    local abilityName = action.en;

    if (abilityName == nil) then
        message('Ability Name nil');
        return;
    end

    if (cd == 0) then
        -- Special check for Random Deal - only use if there's something useful to reset
        if abilityName == 'Random Deal' then
            local shouldUseRandomDeal = false;

            if settings.oldrandomdeal then
                -- Old mode: Reset Snake Eye/Fold if they're on cooldown
                local snakeOnCD = stateManager.hasSnakeEye and recasts[197] > 0;
                local foldOnCD = stateManager.hasFold and recasts[198] > 0;
                shouldUseRandomDeal = snakeOnCD or foldOnCD;
            else
                -- New mode: Reset Crooked Cards if it's on cooldown (we just used it)
                shouldUseRandomDeal = recasts[96] > 0;
            end

            if not shouldUseRandomDeal then
                -- Skip Random Deal if there's nothing useful to reset
                rollQ:pop();
                doNext(); -- Process next action
                return;
            end
        end

        local command = ('/ja "%s" <me>'):format(abilityName);
        message('command: ' .. command);
        AshitaCore:GetChatManager():QueueCommand(-1, command);
        pending[1] = true;
        timeout[1] = os.time();
    elseif (rollWindow[1] and os.time() + cd > rollWindow[1]) then
        -- If we're in a roll window and the ability won't be ready in time, clear and restart
        rollQ:clear();
        rollStrategy()
    elseif (not rollWindow[1] and action.id == 193 and cd > 10) then
        -- If we're not in a roll window and Phantom Roll has significant cooldown, clear and restart
        rollQ:clear();
        rollStrategy()
    end
end

-- Main loop function
local function mainLoop()
    if (not enabled.value) then return; end

    -- Update job info to ensure we have current job status
    stateManager:updateJobInfo();

    -- Wake up if we're enabled but asleep
    if asleep[1] then asleep[1] = false; end

    local now = os.time();

    if (now - globalCooldown[1] < 1.5) then return; end

    if (pending[1] and now - timeout[1] > 5) then actionTimeout(); end

    if (rollWindow[1] and rollWindow[1] < os.time()) then
        pending[1] = false;
        finishRoll();
        -- Don't clear queue here - let Random Deal and other queued actions execute
    end

    if (rollQ:isEmpty()) then
        rollStrategy();
    elseif (not pending[1]) then
        doNext();
    end
end

-- Initialize ImGui interface
local imguiInterface = ImGuiInterface.new({
    settings = settings,
    libSettings = libSettings,
    enabled = enabled,
    rolls = rolls,
    message = message,
    updateJobInfo = function() stateManager:updateJobInfo() end,
    applyPreset = applyPreset,
    once = once,
    setOnce = setOnce
});

-- Initialize command handler
local commandHandler = CommandHandler.new({
    settings = settings,
    libSettings = libSettings,
    enabled = enabled,
    rolls = rolls,
    message = message,
    updateJobInfo = function() stateManager:updateJobInfo() end,
    applyPreset = applyPreset,
    setOnce = setOnce,
    imguiInterface = imguiInterface
});

local gear_size = ffi.new('D3DXVECTOR2', {16.0, 16.0});
local gear_rect = ffi.new('RECT', {0, 0, 16, 16});
-- GUI setup
ashita.events.register('load', 'jroller_gui_load', function()
    local UI = GUI.Container:new({
        layout = GUI.Container.LAYOUT.GRID,
        girdRows = 3,
        gridCols = 2,
        fillDirection = GUI.Container.LAYOUT.HORIZONTAL,
        gridGap = 10,
        padding = {x = 10, y = 10},
        draggable = true,
        _x = settings.x,
        _y = settings.y,
        _width = 280,
        _height = 140,
        onDragFinish = function(view)
            local pos = view:getPos();
            settings.x = pos.x;
            settings.y = pos.y;
            libSettings.save();
        end
    });

    GUI.ctx.addView(UI);

    UI:addView(GUI.ToggleButton:new({
        variable = enabled,
        activeColor = T {0, 55, 255},
        inactiveColor = T {255, 0, 0},
        activeTextureFile = 'On.png',
        inactiveTextureFile = 'Off.png'
    }), GUI.Container:new({
        layout = GUI.Container.LAYOUT.GRID,
        gridRows = 1,
        gridCols = GUI.Container.LAYOUT.AUTO,
        fillDirection = GUI.Container.LAYOUT.HORIZONTAL,
        gridGap = 4,
        padding = {x = 0, y = 0},
        draggable = true
    }):addView(GUI.ToggleButton:new({
        _width = 20,
        _height = 20,
        getTextureSize = function() return gear_size; end,
        getRect = function() return gear_rect; end,
        activeColor = T {0, 55, 255},
        inactiveColor = T {0, 55, 255},
        activeTextureFile = 'whitegear.png',
        inactiveTextureFile = 'whitegear.png',
        getValue = function() return imguiInterface.showImGuiMenu[1]; end,
        toggle = function()
            imguiInterface.showImGuiMenu[1] =
                not imguiInterface.showImGuiMenu[1];
        end
    }), GUI.Label:new({
        padding = {x = 0, y = 4},
        getValue = function()
            local status = asleep[1] and 'Sleeping' or rollQ:peek() and
                               rollQ:peek().en or 'Idle';
            if enabled.value and status == 'Idle' then
                status = 'Enabled';
            end
            return 'Status: ' .. status;
        end
    })), GUI.Label:new({value = 'Roll 1'}), GUI.Dropdown:new({
        color = T {0, 55, 255},
        animated = true,
        expandDirection = GUI.ENUM.DIRECTION.DOWN,
        _width = 140,
        isFixedWidth = true,
        variable = rolls[1]
    }), GUI.Label:new({value = 'Roll 2'}), GUI.Dropdown:new({
        color = T {0, 55, 255},
        animated = true,
        expandDirection = GUI.ENUM.DIRECTION.DOWN,
        _width = 140,
        isFixedWidth = true,
        variable = rolls[2],
        disabled = function()
            stateManager:updateJobInfo();
            return stateManager.subjob == 17;
        end,
        getValue = function()
            stateManager:updateJobInfo();
            if stateManager.subjob == 17 then
                return 'N/A (Sub COR)';
            else
                return rolls[2].value;
            end
        end
    }));
end)

-- ImGui rendering
local function renderImGuiMenu()
    stateManager:updateJobInfo();

    -- Update ImGui state
    imguiInterface:updateState({
        mainjob = stateManager.mainjob,
        subjob = stateManager.subjob,
        hasSnakeEye = stateManager.hasSnakeEye,
        hasFold = stateManager.hasFold,
        asleep = asleep[1],
        rollQ = rollQ,
        rollWindow = rollWindow[1],
        pending = pending[1]
    });

    imguiInterface:render();
end

-- Register main loop and ImGui rendering
ashita.events.register('d3d_present', 'roller_main_loop', mainLoop);
ashita.events.register('d3d_present', 'roller_imgui_render', renderImGuiMenu);

-- Packet handling for action confirmation and roll detection
local ignoreIds = T {177, 178, 96, 133};

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

    if (not rollsByParam[param]) then return; end

    if (pending[1] and rollQ:peek() and param == rollQ:peek().param) then
        -- If the action matches the top of the queue, action complete
        message('action complete: ' .. rollQ:peek().en);
        actionComplete();
    elseif (not rollQ:isEmpty()) then
        -- If the action does not match, clear queue and restrategize
        rollQ:clear();
        rollStrategy();
    end

    if (ignoreIds:contains(param)) then return; end

    -- Update roll number
    rollNum[1] = ashita.bits.unpack_be(e.data_raw, 0, 213, 17);

    -- Filter out Crooked Cards confirmation (601) - not a real roll result
    if rollNum[1] ~= 601 then message('Rolled: ' .. tostring(rollNum[1])); end

    -- Start over if we busted
    if (rollNum[1] == 12) then -- Bust
        finishRoll();
        rollQ:clear();
        rollStrategy();
    end
end);

-- Command handling
enabled.on_change:register(function()
    rollQ:clear();
    -- Clear any pending actions when toggling
    pending[1] = false;
    timeout[1] = nil;
    -- Debug message
    message('Rolling ' .. (enabled.value and 'ENABLED' or 'DISABLED'));
    if enabled.value then sleepManager.wakeUp(); end
end);

ashita.events.register('command', 'command_cb', function(e)
    -- Update command handler state
    stateManager:updateJobInfo();
    commandHandler:updateState({
        mainjob = stateManager.mainjob,
        subjob = stateManager.subjob,
        hasSnakeEye = stateManager.hasSnakeEye,
        hasFold = stateManager.hasFold,
        once = once[1]
    });

    -- Process command
    local handled = commandHandler:processCommand(e);
    if handled then
        e.blocked = true;
        sleepManager.wakeUp(); -- Wake up after any command
    end
end)

-- Event handlers
buffLoss:register(sleepManager.wakeUp);
zoneChange:register(function()
    enabled:set(false);
    sleepManager.sleep();
end)
