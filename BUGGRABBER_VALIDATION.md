# 2.0.7 regression validation

Run `lua tools/test-buggrabber.lua` from this checkout. It loads the complete TOC with a client mock that rejects combat-log registration and access to the shared Blizzard tooltip. It checks later chat/death event registration, private tooltip ownership, tracker method/parent preservation, combat deferral, original-alpha restoration, and death counting across resurrection and restricted values.

After installing, reload the UI before testing; replacing Lua files does not change code already loaded by WoW. Existing BugGrabber records are cumulative and can retain older errors.

1. Confirm version 2.0.7 loads and `/ksm` opens without an event-registration error.
2. Hover a delve map marker, then addon portal/affix/death tooltips, then the map marker again. Check for fresh secret-number tooltip errors.
3. Start a key, test tracker suppression, and finish/reset the run. Confirm the Blizzard tracker returns, its controls behave normally, and no new restricted-aura errors appear.
4. Verify the official death total, optional per-player death attribution, and timer. Restricted player data is skipped; native secret values cannot be reproduced by the mock.

The removed Show override/reparenting and shared-tooltip calls are plausible sources of the captured Blizzard UI taint. Those specific native error signatures still require a fresh in-game check; unit tests cannot establish that another addon will not taint the same UI.

API evidence: Blizzard's generated [combat-log event documentation](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/CombatLogDocumentation.lua) marks the unfiltered event as restricted. The [tooltip source](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_GameTooltip/Mainline/GameTooltip.lua) stores widget state on the tooltip instance.
