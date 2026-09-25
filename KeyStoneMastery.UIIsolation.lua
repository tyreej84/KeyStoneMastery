local ns = _G.KeyStoneMasteryNS
local UIIsolation = {}
ns.UIIsolation = UIIsolation

local tooltip
function UIIsolation.GetTooltip()
    if not tooltip then
        -- Never reuse the world-map tooltip and its Blizzard widget container.
        tooltip = CreateFrame("GameTooltip", "KeyStoneMasteryTooltip", UIParent, "GameTooltipTemplate")
    end
    return tooltip
end

function UIIsolation.HideTooltip()
    if tooltip then tooltip:Hide() end
end

local suppressedTracker, originalAlpha
function UIIsolation.SetTrackerSuppressed(suppress)
    -- Changing the parent or replacing Show taints the tracker's update chain.
    -- Alpha hides it without running its layout/activation code from addon Lua.
    if InCombatLockdown and InCombatLockdown() then return false end
    local tracker = ObjectiveTrackerFrame
    if not tracker then return false end
    if suppressedTracker and (not suppress or suppressedTracker ~= tracker) then
        suppressedTracker:SetAlpha(originalAlpha)
        suppressedTracker, originalAlpha = nil, nil
    end
    if suppress and not suppressedTracker then
        originalAlpha = tracker:GetAlpha()
        suppressedTracker = tracker
        tracker:SetAlpha(0)
    end
    return true
end
