local ns = _G.KeyStoneMasteryNS
if type(ns) ~= "table" then
    ns = {}
    _G.KeyStoneMasteryNS = ns
end

local function trim(s)
    if type(strtrim) == "function" then
        return strtrim(s)
    end
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local function IsReadableStringValue(value)
    if type(value) ~= "string" then
        return false
    end

    if type(canaccessvalue) == "function" then
        local ok, canRead = pcall(canaccessvalue, value)
        if not ok or canRead ~= true then
            return false
        end
    end

    local ok, length = pcall(string.len, value)
    if not ok then
        return false
    end

    return type(length) == "number" and length > 0
end

function ns.NormalizeDungeonName(name)
    if type(name) ~= "string" then
        return nil
    end

    local normalized = string.lower(name)
        :gsub("|c%x%x%x%x%x%x%x%x", "")
        :gsub("|r", "")
        :gsub("[^%a%d%s'%-]", "")
        :gsub("%s+", " ")
    normalized = trim(normalized)

    if normalized == "" then
        return nil
    end

    return normalized
end

function ns.ResolveMapIDFromDungeonName(dungeonName)
    local target = ns.NormalizeDungeonName(dungeonName)
    if not target then
        return nil
    end

    if C_ChallengeMode and C_ChallengeMode.GetMapTable and C_ChallengeMode.GetMapUIInfo then
        local ok, mapTable = pcall(C_ChallengeMode.GetMapTable)
        if ok and type(mapTable) == "table" then
            for _, mapID in ipairs(mapTable) do
                local mapName
                local mapOk, result1 = pcall(C_ChallengeMode.GetMapUIInfo, mapID)
                if mapOk then
                    if type(result1) == "table" then
                        mapName = result1.name or result1.mapName
                    else
                        mapName = result1
                    end
                end
                if ns.NormalizeDungeonName(mapName) == target then
                    return tonumber(mapID) or nil
                end
            end
        end
    end

    return nil
end

function ns.ParseKeystoneFromMessage(message)
    if not IsReadableStringValue(message) then
        return nil, nil
    end

    local ok, parsedMapID, parsedLevel = pcall(function(rawMessage)
        local linkData = rawMessage:match("|Hkeystone:([^|]+)|h")
        if type(linkData) == "string" and linkData ~= "" then
            local _, mapIDText, keyLevelText = linkData:match("^(%d+):(%d+):(%d+)")
            local mapID = tonumber(mapIDText) or 0
            local keyLevel = tonumber(keyLevelText) or 0
            if mapID > 0 and keyLevel > 0 then
                return mapID, keyLevel
            end
        end

        local dungeonName, keyLevelText = rawMessage:match("%[Keystone:%s*(.-)%s*%((%d+)%)%]")
        if type(dungeonName) == "string" and type(keyLevelText) == "string" then
            local keyLevel = tonumber(keyLevelText) or 0
            local mapID = ns.ResolveMapIDFromDungeonName(dungeonName) or 0
            if keyLevel > 0 then
                if mapID > 0 then
                    return mapID, keyLevel
                end
                return nil, keyLevel
            end
        end

        -- Generic fallback for addon/user-facing link text variants.
        local genericName, genericLevelText = rawMessage:match("%[([^%[%]]-)%s*%(([%+]?%d+)%)%]")
        if type(genericName) == "string" and type(genericLevelText) == "string" then
            local normalizedName = trim(genericName)
            normalizedName = normalizedName:gsub("^[Kk]eystone:%s*", "")
            normalizedName = normalizedName:gsub("^[Mm]ythic%s+[Kk]eystone:%s*", "")
            normalizedName = trim(normalizedName)

            local keyLevel = tonumber((genericLevelText:gsub("^%+", ""))) or 0
            local mapID = ns.ResolveMapIDFromDungeonName(normalizedName) or 0
            if keyLevel > 0 then
                if mapID > 0 then
                    return mapID, keyLevel
                end
                return nil, keyLevel
            end
        end

        local plusName, plusLevelText = rawMessage:match("%[([^%[%]]-)%s*%+(%d+)%]")
        if type(plusName) == "string" and type(plusLevelText) == "string" then
            local normalizedName = trim(plusName)
            normalizedName = normalizedName:gsub("^[Kk]eystone:%s*", "")
            normalizedName = normalizedName:gsub("^[Mm]ythic%s+[Kk]eystone:%s*", "")
            normalizedName = trim(normalizedName)

            local keyLevel = tonumber(plusLevelText) or 0
            local mapID = ns.ResolveMapIDFromDungeonName(normalizedName) or 0
            if keyLevel > 0 then
                if mapID > 0 then
                    return mapID, keyLevel
                end
                return nil, keyLevel
            end
        end

        local lowerMessage = string.lower(rawMessage)
        if lowerMessage:find("astral keys", 1, true) or lowerMessage:find("astralkeys", 1, true) then
            local astralDungeonName, astralKeyLevelText = rawMessage:match("%[([^%[%]]-)%s*%((%d+)%)%]")
            if type(astralDungeonName) == "string" and type(astralKeyLevelText) == "string" then
                local keyLevel = tonumber(astralKeyLevelText) or 0
                local mapID = ns.ResolveMapIDFromDungeonName(astralDungeonName) or 0
                if keyLevel > 0 then
                    if mapID > 0 then
                        return mapID, keyLevel
                    end
                    return nil, keyLevel
                end
            end
        end

        return nil, nil
    end, message)

    if not ok then
        return nil, nil
    end

    return parsedMapID, parsedLevel
end

function ns.FormatSeconds(seconds)
    if type(seconds) ~= "number" then
        seconds = 0
    end

    seconds = math.max(0, math.floor(seconds + 0.5))

    local minutes = math.floor(seconds / 60)
    local remainder = seconds % 60

    return string.format("%02d:%02d", minutes, remainder)
end

function ns.FormatSignedSeconds(seconds)
    if type(seconds) ~= "number" then
        return ns.FormatSeconds(0)
    end

    if seconds < 0 then
        return string.format("-%s", ns.FormatSeconds(-seconds))
    end

    return ns.FormatSeconds(seconds)
end

function ns.ParsePercentValue(text)
    if type(text) ~= "string" then
        return nil
    end

    local normalizedText = text
        :gsub("|c%x%x%x%x%x%x%x%x", "")
        :gsub("|r", "")
        :gsub(",", ".")
    local percentText = normalizedText:match("(%d+%.?%d*)%s*%%")
    if percentText then
        return tonumber(percentText)
    end

    return nil
end

function ns.BuildKeystoneSnapshotKey(mapID, keyLevel)
    if type(mapID) ~= "number" or type(keyLevel) ~= "number" then
        return "none"
    end

    return string.format("%d:%d", mapID, keyLevel)
end

function ns.ExtractRequestCommand(message)
    if not ns.CanReadChatPayload(message) then
        return nil
    end

    local requestSet = ns.REQUEST_COMMAND_SET or {}
    local ok, command = pcall(function(rawMessage)
        local msg = trim(string.lower(rawMessage))
        msg = msg:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")

        local parsed = msg:match("^(![%a]+)") or msg:match("%s(![%a]+)")
        if type(parsed) ~= "string" then
            return nil
        end

        parsed = parsed:gsub("[,%.%?!;:]+$", "")
        if requestSet[parsed] then
            return parsed
        end

        return nil
    end, message)

    if ok then
        return command
    end

    return nil
end

function ns.CanReadChatPayload(message)
    return IsReadableStringValue(message)
end
