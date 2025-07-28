-- Rolling strategy module for J-Roller Enhanced
local getAbilityRecasts = require("getAbilityRecasts")

local RollingStrategy = {}

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
        -- Party alert timing
        partyAlertSent = false,
        partyAlertTime = 0
    };

    setmetatable(self, {__index = RollingStrategy})
    return self
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

    -- Reset party alert when we have rolls again
    local haveRoll1 = self.hasBuff(self.rolls[1].value);
    local haveRoll2 = self.hasBuff(self.rolls[2].value);

    -- Reset alert when moving to the next roll phase
    -- Only reset if we're not currently in a waiting period
    if haveRoll1 and not haveRoll2 and self.mainjob == 17 then
        -- Roll 1 is complete, prepare for Roll 2 alert (but only if not currently waiting)
        if not self.partyAlertSent then
            -- No alert sent yet, safe to reset for Roll 2
            self.partyAlertSent = false;
            self.partyAlertTime = 0;
        end
        -- Removed the problematic 8-second reset condition that was causing loops
    elseif haveRoll1 and haveRoll2 then
        -- Both rolls complete, reset for next rotation
        self.partyAlertSent = false;
        self.partyAlertTime = 0;
    end
    -- Note: Don't reset when no rolls are up - this could be during the waiting period
end

-- Check if we should do a new roll
function RollingStrategy:shouldDoNewRoll(enabled)
    -- Do not roll if disabled, or incapacitated
    if not enabled or self.isIncapacitated() then
        return false, "Disabled or incapacitated"
    end

    -- Do not roll while hidden
    if self.hasBuff("sneak") or self.hasBuff("invisible") then
        return false, "Hidden (sneak/invis)"
    end

    -- Don't roll if not COR
    if not (self.mainjob == 17 or self.subjob == 17) then
        return false, "Not COR"
    end

    -- Check engaged only setting
    if self.settings.engaged then
        local player = GetPlayerEntity()
        if not player or player.Status ~= 1 then -- 1 = engaged
            return false, "Not engaged"
        end
    end

    -- Check town mode setting
    if self.settings.townmode then
        local zone = AshitaCore:GetMemoryManager():GetParty():GetMemberZone(0);
        local zoneName = AshitaCore:GetResourceManager():GetString(
                             'zones.names', zone);
        local cities = require('cities');

        if cities[zoneName] then
            return false, "In town (Town mode enabled)"
        end
    end

    -- Handle 'once' mode - check if we have both rolls (or just one for sub-COR)
    if self.once then
        local haveRoll1 = self.hasBuff(self.rolls[1].value)
        local haveRoll2 = self.hasBuff(self.rolls[2].value)

        if self.subjob == 17 then
            -- Sub-COR only gets one roll
            if haveRoll1 then
                return false, "Once mode complete (Sub-COR)"
            end
        else
            -- Main COR gets both rolls
            if haveRoll1 and haveRoll2 then
                return false, "Once mode complete"
            end
        end
    end

    return true, "Ready to roll"
end

-- Handle bust recovery with available abilities
function RollingStrategy:handleBustRecovery()
    -- Only handle bust recovery if we actually have the Bust buff
    if not self.hasBuff("Bust") then return false end

    -- Priority: Fold first (removes bust), then Random Deal (instant recovery)
    if (self.hasFold and self.recasts[198] and self.recasts[198] == 0) then
        self.message('Using Fold for bust recovery');
        self.rollQ:push(self.rollsByName['Fold']);
        return true;
    elseif (self.settings.randomdeal and self.recasts[196] and self.recasts[196] ==
        0) then
        self.message('Using Random Deal for bust recovery');
        self.rollQ:push(self.rollsByName['Random Deal']);
        return true;
    end

    -- Check if we should allow Roll 2 when busted
    local haveRoll1 = self.hasBuff(self.rolls[1].value);
    local haveRoll2 = self.hasBuff(self.rolls[2].value);

    -- If rollwithbust is enabled, always allow proceeding to let the main logic decide
    -- The main logic will handle whether to do Roll 1 (if busted on Roll 2) or Roll 2 (if busted on Roll 1)
    if self.settings.rollwithbust and self.mainjob == 17 then
        self.message(
            'Bust Recovery: Allowing rolling for party benefit (rollwithbust enabled)');
        -- Don't block rolling - let the main logic handle which roll to do
        return false;
    end

    -- If rollwithbust disabled, wait for bust to wear off
    self.message(
        'Bust Recovery: rollwithbust disabled, waiting for bust to wear off');
    self.sleep();
    return true;
