-- State management module for J-Roller Enhanced
local StateManager = {};

-- Initialize the state manager
function StateManager.new(dependencies)
    local self = {
        -- Dependencies from main module
        settings = dependencies.settings,

        -- Job detection and merit abilities
        mainjob = nil,
        subjob = nil,
        hasSnakeEye = false,
        hasFold = false,
    };

    setmetatable(self, { __index = StateManager });
    return self;
end

-- Update job information and merit abilities
function StateManager:updateJobInfo()
    local player = GetPlayerEntity();
    if not player then return; end

    local playerMgr = AshitaCore:GetMemoryManager():GetPlayer();
    if not playerMgr then return; end

    self.mainjob = playerMgr:GetMainJob();
    self.subjob = playerMgr:GetSubJob();

    -- Merit abilities are only available to main job COR
    if self.mainjob == 17 then
        -- Main job COR: use manual merit ability settings
        self.hasSnakeEye = self.settings.hasSnakeEye;
        self.hasFold = self.settings.hasFold;
    else
        -- Subjob COR: no merit abilities available
        self.hasSnakeEye = false;
        self.hasFold = false;
    end
end

-- Get current state information
function StateManager:getState()
    return {
        mainjob = self.mainjob,
        subjob = self.subjob,
        hasSnakeEye = self.hasSnakeEye,
        hasFold = self.hasFold,
    };
end

-- Utility function to check for buffs
-- ? Maybe strip this down, since it's only used to specifically check for
-- ? Buffs in english
function StateManager.hasBuff(matchBuff)
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

-- Check for incapacitation status
-- Amnesia, Impairment, Petrification, Stun, dead, charm, terror, sleep
function StateManager.isIncapacitated()
    return StateManager.hasBuff(16)
        or StateManager.hasBuff(261)
        or StateManager.hasBuff(7)
        or StateManager.hasBuff(10)
        or StateManager.hasBuff(0)
        or StateManager.hasBuff(14)
        or StateManager.hasBuff(28)
        or StateManager.hasBuff(2);
end

-- Message helper function
function StateManager.createMessage(addonName, chat)
    return function(text)
        print(chat.header(addonName):append(chat.message(text)));
    end
end

-- Sleep management helper
function StateManager.createSleepManager(lastActiveRef, asleepRef)
    local sleepManager = {};

    function sleepManager.sleep()
        asleepRef[1] = true;
        lastActiveRef[1] = os.time();
        ashita.tasks.once(10, function()
            if (os.time() >= lastActiveRef[1] + 10) then
                sleepManager.wakeUp();
            end
        end);
    end

    function sleepManager.wakeUp()
        if (asleepRef[1]) then
            asleepRef[1] = false;
        end
    end

    return sleepManager;
end

-- Preset application helper
function StateManager.createPresetApplier(presets, rolls, message, wakeUp)
    return function(presetName)
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
end

-- Action completion handler
function StateManager.createActionCompleteHandler(rollQ, rollWindow, activeRolls, currentRoll, globalCooldown)
    return function()
        local act = rollQ:pop();

        rollQ.pending = false;
        rollQ.timeout = nil;
        globalCooldown[1] = os.time();

        -- If we just started a new roll, do some setup
        if (act.en:contains(' Roll')) then
            rollWindow[1] = os.time() + 45;
            activeRolls[2] = activeRolls[1];
            activeRolls[1] = os.time();

            currentRoll[1] = act.en;
        end
    end
end

-- Finish roll handler
function StateManager.createFinishRollHandler(message, lastRoll, rollWindow, rollNum, currentRoll)
    return function()
        message('Finished rolling: ' .. currentRoll[1] .. ' final roll: ' .. rollNum[1]);
        lastRoll[1] = rollNum[1];
        rollWindow[1] = nil;
    end
end

return StateManager;
