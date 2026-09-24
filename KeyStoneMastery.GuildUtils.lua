local ns = _G.KeyStoneMasteryNS
if type(ns) ~= "table" then
    ns = {}
    _G.KeyStoneMasteryNS = ns
end

function ns.IsPlayerInGuildSafe()
    if IsInGuild and IsInGuild() then
        return true
    end

    if GetGuildInfo then
        local guildName = GetGuildInfo("player")
        if type(guildName) == "string" and guildName ~= "" then
            return true
        end
    end

    return false
end

function ns.RequestGuildRosterSafe()
    if GuildRoster then
        pcall(GuildRoster)
        return true
    end

    if C_GuildInfo and C_GuildInfo.GuildRoster then
        pcall(C_GuildInfo.GuildRoster)
        return true
    end

    return false
end

function ns.GetNumGuildMembersSafe()
    if GetNumGuildMembers then
        local totalMembers = select(1, GetNumGuildMembers())
        return tonumber(totalMembers) or 0
    end

    if C_GuildInfo and C_GuildInfo.GetNumGuildMembers then
        local ok, count = pcall(C_GuildInfo.GetNumGuildMembers)
        if ok then
            return tonumber(count) or 0
        end
    end

    return 0
end

function ns.GetGuildMemberLastOnlineDays(index, isOnline)
    if isOnline then
        return 0
    end

    if not GetGuildRosterLastOnline then
        return nil
    end

    local years, months, days, hours = GetGuildRosterLastOnline(index)
    if type(years) ~= "number" or type(months) ~= "number" or type(days) ~= "number" or type(hours) ~= "number" then
        return nil
    end

    return (years * 365) + (months * 30) + days + (hours / 24)
end

function ns.IsGuildMemberRecent(index, isOnline, cachedEntry)
    local recentDays = tonumber(ns.KSM_GUILD_RECENT_DAYS) or 7
    local lastOnlineDays = ns.GetGuildMemberLastOnlineDays(index, isOnline)
    if type(lastOnlineDays) == "number" then
        return lastOnlineDays <= recentDays
    end

    local updatedAt = cachedEntry and tonumber(cachedEntry.updatedAt)
    if updatedAt then
        local now = (GetServerTime and GetServerTime()) or time()
        return (now - updatedAt) <= (recentDays * 86400)
    end

    return isOnline and true or false
end
