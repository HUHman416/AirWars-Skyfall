# AirWars: Skyfall — Server Guide

AirWars: Skyfall is a Garry's Mod gamemode. The repository checkout must be installed as the internal gamemode folder `garrysmod/gamemodes/airwars` even though the project/repository is named AirWars-Skyfall.

## Development checkout

```bash
cd /path/to/GarrysMod/garrysmod/gamemodes
git clone https://github.com/HUHman416/AirWars-Skyfall.git airwars
cd airwars
git switch agent/skyfall-1.0-development
```

Update with:

```bash
git pull --ff-only
```

## Recommended server workflow

1. Start with a listen server for basic validation.
2. Use a dedicated server before public deployment.
3. Keep `aw_skyfall_profile` available while tuning player/AI counts.
4. Run the automated Skyfall tests after updates.
5. Test at least one full PvP round and one Alliance mission after major updates.

## Server convars

| ConVar | Default | Purpose |
| --- | ---: | --- |
| `aw_skyfall_enable_pve` | `1` | Alliance missions and AI ships |
| `aw_skyfall_enable_boarding` | `1` | Boarding/capture systems |
| `aw_skyfall_enable_weather` | `1` | Stormfront environmental physics |
| `aw_skyfall_auto_weather` | `1` | Random weather selection at round start |
| `aw_skyfall_enable_blueprints` | `1` | Blueprint/prefab loading |
| `aw_skyfall_ai_difficulty` | `1.0` | Global Alliance AI skill multiplier (`0.5`–`2.0`) |

Use `aw_server_settings` from server console/admin client to print the active values.

## Useful admin/developer commands

- `aw_skyfall_version`
- `aw_skyfall_status`
- `aw_skyfall_features`
- `aw_skyfall_profile`
- `aw_skyfall_profile_reset`
- `aw_test_all`
- `aw_test_roundtrip`
- `aw_weather <clear|fog|gale|storm|aether|random>`
- `aw_pve_start <hunt|fortress|survival|convoy|salvage|boss>`
- `aw_pve_stop`
- `aw_training`
- `aw_training_end`

## Performance

Skyfall modernizes several original AirWars hot loops, but the gamemode still performs custom ship physics, virtual-space collision checks, client-side model rendering, projectile simulation, and optional AI/weather systems. Profile your intended player/ship count rather than assuming sandbox-scale limits.

The `aw_skyfall_profile` command reports timing samples collected by Skyfall systems such as ship controls, cross-ship collision checks, projectile collision, weather, fire simulation, and AI.

## Persistence

Player cosmetics/points use the existing AirWars data directory. Skyfall blueprints are stored server-side under:

`garrysmod/data/airwars_skyfall/blueprints/<SteamID64>/`

Back up the `garrysmod/data` directory before migrations or server moves.

## Security posture

Skyfall validates/rate-limits high-risk client network actions such as prop spawning, team actions, flag updates, and ship-part synchronization. Server owners should still keep Garry's Mod and installed dependencies current and review third-party addons that interact with AirWars entities/network strings.
