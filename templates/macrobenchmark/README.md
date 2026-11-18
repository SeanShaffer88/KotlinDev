# Macrobenchmark Template + Baseline Profile Flow

Macrobenchmark measures your real app on a real device/emulator:
cold-start time and frame timing (jank) for scrolling. Its results
are also how you prove a Baseline Profile is doing its job.

## Module setup

1. Copy this folder into your project as a `macrobenchmark/` module
   and add `include(":macrobenchmark")` to `settings.gradle.kts`.
2. Add the catalog entries noted at the bottom of
   `build.gradle.kts` (`benchmark-macro-junit4` — **1.5.0** in this
   snapshot; re-check the current AndroidX Benchmark release —
   plus `uiautomator`, `androidx.test` runner/ext).
3. In `Macrobenchmark.kt`, set `PACKAGE_NAME` to your applicationId
   and make sure something scrollable exists on the first screen
   (the scroll test finds `By.scrollable(true)`).
4. Create a **benchmark build type** in the *app* module: a release
   build that is `isMinifyEnabled = true`, **not** debuggable, and
   `profileable { enabled = true }` (AGP's `android.experimental`
   profileable shell or the manifest `<profileable>` entry,
   depending on your AGP — verify against your version's docs).
5. Run on a physical device (API 24+, ideally your lowest-end target)
   or a Pixel-class emulator image:

```bash
./gradlew :macrobenchmark:connectedBenchmarkAndroidTest
# Results: macrobenchmark/build/outputs/androidTest-results/ and the
# benchmark report JSON under outputs/connected_android_test_additional_output/
```

Compare `startupNoCompilation` vs `startupBaselineProfile`: if the
profile is installed and current, the profile run should start
measurably faster. If it doesn't, the profile is stale or missing —
regenerate it (below).

## Baseline Profile generation flow

A Baseline Profile tells ART which methods to ahead-of-time compile,
cutting startup and first-scroll jank (Google cites roughly 30%
faster code execution for covered paths — measure your own app).

1. Add a `:baselineprofile` generator module using
   `androidx.benchmark:benchmark-baseline-profile-gradle-plugin`
   (same Benchmark release as macrobenchmark) with a
   `BaselineProfileRule` test that starts the app and walks the
   critical user journeys: first screen, main list scroll, the one
   or two flows every user hits. Cover journeys, not the whole app.
2. Generate on a rooted emulator or a `userdebug`/profileable setup
   the plugin supports:

   ```bash
   ./gradlew :app:generateReleaseBaselineProfile
   ```

   Output lands in `app/src/release/generated/baselineProfiles/`
   (`baseline-prof.txt` + `startup-prof.txt`). Commit those files.
3. Ship it: with AGP's baseline-profile support the profile is
   packaged into the AAB automatically; `profileinstaller`
   (`androidx.profileinstaller:profileinstaller`) is the runtime
   piece older setups add explicitly — check whether your setup
   needs it.
4. **Regenerate after big UI/Compose changes** and re-run the
   macrobenchmarks to confirm the gain survived. A stale profile
   quietly stops helping.
5. Hand-written additions (rare) go in the format shown in
   `../baseline-profiles/` — prefer generated profiles; edit by hand
   only for a measured, specific gap.
