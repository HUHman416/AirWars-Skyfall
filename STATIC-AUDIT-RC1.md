# AirWars: Skyfall 1.0 RC1 — Static Integration Audit

This audit was performed before the first full Garry's Mod runtime pass. It is intentionally limited to checks that can be validated from the repository/source tree and **does not certify runtime stability**.

## Passed static checks

- Expected Skyfall 1.0 server modules are present.
- Expected Skyfall 1.0 client modules are present.
- Expected Skyfall 1.0 shared modules are present.
- Required 1.0 documentation/testing files are present.
- Literal `include(...)` targets resolve within the gamemode source tree.
- Literal Skyfall/AirWars `net.Start(...)` / `net.Receive(...)` message names have matching network-string registrations in the source tree.
- `aw_test_all` is present.
- `aw_test_10` is present.
- `aw_test_all_10` is present.
- No leftover `Aetherfall` branding strings were found in the text/source files scanned.
- AirWars: Skyfall branding is present in the gamemode metadata/source.

## Not validated by this audit

The following still require the RC1 Garry's Mod playtest:

- GLua runtime/API behavior on the current GMod build.
- Source physics and moving-ship player attachment behavior.
- Client/server network serialization under real play.
- Multicrew role interactions.
- Fire, repair, armor, component damage, and ammunition behavior.
- Blueprint/prefab persistence and shipyard workflows.
- AI crew and AI ship behavior.
- PvE mission progression/objective completion.
- Boarding, capture, surrender, and sabotage.
- Weather/hazard gameplay and client visual effects.
- Progression/tutorial/cosmetic persistence.
- Victory/reset behavior after multiple consecutive rounds.
- Listen-server and dedicated-server operation.
- Linux/Windows cross-client behavior.

RC1 remains an **untested integrated release candidate**, not a stable 1.0 release.
