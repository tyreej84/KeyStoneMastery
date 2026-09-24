local ns = _G.KeyStoneMasteryNS
if type(ns) ~= "table" then
    ns = {}
    _G.KeyStoneMasteryNS = ns
end

local KSM = {}
ns.KSM = KSM

local function GetShortDisplayName(name)
    if type(name) ~= "string" or name == "" then
        return "Unknown"
    end

    return name:match("^([^-]+)") or name
end

local function ResolveBestKnownScore(tryScoreFn, ...)
    if type(tryScoreFn) ~= "function" then
        return nil
    end

    for i = 1, select("#", ...) do
        local identifier = select(i, ...)
        if identifier and identifier ~= "" then
            local score = tryScoreFn(identifier)
            if type(score) == "number" and score > 0 then
                return score
            end
        end
    end

    return nil
end

local ksmNameContextMenu = CreateFrame("Frame", "KeyStoneMasteryKSMNameContextMenu", UIParent, "UIDropDownMenuTemplate")

local function ShowNameContextMenu(menuItems)
    if type(menuItems) ~= "table" or #menuItems == 0 then
        return false
    end

    if type(EasyMenu) == "function" then
        local ok = pcall(EasyMenu, menuItems, ksmNameContextMenu, "cursor", 0, 0, "MENU")
        return ok == true
    end

    return false
end

function KSM.SetActiveTab(ctx, tabName)
    local ui = ctx.ui
    if not ui or not ui.ksmFrame then
        return
    end

    ui.ksmActiveTab = tabName or "main"

    local showMain = ui.ksmActiveTab == "main"
    local showParty = ui.ksmActiveTab == "party"
    local showGuild = ui.ksmActiveTab == "guild"
    local showRecents = ui.ksmActiveTab == "recents"
    local showWarband = ui.ksmActiveTab == "warband"

    if ui.ksmMainContent then if showMain then ui.ksmMainContent:Show() else ui.ksmMainContent:Hide() end end
    if ui.ksmPartyContent then if showParty then ui.ksmPartyContent:Show() else ui.ksmPartyContent:Hide() end end
    if ui.ksmGuildContent then if showGuild then ui.ksmGuildContent:Show() else ui.ksmGuildContent:Hide() end end
    if ui.ksmRecentsContent then if showRecents then ui.ksmRecentsContent:Show() else ui.ksmRecentsContent:Hide() end end
    if ui.ksmWarbandContent then if showWarband then ui.ksmWarbandContent:Show() else ui.ksmWarbandContent:Hide() end end

    if ui.ksmMainTab then
        ui.ksmMainTab.isSelected = showMain
        if ui.ksmMainTab.bg then
            ui.ksmMainTab.bg:SetColorTexture(showMain and 0.09 or 0.04, showMain and 0.09 or 0.04, showMain and 0.11 or 0.05, showMain and 0.96 or 0.85)
        end
        if ui.ksmMainTab.activeAccent then
            ui.ksmMainTab.activeAccent:SetColorTexture(0.24, 0.64, 1, showMain and 0.95 or 0)
        end
        local mainLabel = ui.ksmMainTab.label or (ui.ksmMainTab.GetFontString and ui.ksmMainTab:GetFontString())
        if mainLabel then
            mainLabel:SetTextColor(showMain and 1 or 0.8, showMain and 0.9 or 0.83, showMain and 0.68 or 0.86, 1)
        end
    end
    if ui.ksmPartyTab then
        ui.ksmPartyTab.isSelected = showParty
        if ui.ksmPartyTab.bg then
            ui.ksmPartyTab.bg:SetColorTexture(showParty and 0.09 or 0.04, showParty and 0.09 or 0.04, showParty and 0.11 or 0.05, showParty and 0.96 or 0.85)
        end
        if ui.ksmPartyTab.activeAccent then
            ui.ksmPartyTab.activeAccent:SetColorTexture(0.24, 0.64, 1, showParty and 0.95 or 0)
        end
        local partyLabel = ui.ksmPartyTab.label or (ui.ksmPartyTab.GetFontString and ui.ksmPartyTab:GetFontString())
        if partyLabel then
            partyLabel:SetTextColor(showParty and 1 or 0.8, showParty and 0.9 or 0.83, showParty and 0.68 or 0.86, 1)
        end
    end
    if ui.ksmGuildTab then
        ui.ksmGuildTab.isSelected = showGuild
        if ui.ksmGuildTab.bg then
            ui.ksmGuildTab.bg:SetColorTexture(showGuild and 0.09 or 0.04, showGuild and 0.09 or 0.04, showGuild and 0.11 or 0.05, showGuild and 0.96 or 0.85)
        end
        if ui.ksmGuildTab.activeAccent then
            ui.ksmGuildTab.activeAccent:SetColorTexture(0.24, 0.64, 1, showGuild and 0.95 or 0)
        end
        local guildLabel = ui.ksmGuildTab.label or (ui.ksmGuildTab.GetFontString and ui.ksmGuildTab:GetFontString())
        if guildLabel then
            guildLabel:SetTextColor(showGuild and 1 or 0.8, showGuild and 0.9 or 0.83, showGuild and 0.68 or 0.86, 1)
        end
    end
    if ui.ksmRecentsTab then
        ui.ksmRecentsTab.isSelected = showRecents
        if ui.ksmRecentsTab.bg then
            ui.ksmRecentsTab.bg:SetColorTexture(showRecents and 0.09 or 0.04, showRecents and 0.09 or 0.04, showRecents and 0.11 or 0.05, showRecents and 0.96 or 0.85)
        end
        if ui.ksmRecentsTab.activeAccent then
            ui.ksmRecentsTab.activeAccent:SetColorTexture(0.24, 0.64, 1, showRecents and 0.95 or 0)
        end
        local recentsLabel = ui.ksmRecentsTab.label or (ui.ksmRecentsTab.GetFontString and ui.ksmRecentsTab:GetFontString())
        if recentsLabel then
            recentsLabel:SetTextColor(showRecents and 1 or 0.8, showRecents and 0.9 or 0.83, showRecents and 0.68 or 0.86, 1)
        end
    end
    if ui.ksmWarbandTab then
        ui.ksmWarbandTab.isSelected = showWarband
        if ui.ksmWarbandTab.bg then
            ui.ksmWarbandTab.bg:SetColorTexture(showWarband and 0.09 or 0.04, showWarband and 0.09 or 0.04, showWarband and 0.11 or 0.05, showWarband and 0.96 or 0.85)
        end
        if ui.ksmWarbandTab.activeAccent then
            ui.ksmWarbandTab.activeAccent:SetColorTexture(0.24, 0.64, 1, showWarband and 0.95 or 0)
        end
        local warbandLabel = ui.ksmWarbandTab.label or (ui.ksmWarbandTab.GetFontString and ui.ksmWarbandTab:GetFontString())
        if warbandLabel then
            warbandLabel:SetTextColor(showWarband and 1 or 0.8, showWarband and 0.9 or 0.83, showWarband and 0.68 or 0.86, 1)
        end
    end
end

