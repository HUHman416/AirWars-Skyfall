# AirWars: Skyfall — Workshop Packaging

Skyfall's GitHub repository is a development source tree. Garry's Mod Workshop packaging expects the gamemode inside a `gamemodes/airwars` directory, so use the included staging script rather than uploading the repository root directly.

## 1. Build the staging directory

From the repository root on Linux/macOS:

```bash
bash tools/package_workshop.sh
```

This creates:

```text
build/workshop/
├── addon.json
└── gamemodes/
    └── airwars/
        ├── airwars.txt
        ├── gamemode/
        ├── entities/
        ├── content/
        ├── logo.png          (when present)
        ├── icon24.png        (when present)
        └── backgrounds/      (when present)
```

The script intentionally does not publish anything by itself.

## 2. Create the GMA

Use the `gmad` executable shipped with Garry's Mod to create a `.gma` from `build/workshop`.

Example Linux layout:

```bash
/path/to/GarrysMod/bin/gmad_linux create \
  -folder build/workshop \
  -out build/AirWars-Skyfall.gma
```

Executable names/locations can differ by platform and Garry's Mod installation.

## 3. Publish/update

Use Garry's Mod's `gmpublish` tool with the generated GMA and Workshop preview image. Once the public Skyfall Workshop item exists, **update that same item for later releases** rather than creating a new Workshop entry for each version.

Keep a separate hidden/unlisted development Workshop item if easy multiplayer playtesting is desired. The public item should track stable releases only.

## Required public attribution

Workshop descriptions should include:

> AirWars: Skyfall is an open-source continuation of the original AirWars gamemode by The HellBox and contributors. Skyfall is developed with substantial assistance from ChatGPT by OpenAI for programming, debugging, design, documentation, research, and planning. AI-assisted material is reviewed and integrated by the project maintainers. This independent community project is not affiliated with or endorsed by OpenAI.

Keep the original MIT license/copyright notice in distributed source where required.

## Menu assets

Garry's Mod gamemode presentation assets belong directly inside the `airwars` gamemode folder:

- `logo.png`
- `icon24.png`
- `backgrounds/*.jpg`

The packaging script copies these automatically when they are present in the repository.
