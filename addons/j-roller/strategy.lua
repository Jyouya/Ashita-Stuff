-- Rolling strategy module for J-Roller Enhanced
local getAbilityRecasts = require('getAbilityRecasts');

local RollingStrategy = {};

-- Initialize the rolling strategy
function RollingStrategy.new(dependencies)
    local self = {
        -- Dependencies from main module
        settings = dependencies.settings,
        rollsByName = dependencies.rollsByName,
        rollsByParam = dependencies.rollsByParam,
        rolls = dependencies.rolls,
        message = dependencies.message,
        hasBuff = dependencies.hasBuff,
        isIncapacitated = dependencies.isIncapacitated,
        sleep = dependencies.sleep,
        rollQ = dependencies.rollQ,
        
        -- State variables (updated from main)
        mainjob = nil,
        subjob = nil,
        hasSnakeEye = false,
        hasFold = false,
        once = false,
        rollWindow = nil,
        currentRoll = nil,
        rollNum = 0,
        lastRoll = 0,
        rollCrooked = false,
        roll1RollTime = 0,
        roll2RollTime = 0,
        recasts = {},
    };
    
    setmetatable(self, { __index = RollingStrategy });
    return self;
end

-- Update state information from main module
function RollingStrategy:updateState(state)
    self.mainjob = state.mainjob;
    self.subjob = state.subjob;
    self.hasSnakeEye = state.hasSnakeEye;
    self.hasFold = state.hasFold;
    self.once = state.once;
    self.rollWindow = state.rollWindow;
    self.currentRoll = state.currentRoll;
    self.rollNum = state.rollNum;
    self.lastRoll = state.lastRoll;
    self.rollCrooked = state.rollCrooked;
    self.roll1RollTime = state.roll1RollTime;
    self.roll2RollTime = state.roll2RollTime;
    self.recasts = state.recasts;
end

-- Check if we should do a new roll
function RollingStrategy:shouldDoNewRoll(enabled)
    -- Do not roll if disabled, or incapacitated
    if (not enabled or self.isIncapacitated()) then
        return false, "Disabled or incapacitated";
    end

    -- Do not roll while hidden
    if (self.hasBuff('sneak') or self.hasBuff('invisible')) then
        return false, "Hidden (sneak/invis)";
    end
    
    -- Don't roll if not COR
    if not (self.mainjob == 17 or self.subjob == 17) then
        return false, "Not COR";
    end
    
    -- Check engaged only setting
    if self.settings.engaged then
        local player = GetPlayerEntity();
        if not player or player.Status ~= 1 then -- 1 = engaged
            return false, "Not engaged";
        end
    end
    
    -- Handle 'once' mode - check if we have both rolls (or just one for sub-COR)
    if self.once then
        local haveRoll1 = self.hasBuff(self.rolls[1].value);
        local haveRoll2 = self.hasBuff(self.rolls[2].value);
        
        if self.subjob == 17 then
            -- Sub-COR only gets one roll
            if haveRoll1 then
                return false, "Once mode complete (Sub-COR)";
            end
        else
            -- Main COR gets both rolls
            if haveRoll1 and haveRoll2 then
                return false, "Once mode complete";
            end
        end
    end

    return true, "Ready to roll";
end

-- Handle bust recovery logic
function RollingStrategy:handleBustRecovery()
    if not self.hasBuff('Bust') then
        return false;
    end
    
    if self.settings.bustrecovery and self.settings.randomdeal and self.recasts[196] == 0 then
        -- Prioritize Random Deal for instant recovery
        self.rollQ:push(self.rollsByName['Random Deal']);
        return true;
    elseif (self.hasFold and self.recasts[198] == 0) then
        -- Use Fold if available
        self.rollQ:push(self.rollsByName['Fold']);
        return true;
    elseif (self.settings.randomdeal and self.recasts[196] < 30) then
        -- Fallback to Random Deal if coming off cooldown soon
        self.rollQ:push(self.rollsByName['Random Deal']);
        return true;
    end
    
    -- If no bust recovery options available, wait for Phantom Roll cooldown
    self.sleep();
    return true;
end

-- Handle Random Deal logic
function RollingStrategy:handleRandomDeal()
    if not (self.settings.randomdeal and self.mainjob == 17 and self.recasts[196] == 0) then
        return false;
    end
    
    if self.settings.oldrandomdeal then
        -- Old mode: Reset Snake Eye/Fold
        if (self.hasSnakeEye and self.recasts[197] > 0) or (self.hasFold and self.recasts[198] > 0) then
            self.rollQ:push(self.rollsByName['Random Deal']);
            return true;
        end
    else
        -- New mode: Reset Crooked Cards
        if self.recasts[96] > 0 and self.recasts[193] == 0 then
            self.rollQ:push(self.rollsByName['Random Deal']);
            return true;
        end
    end
    
    return false;
