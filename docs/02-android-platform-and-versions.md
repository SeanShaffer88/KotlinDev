# Android Platform and Versions

This guide records the verified platform facts for modern Android and
Kotlin development, the API level table, Google Play target requirements,
and the breaking changes that affect apps targeting recent versions.

Official references:
- Android versions: https://developer.android.com/about/versions
- Play target API policy: https://support.google.com/googleplay/android-developer/answer/11926878
- Behavior changes: https://developer.android.com/about/versions/16/behavior-changes-16
- 16 KB page sizes: https://developer.android.com/guide/practices/page-sizes
- App bundles: https://developer.android.com/guide/app-bundle

## Verified Toolchain — November 2026

These versions were verified for this knowledge base. Always re-check
official release notes before starting a new project, because tooling
moves quickly.

| Component | Verified version | Notes |
|-----------|------------------|-------|
| Kotlin | 2.4.21 stable (Oct 8, 2026) | Current stable language release |
| Android Studio | Rabbit 2 — 2026.2.2 | Current stable IDE release |
| Android Gradle Plugin (AGP) | 9.5 | See requirements below |
| Gradle | 9.6 | Required by AGP 9.5 |
| JDK | 17 | Required to run AGP 9.5 |
| Build Tools | 36 | Bundled with recent SDK |
| Max supported API | 37 | Highest API AGP 9.5 supports |
| Built-in Kotlin | Since AGP 9.0 | AGP ships with Kotlin support built in |

AGP 9.x note: since AGP 9.0, Kotlin support is built into AGP itself.
Projects no longer apply a separate Kotlin Android plugin the old way.
Follow the AGP 9 migration guide when upgrading older projects.

## API Level Table

API level is the integer Android uses to identify a platform release.
`minSdk` is the oldest device you support, `targetSdk` is the version
your app is optimized and tested for, and `compileSdk` is the version
you compile against (normally the latest).

| API | Codename | Android version |
|-----|----------|-----------------|
| 37 | CINNAMON_BUN | Android 17 |
| 36 | BAKLAVA | Android 16 |
| 35 | VANILLA_ICE_CREAM | Android 15 |
| 34 | UPSIDE_DOWN_CAKE | Android 14 |
| 33 | TIRAMISU | Android 13 |
| 32 / 31 | S | Android 12L / 12 |
| 30 | R | Android 11 |
| 29 | Q | Android 10 |
| 28 | P | Android 9 |
| 27 / 26 | O | Android 8.1 / 8.0 |
| 25 / 24 | N | Android 7.1 / 7.0 |
| 23 | M | Android 6.0 |
| 22 / 21 | Lollipop | Android 5.1 / 5.0 |

Practical guidance:

- Set `compileSdk` to the latest stable (36, or 37 when your AGP supports it).
- Set `targetSdk` to meet the current Play requirement (see below).
- Choose `minSdk` from your audience. API 24–26 covers the vast majority
  of active devices in most markets; check Play Console device stats for
  your own app before raising it.

## Google Play Target API Requirements

From August 31, 2026, Google Play enforces these target API floors:

- **New apps and app updates:** must target API 36 or higher.
- **Wear OS and Android Auto:** must target API 35 or higher.
- **Android TV and Android XR:** must target API 34 or higher.
- **Existing apps:** must target API 35 or higher to remain available
  to new users on devices running newer Android versions.

If an existing app targets below the floor, it stays available to users
who already have it but is hidden from new installs on newer devices.
Plan target bumps early — each bump brings behavior changes that need
testing, not just a number change in Gradle.

An extension can be requested in Play Console when a migration genuinely
needs more time, but an extension is not a strategy. Target the current
level during normal development.

## Android App Bundle Is Required

Since August 2021, new apps on Google Play must be published as an
Android App Bundle (AAB), not an APK. Play generates optimized APKs per
device from your bundle (split by ABI, density, and language).

- Build with `./gradlew bundleRelease` to produce the `.aab`.
- APKs are still used for local testing, other stores, and sideloading.
- Nothing changes in your code — the bundle is a publishing format.

