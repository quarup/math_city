---
name: run-on-emulator
description: Launch Math City on the Android emulator and drive it (tap, screenshot, look) to visually verify a change. Use when asked to run the app, screenshot it, place buildings, or confirm a UI/Flame-canvas change works on a real device — not just `flutter test`. Android-emulator-specific; the steps below are verified for this repo.
---

# Run Math City on the Android emulator

The recipe below is verified for this machine. Follow it instead of a bare
`flutter run` — several non-obvious steps bite otherwise.

## 0. Pre-flight: clear the iCloud `* 2.*` duplicate-file pollution

This repo lives under `~/Documents`, which is iCloud-synced. Finder/iCloud
periodically creates duplicate files with a ` 2` suffix (e.g.
`libsqlite3 2.so`, `flutter_export_environment 2.sh`). A stray `… 2.so`
under `build/` makes the Android Gradle build fail at
`:app:packJniLibsflutterBuildDebug` ("Could not add file … to ZIP").

If you've just pulled/synced, or a build fails with a `packJniLibs` / ZIP
error, clean it first:

```sh
flutter clean
find . -path ./.git -prune -o -name '* 2.*' -delete
```

(`flutter clean` wipes `build/`; the `find` sweeps `.dart_tool/` and any
tracked tree. Both are safe — only generated/duplicate files match.)

## 1. Confirm the emulator is up, find `adb`

```sh
flutter devices            # expect: sdk gphone64 arm64 • emulator-5554
ADB="$HOME/Library/Android/sdk/platform-tools/adb"   # adb is NOT on PATH
"$ADB" devices
```

If no emulator is listed, start one with `flutter emulators --launch <id>`
(`flutter emulators` lists them) and wait for `"$ADB" wait-for-device`.

## 2. Launch in the background, poll the log

`flutter run` is long-lived — run it detached and tail its log; don't block
on it.

```sh
flutter run -d emulator-5554 > /tmp/mathcity_run.log 2>&1 &
```

Poll until ready (first Android build ~1–3 min; warm rebuilds ~1 min):

```sh
for i in $(seq 1 90); do
  grep -qiE "Dart VM Service|Flutter run key commands|Syncing files" /tmp/mathcity_run.log && { echo READY; break; }
  grep -qiE "BUILD FAILED|assembleDebug failed|^Error:" /tmp/mathcity_run.log && { echo FAILED; break; }
  sleep 10
done
tail -15 /tmp/mathcity_run.log
```

`FAILED` with a `packJniLibs` line → go back to step 0 and relaunch.

## 3. Screenshot — file + pull, not `exec-out`

`adb exec-out screencap -p > file.png` returns **0 bytes** on this setup.
Use the file-then-pull form:

```sh
"$ADB" -s emulator-5554 shell screencap -p /sdcard/mc.png
"$ADB" -s emulator-5554 pull /sdcard/mc.png /tmp/mc.png
```

Then **Read `/tmp/mc.png`** — actually look at it. A blank/garbled frame
means the app didn't render; don't proceed on faith.

The screen is **1080×2400** and screenshots are 1:1, so a feature's pixel
coordinates in the screenshot are the exact `input tap` coordinates.

## 4. Drive it

```sh
"$ADB" -s emulator-5554 shell input tap <x> <y>   # tap
"$ADB" -s emulator-5554 shell input swipe <x1> <y1> <x2> <y2> 300   # drag/pan
```

Tap → screenshot → look → repeat. Coordinates from the screenshot you just
read.

### Getting to the city (the usual target)

1. **Player picker** (first screen): tap a player **card body** (e.g. avatar
   face ~`380,770` for the left card) — not the green edit pencil at the
   card's top-right. Prefer a player that already has a 🧱/🔬 balance so you
   can place buildings without grinding questions first.
2. **"My City" screen** opens with the isometric board. The bottom strip is
   the build catalog (Mayor's office, Single home, Apartment, School, …).
3. **Place a building:** tap a catalog card (it gets a teal border) → tap an
   empty grass tile. Cost is deducted from the 🧱 balance shown top-right.
   Buildings with sprite art render the PNG; the rest show the colored
   box + emoji placeholder.
4. Different tiles of the same building type show different sprite variants
   (variant is picked deterministically per tile), useful for eyeballing the
   art pipeline.

## 5. Clean up

```sh
"$ADB" -s emulator-5554 shell rm -f /sdcard/mc.png
```

Leave the app running (cheap hot-reload target) or quit with `q` in the
`flutter run` session. The emulator itself can stay up between runs.
