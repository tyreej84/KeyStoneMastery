# Changelog

All notable changes to this project will be documented in this file.

## [2.1.0] - 2026-09-26

### Fixed
- Starting a key soon after finishing another no longer announces the depleted keystone as a new key.
- Party chat lines held back by chat restrictions are now dropped after 5 minutes instead of being posted much later, such as mid-run.

### Validation
- Added mocked regressions for start-of-run depletion inside the post-run window and for stale queued chat lines. Live behavior still requires in-game verification.

## [2.0.9] - 2026-09-26

### Fixed
- New keys are now announced to the party when swapped at the keystone NPC after a timed run. Previously the swap was never detected.
- Keystone changes after a completed run (upgrade, downgrade, swap, or picking up a new key) are announced for 15 minutes after completion, instead of only on a single check 3 seconds after the run ended.
- Picking up a key after having none is now announced.

### Validation
- Added mocked regressions for the completion upgrade, post-run swap, key gained from none, key lost, and changes outside the post-run window. Live announcements still require in-game verification.

## [2.0.8] - 2026-09-26

### Fixed
- The new-keystone party announcement no longer fires while chat is restricted after a key ends. Chat lines now wait until the restriction lifts (including its activating phase), retry automatically, and are dropped if the group has disbanded.
- Chat sends now use the current chat API instead of the deprecated wrapper.

### Validation
- Added a mocked regression for restricted, activating, lifted, and left-group chat states. Live chat delivery after a key still requires in-game verification.

## [2.0.7] - 2026-09-24

### Fixed
- Removed restricted combat-log event registration, allowing startup to finish registering group and chat events.
- Kept death attribution through group-unit state checks and skipped restricted identity/death values.
- Stopped replacing the objective tracker's Show method and reparenting its frames. Tracker suppression now preserves its original alpha and defers changes during combat.
- Moved all addon tooltips to a private tooltip so addon hover handlers do not reuse Blizzard's world-map widget container.
- Guarded restricted scenario-timer values before comparing or caching them.

### Validation
- Added mocked startup, tracker, tooltip, and death-tracking regressions. Native UI taint behavior still requires in-game verification after reloading the updated addon.

## [2.0.6] - 2026-09-24

### Changed
- Renamed the addon folder, TOC, Lua modules, database, internal namespace, frame names, texture paths, and GitHub repository to KeyStoneMastery.
- Added `/keystonemastery` for help and settings; retained `/km` and the `/ksm` dashboard.
- Renamed the addon sync identifier. Direct sync between copies requires version 2.0.6 or newer on both sides.
- Added a Windows installer that backs up the previous installation and migrates existing settings while WoW is closed.
- Updated release packaging and current documentation for the new folder and file names.

## [2.0.5] - 2026-09-02

### Fixed
- Registered startup events through a direct call path to avoid protected-call failures.
- Forward-declared the guild snapshot broadcaster so retry callbacks always resolve the local function.

### Changed
- Standardized all current user-facing addon branding as **KeyStoneMastery** while retaining legacy internal identifiers for compatibility.

### Packaging
- Bumped TOC version to `2.0.5`.

## [2.0.4] - 2026-08-28

### Fixed
- Updated the `/ksm` Season Portals row to the eight Midnight Season 2 dungeons and their correct teleport spells.
- Prevented stale configured portals from being merged into Blizzard's current-season dungeon list and displacing valid tiles.
- Registered runtime events during the addon's initial loading context instead of from `ADDON_LOADED`, preventing the protected `Frame:RegisterEvent()` calls captured by BugGrabber.

### Packaging
- Bumped TOC version to `2.0.4`.

## [2.0.3] - 2026-08-10

### Changed
- Updated addon metadata for Retail patch 12.1.0 by setting TOC interface to `120100`.
- Reviewed current Mythic+, challenge-mode, chat, and addon-message API usage for 12.1.0 readiness.

### Packaging
- Bumped TOC version to `2.0.3`.

## [2.0.2] - 2026-06-18

### Fixed
- Guarded the external sync retry timer so `RegisterLibOpenRaidCallbacks` is only called after the local helper has been assigned, preventing the nil-call captured by BugGrabber.

### Packaging
- Bumped TOC version to `2.0.2`.

## [2.0.1] - 2026-06-17

### Changed
- Updated addon metadata for Retail patch 12.0.7 by setting TOC interface to `120007`.

### Packaging
- Bumped TOC version to `2.0.1`.

## [2.0.0] - 2026-05-14

### Fixed
- Fixed `Frame:RegisterEvent()` forbidden errors during addon load. Runtime events are no longer force-registered in the main chunk. Bootstrap events are registered immediately after `frame:SetScript("OnEvent")`, and runtime events are registered from `ADDON_LOADED` / `PLAYER_LOGIN` handlers.
- Fixed `attempt to call a nil value` at `RequestGuildKeysFromAllSources(true, true)` in the external sync retry path. Added a forward declaration and bound the function before first use so retry callbacks always resolve the local function.

### Packaging
- Bumped TOC version to `2.0.0`.

## [1.9.9] - 2026-05-13

### Fixed
- Fixed `!keys`, `!score`, and `!best` chat commands never receiving chat messages. `RegisterRuntimeEventsOnce` (which registers all `CHAT_MSG_*` events) was only called from the `ADDON_LOADED` and `PLAYER_LOGIN` event handlers. Because bootstrap event registration was deferred through `C_Timer.After`, those events had already been dispatched by the WoW loader before the frame ever registered to receive them, so the handlers never fired and `CHAT_MSG_*` events were never registered. The fix registers both bootstrap and runtime events directly after `frame:SetScript("OnEvent")`, matching the pattern used by other addons with working chat commands.

### Packaging
- Bumped TOC version to `1.9.9`.

## [1.9.8] - 2026-05-11

### Fixed
- Fixed M+ overlay appearing on zone-in to a mythic dungeon when no challenge mode is active. `IsChallengeModeRunActive` was returning `true` due to two spurious fallbacks: scenario criteria count (non-zero in any dungeon with objectives) and world elapsed timer (non-negative immediately on instance load). These fallbacks have been removed. The function now relies solely on `ui.inChallengeMode` (set by `CHALLENGE_MODE_START`), `IsChallengeModeActive()`, and `GetActiveChallengeMapID() > 0`.
- Hardened event registration to avoid protected-call faults during startup. `SafeRegisterFrameEvent` no longer routes through `securecallfunction`, which was triggering `ADDON_ACTION_FORBIDDEN` and could prevent `CHAT_MSG_*` events from registering.
- Removed `CanReadChatPayload` guard from the chat command handler. The guard used `canaccessvalue` on the message text which could return `false` in tainted contexts, silently dropping `!keys`/`!score`/`!best` commands before they were parsed.

### Packaging
- Bumped TOC version to `1.9.8`.

## [1.9.7] - 2026-05-05

