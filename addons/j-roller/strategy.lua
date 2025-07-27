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
    
    -- Check town mode setting
    if self.settings.townmode then
        local zone = AshitaCore:GetMemoryManager():GetParty():GetMemberZone(0);
        local zoneName = AshitaCore:GetResourceManager():GetString('zones.names', zone);
        local cities = require('cities');
        

        
        if cities[zoneName] then
            return false, "In town (Town mode enabled)";
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

-- Handle bust recovery with available abilities
function RollingStrategy:handleBustRecovery()
    -- Only handle bust recovery if we actually have the Bust buff
    if not self.hasBuff('Bust') then
        return false;
    end
    
    -- Priority: Fold first (removes bust), then Random Deal (instant recovery)
    if (self.hasFold and self.recasts[198] and self.recasts[198] == 0) then
        self.message('Using Fold for bust recovery');
        self.rollQ:push(self.rollsByName['Fold']);
        return true;
    elseif (self.settings.randomdeal and self.recasts[196] and self.recasts[196] == 0) then
        self.message('Using Random Deal for bust recovery');
        self.rollQ:push(self.rollsByName['Random Deal']);
        return true;
    end
    
    -- If no abilities available, wait
    self.sleep();
    return true;
end

-- Determine which roll to do next
function RollingStrategy:determineNextRoll()
    -- Roll priority: Roll 1 first, then Roll 2 (unless sub-COR)
    local haveRoll1 = self.hasBuff(self.rolls[1].value);
    local haveRoll2 = self.hasBuff(self.rolls[2].value);
    

    
    -- Gamble Mode: Check if we should fold Roll 1 that's not 11
    if self.settings.gamble and haveRoll1 and self.mainjob == 17 then
        local currentRoll1 = self.rollsByName[self.rolls[1].value];
        if self.lastRoll ~= 11 and self.lastRoll > 0 then
            -- We have Roll 1 but it's not 11, consider folding to try again
            if self.hasFold and self.recasts[198] and self.recasts[198] == 0 then
                self.message('Gamble Mode: Folding Roll 1 (not 11) to try again');
                self.rollQ:push(self.rollsByName['Fold']);
                return true;
            elseif self.settings.randomdeal and self.recasts[196] and self.recasts[196] == 0 then
                self.message('Gamble Mode: Random Deal to reset and try for 11 again');
                self.rollQ:push(self.rollsByName['Random Deal']);
                return true;
            end
        end
    end
    
    if (not haveRoll1) then
        -- Roll 1 setup
        self.message('Setting up Roll 1: ' .. self.rolls[1].value);
        
        -- Use Crooked Cards on Roll 1 only if we're NOT saving it for Roll 2
        local level = AshitaCore:GetMemoryManager():GetPlayer():GetMainJobLevel();
        local crookedCD = self.recasts[96];
        
        if not self.settings.crooked2 and self.mainjob == 17 and level >= 95 and crookedCD and crookedCD == 0 then
            self.message('Using Crooked Cards for Roll 1');
            self.rollQ:push(self.rollsByName['Crooked Cards']);
        end
        
        self.rollQ:push(self.rollsByName[self.rolls[1].value]);
        

        
        return true;
        
    elseif (self.mainjob == 17 and not haveRoll2 and not self.hasBuff('Bust')) then
        -- Roll 2 only for main COR (sub-COR gets only one roll)
        

        
        self.message('Setting up Roll 2: ' .. self.rolls[2].value);
        
        if self.settings.crooked2 and AshitaCore:GetMemoryManager():GetPlayer():GetMainJobLevel() >= 95 and self.recasts[96] and self.recasts[96] == 0 then
            self.message('Using Crooked Cards for Roll 2');
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

    -- Handle bust recovery FIRST (highest priority)
    if self:handleBustRecovery() then
        return true;
    end

    -- Check phantom roll recast
    if self.recasts[193] and self.recasts[193] > 10 then
        self.sleep();
        return true;
    end

    -- Check if we already have both rolls 
    local haveRoll1 = self.hasBuff(self.rolls[1].value);
    local haveRoll2 = self.hasBuff(self.rolls[2].value);
    
    if haveRoll1 and (haveRoll2 or self.subjob == 17) then
        -- Nothing else to do - all rolls are up
        return false;
    end

    -- Reset lastRoll if we don't have any buffs
    if not haveRoll1 and not haveRoll2 then
        self.lastRoll = 0;
    end

    -- Party alert before rolling (only if we don't have any rolls)
    if self.settings.partyalert and not haveRoll1 and not haveRoll2 then
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
    -- Get fresh recast data for accurate cooldown checks
    self.recasts = getAbilityRecasts();
    
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
    
    -- Safe mode: use subjob-like strategy even on main COR
    if self.settings.safemode then
        if self.rollNum < 5 then
            return true, "Safe Mode: Roll < 5";
        end
        return false, "Safe Mode: Roll >= 5, stopping";
    end
    
    -- Main COR advanced strategy (from AshitaRoller)
    if self.mainjob == 17 then
        -- Gamble mode: aggressive strategy targeting 11s
        if self.settings.gamble then
            -- If we have bust immunity (last roll was 11), be very aggressive
            if self.lastRoll == 11 then
                if self.hasSnakeEye and self.recasts[197] and self.recasts[197] == 0 and self.rollNum == 10 then
                    return false, "Gamble: Snake Eye for guaranteed 11 while immune";
                else
                    return true, "Gamble: Bust immune, rolling aggressively for 11";
                end
            else
                -- No bust immunity - be more conservative but still target 11
                if self.hasSnakeEye and self.recasts[197] and self.recasts[197] == 0 and self.rollNum == 10 then
                    return false, "Gamble: Snake Eye for 11";
                elseif self.rollNum < 4 then
                    return true, "Gamble: Roll < 4, continuing to target 11";
                elseif self.rollNum < 7 and (self.hasFold and self.recasts[198] and self.recasts[198] == 0) then
                    return true, "Gamble: Have Fold safety net, continuing";
                else
                    return false, "Gamble: Stopping to avoid bust without safety";
                end
            end
        else
            -- Normal strategy - conservative approach
            
            -- PRIORITY 1: Use Snake Eye for 10 → 11 (highest priority)
            if self.hasSnakeEye and self.recasts[197] and self.recasts[197] == 0 and self.rollNum == 10 then
                return false, "Using Snake Eye for guaranteed 11 (highest priority)";
            end
            
            -- PRIORITY 2: Use Snake Eye for lucky-1 (second priority)
            if self.hasSnakeEye and self.recasts[197] and self.recasts[197] == 0 and self.rollNum == (luckyNum - 1) and self.rollCrooked then
                return false, "Using Snake Eye for lucky number (second priority)";
            end
            
            -- PRIORITY 3: Use Snake Eye for unlucky numbers (third priority)
            if self.hasSnakeEye and self.recasts[197] and self.recasts[197] == 0 and self.rollNum == unluckyNum then
                return false, "Using Snake Eye to avoid unlucky (third priority)";
            end
            
            -- Check if we're on an unlucky 8+ - handle differently
            if self.rollNum >= 8 then
                if self.rollNum == unluckyNum then
                    -- We're on an unlucky 8+ - try to Snake Eye off it
                    if self.hasSnakeEye and self.recasts[197] and self.recasts[197] == 0 then
                        return false, "Using Snake Eye to avoid unlucky " .. unluckyNum;
                    else
                        -- No Snake Eye available - sit on unlucky unless aggressive mode
                        if self.settings.gamble then
                            return true, "Aggressive: Rolling off unlucky " .. unluckyNum;
                        else
                            return false, "Stopping: Unlucky " .. unluckyNum .. " without Snake Eye";
                        end
                    end
                else
                    -- Not unlucky, just a good high roll
                    return false, "Stopping: " .. self.rollNum .. " is a good roll";
                end
            end
            
            -- Stop on 7 unless we have safety nets
            if self.rollNum == 7 then
                if self.hasFold and self.recasts[198] and self.recasts[198] == 0 and not self.rollCrooked then
                    return true, "Roll 7: Safe to risk with Fold available";
                else
                    return false, "Stopping: Roll 7 without safety";
                end
            end
            
            -- Continue on 6 only with safety or bust immunity
            if self.rollNum == 6 then
                if self.settings.bustimmunity and self.lastRoll == 11 then
                    return true, "Roll 6: Bust immune, continuing";
                elseif self.hasFold and self.recasts[198] and self.recasts[198] == 0 and not self.rollCrooked then
                    return true, "Roll 6: Safe to risk with Fold available";
                else
                    return false, "Stopping: Roll 6 without safety";
                end
            end
            
            -- Always continue on rolls < 6
            if self.rollNum < 6 then
                return true, "Roll < 6, continuing";
            end
            
            -- Fallback
            return false, "Stopping: conditions not met";
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
        self.message('Snake Eye buff detected, queueing Double-Up immediately');
        local doubleUpAction = self:createDoubleUpAction();
        self.rollQ:push(doubleUpAction);
        return true;
    end

    -- Advanced Snake Eye logic from AshitaRoller
    if self.recasts[197] and self.recasts[197] == 0 then
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
            elseif (not self.hasFold or not self.recasts[198] or self.recasts[198] > 0 or (self.rollCrooked and not self.settings.gamble)) and self.rollNum == unluckyNum then
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
        
        -- No fallback to Random Deal during active rolling
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

    -- Before any roll decisions, check if we should use Random Deal after roll completion
    -- This should happen once per roll, regardless of the result
    local function checkAndUseRandomDeal()
        if self.settings.randomdeal and self.recasts[196] and self.recasts[196] == 0 then
            local shouldUseRandomDeal = false;
            local resetReasons = {};
            
            -- Check abilities based on user-configured priority order
            for i, abilityName in ipairs(self.settings.randomDealPriority) do
                local isOnCooldown = false;
                local shouldCheck = true;
                
                if abilityName == 'Crooked Cards' then
                    -- Don't check Crooked Cards if disabled by toggle
                    shouldCheck = not self.settings.oldrandomdeal;
                    isOnCooldown = shouldCheck and self.recasts[96] and self.recasts[96] > 0;
                elseif abilityName == 'Snake Eye' then
                    isOnCooldown = self.hasSnakeEye and self.recasts[197] and self.recasts[197] > 0;
                elseif abilityName == 'Fold' then
                    isOnCooldown = self.hasFold and self.recasts[198] and self.recasts[198] > 0;
                end
                
                if shouldCheck and isOnCooldown then
                    table.insert(resetReasons, abilityName);
                    shouldUseRandomDeal = true;
                end
            end
            
            if shouldUseRandomDeal then
                local reason = table.concat(resetReasons, ', ');
                self.message('Using Random Deal to reset: ' .. reason);
                self.rollQ:push(self.rollsByName['Random Deal']);
                return true; -- Don't finish roll yet, let Random Deal execute
            end
        end
        return false;
    end

    -- If we hit 11 or lucky number, check Random Deal then finish
    if (self.rollNum == 11 or self.rollNum == self.rollsByName[self.currentRoll].lucky) then
        if checkAndUseRandomDeal() then
            return true; -- Random Deal queued, don't finish yet
        end
        finishRoll();
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
            -- Roll is ending without double-up, check Random Deal
            if checkAndUseRandomDeal() then
                return true; -- Random Deal queued, don't finish yet
            end
            
            -- If we decide not to double up, close the roll
            finishRoll();
        end
    end
    
    return true;
end

return RollingStrategy; 