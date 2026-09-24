# Retail 12.0.5 Readiness Checklist

This checklist is for launch-day validation after the Retail 12.0.5 patch goes live.

## Metadata

- Confirm [KeyStoneMastery.toc](KeyStoneMastery.toc) has `## Interface: 120005`.
- Log in and verify the addon loads without an out-of-date warning.

## Keystone Data APIs

- Verify `C_MythicPlus.GetOwnedKeystoneChallengeMapID()` returns the expected map ID.
- Verify `C_MythicPlus.GetOwnedKeystoneLevel()` returns the expected key level.
- Verify keystone link fallback still works via `C_Container.GetContainerItemLink()` bag scan.

## Chat Command Flow

- In party chat, send `!key` and confirm `KeyStoneMastery: [keystone link]` reply.
- In party chat, send `!score` and confirm score reply.
- In party chat, send `!best` and confirm weekly and season best summary.

## Guild Sync Flow

- Open `/ksm guild` and press request refresh.
- Confirm the addon sends a guild sync request and receives responses.
- Confirm malformed or partial addon payloads do not throw Lua errors.
- Confirm guild rows update with map, level, and rating values.

## Mythic+ Run State UI

- Enter an active M+ run and verify timer, objectives, deaths, and forces update.
- Complete a run and confirm completion summary appears and updates timing from API.
- Exit/reset run and confirm state clears without stale data in the overlay.

## Regression Watchlist

- Event registration: no forbidden `RegisterEvent` errors.
- Addon messaging: no prefix-registration or channel errors.
- Combat safety: deferred chat messages flush after combat ends.

## Post-Validation

- If all checks pass, tag the next release as Retail 12.0.5 validated.
- If an API behavior changed, patch wrapper/fallback functions first in [KeyStoneMastery.lua](KeyStoneMastery.lua) and [KeyStoneMastery.Sync.lua](KeyStoneMastery.Sync.lua).

## Validation Status

- Release `1.8.3` prepared on 2026-04-21 with `## Interface: 120005`.