### Fixed
- Fixed `!keys`, `!key`, `!score`, `!scores`, and `!best` chat commands silently failing to reply. `SendChatMessage` is now localized at load time and called directly without a `pcall` wrapper, so any blocked-call error surfaces in BugGrabber. The previous security-variable gate on `C_ChatInfo.SendChatMessage` has been removed; sends now go through the global `SendChatMessage` first with `C_ChatInfo.SendChatMessage` as fallback.
- Removed the combat-lockdown hard-drop in the chat handler. Commands typed during combat are now parsed and the reply is queued; it sends automatically when combat ends via `PLAYER_REGEN_ENABLED`.
- Fixed overlay showing prematurely on dungeon zone-in before a key was started. The zone-in recovery poll was falling back to `GetActiveChallengeMapID() > 0`, which returns the dungeon map ID immediately on entry regardless of run state. The overlay now only shows when `IsChallengeModeActive()` returns true.
- Fixed the active-run timer not showing over-time progress. `timeLeftSeconds` was clamped to zero when elapsed exceeded the limit; the overlay now shows `+MM:SS over` in red once the timer expires.
- M+ overlay no longer displays inside incursions or other non-Mythic+ party instances. The instance gate now strictly checks for Mythic+ difficulty IDs (8 and 23) only.

### Packaging
- Bumped TOC version to `1.9.7`.

## [1.9.6] - 2026-05-03

### Fixed
- M+ overlay no longer displays inside incursions or other non-Mythic+ party instances. The instance gate now strictly checks for Mythic+ difficulty IDs only.

### Packaging
- Bumped TOC version to `1.9.6`.

## [1.9.5] - 2026-05-02

### Fixed
- M+ overlay now auto-displays on zone-in and `/reload` during active runs without requiring `/km ui on`.
- Fixed the render deadlock where the refresh ticker was attached to the hidden overlay frame. The ticker now runs on the always-active main frame.
- Fixed overlay visibility leaking outside the dungeon by applying a strict Mythic+ instance gate for display.
- Fixed default objective tracker suppression reliability by deferring suppression through combat lockdown and retrying on `PLAYER_REGEN_ENABLED`.
- Fixed stale completed-run overlays showing in a different dungeon by matching completed run map context to the current instance before rendering.
- Death hover now falls back to a minimal total line (`Deaths: N`) when per-player attribution entries are unavailable.
- Hardened death attribution by refreshing group GUID-to-name mapping during active runs and resolving combat-log deaths from live party GUIDs before fallback heuristics.

### Packaging
- Bumped TOC version to `1.9.5`.
- Established `1.9.5` as the active testing baseline for SavedVariables persistence fixes.

## [1.9.4] - 2026-04-30

### Fixed
- Own snapshot persistence now bypasses the max-level gate when a valid keystone is present, preventing characters with keys from being filtered out when level APIs are unstable during login timing.
- Added a manual expansion max-level fallback of `90` when Blizzard max-level APIs do not return a usable value.
- Added `BAG_UPDATE_DELAYED` persistence handling so own snapshots are retried when inventory data becomes available after login.
- Fixed runtime event registration starvation: a single failed event bind no longer aborts the remaining runtime event registrations. This ensures persistence-critical events like `PLAYER_LOGOUT` and `BAG_UPDATE_DELAYED` can still register even if another runtime event fails.

### Packaging
- Bumped TOC version to `1.9.4`.

## [1.9.3] - 2026-04-30

### Fixed
- Own character data now saves even when the expansion max-level API is unavailable (e.g. 12.0.5). A character with a valid keystone in their bag bypasses the level gate, since keystone possession already confirms M+ eligibility. Prevents `characters` and `guild.members` tables from remaining empty after login.
- Added a manual expansion max-level fallback of `90` when Blizzard level APIs do not return a value, preventing false negatives in eligibility checks on patch transitions.
- Added `BAG_UPDATE_DELAYED` persistence handling so own keystone snapshots are retried when inventory data finishes loading after login, closing the timing gap where login-time API calls can still be empty.

### Packaging
- Bumped TOC version to `1.9.3`.

## [1.9.2] - 2026-04-30

### Fixed
- Own character keystone data now persists to SavedVariables correctly when the direct keystone API returns empty on login. The character snapshot now uses the full keystone resolution path (including bag-scan fallback) so keystones visible in-game are always captured and saved.

### Packaging
- Bumped TOC version to `1.9.2`.

## [1.9.1] - 2026-04-30

### Fixed
- Deferred bootstrap `ADDON_LOADED`/`PLAYER_LOGIN` event binding out of the main chunk and added guarded retry scheduling, reducing `Frame:RegisterEvent()` forbidden-call captures in taint-heavy 12.0.5 sessions.
- Hardened chat keystone-link parsing with a fail-closed readability gate and protected execution path so secret/unreadable payloads cannot trigger string-operation faults.
- Added extra fail-closed protection around chat keystone-link ingestion and command extraction so parsing failures no longer propagate through chat event handling.
- Unified chat payload readability validation through a reusable guarded string-access helper that checks readable string access before normalization/parsing work.

### Packaging
- Bumped TOC version to `1.9.1`.
- Refreshed `Releases/1.9.1` payload and archive with the current runtime addon files.

## [1.9.0] - 2026-04-29

### Fixed
- Hardened startup bootstrap event registration by routing initial `ADDON_LOADED` and `PLAYER_LOGIN` binds through the guarded safe-register path, avoiding direct `frame:RegisterEvent` calls in taint-sensitive sessions.
- Hardened chat command fallback parsing with a guarded normalization path so unreadable/secret payloads fail closed instead of attempting direct string normalization.
- Tightened chat payload readability checks to rely on guarded access/type checks before command parsing.

### Packaging
- Bumped TOC version to `1.9.0`.
- Refreshed `Releases/1.9.0` payload and archive with the current runtime addon files.

## [1.8.9] - 2026-04-25

### Fixed
- Removed stale Horde-specific portal spell entries (Siege of Boralus and The MOTHERLODE!!) from the season portal configuration. These dungeons are not in the current Midnight Season 2 M+ pool, and their presence caused Siege of Boralus to appear in the Season Portals display for Horde players while Windrunner Spire was incorrectly pushed out of the visible tile set.

## [1.8.8] - 2026-04-25
### Fixed
- Hardened runtime event registration for 12.0.5 taint-heavy sessions by routing each event bind through a guarded safe-register path and failing closed per-event instead of issuing raw `frame:RegisterEvent` calls.
- Added a recovery registration attempt on `PLAYER_ENTERING_WORLD` when runtime events were not fully registered during earlier startup timing.
- Improved Party/Guild data convergence by aligning Party tab cache resolution with alias-aware own-store fallback and strengthening group-member score fallback behavior.

### Packaging
- Bumped TOC version to `1.8.8`.
- Refreshed `Releases/1.8.8` payload and archive with the current runtime addon files.

## [1.8.7] - 2026-04-23

### Fixed
- Fixed Party tab key resolution for group members whose cached guild records are stored under full cross-realm names while the live unit only resolves to a short name. Guild cache reads now reuse preferred-name resolution so entries like `Name` correctly resolve stored data like `Name-Realm`.

### Packaging
- Bumped TOC version to `1.8.7`.
- Refreshed `Releases/1.8.7` payload and archive with the current runtime addon files.

## [1.8.6] - 2026-04-22

