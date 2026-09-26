local ns = _G.KeyStoneMasteryNS
if type(ns) ~= "table" then
    ns = {}
    _G.KeyStoneMasteryNS = ns
end

local RunState = {}
ns.RunState = RunState

local function RefreshMythicUIIfAvailable(ctx)
    if type(ctx) == "table" and type(ctx.RefreshMythicUI) == "function" then
        ctx.RefreshMythicUI()
    end
end

-- Long enough to loot, swap at the NPC, and leave the instance.
local KEYSTONE_ANNOUNCE_WINDOW_SECONDS = 900

local function GetUpgradeLevels(state)
    if not state or type(state.elapsedSeconds) ~= "number" or type(state.maxTimeSeconds) ~= "number" then
        return nil
    end

    if type(state.threeChestLimit) == "number" and state.elapsedSeconds <= state.threeChestLimit then
        return 3
    end

    if type(state.twoChestLimit) == "number" and state.elapsedSeconds <= state.twoChestLimit then
        return 2
    end

    if state.elapsedSeconds <= state.maxTimeSeconds then
        return 1
    end

    return 0
end

function RunState.ScheduleOwnedKeystoneObservation(ctx, allowAnnounce, delaySeconds)
    if not (C_Timer and C_Timer.After) then
        ctx.ObserveOwnedKeystone(allowAnnounce)
        return
    end

    local delay = type(delaySeconds) == "number" and ctx.max(0, delaySeconds) or 0
    C_Timer.After(delay, function()
        ctx.ObserveOwnedKeystone(allowAnnounce)
    end)
end

function RunState.GetActiveRunState(ctx)
    if not ctx.IsInMythicDungeonInstance() then
        return nil
    end

    if not ctx.IsChallengeModeRunActive() then
        return nil
    end

    local mapID
    if C_ChallengeMode and type(C_ChallengeMode.GetActiveChallengeMapID) == "function" then
        mapID = C_ChallengeMode.GetActiveChallengeMapID()
    end
    if type(mapID) ~= "number" or mapID <= 0 then
        mapID = ctx.GetOwnedKeystoneMapID()
    end
    local mapName = ctx.GetKeystoneMapName(mapID)
    local maxTimeSeconds = ctx.GetChallengeMapTimeLimit(mapID)
    local elapsedSeconds = ctx.GetWorldElapsedSeconds() or 0
    local level, affixIDs = ctx.GetActiveKeystoneDetails()
    local objectives, enemyForcesPercent = ctx.GetCriteriaState(mapID, mapName)
    local deathCount, deathPenalty = ctx.GetDeathState()
    local _, _, _, _, _, _, _, instanceMapID = GetInstanceInfo()

    if (not mapName or mapName == "") and instanceMapID then
        mapName = ctx.FormatDungeonLabel(instanceMapID)
    end

    if not mapName or mapName == "" then
        local instanceName = GetInstanceInfo()
        if type(instanceName) == "string" and instanceName ~= "" then
            mapName = instanceName
        end
    end

    local twoChestLimit, threeChestLimit = ctx.CalculateChestTimerLimits(maxTimeSeconds, affixIDs)

    return {
        mapID = mapID,
        mapName = mapName or "Unknown",
        level = level,
        affixIDs = affixIDs,
        affixSummary = ctx.GetAffixSummary(affixIDs),
        elapsedSeconds = elapsedSeconds,
        maxTimeSeconds = maxTimeSeconds,
        timeLeftSeconds = maxTimeSeconds and (maxTimeSeconds - elapsedSeconds) or nil,
        twoChestLimit = twoChestLimit,
        threeChestLimit = threeChestLimit,
        objectives = objectives,
        enemyForcesPercent = enemyForcesPercent,
        deathCount = deathCount,
        deathPenalty = deathPenalty,
    }
end

