---
name: vpet-run
description: "Use when you need to SEE the Digimon V-Pet app actually running to visually verify the HUD or game on screen — launch the emulator, run the app, and capture a screenshot. Use after a visual/HUD change, when the user asks to run/start/screenshot the app, or to confirm rendering (glass blur, parallax, layout) that headless widget tests can't check. Handles this machine's Flutter env and the pre-made `digimon_test` AVD."
---

# /vpet-run

Launch the app on the `digimon_test` Android emulator and grab a screenshot, so
visual/HUD work can be confirmed on a real screen (not just via tests).

**Use `/vpet-verify` for tests/analyze — this skill is only for _seeing_ it run.**
`BackdropFilter` blur perf, parallax motion, and layout are things only a real
device/emulator shows.

## Environment

- Flutter SDK (not on PATH): `C:\Users\felip\flutter\bin`
- `JAVA_HOME`: `C:\Program Files\Android\Android Studio\jbr`
- Android SDK: `%LOCALAPPDATA%\Android\Sdk` (adb at `...\platform-tools\adb.exe`)
- Pre-made emulator (AVD) id: **`digimon_test`** (android-34)

## Procedure

### 1. Is a device already connected?

```bash
export PATH="/c/Users/felip/flutter/bin:/c/Users/felip/AppData/Local/Android/Sdk/platform-tools:$PATH"
export JAVA_HOME="C:/Program Files/Android/Android Studio/jbr"
flutter devices
```

If an `emulator-....` / `android` device is already listed, skip to step 3.

### 2. Launch the emulator (only if none connected)

```bash
flutter emulators --launch digimon_test
adb wait-for-device
# Block until Android finishes booting (emulator is listed long before it's ready):
until [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; do sleep 3; done
```

Booting a cold AVD takes a couple of minutes — run the launch with the Bash
tool's `run_in_background`, then poll `sys.boot_completed` on a later turn rather
than blocking one call for minutes.

### 3. Run the app (background — `flutter run` stays alive)

```bash
cd "C:/Users/felip/Documents/digimon"
flutter run -d emulator-5554 --no-version-check
```

Start this with `run_in_background: true`. Wait for the log line
`Flutter run key commands.` / `Syncing files to device` before screenshotting —
that means the first frame is up. Hot reload: while it runs, `flutter` watches
for changes; re-screenshot after an edit to see the update.

### 4. Screenshot

```bash
adb exec-out screencap -p > "C:/Users/felip/AppData/Local/Temp/claude/vpet-shot.png"
```

Then `Read` that PNG to view it, and share what the HUD/scene looks like. Take a
fresh screenshot (new filename or overwrite) after each visual change.

### 5. Stop when done

Stop the backgrounded `flutter run` task (its task id from step 3). Leave the
emulator running if more iterations are coming; otherwise it can be closed.

## Notes / gotchas

- The device id is usually `emulator-5554`; confirm with `flutter devices` and
  substitute if different.
- If `adb` isn't found, the platform-tools path above wasn't on PATH — re-export
  it (step 1).
- Release-mode rendering can differ from debug; for a true perf read of the glass
  blur, build/run in `--release` (`flutter run --release -d emulator-5554`). Note
  the project disables R8 for release (WorkManager reflection history) — that's
  expected, not a bug.
