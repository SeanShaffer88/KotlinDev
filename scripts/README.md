# Scripts — adb, emulator, and release helpers

Ready-to-run command-line helpers for the everyday Android development
loop: build/install/launch, logs, captures, app operations, emulator
boot, keystore creation, deep-link testing, and App Bundle verification.

Every helper comes as a **pair** with identical options and behaviour:

- `name.sh` — Bash (Linux, macOS, Git Bash / WSL on Windows)
- `name.ps1` — PowerShell (Windows; also works on PowerShell 7 anywhere)

Every script prints usage with `--help` (Bash) or `-Help` (PowerShell),
checks its requirements before acting, and contains no secrets.

## The scripts

| Script | Purpose |
|---|---|
| `adb-install-launch` | Build the debug APK, install it, and launch the app. |
| `adb-logcat-app` | Stream logcat filtered to one running app's process. |
| `adb-capture` | Save a timestamped screenshot, and optionally a screen recording. |
| `adb-app-ops` | Force-stop, grant/revoke permissions, open app settings, reset app data. |
| `emulator-boot` | List AVDs, boot one (headless option), and wait until it is ready. |
| `keystore-create` | Guided release keystore creation with keytool + a password-free properties template. |
| `deeplink-test` | Fire a deep link at an app and inspect App Links verification state. |
| `play-bundle-verify` | Build a universal APK from an `.aab` with bundletool and install it. |

## Usage examples

```bash
# Build, install, and launch your app
./adb-install-launch.sh --package com.example.app
./adb-install-launch.sh --package com.example.app --apk ./app-debug.apk

# Follow only your app's logs (Ctrl+C to stop), saving a copy
./adb-logcat-app.sh --package com.example.app --clear --save log.txt

# Screenshot now, or screenshot + a 30-second recording
./adb-capture.sh --out ./shots
./adb-capture.sh --out ./shots --record 30

# App operations: permissions, settings, force-stop
./adb-app-ops.sh --package com.example.app --grant android.permission.CAMERA
./adb-app-ops.sh --package com.example.app --settings
./adb-app-ops.sh --package com.example.app --reset        # asks for confirmation

# Emulators: see what exists, then boot one headless
./emulator-boot.sh --list
./emulator-boot.sh --avd Pixel_8_API_36 --headless

# Create a release (upload) keystore — guided prompts
./keystore-create.sh --output ./keys/upload-keystore.jks

# Deep links: open one, then check why an App Link did or didn't verify
./deeplink-test.sh --url "https://example.com/item/42" --package com.example.app
./deeplink-test.sh --package com.example.app --list-links

# Verify a release bundle the way Play will consume it
./play-bundle-verify.sh --aab app-release.aab --bundletool bundletool.jar
./play-bundle-verify.sh --aab app-release.aab   # no jar? prints the exact commands
```

PowerShell is the same with `-PascalCase` options, e.g.
`.\adb-install-launch.ps1 -Package com.example.app`.

## Safety notes

- **Nothing here is destructive without a confirmation.** The only
  data-destroying operation, `adb-app-ops --reset` (`pm clear`), asks you
  to type the full package ID before it runs.
- **No secrets in any script.** `keystore-create` reads passwords at
  hidden prompts, passes them to `keytool` through environment
  variables, never echoes them, and writes a `keystore.properties`
  template containing **placeholders only**. `play-bundle-verify` never
  asks for a keystore password at all.
- **Keystores are forever.** Back up a release keystore in at least two
  safe places *outside* any repo, and never commit it (or a filled-in
  `keystore.properties`): add `*.jks`, `*.keystore`, and
  `keystore.properties` to `.gitignore`. Losing an upload keystore is
  recoverable only if the app uses Play App Signing.
- **Captures and logs can contain personal data.** Screenshots, screen
  recordings, and logcat output from a real device may include
  notifications, names, or tokens — review before sharing, and don't
  commit captures to a repo.
- **Check the target device first.** Most scripts accept `--serial` /
  `-Serial`; without it they act on whatever `adb devices` picks as the
  default — make sure that is the device you mean.

## Requirements

- `adb` on PATH for all `adb-*` and `deeplink-test` scripts (Android SDK
  platform-tools).
- A JDK (`keytool`, `java`) for `keystore-create` and
  `play-bundle-verify`; the bundletool jar for the latter (the script
  prints where to get it and the exact manual commands without one).
- The Android SDK emulator + at least one AVD for `emulator-boot`.
- A Gradle wrapper in the project for `adb-install-launch`'s build step
  (skippable with `--apk` / `--skip-build`).

## Verification status

The Bash scripts are syntax-checked (`bash -n`) and follow
`set -euo pipefail`. The PowerShell scripts mirror the same logic
option-for-option; their execution on a real Windows machine is
**Unverified** from the environment this repo was built in — run one
with `-Help` first and report any mismatch with its `.sh` twin.
