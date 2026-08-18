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

### Developer testing
- Added a server-side Skyfall developer test harness.
- Added `aw_test_all` automated `PASS` / `WARN` / `FAIL` smoke testing for core globals, configuration, round state, entities, SWEPs, network strings, teams, players, and active ships.
- Added `aw_test_buildship` to generate a standardized ten-part test craft containing the helm, propulsion/lift, spawn, ammo storage, cannon, rifle, grappling hook, and bomb.
- Added commands for developer mode, immediate fight start, round reset, timer control, respawn, status/ship inspection, and destructive round-trip validation.
- Added `TESTING.md` with the fast local workflow and manual regression checklist.

### Still to verify in-game
- Building phase completes and transitions into combat.
- Spawned ships respond to helm controls.
- Weapons fire and damage ship parts correctly.
- Destroyed/defeated teams trigger the intended victory flow.
- Round reset returns all players and state to a clean build phase.
- Listen-server and dedicated-server behavior.
- Windows and Linux client behavior.

This development build is not yet considered a stable release.