end

-- Determine which roll to do next
function RollingStrategy:determineNextRoll()
    -- Roll priority: Roll 1 first, then Roll 2 (unless sub-COR)
    local haveRoll1 = self.hasBuff(self.rolls[1].value);
    local haveRoll2 = self.hasBuff(self.rolls[2].value);

    -- Gamble Mode: Never fold completed rolls - only fold busts
    -- Gamble mode means: double up until 11 or bust, then recover from bust

    if not haveRoll1 then
        -- Check if we're busted and should skip to Roll 2
        -- When busted, Roll 1 slot has bust debuff instead of roll buff
        if self.hasBuff('Bust') and self.settings.rollwithbust and self.mainjob ==
            17 then
            -- We're busted on Roll 1, Roll 1 slot is occupied by bust debuff
            -- Skip to Roll 2 to give party that buff
            self.message(
                'Busted on Roll 1: Proceeding to Roll 2 for party benefit');
            -- Fall through to Roll 2 logic below
        else
            -- Normal Roll 1 setup
            self.message('Setting up Roll 1: ' .. self.rolls[1].value);

            -- Use Crooked Cards on Roll 1 only if we're NOT saving it for Roll 2
            local level = AshitaCore:GetMemoryManager():GetPlayer()
                              :GetMainJobLevel();
            local crookedCD = self.recasts[96];

            if not self.settings.crooked2 and self.mainjob == 17 and level >= 95 and
                crookedCD and crookedCD == 0 then
                self.message('Using Crooked Cards for Roll 1');
                self.rollQ:push(self.rollsByName['Crooked Cards']);
            end

            self.rollQ:push(self.rollsByName[self.rolls[1].value]);

            return true;
        end
    end

    if self.mainjob == 17 and not haveRoll2 then
        -- Roll 2 only for main COR (sub-COR gets only one roll)

        -- If busted, check setting and prioritize accordingly
        if self.hasBuff('Bust') then
            if self.settings.rollwithbust then
                -- Setting enabled: prioritize recovery if available, otherwise roll for party
                if self.hasFold and self.recasts[198] and self.recasts[198] == 0 then
                    self.message('Busted: Using Fold before Roll 2');
                    self.rollQ:push(self.rollsByName['Fold']);
                    return true;
                elseif self.settings.randomdeal and self.recasts[196] and
                    self.recasts[196] == 0 then
                    self.message('Busted: Using Random Deal before Roll 2');
                    self.rollQ:push(self.rollsByName['Random Deal']);
                    return true;
                else
                    -- No recovery available - still roll for party benefit
                    self.message(
                        'Setting up Roll 2 (busted but party benefits): ' ..
                            self.rolls[2].value);
                end
            else
                -- Setting disabled: always prioritize bust recovery over Roll 2
                if self.hasFold and self.recasts[198] and self.recasts[198] == 0 then
                    self.message(
                        'Busted: Using Fold (Roll 2 disabled while busted)');
                    self.rollQ:push(self.rollsByName['Fold']);
                    return true;
                elseif self.settings.randomdeal and self.recasts[196] and
                    self.recasts[196] == 0 then
                    self.message(
                        'Busted: Using Random Deal (Roll 2 disabled while busted)');
                    self.rollQ:push(self.rollsByName['Random Deal']);
                    return true;
                else
                    -- No recovery available and setting disabled - skip Roll 2
                    return false;
                end
            end
        else
            self.message('Setting up Roll 2: ' .. self.rolls[2].value);
        end

        if self.settings.crooked2 and
            AshitaCore:GetMemoryManager():GetPlayer():GetMainJobLevel() >= 95 and
            self.recasts[96] and self.recasts[96] == 0 then
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
    self.recasts = getAbilityRecasts()

    local canRoll, reason = self:shouldDoNewRoll(enabled)
    if not canRoll then
        if reason == "Once mode complete" or reason ==
            "Once mode complete (Sub-COR)" then
            self.message("Once mode: Roll complete")
            -- Note: once flag will be reset by main module
        end
        return false
    end

    -- Handle bust recovery FIRST (highest priority)
    if self:handleBustRecovery() then return true end

    -- Check phantom roll recast
    if self.recasts[193] and self.recasts[193] > 10 then
        self.sleep()
        return true
    end

    -- Check if we already have both rolls
    local haveRoll1 = self.hasBuff(self.rolls[1].value)
    local haveRoll2 = self.hasBuff(self.rolls[2].value)

    if haveRoll1 and (haveRoll2 or self.subjob == 17) then
        -- Nothing else to do - all rolls are up
        return false
    end

    -- Reset lastRoll if we don't have any buffs
    if not haveRoll1 and not haveRoll2 then self.lastRoll = 0; end

    -- Party alert system with proper timing - alert for each roll individually
    if self.settings.partyalert then
        local needAlert = false;
        local alertMessage = "";

        -- Check if we need to alert for Roll 1 or Roll 2
        if not haveRoll1 then
            needAlert = true;
            alertMessage = "Rolling Roll 1 (" .. self.rolls[1].value ..
                               ") in 8 seconds, stay close <call12>";
        elseif self.mainjob == 17 and not haveRoll2 then
            needAlert = true;
            alertMessage = "Rolling Roll 2 (" .. self.rolls[2].value ..
                               ") in 8 seconds, stay close <call12>";
        end

        if needAlert then
            local currentTime = os.time();

            -- Send alert only once when we first need to roll
            if not self.partyAlertSent then
                AshitaCore:GetChatManager():QueueCommand(-1,
                                                         "/p " .. alertMessage);
                self.partyAlertSent = true;
                self.partyAlertTime = currentTime;
                self.message(
                    "Party alert sent, waiting 8 seconds before rolling...");
                self.sleep();
                return true;
            end

            -- Check if 8 seconds have passed since alert
            if currentTime < self.partyAlertTime + 8 then
                -- Still waiting for the 8 seconds to pass
                self.sleep();
                return true;
            end

            -- 8 seconds have passed, we can now proceed with rolling
            -- Clear the alert flags so we don't send another alert
            self.partyAlertSent = false;
            self.partyAlertTime = 0;
        end
    end

    -- Determine which roll to do next
    if self:determineNextRoll() then
        return true
    else
        self.sleep()
        return true
    end