end

-- Determine which roll to do next
function RollingStrategy:determineNextRoll()
    -- Roll priority: Roll 1 first, then Roll 2 (unless sub-COR)
    
    if (not self.hasBuff(self.rolls[1].value)) then
        -- Track roll time and crooked status for advanced logic
        -- Note: roll1RollTime and rollCrooked will be updated by main module
        
        -- Use Crooked Cards if available and level 95+
        if self.mainjob == 17 and AshitaCore:GetMemoryManager():GetPlayer():GetMainJobLevel() >= 95 and self.recasts[96] == 0 then
            self.rollQ:push(self.rollsByName['Crooked Cards']);
        end
        self.rollQ:push(self.rollsByName[self.rolls[1].value]);
        return true;
    elseif (self.subjob ~= 17 and not (self.hasBuff(self.rolls[2].value) or self.hasBuff('Bust'))) then
        -- Track roll time and crooked status for advanced logic
        -- Note: roll2RollTime and rollCrooked will be updated by main module
        
        -- Roll 2 only if main COR (sub-COR gets only one roll)
        if self.settings.crooked2 and self.mainjob == 17 and AshitaCore:GetMemoryManager():GetPlayer():GetMainJobLevel() >= 95 and self.recasts[96] == 0 then
            self.rollQ:push(self.rollsByName['Crooked Cards']);
        end
        self.rollQ:push(self.rollsByName[self.rolls[2].value]);
        return true;
    end
    
    return false;
end

-- Main new roll strategy
function RollingStrategy:doNewRoll(enabled)
    self.recasts = getAbilityRecasts();
    
    local canRoll, reason = self:shouldDoNewRoll(enabled);
    if not canRoll then
        if reason == "Once mode complete" or reason == "Once mode complete (Sub-COR)" then
            self.message('Once mode: Roll complete');
            -- Note: once flag will be reset by main module
        end
        return false;
    end

    -- Enhanced bust handling with priority options
    if self:handleBustRecovery() then
        return true;
    end

    -- Check phantom roll recast first
    if self.recasts[193] > 10 then
        self.sleep();
        return true;
    end

    -- Enhanced Random Deal logic
    if self:handleRandomDeal() then
        return true;
    end

    -- Party alert before rolling
    if self.settings.partyalert and not self.hasBuff(self.rolls[1].value) and not self.hasBuff(self.rolls[2].value) then
        AshitaCore:GetChatManager():QueueCommand(-1, '/p Rolling in 8 seconds, stay close <call12>');
    end

    -- Determine which roll to do next
    if self:determineNextRoll() then
        return true;
    else
        self.sleep();
        return true;
    end
end

-- Advanced double-up logic from AshitaRoller
function RollingStrategy:shouldDoubleUp()
    local current = self.rollsByName[self.currentRoll];
    local rollID = current.param;
    local luckyNum = current.lucky;
    local unluckyNum = current.unlucky;
    
    -- Sub-COR simplified strategy: double up if roll < 5
    if self.subjob == 17 then
        if self.rollNum < 5 then
            return true, "Sub-COR: Roll < 5";
        end
        return false, "Sub-COR: Roll >= 5, stopping";
    end
    
    -- Main COR advanced strategy (from AshitaRoller)
    if self.mainjob == 17 then
        -- Gamble mode: if last roll was 11 (bust immune), be aggressive
        if self.settings.gamble and self.lastRoll == 11 then
            if self.hasSnakeEye and self.recasts[197] == 0 and (self.rollNum == 10 or (self.rollNum == (luckyNum - 1) and self.rollCrooked)) then
                return false, "Gamble: Using Snake Eye for 11 or crooked lucky";
            else
                return true, "Gamble: Immune to bust, rolling for double 11";
            end
        else
            -- Normal strategy
            if self.hasSnakeEye and self.recasts[197] == 0 and (self.rollNum == 10 or (self.rollNum == (luckyNum - 1) and (not self.settings.gamble or self.rollCrooked))) then
                return false, "Using Snake Eye for lucky or 11";
            elseif self.hasSnakeEye and self.recasts[197] == 0 and (not self.hasFold or self.recasts[198] > 0 or (self.rollCrooked and not self.settings.gamble)) and self.rollNum == unluckyNum then
                return false, "Using Snake Eye to remove unlucky";
            elseif self.hasFold and self.recasts[198] == 0 and (not self.rollCrooked or self.settings.gamble) then
                return true, "Safe to risk: have Fold and roll not crooked";
            elseif self.rollNum < 6 then
                return true, "Roll < 6, continuing";
            elseif self.hasSnakeEye and self.recasts[197] == 0 and self.rollNum + 1 ~= unluckyNum and 
                   os.time() - self.roll1RollTime < 240 and os.time() - self.roll2RollTime < 240 then
                return false, "End-game Snake Eye: rollNum+1 not unlucky, Snake Eye available";
            else
                return false, "Stopping: conditions not met";
            end
        end
    end
    
    return false, "Unknown job configuration";