function KSM.RefreshMainTab(ctx)
    local ui = ctx.ui
    if not ui or not ui.ksmMainContent then
        return
    end

    local floor = ctx.floor
    local max = ctx.max
    local min = ctx.min
    local GetMythicPlusScore = ctx.GetMythicPlusScore
    local GetBestRunsFromHistory = ctx.GetBestRunsFromHistory
    local GetBestRunFromMapLookup = ctx.GetBestRunFromMapLookup
    local GetBestSeasonRunFromKnownMaps = ctx.GetBestSeasonRunFromKnownMaps
    local GetActiveKeystoneDetails = ctx.GetActiveKeystoneDetails
    local GetOwnedKeystoneSnapshot = ctx.GetOwnedKeystoneSnapshot
    local GetCurrentSeasonPortalEntries = ctx.GetCurrentSeasonPortalEntries
    local GetBestPortalRunForMap = ctx.GetBestPortalRunForMap
    local TrySetGreatVaultTexture = ctx.TrySetGreatVaultTexture
    local GetAffixDisplayInfo = ctx.GetAffixDisplayInfo
    local GetVaultProgressSummary = ctx.GetVaultProgressSummary
    local FormatBestRun = ctx.FormatBestRun
    local FormatBestRunNoScore = ctx.FormatBestRunNoScore
    local FormatDungeonLabel = ctx.FormatDungeonLabel
    local GetDungeonTileTexture = ctx.GetDungeonTileTexture
    local PrintLocal = ctx.PrintLocal
    local IsPortalSpellKnown = ctx.IsPortalSpellKnown
    local ConfigurePortalActionButton = ctx.ConfigurePortalActionButton

    local weeklyPanel = ui.ksmWeeklyPanel or ui.ksmMainContent
    local seasonPanel = ui.ksmSeasonPanel or ui.ksmMainContent

    local score = GetMythicPlusScore()
    local weekBest, seasonBest = GetBestRunsFromHistory()
    if not weekBest or not seasonBest then
        weekBest = weekBest or GetBestRunFromMapLookup("GetWeeklyBestForMap")
        seasonBest = seasonBest or GetBestRunFromMapLookup("GetSeasonBestForMap")
    end

    local mapSeasonBest = GetBestSeasonRunFromKnownMaps()
    if mapSeasonBest then
        local mapScore = tonumber(mapSeasonBest.score)
        local currentScore = seasonBest and tonumber(seasonBest.score)
        if not seasonBest
            or (mapScore and currentScore and mapScore > currentScore)
            or (mapScore and not currentScore)
            or ((not mapScore or not currentScore) and (mapSeasonBest.level or 0) > (seasonBest.level or 0))
        then
            seasonBest = mapSeasonBest
        end
    end

    local _, affixIDs = GetActiveKeystoneDetails()
    local keyMapID, keyLevel = GetOwnedKeystoneSnapshot()
    local portalEntries = GetCurrentSeasonPortalEntries()

    local function IsBetterSeasonCandidate(candidate, current)
        if not candidate then
            return false
        end
        if not current then
            return true
        end

        local candidateScore = tonumber(candidate.score)
        local currentScore = tonumber(current.score)
        if candidateScore and currentScore and candidateScore ~= currentScore then
            return candidateScore > currentScore
        end
        if candidateScore and not currentScore then
            return true
        end
        if currentScore and not candidateScore then
            return false
        end

        return (candidate.level or 0) > (current.level or 0)
    end

    local portalSeasonBest
    for _, entry in ipairs(portalEntries) do
        local bestForMap = GetBestPortalRunForMap(entry.mapID)
        if bestForMap and IsBetterSeasonCandidate(bestForMap, portalSeasonBest) then
            portalSeasonBest = bestForMap
        end
    end

    if IsBetterSeasonCandidate(portalSeasonBest, seasonBest) then
        seasonBest = portalSeasonBest
    end

    if ui.ksmRatingLine then ui.ksmRatingLine:Hide() end
    if ui.ksmBestLine then ui.ksmBestLine:Hide() end
    if ui.ksmAffixLine then ui.ksmAffixLine:Hide() end
    if ui.ksmKeyLine then ui.ksmKeyLine:Hide() end
    if ui.ksmVaultLine then ui.ksmVaultLine:Hide() end
    if ui.ksmPortalsLabel then ui.ksmPortalsLabel:Hide() end

    if not ui.ksmSeasonHeader then
        ui.ksmSeasonHeader = weeklyPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        ui.ksmSeasonHeader:SetPoint("TOP", weeklyPanel, "TOP", 0, -10)
        ui.ksmSeasonHeader:SetTextColor(1.0, 0.84, 0.15, 1)
        ui.ksmSeasonHeader:SetText("Mythic+ Dungeons")
        ui.ksmSeasonHeader:SetFontObject("GameFontHighlight")
    end

    if not ui.ksmWeekHeader then
        ui.ksmWeekHeader = weeklyPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        ui.ksmWeekHeader:SetPoint("TOP", weeklyPanel, "TOP", 0, -26)
        ui.ksmWeekHeader:SetTextColor(1, 1, 1, 1)
        ui.ksmWeekHeader:SetText("This Week")
        ui.ksmWeekHeader:SetFontObject("GameFontHighlightLarge")
    end

    if not ui.ksmVaultPrompt then
        ui.ksmVaultPrompt = weeklyPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        ui.ksmVaultPrompt:SetTextColor(1.0, 0.8, 0.1, 1)
        ui.ksmVaultPrompt:SetText("Complete Mythic+ dungeons to earn:")
    end
    ui.ksmVaultPrompt:ClearAllPoints()
    ui.ksmVaultPrompt:SetPoint("TOP", weeklyPanel, "TOP", 0, -92)

    if not ui.ksmAffixButtons then
        ui.ksmAffixButtons = {}
    end

    local affixCount = type(affixIDs) == "table" and #affixIDs or 0
    local affixSize = 42
    local affixGap = 12
    local affixStartX = -(((affixCount * affixSize) + ((max(affixCount - 1, 0)) * affixGap)) / 2)

    for index = 1, affixCount do
        local affixID = affixIDs[index]
        local button = ui.ksmAffixButtons[index]
        if not button then
            button = CreateFrame("Button", nil, weeklyPanel)
            button:SetSize(affixSize, affixSize)

            local bg = button:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints(button)
            bg:SetColorTexture(0.02, 0.02, 0.02, 0.9)

            local icon = button:CreateTexture(nil, "ARTWORK")
            icon:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
            icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
            button.icon = icon

            local border = button:CreateTexture(nil, "OVERLAY")
            border:SetAllPoints(button)
            border:SetColorTexture(1, 1, 1, 0.2)

            button:SetScript("OnEnter", function(self)
                if not self.affixID then
                    return
                end

                local name, description = GetAffixDisplayInfo(self.affixID)
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:ClearLines()
                GameTooltip:AddLine(name or string.format("Affix %d", self.affixID), 1, 1, 1)
                if type(description) == "string" and description ~= "" then
                    GameTooltip:AddLine(description, 0.85, 0.85, 0.85, true)
                end
                GameTooltip:Show()
            end)
            button:SetScript("OnLeave", GameTooltip_Hide)

            ui.ksmAffixButtons[index] = button
        end

        local _, _, affixTexture = GetAffixDisplayInfo(affixID)
        button.icon:SetTexture(affixTexture or "Interface\\Icons\\INV_Misc_QuestionMark")
        button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        button.affixID = affixID
        button:ClearAllPoints()
        button:SetPoint("TOP", weeklyPanel, "TOP", affixStartX + ((index - 1) * (affixSize + affixGap)) + (affixSize / 2), -46)
        button:Show()
    end

    for index = affixCount + 1, #ui.ksmAffixButtons do
        ui.ksmAffixButtons[index]:Hide()
    end

    if ui.ksmVaultButton then
        if ui.ksmVaultButton.plate then
            local usingCustomVaultArt = TrySetGreatVaultTexture(ui.ksmVaultButton.plate)
            if ui.ksmVaultButton.lock then
                local _ = usingCustomVaultArt
                ui.ksmVaultButton.lock:Hide()
            end
        end
    end

    if not ui.ksmRatingText then
        ui.ksmRatingText = weeklyPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
        ui.ksmRatingText:SetTextColor(1.0, 0.72, 0.2, 1)
    end
    ui.ksmRatingText:ClearAllPoints()
    ui.ksmRatingText:SetPoint("TOP", ui.ksmVaultButton or weeklyPanel, "BOTTOM", 0, -24)
    ui.ksmRatingText:SetJustifyH("CENTER")
    ui.ksmRatingText:SetText(score and tostring(floor(score + 0.5)) or "—")

    if not ui.ksmRatingLabel then
        ui.ksmRatingLabel = weeklyPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        ui.ksmRatingLabel:SetTextColor(1, 1, 1, 0.95)
        ui.ksmRatingLabel:SetText("Mythic+ Rating")
        ui.ksmRatingLabel:SetFontObject("GameFontHighlight")
    end
    ui.ksmRatingLabel:ClearAllPoints()
    ui.ksmRatingLabel:SetPoint("BOTTOM", ui.ksmRatingText, "TOP", 0, 6)
    ui.ksmRatingLabel:SetJustifyH("CENTER")

    if not ui.ksmRecordsBox then
        local recordsBox = CreateFrame("Frame", nil, weeklyPanel, BackdropTemplateMixin and "BackdropTemplate")
        recordsBox:SetSize(236, 106)
        recordsBox:SetPoint("BOTTOMLEFT", weeklyPanel, "BOTTOMLEFT", 12, 12)

        local recordsTitle = recordsBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        recordsTitle:SetPoint("TOPLEFT", recordsBox, "TOPLEFT", 8, -8)
        recordsTitle:SetTextColor(1.0, 0.82, 0.22, 1)
        recordsTitle:SetText("Records")

        local keyLine = recordsBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        keyLine:SetPoint("TOPLEFT", recordsTitle, "BOTTOMLEFT", 0, -6)
        keyLine:SetJustifyH("LEFT")
        keyLine:SetTextColor(0.86, 0.9, 0.95, 1)

        local vaultLine = recordsBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        vaultLine:SetPoint("TOPLEFT", keyLine, "BOTTOMLEFT", 0, -4)
        vaultLine:SetJustifyH("LEFT")
        vaultLine:SetTextColor(0.86, 0.9, 0.95, 1)

        local weekLine = recordsBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        weekLine:SetPoint("TOPLEFT", vaultLine, "BOTTOMLEFT", 0, -4)
        weekLine:SetJustifyH("LEFT")
        weekLine:SetTextColor(0.86, 0.9, 0.95, 1)

        local seasonLine = recordsBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        seasonLine:SetPoint("TOPLEFT", weekLine, "BOTTOMLEFT", 0, -4)
        seasonLine:SetJustifyH("LEFT")
        seasonLine:SetTextColor(0.86, 0.9, 0.95, 1)

        ui.ksmRecordsBox = recordsBox
        ui.ksmRecordsKeyLine = keyLine
        ui.ksmRecordsVaultLine = vaultLine
        ui.ksmRecordsWeekLine = weekLine
        ui.ksmRecordsSeasonLine = seasonLine
    end

    if ui.ksmRecordsKeyLine then
        ui.ksmRecordsKeyLine:SetText(keyLevel and string.format("Keystone: +%d %s", keyLevel, FormatDungeonLabel(keyMapID)) or "Keystone: Unavailable")
    end
    if ui.ksmRecordsVaultLine then
        ui.ksmRecordsVaultLine:SetText(GetVaultProgressSummary())
    end
    if ui.ksmRecordsWeekLine then
        ui.ksmRecordsWeekLine:SetText(string.format("Weekly Best: %s", FormatBestRun(weekBest)))
    end
    if ui.ksmRecordsSeasonLine then
        ui.ksmRecordsSeasonLine:SetText(string.format("Season Best: %s", FormatBestRunNoScore(seasonBest)))
    end

    if not ui.ksmPortalLabel then
        ui.ksmPortalLabel = seasonPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        ui.ksmPortalLabel:SetPoint("TOP", seasonPanel, "TOP", 0, -10)
        ui.ksmPortalLabel:SetTextColor(1, 1, 1, 1)
        ui.ksmPortalLabel:SetText("Season Portals")
        ui.ksmPortalLabel:SetFontObject("GameFontHighlight")
    end

    local entries = portalEntries
    local bestForMapCache = {}
    local function GetBestForMapCached(mapID)
        if bestForMapCache[mapID] == nil then
            bestForMapCache[mapID] = GetBestPortalRunForMap(mapID) or false
        end
        return bestForMapCache[mapID] ~= false and bestForMapCache[mapID] or nil
    end

    table.sort(entries, function(left, right)
        local leftBest = GetBestForMapCached(left.mapID)
        local rightBest = GetBestForMapCached(right.mapID)
        local leftScore = leftBest and tonumber(leftBest.score) or nil
        local rightScore = rightBest and tonumber(rightBest.score) or nil

        if leftScore and rightScore and leftScore ~= rightScore then
            return leftScore > rightScore
        end
        if leftScore and not rightScore then
            return true
        end
        if rightScore and not leftScore then
            return false
        end

        local leftLevel = leftBest and tonumber(leftBest.level) or 0
        local rightLevel = rightBest and tonumber(rightBest.level) or 0
        if leftLevel ~= rightLevel then
            return leftLevel > rightLevel
        end

        return (left.mapName or "") < (right.mapName or "")
    end)

    local maxTiles = min(#entries, 8)
    local tileWidth = 60
    local tileHeight = 52
    local tileGap = 4

    if ui.ksmPortalLabel then
        ui.ksmPortalLabel:SetText(maxTiles > 0 and "Season Portals" or "Season Portals (No Data)")
    end

    for index = 1, maxTiles do
        local entry = entries[index]
        local button = ui.ksmPortalButtons[index]
        if not button then
            button = CreateFrame("Button", nil, seasonPanel, "SecureActionButtonTemplate")
            button:SetSize(tileWidth, tileHeight)
            button:RegisterForClicks("AnyUp", "AnyDown")

            local icon = button:CreateTexture(nil, "ARTWORK")
            icon:SetAllPoints(button)
            button.icon = icon

            local dim = button:CreateTexture(nil, "OVERLAY")
            dim:SetAllPoints(button)
            dim:SetColorTexture(0, 0, 0, 0.12)
            button.dim = dim

            local levelText = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            levelText:SetPoint("TOPLEFT", button, "TOPLEFT", 4, -3)
            levelText:SetTextColor(1.0, 0.72, 0.2, 1)
            button.levelText = levelText

            button:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:ClearLines()
                GameTooltip:AddLine(self.mapName or "Dungeon", 1, 1, 1)
                if self.bestLevel then
                    GameTooltip:AddLine(string.format("Season Best: +%d", self.bestLevel), 1, 0.82, 0.2)
                else
                    GameTooltip:AddLine("Season Best: None", 0.8, 0.8, 0.8)
                end
                if self.bestScore then
                    GameTooltip:AddLine(string.format("Dungeon Score: %d", floor(self.bestScore + 0.5)), 0.8, 0.95, 1)
                end
                if not self.spellID then
                    GameTooltip:AddLine("Portal spell not configured", 0.85, 0.3, 0.3)
                else
                    GameTooltip:AddLine(self.known and "Click to cast portal" or "Portal locked", self.known and 0.5 or 0.8, self.known and 1 or 0.2, self.known and 0.5 or 0.2)
                end
                GameTooltip:Show()
            end)
            button:SetScript("OnLeave", GameTooltip_Hide)

            ui.ksmPortalButtons[index] = button
        end

        local bestForMap = GetBestForMapCached(entry.mapID)
        button.bestLevel = bestForMap and bestForMap.level or nil
        button.bestScore = bestForMap and bestForMap.score or nil
        button.overallScore = score
        button.spellID = entry.spellID
        button.mapName = entry.mapName
        button.known = ConfigurePortalActionButton and ConfigurePortalActionButton(button, entry.spellID) or entry.known

        local iconTexture, isSpellIcon = GetDungeonTileTexture(entry.mapID, entry.spellID)
        button.icon:SetTexture(iconTexture)
        if isSpellIcon then
            button.icon:SetTexCoord(0, 1, 0, 1)
        else
            button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        end
        button.levelText:SetText(bestForMap and tostring(bestForMap.level) or "-")
        if button.known then button.dim:Hide() else button.dim:Show() end

        local totalWidth = (maxTiles * tileWidth) + (max(0, maxTiles - 1) * tileGap)
        local rowStartX = -(totalWidth / 2)
        local rowY = -48

        button:ClearAllPoints()
        button:SetPoint("TOP", seasonPanel, "TOP", rowStartX + ((index - 1) * (tileWidth + tileGap)) + (tileWidth / 2), rowY)
        button:Show()
    end

    for index = maxTiles + 1, #ui.ksmPortalButtons do
        ui.ksmPortalButtons[index]:Hide()
    end
