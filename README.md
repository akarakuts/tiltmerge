# TiltMerge

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)

Russian / Русский: [README.ru.md](README.ru.md)

**TiltMerge** — a fast physics-merge puzzle for Android: tilt the phone so matching cubes collide and level up (inspired by 2048 / Threes / Suika Game). Built with **Godot 4.3+** and **GDScript**.

## Features

- **Core loop** — cubes spawn from the top; tilt (or swipe) to roll them; same **tier** cubes merge into the next tier; overflow past the ceiling line ends the run (with a short grace period).
- **Tilt controls** — accelerometer as the primary input; swipe/touch fallback for desktop and emulator; keyboard A/D or ←/→ for debug.
- **Tactics** — next-cube preview, combo-earned **reroll** charges, combo multiplier window (~2 s).
- **Modes** — Classic, Blitz (60 s), Zen (no game over), Daily (seeded sequence + target tier).
- **Meta** — local best scores, achievements, unlockable skins, onboarding (interactive or slide A/B), EN/RU localisation.
- **Juice** — haptics, camera shake, squash/stretch, glow shader, floating score text, SFX/music (optional assets).
- **Data-driven balance** — tiers, spawn curve, tilt, combo, and modes live in `data/config.json` (see `docs/BALANCE.md`).

## Godot stack

| Area | Choice |
|------|--------|
| Engine | Godot **4.3+** (project tested on 4.7.x) |
| Language | GDScript |
| Physics | Godot 2D (`RigidBody2D` cubes) |
| Architecture | Autoloads: `GameConfig`, `SaveSystem`, `GameManager`, `AudioManager`, `Haptics`, … |
| Saves | `user://save.json` |
| Locales | `translations/en.csv`, `translations/ru.csv` |
| Export | Android Debug / Release presets in `export_presets.cfg` |

## Requirements

- **Godot 4.3+** with Android export templates matching the editor version
- **JDK 17+** (signing / Android build-tools)
- **Android SDK** (`ANDROID_HOME`); min API **24**, package `com.akarakuts.tiltmerge`
- Optional: device or emulator for install/smoke tests

## CI & automation

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| [Build Android](.github/workflows/build.yml) | push / PR to `main`/`dev`, tag `v*`, manual | Import, gdlint, `validate_release.py`, `./scripts/run_tests.sh`, translation parity, debug APK artifact; on `v*` — signed AAB when secrets are set |

## Build & run

### Editor

1. Install Godot 4.3+ (`brew install --cask godot` or [godotengine.org](https://godotengine.org/download)).
2. Open / import this folder (`project.godot`).
3. Press **F5** — main scene is `scenes/MainMenu.tscn`.

### Headless tests

```bash
./scripts/run_tests.sh
python3 scripts/validate_release.py
./scripts/check_strings_parity.sh
```

### Debug APK (CLI)

```bash
mkdir -p build
godot --headless --path . --import
godot --headless --path . --export-debug "Android Debug" build/tiltmerge-debug.apk
adb install -r build/tiltmerge-debug.apk
adb shell monkey -p com.akarakuts.tiltmerge -c android.intent.category.LAUNCHER 1
```

For **signed release** builds, see [Release signing](#release-signing).

## Release signing

Android presets are in `export_presets.cfg`. Keep **keystore passwords and paths out of Git**.

### 1. Create an upload keystore (once)

```bash
keytool -genkeypair -v \
  -keystore tiltmerge.keystore \
  -alias tiltmerge \
  -keyalg RSA -keysize 2048 -validity 10000
```

Back up the keystore — without it you cannot ship compatible store updates.

### 2. Local signed export

1. Point `keystore/release` (and passwords) via Godot **Editor → Export…** or a local override such as `export_presets.local.cfg` (gitignored if you add it).
2. Export **Android Release** (AAB) or use:

```bash
./scripts/build_release.sh
```

(`store-upload.dir` — see `store-upload.dir.example` if present.)

### 3. GitHub Actions tag releases (`v*`)

Configure repository secrets (Settings → Secrets and variables → Actions):

| Secret | Value |
|--------|-------|
| `ANDROID_KEYSTORE_BASE64` | Base64 of the upload keystore |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password |
| `ANDROID_KEY_ALIAS` | Key alias (e.g. `tiltmerge`) |

The release job in [build.yml](.github/workflows/build.yml) attaches signed artifacts to the GitHub Release when these secrets are present.

External Play Console / Firebase steps: [docs/RELEASE_CHECKLIST.md](docs/RELEASE_CHECKLIST.md), [docs/SOFT_LAUNCH.md](docs/SOFT_LAUNCH.md).

## Project layout

| Path | Role |
|------|------|
| `scenes/` | Main menu, game, settings, onboarding, skins, leaderboard |
| `scripts/Cube.gd`, `MergeLogic.gd`, `Spawner.gd`, `TiltController.gd` | Core gameplay |
| `scripts/Game.gd` | Mode orchestration, HUD, game over |
| `scripts/GameConfig.gd` | Loads `data/config.json` / `skins.json` |
| `scripts/SaveSystem.gd` | Progress, settings, daily streak |
| `data/config.json` | Balance source of truth |
| `tests/` | Unit + gameplay + onboarding headless suites |
| `docs/` | GDD, BALANCE, PRIVACY, soft launch, release checklist |
| `store/` | Play listing copy |
| `shaders/` | Glow and related effects |

## Testing

```bash
./scripts/run_tests.sh
```

| Suite | Location | Coverage |
|-------|----------|----------|
| Unit / runner | `tests/TestRunner.gd` | Config, save, i18n helpers |
| Onboarding | `tests/OnboardingTest.gd` | Interactive + slide flows |
| Gameplay | `tests/GameplayTest.gd` | Spawn/merge, pause, reroll, game over, daily bonus |
| Strings | `scripts/check_strings_parity.sh` | EN/RU CSV key parity |
| Release config | `scripts/validate_release.py` | Store/export sanity |

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/run_tests.sh` | Headless Godot test suite |
| `scripts/validate_release.py` | Release-critical config checks |
| `scripts/check_strings_parity.sh` | EN/RU translation key parity |
| `scripts/build_release.sh` | Export APK into path from `store-upload.dir` |
| `scripts/generate_sounds.py` | Procedural WAV SFX/music stubs |
| `scripts/generate_assets.py` | Icon / store graphic helpers |

## Contact

**Aleksey Karakuts** — [aleksey@karakuts.com](mailto:aleksey@karakuts.com)

## License

This program is free software: you can redistribute it and/or modify it under the terms of the **GNU General Public License** as published by the Free Software Foundation, either **version 3** of the License, or (at your option) any later version.

See the [`LICENSE`](LICENSE) file for the full GPLv3 text.

Copyright (C) 2026 Aleksey Karakuts &lt;aleksey@karakuts.com&gt;
