-- Mocked client regression tests; no claim of reproducing the native taint engine.
local function check(value, message) if not value then error(message) end end
local function noop() end
local frames, timers = {}, {}
local combat = false
UIParent = {}
GameTooltip = setmetatable({}, { __index = function() error("Touched Blizzard's shared tooltip") end })
Enum = { BagIndex = { Backpack=0, Bag_1=1, Bag_2=2, Bag_3=3, Bag_4=4 } }
SlashCmdList = {}
C_Timer = { After = function(_, callback) timers[#timers+1] = callback end }
GetTime = function() return 100 end
InCombatLockdown = function() return combat end
local methods = {}
function methods:RegisterEvent(event)
    check(event ~= "COMBAT_LOG_EVENT_UNFILTERED", "Attempted restricted combat-log registration")
    self.events[event] = true
end
function methods:IsEventRegistered(event) return self.events[event] end
function methods:SetScript(name, fn) self.scripts[name] = fn end
function methods:Hide() self.shown = false end
function methods:Show() self.shown = true end
function methods:GetAlpha() return self.alpha end
function methods:SetAlpha(alpha) self.alpha = alpha end
function CreateFrame(kind, name, parent, template)
    local frame = setmetatable({ events={}, scripts={}, alpha=1, parent=parent, template=template }, { __index = function(_, key) return methods[key] or noop end })
    frames[#frames+1] = frame
    if name then _G[name] = frame end
    return frame
end

-- Load shipped modules in TOC order, using actual top-level event registration.
for line in io.lines("KeyStoneMastery.toc") do
    if line:match("%.lua$") then assert(loadfile(line))("KeyStoneMastery") end
end
local eventFrame
for _, frame in ipairs(frames) do
    if frame.events.PLAYER_LOGIN then eventFrame = frame end
end
check(eventFrame and eventFrame.events.ADDON_LOADED, "Bootstrap events missing")
check(eventFrame.events.PLAYER_DEAD and eventFrame.events.UNIT_FLAGS, "Unit death events missing")
check(eventFrame.events.CHAT_MSG_GUILD and eventFrame.events.CHAT_MSG_PARTY, "Registration stopped before chat events")
check(#timers == 0, "Startup should not schedule event registration retries")
local isolation = KeyStoneMasteryNS.UIIsolation
local tooltip = isolation.GetTooltip()
check(tooltip ~= GameTooltip and tooltip == isolation.GetTooltip(), "Tooltip must be private and reused")
check(tooltip.template == "GameTooltipTemplate", "Tooltip template missing")
tooltip:Show(); isolation.HideTooltip(); check(not tooltip.shown, "Private tooltip did not hide")
ObjectiveTrackerFrame = CreateFrame("Frame", nil, UIParent)
ObjectiveTrackerFrame.alpha = 0.7
local show = ObjectiveTrackerFrame.Show
check(isolation.SetTrackerSuppressed(true), "Tracker suppression failed")
check(ObjectiveTrackerFrame.alpha == 0, "Tracker remains visible")
check(ObjectiveTrackerFrame.parent == UIParent and ObjectiveTrackerFrame.Show == show, "Tracker parent/method changed")
ObjectiveTrackerFrame:Show()
check(ObjectiveTrackerFrame.alpha == 0, "Blizzard Show should not undo suppression")
combat = true
check(not isolation.SetTrackerSuppressed(false), "Changed tracker in combat")
check(ObjectiveTrackerFrame.alpha == 0, "Combat deferral lost suppression")
combat = false
check(isolation.SetTrackerSuppressed(false), "Tracker restoration failed")
check(ObjectiveTrackerFrame.alpha == 0.7, "Original alpha was not preserved")
local calls = 0
local ctx = { SyncGroupDeathLogFromUnits=function() calls=calls+1 end, RefreshKSMWindowIfVisible=noop }
for _, event in ipairs({"UNIT_FLAGS", "PLAYER_DEAD", "GROUP_ROSTER_UPDATE"}) do
    check(KeyStoneMasteryNS.RunState.HandleGroupStateEvent(ctx, event), "Death/group event not handled")
end
check(calls == 3, "Unit death tracking fallback was lost")
local function findUpvalue(fn, wanted, seen)
    seen = seen or {}
    if seen[fn] then return end
    seen[fn] = true
    for i = 1, 200 do
        local name, value = debug.getupvalue(fn, i)
        if not name then break end
        if name == wanted then return value end
        if type(value) == "function" then
            local found = findUpvalue(value, wanted, seen)
            if found then return found end
        end
    end
end
local buildContext = findUpvalue(eventFrame.scripts.OnEvent, "BuildRunStateContext")
check(buildContext, "Cannot reach runtime context")
local run = buildContext()
run.ui.inChallengeMode = true
run.ResetDeathLog()
local dead = false
local secret = {}
issecretvalue = function(value) return value == secret end
UnitExists = function(unit) return unit == "player" or unit == "party1" end
UnitGUID = function(unit) return unit == "player" and "Player-1" or secret end
UnitName = function() return "Alice", "TestRealm" end
UnitIsDeadOrGhost = function() return dead end
run.SyncGroupDeathLogFromUnits()
dead = true
run.SyncGroupDeathLogFromUnits()
run.SyncGroupDeathLogFromUnits()
check(run.ui.deathLog.Alice.count == 1, "Same death was counted more than once")
dead = false; run.SyncGroupDeathLogFromUnits()
dead = true; run.SyncGroupDeathLogFromUnits()
check(run.ui.deathLog.Alice.count == 2, "Death after resurrection was lost")
dead = secret; run.SyncGroupDeathLogFromUnits()
check(run.ui.deathLog.Alice.count == 2, "Restricted death state was counted")
dead = true; run.SyncGroupDeathLogFromUnits()
check(run.ui.deathLog.Alice.count == 2, "Restricted state was mistaken for resurrection")
print("PASS: full TOC startup, supported event registration, private tooltip, tracker isolation/restoration, unit death event routing")
