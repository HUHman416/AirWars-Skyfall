# AirWars: Skyfall Testing

Skyfall includes a server-side developer test harness so most repeatable checks do not have to be performed by hand.

All state-changing test commands require an administrator or the server console. `aw_test_buildship` and `aw_test_respawn` must be run by an in-game admin player because they operate on the issuing player/team.

## Fast local v0.1 test

For a quick Resurrection pass:

1. Start an AirWars: Skyfall map and join the server.
2. Open the developer console.
3. Run:

```text
aw_test_devmode 1
aw_test_all
aw_test_buildship
aw_test_startfight
aw_test_all
```

4. Manually verify that the generated craft can be controlled and that its weapons can be used.
5. Run:

```text
aw_test_reset
aw_test_all
```

The goal is to verify the entire `BUILDING -> FIGHT -> BUILDING` loop without manually waiting for either round timer.

## Commands

### `aw_test_help`
Prints the current developer-test command list.

### `aw_test_all`
Runs the non-destructive automated smoke test and prints `PASS`, `WARN`, or `FAIL` for core systems including:

- AirWars globals and registries
- required round/ship functions
- build/fight timers and configuration
- current game state
- required scripted entities
- required player SWEPs/tools
- important network strings
- team registration and leaders
- player/team consistency
- active ship structures
- helm and player-spawn presence during combat

A warning is not automatically a broken test. For example, having no active ships during the build phase is expected.

### `aw_test_status`
Prints a compact snapshot of the current state, timer, team count, active ship count, build-prop count, and developer-mode status.

### `aw_test_buildship`
Deletes the issuing admin player's existing build props and creates a standardized ten-part v0.1 test craft containing:

- hull plate
- steering wheel
- sail
- balloon
- player spawn
- ammunition storage
- cannon
- rifle
- grappling hook
- bomb

This is intended to replace repetitive hand-building during compatibility testing.

### `aw_test_ship [team id]`
Prints structural information for an active ship. If no team ID is supplied, Skyfall tries the issuing player's current ship and then the first active ship.

### `aw_test_devmode [0|1]`
Toggles developer mode. Developer mode is useful for solo testing because vanilla AirWars normally requires multiple teams to begin a timed round and automatically ends a fight when only one team remains.

### `aw_test_time <seconds>`
Changes the current round timer without waiting. The original `set_time` command remains available for compatibility.

### `aw_test_startfight`
Immediately invokes the normal AirWars fight-start path. When only one team exists, it automatically enables developer mode so the winner check does not instantly reset the round.

### `aw_test_reset`
Immediately invokes the normal AirWars round-reset path and returns to the build phase.

### `aw_test_respawn`
Respawns the issuing admin player through the normal player spawn path.

### `aw_test_roundtrip`
**Destructive.** Requires build props and automatically performs:

```text
BUILDING
   -> StartRound
FIGHT
   -> automated smoke test
ResetRound
   -> BUILDING
```

It reports whether both state transitions succeeded. The build is consumed by the normal fight-start process and the resulting combat entities are removed by the normal round reset.

## What remains manual in v0.1

The harness can validate state and data, but Source/Garry's Mod physics and player-facing behavior still require observation. For the Resurrection milestone, manually verify:

- steering wheel input moves and turns the ship correctly
- ascend/descend controls behave correctly
- players remain positioned correctly on moving ships
- cannon fires and damages ship parts
- rifle fires and damages ship parts
- grappling hook behaves correctly
- bomb behaves correctly
- ammunition interaction works
- destroyed parts are removed/damaged correctly
- death and respawn behavior works during combat
- victory detection works with two real teams
- the second round after a reset behaves like the first
- no Lua errors appear in server or client console

As new Skyfall systems are added, their automated checks and test fixtures should be added to this harness rather than creating separate one-off test code.

## Testing philosophy

- Every meaningful code change gets a quick smoke test.
- Every numbered milestone gets a full regression pass.
- Public/Workshop releases get multiplayer, listen-server, and dedicated-server testing.
- Automated tests should accelerate repetitive validation, but physics, visuals, feel, networking under real players, and user experience still require human playtesting.
