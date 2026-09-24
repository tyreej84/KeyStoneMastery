local ns = _G.KeyStoneMasteryNS
if type(ns) ~= "table" then
    ns = {}
    _G.KeyStoneMasteryNS = ns
end

local Sync = {}
ns.Sync = Sync

local lastGuildSyncRequestAt = 0
local pendingSendRetries = {}

local SEND_RESULT_SUCCESS = 0
local SEND_RESULT_ADDON_MESSAGE_THROTTLE = 3
local SEND_RESULT_CHANNEL_THROTTLE = 8
local SEND_RESULT_ADDON_MESSAGE_LOCKDOWN = 11

local DETAILS_PLAYERINFO_PREFIX = ns.DETAILS_PLAYERINFO_PREFIX or "PITB"
local DETAILS_PLAYERINFO_REQUEST_PREFIX = ns.DETAILS_PLAYERINFO_REQUEST_PREFIX or "R"
local DETAILS_PLAYERINFO_FULLINFO_PREFIX = ns.DETAILS_PLAYERINFO_FULLINFO_PREFIX or "F"
local DETAILS_PLAYERINFO_KEYSTONE_PREFIX = ns.DETAILS_PLAYERINFO_KEYSTONE_PREFIX or "K"

local function ExtractSendAddonMessageResult(result1, result2, result3)
    if type(result3) == "number" then
        return result3
    end

    if type(result2) == "number" then
        return result2
    end

    if type(result1) == "number" then
        return result1
    end

    return nil
end

local function ShouldRetrySendResult(result)
    return result == SEND_RESULT_ADDON_MESSAGE_THROTTLE
        or result == SEND_RESULT_CHANNEL_THROTTLE
        or result == SEND_RESULT_ADDON_MESSAGE_LOCKDOWN
end

local function BuildRetryKey(prefix, message, channel, target)
    return table.concat({
        tostring(prefix or ""),
        tostring(channel or ""),
        tostring(target or ""),
        tostring(message or ""),
    }, "\031")
end

local function SendAddonMessageSafe(prefix, message, channel, target)
    if not (C_ChatInfo and C_ChatInfo.SendAddonMessage) then
        return false, nil
    end

    local ok, result1, result2, result3 = pcall(C_ChatInfo.SendAddonMessage, prefix, message, channel, target)
    if not ok then
        return false, nil
    end

    local result = ExtractSendAddonMessageResult(result1, result2, result3)
    if result == nil and type(result1) == "boolean" then
        return result1, nil
    end

    if result == nil then
        return true, nil
    end

    return result == SEND_RESULT_SUCCESS, result
end

local function TrySendAddonMessage(prefix, message, channel, target)
    local sent, result = SendAddonMessageSafe(prefix, message, channel, target)
    if sent or not ShouldRetrySendResult(result) then
        return sent, result
    end

    if not (C_Timer and type(C_Timer.After) == "function") then
        return sent, result
    end

    local retryKey = BuildRetryKey(prefix, message, channel, target)
    if pendingSendRetries[retryKey] then
        return sent, result
    end

    pendingSendRetries[retryKey] = true
    C_Timer.After(1, function()
        pendingSendRetries[retryKey] = nil
        SendAddonMessageSafe(prefix, message, channel, target)
    end)

    return sent, result
end

ns.SendAddonMessageSafe = TrySendAddonMessage

local function BuildSyncChannels(ctx)
    local channels = {}
    local seen = {}

    local function AddChannel(channel)
        if seen[channel] then
            return
        end

        seen[channel] = true
        table.insert(channels, channel)
    end

    if ctx.IsPlayerInGuildSafe and ctx.IsPlayerInGuildSafe() then
        AddChannel("GUILD")
    end

    local inInstanceGroup = IsInGroup and LE_PARTY_CATEGORY_INSTANCE and IsInGroup(LE_PARTY_CATEGORY_INSTANCE)
    if inInstanceGroup then
        AddChannel("INSTANCE_CHAT")
    elseif IsInRaid and IsInRaid() then
        AddChannel("RAID")
    elseif IsInGroup and IsInGroup() then
        AddChannel("PARTY")
    end

    return channels
end

local function ClampNumber(value, minValue, maxValue, defaultValue)
    local numberValue = tonumber(value)
    if type(numberValue) ~= "number" then
        return defaultValue
    end

    numberValue = math.floor(numberValue + 0.5)
    if numberValue < minValue or numberValue > maxValue then
        return defaultValue
    end

    return numberValue
