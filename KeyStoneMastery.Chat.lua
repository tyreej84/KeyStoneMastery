local ns = _G.KeyStoneMasteryNS
if type(ns) ~= "table" then
    ns = {}
    _G.KeyStoneMasteryNS = ns
end

local Chat = {}
ns.Chat = Chat

function Chat.BuildReplyForCommand(ctx, command)
    if type(command) ~= "string" or command == "" then
        return nil
    end

    if command == ctx.KEY_TEXT_COMMAND or command == ctx.KEYS_TEXT_COMMAND then
        return ctx.BuildKeystoneReply()
    end

    if command == ctx.SCORE_TEXT_COMMAND or command == ctx.SCORES_TEXT_COMMAND then
        return ctx.BuildScoreReply()
    end

    if command == ctx.BEST_TEXT_COMMAND then
        return ctx.BuildBestReply()
    end

    return nil
end

function Chat.UpdateGuildMemberFromChatKeystoneLink(ctx, message, sender)
    if type(sender) ~= "string" then
        return
    end

    if ctx.CanReadChatPayload and not ctx.CanReadChatPayload(message) then
        return
    end

    local ok, mapID, keyLevel = pcall(ctx.ParseKeystoneFromMessage, message)
    if not ok then
        return
    end

    if type(keyLevel) ~= "number" or keyLevel <= 0 then
        return
    end

    if type(mapID) ~= "number" or mapID <= 0 then
        mapID = 0
    end

    ctx.SaveGuildMemberData(sender, {
        mapID = mapID,
        keyLevel = keyLevel,
        source = "guild-chat-link",
    })
end

function Chat.ExtractCommandWithFallback(ctx, message)
    local command = ctx.ExtractRequestCommand and ctx.ExtractRequestCommand(message) or nil
    if command then
        return command
    end

    if type(message) ~= "string" then
        return nil
    end

    local ok, normalized = pcall(function(rawMessage)
        return ctx.strtrim(ctx.strlower(rawMessage))
            :gsub("|c%x%x%x%x%x%x%x%x", "")
            :gsub("|r", "")
    end, message)
    if not ok or type(normalized) ~= "string" or normalized == "" then
        return nil
    end

    local parsed = normalized:match("^(![%a]+)") or normalized:match("%s(![%a]+)")
    if type(parsed) ~= "string" then
        if normalized:find("!keys", 1, true) then
            return ctx.KEYS_TEXT_COMMAND
        end
        if normalized:find("!score", 1, true) or normalized:find("!scores", 1, true) then
            return ctx.SCORES_TEXT_COMMAND
        end
        if normalized:find("!best", 1, true) then
            return ctx.BEST_TEXT_COMMAND
        end
        return nil
    end

    parsed = parsed:gsub("[,%.%?!;:]+$", "")
    if parsed == ctx.KEY_TEXT_COMMAND
        or parsed == ctx.KEYS_TEXT_COMMAND
        or parsed == ctx.SCORE_TEXT_COMMAND
        or parsed == ctx.SCORES_TEXT_COMMAND
        or parsed == ctx.BEST_TEXT_COMMAND then
        return parsed
    end

    return nil
end

local function BuildFallbackReply(ctx, command)
    local prefix = ctx.REPLY_PREFIX or "KSM:"
    if command == ctx.KEY_TEXT_COMMAND or command == ctx.KEYS_TEXT_COMMAND then
        return string.format("%s Keystone unavailable", prefix)
    end

    if command == ctx.SCORE_TEXT_COMMAND or command == ctx.SCORES_TEXT_COMMAND then
        return string.format("%s M+ Score unavailable", prefix)
    end

    if command == ctx.BEST_TEXT_COMMAND then
        return string.format("%s Best run unavailable", prefix)
    end

    return nil
end

function Chat.HandleChatMessage(ctx, event, message, sender)
    if not ctx.CHAT_EVENTS[event] then
        return
    end

    -- Do not gate on combat lockdown here: SendOrQueueChatMessage will defer
    -- the reply until combat ends, so commands typed in combat still get a reply.

    if type(message) ~= "string" then
        return
    end

    local normalizedMessage = message

    pcall(Chat.UpdateGuildMemberFromChatKeystoneLink, ctx, normalizedMessage, sender)

    local okCommand, command = pcall(Chat.ExtractCommandWithFallback, ctx, normalizedMessage)
    if not okCommand then
        command = nil
    end
    if not command then
        ctx.RefreshKSMWindowIfVisible()
        return
    end

    local ok, reply = pcall(Chat.BuildReplyForCommand, ctx, command)
    if not ok or not reply then
        reply = BuildFallbackReply(ctx, command)
        if not reply then
            return
        end
    end

    local chatType = ctx.CHAT_EVENT_TO_CHANNEL[event]
    if not chatType then
        return
    end

    ctx.SendOrQueueChatMessage(reply, chatType)

    if event == "CHAT_MSG_GUILD" and (command == ctx.KEY_TEXT_COMMAND or command == ctx.KEYS_TEXT_COMMAND) then
        -- Keep sync-request failures from blocking the visible chat reply.
        pcall(ctx.RequestGuildSnapshots)
    end

    ctx.RefreshKSMWindowIfVisible()
end
