# TiltMerge release checklist

Русская версия: [RELEASE_CHECKLIST.ru.md](RELEASE_CHECKLIST.ru.md)

## Verified in the repository

- Gameplay modes, onboarding, local saves, skins, achievements, localisation and local leaderboards are implemented. Localisation covers 23 languages and auto-applies the device locale on first launch.
- A/B cohorts have stable per-install assignments. `spawn_speed` changes the spawn cadence and `onboarding_style` selects interactive or slide onboarding.
- The Android presets enable vibration and internet access. The latter is required only for optional online services.
- CI validates scripts, tests, translations and release-critical configuration.

## Required before an external release

1. Create a Firebase Android application for `com.akarakuts.tiltmerge`, keep `google-services.json` out of Git, then install and verify the Godot Firebase plugin.
2. Create a Play App Signing key and provide the signing values only through local `export_presets.local.cfg` or GitHub Actions secrets. Tag builds require `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD` and `ANDROID_KEY_ALIAS`.
3. Build a signed `.aab`, upload it to Play Console Internal Testing, and test install, audio, haptics and tilt on at least one low-end device.
4. Publish a privacy policy at a stable URL and complete Play Data safety from the actual SDKs enabled in the build.
5. If optional analytics is enabled, verify `game_start`, `merge`, `game_over`, `daily_played` and `skin_selected` in DebugView, then set a staged rollout.
6. In Play Console, upload the localised Store Listing for every available locale (`translations/*.csv` lists the 23 supported languages).

## Release gates

- `./scripts/run_tests.sh` exits successfully.
- `python3 scripts/validate_release.py` exits successfully.
- The full [Android device QA gate](DEVICE_QA.md) passes for the exact release commit.
- All external service credentials are present only in secure local or CI secret storage.