end

local function NormalizeClassFile(ctx, classFile)
    if type(classFile) ~= "string" then
        return nil
    end

    local normalized = strupper(classFile)
    if normalized:match("^[A-Z]+$") ~= normalized then
        return nil
    end

    if RAID_CLASS_COLORS and RAID_CLASS_COLORS[normalized] then
        return normalized
    end

    for _, knownClassFile in pairs(ctx.CLASS_ID_TO_FILE or {}) do
        if knownClassFile == normalized then
            return normalized
        end
    end

    return nil
end

local function ParseGuildSyncPayload(ctx, message)
    if type(message) ~= "string" or message == "" then
        return nil
    end

    local version, classFile, mapIDText, keyLevelText, ratingText = strsplit("\t", message)
    if version == ctx.KSM_GUILD_SYNC_VERSION then
        return {
            class = NormalizeClassFile(ctx, classFile),
            mapID = ClampNumber(mapIDText, 0, 20000, 0),
            keyLevel = ClampNumber(keyLevelText, 0, 50, 0),
            rating = ClampNumber(ratingText, 0, 20000, 0),
            source = "keystonemastery",
        }
    end

    -- Compatibility parser for Name:MapID:Level payloads.
    local _, mapIDColon, keyLevelColon = strsplit(":", message)
    local parsedMapID = ClampNumber(mapIDColon, 0, 20000, nil)
    local parsedKeyLevel = ClampNumber(keyLevelColon, 0, 50, nil)
    if parsedMapID and parsedKeyLevel then
        return {
            mapID = parsedMapID,
            keyLevel = parsedKeyLevel,
            source = "keystonemastery",
        }
    end

    local genericMapID, genericKeyLevel = message:match(":(%d+):(%d+):")
    genericMapID = ClampNumber(genericMapID, 0, 20000, nil)
    genericKeyLevel = ClampNumber(genericKeyLevel, 0, 50, nil)
    if genericMapID and genericKeyLevel then
        return {
            mapID = genericMapID,
            keyLevel = genericKeyLevel,
            source = "keystonemastery",
        }
    end

    local trailingMapID, trailingKeyLevel = message:match(":(%d+):(%d+)$")
    trailingMapID = ClampNumber(trailingMapID, 0, 20000, nil)
    trailingKeyLevel = ClampNumber(trailingKeyLevel, 0, 50, nil)
    if trailingMapID and trailingKeyLevel then
        return {
            mapID = trailingMapID,
            keyLevel = trailingKeyLevel,
            source = "keystonemastery",
        }
    end

    return nil
end

local function GetLibDeflateInstance(ctx)
    if not LibStub then
        return nil
    end

    local ok, libDeflate = pcall(LibStub.GetLibrary, LibStub, "LibDeflate", true)
    if ok and libDeflate then
        return libDeflate
    end

    return nil
end

local function SendDetailsOpenRaidKeystoneRequest(ctx, channel)
    if type(channel) ~= "string" or channel == "" then
        return false
    end

    if not (C_ChatInfo and C_ChatInfo.SendAddonMessage) then
        return false
    end

    local libDeflate = GetLibDeflateInstance(ctx)
    if not libDeflate then
        return false
    end

    local compressed = libDeflate:CompressDeflate(ctx.DETAILS_OPENRAID_KEYSTONE_REQUEST_PREFIX, { level = 9 })
    if type(compressed) ~= "string" then
        return false
    end

    local encoded = libDeflate:EncodeForWoWAddonChannel(compressed)
    if type(encoded) ~= "string" or encoded == "" then
        return false
    end

    local sent = TrySendAddonMessage(ctx.DETAILS_OPENRAID_PREFIX, encoded, channel)
    return sent == true
end

local function EncodeDeflatedBase64(dataString)
    if type(dataString) ~= "string" or dataString == "" then
        return nil
    end
    if not (C_EncodingUtil and C_EncodingUtil.CompressString and C_EncodingUtil.EncodeBase64 and Enum and Enum.CompressionMethod and Enum.CompressionMethod.Deflate) then
        return nil
    end

    local compressed = C_EncodingUtil.CompressString(dataString, Enum.CompressionMethod.Deflate)
    if type(compressed) ~= "string" or compressed == "" then
        return nil
    end

    local encoded = C_EncodingUtil.EncodeBase64(compressed)
    if type(encoded) ~= "string" or encoded == "" then
        return nil
    end

    return encoded
end

