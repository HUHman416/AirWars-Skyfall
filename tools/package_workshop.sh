#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STAGE="$ROOT/build/workshop"
GM="$STAGE/gamemodes/airwars"

rm -rf "$STAGE"
mkdir -p "$GM"

cp "$ROOT/workshop/addon.json" "$STAGE/addon.json"
cp "$ROOT/airwars.txt" "$GM/airwars.txt"

for dir in gamemode entities content; do
    if [[ -d "$ROOT/$dir" ]]; then
        cp -a "$ROOT/$dir" "$GM/$dir"
    fi
done

for file in logo.png icon24.png; do
    if [[ -f "$ROOT/$file" ]]; then
        cp "$ROOT/$file" "$GM/$file"
    fi
done

if [[ -d "$ROOT/backgrounds" ]]; then
    cp -a "$ROOT/backgrounds" "$GM/backgrounds"
fi

printf 'AirWars: Skyfall Workshop staging created at:\n  %s\n' "$STAGE"
printf 'Next: run Garry\x27s Mod gmad against that folder.\n'
