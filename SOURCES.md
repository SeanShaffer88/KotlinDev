# SOURCES.md — Curated source list, verified

Every resource this repo leans on, organized by kind, with its URL and
why it matters. Snapshot checked November 2026. Statuses: **Verified**
(exists as described at check time) · **Unverified** (could not be
pinned to an exact current value in this pass — re-check before use).

Rule of use: official docs and artifact repositories are ground truth
for APIs, versions, and policy. Everything else is learning material.

## Official Android / Kotlin / JetBrains

| Resource | URL | Why it matters |
|---|---|---|
| Android Developers (docs home) | https://developer.android.com/ | The ground truth: API references, guides, behavior changes, training. Start here for any API question. **Verified** Nov 2026. |
| Android API reference | https://developer.android.com/reference | Per-class reference with "added in API level" data — the check for version-gating mistakes. |
| Kotlin language docs | https://kotlinlang.org/docs/home.html | Language ground truth: coroutines, Flow, multiplatform, releases. **Verified** Nov 2026. |
| Kotlin releases | https://kotlinlang.org/docs/releases.html | Which Kotlin is current (snapshot: 2.4.21) and what changed per release. |
| JetBrains / Android Studio downloads | https://developer.android.com/studio | Current Android Studio (snapshot: Rabbit 2, 2026.2.2) and release notes. |
| Gradle releases & compatibility | https://gradle.org/releases/ + https://docs.gradle.org/current/userguide/compatibility.html | AGP ↔ Gradle ↔ JDK compatibility (snapshot: AGP 9.5 / Gradle 9.6 / JDK 17). |
| Google Maven | https://maven.google.com/ | The repository of record for AndroidX, AGP, Compose, Media3, Billing — exact versions live here. |
| Maven Central | https://central.sonatype.com/ | The repository of record for Kotlin, OkHttp, Retrofit, Ktor, Coil, and most third-party libraries. |
| AndroidX documentation | https://developer.android.com/jetpack/androidx | Library index, per-library guides, and the versions page. |
| Compose documentation | https://developer.android.com/develop/ui/compose | The Compose guide set: state, layout, theming, performance, testing. |
| Play Games Services docs | https://developer.android.com/games/playgames | PGS v2 setup, sign-in, achievements, leaderboards, saved games. |
| Android Game Development Kit (AGDK) | https://developer.android.com/games/agdk | GameActivity, frame pacing, performance tooling for native/C++ games. |
| Google Play Billing docs | https://developer.android.com/google/play/billing | Billing Library integration (8+), products, subscriptions, testing. |

## AndroidX release notes

| Resource | URL | Why it matters |
|---|---|---|
| AndroidX release notes (all libraries) | https://developer.android.com/jetpack/androidx/versions | The single feed for what shipped in every AndroidX library. |
| Compose release notes / BOM mapping | https://developer.android.com/jetpack/androidx/releases/compose + BOM page | Which library versions a Compose BOM (snapshot: 2026.09.00) maps to, and any compileSdk requirements. |
| Room release notes | https://developer.android.com/jetpack/androidx/releases/room | Room 2.x vs 3.x changes and migration notes — read before mixing majors. |
| Navigation release notes | https://developer.android.com/jetpack/androidx/releases/navigation | Navigation 2.x and the Navigation 3 line: what is stable vs alpha. |
| Media3 release notes | https://developer.android.com/jetpack/androidx/releases/media3 | Media3 versions (snapshot: 1.11.1) and ExoPlayer migration notes. |
| WorkManager / Paging / CameraX notes | Via the AndroidX versions feed above | Snapshot: Paging 3.5.3, CameraX 1.6.2 — confirm on the feed before pinning. |

## Play Console / policy

| Resource | URL | Why it matters |
|---|---|---|
| Play Console Help | https://support.google.com/googleplay/android-developer | Policy center: the binding text for target API, billing, permissions, data safety. |
| Target API requirements | https://developer.android.com/google/play/requirements/target-sdk | The deadline table: API 36 required for new apps/updates since Aug 31, 2026. **Verified** Nov 2026. |
| Play Billing requirements | Via Play Console Help → Payments / Billing | Billing Library 8+ requirement and deprecation schedule. |
| Data safety section help | https://support.google.com/googleplay/android-developer/answer/10787469 | How to declare data collection/sharing accurately. |
| 16 KB page size requirement | https://developer.android.com/guide/practices/page-sizes | Native-code alignment rule; Play enforcement steps up Feb 1, 2027 (see `reference/play-requirements-and-deadlines.md`). |
| Developer Program Policies | https://play.google.com/about/developer-content-policy/ | The full policy set submissions are reviewed against. |

## Official samples