local function DecodeDeflatedBase64(message)
    if type(message) ~= "string" or message == "" then
        return nil
    end
    if not (C_EncodingUtil and C_EncodingUtil.DecodeBase64 and C_EncodingUtil.DecompressString and Enum and Enum.CompressionMethod and Enum.CompressionMethod.Deflate) then
        return nil
    end

    local decoded = C_EncodingUtil.DecodeBase64(message)
    if type(decoded) ~= "string" or decoded == "" then
        return nil
    end

    local inflated = C_EncodingUtil.DecompressString(decoded, Enum.CompressionMethod.Deflate)
    if type(inflated) ~= "string" or inflated == "" then
        return nil
    end

    return inflated
end

local function SendDetailsPlayerInfoKeystoneRequest(ctx, channel)
    if type(channel) ~= "string" or channel == "" then
        return false
    end
    if channel == "GUILD" then
        return false
    end

    local encoded = EncodeDeflatedBase64(DETAILS_PLAYERINFO_REQUEST_PREFIX)
    if type(encoded) ~= "string" or encoded == "" then
        return false
    end

    local sent = TrySendAddonMessage(DETAILS_PLAYERINFO_PREFIX, encoded, channel)
    return sent == true
end

local function ParsePackedNumericTable(packedData)
    if type(packedData) ~= "string" or packedData == "" then
        return nil
    end

    local pieces = {}
    for value in packedData:gmatch("[^,]+") do
        pieces[#pieces + 1] = value
    end

    local count = tonumber(pieces[1])
    if type(count) ~= "number" or count < 1 then
        return nil
    end

    count = math.floor(count + 0.5)
    local result = {}
    for index = 1, count do
        result[index] = pieces[index + 1]
    end

    return result
end

local function SaveDetailsPlayerInfoKeystone(ctx, sender, packedData)
    local fields = ParsePackedNumericTable(packedData)
    if type(fields) ~= "table" then
        return
    end

    local keyLevel = ClampNumber(fields[1], 0, 50, 0)
    local mapID = ClampNumber(fields[3], 0, 20000, nil)
        or ClampNumber(fields[6], 0, 20000, nil)
        or ClampNumber(fields[2], 0, 20000, 0)
    local classID = ClampNumber(fields[4], 1, 99, nil)
    local rating = ClampNumber(fields[5], 0, 20000, 0)

    ctx.SaveGuildMemberData(sender, {
        class = classID and ctx.CLASS_ID_TO_FILE[classID] or nil,
        mapID = mapID,
        keyLevel = keyLevel,
        rating = rating,
        source = "details-playerinfo",
    })
end

function Sync.RequestGuildSnapshots(ctx)
    if not (C_ChatInfo and C_ChatInfo.SendAddonMessage) then
        return
    end

    for _, channel in ipairs(BuildSyncChannels(ctx)) do
        TrySendAddonMessage(ctx.KSM_ADDON_PREFIX, ctx.KSM_GUILD_SYNC_REQUEST, channel)
    end
end

function Sync.RequestGuildKeysFromAllSources(ctx, force, includeExternal)
    local now = GetTime and GetTime() or 0
    if not force and now > 0 and (now - lastGuildSyncRequestAt) < 8 then
        return false
    end

    local channels = BuildSyncChannels(ctx)
    if #channels == 0 then
        return false
    end

    lastGuildSyncRequestAt = now

    if ctx.IsPlayerInGuildSafe and ctx.IsPlayerInGuildSafe() and C_GuildInfo and C_GuildInfo.GuildRoster then
        pcall(C_GuildInfo.GuildRoster)
    elseif ctx.IsPlayerInGuildSafe and ctx.IsPlayerInGuildSafe() and GuildRoster then
        pcall(GuildRoster)
    end

    for _, channel in ipairs(channels) do
        TrySendAddonMessage(ctx.KSM_ADDON_PREFIX, ctx.KSM_GUILD_SYNC_REQUEST, channel)
    end

    if includeExternal and C_ChatInfo and C_ChatInfo.SendAddonMessage then
        for _, channel in ipairs(channels) do
            TrySendAddonMessage(ctx.ASTRAL_KEYS_PREFIX, "request", channel)
            SendDetailsOpenRaidKeystoneRequest(ctx, channel)
            SendDetailsPlayerInfoKeystoneRequest(ctx, channel)
        end
    end

    return true
end

local function HandleKeyStoneMasteryAddonMessage(ctx, message, sender)
    if type(message) ~= "string" or type(sender) ~= "string" then
        return
    end

    if message == ctx.KSM_GUILD_SYNC_REQUEST or message == "REQUEST_KEYS" or message == "req" then
        local playerName = ctx.GetNormalizedPlayerName(UnitName("player"))
        local senderName = ctx.GetNormalizedPlayerName(sender)
        if senderName and playerName and senderName ~= playerName then
            ctx.BroadcastOwnGuildSnapshot()
        end
        return
    end

    local payload = ParseGuildSyncPayload(ctx, message)
    if not payload then
        return
    end

    ctx.SaveGuildMemberData(sender, payload)
end

local function HandleAstralKeysAddonMessage(ctx, message)
    if type(message) ~= "string" then
        return
    end

    local function SaveAstralRecord(unit, classFile, dungeonID, keyLevel, mplusScore)
        if type(unit) ~= "string" or unit == "" then
            return
        end

        ctx.SaveGuildMemberData(unit, {
            class = NormalizeClassFile(ctx, classFile),
            mapID = ClampNumber(dungeonID, 0, 20000, 0),
            keyLevel = ClampNumber(keyLevel, 0, 50, 0),
            rating = ClampNumber(mplusScore, 0, 20000, 0),
            source = "astralkeys",
        })
    end

    local updatePayload = message:match("^updateV%d+%s+(.+)$")
    if updatePayload then
        local unit, classFile, dungeonID, keyLevel, _, _, mplusScore = strsplit(":", updatePayload)
        SaveAstralRecord(unit, classFile, dungeonID, keyLevel, mplusScore)
        return
    end

    local syncPayload = message:match("^sync%d+%s+(.+)$")
    if not syncPayload then
        return
    end

    if syncPayload:sub(-1) ~= "_" then
        syncPayload = syncPayload .. "_"
    end

    for entry in syncPayload:gmatch("([^_]+)_") do
        local unit, classFile, dungeonID, keyLevel, _, _, _, mplusScore = strsplit(":", entry)
        SaveAstralRecord(unit, classFile, dungeonID, keyLevel, mplusScore)
    end
end

local function HandleDetailsOpenRaidAddonMessage(ctx, message, sender)
    if type(message) ~= "string" or message == "" or type(sender) ~= "string" then
        return
    end

    local libDeflate = GetLibDeflateInstance(ctx)
    if not libDeflate then
        return
    end

    local decoded = libDeflate:DecodeForWoWAddonChannel(message)
    if type(decoded) ~= "string" then
        return
    end

    local inflated = libDeflate:DecompressDeflate(decoded)
    if type(inflated) ~= "string" or inflated == "" then
        return
    end

    local dataType, levelText, mapIDText, challengeMapIDText, classIDText, ratingText, mythicPlusMapIDText = strsplit(",", inflated)
    if dataType ~= ctx.DETAILS_OPENRAID_KEYSTONE_DATA_PREFIX then
        return
    end

    local level = tonumber(levelText) or 0
    local mapID = tonumber(challengeMapIDText) or tonumber(mythicPlusMapIDText) or tonumber(mapIDText) or 0
    local classID = tonumber(classIDText) or 0
    local classFile = ctx.CLASS_ID_TO_FILE[classID]
    local rating = tonumber(ratingText) or 0

    ctx.SaveGuildMemberData(sender, {
        class = classFile,
        mapID = mapID,
        keyLevel = level,
        rating = rating,
        source = "details-openraid",
    })
end

local function HandleDetailsPlayerInfoAddonMessage(ctx, message, sender)
    if type(message) ~= "string" or message == "" or type(sender) ~= "string" then
        return
    end

    local dataString = DecodeDeflatedBase64(message)
    if type(dataString) ~= "string" or dataString == "" then
        return
    end

    local dataType = dataString:sub(1, 1)
    if dataType == DETAILS_PLAYERINFO_KEYSTONE_PREFIX then
        SaveDetailsPlayerInfoKeystone(ctx, sender, dataString:sub(2))
        return
    end

    if dataType ~= DETAILS_PLAYERINFO_FULLINFO_PREFIX then
        return
    end

    local fullInfoPayload = dataString:sub(3)
    if fullInfoPayload == "" then
        return
    end

    for segment in fullInfoPayload:gmatch("([^#]+)") do
        local segmentType = segment:sub(1, 1)
        if segmentType == DETAILS_PLAYERINFO_KEYSTONE_PREFIX then
            SaveDetailsPlayerInfoKeystone(ctx, sender, segment:sub(2))
        end
    end
end

function Sync.HandleAddonMessage(ctx, prefix, message, channel, sender)
    if type(channel) ~= "string" or not sender then
        return
    end

    local isGuildChannel = channel == "GUILD"
    local isGroupChannel = channel == "PARTY" or channel == "RAID" or channel == "INSTANCE_CHAT"

    if prefix == ctx.KSM_ADDON_PREFIX and (isGuildChannel or isGroupChannel) then
        HandleKeyStoneMasteryAddonMessage(ctx, message, sender)
        ctx.RefreshKSMWindowIfVisible()
        return
    end

    if prefix == ctx.ASTRAL_KEYS_PREFIX and (isGuildChannel or isGroupChannel) then
        HandleAstralKeysAddonMessage(ctx, message)
        ctx.RefreshKSMWindowIfVisible()
        return
    end

    if prefix == DETAILS_PLAYERINFO_PREFIX and isGroupChannel then
        HandleDetailsPlayerInfoAddonMessage(ctx, message, sender)
        ctx.RefreshKSMWindowIfVisible()
    end
end

-- Integrate with LibOpenRaid-1.0 (bundled in Details).
-- Registers a KeystoneUpdate callback, drains any already-known keystones,
-- and requests fresh data from guild/party via the library's own wire protocol.
local libOpenRaidCallbacksRegistered = false

local function SaveLibOpenRaidKeystoneInfo(ctx, unitName, keystoneInfo)
    if type(unitName) ~= "string" or unitName == "" then
        return
    end
    if type(keystoneInfo) ~= "table" then
        return
    end

    local keyLevel = tonumber(keystoneInfo.level) or 0
    -- challengeMapID is the most reliable field for the dungeon map ID in LibOpenRaid
    local mapID = tonumber(keystoneInfo.challengeMapID)
        or tonumber(keystoneInfo.mythicPlusMapID)
        or tonumber(keystoneInfo.mapID)
        or 0
    local classID = tonumber(keystoneInfo.classID)
    local rating = tonumber(keystoneInfo.rating) or 0

    ctx.SaveGuildMemberData(unitName, {
        class = classID and ctx.CLASS_ID_TO_FILE[classID] or nil,
        mapID = mapID,
        keyLevel = keyLevel,
        rating = rating,
        source = "details-openraid",
    })
end

function Sync.RegisterLibOpenRaidCallbacks(ctx)
    if not LibStub then
        return false
    end

    local ok, openRaidLib = pcall(LibStub.GetLibrary, LibStub, "LibOpenRaid-1.0", true)
    if not ok or not openRaidLib then
        return false
    end

    -- Drain keystones already known to LibOpenRaid (e.g. from a previous group).
    if type(openRaidLib.GetAllKeystonesInfo) == "function" then
        local allKeystones = openRaidLib.GetAllKeystonesInfo()
        if type(allKeystones) == "table" then
            for unitName, keystoneInfo in pairs(allKeystones) do
                SaveLibOpenRaidKeystoneInfo(ctx, unitName, keystoneInfo)
            end
            ctx.RefreshKSMWindowIfVisible()
        end
    end

    -- Register KeystoneUpdate callback (fires when any group/guild member's keystone is received).
    if not libOpenRaidCallbacksRegistered and type(openRaidLib.RegisterCallback) == "function" then
        local callbackObject = {
            OnKeystoneUpdate = function(_, unitName, keystoneInfo)
                SaveLibOpenRaidKeystoneInfo(ctx, unitName, keystoneInfo)
                ctx.RefreshKSMWindowIfVisible()
            end,
        }
        pcall(openRaidLib.RegisterCallback, openRaidLib, callbackObject, "KeystoneUpdate", "OnKeystoneUpdate")
        libOpenRaidCallbacksRegistered = true
    end

    -- Request fresh keystone data from guild and current group.
    if type(openRaidLib.RequestKeystoneDataFromGuild) == "function" then
        pcall(openRaidLib.RequestKeystoneDataFromGuild, openRaidLib)
    end
    if type(openRaidLib.RequestKeystoneDataFromParty) == "function" then
        pcall(openRaidLib.RequestKeystoneDataFromParty, openRaidLib)
    end
    if type(openRaidLib.RequestKeystoneDataFromRaid) == "function" then
        pcall(openRaidLib.RequestKeystoneDataFromRaid, openRaidLib)
    end

    return true
end
