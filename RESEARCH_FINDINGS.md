## Research Disclaimer

The reference addons (**AstralKeys**, **MythicDungeonTools**, **MythicPlusTimer**) examined in this document were used **for research and analysis purposes only**. No code from these addons has been copied or directly incorporated into KeyStone Master. This research was conducted to understand industry-standard approaches to Mythic+ data retrieval and to identify optimal Blizzard API usage patterns. All KeyStone Master implementations are original code built independently based on findings from this research.

---

# Reference Addons: Mythic+ Score & Keystone Information Retrieval

## Executive Summary

Examined three major reference addons (**AstralKeys**, **MythicDungeonTools**, **MythicPlusTimer**) to understand how they retrieve, cache, and sync Mythic+ data across party/group members.

---

## 1. BLIZZARD APIs USED

### Primary APIs

#### For Player Data Retrieval:
```lua
-- Get owned keystone info
C_MythicPlus.GetOwnedKeystoneChallengeMapID()
C_MythicPlus.GetOwnedKeystoneLevel()

-- Get Mythic+ rating summary (includes score)
C_PlayerInfo.GetPlayerMythicPlusRatingSummary('player')
  -- Returns: currentSeasonScore, lifetimeScore, etc.

-- Get run history for weekly best
C_MythicPlus.GetRunHistory(false, true)
  -- Returns: array of runs with thisWeek flag and level
  -- Used to determine weekly best run

-- Request rewards (triggers data refresh)
C_MythicPlus.RequestRewards()

-- Challenge mode info
C_ChallengeMode.GetMapUIInfo(mapID)
C_ChallengeMode.GetActiveKeystoneInfo()
```

#### For Cross-Player Information:
```lua
-- Guild roster (to get guild members)
C_GuildInfo.GuildRoster()

-- Player info for other players (LIMITED)
C_PlayerInfo.GetPlayerMythicPlusRatingSummary('unit')
  -- NOTE: Only works for 'player', cannot retrieve for other units
```

### Key Limitation
**Blizzard APIs cannot directly retrieve Mythic+ data for party members or cross-player units.** This forces all addons to use **custom addon communication** for syncing group/guild data.

---

## 2. ADDON COMMUNICATION PATTERNS

### AstralKeys: Multi-Channel Syncing Strategy

#### Communication Channels Used:
1. **GUILD Channel** - For guild-wide key sharing
2. **BNET (Battle.net)** - For friends across realms
3. **WHISPER** - For targeted friend communication
4. **PARTY Channel** - For visible announcements (chat-based)

#### Message Prefix Registration:
```lua
-- Communications.lua
addon.UPDATE_VERSION = 'updateV8'  -- Version control for compatibility

-- Handlers registered:
AstralComs:RegisterPrefix('GUILD', 'versionRequest', VersionRequest)
AstralComs:RegisterPrefix('GUILD', 'versionPush', VersionPush)
AstralComs:RegisterPrefix('GUILD', 'request', AstralKeys_PushKeyList)
```

#### Message Queue System:
- Messages queued and sent with **rate limiting** to prevent spam
- Different send intervals based on context:
  - **Normal**: 0.2 seconds + random variance (±0.001-0.100)
  - **Raid instance**: 1 second (slower to prevent disconnects)
  - **Version checks**: 2 seconds

#### Code Location: `Communications.lua` (lines 1-290+)
```lua
SEND_INTERVAL = {}
SEND_INTERVAL[1] = 0.2 + SEND_VARIANCE  -- Normal
SEND_INTERVAL[2] = 1 + SEND_VARIANCE    -- Raid
SEND_INTERVAL[3] = 2                     -- Version check

function AstralComs:OnUpdate(elapsed)
	self.delay = self.delay + elapsed
	if self.delay < SEND_INTERVAL[SEND_INTERVAL_SETTING] + self.loadDelay then
		return
	end
	self:SendMessage()  -- Dequeued from queue table
end
```

---