end

function KSM.RefreshPartyTab(ctx)
    local ui = ctx.ui
    if not ui or not ui.ksmPartyContent then
        return
    end

    local floor = ctx.floor
    local GetOwnedKeystoneSnapshot = ctx.GetOwnedKeystoneSnapshot
    local GetPlayerClassFile = ctx.GetPlayerClassFile
    local GetGuildMemberData = ctx.GetGuildMemberData
    local GetOwnCharacterStore = ctx.GetOwnCharacterStore
    local GetNormalizedPlayerName = ctx.GetNormalizedPlayerName
    local TryGetUnitMythicScore = ctx.TryGetUnitMythicScore
    local TryGetMythicScoreForIdentifier = ctx.TryGetMythicScoreForIdentifier
    local GetPortalSpellIDForMap = ctx.GetPortalSpellIDForMap
    local EnsureKSMDataLine = ctx.EnsureKSMDataLine
    local EnsureKSMPartyRow = ctx.EnsureKSMPartyRow
    local GetClassColorInfo = ctx.GetClassColorInfo
    local ApplyClassIcon = ctx.ApplyClassIcon
    local GetDungeonTileTexture = ctx.GetDungeonTileTexture
    local FormatDungeonLabel = ctx.FormatDungeonLabel
    local ConfigurePortalActionButton = ctx.ConfigurePortalActionButton

    local function BuildNameAliases(rawName)
        local aliases = {}
        local seen = {}

        local function AddAlias(value)
            if type(value) == "string" and value ~= "" and not seen[value] then
                seen[value] = true
                table.insert(aliases, value)
            end
        end

        AddAlias(rawName)
        AddAlias(GetNormalizedPlayerName and GetNormalizedPlayerName(rawName) or nil)

        return aliases
    end

    local ownByAlias = {}
    local ownStore = type(GetOwnCharacterStore) == "function" and GetOwnCharacterStore() or nil
    if type(ownStore) == "table" then
        for ownName, ownCache in pairs(ownStore) do
            if type(ownName) == "string" and type(ownCache) == "table" then
                for _, alias in ipairs(BuildNameAliases(ownName)) do
                    ownByAlias[alias] = ownCache
                end
            end
        end
    end

    local function FindOwnEntryByAnyAlias(name)
        for _, alias in ipairs(BuildNameAliases(name)) do
            local ownEntry = ownByAlias[alias]
            if ownEntry then
                return ownEntry
            end
        end
        return nil
    end

    local function ResolvePartyCache(fullName, shortName)
        local cache = GetGuildMemberData(fullName)
        if not cache then
            cache = GetGuildMemberData(shortName)
        end
        if cache then
            return cache
        end

        cache = FindOwnEntryByAnyAlias(fullName)
        if cache then
            return cache
        end

        return FindOwnEntryByAnyAlias(shortName)
    end

    local entries = {}
    local units = { "player", "party1", "party2", "party3", "party4" }
    for _, unitToken in ipairs(units) do
        if UnitExists(unitToken) then
            local name, realm = UnitName(unitToken)
            name = name or "Unknown"
            local fullName = name
            if type(realm) == "string" and realm ~= "" then
                fullName = string.format("%s-%s", name, realm)
            end
            local mapID, keyLevel
            local classFile = GetPlayerClassFile(unitToken)

            if unitToken == "player" then
                mapID, keyLevel = GetOwnedKeystoneSnapshot()
            else
                local cache = ResolvePartyCache(fullName, name)
                mapID = cache and tonumber(cache.mapID) or 0
                keyLevel = cache and tonumber(cache.keyLevel) or 0
                if cache and cache.class then
                    classFile = cache.class
                end
            end

            local score = TryGetUnitMythicScore(unitToken)
            if (not score or score <= 0) and unitToken ~= "player" then
                local cache = ResolvePartyCache(fullName, name)
                score = cache and tonumber(cache.rating) or nil
                if not score or score <= 0 then
                    score = ResolveBestKnownScore(TryGetMythicScoreForIdentifier, fullName, name)
                end
            end

            mapID = tonumber(mapID) or 0
            keyLevel = tonumber(keyLevel) or 0

            table.insert(entries, {
                unitToken = unitToken,
                name = name,
                classFile = classFile,
                mapID = mapID,
                keyLevel = keyLevel,
                score = score and floor(score + 0.5) or 0,
                spellID = GetPortalSpellIDForMap(mapID),
            })
        end
    end

    if #entries == 0 then
        local line = EnsureKSMDataLine(ui.ksmPartyLines, ui.ksmPartyContent, 1)
        line:SetWidth(570)
        line:SetPoint("TOPLEFT", ui.ksmPartyContent, "TOPLEFT", 10, -48)
        line:SetText("No party members found")
        line:Show()
        for index = 1, #ui.ksmPartyRows do
            ui.ksmPartyRows[index]:Hide()
        end
        return
    end

    for index = 1, #ui.ksmPartyLines do
        ui.ksmPartyLines[index]:Hide()
    end

    local y = -42
    for index, entry in ipairs(entries) do
        local row = EnsureKSMPartyRow(index)
        local r, g, b = GetClassColorInfo(entry.classFile)

        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", ui.ksmPartyContent, "TOPLEFT", 10, y)
        row.nameText:SetText(GetShortDisplayName(entry.name))
        row.nameText:SetTextColor(r, g, b, 1)

        if SetPortraitTexture and UnitExists(entry.unitToken) then
            SetPortraitTexture(row.portrait, entry.unitToken)
            row.portrait:SetTexCoord(0, 1, 0, 1)
        else
            ApplyClassIcon(row.portrait, entry.classFile)
        end

        local iconTexture = "Interface\\Icons\\INV_Misc_QuestionMark"
        local useSpellCoords = false
        if entry.mapID > 0 then
            local tileTexture, fromSpellIcon = GetDungeonTileTexture(entry.mapID, entry.spellID)
            if tileTexture then
                iconTexture = tileTexture
                useSpellCoords = fromSpellIcon and true or false
            end
        end

        row.keyTile.icon:SetTexture(iconTexture)
        row.keyTile.icon:SetTexCoord(useSpellCoords and 0.08 or 0.06, useSpellCoords and 0.92 or 0.94, useSpellCoords and 0.08 or 0.06, useSpellCoords and 0.92 or 0.94)
        row.keyTile.levelText:SetText(entry.keyLevel > 0 and string.format("+%d", entry.keyLevel) or "")
        row.scoreText:SetText(entry.score > 0 and string.format("M+ %d", entry.score) or "M+ -")
        row.dungeonText:SetText(entry.mapID > 0 and FormatDungeonLabel(entry.mapID) or "No key data")

        row.keyTile.mapID = entry.mapID
        row.keyTile.keyLevel = entry.keyLevel
        row.keyTile.spellID = entry.spellID
        if ConfigurePortalActionButton then
            ConfigurePortalActionButton(row.keyTile, entry.spellID)
        end
        row.keyTile.dungeonLabel = entry.mapID > 0 and FormatDungeonLabel(entry.mapID) or "No key"
        row.keyTile:SetAlpha(entry.keyLevel > 0 and 1 or 0.55)
        if row.cardBG then
            row.cardBG:SetColorTexture(0.02, 0.03, 0.04, entry.keyLevel > 0 and 0.44 or 0.3)
        end

        row:Show()
        y = y - 68
    end

    for index = #entries + 1, #ui.ksmPartyRows do
        ui.ksmPartyRows[index]:Hide()
    end
