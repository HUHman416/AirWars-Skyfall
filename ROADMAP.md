# AirWars: Skyfall Roadmap

This roadmap describes the intended direction of AirWars: Skyfall. Exact features and version boundaries may change as testing reveals limitations in Garry's Mod, Source networking, physics, or the inherited AirWars codebase.

## 0.1 — Resurrection

Goal: make original AirWars reliably playable on current Garry's Mod before changing the core design.

- Fix current Lua/runtime errors.
- Restore steering and entity-control behavior.
- Repair round start, victory, reset, and respawn flows.
- Validate ship building, ship spawning, weapons, destruction, and flags.
- Audit stale Garry's Mod API usage.
- Improve defensive checks and error reporting.
- Test listen servers and dedicated servers.
- Establish Windows and Linux client testing.
- Document required content/dependencies.

## 0.2 — Foundation

Goal: establish a maintainable base for long-term development.

- Refactor high-risk legacy systems without changing intended gameplay.
- Profile expensive Think hooks, traces, networking, and ship synchronization.
- Reduce avoidable per-frame work.
- Improve network validation and state synchronization.
- Add structured debug logging and developer commands.
- Centralize server configuration and feature flags.
- Build repeatable test scenarios for rounds, ships, and weapons.
- Improve dedicated-server deployment documentation.

## 0.3 — Skyfall Crew

Goal: make operating an airship a true multicrew experience.

- Pilot, Engineer, and Gunner specialties.
- Specialties grant tools/advantages but never hard-lock basic actions.
- Repair, rebuild, extinguish, and temporary component buff mechanics.
- Component health and effectiveness states.
- Engine, lift, helm, weapon, and hull damage.
- Crew-focused HUD and ship status information.
- Spotting and target-identification systems.

## 0.4 — Fire & Steel

Goal: deepen combat beyond raw hull damage.

- Armor and penetration.
- Fire stacks, fire spread, suppression, and fire protection.
- Specialized ammunition.
- Expanded weapon families: gatlings, cannons, carronades, flak, mortars, rockets, flamethrowers, harpoons, mines, and experimental steampunk weapons.
- Distinct component, armor, and hull damage profiles.
- Weapon arcs, recoil, reload, and ammunition logistics balancing.

## 0.5 — Shipwright

Goal: make ship construction powerful without forcing every player to build from scratch every round.

- Saved ship blueprints.
- Blueprint validation/versioning.
- Prefab ships for instant play.
- Expanded construction parts and interior modules.
- Mass, lift, propulsion, turning, power, and cost statistics.
- Improved build UI and ship diagnostics.
- Server-configurable build limits.

## 0.6 — Alliance

Goal: make Skyfall worthwhile even without a large PvP population.

- PvE mission framework.
- AI-controlled enemy airships.
- AI crew capable of filling empty stations.
- Human players automatically replace bots when joining a crew.
- Crew orders and repair/weapon priorities.
- Convoy escort.
- Fortress assault.
- Airship hunt.
- Survival/wave defense.
- Salvage missions.
- Large boss encounters.

## 0.7 — Boarding Party

Goal: turn ships into physical places worth defending.

- Expanded grappling mechanics.
- Ship-to-ship boarding.
- Sabotage of internal components.
- Melee and close-range boarding weapons.
- Interior combat spaces.
- Disabled-ship capture mechanics.
- Grapple cutting and emergency disengagement.

## 0.8 — Stormfront

Goal: make the sky itself part of combat.

- Floating islands and fortresses.
- Cloud cover and fog.
- Wind and turbulence.
- Lightning and storms.
- Dangerous altitude/sky regions.
- Environmental hazards and wreckage.
- New maps built around terrain and objectives rather than empty sky.

## 0.9 — Fleet

Goal: prepare Skyfall for broad public use.

- Tutorials and training scenarios.
- Improved onboarding and contextual help.
- Server/community configuration polish.
- Accessibility and controller improvements where practical.
- Cosmetic progression: uniforms, coats, hats, goggles, titles, flags, paint, decals, and weapon appearance.
- No pay-to-win progression.
- Community extension documentation.
- Workshop packaging and distribution workflow.

## 1.0 — AirWars: Skyfall

Goal: stable public release.

A 1.0 release should provide a reliable, polished multicrew steampunk airship game with PvP, PvE, custom ship construction, prefab ships, meaningful engineering and gunnery, boarding, bots, and enough documentation for communities to host and extend it.

## Beyond 1.0

Potential post-release directions include persistent/cooperative campaigns, additional factions and ship technologies, advanced power management, larger interiors, new PvE enemy archetypes, campaign progression, community APIs, and additional maps and mission types.

## Development Disclosure

AirWars: Skyfall is developed with substantial assistance from ChatGPT by OpenAI for programming, debugging, research, design, balancing, documentation, and planning. AI-assisted material is reviewed and integrated by project maintainers. The project is independent and is not affiliated with or endorsed by OpenAI.
