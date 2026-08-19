# Contributing to AirWars: Skyfall

AirWars: Skyfall is an open-source continuation of The HellBox's original AirWars Garry's Mod gamemode. Contributions are welcome in code, testing, balance, maps, models, sound, UI, documentation, profiling, and game design.

## AI-assisted development disclosure

Skyfall is developed with substantial assistance from **ChatGPT by OpenAI**. Assistance includes programming, debugging, design exploration, balance work, documentation, research, and development planning. AI-assisted material is reviewed and integrated by human project maintainers.

Contributors may use AI-assisted tools, but remain responsible for reviewing what they submit, respecting licenses/copyright, and accurately describing third-party material. AirWars: Skyfall is independent and is not affiliated with or endorsed by OpenAI.

## Development workflow

- Keep changes focused and reviewable.
- Preserve the original AirWars MIT license and attribution.
- New gameplay systems should add or extend developer tests where practical.
- Do not introduce pay-to-win mechanics.
- Avoid silently requiring new Workshop dependencies; document them explicitly.
- Prefer data-driven weapons/ships/missions over duplicated one-off implementations.
- Validate network messages on the server and rate-limit actions that can be spammed.

## Testing

At minimum for gameplay changes:

1. Run `aw_test_all`.
2. Exercise the changed feature directly.
3. Check client and server consoles for Lua errors.
4. Verify a round can still reset cleanly.

Milestone/public releases should also test:

- PvP with two real teams.
- At least one Alliance mission.
- Dedicated server operation.
- A second round after reset.
- Ship building/prefab loading.
- Components, fire, repair/rebuild, and ammunition.
- Boarding/capture.
- Weather.
- Windows and Linux clients when testers are available.

See `TESTING.md` for the current automated commands.

## Bug reports

Include:

- Skyfall version/commit if known.
- Garry's Mod branch/build.
- Client OS.
- Listen server or dedicated server.
- Exact reproduction steps.
- Relevant console/Lua errors.
- Screenshot/video when the issue is visual or physics-related.