### Fixed
- Fixed `ResolvePreferredStoreName` nil-call crash (`KeyStoneMastery.lua:933`) by forward-declaring `GetNormalizedPlayerName` so early-scope calls bind to the local helper instead of global nil.
- Removed dead local declarations discovered during BugGrabber follow-up cleanup (`lastMismatchToastAt`, `ShowLocalToast`) while preserving runtime behavior.

### Packaging
- Bumped TOC version to `1.8.6`.
- Refreshed `Releases/1.8.6` payload and archive with the current runtime addon files.

## [1.8.5] - 2026-04-22

### Fixed
- Resolved Lua compiler error "main function has more than 200 local variables" that prevented KeyStoneMastery from loading. Inlined three rarely-used stdlib aliases (`band`, `strfind`, `strmatch`) to bring the top-level local count back within Lua's 200-variable limit.
- Fixed `ResolvePreferredStoreName` nil-call crash (`KeyStoneMastery.lua:933`) by forward-declaring `GetNormalizedPlayerName` so early-scope calls bind to the local helper instead of global nil.
- Reduced top-level local pressure to create expansion headroom by collapsing five single-use KSM refresh wrapper functions into one table-driven refresh loop in `RefreshKSMWindow`.
- Removed five unreferenced local helper functions and two additional dead local declarations discovered during cleanup (`CollapseRepeatedRealmSuffix`, `ShowMismatchToast`, `EnsureHiddenTrackerFrame`, `GetPortalSecureSpellToken`, `TryGetBestSeasonRunForIdentifier`, `lastMismatchToastAt`, `ShowLocalToast`).
- Lowered `KeyStoneMastery.lua` top-level local declaration count from `200` to `188`.

### Packaging
- Bumped TOC version to `1.8.5`.
- Refreshed `Releases/1.8.5` payload and archive with the current runtime addon files.

## [1.8.4] - 2026-04-21

### Fixed
- Hardened own snapshot persistence max-level gating to fail closed while level APIs are unresolved, preventing sub-max characters from being written during login/character-swap timing windows.
- Added same-short-name alias cleanup for own records so stale cross-realm variants (for example `Name-OtherRealm`) are purged when saving the active character snapshot.
- Corrected BugGrabber issue provenance: the `Frame:RegisterEvent()` forbidden-call report was observed from `1.8.3` runtime behavior.
- Removed runtime `RegisterEvent` calls from login initialization; runtime events now bind once at addon load to avoid recurring `Frame:RegisterEvent()` forbidden-call captures.
- Added preferred-name store resolution for guild snapshots so short-name updates reuse existing full-name keys and stop short/full duplicate resurfacing.
- Fixed challenge timer limit parsing to reject bogus tuple values (for example large texture/file IDs) and normalize millisecond-vs-second returns, preventing absurd completion-time displays.
- Aligned elapsed Mythic+ timer sourcing with Blizzard tracker updates by caching `ScenarioObjectiveTracker.ChallengeModeBlock:UpdateTime` elapsed seconds and using API polling only as fallback.

### Packaging
- Bumped TOC version to `1.8.4`.
- Refreshed `Releases/1.8.4` payload and archive with the current runtime addon files.

## [1.8.3] - 2026-04-21

### Changed
- Updated addon metadata for Retail patch day by setting TOC interface to `120005`.

### Fixed
- Hardened challenge-map API handling to support both tuple and table return shapes from map info lookups used by dungeon name/time-limit resolution.
- Fixed a run-state nil-guard gap around active challenge map lookup so startup/state refresh paths do not assume `C_ChallengeMode` is always initialized.
- Wrapped affix name and keystone auto-slot API calls with safer guards/pcalls and added combat-lockdown short-circuiting for auto-slot attempts.

### Packaging
- Bumped TOC version to `1.8.3`.

## [1.8.2] - 2026-04-21

### Fixed
- Removed runtime event-registration calls from login/addon handlers and restored one-time startup event wiring to eliminate the KeyStoneMastery `Frame:RegisterEvent()` forbidden call path reported by BugGrabber.

### Packaging
- Bumped TOC version to `1.8.2`.

## [1.8.1] - 2026-04-21

### Fixed
- Enforced combat-time chat safety by treating all incoming chat payloads as unreadable while in combat.
- Added an explicit combat short-circuit in chat handlers so KeyStoneMastery performs no chat parsing during combat lockdown.

### Packaging
- Bumped TOC version to `1.8.1`.

## [1.8.0] - 2026-04-21

### Fixed
- Hardened chat payload safety checks so unreadable secret-string payloads are dropped before command extraction, avoiding secret-string conversion faults in chat handlers.
- Removed string-coercion fallback in chat message handling for non-string payloads; only readable plain strings now proceed to parsing.
- Moved runtime event registration out of file-load scope and into one-time startup registration, preventing protected `RegisterEvent` calls from the main chunk path.

### Changed
- Added `/Backup/` to `.gitignore` to keep local deployment backups out of git workflows.

### Packaging
- Bumped TOC version to `1.8.0`.

## [1.7.9] - 2026-04-21

### Fixed
- Removed deferred runtime event-registration retries and switched to one-time startup event wiring so KeyStoneMastery no longer performs late `RegisterEvent` calls in taint-sensitive contexts.
- Hardened abandon vote button handling to prefer Blizzard challenge-mode vote APIs only (`RequestLeaverVote`/`StartLeaverVote`) instead of slash/macro fallbacks that can vary by client state.
- Improved world timer reads by probing available timer IDs before falling back, reducing brittle assumptions around timer index ordering in Retail 12.0.1.

### Packaging
- Bumped TOC version to `1.7.9`.

## [1.7.8] - 2026-04-21

### Fixed
- Clarified abandon behavior for solo runs: the button now explicitly reports that abandon voting requires a party, and the button is only shown at `5+` deaths while grouped.
- Removed secure-template abandon button wiring that could no-op in some client states; abandon now routes through explicit click handling again.
- Hardened chat command extraction against secret-string payload taint by validating chat payload readability before command parsing/string normalization.

### Packaging
- Bumped TOC version to `1.7.8`.

## [1.7.7] - 2026-04-21

### Fixed
- Fixed abandon button no-op behavior by restoring an explicit click-handler fallback (`RequestAbandonKeyVote`) while keeping secure `/abandon` macro attributes.
- Updated abandon vote invocation order to try slash-handler execution first, then direct challenge-mode APIs, then macro fallback.
- Moved runtime event registration back to `PLAYER_LOGIN` timing to avoid the startup forbidden path introduced by addon-load registration timing.

### Packaging
- Bumped TOC version to `1.7.7`.

## [1.7.6] - 2026-04-21

### Fixed
- Prevented stale Mythic+ overlay persistence after zoning/reset by hard-gating active run rendering to Mythic dungeon instance context and clearing challenge-active flags when out of instance.
- Updated the abandon vote button to a secure macro action button that executes `/abandon` directly on hardware click.
- Moved runtime event registration to addon-load timing with guarded registration attempts to reduce `Frame:RegisterEvent()` forbidden errors from runtime registration paths.

### Packaging
- Bumped TOC version to `1.7.6`.

## [1.7.5] - 2026-04-21