function RunState.CaptureCompletedRunState(ctx)
    local source = ctx.ui.lastRunState or RunState.GetActiveRunState(ctx)
    if not source then
        return
    end

    local completionMapID
    local completionLevel
    local completionTimeMs
    local completionOnTime
    local completionUpgradeLevels

    if C_ChallengeMode and C_ChallengeMode.GetCompletionInfo then
        local ok, mapChallengeModeID, level, time, onTime, keystoneUpgradeLevels = pcall(C_ChallengeMode.GetCompletionInfo)
        if ok then
            completionMapID = mapChallengeModeID
            completionLevel = level
            completionTimeMs = time
            completionOnTime = onTime
            completionUpgradeLevels = keystoneUpgradeLevels
        end
    end

    local completionElapsedSeconds = source.elapsedSeconds
    if type(completionTimeMs) == "number" and completionTimeMs > 0 then
        completionElapsedSeconds = completionTimeMs / 1000
    end

    local completionMaxTimeSeconds = source.maxTimeSeconds
    local completionTimeLeftSeconds = source.timeLeftSeconds
    if type(completionElapsedSeconds) == "number" and type(completionMaxTimeSeconds) == "number" then
        completionTimeLeftSeconds = completionMaxTimeSeconds - completionElapsedSeconds
    end

    local upgradeLevels = completionUpgradeLevels
    if type(upgradeLevels) ~= "number" then
        local upgradedSource = {
            elapsedSeconds = completionElapsedSeconds,
            maxTimeSeconds = completionMaxTimeSeconds,
            twoChestLimit = source.twoChestLimit,
            threeChestLimit = source.threeChestLimit,
        }
        upgradeLevels = GetUpgradeLevels(upgradedSource)
    elseif completionOnTime == false and upgradeLevels <= 0 then
        upgradeLevels = 0
    end

    local resultText
    if upgradeLevels == 3 then
        resultText = "Result: +3"
    elseif upgradeLevels == 2 then
        resultText = "Result: +2"
    elseif upgradeLevels == 1 then
        resultText = "Result: +1"
    elseif upgradeLevels == 0 then
        resultText = "Result: Depleted"
    else
        resultText = "Result: Completed"
    end

    ctx.ui.completedRun = {
        completedAt = GetTime(),
        mapID = completionMapID or source.mapID,
        mapName = ctx.GetKeystoneMapName(completionMapID) or source.mapName,
        level = completionLevel or source.level,
        affixSummary = source.affixSummary,
        elapsedSeconds = completionElapsedSeconds,
        maxTimeSeconds = completionMaxTimeSeconds,
        timeLeftSeconds = completionTimeLeftSeconds,
        twoChestLimit = source.twoChestLimit,
        threeChestLimit = source.threeChestLimit,
        deathCount = source.deathCount,
        deathPenalty = source.deathPenalty,
        deathLog = ctx.CopyDeathLog(ctx.ui.deathLog),
        resultText = resultText,
    }
end

function RunState.RefreshCompletedRunTimingFromAPI(ctx)
    if not (ctx.ui.completedRun and C_ChallengeMode and C_ChallengeMode.GetCompletionInfo) then
        return
    end

    local ok, _, _, completionTimeMs = pcall(C_ChallengeMode.GetCompletionInfo)
    if not ok or type(completionTimeMs) ~= "number" or completionTimeMs <= 0 then
        return
    end

    local elapsedSeconds = completionTimeMs / 1000
    ctx.ui.completedRun.elapsedSeconds = elapsedSeconds

    if type(ctx.ui.completedRun.maxTimeSeconds) == "number" then
        ctx.ui.completedRun.timeLeftSeconds = ctx.ui.completedRun.maxTimeSeconds - elapsedSeconds
    end

    RefreshMythicUIIfAvailable(ctx)
end