end

-- Advanced double-up logic from AshitaRoller
function RollingStrategy:shouldDoubleUp()
    -- Get fresh recast data for accurate cooldown checks
    self.recasts = getAbilityRecasts()

    local current = self.rollsByName[self.currentRoll]
    local rollID = current.param
    local luckyNum = current.lucky
    local unluckyNum = current.unlucky

    -- Sub-COR simplified strategy: double up if roll < 5
    if self.subjob == 17 then
        if self.rollNum < 5 then return true, "Sub-COR: Roll < 5" end
        return false, "Sub-COR: Roll >= 5, stopping"
    end

    -- Safe mode: use subjob-like strategy even on main COR
    if self.settings.safemode then
        if self.rollNum < 5 then return true, "Safe Mode: Roll < 5" end
        return false, "Safe Mode: Roll >= 5, stopping"
    end

    -- Main COR advanced strategy (from AshitaRoller)
    if self.mainjob == 17 then
        -- Gamble mode: aggressive strategy targeting 11s
        if self.settings.gamble then
            -- If we have bust immunity (last roll was 11), be extremely aggressive
            if self.lastRoll == 11 then
                -- Bust immune - only stop for Snake Eye on 10 for guaranteed 11
                if self.hasSnakeEye and self.recasts[197] and self.recasts[197] ==
                    0 and self.rollNum == 10 then
                    return false,
                           "Gamble: Snake Eye for guaranteed 11 while immune";
                else
                    -- Otherwise, keep rolling until 11 (can't bust)
                    return true,
                           "Gamble: Bust immune, rolling aggressively for 11";
                end
            else
                -- No bust immunity - still aggressive but use Snake Eye strategically
                if self.hasSnakeEye and self.recasts[197] and self.recasts[197] ==
                    0 and self.rollNum == 10 then
                    return false, "Gamble: Snake Eye for guaranteed 11";
                else
                    -- Keep doubling up until 11 or bust - fold will handle the bust
                    return true, "Gamble: Rolling for 11, fold will handle bust";
                end
            end
        else
            -- Normal strategy - conservative approach

            -- PRIORITY 1: Use Snake Eye for 10 → 11 (highest priority)
            if self.hasSnakeEye and self.recasts[197] and self.recasts[197] == 0 and
                self.rollNum == 10 then
                return false,
                       "Using Snake Eye for guaranteed 11 (highest priority)"
            end

            -- PRIORITY 2: Use Snake Eye for lucky-1 (second priority)
            if self.hasSnakeEye and self.recasts[197] and self.recasts[197] == 0 and
                self.rollNum == (luckyNum - 1) and self.rollCrooked then
                return false,
                       "Using Snake Eye for lucky number (second priority)"
            end

            -- PRIORITY 3: Use Snake Eye for unlucky numbers (third priority)
            if self.hasSnakeEye and self.recasts[197] and self.recasts[197] == 0 and
                self.rollNum == unluckyNum then
                return false,
                       "Using Snake Eye to avoid unlucky (third priority)"
            end

            -- Handle 8+ rolls differently
            if self.rollNum >= 8 then
                if self.rollNum == unluckyNum then
                    -- We're on an unlucky 8+ - try to Snake Eye off it
                    if self.hasSnakeEye and self.recasts[197] and
                        self.recasts[197] == 0 then
                        return false, "Using Snake Eye to avoid unlucky " ..
                                   unluckyNum;
                    else
                        -- No Snake Eye available - be more aggressive in gamble mode
                        if self.settings.gamble and
                            (self.hasFold and self.recasts[198] and
                                self.recasts[198] == 0) then
                            return true, "Gamble: Rolling off unlucky " ..
                                       unluckyNum .. " with Fold insurance";
                        else
                            return false, "Stopping: Unlucky " .. unluckyNum ..
                                       " without Snake Eye or Fold";
                        end
                    end
                else
                    -- Good 8+ roll - use Snake Eye if available for potential 9-11
                    if self.hasSnakeEye and self.recasts[197] and
                        self.recasts[197] == 0 and self.settings.gamble then
                        return false, "Gamble: Using Snake Eye to push " ..
                                   self.rollNum .. " higher";
                    else
                        -- Keep the good 8+ roll
                        return false, "Stopping: " .. self.rollNum ..
                                   " is a good roll";
                    end
                end
            end

            -- Roll 7: Use fold as insurance to risk for 8+
            if self.rollNum == 7 then
                if self.hasFold and self.recasts[198] and self.recasts[198] == 0 then
                    return true,
                           "Roll 7: Doubling up with Fold insurance for 8+";
                else
                    return false, "Stopping: Roll 7 without Fold insurance";
                end
            end

            -- Roll 6: Very aggressive - lowest bust risk of any 6+ roll
            if self.rollNum == 6 then
                if self.settings.bustimmunity and self.lastRoll == 11 then
                    return true, "Roll 6: Bust immune, definitely continuing";
                elseif self.hasFold and self.recasts[198] and self.recasts[198] ==
                    0 then
                    return true, "Roll 6: Low bust risk with Fold insurance";
                elseif self.hasSnakeEye then
                    return true,
                           "Roll 6: Low bust risk, Snake Eye available for optimization";
                elseif self.settings.randomdeal and self.recasts[196] and
                    self.recasts[196] == 0 then
                    return true, "Roll 6: Low bust risk with Random Deal backup";
                else
                    -- Even without safety nets, Roll 6 has good odds (6/11 safe outcomes)
                    return true,
                           "Roll 6: Aggressive (good odds even without safety nets)";
                end
            end

            -- Always continue on rolls < 6
            if self.rollNum < 6 then
                return true, "Roll < 6, continuing"
            end

            -- Fallback
            return false, "Stopping: conditions not met"
        end
    end

    return false, "Unknown job configuration"
end

-- Create a double-up action
function RollingStrategy:createDoubleUpAction()
    local current = self.rollsByName[self.currentRoll]
    local action = self.rollsByName["Double-Up"]:copy()
    action.param = current.param
    return action
end

-- Execute double-up strategy
function RollingStrategy:doubleUp()
    local shouldDouble, reason = self:shouldDoubleUp()
    if shouldDouble then
        local action = self:createDoubleUpAction()
        self.rollQ:push(action)
        return true
    end
    return false
end

-- Advanced Snake Eye logic
function RollingStrategy:executeSnakeEye(waiting)
    -- Skip Snake Eye logic for sub-COR
    if self.subjob == 17 or not self.hasSnakeEye then return false end

    local current = self.rollsByName[self.currentRoll]
    local snakeEyesActive = self.hasBuff("Snake Eye")
    local luckyNum = current.lucky
    local unluckyNum = current.unlucky

    if snakeEyesActive then
        self.message("Snake Eye buff detected, queueing Double-Up immediately")
        local doubleUpAction = self:createDoubleUpAction()
        self.rollQ:push(doubleUpAction)
        return true
    end

    -- Check if Snake Eye is available
    if self.recasts[197] and self.recasts[197] == 0 then
        -- Determine which roll we're currently working on
        local haveRoll1 = self.hasBuff(self.rolls[1].value);
        local workingOnRoll2 = haveRoll1 and self.currentRoll ==
                                   self.rolls[2].value;

        -- PRIORITY 1: Gamble mode - aggressive Snake Eye usage for 11s
        if self.settings.gamble then
            -- With bust immunity (last roll was 11), be very aggressive
            if self.lastRoll == 11 then
                if self.rollNum == 10 or
                    (self.rollNum == (luckyNum - 1) and self.rollCrooked) then
                    self.message(
                        'Gamble + Bust Immune: Snake Eye for guaranteed benefit');
                    self.rollQ:push(self.rollsByName['Snake Eye']);
                    local doubleUpAction = self:createDoubleUpAction();
                    self.rollQ:push(doubleUpAction);
                    return true;
                end
            else
                -- No bust immunity - still aggressive but strategic
                if self.rollNum == 10 then
                    self.message('Gamble: Snake Eye 10→11 for bust immunity');
                    self.rollQ:push(self.rollsByName['Snake Eye']);
                    local doubleUpAction = self:createDoubleUpAction();
                    self.rollQ:push(doubleUpAction);
                    return true;
                elseif self.rollNum == (luckyNum - 1) and self.rollCrooked then
                    self.message('Gamble: Snake Eye for lucky number');
                    self.rollQ:push(self.rollsByName['Snake Eye']);
                    local doubleUpAction = self:createDoubleUpAction();
                    self.rollQ:push(doubleUpAction);
                    return true;
                end
            end
        end

        -- PRIORITY 2: Standard Snake Eye usage (non-gamble)
        if not self.settings.gamble then
            if self.rollNum == 10 then
                self.message('Standard: Snake Eye 10→11');
                self.rollQ:push(self.rollsByName['Snake Eye']);
                local doubleUpAction = self:createDoubleUpAction();
                self.rollQ:push(doubleUpAction);
                return true;
            elseif self.rollNum == (luckyNum - 1) and self.rollCrooked then
                self.message('Standard: Snake Eye for lucky number');
                self.rollQ:push(self.rollsByName['Snake Eye']);
                local doubleUpAction = self:createDoubleUpAction();
                self.rollQ:push(doubleUpAction);
                return true;
            elseif self.rollNum == unluckyNum then
                self.message('Standard: Snake Eye to avoid unlucky');
                self.rollQ:push(self.rollsByName['Snake Eye']);
                local doubleUpAction = self:createDoubleUpAction();
                self.rollQ:push(doubleUpAction);
                return true;
            end
        end

        -- PRIORITY 3: Smart end-rotation optimization (ONLY for Roll 2)
        if self.settings.smartsnakeeye and workingOnRoll2 then
            -- Check if we're unlikely to double-up further (end of rotation)
            local wouldDoubleUp = self:shouldDoubleUp();

            if not wouldDoubleUp and self.rollNum >= 8 and self.rollNum < 10 then
                -- Calculate if Snake Eye will recharge before buffs expire
                local currentTime = os.time();
                local buffTimeRemaining = math.min(
                                              (self.roll1RollTime + 300) -
                                                  currentTime, -- Roll 1 expires in ~5 min
                                              (self.roll2RollTime + 300) -
                                                  currentTime -- Roll 2 expires in ~5 min
                );

                -- Snake Eye recharges in 60 seconds, give 60s buffer for next rotation
                local snakeEyeWillBeReady = buffTimeRemaining > 120; -- 60s recharge + 60s buffer

                if snakeEyeWillBeReady and (self.rollNum + 1) ~= unluckyNum then
                    self.message('Smart optimization (Roll 2): Snake Eye ' ..
                                     self.rollNum .. '→' .. (self.rollNum + 1) ..
                                     ' (will recharge in time)');
                    self.rollQ:push(self.rollsByName['Snake Eye']);
                    local doubleUpAction = self:createDoubleUpAction();
                    self.rollQ:push(doubleUpAction);
                    return true;
                end
            end
        end
    end

    return false;
end

-- Main rolling strategy when we have an active roll window
function RollingStrategy:executeRollStrategy(finishRoll)
    self.recasts = getAbilityRecasts()

    -- If we do not have an open window, do new roll
    if not self.rollWindow then
        return self:doNewRoll(true) -- enabled is handled in doNewRoll
    end

    -- Before any roll decisions, check if we should use Random Deal after roll completion
    -- This should happen once per roll, regardless of the result
    local function checkAndUseRandomDeal()
        if self.settings.randomdeal and self.recasts[196] and self.recasts[196] ==
            0 then
            local shouldUseRandomDeal = false
            local resetReasons = {}

            -- Check abilities based on user-configured priority order
            for i, abilityName in ipairs(self.settings.randomDealPriority) do
                local isOnCooldown = false
                local shouldCheck = true

                if abilityName == "Crooked Cards" then
                    -- Don't check Crooked Cards if disabled by toggle
                    shouldCheck = not self.settings.oldrandomdeal
                    isOnCooldown = shouldCheck and self.recasts[96] and
                                       self.recasts[96] > 0
                elseif abilityName == "Snake Eye" then
                    isOnCooldown = self.hasSnakeEye and self.recasts[197] and
                                       self.recasts[197] > 0
                elseif abilityName == "Fold" then
                    isOnCooldown = self.hasFold and self.recasts[198] and
                                       self.recasts[198] > 0
                end

                if shouldCheck and isOnCooldown then
                    table.insert(resetReasons, abilityName)
                    shouldUseRandomDeal = true
                end
            end

            if shouldUseRandomDeal then
                local reason = table.concat(resetReasons, ", ")
                self.message("Using Random Deal to reset: " .. reason)
                self.rollQ:push(self.rollsByName["Random Deal"])
                return true -- Don't finish roll yet, let Random Deal execute
            end
        end
        return false
    end

    -- If we hit 11 or lucky number, check Random Deal then finish
    if self.rollNum == 11 or self.rollNum ==
        self.rollsByName[self.currentRoll].lucky then
        if checkAndUseRandomDeal() then
            return true -- Random Deal queued, don't finish yet
        end
        finishRoll()
        return true
    end

    -- Try Snake Eye first
    local snakeEyeResult = self:executeSnakeEye(false) -- waiting will be managed by main module

    if snakeEyeResult == "wait" then
        -- waiting = true; -- will be set by main module
        return true
    end

    if not snakeEyeResult then
        if not self:doubleUp() then
            -- Roll is ending without double-up, check Random Deal
            if checkAndUseRandomDeal() then
                return true -- Random Deal queued, don't finish yet
            end

            -- If we decide not to double up, close the roll
            finishRoll()
        end
    end

    return true
end

return RollingStrategy