### Fixed
- Updated the abandon button fallback to execute the same slash-command parsing path as manual `/abandon`, improving reliability on client builds where direct `C_ChallengeMode` vote APIs are unavailable.

### Packaging
- Bumped TOC version to `1.7.5`.

## [1.7.4] - 2026-04-21

### Fixed
- Updated the Mythic+ abandon vote button to use a slash-command fallback (`/abandon`) when direct `C_ChallengeMode` vote APIs are unavailable in the client build.

### Changed
- Restyled the Mythic+ abandon vote button to match the KeyStoneMastery overlay aesthetic (custom dark panel styling with blue accent and hover/press states).
- The abandon vote button now stays hidden until death count reaches `5` or higher.

### Packaging
- Bumped TOC version to `1.7.4`.

## [1.7.3] - 2026-04-21

### Packaging
- Bumped TOC version to `1.7.3`.

## [1.7.2] - 2026-04-21

### Fixed
- Fixed a nil run-state context binding (`GetWorldElapsedSeconds`) that could error during M+ UI refresh and prevent the overlay from rendering.
- Fixed additional nil run-state helper bindings (`GetActiveKeystoneDetails`, affix/criteria/death helpers) so context callbacks remain valid across load order.
- Removed main-chunk runtime event registration and restored guarded runtime event wiring to prevent `Frame:RegisterEvent()` forbidden errors at addon load.

### Packaging
- Bumped TOC version to `1.7.2`.

## [1.7.1] - 2026-04-20

### Fixed
- Restored missing Mythic+ lifecycle runtime events (`CHALLENGE_MODE_START`, `CHALLENGE_MODE_COMPLETED`, `CHALLENGE_MODE_RESET`) so the custom M+ overlay activates reliably at key start and transitions correctly on completion/reset.
- Restored supporting run-state events (`COMBAT_LOG_EVENT_UNFILTERED`, `UNIT_FLAGS`, `PLAYER_DEAD`) needed for in-run death tracking and related overlay updates.

### Packaging
- Bumped TOC version to `1.7.1`.

## [1.7.0] - 2026-04-14

### Changed
- Renamed addon branding from **KeyStone Master** to **KeyStoneMastery**.
- Updated chat reply prefix to `KeyStoneMastery:`.
- Prepared Retail `12.0.5` readiness notes and validation checklist.
- Updated project docs to call out Retail `12.0.5` forward compatibility.
- Expanded `/ksm` dashboard as a full multi-tab Mythic+ panel (`Main`, `Party`, `Guild`).
- Added a `/ksm` `Recents` tab for previously seen players with known key data.
- Added TOC icon metadata so KeyStoneMastery shows an addon-list icon in-game.
- Added Guild tab controls for pagination and `Hide Offline` filtering.
- Guild request button now triggers active guild key pulls across enabled sources.
- Kept `KeyStoneMastery.lua` as the main runtime file and split shared constants/data into dedicated modules:
  - `KeyStoneMastery.Constants.lua`
  - `KeyStoneMastery.Data.lua`
- Split reusable parsing/formatting/request helpers into `KeyStoneMastery.Utils.lua`.
- Split guild safety/recent-activity helpers into `KeyStoneMastery.GuildUtils.lua`.
- Split addon sync/external key-ingestion pipeline into `KeyStoneMastery.Sync.lua`.
- Extracted `/ksm` tab refresh logic into `KeyStoneMastery.UI.KSM.lua` to keep `KeyStoneMastery.lua` focused on orchestration.
- Updated TOC load order so shared modules load before `KeyStoneMastery.lua`.

### Fixed
- Reduced risk of Lua chunk-local overflow in the main file by moving large static tables out of `KeyStoneMastery.lua`.
- Added passive guild key cache ingestion from observed keystone chat links and external key-sharing payloads.
- Restricted `!keys` handling to KeyStoneMastery sync behavior while leaving active external pulls to the Guild request path.
- Strengthened guild sync payload parsing and sanitization for malformed addon messages.
- Added AstralKeys `sync*` batch payload parsing (in addition to `updateV*`) so guild key snapshots populate reliably.
- Expanded external key-ingestion channels for AstralKeys/OpenRaid messages beyond guild-only flows to improve party/guild coverage.
- Ensured guild chat key replies are merged into `/ksm guild` rows even when roster-derived entries already exist, with Blizzard roster/API enrichment for class, online state, and score when available.
- Improved Blizzard rating enrichment lookups for Party/Guild tabs by trying multiple member identifiers (GUID, full name, normalized name) when score data is missing.
- Restored guild/officer `!keys` auto-replies when chat payload coercion is required by using safer command normalization flow.
- Added AstralKeys plaintext chat parsing for messages like `Astral Keys: [Dungeon (12)]` so guild tab rows are created from those links.
- Expanded generic guild chat keystone parsing to capture additional addon/user-facing formats (including `(+12)` and `+12` variants) so addon responders reliably populate `/ksm guild`.
- Added fail-safe guild command replies so `!keys`/`!score`/`!best` still respond with fallback text when runtime command parsing or reply generation returns nil.
- Updated `!keys` reply building to fall back to owned snapshot text (`+level dungeon`) when hyperlink creation is unavailable, preventing false "Keystone unavailable" replies.
- Fixed portal click-casting reliability in `/ksm` Main/Party/Guild views by using a shared known-spell check (`IsSpellKnownOrOverridesKnown`/`IsPlayerSpell`) and robust cast fallback path.
- Replaced direct portal cast calls with secure spell action-button bindings in Main/Party/Guild portal buttons to resolve BugGrabber `ADDON_ACTION_FORBIDDEN` protected-call errors.
- Removed legacy direct-cast behavior from the old portal helper so stale call paths cannot invoke protected cast APIs.
- Fixed portal button click execution by registering secure portal buttons for hardware clicks and binding spell cast tokens compatible with secure action attributes.
- Hardened portal spell API compatibility checks to avoid indexing non-table globals on clients where `C_Spell`/`C_SpellBook` differ, preventing addon load/runtime breaks.
- Hardened `/km` and `/ksm` slash registration with unique command IDs and early command binding to avoid addon command collisions and preserve command availability during partial initialization.
- Added dual slash alias registration (`KEYSTONEMASTERY`/`KEYSTONEMASTER` plus `KEYSTONEMASTERY*`) and login-time rebind to keep `/km` and `/ksm` available even if another addon overwrites slash tables.
- Added ultra-early fallback slash handlers in constants so `/km` and `/ksm` return a startup diagnostic if later files fail during addon initialization.
- Hardened core startup against early-load globals by guarding slash registration when `SlashCmdList` is unavailable and falling back to direct `ADDON_LOADED` registration if `C_Timer.After` is unavailable.
- Simplified `/km` and `/ksm` core slash wiring back to direct handlers in `KeyStoneMastery.lua` to reduce chunk complexity and avoid early core aborts while retaining constants-level fallback diagnostics.
- Fixed core compile failure (`main function has more than 200 local variables`) by removing top-level utility alias locals in `KeyStoneMastery.lua` and routing those helpers through a shared namespace reference.
- Fixed `/ksm` teleport buttons (Main/Party/Guild) no-op behavior by binding secure spell actions for valid portal spell IDs regardless of known-check result; known-check now controls visuals/tooltips only.
- Fixed `/ksm guild` `Hide Offline` filtering by normalizing Blizzard roster online flags (0/1/boolean) before row inclusion and filter checks.
- Improved `/ksm guild` population reliability by including recent roster members even when key cache is empty, guarding against invalid roster names, and always showing the current player row.
- Hotfixed `/ksm` tab rendering break by removing non-WoW Lua `goto`/label syntax from guild-tab roster parsing.
- Expanded KeyStoneMastery sync request/broadcast channels to include active group contexts (`PARTY`/`RAID`/`INSTANCE_CHAT`) in addition to guild, improving raid pickup coverage.
- Updated `/ksm guild` roster filtering to list only guild members with known keys, reducing noise from inactive/alts-without-key entries.
- Ensured `/ksm guild` always includes the current player row when your own known key exists, even if roster normalization misses your name.
- Excluded the current player from `/ksm recents` so your own key only appears in Guild/Main views.
- Fixed `/ksm` portal secure-button binding to use spell-name tokens (matching working `/cast` behavior) instead of numeric IDs for improved click-cast reliability.
- Removed custom `OnClick` handlers from secure portal action buttons so protected spell actions can execute on hardware clicks in Main/Party/Guild.
- Hardened addon-message sending for Retail 12.x result enums, including retry handling for throttle/lockdown outcomes.
- Improved Guild tab online detection by correctly handling numeric roster status values and mobile-online flags.
- Reduced Guild tab online-state stickiness window to improve offline transition responsiveness.
- Corrected guild roster field unpacking so online/status/isMobile are read from proper `GetGuildRosterInfo` return positions.
- Added stronger Guild tab dedupe logic using GUID and same-character heuristics to collapse duplicate short/full-realm rows.
- Added max-level-only filtering for Guild tab roster rows (Retail cap-aware, supports current level 90 environments).
- Fixed realm normalization so hyphenated realm display forms (for example `Earthen-Ring`) do not collapse into truncated synthetic names.
- Prevented synthetic `Name-RealmFragment` identity generation in normalized storage keys.
- Cleaned guild member cache handling and display behavior for short/full name variants to reduce duplicate row resurfacing.
- Added follow-up refresh bursts to the Guild request button path to capture members whose addon comm handlers initialize shortly after login.
- Removed runtime protected event-registration retry paths that were still triggering `ADDON_ACTION_FORBIDDEN` in live BugGrabber captures.
- Simplified runtime event wiring to avoid late `Frame:RegisterEvent()` calls during taint-sensitive contexts.
- Trimmed non-essential runtime event registrations while preserving guild/chat sync coverage.

