local ns = _G.KeyStoneMasteryNS
if type(ns) ~= "table" then
    ns = {}
    _G.KeyStoneMasteryNS = ns
end

ns.REPLY_PREFIX = "KSM:"
ns.KEYSTONE_ITEM_IDS = { [180653] = true, [158923] = true, [151086] = true }
ns.KEYSTONE_BAG_SLOTS = { Enum.BagIndex.Backpack, Enum.BagIndex.Bag_1, Enum.BagIndex.Bag_2, Enum.BagIndex.Bag_3, Enum.BagIndex.Bag_4 }
ns.KSM_PORTAL_SPELL_IDS = {
    [249] = 1286831, -- King's Rest
    [250] = 1286828, -- Temple of Sethraliss
    [399] = 393256, -- Ruby Life Pools
    [584] = 1286801, -- The Blinding Vale
    [585] = 1286804, -- Voidscar Arena
    [586] = 1286807, -- Den of Nalorakk
    [587] = 1286809, -- Murder Row
    [588] = 1286812, -- Altar of Fangs
}
-- No Horde-specific portal overrides for the current season (Season 2 Midnight).
-- Populate this table when a future season includes a dungeon with distinct Horde/Alliance portal spells.
ns.KSM_PORTAL_SPELL_IDS_HORDE = {}
ns.KEYS_TEXT_COMMAND = "!keys"
ns.KEY_TEXT_COMMAND = "!key"
ns.SCORE_TEXT_COMMAND = "!score"
ns.SCORES_TEXT_COMMAND = "!scores"
ns.BEST_TEXT_COMMAND = "!best"
ns.KSM_ADDON_PREFIX = "KeyStoneMastery"
ns.KSM_GUILD_SYNC_VERSION = "g1"
ns.KSM_GUILD_SYNC_REQUEST = "req1"
ns.ASTRAL_KEYS_PREFIX = "AstralKeys"
ns.DETAILS_OPENRAID_PREFIX = "LRS"
ns.DETAILS_OPENRAID_KEYSTONE_REQUEST_PREFIX = "J"
ns.DETAILS_OPENRAID_KEYSTONE_DATA_PREFIX = "K"
ns.DETAILS_PLAYERINFO_PREFIX = "PITB"
ns.DETAILS_PLAYERINFO_REQUEST_PREFIX = "R"
ns.DETAILS_PLAYERINFO_FULLINFO_PREFIX = "F"
ns.DETAILS_PLAYERINFO_KEYSTONE_PREFIX = "K"
ns.CLASS_ID_TO_FILE = {
    [1] = "WARRIOR",
    [2] = "PALADIN",
    [3] = "HUNTER",
    [4] = "ROGUE",
    [5] = "PRIEST",
    [6] = "DEATHKNIGHT",
    [7] = "SHAMAN",
    [8] = "MAGE",
    [9] = "WARLOCK",
    [10] = "MONK",
    [11] = "DRUID",
    [12] = "DEMONHUNTER",
    [13] = "EVOKER",
}
ns.KSM_VAULT_TEXTURE_EMPTY = "Interface\\AddOns\\KeyStoneMastery\\Assets\\UI\\Vault.png"
ns.KSM_VAULT_TEXTURE_GLOWY = "Interface\\AddOns\\KeyStoneMastery\\Assets\\UI\\Vault_Glowy.png"
ns.REQUEST_COMMAND_SET = {
    ["!key"] = true,
    ["!keys"] = true,
    ["!score"] = true,
    ["!scores"] = true,
    ["!best"] = true,
}
ns.MISMATCH_TOAST_COOLDOWN_SECONDS = 2
ns.UI_REFRESH_INTERVAL_SECONDS = 0.2
ns.COMPLETION_DISPLAY_SECONDS = 90
ns.CHALLENGERS_PERIL_AFFIX_ID = 152
ns.BREAK_TIMER_BLUE = { 0.15, 0.55, 1.00, 0.90 }
ns.KSM_GUILD_RECENT_DAYS = 7
ns.CHAT_EVENTS = {
    CHAT_MSG_PARTY = true,
    CHAT_MSG_PARTY_LEADER = true,
    CHAT_MSG_RAID = true,
    CHAT_MSG_RAID_LEADER = true,
    CHAT_MSG_INSTANCE_CHAT = true,
    CHAT_MSG_INSTANCE_CHAT_LEADER = true,
    CHAT_MSG_GUILD = true,
    CHAT_MSG_OFFICER = true,
}
ns.CHAT_EVENT_TO_CHANNEL = {
    CHAT_MSG_PARTY = "PARTY",
    CHAT_MSG_PARTY_LEADER = "PARTY",
    CHAT_MSG_RAID = "RAID",
    CHAT_MSG_RAID_LEADER = "RAID",
    CHAT_MSG_INSTANCE_CHAT = "INSTANCE_CHAT",
    CHAT_MSG_INSTANCE_CHAT_LEADER = "INSTANCE_CHAT",
    CHAT_MSG_GUILD = "GUILD",
    CHAT_MSG_OFFICER = "OFFICER",
}
ns.MAX_DEFERRED_CHAT_MESSAGES = 10
ns.DEFAULT_DB = {
    ui = {
        enabled = true,
        hideTrackerInMythicPlus = true,
        hideOfflineGuild = false,
        locked = true,
        hidden = false,
        scale = 1,
        point = { "TOPRIGHT", "UIParent", "TOPRIGHT", -24, -210 },
    },
    guild = {
        members = {},
    },
}

-- Early fallback slash bindings: if later addon files error, users still get a KeyStoneMastery response.
local function KeyStoneMasteryEarlySlashFallback(command)
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff98KSM:|r core did not fully initialize. Check Lua errors, then /reload.")
    end
end

if type(SlashCmdList) == "table" then
    if type(SlashCmdList.KEYSTONEMASTERY) ~= "function" then
        SLASH_KEYSTONEMASTERY1 = "/keystonemastery"
        SLASH_KEYSTONEMASTERY2 = "/km"
        SlashCmdList.KEYSTONEMASTERY = KeyStoneMasteryEarlySlashFallback
    end

    if type(SlashCmdList.KEYSTONEMASTERYDASHBOARD) ~= "function" then
        SLASH_KEYSTONEMASTERYDASHBOARD1 = "/ksm"
        SlashCmdList.KEYSTONEMASTERYDASHBOARD = KeyStoneMasteryEarlySlashFallback
    end
end