end

-- Create a double-up action
function RollingStrategy:createDoubleUpAction()
    local current = self.rollsByName[self.currentRoll];
    local action = self.rollsByName['Double-Up']:copy();
    action.param = current.param;
    return action;
end

-- Execute double-up strategy
function RollingStrategy:doubleUp()
    local shouldDouble, reason = self:shouldDoubleUp();
    if shouldDouble then
        local action = self:createDoubleUpAction();
        self.rollQ:push(action);
        return true;
    end
    return false;
end

-- Advanced Snake Eye logic
function RollingStrategy:executeSnakeEye(waiting)
    -- Skip Snake Eye logic for sub-COR
    if self.subjob == 17 or not self.hasSnakeEye then
        return false;
    end
    
    local current = self.rollsByName[self.currentRoll];
    local snakeEyesActive = self.hasBuff('Snake Eye');
    local luckyNum = current.lucky;
    local unluckyNum = current.unlucky;

    if (snakeEyesActive) then
        if (not waiting) then
            -- globalCooldown will be set by main module
            return 'wait'
        end
        -- waiting = false; -- will be set by main module
        local doubleUpAction = self:createDoubleUpAction();
        self.rollQ:push(doubleUpAction);
        return true;
    end

    -- Advanced Snake Eye logic from AshitaRoller
    if self.recasts[197] == 0 then
        -- Gamble mode with bust immunity
        if self.settings.gamble and self.lastRoll == 11 then
            if self.rollNum == 10 or (self.rollNum == (luckyNum - 1) and self.rollCrooked) then
                self.rollQ:push(self.rollsByName['Snake Eye']);
                local doubleUpAction = self:createDoubleUpAction();
                self.rollQ:push(doubleUpAction);
                return true;
            end
        else
            -- Normal Snake Eye usage
            if self.rollNum == 10 or (self.rollNum == (luckyNum - 1) and (not self.settings.gamble or self.rollCrooked)) then
                self.rollQ:push(self.rollsByName['Snake Eye']);
                local doubleUpAction = self:createDoubleUpAction();
                self.rollQ:push(doubleUpAction);
                return true;
            elseif (not self.hasFold or self.recasts[198] > 0 or (self.rollCrooked and not self.settings.gamble)) and self.rollNum == unluckyNum then
                self.rollQ:push(self.rollsByName['Snake Eye']);
                local doubleUpAction = self:createDoubleUpAction();
                self.rollQ:push(doubleUpAction);
                return true;
            elseif self.rollNum + 1 ~= unluckyNum and os.time() - self.roll1RollTime < 240 and os.time() - self.roll2RollTime < 240 then
                -- End-game optimization: use Snake Eye if next roll won't be unlucky
                self.rollQ:push(self.rollsByName['Snake Eye']);
                local doubleUpAction = self:createDoubleUpAction();
                self.rollQ:push(doubleUpAction);
                return true;
            end
        end
        
        -- Fallback to Random Deal if Snake Eye conditions not met
        if self.settings.randomdeal and self.recasts[196] == 0 then
            self.rollQ:push(self.rollsByName['Random Deal']);
            return true;
        end
    end
    
    return false;
end

-- Main rolling strategy when we have an active roll window
function RollingStrategy:executeRollStrategy(finishRoll)
    self.recasts = getAbilityRecasts();

    -- If we do not have an open window, do new roll
    if (not self.rollWindow) then
        return self:doNewRoll(true); -- enabled is handled in doNewRoll
    end

    -- If we hit 11 or lucky number, we're done
    if (self.rollNum == 11 or self.rollNum == self.rollsByName[self.currentRoll].lucky) then
        -- rollWindow will be cleared by main module
        return true;
    end

    -- Try Snake Eye first
    local snakeEyeResult = self:executeSnakeEye(false); -- waiting will be managed by main module

    if (snakeEyeResult == 'wait') then
        -- waiting = true; -- will be set by main module
        return true;
    end

    if (not snakeEyeResult) then
        if (not self:doubleUp()) then
            -- If we decide not to double up, close the roll
            finishRoll();
        end
    end
    
    return true;
end

return RollingStrategy; 