### Packaging
- Built release archive at `Releases/1.7.0/KeyStoneMastery.zip` with a top-level `KeyStoneMastery/` folder for direct AddOns extraction.
- Renewed `Releases/1.7.0/KeyStoneMastery.zip` on 2026-04-20 so package contents match latest 1.7.0 code.

## [1.6.8] - 2026-04-13

### Changed
- Renamed addon from **KeyStoneMastery** to **KeyStone Master**
- Updated chat reply prefix to `KeyStoneMaster:`

### Fixed
- Fixed protected function call error with frame event registration

### Packaging
- Built release archive at `Releases/1.6.8/KeyStoneMastery.zip`.

## [1.6.7] - 2026-04-11

### Fixed
- Stopped registering the full event list in the main chunk, which was still triggering protected `Frame:RegisterEvent()` forbidden errors in fresh BugGrabber captures.
- Kept only `ADDON_LOADED` registration at file load and moved runtime event registration into addon `ADDON_LOADED` handling with one-time guarding.

### Notes
- Addon name changed to **KeyStone Master**

### Packaging
- Built release archive at `Releases/1.6.7/KeyStoneMastery.zip`.

## [1.6.6] - 2026-04-11

### Fixed
- Moved frame event registration to early startup immediately after frame creation, before taint-prone runtime paths.
- Removed the `securecallfunction` registration wrapper and late registration path tied to fresh `UNKNOWN()` forbidden BugGrabber stacks.

### Packaging
- Built release archive at `Releases/1.6.6/KeyStoneMastery.zip`.

## [1.6.5] - 2026-04-09

### Fixed
- Routed frame event registration through `securecallfunction` to avoid the protected `Frame:RegisterEvent()` forbidden path seen in fresh BugGrabber dumps.
- Kept one-time startup event wiring behavior while hardening against taint-sensitive registration contexts.

### Packaging
- Built release archive at `Releases/1.6.5/KeyStoneMastery.zip`.

## [1.6.4] - 2026-04-08

### Fixed
- Removed runtime/deferred `Frame:RegisterEvent()` calls and restored one-time static event registration at file load.
- Eliminated the KeyStoneMastery forbidden call path seen in BugGrabber stacks (`Frame:RegisterEvent()` at runtime).

### Packaging
- Built release archive at `Releases/1.6.4/KeyStoneMastery.zip`.

## [1.6.3] - 2026-04-03

### Fixed
- Deferred runtime event registration when combat lockdown is active, then retries registration after combat ends.
- Added idempotent login initialization so startup setup still runs if `PLAYER_LOGIN` was missed while runtime events were deferred.

### Packaging
- Built release archive at `Releases/1.6.3/KeyStoneMastery.zip`.

## [1.6.2] - 2026-04-02

### Fixed
- Replaced the `pcall`-based deferred event bootstrap with a safer `ADDON_LOADED`-first registration flow.
- Eliminated the protected `UNKNOWN()`/`Frame:RegisterEvent()` forbidden path seen in BugGrabber stacks.

### Packaging
- Built release archive at `Releases/1.6.2/KeyStoneMastery.zip`.

## [1.6.1] - 2026-04-02

### Fixed
- Moved frame event registration out of main chunk and into a deferred bootstrap path to prevent `[ADDON_ACTION_FORBIDDEN]` errors on `Frame:RegisterEvent()`.
- Added guarded retry registration logic so event wiring completes safely after load/combat constraints clear.

### Packaging
- Built release archive at `Releases/1.6.1/KeyStoneMastery.zip`.

## [1.6.0] - 2026-04-02

### Fixed
- Deferred outgoing chat replies during combat and flushes them once combat ends instead of dropping them outright.
- Deferred new-keystone party announcements during combat so post-run key updates still announce safely after `PLAYER_REGEN_ENABLED`.

### Packaging
- Built release archive at `Releases/1.6.0/KeyStoneMastery.zip`.

## [1.5.9] - 2026-04-01

### Fixed
- Restored automatic keystone slotting when the Font of Power receptacle opens — scans bags for a Mythic Keystone and slots it via `C_ChallengeMode.SlotKeystone()` without triggering protected-action errors.
- Updated settings panel description to accurately reflect that automatic keystone slotting is active when the KeyStoneMastery Mythic+ UI is enabled.

### Packaging
- Built release archive at `Releases/1.5.9/KeyStoneMastery.zip`.

## [1.5.8] - 2026-03-31

