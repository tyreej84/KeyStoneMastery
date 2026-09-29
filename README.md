# KeyStoneMastery

KeyStoneMastery is a World of Warcraft Retail Mythic+ addon that does three things:

1. Replies to M+ chat requests (`!key`, `!score`, `!best`).
2. Tracks your key and group/guild key data in a `/ksm` dashboard.
3. Shows a live Mythic+ run overlay with timer/objectives/deaths/Enemy Forces.

Target client/API: Retail 12.0.7 (compatible with 12.0.1+).

Repository: https://github.com/tyreej84/KeyStoneMastery

## Exactly What The Addon Does

### 1) Chat responses for Mythic+ requests

- Responds to `!key` / `!keys` with your current keystone link (or fallback text if link APIs are unavailable).
- Responds to `!score` / `!scores` with your Mythic+ score.
- Responds to `!best` with your best weekly/season run summary.
- Watches guild chat for keystone-style messages and uses them to update guild key cache.
- Defers outgoing chat messages during combat and sends them after combat ends.

### 2) `/ksm` dashboard for key visibility

- `Main` tab shows your key/rating context plus seasonal summary data.
- `Party` tab shows current party member key snapshots and score context.
- `Guild` tab shows known guild keys with pagination/filtering and refresh requests.
- `Recents` tab shows previously seen players with known keys.
- `Warband` tab shows your own character key snapshots.
- Integrates incoming key data from KeyStoneMastery sync messages and supported external payload formats.

### 3) Live Mythic+ run overlay

- Displays dungeon header, affixes, run timer, chest breakpoints, objectives, death tracking, and Enemy Forces progress.
- Can be enabled/disabled, shown/hidden, moved, locked, and scaled with slash commands.
- Supports falling back to Blizzard UI behavior when the custom overlay is disabled.

### 4) Keystone workflow helpers

- Announces newly changed keys to party when your key changes.
- Auto-slots your keystone when the Font of Power receptacle opens.

### 5) Name handling and storage behavior

- Stores names using incoming authoritative data.
- Does not synthesize local realm suffixes.
- Preserves cross-realm player identifiers when they are provided.

### 6) Guild tab inclusion rules (current)

- Shows max-level guild characters only (Retail cap-aware).
- Shows rows when known key data is available (map + level).
- Deduplicates same-character variants (short/full realm names) and prefers richer roster/GUID-backed data.
- Keeps online/offline state resilient to roster churn while updating quickly.

### 7) Guild refresh behavior

- `Request Guild Keys` performs an immediate refresh and short follow-up pulls to catch members whose addons initialize shortly after login.
- Inbound updates are accepted from KeyStoneMastery sync messages, AstralKeys payloads, and Details/OpenRaid payloads.
- A guild member may still not appear if they are below max level, have no known key to share, or do not have a compatible key-sharing addon payload active.

## Commands

### Chat triggers

- `!key` / `!keys`
- `!score` / `!scores`
- `!best`

### Slash commands

- `/km` or `/keystonemastery`: addon help and status entry point.
- `/km settings`: open settings panel.
- `/km status`: show UI state.
- `/km ui on` / `/km ui off` / `/km ui restore`.
- `/km unlock` / `/km lock`.
- `/km hide` / `/km show`.
- `/km reset`.
- `/km scale <0.70-1.50>`.
- `/km deaths`.
- `/km criteria`.
- `/km forces`.
- `/ksm`: open/toggle dashboard.
- `/ksm show` / `/ksm hide`.
- `/ksm main` / `/ksm party` / `/ksm guild`.
- `/ksm refresh`.

## Install

1. Download the latest release zip.
2. Extract the `KeyStoneMastery` folder into:

```text
World of Warcraft/_retail_/Interface/AddOns/
```

3. Launch WoW and enable KeyStoneMastery in the addon list.
4. Run `/reload`.

### Upgrading to the renamed addon (2.0.6)

Install KeyStoneMastery as a new addon. To keep your existing settings and key history, migrate them once, with WoW closed: copy each account's `SavedVariables\KeyMaster.lua` to `SavedVariables\KeyStoneMastery.lua` and change only its top-level `KeyMasterDB =` assignment to `KeyStoneMasteryDB =`. Keep a backup, remove the old `KeyMaster` addon folder from `Interface\AddOns`, install the new folder, and enable KeyStoneMastery at character selection. Do not run both addon folders together.

From a source checkout, `tools\Install-KeyStoneMastery.ps1 -WowRoot '<path to _retail_>'` performs the same migration automatically, with backups. It is not included in the release zip.

The `/ksm` dashboard and `/km` shorthand remain available; the full help command is now `/keystonemastery`. Direct addon sync uses the renamed identifier, so both players need 2.0.6 or newer. Archived releases and backups preserve their original filenames and contents.
