# AirWars: Skyfall 1.0 RC1

**Status:** Integrated release candidate — not yet runtime-validated as a stable 1.0 release.

This branch contains the full planned 0.2 through 1.0 feature stack built on top of the 0.1 Resurrection work. It is intentionally being tested as one integrated build, per the project development plan.

## Included milestone stack

- **0.1 — Resurrection:** modern-GMod compatibility, round/helm stability fixes, diagnostics, developer test harness.
- **0.2 — Foundation:** configuration/state helpers, player metadata, performance and networking foundation.
- **0.3 — Skyfall Crew:** Pilot, Engineer, and Gunner specialties and crew HUD support.
- **0.4 — Fire & Steel:** component health, armor, fire, disabling, repair, ammo profiles, and the expanded damage pipeline.
- **0.5 — Shipwright:** ship classes, prefabs, blueprint save/load/import/export, and shipyard UI.
- **0.6 — Alliance:** PvE objectives, AI ships/crew, escort, fortress, survival, hunts, salvage, and boss-style encounters.
- **0.7 — Boarding Party:** grappling/boarding sessions, sabotage, capture, surrender, and boarding tools/HUD.
- **0.8 — Stormfront:** weather, wind, storms, lightning, fog, local hazards, and environmental HUD/effects.
- **0.9 — Fleet:** persistence, progression/stat tracking, commendations, tutorials, cosmetics, credits, and fleet UI.
- **1.0 — Integration/Public Contract:** consolidated APIs, version/readiness surfaces, documentation, and full-suite developer testing.

## Test policy

RC1 is deliberately **not** labelled stable until it survives the integrated Garry's Mod playtest. Bugs are expected. The milestone commit history is preserved so regressions can be bisected back to the subsystem that introduced them.

Start with:

```text
aw_test_devmode 1
aw_test_all
aw_test_10
aw_test_all_10
```

Then follow `TESTING-1.0.md` for the manual multiplayer/physics/gameplay pass.

## Attribution

AirWars: Skyfall is an open-source continuation of the original AirWars project and preserves the original MIT licensing/attribution requirements.

Skyfall is developed with substantial assistance from **ChatGPT by OpenAI**, including programming, debugging, game design, balancing, documentation, research, and development planning. AI-assisted material is reviewed and integrated by the project maintainers. AirWars: Skyfall is an independent community project and is not affiliated with or endorsed by OpenAI.
