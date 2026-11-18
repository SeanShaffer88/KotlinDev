# Templates

Copy-paste starting points. Every version below comes from
[`../tools/versions.json`](../tools/versions.json) (verified
November 2026) — re-check against the official release notes before
starting a production project.

| Template | What it is |
|---|---|
| [`compose-app/`](compose-app/) | Minimal single-module Jetpack Compose app: Kotlin 2.4.21, AGP 9.5, compileSdk 37, targetSdk 36, minSdk 24, Material 3, version catalog included. Scaffold it with [`../tools/new-project.sh`](../tools/new-project.sh) / [`new-project.ps1`](../tools/new-project.ps1). |
| [`github-workflows/android-ci.yml`](github-workflows/android-ci.yml) | GitHub Actions CI: JDK 17, Gradle cache, lint + unit tests + `assembleDebug` on push / pull request. Copy to `.github/workflows/android-ci.yml`. |
| [`github-workflows/release-aab.yml`](github-workflows/release-aab.yml) | Manual-dispatch release workflow: builds `bundleRelease` and uploads the AAB as a workflow artifact. Signing uses CI secrets — see the comments in the file; no secret is ever printed. Copy to `.github/workflows/release-aab.yml`. |

## Using `compose-app`

1. Run the scaffolder (recommended — it renames the package for you):

   ```bash
   # bash / zsh / Git Bash
   tools/new-project.sh MyApp com.example.myapp
   ```

   ```powershell
   # PowerShell
   tools\new-project.ps1 -ProjectName MyApp -PackageId com.example.myapp
   ```

2. Or copy `compose-app/` by hand and replace every `com.example.app`
   and `ComposeApp` occurrence with your own values.
3. Open the folder in Android Studio (Rabbit 2 2026.2.2 or newer),
   let Gradle sync, and run the `app` configuration.
4. Validate the result any time:

   ```bash
   python3 tools/check-project.py path/to/MyApp
   ```