### Fixed
- Removed runtime/retry event registration and restored static frame event registration to avoid protected `Frame:RegisterEvent()` forbidden errors.
- Hardened chat command extraction to avoid direct restricted-string equality checks that can trigger secret-string taint comparisons.
- Added a `canaccessvalue` guard before chat parsing so unreadable secret-string payloads are dropped safely.
- Wrapped command reply construction in protected execution to fail closed on unexpected runtime payload edge cases.

### Packaging
- Built release archive at `Releases/1.5.8/KeyStoneMastery.zip`.

## [1.5.7] - 2026-03-30

### Fixed
- Hardened chat command parsing against secret-string taint by converting incoming chat message values to plain strings before comparisons/parsing.
- Reworked deferred event registration to use direct `frame:RegisterEvent(...)` calls in safe initialization context, removing pcall-wrapped registration that could trigger protected-action reports.
- Added one-time frame-event registration guard to prevent duplicate event wiring.

### Packaging
- Built release archive at `Releases/1.5.7/KeyStoneMastery.zip`.

## [1.5.6] - 2026-03-29

### Fixed
- Added `!scores` as an alias for `!score` so both commands return Mythic+ score replies.
- Improved `!best` run-history parsing to accept numeric-string level/map values and partial run records.
- Added safe fallback so weekly best uses season best when week-specific API flags are missing but valid season data exists.

### Packaging
- Built release archive at `Releases/1.5.6/KeyStoneMastery.zip`.

## [1.5.5] - 2026-03-29

### Fixed
- Restored startup initialization by registering `ADDON_LOADED` at file load so the addon can receive its first event and initialize correctly.
- Kept deferred registration for remaining frame events after initialization to preserve protected-call safety.

### Packaging
- Built release archive at `Releases/1.5.5/KeyStoneMastery.zip`.

## [1.5.4] - 2026-03-29

### Fixed
- Deferred frame event registration to ADDON_LOADED handler to prevent protected-function errors during addon load.
- RegisterEvent calls now use deferred execution via pcall guards in a safe event context.

### Packaging
- Built release archive at `Releases/1.5.4/KeyStoneMastery.zip`.

## [1.5.3] - 2026-03-29

### Fixed
- Hardened chat command handling to avoid comparing directly against tainted secret-string message values.
- Command replies now route through normalized command tokens (`!key`, `!keys`, `!score`, `!best`) for safer comparisons in chat-event handlers.

### Packaging
- Built release archive at `Releases/1.5.3/KeyStoneMastery.zip`.

## [1.5.2] - 2026-03-28

### Fixed
- Enemy Forces label now renders on a dedicated top overlay layer above the progress fill so the text stays over the bar as it fills.
- Reduced label backdrop tint so bar fill remains visible while preserving text contrast.

### Packaging
- Built release archive at `Releases/1.5.2/KeyStoneMastery.zip`.

## [1.5.1] - 2026-03-28

### Fixed
- Increased Enemy Forces bar label readability by darkening the label backdrop and using outlined text styling.

### Packaging
- Built release archive at `Releases/1.5.1/KeyStoneMastery.zip`.

## [1.5.0] - 2026-03-28

### Fixed
- Completed-run summary now preserves and displays actual completion time instead of occasionally showing `00:00`.
- Remaining-time display on completion now supports signed values; overtime is shown as a negative value and highlighted in red.
- Added delayed completion-time refresh to pick up final run time when completion info arrives slightly after the completion event.

### Packaging
- Built release archive at `Releases/1.5.0/KeyStoneMastery.zip`.

## [1.4.9] - 2026-03-28

### Added
- Added automatic new-key announcements to party chat when your owned keystone changes after Mythic+ completion/reset.
- Key-change detection uses a stored keystone snapshot and delayed post-completion checks so rerolled keys are picked up reliably.

### Packaging
- Built release archive at `Releases/1.4.9/KeyStoneMastery.zip`.

## [1.4.8] - 2026-03-28

### Fixed
- Blizzard objective tracker now returns correctly when the KeyStoneMastery overlay is hidden or disabled, while still fading during active Mythic+ overlay use.
- Improved Enemy Forces label readability by adding stronger text contrast over the blue progress bar.
- Reworked death attribution to track party member death state directly from group units in addition to combat-log events, making hover details more reliable.

### Packaging
- Built release archive at `Releases/1.4.8/KeyStoneMastery.zip`.

## [1.4.7] - 2026-03-28

### Changed
- Updated README to reflect current behavior for chat command coverage, command matching tolerance, and fallback responses.
- Documented current protected-action safety state: automatic keystone slotting remains disabled.
- Added slash-command documentation for `/km deaths`, `/km criteria`, and `/km forces`.

### Packaging
- Built release archive at `Releases/1.4.7/KeyStoneMastery.zip`.

## [1.4.6] - 2026-03-27

### Fixed
- Corrected run-active detection so completed Mythic+ runs do not remain in an active-timer state after completion.
- Completion view now zeroes the remaining timer at run end, restoring expected timer reset behavior.

### Packaging
- Built release archive at `Releases/1.4.6/KeyStoneMastery.zip`.

## [1.4.5] - 2026-03-27

### Fixed
- Restored suppression of the default Blizzard objective tracker during Mythic+ using alpha changes instead of frame reparenting.
- This keeps the custom KeyStoneMastery overlay visible without bringing back the earlier protected-action risk from tracker parent swaps.

### Packaging
- Built release archive at `Releases/1.4.5/KeyStoneMastery.zip`.

## [1.4.4] - 2026-03-27

### Fixed
- Improved `!key` and `!keys` reliability by detecting Mythic Keystones from actual bag hyperlinks, not only the owned-keystone API path.
- Added direct bag-link fallback so players with a keystone in their bags are more likely to respond even when Blizzard keystone ownership APIs are late or inconsistent.

### Packaging
- Built release archive at `Releases/1.4.4/KeyStoneMastery.zip`.

## [1.4.3] - 2026-03-27

### Fixed
- Disabled automatic keystone slotting to eliminate the remaining protected-action path most likely causing Blizzard UI blocked popups.
- Manual keystone slotting remains available through the default Blizzard UI.

### Packaging
- Built release archive at `Releases/1.4.3/KeyStoneMastery.zip`.

## [1.4.2] - 2026-03-27

### Fixed
- Removed direct Objective Tracker frame parent manipulation from runtime updates to avoid Blizzard protected-action taint errors.
- This hotfix targets the "action only available to Blizzard UI" block message.

### Packaging
- Built release archive at `Releases/1.4.2/KeyStoneMastery.zip`.

## [1.4.1] - 2026-03-27

### Fixed
- Broadened death attribution capture gating to track group deaths whenever Mythic dungeon context is active, even if challenge-state APIs briefly lag.
- Reduces cases where total deaths are shown but hover details fall back to `Unattributed` for the whole run.

### Packaging
- Built release archive at `Releases/1.4.1/KeyStoneMastery.zip`.

## [1.4.0] - 2026-03-27

### Fixed
- Auto-reply command parsing now tolerates color formatting and inline punctuation more robustly.
- `!key`, `!keys`, `!score`, and `!best` now always return a response instead of failing silently when game API data is temporarily unavailable.
- Added explicit fallback replies (`Keystone unavailable`, `M+ Score unavailable`) to make temporary data gaps clear.