## 16 KB Page Sizes

Android devices are moving from 4 KB to 16 KB memory page sizes for
better performance. The rules that matter:

- Apps targeting API 35 or higher must support 16 KB page sizes.
- Enforcement date: February 1, 2027.
- **Pure Kotlin and Java apps already comply.** No action is needed if
  your app ships no native code.
- Apps with native libraries (`.so` files from the NDK, game engines, or
  native dependencies) must recompile those libraries with 16 KB
  alignment, or Play will reject updates and the app may fail to install
  or crash on 16 KB devices.

Check compliance in Android Studio with the APK Analyzer, and test on a
16 KB emulator image. Game projects using native engines should confirm
their engine version is 16 KB-ready.

## Breaking Changes by Target Version

Behavior changes apply when you raise `targetSdk`, even if the device
runs an older version in some cases. Test these areas on every bump.

### Targeting API 34 (Android 14)

- **Foreground service types are mandatory.** Every foreground service
  must declare a type (for example `dataSync`, `mediaPlayback`,
  `health`, `remoteMessaging`) in the manifest and in code, and hold
  the matching permission (for example `FOREGROUND_SERVICE_DATA_SYNC`).
- Runtime permission is required before starting certain FGS types.
- Apps must declare how they use each FGS type in Play Console.

### Targeting API 35 (Android 15)

- **Partial media access.** Users can grant access to selected photos
  and videos only. Handle re-selection and limited grants gracefully;
  do not assume full library access after a grant.
- **Edge-to-edge is enforced.** Apps draw behind the system bars by
  default. Handle window insets in Compose or Views — content hidden
  behind the status or navigation bar is now your bug to fix.
- **dataSync foreground service timeout.** `dataSync` FGS instances
  have a cumulative time limit (about 6 hours in 24 hours). When the
  limit is hit the system stops the service. Use WorkManager for
  deferrable sync instead of a long-running FGS.
- 16 KB page size support is required (see above).

### Targeting API 36 (Android 16)

- **Edge-to-edge opt-out removed.** The temporary opt-out available at
  API 35 no longer works. Edge-to-edge handling is mandatory.
- **Predictive back is on by default.** The predictive back gesture
  (showing a preview of the previous screen) is enabled by default.
  Apps using custom back handling must migrate to the supported APIs
  (`OnBackPressedDispatcher`, Compose back handlers). Legacy
  `onBackPressed` overrides can break the preview and gesture flow.
- **Large-screen restrictions ignored.** On large screens (sw600dp+),
  apps can no longer lock orientation, restrict resizability, or fix
  aspect ratio — those manifest and runtime requests are ignored.
  Apps must support landscape, portrait, and freeform resizing,
  including on foldables and tablets. Games should handle dynamic
  resizing and aspect changes gracefully.

### General Rules for Every Bump

- Read the official "behavior changes for apps targeting X" page for
  the exact level before changing `targetSdk`.
- Test on an emulator or device actually running that Android version.
- Re-check permissions, background work limits, and notification
  behavior — these tighten almost every release.
- Update Play Console declarations (FGS types, permissions, data
  safety) in the same release as the target bump.

## Choosing Your SDK Levels — Checklist

```kotlin
android {
    compileSdk = 36

    defaultConfig {
        minSdk = 26        // example — decide from your audience data
        targetSdk = 36     // meets the Aug 31, 2026 Play requirement
    }
}
```

1. `compileSdk` = latest stable your AGP supports.
2. `targetSdk` = current Play requirement or one below while migrating.
3. `minSdk` = lowest version with meaningful share for your users.
4. Never set `targetSdk` higher than you have tested.
5. Never set `compileSdk` lower than `targetSdk`.

## Version Catalog Note

Keep Kotlin, AGP, and SDK versions in one place — the Gradle version
catalog (`gradle/libs.versions.toml`) — so modules never drift. See
the project setup guide in this knowledge base for the full pattern.
