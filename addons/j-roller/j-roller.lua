addon.name    = 'J-Roller';
addon.author  = 'Jyouya';
addon.version = '1.0';
addon.desc    = 'An advanced auto-roller';



require('table');
local Q = require('Queue');
local M = require('J-Mode');
local GUI = require('J-GUI');
local VStack = require('J-GUI.VStack');
local encoding = require('encoding');
local chat = require('chat');
local getAbilityRecasts = require('getAbilityRecasts')
local japanese = (AshitaCore:GetConfigurationManager():GetInt32('boot', 'ashita.language', 'ashita', 2) == 1);
local buffLoss = require('events.buffChange').buffLoss;

local zoneChange = require('events.zoneChange');

local libSettings = require('settings');

local defaultSettings = T{
    x = 200,
    y = 200,
    rolls = {
        'Wizard\'s Roll',
        'Warlock\'s Roll',
    } 
};

local settings = libSettings.load(defaultSettings);

local fuzzyNames = require('FuzzyNames');
local rollsByName = require('actions').rollsByName;
local rollsByParam = require('actions').rollsByParam;
local cities = require('cities');

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
        girdRows = GUI.Container.LAYOUT.AUTO,
        gridCols = 2,
        fillDirection = GUI.Container.LAYOUT.HORIZONTAL,
        gridGap = 8,
        padding = { x = 0, y = 0 },
        draggable = true,
        _x = settings.x,
        _y = settings.y,
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
            activeTextureFile = 'assets/On.png',
            inactiveTextureFile = 'assets/Off.png'
        }),
        GUI.Label:new({
            getValue = function()
                return 'Status: ' ..
                    (asleep and 'Sleeping' or rollQ:peek() and rollQ:peek().en or 'Idle')
            end
        }),
        GUI.Label:new({ value = 'Roll 1', _y = -10 }),
        GUI.Dropdown:new({
            color = T { 0, 55, 255 },
            animated = true,
            expandDirection = GUI.ENUM.DIRECTION.DOWN,
            _width = 120,
            isFixedWidth = true,
            variable = rolls[1]
        }),
        GUI.Label:new({ value = 'Roll 2' }),
        GUI.Dropdown:new({
            color = T { 0, 55, 255 },
            animated = true,
            expandDirection = GUI.ENUM.DIRECTION.DOWN,
            _width = 120,
            isFixedWidth = true,
            variable = rolls[2]
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

-- ? Maybe strip this down, since it's only used to specifically check for
-- ? Buffs in english
local function hasBuff(matchBuff)
    local buffs = AshitaCore:GetMemoryManager():GetPlayer():GetBuffs();
    if (type(matchBuff) == 'string') then
        local matchText = string.lower(matchBuff);
        for _, buff in pairs(buffs) do
            local buffString = AshitaCore:GetResourceManager():GetString("buffs.names", buff)
            if (buffString) then
                buffString = encoding:ShiftJIS_To_UTF8(buffString:trimend('\x00'));
                if (not japanese) then
                    buffString = string.lower(buffString);
                end

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
        or hasBuff(29)
        or hasBuff(2);
end

local wakeUp;

local function sleep()
    ashita.events.unregister('d3d_present', 'roller_main_loop');
    asleep = true
    lastActive = os.time();
    ashita.tasks.once(10, function()
        if (os.time() >= lastActive + 10) then
            wakeUp();
        end
    end);
end

local function doNewRoll()
    -- Do not auto roll in town
    if (cities[AshitaCore:GetResourceManager():GetString("zones.names", AshitaCore:GetMemoryManager():GetParty():GetMemberZone(0))]) then
        return;
    end

    -- Do not roll if disabled, or incapacitated
    if (not enabled.value or isIncapacitated()) then
        return;
    end

    -- Do not roll while hidden
    if (hasBuff('sneak') or hasBuff('invisible')) then
        return;
    end

    if (hasBuff('Bust')) then
        if (recasts[198] == 0) then
            rollQ:push(rollsByName['Fold']);
            return;
        elseif recasts[196] < 30 then
            rollQ:push(rollsByName['Random Deal']);
            return;
        end
    end

    if recasts[193] > 10 then
        sleep();
        return
    end

    if (not hasBuff(rolls[1].value)) then
        if recasts[96] < 30 then
            rollQ:push(rollsByName['Crooked Cards']);
        end
        rollQ:push(rollsByName[rolls[1].value]);
    elseif (not (hasBuff(rolls[2].value) or hasBuff('Bust'))) then
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
    local current = rollsByName[currentRoll];
    local snakeEyesActive = hasBuff('Snake Eye');

    if (snakeEyesActive) then
        if (not waiting) then
            globalCooldown = os.time() + 1;
            return 'wait'
        end
        waiting = false;
        rollQ:push(doubleUpFactory(current));
        return true;
    end

    if ((rollNum == current.lucky - 1)
            or (rollNum == 10)
            or (rollNum == 9 and current.unlucky ~= 10)
            or (rollNum == current.unlucky and current.unlucky >= 8)
            or (rollNum == 8
                and os.time() - activeRolls[2] <= 270
                and current.unlucky ~= 9
                and recasts[198] < 30)
        ) then
        if (recasts[197] < rollWindow - os.time() - 5) then
            rollQ:push(rollsByName['Snake Eye']);
            rollQ:push(doubleUpFactory(current));
            return true;
        elseif (recasts[196] == 0 and randomDeal.value) then
            rollQ:push(rollsByName['Random Deal']);
            return true;
        end
    end
    return false;
end

local function finishRoll()
    rollWindow = nil;
end;

local function doubleUp()
    local current = rollsByName[currentRoll];
    if ((rollNum == current.unlucky)
            or (rollNum < 8)
            or (rollNum == 8 and current.unlucky < 8)
            or (rollNum == 8 and recasts[197] < rollWindow - os.time() - 5)
        ) then
        rollQ:push(doubleUpFactory(current));
        return true;
    end
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
        print('Ability Name nil');
    end

    if (cd == 0) then
        AshitaCore:GetChatManager():QueueCommand(-1, ('/ja "%s" <me>'):format(abilityName));
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
    if (not enabled.value) then
        sleep();
        return;
    end

    local now = os.time();

    if (now - globalCooldown < 1) then
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
        ashita.events.register('d3d_present', 'roller_main_loop', mainLoop);
        asleep = false;
    end
end

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

    print('param: ' .. param)
    print('pending param: ' .. rollQ:peek().param);
    print('pending: ' .. (pending and 'true' or 'false'));
    ---@diagnostic disable-next-line: need-check-nil
    if (not rollsByParam[param]) then return; end

    if (pending and param == rollQ:peek().param) then
        -- If the action matches the top of the queue, action complete
        print('action complete: ' .. rollQ:peek().en);
        actionComplete();
    elseif (not rollQ:isEmpty()) then
        -- If the action does not match, cleare queue and restrategize
        rollQ = Q {};
        rollStrategy();
    end

    if (ignoreIds:contains(param)) then return; end

    -- Update roll number
    rollNum = ashita.bits.unpack_be(e.data_raw, 0, 213, 17);
    print(rollNum);

    -- Start over if we busted
    if (rollNum == 12) then -- Bust
        finishRoll();
        rollQ = Q {};
        rollStrategy();
    end
end);

local startCommands = T { 'start', 'go', 'on', 'enable' };
local stopCommands = T { 'stop', 'quit', 'off', 'disable' };

local function message(text)
    print(chat.header(addon.name):append(chat.message(text)));
end

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

enabled.on_change:register(function()
    rollQ = Q {};
    wakeUp();
end);

ashita.events.register('command', 'command_cb', function(e)
    local args = e.command:args();
    if (#args == 0 or not args[1]:any('/roller')) then
        return;
    end

    args:remove(1);

    -- Block all related commands..
    e.blocked = true;

    local cmd = args:remove(1):lower();

    if (startCommands:contains(cmd)) then
        message('Rolling enabled.');
        enabled:set(true);

        -- rollQ = Q {};
        -- wakeUp();
    elseif (stopCommands:contains(cmd)) then
        message('Rolling disabled.');
        enabled:set(false);
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
    end
end)

buffLoss:register(wakeUp);
zoneChange:register(function()
    enabled:set(false);
    sleep();
end)

-- TODO: Zone change and lose buff events
