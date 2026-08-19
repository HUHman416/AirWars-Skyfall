# AirWars: Skyfall — Garry's Mod Menu Assets

Garry's Mod gamemode presentation assets belong at the root of the internal `airwars` gamemode folder:

```text
garrysmod/gamemodes/airwars/
├── logo.png
├── icon24.png
└── backgrounds/
    └── skyfall_menu.jpg
```

For **RC1**, the Skyfall-branded art is being distributed alongside the test build while binary-asset upload through the repository integration is being resolved.

- `logo.png` — AirWars: Skyfall main-menu logo with a small ChatGPT development credit.
- `icon24.png` — compact gamemode-selector icon.
- `backgrounds/skyfall_menu.jpg` — steampunk parchment menu background derived from the project-supplied artwork.

These assets are cosmetic and do not affect gameplay/runtime validation.

## Expected result

When AirWars: Skyfall is selected as the active gamemode and Garry's Mod is restarted/reloaded as necessary, the main menu should use the Skyfall logo/background and the gamemode selector should use the Skyfall icon rather than the original AirWars artwork.