## 3. DATA STRUCTURE & MESSAGE FORMAT

### Keystone Data Message Format

**Location**: `Keystone.lua:134`

```lua
-- Format: PlayerName : PlayerClass : MapID : KeyLevel : WeeklyBest : Week : MplusScore : Faction
msg = string.format('%s:%s:%d:%d:%d:%d:%s', 
    addon.Player(),              -- PlayerName-Realm
    addon.PlayerClass(),         -- class name (WARRIOR, MAGE, etc)
    mapID,                       -- dungeon map ID
    keyLevel,                    -- current key level
    weeklyBest,                  -- best completed this week
    addon.Week,                  -- week number for season
    mplusScore,                  -- M+ rating score
    addon.FACTION                -- 0 = Alliance, 1 = Horde
)
```

### Saved Data Structure

**Location**: `Unit Information.lua` and `Character Info.lua`

```lua
-- Global tables storing data
AstralKeys = {
    {
        unit = "PlayerName-Realm",
        class = "WARRIOR",
        dungeon_id = 375,
        key_level = 20,
        week = 50,
        time_stamp = 1234567890,
        weekly_best = 20,
        mplus_score = 3847,
        faction = 1,
        btag = "PlayerName#1234"  -- BattleTag for friends
    }
}

AstralCharacters = {
    {
        unit = "PlayerName-Realm",
        class = "WARRIOR",
        weekly_best = 20,
        mplus_score = 3847,
        faction = 1
    }
}

-- Unit ID mapping (quick lookup)
UNIT_LIST = {
    ["PlayerName-Realm"] = 1  -- maps to AstralKeys[1]
}
```

---

## 4. DATA RETRIEVAL & CACHING STRATEGY

### Initial Data Load

**Location**: `AstralKeys.lua:RefreshData()` (lines 45-72)

```lua
function addon.RefreshData()
	local elapsed = time() - addon.refreshTime
	
	-- Only refresh if 30+ seconds elapsed
	if addon.refreshTime == 0 or (elapsed >= ASTRAL_KEYS_REFRESH_INTERVAL) then
		addon.WipeCharacterList()
		addon.WipeUnitList()
		addon.WipeFriendList()
		C_MythicPlus.RequestRewards()          -- Trigger API data refresh
		
		-- Clear and rebuild caches
		AstralCharacters = {}
		AstralKeys = {}
		AstralKeysSettings.general.init_time = addon.DataResetTime()
		
		addon.PushKeystone(false)               -- Announce own key
		addon.UpdateAffixes()
		
		if IsInGuild() then
			C_GuildInfo.GuildRoster()
		end
		
		addon.SetPlayerNameRealm()
		addon.SetPlayerClass()
		InitKeystoneData()
		
		addon.refreshTime = time()
		return true
	end
	return false
end
```

### Continuous Updates

**Location**: `Keystone.lua:UpdateWeekly()` (lines 23-42)

```lua
local function UpdateWeekly()
	addon.UpdateCharacterBest()
	
	local characterID = addon.GetCharacterID(addon.Player())
	local characterWeeklyBest = addon.GetCharacterBestLevel(characterID)
	local characterScore = addon.GetCharacterMplusScore(characterID)
	
	if IsInGuild() then
		-- Send to guild via addon message
		AstralComs:NewMessage('AstralKeys', 'updateWeekly ' .. characterWeeklyBest, 'GUILD')
	else
		-- Self-update if not in guild
		local id = addon.UnitID(addon.Player())
		if id then
			AstralKeys[id].weekly_best = characterWeeklyBest
			AstralKeys[id].mplus_score = characterScore
		end
	end
	addon.UpdateCharacterFrames()
end
```

### Update Triggers

**Location**: `Keystone.lua:249-290`