### Packaging
- Built release archive at `Releases/1.4.0/KeyStoneMastery.zip`.

## [1.3.9] - 2026-03-27

### Fixed
- Expanded chat trigger coverage for auto-replies to include party/raid leader channels and instance chat channels.
- Relaxed command parsing so requests like `!score?` and `!best.` still trigger replies.

### Packaging
- Built release archive at `Releases/1.3.9/KeyStoneMastery.zip`.

## [1.3.8] - 2026-03-27

### Fixed
- Improved death-name capture timing so per-player attribution is recorded more reliably during active Mythic dungeon runs.
- Death tooltip now shows an `Unattributed` fallback count when Blizzard death totals exist but per-player names were unavailable.

### Packaging
- Built release archive at `Releases/1.3.8/KeyStoneMastery.zip`.

## [1.3.7] - 2026-03-27

### Fixed
- Enemy Forces bar text now truncates fractional percentages to match Blizzard-style integer display (for example, 85.5% now shows as 85% instead of 86%).

### Packaging
- Built release archive at `Releases/1.3.7/KeyStoneMastery.zip`.

## [1.3.6] - 2026-03-27

### Fixed
- Death attribution capture now prefers player GUID detection, making per-player death names more reliable in combat-log edge cases.
- Death hover hitbox is now more robust and keeps an interactive area even when text width/height reports transient zero values.

### Packaging
- Built release archive at `Releases/1.3.6/KeyStoneMastery.zip`.

## [1.3.5] - 2026-03-27

### Fixed
- Reworked Enemy Forces percent calculation to follow the in-game criteria logic path first.
- Weighted criteria now prioritize direct handling of `quantity`, `quantityString`, and `totalQuantity` before custom fallbacks.
- Retained dungeon total-unit conversion only as fallback when criteria data is incomplete.

### Packaging
- Built release archive at `Releases/1.3.5/KeyStoneMastery.zip`.

## [1.3.4] - 2026-03-27

### Fixed
- Enemy Forces conversion now uses dungeon-specific total-unit values across the full current Midnight season dungeon pool.
- Added mapID-based total-unit lookup for deterministic conversion, with name fallback handling for localization/name variants.
- Added `/km forces` debug command to print live Enemy Forces mapping details (mapID, known total, cached total, criterion raw values).

### Packaging
- Built release archive at `Releases/1.3.4/KeyStoneMastery.zip`.

## [1.3.3] - 2026-03-27

### Fixed
- Completed-run panel now stays visible while you remain inside the Mythic+ dungeon and clears immediately when you leave (e.g., hearth out).
- Improved weighted Enemy Forces fallback: when weighted quantity is absolute progress with a non-100 total, percent is now computed as `quantity / total * 100`.

### Packaging
- Built release archive at `Releases/1.3.3/KeyStoneMastery.zip`.

## [1.3.2] - 2026-03-27

### Fixed
- Fixed `/km criteria` runtime error (line 262) caused by early references to local helper functions that are declared later in file scope.
- Criteria debug now uses direct Blizzard API calls within the command handler, preventing nil-function lookup errors.

### Packaging
- Built release archive at `Releases/1.3.2/KeyStoneMastery.zip`.

## [1.3.1] - 2026-03-27

### Fixed
- Replaced fuzzy Enemy Forces objective matching with strict normalized label matching against Blizzard's Enemy Forces criterion.
- Removed broad substring matching (e.g., generic "forces") that could bind to the wrong weighted objective and show incorrect percentages.
- Enemy Forces criterion selection is now deterministic and confidence-based among exact-name weighted candidates only.

### Packaging
- Built release archive at `Releases/1.3.1/KeyStoneMastery.zip`.

## [1.3.0] - 2026-03-27

### Changed
- Adopted rollover versioning policy: when patch reaches 9, the next release increments minor and resets patch to 0.
- Promoted latest fixes into 1.3.0 under the new versioning scheme.

### Packaging
- Built release archive at `Releases/1.3.0/KeyStoneMastery.zip`.

## [1.2.14] - 2026-03-27

### Fixed
- Enemy Forces percent resolution now mirrors the game criteria weighted handling more closely after mid-run reloads.
- For weighted Enemy Forces criteria, fallback now uses the weighted quantity directly (percent-like) instead of quantity/total conversion.
- Percent parser now tolerates WoW color formatting and spacing variants like `88 %`, reducing false fallback to bad values.

### Packaging
- Built release archive at `Releases/1.2.14/KeyStoneMastery.zip`.

## [1.2.13] - 2026-03-27

### Fixed
- Enemy Forces bar mapping is now strict: it only binds to weighted-progress criteria whose name matches the Blizzard Enemy Forces label.
- This removes ambiguous criterion fallback that could select a completed objective and incorrectly show 100% early.
- Per-player death attribution now records while Mythic+ is actively detected (not only when the start-event flag is set), preventing missed capture from event ordering edge cases.

### Packaging
- Built release archive at `Releases/1.2.13/KeyStoneMastery.zip`.

## [1.2.12] - 2026-03-27

### Fixed
- `/km criteria` now always prints a status header and wraps debug collection in `pcall`, so failures are shown as chat errors instead of appearing to do nothing.

### Packaging
- Built release archive at `Releases/1.2.12/KeyStoneMastery.zip`.

## [1.2.11] - 2026-03-27

### Fixed
- Further tightened Enemy Forces criterion selection by preferring weighted-progress objectives with expected totals and computing percent from quantity/total when needed.
- Fixed death-hover interaction while UI is locked by keeping frame mouse enabled (dragging is still blocked by lock checks).

### Added
- Added `/km criteria` debug command to print raw scenario criteria values (name, weighted flag, quantity, total, quantityString) for fast in-run diagnosis.

### Packaging
- Built release archive at `Releases/1.2.11/KeyStoneMastery.zip`.

## [1.2.10] - 2026-03-27

### Fixed
- Tightened Enemy Forces mapping again by prioritizing the localized Blizzard label (`CHALLENGE_MODE_ENEMY_FORCES`) on weighted-progress criteria.
- Improved death-hover reliability by expanding the hover hit area to the full deaths row width.

### Added
- Added `/km deaths` to print per-player death attribution captured during the current/recent run.

### Packaging
- Built release archive at `Releases/1.2.10/KeyStoneMastery.zip`.

## [1.2.9] - 2026-03-26

### Fixed
- Tightened Enemy Forces detection to only use weighted-progress scenario criteria, matching in-game criteria behavior more closely.
- This avoids treating unrelated percentage-based objectives as Enemy Forces, which could cause the bar to jump to 100% on an early pull.
- Improved the deaths hover area and tooltip behavior so hovering the deaths line always gives visible feedback.

### Changed
- Group death attribution now uses explicit combat-log player and affiliation flags for more reliable party-member tracking.

### Packaging
- Built release archive at `Releases/1.2.9/KeyStoneMastery.zip`.

## [1.2.8] - 2026-03-26

### Added
- Added a hover tooltip on the deaths line that shows which party members died and how many times.

