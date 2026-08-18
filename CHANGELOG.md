# Changelog

All notable changes to **AirWars: Skyfall** will be documented here.

## 0.1.0-skyfall-dev — Resurrection

### Branding and project setup
- Renamed the in-game gamemode title to **AirWars: Skyfall**.
- Added explicit original-AirWars attribution and MIT-license preservation language.
- Added visible disclosure that development is being carried out with substantial assistance from ChatGPT by OpenAI.
- Added the long-term Skyfall roadmap.
- Removed the inherited original Workshop ID from the Skyfall gamemode metadata so development builds do not identify themselves as the upstream Workshop item.

### Compatibility and stability
- Fixed ship-control release handling that referenced `player` instead of the active `ply` argument.
- Removed an empty per-frame ship `Think` hook.
- Hardened ship position/control loops against missing ship tables.
- Fixed round reset so an incompatible `aw*` entity is skipped instead of aborting the entire reset routine.
- Added safer team-state synchronization when a team has no connected players.
- Hardened player collision traces against entities that do not expose AirWars team helpers.
- Added validity checks around ragdoll removal and delayed respawn callbacks.
- Hardened shared team/name/leader helpers against missing team state.
- Hardened physgun ownership checks against invalid/non-AirWars entities.
- Corrected the rare team-ID collision retry path so it no longer attempts to call the generated ID as a function.
- Updated the runtime gamemode name to **AirWars: Skyfall**.

### Developer testing
- Added a server-side Skyfall developer test harness.
- Added `aw_test_all` automated `PASS` / `WARN` / `FAIL` smoke testing for core globals, configuration, round state, entities, SWEPs, network strings, teams, players, and active ships.
- Added `aw_test_buildship` to generate a standardized test craft containing the helm, propulsion/lift, spawn, ammo storage, cannon, rifle, grappling hook, and bomb.
- Expanded the generated test craft to 15 parts with a six-plate 3x2 metal deck so players have a practical surface to stand and move on during physics testing.
- Fixed listen-server test output appearing twice by routing player-issued test output only to the issuing player's console and server-console-issued tests only to the server console.
- Added commands for developer mode, immediate fight start, round reset, timer control, respawn, status/ship inspection, and destructive round-trip validation.
- Added `TESTING.md` with the fast local workflow and manual regression checklist.

### First local playtest
- First local/listen-server Resurrection smoke test completed with **42 PASS / 1 expected WARN / 0 FAIL** after round reset.
- Core human-facing gameplay tested in the first pass appeared functional.
- The only test-craft usability issue observed was the original generated ship's undersized single-plate deck; this is addressed by the expanded test craft above.
- The single warning after reset was expected: no active ships exist during the BUILDING phase.

### Still to verify in-game
- Re-test the expanded generated ship deck and single-output test console behavior.
- Full weapon/component behavior on the improved test craft.
- Destroyed/defeated teams trigger the intended victory flow with two real teams.
- The second full round behaves correctly after reset.
- Dedicated-server behavior.
- Windows client behavior in addition to the current Linux/listen-server pass.

This development build is not yet considered a stable release.