function RunState.HandleChallengeLifecycleEvent(ctx, event)
    if event == "CHALLENGE_MODE_START" then
        ctx.ui.inChallengeMode = true
        ctx.ui.lastScenarioElapsedSeconds = 0
        ctx.ui.completedRun = nil
        ctx.ui.lastRunState = nil
        ctx.ui.keystoneAnnounceUntil = nil
        ctx.ResetDeathLog()
        ctx.ResetEnemyForcesCalibration()
        ctx.ObserveOwnedKeystone(false)
        ctx.SyncGroupDeathLogFromUnits()
        RefreshMythicUIIfAvailable(ctx)
        return true
    end

    if event == "CHALLENGE_MODE_COMPLETED" then
        ctx.SyncGroupDeathLogFromUnits()
        RunState.CaptureCompletedRunState(ctx)
        ctx.ui.inChallengeMode = false
        ctx.ui.lastScenarioElapsedSeconds = nil
        ctx.ui.keystoneAnnounceUntil = GetTime() + KEYSTONE_ANNOUNCE_WINDOW_SECONDS
        RunState.ScheduleOwnedKeystoneObservation(ctx, true, 3)
        if C_Timer and C_Timer.After then
            C_Timer.After(2, function()
                RunState.RefreshCompletedRunTimingFromAPI(ctx)
            end)
        end
        RefreshMythicUIIfAvailable(ctx)
        return true
    end

    if event == "CHALLENGE_MODE_RESET" then
        ctx.ui.inChallengeMode = false
        ctx.ui.lastScenarioElapsedSeconds = nil
        ctx.ui.lastRunState = nil
        ctx.ui.completedRun = nil
        ctx.ResetDeathLog()
        ctx.ResetEnemyForcesCalibration()
        RunState.ScheduleOwnedKeystoneObservation(ctx, true, 1)
        RefreshMythicUIIfAvailable(ctx)
        return true
    end

    return false
end

function RunState.HandleGroupStateEvent(ctx, event)
    if event ~= "GROUP_ROSTER_UPDATE" and event ~= "UNIT_FLAGS" and event ~= "PLAYER_DEAD" then
        return false
    end

    ctx.SyncGroupDeathLogFromUnits()
    ctx.RefreshKSMWindowIfVisible()
    return true
end

function RunState.HandleRunRefreshEvent(ctx, event)
    if event ~= "PLAYER_ENTERING_WORLD"
        and event ~= "PLAYER_REGEN_ENABLED"
        and event ~= "SCENARIO_UPDATE"
        and event ~= "SCENARIO_CRITERIA_UPDATE" then
        return false
    end

    if event == "PLAYER_ENTERING_WORLD" then
        local _, instanceType, difficultyID = GetInstanceInfo()
        local inMythicInstance = instanceType == "party" and (difficultyID == 8 or difficultyID == 23)
        local elapsedSeconds = ctx.GetWorldElapsedSeconds and ctx.GetWorldElapsedSeconds() or nil
        local scenarioHasCriteria = false
        if C_Scenario and C_Scenario.GetStepInfo then
            local _, _, criteriaCount = C_Scenario.GetStepInfo()
            scenarioHasCriteria = type(criteriaCount) == "number" and criteriaCount > 0
        end
        local challengeApiActive = C_ChallengeMode and (
            (C_ChallengeMode.IsChallengeModeActive and C_ChallengeMode.IsChallengeModeActive())
            or (C_ChallengeMode.GetActiveChallengeMapID and type(C_ChallengeMode.GetActiveChallengeMapID()) == "number" and C_ChallengeMode.GetActiveChallengeMapID() > 0)
        )

        -- Zoning transitions can briefly report "not in mythic" while a run is active.
        -- Only clear state when there is no mythic instance context and no active
        -- challenge signal from APIs or world elapsed timer.
        if (not inMythicInstance)
            and (type(elapsedSeconds) ~= "number" or elapsedSeconds < 0)
            and not scenarioHasCriteria
            and not challengeApiActive then
            ctx.ui.completedRun = nil
            ctx.ui.lastRunState = nil
            ctx.ui.inChallengeMode = false
            ctx.ResetEnemyForcesCalibration()
        end
    end
    if event == "PLAYER_ENTERING_WORLD" then
        RunState.ScheduleOwnedKeystoneObservation(ctx, false, 1)
    end
    if event == "PLAYER_REGEN_ENABLED" then
        ctx.FlushDeferredChatMessages()
    end

    ctx.SyncGroupDeathLogFromUnits()
    RefreshMythicUIIfAvailable(ctx)
    ctx.RefreshKSMWindowIfVisible()
    return true
end
