# Android device QA gate

Русская версия: [DEVICE_QA.ru.md](DEVICE_QA.ru.md)

Run this checklist on a signed release AAB from the exact commit that will be
submitted to a store. Use at least one low-end Android device and one current
device; test both portrait orientations supported by the target devices.

## Install and lifecycle

- Install the release build over the previous store build and launch it.
- Start a new game, background the app for 30 seconds, then return to it.
- Force-close and relaunch the app; verify settings, score and selected skin
  persist.
- Uninstall and reinstall; verify first-run onboarding starts normally.

## Gameplay

- Complete the interactive onboarding with tilt and with swipe control.
- In Classic, roll a cube into each bottom corner and move it back out.
- Pause with the UI and with the device/system back or keyboard pause action;
  resume successfully in both cases.
- Complete a merge, use a reroll, then finish a Classic game by overflow.
- Start Zen and confirm overflow does not end the session; start Blitz and
  confirm the timer ends it.

## Device integration

- Check tilt direction in portrait orientation and ensure it is stable after
  rotation or resume.
- Verify sound volume, music volume, haptics and Reduce Motion settings; confirm that dragging the volume sliders persists a single save (debounced) instead of writing on every tick.
- On a clean install, confirm the UI language matches the device Android locale; then open Settings, switch language explicitly, and confirm every label relabels immediately and survives a relaunch.
- Inspect logcat for fatal exceptions and Godot script errors after a 10-minute
  session.

## Exit criterion

Record device model, Android version, APK/AAB version, commit SHA, tester and
result. A release candidate passes only when every item above passes on both
devices and the CI quality gate is green.