```lua
-- Refresh on challenge complete
AstralEvents:Register('CHALLENGE_MODE_COMPLETED', function()
	C_Timer.After(3, function() addon.CheckKeystone() end)
end)

-- Refresh on item change (when key removed/added)
AstralEvents:Register('ITEM_CHANGED', function()
	C_Timer.After(3, function() addon.CheckKeystone() end)
end)

-- Refresh after combat (delayed update)
AstralEvents:Register('PLAYER_REGEN_ENABLED', function() 
	C_Timer.After(3, function() addon.CheckKeystone() end)
end)

-- Refresh on npc gossip
AstralEvents:Register('GOSSIP_CLOSED', function()
	if IsInGuild() then
		C_GuildInfo.GuildRoster()
	end
end)
```

---

## 5. CROSS-PLAYER INFORMATION ACCESS

### Methods to Obtain Party/Group Member Data

#### Guild Members:
```lua
-- Request guild roster
C_GuildInfo.GuildRoster()

-- Then share own data via guild channel
if IsInGuild() then
    AstralComs:NewMessage('AstralKeys', msg, 'GUILD')
end

-- Members respond with same format
```

#### BattleTag Friends (Cross-Realm):
```lua
-- Detect friends online
BNConnected()
select(3, BNGetGameAccountInfo(friendID))  -- Check if logged into WoW

-- Send via BNET addon messages
msg.method = BNSendGameData
msg[1] = friendIdx
msg[2] = 'AstralKeys'  -- prefix
msg[3] = keyData        -- message content
```

#### Whisper-Based (Targeted):
```lua
-- Send to specific player
SendAddonMessage('AstralKeys', msg, 'WHISPER', targetPlayer)

-- Only if they're online (checked before sending)
if addon.IsFriendOnline(msg[4]) then
    msg.method(unpack(msg, 1, #msg))
end
```

### Instance Group Handling

```lua
-- Detect instance type
local inInstance, instanceType = IsInInstance()

-- If raid, use slower send intervals to avoid DC
if inInstance and instanceType == 'raid' then
    SEND_INTERVAL_SETTING = 2  -- Use 1 second interval instead of 0.2
end

-- Pause sending during boss fights
AstralEvents:Register('ENCOUNTER_START', function()
    AstralComs:UnregisterPrefix('GUILD', 'request')
end)

AstralEvents:Register('ENCOUNTER_END', function()
    AstralComs:RegisterPrefix('GUILD', 'request', AstralKeys_PushKeyList)
end)
```

---

## 6. COMPARISON: OTHER ADDONS

### MythicDungeonTools
- **Focus**: Dungeon route planning and visualization
- **M+ Data**: Uses `C_ChallengeMode.GetActiveKeystoneInfo()` for **active dungeon only**
- **Cross-player**: Minimal, primarily personal tracking
- **No guild/friend syncing** for keystone data

### MythicPlusTimer
- **Focus**: Real-time timer tracking during dungeons
- **M+ Data**: Uses `C_ChallengeMode.GetActiveKeystoneInfo()` for active run
- **Cross-player**: None (self-only)
- **Chat-based**: Broadcasts timer updates via CHAT_MSG (not addon messages)
- **Use**: `local cm_level, affixes = C_ChallengeMode.GetActiveKeystoneInfo()`

---

## 7. KEY INSIGHTS FOR IMPLEMENTATION

### What Works Well:
1. **Message Versioning** - `updateV8` allows backward compatibility and phased rollouts
2. **Rate Limiting** - Prevents addon spam and disconnects during raids
3. **Multiple Channels** - Guild, Friends, and self-contained fallback
4. **Event-Driven Updates** - Listens to relevant game events rather than polling
5. **Week-Based Expiry** - Automatically clears data on reset day

### Limitations Exposed:
1. **No Cross-Realm Self-Updates** - Cannot query friend's M+ data directly, must receive via sync
2. **Manual Sync Required** - Friends must have addon and opt-in to sharing
3. **Data Staleness** - Cached data only updates when:
   - User logs in
   - User completes/starts dungeon
   - User explicitly requests
   - Addon message received from other player