### Changed
- Death tooltip data is tracked from `COMBAT_LOG_EVENT_UNFILTERED`, matching a combat-log-first attribution approach.
- Death breakdown is preserved briefly on the completed-run summary as well.

### Packaging
- Built release archive at `Releases/1.2.8/KeyStoneMastery.zip`.

## [1.2.7] - 2026-03-26

### Fixed
- End-of-key summary now uses Blizzard's `C_ChallengeMode.GetCompletionInfo()` for final completion time and upgrade levels.
- This prevents the completion display from falling back to `00:00` when the live world timer resets after dungeon completion.

### Packaging
- Built release archive at `Releases/1.2.7/KeyStoneMastery.zip`.

## [1.2.6] - 2026-03-26

### Fixed
- Enemy Forces now uses Blizzard-provided percentage text directly from scenario criteria (the `%` value), instead of inferred quantity/total math.
- This prevents incorrect early 100% spikes caused by selecting non-forces criteria with ratio-style values.

### Packaging
- Built release archive at `Releases/1.2.6/KeyStoneMastery.zip`.

## [1.2.5] - 2026-03-26

### Fixed
- Fixed end-of-key timer resetting to `00:00` by capturing a completion snapshot and rendering that summary after `CHALLENGE_MODE_COMPLETED`.
- Added explicit key result line showing `Result: +1`, `Result: +2`, `Result: +3`, or `Result: Depleted`.
- Improved Enemy Forces objective detection to avoid false positives (such as immediate 100% from non-forces criteria).

### Changed
- Added a short post-completion display window showing final elapsed time, remaining time, and key result.

### Packaging
- Built release archive at `Releases/1.2.5/KeyStoneMastery.zip`.

## [1.2.4] - 2026-03-26

### Fixed
- Fixed inaccurate Enemy Forces progress by improving how the addon identifies the Enemy Forces scenario criterion.
- Replaced first-match weighted detection with scored candidate selection using name, percent text, weighted flag, and quantity metadata.

### Packaging
- Built release archive at `Releases/1.2.4/KeyStoneMastery.zip`.

## [1.2.3] - 2026-03-26

### Fixed
- Fixed a render deadlock where the Mythic+ panel could remain hidden forever because visibility logic only ran in `OnUpdate` while the frame was hidden.
- `RefreshMythicUI()` now performs an immediate render pass so event-driven updates can show the frame instantly.
- Removed `PLAYER_ENTERING_WORLD` flag reset that could clear M+ state during key-start transitions.

### Changed
- Refactored UI drawing into a shared `RenderMythicUI()` routine used by both event refreshes and periodic timer refreshes.

### Packaging
- Built release archive at `Releases/1.2.3/KeyStoneMastery.zip`.

## [1.2.2] - 2026-03-26

### Fixed
- Fixed M+ overlay not appearing during actual Mythic+ runs by using event-driven detection from challenge events.
- Added `ui.inChallengeMode` flag that is set immediately when `CHALLENGE_MODE_START` event fires, bypassing API initialization delays.
- Challenge mode detection now has higher priority for event-based signal over API queries.
- Added "M+ detected: yes/no" output to `/km status` for better diagnostic visibility.

### Changed
- Improved event handling for `CHALLENGE_MODE_START`, `CHALLENGE_MODE_COMPLETED`, and `CHALLENGE_MODE_RESET` with dedicated handlers.
- Challenge mode flag is now cleared on world transitions to prevent stale state.

### Packaging
- Built release archive at `Releases/1.2.2/KeyStoneMastery.zip`.

## [1.2.1] - 2026-03-26

### Added
- Added `/km status` to show current KeyStoneMastery UI state (enabled, hidden, tracker-hide mode, lock state, scale, and anchor).
- Added `/km ui restore` to re-enable and reset the KeyStoneMastery UI to a known-good default position.
- Added `Unlock UI` and `Lock UI` buttons to the KeyStoneMastery settings panel.
- Added a `Hide Blizzard objectives during Mythic+` setting (enabled by default).

### Changed
- Improved Mythic+ activity detection and added a fallback overlay state while challenge data initializes.
- Changed default overlay anchor to top-right under the minimap.
- Improved slash/help messaging for positioning and UI recovery.

### Packaging
- Built release archive at `Releases/1.2.1/KeyStoneMastery.zip`.

## [1.2.0] - 2026-03-26

### Added
- Added a live Mythic+ overlay UI to KeyStoneMastery with a transparent black panel and white text.
- Added active dungeon header, affix summary, elapsed timer, and +2/+3 chest breakpoint lines.
- Added scenario objective tracking, death counter display, and an Enemy Forces progress bar.
- Added `/km` UI controls for lock, unlock, hide, show, reset, and scale.
- Added a KeyStoneMastery settings option to disable the custom Mythic+ UI and fall back to Blizzard's default Mythic+ interface.

### Changed
- Styled the Enemy Forces bar with a blue progress fill and centered white percentage text.

### Packaging
- Built release archive at `Releases/1.2.0/KeyStoneMastery.zip`.

## [1.1.9] - 2026-03-26

### Changed
- Removed all debug logging and slash command debug modes for a clean production build.
- Fixed latent nil reference to removed `KEYSTONE_ITEM_ID` constant in synthetic keystone link builder.

### Packaging
- Built release archive at `Releases/1.1.9/KeyStoneMastery.zip`.

## [1.1.8] - 2026-03-26

### Fixed
- Fixed `!best` reporting impossible key levels: `GetWeeklyBestForMap`/`GetSeasonBestForMap` return scores on current Retail, not key levels. Run history is now the primary source with a key-level sanity check (2-40).
- Fixed `!best` crash caused by unescaped pipe character in chat reply string (replaced `|` with `/`).

## [1.1.7] - 2026-03-26

### Removed
- Removed `!vault` and `!weekly` commands (only showed completion counts, not reward item levels).

## [1.1.6] - 2026-03-26

### Fixed
- Replaced `CHALLENGE_MODE_KEYSTONE_RECEPTABLE_OPEN` event registration with `ChallengesKeystoneFrame:HookScript("OnShow")` for reliable auto-slot behaviour.
- Auto-slot now uses `PickupContainerItem` + `CursorHasItem()` before calling `SlotKeystone()`.
- Added `ADDON_LOADED` handling to hook `Blizzard_ChallengesUI` when it loads, with a fallback check at `PLAYER_LOGIN`.
- Expanded keystone item ID support to cover all known variants: 180653 (Dragonflight/TWW), 158923 (BfA), 151086 (Legion).

## [1.1.2] - 2026-03-26

### Fixed
- Added bag-scan fallback for keystone link resolution when `C_MythicPlus.GetOwnedKeystoneLink()` returns nil.

## [1.1.0] - 2026-03-25

### Fixed
- Simplified chat event listening to party, raid, and guild channels only.

## [1.0.4] - 2026-03-25

### Added
- Added `!best` command to report best key for the current week and season.
- Added `!score` command to report current Mythic+ score.

## [1.0.0] - 2026-03-24

### Added
- Initial release.
- `!key` and `!keys` commands reply with your clickable keystone link in party, raid, and guild chat.
- Font of Power auto-slot when your key matches the dungeon.
