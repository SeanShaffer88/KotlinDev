# Performance Profiling and Optimization
## TL;DR
Measure first, then fix. Profile startup, scrolling, and memory on a real device in a release-like build, generate a Baseline Profile, enable R8 shrinking, ship an Android App Bundle, and watch frame timing and leaks in every release. Guessing is slower than measuring.
Official guides: Performance https://developer.android.com/topic/performance · Startup https://developer.android.com/topic/performance/app-startup · Profilers https://developer.android.com/studio/profile
## 1. Principles
- Profile the **release** build (with R8 on) on a mid-range real device, not only a fast emulator in debug mode. Debug builds are slower and hide real costs.
- Change one thing at a time and re-measure the same journey.
- Set budgets for cold start time, frame deadline misses, download size, and memory after a key journey. Fail CI or block a release when a budget is badly missed.
- Keep the main thread free: no disk, network, or heavy parsing on it.
## 2. App startup
Startup types are cold (process created), warm (activity created), and hot (activity resumed). Cold start is the hardest and the one users notice most.
Reduce cold start work:
- Keep `Application.onCreate()` and first-screen init minimal. Defer analytics, logging setup, and feature init until after the first frame, or move them to a background thread.
- Avoid loading every dependency at launch. Use lazy initialization and only start what the first screen needs.
- Load data off the main thread with coroutines, and show the first frame as soon as the shell is ready.
- Avoid many small disk reads at launch; batch preferences/DataStore reads and cache the result in memory.
- Trace startup with Macrobenchmark and Android Studio System Trace to see what runs before the first frame.
```kotlin
class App : Application() {
    override fun onCreate() {
        super.onCreate()
        initCrashReporting() // only the minimum needed for the first frame
        AppInitializer.initAsync(this) // heavy work is lazy / after first frame
    }
}
```
Measure it:
```kotlin
@LargeTest @RunWith(AndroidJUnit4::class)
class StartupBenchmark {
    @get:Rule val rule = MacrobenchmarkRule()
    @Test fun coldStart() = rule.measureRepeated(
        packageName = "com.example.app",
        metrics = listOf(StartupTimingMetric()),
        iterations = 5, startupMode = StartupMode.COLD
    ) { pressHome(); startActivityAndWait() }
}
```
Analysis guide: https://developer.android.com/topic/performance/app-startup/analysis
## 3. Baseline Profiles: about 30% faster startup
A Baseline Profile is a list of classes and methods the system compiles ahead of time (AOT) and ships inside the APK/AAB. Google reports apps commonly see **around 30% faster startup** from the first launch with a Baseline Profile, and profile-guided compilation also helps scrolling and navigation. The exact gain depends on the app — measure yours with and without the profile.
Generate the profile with the Macrobenchmark / Baseline Profile Gradle plugin, covering cold start and the most common journeys, then commit the generated `baseline-prof.txt` under `src/main/baselineProfiles/` (or the release source set). Generation task: `./gradlew :app:generateReleaseBaselineProfile`
Rules: regenerate the profile when startup code or main journeys change; verify in a benchmark that the profile is actually applied; ship profiles in the App Bundle so Play can also deliver cloud profiles for other journeys as usage data arrives.
Guides: https://developer.android.com/topic/performance/baselineprofiles/overview · https://developer.android.com/topic/performance/baselineprofiles/create-baselineprofile
## 4. R8, shrinking, and obfuscation
R8 is the default compiler that shrinks, optimizes, and obfuscates release builds. Enable it for every release:
```kotlin
// build.gradle.kts, release build type
isMinifyEnabled = true
isShrinkResources = true
proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
```
- `isMinifyEnabled` removes unused code and renames symbols. `isShrinkResources` removes unused resources and needs minify on.
- Add keep rules only where reflection, serialization, JNI, or a library truly needs them. Prefer library consumer rules and `@Keep` on the smallest possible scope.
- Test the release build, not only debug: most R8 failures (missing class, stripped model) appear only after shrinking.
- Save `mapping.txt` for every release so crash stack traces can be de-obfuscated in Play Console / Firebase Crashlytics.
Guides: https://developer.android.com/build/shrink-code · https://developer.android.com/build/shrink-code#keep-code
## 5. App size and the Android App Bundle (AAB)
Publish an **Android App Bundle (.aab)** to Google Play, not a universal APK. Play generates split APKs per device — language, density, and CPU architecture — so each user downloads only what their device needs.
Reduce size further: use vector drawables where possible and WebP/AVIF for photos; remove unused resources and densities; check native library size and upload debug symbols separately for crash reports; avoid duplicate libraries; inspect the dependency tree and APK Analyzer output after each release; use Play's size report and `bundletool` to test the exact APKs Play will deliver.
```bash
bundletool build-apks --bundle=app-release.aab --output=out.apks
bundletool get-size total --apks=out.apks
```
Links: https://developer.android.com/guide/app-bundle · https://developer.android.com/studio/build/apk-analyzer · https://developer.android.com/topic/performance/reduce-apk-size
## 6. Android Studio profilers
Use the built-in profilers before reaching for external tools:
- **CPU Profiler / System Trace**: record startup or a scroll and read the flame chart. Look for long main-thread blocks, repeated layout, and work that could move off the main thread.
- **Memory Profiler**: watch the heap during a journey, force GC, capture a heap dump, and look for retained Activities or large bitmaps that never drop.
- **Energy Profiler**: check wake locks, alarms, and background work.
- **App Inspection**: inspect databases, DataStore, network calls, and background jobs in a running debug build.
- **Layout Inspector**: check recomposition counts and view hierarchy depth, and why a screen is nested too deeply.
Record traces on the same device and journey each time so results are comparable, and save a trace with every performance fix. Guide: https://developer.android.com/studio/profile/android-profiler
## 7. Macrobenchmark
Macrobenchmark runs on a real device, controls the app from outside its process, and measures startup, frame timing, and custom traces with low noise. Use it for regression testing, not one-off checks.
```kotlin
@Test fun scrollList() = rule.measureRepeated(
    packageName = "com.example.app",
    metrics = listOf(FrameTimingMetric()),
    iterations = 5, startupMode = StartupMode.WARM
) {
    startActivityAndWait()
    val list = device.findObject(By.res("itemList"))
    list.setGestureMargins(0, 200, 0, 200)
    repeat(5) { list.fling(Direction.DOWN, 2_000); device.waitForIdle() }
}
```
Run benchmarks on a physical device, in CI on a device lab if available, with battery and thermal state noted. Compare medians, not single runs. Guide: https://developer.android.com/topic/performance/benchmarking/macrobenchmark-overview
## 8. Jank and frame timing
Jank is a frame that misses its deadline — about 16 ms at 60 Hz, about 8 ms at 120 Hz. The user sees it as stutter while scrolling or animating.
Common causes and fixes:
- Main-thread disk/network, large JSON parsing, or image decoding: move it to a background dispatcher and decode images at display size.
- Overdraw and deep hierarchies: flatten layouts. In Compose, keep composables stable, pass immutable data, use `key` in lists, and defer state reads to the smallest scope that needs them.
- Unstable Compose parameters causing extra recomposition: check Layout Inspector recomposition counts and stability reports.
- Large lists without recycling/paging: use `LazyColumn` / `RecyclerView` with stable IDs, paging, and image placeholders at a fixed size.
Measure with `FrameTimingMetric`, Android Studio tooling, JankStats, and the GPU rendering profile overlay on device during manual testing.
Links: https://developer.android.com/topic/performance/vitals/render · https://developer.android.com/topic/performance/jankstats · https://developer.android.com/jetpack/compose/performance
## 9. Memory leaks and LeakCanary
A leak is memory that stays retained after it should be freed — most often an Activity, Fragment, or View held by a static field, a long-lived coroutine, a listener, or a singleton Context.
Add LeakCanary to debug builds only. It watches destroyed Activities/Fragments and reports a leak trace with the reference chain:
```kotlin
dependencies { debugImplementation("com.squareup.leakcanary:leakcanary-android:2.14") }
```
No code change is needed for the default setup. Fix leaks by holding `applicationContext` (not an Activity Context) in singletons, cancelling coroutines in `viewModelScope` / `lifecycleScope` instead of a global scope, clearing bindings in `onDestroyView`, unregistering listeners, closing cursors/streams, and setting explicit limits on bitmap and image caches.
Links: https://square.github.io/leakcanary/ · https://developer.android.com/topic/performance/memory-overview
## 10. 16 KB page size
Android 15+ supports devices with **16 KB memory pages**, and Google Play requires apps targeting Android 15+ to support 16 KB pages on 64-bit devices. Apps with native code (.so libraries) built with old alignment can fail to install or crash on those devices.
What to do: rebuild native libraries with 16 KB alignment and update prebuilt .so dependencies that are not aligned; use a recent Android Gradle Plugin and NDK; check alignment with the tools in the official guide; test on a 16 KB emulator image. Pure Kotlin/Java apps with no native code are generally ready, but verify any library you ship that bundles native code.
Guide: https://developer.android.com/guide/practices/page-sizes
## 11. Putting it together: a repeatable routine
Before each release, run the same routine on the same device so results can be compared over time:
1. Build the release variant with R8 on and install it fresh, clearing app data first.
2. Record a cold start trace and the main scroll journey with Macrobenchmark.
3. Walk the main screens with LeakCanary enabled in the debug build and check for new leaks.
4. Check the AAB download size and the APK Analyzer diff against the last release.
5. Save the traces, benchmark output, and size report with the release notes for the next comparison.
Watch trends, not only single numbers: a small slow increase in startup or size on every release adds up to a large regression that no single release review will catch.
Use Android vitals in Play Console after release to confirm lab results match real users, and investigate any bad behavior cluster (slow start, slow rendering, excessive wakeups) that rises above the Play thresholds.
Vitals guide: https://developer.android.com/topic/performance/vitals
## Release checklist
- [ ] Cold start measured on a real mid-range device, release build.
- [ ] Baseline Profile generated, committed, and verified applied.
- [ ] R8 minify + resource shrinking on; release build fully tested.
- [ ] AAB uploaded; download size checked with bundletool / Play.
- [ ] Main scroll journey has no sustained jank in Macrobenchmark.
- [ ] LeakCanary clean on debug after navigating all main screens.
- [ ] Native libraries checked for 16 KB page alignment.
