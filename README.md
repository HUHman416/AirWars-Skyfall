# AirWars: Skyfall

**AirWars: Skyfall** is an open-source continuation and modernization of the original **AirWars** Garry's Mod gamemode by The HellBox and its contributors.

Skyfall's long-term goal is to preserve AirWars' freeform steampunk ship-building while expanding it into a modern multicrew airship-combat game inspired by the teamwork, engineering, gunnery, and PvE strengths of games such as *Guns of Icarus*.

> **Development disclosure:** AirWars: Skyfall is developed with substantial assistance from **ChatGPT by OpenAI**, including programming, debugging, game design, balancing, documentation, research, and development planning. AI-assisted material is reviewed and integrated by the project maintainers. AirWars: Skyfall is an independent community project and is not affiliated with or endorsed by OpenAI.

## Current Status

**Version:** 0.1.0-skyfall-dev  
**Milestone:** 0.1 — Resurrection

The current milestone intentionally focuses on restoring the original AirWars gameplay on modern Garry's Mod before adding major new mechanics.

### Resurrection goals

- Restore reliable ship steering and controls.
- Repair round start/reset logic.
- Eliminate current Lua errors and stale API assumptions.
- Verify building, ship spawning, combat, destruction, victory, and round reset.
- Improve error handling and diagnostics.
- Establish reliable dedicated-server operation.
- Test Windows and Linux clients.
- Preserve original gameplay until the baseline is stable.

## Developer Testing

Skyfall includes an admin/server-console test harness so repeatable compatibility checks do not need to be performed by hand.

A typical v0.1 local test is:

```text
aw_test_devmode 1
aw_test_all
aw_test_buildship
aw_test_startfight
aw_test_all
```

The test harness can generate a standardized ship containing the legacy helm, propulsion/lift components, player spawn, ammunition storage, and every current ship weapon. It can also force round transitions, reset rounds, inspect active ships, and run automated `PASS` / `WARN` / `FAIL` smoke tests.

See [TESTING.md](TESTING.md) for the full command reference and manual regression checklist.

## Skyfall Vision

After the original gamemode is stable, planned systems include:

- Pilot, Engineer, and Gunner specialties without hard class restrictions.
- Component-based ship damage and repair gameplay.
- Fire, armor, penetration, and specialized ammunition.
- Expanded steampunk weapons and ship components.
- Saved ship blueprints and ready-to-play prefab ships.
- Boarding, grappling, sabotage, and ship capture.
- PvE / Alliance missions, AI airships, and AI crew.
- Floating islands, fortresses, storms, fog, and environmental hazards.
- Meaningful ship interiors including engineering spaces, magazines, bridges, and gun decks.
- Tutorials, bots, accessibility improvements, and modern UI/HUD work.
- Workshop-friendly extension points for community ships, weapons, maps, and missions.
- Cosmetic-only progression if progression is introduced; no pay-to-win gameplay systems.

See [ROADMAP.md](ROADMAP.md) for the development plan.

## Original AirWars

AirWars is a unique gamemode where players build their own steampunk ships and fight other crews. The original project includes custom assets and music, character customization, destructible ships, custom flags, and support for large multi-ship battles.

Original project: **TheHellBox/AirWars**  
Original author: **The HellBox**

AirWars: Skyfall preserves the original project's copyright and MIT license. See [LICENSE](LICENSE).

## For Server Owners

The original AirWars code is CPU intensive. Performance and networking are explicit priorities for Skyfall, but the Resurrection milestone should initially be treated as development/testing software rather than a production-ready server gamemode.

## Contributing

Skyfall is being developed openly. Bug reports, testing results, profiling data, fixes, maps, models, balance feedback, and feature proposals are welcome as the project matures.

When reporting a bug, please include:

- Garry's Mod branch/build if relevant.
- Client OS (Windows/Linux).
- Whether the issue occurs in single-player, listen server, or dedicated server.
- Relevant console/Lua errors.
- Reproduction steps.
- Output from `aw_test_all` when applicable.

## Credits

### Original AirWars
- The HellBox
- Original AirWars contributors

### AirWars: Skyfall
- HUHman416 — Project maintainer
- Community contributors

### Development Assistance
- **ChatGPT by OpenAI** — programming, debugging, design assistance, documentation, research, and development planning

AirWars: Skyfall is not affiliated with Valve, Facepunch Studios, Muse Games, or OpenAI.