| Resource | URL | Why it matters |
|---|---|---|
| Now in Android | https://github.com/android/nowinandroid | Google's reference app: modularization, Compose, offline-first, testing — the architecture docs in this repo trace back to it. **Verified** Nov 2026. |
| Jetpack Compose samples | https://github.com/android/compose-samples | JetNews, Jetchat, Jetsnack and friends — idiomatic Compose patterns per feature. |
| Android architecture samples | https://github.com/android/architecture-samples | Smaller focused samples for data layer / TODO-MVVM patterns. |
| Android games samples | https://github.com/android/games-samples | AGDK/GameActivity and Play Games samples for the native route. |
| Kotlin coroutines / multiplatform samples | https://github.com/Kotlin (org samples) | JetBrains' own KMP and coroutines examples. |

## Awesome lists & directories

| Resource | URL | Why it matters |
|---|---|---|
| awesome-android | https://github.com/JStumpp/awesome-android | Long-running curated index of Android libraries and tools. Check dates — entries age. |
| awesome-kotlin | https://github.com/KotlinBy/awesome-kotlin | Kotlin libraries/projects across JVM, Android, and multiplatform. |
| awesome-compose / Android Dev resources lists | GitHub search: `awesome jetpack compose` | Useful discovery layer only — verify every entry on Maven Central before adopting. |

## Books & courses

| Resource | Why it matters |
|---|---|
| *Kotlin in Action* (2nd ed., Manning) | The standard Kotlin language book, updated for modern Kotlin. |
| *Head First Android Development* (O'Reilly) | Beginner-friendly full-path Android book; check its edition targets Kotlin/Compose before relying on version details. |
| Android Basics with Compose (developer.android.com/courses) | Google's free beginner course — the canonical first path for Compose. |
| Advanced Android / MAD Skills series (developer.android.com + YouTube) | Google's topic deep-dives: architecture, performance, Media3, large screens. |
| Kotlin Coroutines by Tutorials / coroutines codelabs | Structured coroutines/Flow learning; pair with the official coroutines guide. |

## Communities

| Resource | Why it matters |
|---|---|
| Kotlin Slack (kotlinlang.slack.com) | JetBrains-run; `#android` and `#compose` channels for library-level questions. |
| AndroidDev / Kotlin Discord servers | Fast informal help; treat answers as leads, verify in docs. |
| Stack Overflow (`android`, `kotlin`, `jetpack-compose` tags) | Searchable problem archive — check answer dates against current APIs. |
| Reddit r/androiddev, r/Kotlin | Release discussion and experience reports. |
| Android Developers on YouTube / Medium | Launch announcements and engineering posts from the platform team. |

## Games sources

| Resource | URL | Why it matters |
|---|---|---|
| AGDK home + downloads | https://developer.android.com/games/agdk | Native game stack: GameActivity, Frame Pacing, AGDK libraries, Android Game Development Extension for Visual Studio. |
| Android games hub | https://developer.android.com/games | Play Games, Google Play Games on PC, performance and reach guidance. |
| libGDX | https://libgdx.com/ + https://github.com/libgdx/libgdx | The main open-source JVM game framework for Android; wiki covers setup, deployment, backends. **Verified** Nov 2026. |
| KTX (libGDX Kotlin extensions) | https://github.com/libktx/ktx | Idiomatic Kotlin APIs over libGDX — the default way to write libGDX in Kotlin. |
| KorGE | https://korge.org/ + https://github.com/korlibs/korge | Kotlin-native 2D game engine, multiplatform. **Current version: Unverified** in this pass — check the repo releases / Maven Central (`com.soywiz.korge`) before pinning. |
| Godot engine | https://godotengine.org/ + https://docs.godotengine.org/ | Full engine with Android export; the route for teams already on Godot. |
| godot-kotlin/jvm | https://github.com/utopia-rise/godot-kotlin-jvm | Kotlin/JVM language support for Godot — lets a Godot game be written in Kotlin. Check its supported Godot version before starting. |
| Play Games Services | https://developer.android.com/games/playgames | v2 SDK: sign-in, achievements, leaderboards, saved games, Play Games on PC requirements. |
| OpenGL ES / Vulkan on Android | https://developer.android.com/games/graphics | Official graphics guides for the native route. |

## Explicitly Unverified in this pass

| Item | Status |
|---|---|
| KorGE current version | **Unverified** — check https://github.com/korlibs/korge/releases and Maven Central before pinning a version. |
| Firebase BoM exact version | **Unverified** — Firebase ships via a Bill of Materials whose version moves often; read the current BoM version at https://firebase.google.com/docs/android/setup and pin that. |
| Dagger / Hilt exact latest version | **Unverified** — Hilt moves with Dagger releases; read the current version at https://dagger.dev/hilt/ and Google Maven (`com.google.dagger:hilt-android`) before pinning. |