end

function KSM.RefreshGuildTab(ctx)
    local ui = ctx.ui
    if not ui or not ui.ksmGuildContent then
        return
    end

    local floor = ctx.floor
    local max = ctx.max
    local min = ctx.min
    local IsPlayerInGuildSafe = ctx.IsPlayerInGuildSafe
    local EnsureKSMGuildRow = ctx.EnsureKSMGuildRow
    local RequestGuildRosterSafe = ctx.RequestGuildRosterSafe
    local RequestGuildKeysFromAllSources = ctx.RequestGuildKeysFromAllSources
    local GetNormalizedPlayerName = ctx.GetNormalizedPlayerName
    local GetOwnCharacterStore = ctx.GetOwnCharacterStore
    local GetMythicPlusScore = ctx.GetMythicPlusScore
    local GetOwnedKeystoneSnapshot = ctx.GetOwnedKeystoneSnapshot
    local GetPlayerClassFile = ctx.GetPlayerClassFile
    local GetNumGuildMembersSafe = ctx.GetNumGuildMembersSafe
    local GetGuildMemberData = ctx.GetGuildMemberData
    local TryGetMythicScoreForIdentifier = ctx.TryGetMythicScoreForIdentifier
    local TryGetUnitMythicScore = ctx.TryGetUnitMythicScore
    local IsGuildMemberRecent = ctx.IsGuildMemberRecent
    local GetPortalSpellIDForMap = ctx.GetPortalSpellIDForMap
    local GetClassColorInfo = ctx.GetClassColorInfo
    local ApplyClassIcon = ctx.ApplyClassIcon
    local FormatDungeonLabel = ctx.FormatDungeonLabel
    local IsPortalSpellKnown = ctx.IsPortalSpellKnown
    local ConfigurePortalActionButton = ctx.ConfigurePortalActionButton
    local InvitePlayerByName = ctx.InvitePlayerByName

    local function IsGuildOnlineValue(value)
        if value == true then
            return true
        end

        if type(value) == "string" then
            local normalized = strtrim(strlower(value))
            if normalized == "true" or normalized == "online" then
                return true
            end
        end

        local numeric = tonumber(value)
        return numeric == 1
    end

    local function IsGuildStatusOnline(statusText)
        if type(statusText) == "number" then
            -- Non-zero status values (AFK/DND/mobile variants) still indicate an online member.
            return statusText ~= 0
        end

        if type(statusText) ~= "string" then
            return false
        end

        local normalized = strtrim(statusText)
        return normalized ~= ""
    end

    if ui.ksmGuildHideOfflineCheck then
        ui.ksmGuildHideOfflineCheck:SetChecked(ui.ksmHideOffline == true)
    end

    local inGuild = IsPlayerInGuildSafe()
    if not inGuild then
        local row = EnsureKSMGuildRow(1)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", ui.ksmGuildContent, "TOPLEFT", 10, -52)
        row.classIcon:Hide()
        row.nameText:SetText("You are not in a guild")
        row.nameText:SetTextColor(1, 1, 1, 1)
        row.keyText:SetText("")
        row.dungeonText:SetText("")
        row.ratingText:SetText("")
        row.teleportButton:Hide()
        row:Show()

        for index = 2, #ui.ksmGuildRows do
            ui.ksmGuildRows[index]:Hide()
        end
        for index = 1, #ui.ksmGuildLines do
            ui.ksmGuildLines[index]:Hide()
        end
        return
    end

    RequestGuildRosterSafe()
    RequestGuildKeysFromAllSources(false)

    local entries = {}
    local entryByName = {}
    local rosterByName = {}
    local rosterSeen = {}
    local ownStore = type(GetOwnCharacterStore) == "function" and GetOwnCharacterStore() or nil
    local ownByAlias = {}
    ui.ksmGuildOnlineSeenAt = ui.ksmGuildOnlineSeenAt or {}
    local onlineSeenAt = ui.ksmGuildOnlineSeenAt
    local now = GetServerTime and GetServerTime() or (time and time()) or 0
    local onlineStickyWindow = 30

    local function BuildNameAliases(rawName)
        local aliases = {}
        local seen = {}

        local function AddAlias(value)
            if type(value) == "string" and value ~= "" and not seen[value] then
                seen[value] = true
                table.insert(aliases, value)
            end
        end

        AddAlias(rawName)
        AddAlias(GetNormalizedPlayerName(rawName))

        return aliases
    end

    local function NamesReferToSameCharacter(leftName, rightName)
        if type(leftName) ~= "string" or leftName == "" or type(rightName) ~= "string" or rightName == "" then
            return false
        end

        local leftAliases = {}
        for _, alias in ipairs(BuildNameAliases(leftName)) do
            leftAliases[alias] = true
        end

        for _, alias in ipairs(BuildNameAliases(rightName)) do
            if leftAliases[alias] then
                return true
            end
        end

        return false
    end

    local function HasEntryByAnyAlias(name)
        for _, alias in ipairs(BuildNameAliases(name)) do
            if entryByName[alias] then
                return true
            end
        end
        return false
    end

    local function FindRosterEntryByAnyAlias(name)
        for _, alias in ipairs(BuildNameAliases(name)) do
            local rosterEntry = rosterByName[alias]
            if rosterEntry then
                return rosterEntry
            end
        end
        return nil
    end

    local function FindActiveUnitTokenByAnyAlias(name)
        local aliases = {}
        for _, alias in ipairs(BuildNameAliases(name)) do
            aliases[alias] = true
        end

        local function TokenMatches(token)
            if not UnitExists(token) then
                return false
            end

            local unitName, unitRealm = UnitName(token)
            if type(unitName) ~= "string" or unitName == "" then
                return false
            end

            local fullName = unitName
            if type(unitRealm) == "string" and unitRealm ~= "" then
                fullName = string.format("%s-%s", unitName, unitRealm)
            end

            for _, alias in ipairs(BuildNameAliases(fullName)) do
                if aliases[alias] then
                    return true
                end
            end

            for _, alias in ipairs(BuildNameAliases(unitName)) do
                if aliases[alias] then
                    return true
                end
            end

            return false
        end

        if TokenMatches("player") then
            return "player"
        end

        for i = 1, 4 do
            local token = string.format("party%d", i)
            if TokenMatches(token) then
                return token
            end
        end

        for i = 1, 40 do
            local token = string.format("raid%d", i)
            if TokenMatches(token) then
                return token
            end
        end

        return nil
    end

    local function MarkEntryAliases(name)
        for _, alias in ipairs(BuildNameAliases(name)) do
            entryByName[alias] = true
        end
    end

    local function FindOwnEntryByAnyAlias(name)
        for _, alias in ipairs(BuildNameAliases(name)) do
            local ownEntry = ownByAlias[alias]
            if ownEntry then
                return ownEntry
            end
        end
        return nil
    end

    if type(ownStore) == "table" then
        for ownName, ownCache in pairs(ownStore) do
            if type(ownName) == "string" and type(ownCache) == "table" then
                local normalizedOwnName = GetNormalizedPlayerName(ownName) or ownName
                if normalizedOwnName and normalizedOwnName ~= "" then
                    for _, alias in ipairs(BuildNameAliases(normalizedOwnName)) do
                        ownByAlias[alias] = ownCache
                    end
                end
            end
        end
    end

    local playerName = GetNormalizedPlayerName(UnitName("player"))
    local playerLevel = UnitLevel and UnitLevel("player") or nil
    local maxPlayerLevel = nil
    if type(GetMaxLevelForPlayerExpansion) == "function" then
        maxPlayerLevel = tonumber(GetMaxLevelForPlayerExpansion())
    end
    if not maxPlayerLevel and type(MAX_PLAYER_LEVEL) == "number" then
        maxPlayerLevel = MAX_PLAYER_LEVEL
    end
    if type(playerLevel) == "number" and playerLevel > 0 then
        maxPlayerLevel = max(tonumber(maxPlayerLevel) or 0, playerLevel)
    end
    if type(maxPlayerLevel) ~= "number" or maxPlayerLevel <= 0 then
        maxPlayerLevel = 90
    end

    local function IsMaxLevel(level)
        local numericLevel = tonumber(level) or 0
        return numericLevel >= maxPlayerLevel
    end

    local playerScore = floor((GetMythicPlusScore() or 0) + 0.5)
    local playerMapID, playerKeyLevel = GetOwnedKeystoneSnapshot()
    local playerCache = playerName and GetGuildMemberData(playerName) or nil
    if (tonumber(playerMapID) or 0) <= 0 then
        playerMapID = playerCache and tonumber(playerCache.mapID) or playerMapID
    end
    if (tonumber(playerKeyLevel) or 0) <= 0 then
        playerKeyLevel = playerCache and tonumber(playerCache.keyLevel) or playerKeyLevel
    end
    local playerClass = GetPlayerClassFile("player")

    local total = GetNumGuildMembersSafe()
    for index = 1, total do
        local fullName, _, _, level, _, _, _, _, online, statusText, classFile, _, _, isMobile, _, _, guid = GetGuildRosterInfo(index)
        if fullName then
            local name = GetNormalizedPlayerName(fullName)
            if not name or name == "" then
                name = type(fullName) == "string" and fullName ~= "" and fullName or nil
            end
            if name and IsMaxLevel(level) then
                local onlineNow = IsGuildOnlineValue(online)
                if not onlineNow and IsGuildOnlineValue(isMobile) then
                    onlineNow = true
                end
                if not onlineNow and IsGuildStatusOnline(statusText) then
                    onlineNow = true
                end

                if onlineNow then
                    for _, alias in ipairs(BuildNameAliases(name)) do
                        onlineSeenAt[alias] = now
                    end
                else
                    local seenRecently = false
                    for _, alias in ipairs(BuildNameAliases(name)) do
                        local seenAt = tonumber(onlineSeenAt[alias]) or 0
                        if seenAt > 0 and (now - seenAt) <= onlineStickyWindow then
                            seenRecently = true
                            break
                        end
                    end
                    if seenRecently then
                        onlineNow = true
                    end
                end

                local cache = GetGuildMemberData(name) or {}
                local ownCache = FindOwnEntryByAnyAlias(name)
                if type(ownCache) == "table" then
                    cache = ownCache
                end
                local isPlayer = NamesReferToSameCharacter(name, playerName)
                local rosterEntry = {
                    online = onlineNow,
                    classFile = classFile,
                    guid = guid,
                    level = tonumber(level) or 0,
                }
                for _, alias in ipairs(BuildNameAliases(name)) do
                    rosterByName[alias] = rosterEntry
                    rosterSeen[alias] = true
                end
                for _, alias in ipairs(BuildNameAliases(fullName)) do
                    rosterByName[alias] = rosterEntry
                    rosterSeen[alias] = true
                end

                local mapID = isPlayer and playerMapID or cache.mapID
                local keyLevel = isPlayer and playerKeyLevel or cache.keyLevel
                local rating = isPlayer and playerScore or cache.rating

                if not rating or rating <= 0 then
                    local apiScore = ResolveBestKnownScore(TryGetMythicScoreForIdentifier, guid, fullName, name)
                    if apiScore then
                        rating = floor(apiScore + 0.5)
                    end
                end

                if (not rating or rating <= 0) and type(TryGetUnitMythicScore) == "function" then
                    local activeUnitToken = FindActiveUnitTokenByAnyAlias(name)
                    if activeUnitToken then
                        local unitScore = TryGetUnitMythicScore(activeUnitToken)
                        if type(unitScore) == "number" and unitScore > 0 then
                            rating = floor(unitScore + 0.5)
                        end
                    end
                end

                local normalizedMapID = tonumber(mapID) or 0
                local normalizedKeyLevel = tonumber(keyLevel) or 0
                local normalizedRating = tonumber(rating) or 0
                local hasKnownKey = normalizedMapID > 0 and normalizedKeyLevel > 0

                if hasKnownKey then
                    local rowEntry = {
                        name = name or fullName,
                        class = isPlayer and playerClass or cache.class or classFile,
                        mapID = normalizedMapID,
                        keyLevel = normalizedKeyLevel,
                        rating = normalizedRating,
                        spellID = GetPortalSpellIDForMap(normalizedMapID),
                        online = isPlayer or onlineNow,
                        isOwnedCharacter = isPlayer,
                        guid = guid,
                    }
                    table.insert(entries, rowEntry)
                    MarkEntryAliases(rowEntry.name)
                end
            end
        end
    end

    if type(ownStore) == "table" then
        for ownName, ownCache in pairs(ownStore) do
            if type(ownName) == "string" and type(ownCache) == "table" then
                local normalizedOwnName = GetNormalizedPlayerName(ownName) or ownName
                if normalizedOwnName and normalizedOwnName ~= "" and not HasEntryByAnyAlias(normalizedOwnName) then
                    local ownedMapID = tonumber(ownCache.mapID) or 0
                    local ownedKeyLevel = tonumber(ownCache.keyLevel) or 0
                    if ownedMapID > 0 and ownedKeyLevel > 0 then
                        local ownedRating = tonumber(ownCache.rating) or 0
                        local rosterEntry = FindRosterEntryByAnyAlias(normalizedOwnName)
                        local isOwnedPlayer = NamesReferToSameCharacter(normalizedOwnName, playerName)
                        -- Guild tab should not synthesize non-roster rows from own-store alts.
                        if (rosterEntry and IsMaxLevel(rosterEntry.level))
                            or (isOwnedPlayer and IsMaxLevel(playerLevel)) then
                            table.insert(entries, {
                                name = normalizedOwnName,
                                class = isOwnedPlayer and playerClass or ownCache.class or (rosterEntry and rosterEntry.classFile),
                                mapID = ownedMapID,
                                keyLevel = ownedKeyLevel,
                                rating = ownedRating,
                                spellID = GetPortalSpellIDForMap(ownedMapID),
                                online = isOwnedPlayer or (rosterEntry and rosterEntry.online) or false,
                                isOwnedCharacter = true,
                                guid = rosterEntry and rosterEntry.guid,
                            })
                            MarkEntryAliases(normalizedOwnName)
                        end
                    end
                end
            end
        end
    end

    for alias in pairs(onlineSeenAt) do
        if not rosterSeen[alias] then
            onlineSeenAt[alias] = nil
        end
    end

    if playerName and not HasEntryByAnyAlias(playerName) then
        local fallbackMapID = tonumber(playerMapID) or 0
        local fallbackKeyLevel = tonumber(playerKeyLevel) or 0
        table.insert(entries, {
            name = playerName,
            class = playerClass,
            mapID = fallbackMapID,
            keyLevel = fallbackKeyLevel,
            rating = tonumber(playerScore) or 0,
            spellID = GetPortalSpellIDForMap(fallbackMapID),
            online = true,
            isOwnedCharacter = true,
            guid = UnitGUID and UnitGUID("player") or nil,
        })
        MarkEntryAliases(playerName)
    end

    local function SplitNameRealm(name)
        if type(name) ~= "string" then
            return nil, nil
        end

        local short, realm = name:match("^([^-]+)%-(.+)$")
        if short and realm then
            return short, realm
        end

        return name, nil
    end

    local function AreEquivalentGuildEntries(leftEntry, rightEntry)
        if type(leftEntry) ~= "table" or type(rightEntry) ~= "table" then
            return false
        end

        local leftGuid = type(leftEntry.guid) == "string" and leftEntry.guid or nil
        local rightGuid = type(rightEntry.guid) == "string" and rightEntry.guid or nil
        if leftGuid and rightGuid and leftGuid == rightGuid then
            return true
        end

        local leftName = leftEntry.name
        local rightName = rightEntry.name
        if NamesReferToSameCharacter(leftName, rightName) then
            return true
        end

        local leftShort, leftRealm = SplitNameRealm(leftName)
        local rightShort, rightRealm = SplitNameRealm(rightName)
        if not leftShort or not rightShort then
            return false
        end

        -- Collapse duplicate short/full forms for the same roster member (e.g. Chenyr + Chenyr-Stormrage).
        if leftShort == rightShort and ((leftRealm and not rightRealm) or (rightRealm and not leftRealm)) then
            return true
        end

        if leftShort == rightShort then
            if leftRealm == rightRealm then
                return true
            end

            local leftClass = type(leftEntry.class) == "string" and leftEntry.class or nil
            local rightClass = type(rightEntry.class) == "string" and rightEntry.class or nil
            local sameClass = leftClass and rightClass and leftClass == rightClass
            local leftMap = tonumber(leftEntry.mapID) or 0
            local rightMap = tonumber(rightEntry.mapID) or 0
            local leftKey = tonumber(leftEntry.keyLevel) or 0
            local rightKey = tonumber(rightEntry.keyLevel) or 0
            local leftRating = tonumber(leftEntry.rating) or 0
            local rightRating = tonumber(rightEntry.rating) or 0
            local sameKey = leftMap == rightMap and leftKey == rightKey
            local sameRating = math.abs(leftRating - rightRating) <= 1
            if sameClass and sameKey and sameRating then
                return true
            end

            if leftEntry.isOwnedCharacter or rightEntry.isOwnedCharacter then
                return true
            end
        end

        return false
    end

    local function ChoosePreferredGuildEntry(existing, candidate)
        if type(existing) ~= "table" then
            return candidate
        end
        if type(candidate) ~= "table" then
            return existing
        end

        -- Prefer roster-style short name when it exists, otherwise keep richer metadata.
        local existingShort, existingRealm = SplitNameRealm(existing.name)
        local candidateShort, candidateRealm = SplitNameRealm(candidate.name)
        if existingShort and candidateShort and existingShort == candidateShort then
            if existingRealm and not candidateRealm then
                return candidate
            end
            if candidateRealm and not existingRealm then
                return existing
            end
        end

        local existingGuid = type(existing.guid) == "string" and existing.guid ~= ""
        local candidateGuid = type(candidate.guid) == "string" and candidate.guid ~= ""
        if existingGuid ~= candidateGuid then
            return candidateGuid and candidate or existing
        end

        local existingOnline = existing.online and 1 or 0
        local candidateOnline = candidate.online and 1 or 0
        if existingOnline ~= candidateOnline then
            return candidateOnline > existingOnline and candidate or existing
        end

        local existingKey = tonumber(existing.keyLevel) or 0
        local candidateKey = tonumber(candidate.keyLevel) or 0
        if existingKey ~= candidateKey then
            return candidateKey > existingKey and candidate or existing
        end

        local existingRating = tonumber(existing.rating) or 0
        local candidateRating = tonumber(candidate.rating) or 0
        if existingRating ~= candidateRating then
            return candidateRating > existingRating and candidate or existing
        end

        return existing
    end

    local dedupedEntries = {}
    for _, entry in ipairs(entries) do
        local merged = false
        for index, existing in ipairs(dedupedEntries) do
            if AreEquivalentGuildEntries(existing, entry) then
                dedupedEntries[index] = ChoosePreferredGuildEntry(existing, entry)
                merged = true
                break
            end
        end

        if not merged then
            table.insert(dedupedEntries, entry)
        end
    end
    entries = dedupedEntries

    table.sort(entries, function(left, right)
        local leftOnline = left.online and 1 or 0
        local rightOnline = right.online and 1 or 0
        if leftOnline ~= rightOnline then
            return leftOnline > rightOnline
        end

        local leftLevel = tonumber(left.keyLevel) or 0
        local rightLevel = tonumber(right.keyLevel) or 0
        if leftLevel ~= rightLevel then
            return leftLevel > rightLevel
        end

        local leftRating = tonumber(left.rating) or 0
        local rightRating = tonumber(right.rating) or 0
        if leftRating ~= rightRating then
            return leftRating > rightRating
        end

        return (left.name or "") < (right.name or "")
    end)

    if ui.ksmHideOffline then
        local visibleEntries = {}
        for _, entry in ipairs(entries) do
            if entry.online or entry.isOwnedCharacter then
                table.insert(visibleEntries, entry)
            end
        end
        entries = visibleEntries
    end

    ui.ksmGuildTotalPages = max(1, math.ceil(#entries / 15))
    ui.ksmGuildPage = min(max(ui.ksmGuildPage or 1, 1), ui.ksmGuildTotalPages)

    if ui.ksmGuildPageText then
        ui.ksmGuildPageText:SetText(string.format("Page %d/%d", ui.ksmGuildPage, ui.ksmGuildTotalPages))
    end
    if ui.ksmGuildPrevButton then
        if ui.ksmGuildPage > 1 then
            ui.ksmGuildPrevButton:Enable()
            ui.ksmGuildPrevButton:SetAlpha(1)
        else
            ui.ksmGuildPrevButton:Disable()
            ui.ksmGuildPrevButton:SetAlpha(0.45)
        end
    end
    if ui.ksmGuildNextButton then
        if ui.ksmGuildPage < ui.ksmGuildTotalPages then
            ui.ksmGuildNextButton:Enable()
            ui.ksmGuildNextButton:SetAlpha(1)
        else
            ui.ksmGuildNextButton:Disable()
            ui.ksmGuildNextButton:SetAlpha(0.45)
        end
    end

    if #entries == 0 then
        local row = EnsureKSMGuildRow(1)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", ui.ksmGuildContent, "TOPLEFT", 10, -52)
        row.classIcon:Hide()
        row.nameText:SetText(ui.ksmHideOffline and "No online guild members with known keys" or "No guild members with known keys")
        row.nameText:SetTextColor(1, 1, 1, 1)
        row.keyText:SetText("")
        row.dungeonText:SetText("")
        row.ratingText:SetText("")
        row.teleportButton:Hide()
        row:Show()
        for index = 2, #ui.ksmGuildRows do
            ui.ksmGuildRows[index]:Hide()
        end
        for index = 1, #ui.ksmGuildLines do
            ui.ksmGuildLines[index]:Hide()
        end
        return
    end

    local pageStart = ((ui.ksmGuildPage - 1) * 15) + 1
    local pageEnd = min(pageStart + 15 - 1, #entries)

    local y = -56
    local renderedCount = 0
    for index = pageStart, pageEnd do
        local entry = entries[index]
        renderedCount = renderedCount + 1
        local row = EnsureKSMGuildRow(renderedCount)
        local r, g, b = GetClassColorInfo(entry.class)

        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", ui.ksmGuildContent, "TOPLEFT", 10, y)
        ApplyClassIcon(row.classIcon, entry.class)
        row.classIcon:Show()
        local displayName = GetShortDisplayName(entry.name)
        row.nameText:SetText(entry.online and displayName or string.format("%s (offline)", displayName))
        row.nameText:SetTextColor(r, g, b, entry.online and 1 or 0.65)
        if row.nameButton then
            row.nameButton:SetScript("OnEnter", function(self)
                if not self.inviteName then
                    return
                end
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:AddLine(GetShortDisplayName(self.inviteName), 1, 1, 1)
                GameTooltip:AddLine("Right-click to invite", 0.75, 0.85, 1)
                GameTooltip:Show()
            end)
            row.nameButton:SetScript("OnLeave", GameTooltip_Hide)
            row.nameButton:SetScript("OnClick", function(self, button)
                if button ~= "RightButton" or not self.inviteName or type(InvitePlayerByName) ~= "function" then
                    return
                end

                local inviteName = self.inviteName
                local shown = ShowNameContextMenu({
                    {
                        text = "Invite",
                        notCheckable = true,
                        func = function()
                            InvitePlayerByName(inviteName)
                        end,
                    },
                })
                if not shown then
                    InvitePlayerByName(inviteName)
                end
            end)
            row.nameButton.inviteName = entry.name
            row.nameButton:Show()
        end
        row.keyText:SetText(entry.keyLevel > 0 and string.format("+%d", entry.keyLevel) or "-")
        row.dungeonText:SetText(entry.mapID > 0 and FormatDungeonLabel(entry.mapID) or "No key")
        row.keyText:SetTextColor(1, 0.82, 0.2, entry.online and 1 or 0.65)
        row.dungeonText:SetTextColor(0.95, 0.95, 0.95, entry.online and 1 or 0.65)
        row.ratingText:SetText(entry.rating > 0 and tostring(entry.rating) or "-")
        row.ratingText:SetTextColor(0.95, 0.95, 0.95, entry.online and 1 or 0.65)

        if entry.spellID then
            row.teleportButton.spellID = entry.spellID
            local known = ConfigurePortalActionButton and ConfigurePortalActionButton(row.teleportButton, entry.spellID)
            row.teleportButton:Show()
            row.teleportButton.label:SetText("Teleport")
            if known == nil then
                known = IsPortalSpellKnown and IsPortalSpellKnown(entry.spellID)
            end
            row.teleportButton.label:SetTextColor(known and 1 or 0.55, known and 1 or 0.55, known and 1 or 0.55, 1)
        else
            row.teleportButton.spellID = nil
            if ConfigurePortalActionButton then
                ConfigurePortalActionButton(row.teleportButton, nil)
            end
            row.teleportButton:Hide()
        end

        row:Show()
        y = y - 24
    end

    for index = renderedCount + 1, #ui.ksmGuildRows do
        ui.ksmGuildRows[index]:Hide()
    end

    for index = 1, #ui.ksmGuildLines do
        ui.ksmGuildLines[index]:Hide()
    end
end

function KSM.RefreshRecentsTab(ctx)
    local ui = ctx.ui
    if not ui or not ui.ksmRecentsContent then
        return
    end

    local floor = ctx.floor
    local max = ctx.max
    local min = ctx.min
    local EnsureKSMRecentRow = ctx.EnsureKSMRecentRow
    local GetGuildMemberStore = ctx.GetGuildMemberStore
    local GetPortalSpellIDForMap = ctx.GetPortalSpellIDForMap
    local GetClassColorInfo = ctx.GetClassColorInfo
    local ApplyClassIcon = ctx.ApplyClassIcon
    local FormatDungeonLabel = ctx.FormatDungeonLabel
    local IsPortalSpellKnown = ctx.IsPortalSpellKnown
    local ConfigurePortalActionButton = ctx.ConfigurePortalActionButton
    local TryGetMythicScoreForIdentifier = ctx.TryGetMythicScoreForIdentifier
    local GetNormalizedPlayerName = ctx.GetNormalizedPlayerName
    local InvitePlayerByName = ctx.InvitePlayerByName
    local RemoveRecentEntryByName = ctx.RemoveRecentEntryByName

    local dedupedEntries = {}
    local playerName = GetNormalizedPlayerName(UnitName("player"))
    local store = GetGuildMemberStore()

    local function ShouldUseCandidate(existing, candidate)
        if type(existing) ~= "table" then
            return true
        end

        local existingUpdated = tonumber(existing.updatedAt) or 0
        local candidateUpdated = tonumber(candidate.updatedAt) or 0
        if candidateUpdated ~= existingUpdated then
            return candidateUpdated > existingUpdated
        end

        local existingKey = tonumber(existing.keyLevel) or 0
        local candidateKey = tonumber(candidate.keyLevel) or 0
        if candidateKey ~= existingKey then
            return candidateKey > existingKey
        end

        local existingRating = tonumber(existing.rating) or 0
        local candidateRating = tonumber(candidate.rating) or 0
        return candidateRating > existingRating
    end

    for cachedName, cache in pairs(store) do
        if type(cachedName) == "string" and type(cache) == "table" then
            local normalizedName = GetNormalizedPlayerName(cachedName) or cachedName
            if normalizedName ~= playerName and cache.hiddenInRecents ~= true then
                local mapID = tonumber(cache.mapID) or 0
                local keyLevel = tonumber(cache.keyLevel) or 0
                if mapID > 0 and keyLevel > 0 then
                    local rating = tonumber(cache.rating) or 0
                    if rating <= 0 and type(TryGetMythicScoreForIdentifier) == "function" then
                        local apiScore = TryGetMythicScoreForIdentifier(normalizedName)
                        if type(apiScore) == "number" and apiScore > 0 then
                            rating = floor(apiScore + 0.5)
                        end
                    end

                    local candidate = {
                        name = normalizedName,
                        class = cache.class,
                        mapID = mapID,
                        keyLevel = keyLevel,
                        rating = rating,
                        spellID = GetPortalSpellIDForMap(mapID),
                        updatedAt = tonumber(cache.updatedAt) or 0,
                    }

                    if ShouldUseCandidate(dedupedEntries[normalizedName], candidate) then
                        dedupedEntries[normalizedName] = candidate
                    end
                end
            end
        end
    end

    local entries = {}
    for _, entry in pairs(dedupedEntries) do
        table.insert(entries, entry)
    end

    table.sort(entries, function(left, right)
        local leftUpdated = tonumber(left.updatedAt) or 0
        local rightUpdated = tonumber(right.updatedAt) or 0
        if leftUpdated ~= rightUpdated then
            return leftUpdated > rightUpdated
        end

        local leftLevel = tonumber(left.keyLevel) or 0
        local rightLevel = tonumber(right.keyLevel) or 0
        if leftLevel ~= rightLevel then
            return leftLevel > rightLevel
        end

        return (left.name or "") < (right.name or "")
    end)

    ui.ksmRecentsTotalPages = max(1, math.ceil(#entries / 15))
    ui.ksmRecentsPage = min(max(ui.ksmRecentsPage or 1, 1), ui.ksmRecentsTotalPages)

    if ui.ksmRecentsPageText then
        ui.ksmRecentsPageText:SetText(string.format("Page %d/%d", ui.ksmRecentsPage, ui.ksmRecentsTotalPages))
    end
    if ui.ksmRecentsPrevButton then
        if ui.ksmRecentsPage > 1 then
            ui.ksmRecentsPrevButton:Enable()
            ui.ksmRecentsPrevButton:SetAlpha(1)
        else
            ui.ksmRecentsPrevButton:Disable()
            ui.ksmRecentsPrevButton:SetAlpha(0.45)
        end
    end
    if ui.ksmRecentsNextButton then
        if ui.ksmRecentsPage < ui.ksmRecentsTotalPages then
            ui.ksmRecentsNextButton:Enable()
            ui.ksmRecentsNextButton:SetAlpha(1)
        else
            ui.ksmRecentsNextButton:Disable()
            ui.ksmRecentsNextButton:SetAlpha(0.45)
        end
    end

    if #entries == 0 then
        local row = EnsureKSMRecentRow(1)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", ui.ksmRecentsContent, "TOPLEFT", 10, -52)
        row.classIcon:Hide()
        row.nameText:SetText("No recent key data yet")
        row.nameText:SetTextColor(1, 1, 1, 1)
        row.keyText:SetText("")
        row.dungeonText:SetText("Join a group and request keys")
        row.ratingText:SetText("")
        row.teleportButton:Hide()
        row:Show()
        for index = 2, #ui.ksmRecentsRows do
            ui.ksmRecentsRows[index]:Hide()
        end
        for index = 1, #ui.ksmRecentsLines do
            ui.ksmRecentsLines[index]:Hide()
        end
        return
    end

    local pageStart = ((ui.ksmRecentsPage - 1) * 15) + 1
    local pageEnd = min(pageStart + 15 - 1, #entries)

    local y = -56
    local renderedCount = 0
    for index = pageStart, pageEnd do
        local entry = entries[index]
        renderedCount = renderedCount + 1
        local row = EnsureKSMRecentRow(renderedCount)
        local r, g, b = GetClassColorInfo(entry.class)

        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", ui.ksmRecentsContent, "TOPLEFT", 10, y)
        ApplyClassIcon(row.classIcon, entry.class)
        row.classIcon:Show()
        row.nameText:SetText(GetShortDisplayName(entry.name))
        row.nameText:SetTextColor(r, g, b, 1)
        if row.nameButton then
            row.nameButton:SetScript("OnEnter", function(self)
                if not self.playerName then
                    return
                end
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:AddLine(GetShortDisplayName(self.playerName), 1, 1, 1)
                GameTooltip:AddLine("Right-click to invite", 0.75, 0.85, 1)
                GameTooltip:AddLine("Shift+Right-click to remove", 0.75, 0.85, 1)
                GameTooltip:Show()
            end)
            row.nameButton:SetScript("OnLeave", GameTooltip_Hide)
            row.nameButton:SetScript("OnClick", function(self, button)
                if button ~= "RightButton" or not self.playerName then
                    return
                end

                local playerName = self.playerName
                local shown = ShowNameContextMenu({
                    {
                        text = "Invite",
                        notCheckable = true,
                        disabled = type(InvitePlayerByName) ~= "function",
                        func = function()
                            if type(InvitePlayerByName) == "function" then
                                InvitePlayerByName(playerName)
                            end
                        end,
                    },
                    {
                        text = "Remove",
                        notCheckable = true,
                        disabled = type(RemoveRecentEntryByName) ~= "function",
                        func = function()
                            if type(RemoveRecentEntryByName) == "function" then
                                RemoveRecentEntryByName(playerName)
                                KSM.RefreshRecentsTab(ctx)
                                KSM.RefreshGuildTab(ctx)
                            end
                        end,
                    },
                })

                if not shown then
                    if IsShiftKeyDown and IsShiftKeyDown() and type(RemoveRecentEntryByName) == "function" then
                        RemoveRecentEntryByName(playerName)
                        KSM.RefreshRecentsTab(ctx)
                        KSM.RefreshGuildTab(ctx)
                    elseif type(InvitePlayerByName) == "function" then
                        InvitePlayerByName(playerName)
                    end
                end
            end)
            row.nameButton.playerName = entry.name
            row.nameButton:Show()
        end
        row.keyText:SetText(entry.keyLevel > 0 and string.format("+%d", entry.keyLevel) or "-")
        row.dungeonText:SetText(entry.mapID > 0 and FormatDungeonLabel(entry.mapID) or "No key")
        row.keyText:SetTextColor(1, 0.82, 0.2, 1)
        row.dungeonText:SetTextColor(0.95, 0.95, 0.95, 1)
        row.ratingText:SetText(entry.rating > 0 and tostring(entry.rating) or "-")
        row.ratingText:SetTextColor(0.95, 0.95, 0.95, 1)

        if entry.spellID then
            row.teleportButton.spellID = entry.spellID
            local known = ConfigurePortalActionButton and ConfigurePortalActionButton(row.teleportButton, entry.spellID)
            row.teleportButton:Show()
            row.teleportButton.label:SetText("Teleport")
            if known == nil then
                known = IsPortalSpellKnown and IsPortalSpellKnown(entry.spellID)
            end
            row.teleportButton.label:SetTextColor(known and 1 or 0.55, known and 1 or 0.55, known and 1 or 0.55, 1)
        else
            row.teleportButton.spellID = nil
            if ConfigurePortalActionButton then
                ConfigurePortalActionButton(row.teleportButton, nil)
            end
            row.teleportButton:Hide()
        end

        row:Show()
        y = y - 24
    end

    for index = renderedCount + 1, #ui.ksmRecentsRows do
        ui.ksmRecentsRows[index]:Hide()
    end

    for index = 1, #ui.ksmRecentsLines do
        ui.ksmRecentsLines[index]:Hide()
    end
end

function KSM.RefreshWarbandTab(ctx)
    local ui = ctx.ui
    if not ui or not ui.ksmWarbandContent then
        return
    end

    local floor = ctx.floor
    local max = ctx.max
    local min = ctx.min
    local EnsureKSMWarbandRow = ctx.EnsureKSMWarbandRow
    local GetOwnCharacterStore = ctx.GetOwnCharacterStore
    local GetPortalSpellIDForMap = ctx.GetPortalSpellIDForMap
    local GetClassColorInfo = ctx.GetClassColorInfo
    local ApplyClassIcon = ctx.ApplyClassIcon
    local FormatDungeonLabel = ctx.FormatDungeonLabel
    local IsPortalSpellKnown = ctx.IsPortalSpellKnown
    local ConfigurePortalActionButton = ctx.ConfigurePortalActionButton
    local GetNormalizedPlayerName = ctx.GetNormalizedPlayerName

    local dedupedEntries = {}
    local playerName = GetNormalizedPlayerName(UnitName("player"))
    local playerFullName = nil
    if UnitFullName then
        local unitName, unitRealm = UnitFullName("player")
        if type(unitName) == "string" and unitName ~= "" then
            playerFullName = (type(unitRealm) == "string" and unitRealm ~= "") and string.format("%s-%s", unitName, unitRealm) or unitName
        end
    end

    local function IsCurrentCharacterName(name)
        if type(name) ~= "string" or name == "" then
            return false
        end

        if playerFullName and name == playerFullName then
            return true
        end

        local normalizedName = GetNormalizedPlayerName(name) or name
        return playerName and normalizedName == playerName
    end

    local store = type(GetOwnCharacterStore) == "function" and GetOwnCharacterStore() or nil

    local function ShouldUseCandidate(existing, candidate)
        if type(existing) ~= "table" then
            return true
        end

        local existingUpdated = tonumber(existing.updatedAt) or 0
        local candidateUpdated = tonumber(candidate.updatedAt) or 0
        if candidateUpdated ~= existingUpdated then
            return candidateUpdated > existingUpdated
        end

        local existingKey = tonumber(existing.keyLevel) or 0
        local candidateKey = tonumber(candidate.keyLevel) or 0
        if candidateKey ~= existingKey then
            return candidateKey > existingKey
        end

        local existingRating = tonumber(existing.rating) or 0
        local candidateRating = tonumber(candidate.rating) or 0
        return candidateRating > existingRating
    end

    if type(store) == "table" then
        for cachedName, cache in pairs(store) do
            if type(cachedName) == "string" and type(cache) == "table" then
                local normalizedName = GetNormalizedPlayerName(cachedName) or cachedName
                local mapID = tonumber(cache.mapID) or 0
                local keyLevel = tonumber(cache.keyLevel) or 0
                if normalizedName and normalizedName ~= "" and mapID > 0 and keyLevel > 0 then
                    local candidate = {
                        name = normalizedName,
                        class = cache.class,
                        mapID = mapID,
                        keyLevel = keyLevel,
                        rating = tonumber(cache.rating) or 0,
                        spellID = GetPortalSpellIDForMap(mapID),
                        updatedAt = tonumber(cache.updatedAt) or 0,
                        isCurrent = IsCurrentCharacterName(normalizedName),
                    }

                    local existing = dedupedEntries[normalizedName]
                    if ShouldUseCandidate(existing, candidate) then
                        dedupedEntries[normalizedName] = candidate
                    elseif existing and candidate.isCurrent then
                        existing.isCurrent = true
                    end
                end
            end
        end
    end

    local entries = {}
    for _, entry in pairs(dedupedEntries) do
        table.insert(entries, entry)
    end

    table.sort(entries, function(left, right)
        local leftCurrent = left.isCurrent and 1 or 0
        local rightCurrent = right.isCurrent and 1 or 0
        if leftCurrent ~= rightCurrent then
            return leftCurrent > rightCurrent
        end

        local leftUpdated = tonumber(left.updatedAt) or 0
        local rightUpdated = tonumber(right.updatedAt) or 0
        if leftUpdated ~= rightUpdated then
            return leftUpdated > rightUpdated
        end

        local leftLevel = tonumber(left.keyLevel) or 0
        local rightLevel = tonumber(right.keyLevel) or 0
        if leftLevel ~= rightLevel then
            return leftLevel > rightLevel
        end

        return (left.name or "") < (right.name or "")
    end)

    ui.ksmWarbandTotalPages = max(1, math.ceil(#entries / 15))
    ui.ksmWarbandPage = min(max(ui.ksmWarbandPage or 1, 1), ui.ksmWarbandTotalPages)

    if ui.ksmWarbandPageText then
        ui.ksmWarbandPageText:SetText(string.format("Page %d/%d", ui.ksmWarbandPage, ui.ksmWarbandTotalPages))
    end
    if ui.ksmWarbandPrevButton then
        if ui.ksmWarbandPage > 1 then
            ui.ksmWarbandPrevButton:Enable()
            ui.ksmWarbandPrevButton:SetAlpha(1)
        else
            ui.ksmWarbandPrevButton:Disable()
            ui.ksmWarbandPrevButton:SetAlpha(0.45)
        end
    end
    if ui.ksmWarbandNextButton then
        if ui.ksmWarbandPage < ui.ksmWarbandTotalPages then
            ui.ksmWarbandNextButton:Enable()
            ui.ksmWarbandNextButton:SetAlpha(1)
        else
            ui.ksmWarbandNextButton:Disable()
            ui.ksmWarbandNextButton:SetAlpha(0.45)
        end
    end

    if #entries == 0 then
        local row = EnsureKSMWarbandRow(1)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", ui.ksmWarbandContent, "TOPLEFT", 10, -52)
        row.classIcon:Hide()
        row.nameText:SetText("No warband characters with known keys yet")
        row.nameText:SetTextColor(1, 1, 1, 1)
        row.keyText:SetText("")
        row.dungeonText:SetText("Run a key on an alt to add it")
        row.ratingText:SetText("")
        row.teleportButton:Hide()
        row:Show()
        for index = 2, #ui.ksmWarbandRows do
            ui.ksmWarbandRows[index]:Hide()
        end
        for index = 1, #ui.ksmWarbandLines do
            ui.ksmWarbandLines[index]:Hide()
        end
        return
    end

    local pageStart = ((ui.ksmWarbandPage - 1) * 15) + 1
    local pageEnd = min(pageStart + 15 - 1, #entries)

    local y = -56
    local renderedCount = 0
    for index = pageStart, pageEnd do
        local entry = entries[index]
        renderedCount = renderedCount + 1
        local row = EnsureKSMWarbandRow(renderedCount)
        local r, g, b = GetClassColorInfo(entry.class)

        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", ui.ksmWarbandContent, "TOPLEFT", 10, y)
        ApplyClassIcon(row.classIcon, entry.class)
        row.classIcon:Show()
        local warbandDisplayName = GetShortDisplayName(entry.name)
        row.nameText:SetText(entry.isCurrent and string.format("%s (current)", warbandDisplayName) or warbandDisplayName)
        row.nameText:SetTextColor(r, g, b, 1)
        row.keyText:SetText(entry.keyLevel > 0 and string.format("+%d", entry.keyLevel) or "-")
        row.dungeonText:SetText(entry.mapID > 0 and FormatDungeonLabel(entry.mapID) or "No key")
        row.keyText:SetTextColor(1, 0.82, 0.2, 1)
        row.dungeonText:SetTextColor(0.95, 0.95, 0.95, 1)
        row.ratingText:SetText(entry.rating > 0 and tostring(entry.rating) or "-")
        row.ratingText:SetTextColor(0.95, 0.95, 0.95, 1)

        if entry.spellID then
            row.teleportButton.spellID = entry.spellID
            local known = ConfigurePortalActionButton and ConfigurePortalActionButton(row.teleportButton, entry.spellID)
            row.teleportButton:Show()
            row.teleportButton.label:SetText("Teleport")
            if known == nil then
                known = IsPortalSpellKnown and IsPortalSpellKnown(entry.spellID)
            end
            row.teleportButton.label:SetTextColor(known and 1 or 0.55, known and 1 or 0.55, known and 1 or 0.55, 1)
        else
            row.teleportButton.spellID = nil
            if ConfigurePortalActionButton then
                ConfigurePortalActionButton(row.teleportButton, nil)
            end
            row.teleportButton:Hide()
        end

        row:Show()
        y = y - 24
    end

    for index = renderedCount + 1, #ui.ksmWarbandRows do
        ui.ksmWarbandRows[index]:Hide()
    end

    for index = 1, #ui.ksmWarbandLines do
        ui.ksmWarbandLines[index]:Hide()
    end
end