4. **Guild Only** - Non-guild members cannot share data unless using friend sync
5. **Chat-Based Fallback** - Resorts to party/guild chat announcements when addon messages fail

### Recommended for KeyStoneMastery:
- Use **same message format** for compatibility with AstralKeys data
- Implement **guild channel syncing** as primary method
- Add **optional BattleTag friend sync** for cross-realm parties
- Use **C_PlayerInfo.GetPlayerMythicPlusRatingSummary('player')** for self only
- Cache with **weekly expiry** similar to AstralKeys
- Listen to **CHALLENGE_MODE_COMPLETED** event for updates

---

## 8. CODE SNIPPET EXAMPLES

### Retrieving Own M+ Score:
```lua
local mplusSummary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary('player')
local mplusScore = mplusSummary.currentSeasonScore
```

### Getting Weekly Best:
```lua
local weeklyBest = 0
local runHistory = C_MythicPlus.GetRunHistory(false, true)
for i = 1, #runHistory do
    if runHistory[i].thisWeek and runHistory[i].level > weeklyBest then
        weeklyBest = runHistory[i].level
    end
end
```

### Sending Guild Sync:
```lua
if IsInGuild() then
    local msg = string.format('%s:%s:%d:%d:%d:%d:%s:%d',
        UnitName('player') .. '-' .. GetRealmName():gsub("%s+", ""),
        select(2, UnitClass('player')),
        mapID,
        keyLevel,
        weeklyBest,
        weekNumber,
        mplusScore,
        faction
    )
    SendAddonMessage('AstralKeys', 'updateV8 ' .. msg, 'GUILD')
end
```

---

## 9. MESSAGE FLOW DIAGRAM

```
┌─────────────────────────────────────────────────────────┐
│ Initial Load (PLAYER_LOGIN)                             │
├─────────────────────────────────────────────────────────┤
│ 1. C_MythicPlus.RequestRewards() - fetch data           │
│ 2. C_PlayerInfo.GetPlayerMythicPlusRatingSummary()     │
│ 3. C_MythicPlus.GetRunHistory(false, true)             │
│ 4. Build message: "Player:Class:Map:Level:Best:Week:Score:Faction"
│ 5. Send via SendAddonMessage('AstralKeys', msg, 'GUILD')
│ 6. Store in AstralKeys[] and AstralCharacters[]        │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│ Incoming Message Handler (CHAT_MSG_ADDON)              │
├─────────────────────────────────────────────────────────┤
│ 1. Parse message by ':'                                │
│ 2. Validate sender in guild/friends list               │
│ 3. Update AstralKeys[unitID] with new data            │
│ 4. Update display frames with GetCharacterBestLevel()  │
│ 5. Store with timestamp for weekly expiry check        │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│ Continuous Updates (Events)                            │
├─────────────────────────────────────────────────────────┤
│ CHALLENGE_MODE_COMPLETED                               │
│ ITEM_CHANGED (keystone pickup/drop)                   │
│ PLAYER_REGEN_ENABLED (after combat)                   │
│ GOSSIP_CLOSED (NPC interaction)                       │
│ → All trigger addon.CheckKeystone() → PushKeystone()   │
└─────────────────────────────────────────────────────────┘
```

---

## Summary Table

| Aspect | Implementation |
|--------|-----------------|
| **API Used for Self** | C_PlayerInfo.GetPlayerMythicPlusRatingSummary('player') |
| **API Used for Others** | None (impossible) - must use addon sync |
| **Guild Sync Channel** | GUILD channel via SendAddonMessage |
| **Cross-Realm Friends** | BattleTag via BNSendGameData |
| **Message Format** | Player:Class:MapID:Level:WeeklyBest:Week:Score:Faction |
| **Send Rate (Normal)** | 0.2s + random variance |
| **Send Rate (Raid)** | 1.0s |
| **Data Expiry** | Weekly (automatic wipe on reset) |
| **Primary Triggers** | Challenge complete, item change, player login |
| **Fallback Method** | Chat-based announcements (not addon messages) |

