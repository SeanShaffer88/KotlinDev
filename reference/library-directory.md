# Reference — Library Directory

The libraries an Android Kotlin developer actually meets, grouped by
job. Versions are the November 2026 snapshot — **re-check Maven
Central / Google Maven before pinning**; see
[`gradle-and-versions-cheatsheet.md`](gradle-and-versions-cheatsheet.md).
Licenses: Apache-2.0 unless noted.

## Dependency injection

| Library | Purpose | Coordinates | When to use / avoid |
|---|---|---|---|
| Hilt | Standard DI for Android, built on Dagger; compile-time graph | `com.google.dagger:hilt-android` (+ KSP compiler) — exact latest **Unverified**, check Google Maven | Use for most multi-module / tested apps. Avoid for tiny single-screen apps — manual DI is less machinery. |
| Dagger | The DI engine under Hilt | `com.google.dagger:dagger` | Use directly only when Hilt's Android assumptions do not fit. |
| Koin | Runtime (service-locator style) DI, popular in KMP | `io.insert-koin:koin-android` | Use for KMP shared code or when compile-time DI is unwanted. Avoid when you need compile-time graph errors. |

## Persistence & data

| Library | Purpose | Coordinates | When to use / avoid |
|---|---|---|---|
| Room 2 | SQLite ORM, Android-only line | `androidx.room:room-runtime` / `room-ktx` (2.x) | Use in existing Room 2 projects. KAPT or KSP. |
| Room 3 | SQLite ORM, KMP-ready line | `androidx.room3:room-runtime` (3.x) | Use for new projects that need shared/KMP database code. **Different artifacts and setup from Room 2 — never mix.** |
| DataStore | Key-value / typed settings storage (Preferences + Proto) | `androidx.datastore:datastore-preferences` / `datastore` | Use instead of SharedPreferences for all new settings storage. |
| SQLDelight | Type-safe SQL, KMP-first (Square) | `app.cash.sqldelight:android-driver` (+ runtime) | Use when the database is shared with iOS/Desktop via KMP. |
| Paging 3 | Paged loading from DB/network (snapshot 3.5.3) | `androidx.paging:paging-runtime-ktx` / `paging-compose` | Use for long scrolling lists backed by Room or an API. Avoid for small in-memory lists. |
| WorkManager | Deferrable, guaranteed background work | `androidx.work:work-runtime-ktx` | The default for sync, uploads, cleanup. Not for exact-time or immediate work. |

## UI

| Library | Purpose | Coordinates | When to use / avoid |
|---|---|---|---|
| Compose BOM | Version-aligns all Compose libraries (snapshot BOM 2026.09.00) | `androidx.compose:compose-bom` (platform) | Always import the BOM; pin individual Compose versions only to override deliberately. |
| Compose UI / Material 3 | The Compose toolkit + Material 3 components | `androidx.compose.ui:ui`, `androidx.compose.material3:material3` (via BOM) | Default UI stack for new apps. |
| Navigation 2 | Fragment/Compose navigation, stable line | `androidx.navigation:navigation-compose` (2.x) | Safe default for Compose navigation today. |
| Navigation 3 | New navigation library (scene/back-stack model) | `androidx.navigation3:*` | Adopt for new projects after checking its current stability status in the release notes. |
| Coil 3 | Kotlin-first image loading (snapshot: Coil 3 line) | `io.coil-kt.coil3:coil-compose`, `io.coil-kt.coil3:coil-network-okhttp` | Default image loader for Compose. **Coil 3 coordinates differ from Coil 2** (`io.coil-kt:coil-compose`). |
| Glide | Mature image loading, strong for Views/GIFs (snapshot: 5.x line) | `com.github.bumptech.glide:glide` (+ `compose` integration) | Use in View-based apps or where its disk-cache behavior is needed. |
| CameraX | Camera lifecycle + use cases (snapshot 1.6.2) | `androidx.camera:camera-camera2`, `camera-lifecycle`, `camera-view` | The default camera stack. Avoid raw Camera2 unless CameraX cannot do the job. |
| Media3 | Playback (ExoPlayer successor), UI, session (snapshot 1.11.1) | `androidx.media3:media3-exoplayer`, `media3-ui`, `media3-session` | The only playback stack for new code. **Replaces standalone ExoPlayer 2.** |

## Networking & serialization

| Library | Purpose | Coordinates | When to use / avoid |
|---|---|---|---|
| Retrofit 3 | Type-safe REST client over OkHttp (snapshot 3.0.0) | `com.squareup.retrofit2:retrofit` | Default REST client for Android-only apps. |
| OkHttp 5 | HTTP client, interceptors, caching (snapshot 5.5.1) | `com.squareup.okhttp3:okhttp` | Comes with Retrofit; also used directly. |
| Ktor Client | Kotlin-first HTTP client, KMP-ready (3.x line) | `io.ktor:ktor-client-core` (+ engine, e.g. `ktor-client-okhttp` / `ktor-client-android`) | Use when networking code is shared in KMP. |
| kotlinx.serialization | Kotlin-first JSON (and more) serialization | `org.jetbrains.kotlinx:kotlinx-serialization-json` (+ compiler plugin) | Default serializer with Retrofit/Ktor converters. Moshi/Gson only for existing codebases. |

## Concurrency

| Library | Purpose | Coordinates | When to use / avoid |
|---|---|---|---|
| kotlinx.coroutines | Structured concurrency + Flow (snapshot 1.11.0) | `org.jetbrains.kotlinx:kotlinx-coroutines-android` | Foundation of all modern Android async code. Never `GlobalScope`. |
| Turbine | Flow testing assertions | `app.cash.turbine:turbine` | Use in unit tests for any non-trivial Flow. |

## Testing

| Library | Purpose | Coordinates | When to use / avoid |
|---|---|---|---|
| JUnit / Truth | Test runner / fluent assertions | `junit:junit`, `com.google.truth:truth` | Standard unit-test pair. |
| MockK | Kotlin mocking | `io.mockk:mockk` | Use for mocks; prefer fakes for repositories/data sources. |
| Robolectric | Android framework tests on the JVM | `org.robolectric:robolectric` | Use for fast framework-dependent tests; keep some real-device tests too. |
| Roborazzi | Screenshot testing (Robolectric-based) | `io.github.takahirom.roborazzi:roborazzi` | Use for Compose/View screenshot regression tests. |
| LeakCanary | Memory-leak detection in debug builds (Square) | `com.squareup.leakcanary:leakcanary-android` | Debug builds only; never ship it in release. |
| Compose Test / Espresso | UI & instrumented tests | `androidx.compose.ui:ui-test-junit4` (via BOM), `androidx.test.espresso:*` | Compose tests for Compose UI; Espresso for View/interop flows. |
| Macrobenchmark / Baseline Profiles | Startup & scroll performance measurement | `androidx.benchmark:benchmark-macro-junit4`, `androidx.profileinstaller:profileinstaller` | Use before release on any performance-sensitive app. |

## Games

| Library | Purpose | Coordinates / source | When to use / avoid |
|---|---|---|---|
| libGDX | Cross-platform game framework (Java/Kotlin) | `com.badlogicgames.gdx:gdx` (+ `gdx-backend-android`) | Default engine route for 2D/3D Kotlin games. |
| KTX | Idiomatic Kotlin extensions for libGDX | `io.github.libktx:*` modules | Use with libGDX in Kotlin — do not write raw libGDX Kotlin without it. |
| KorGE | Kotlin-native 2D engine, multiplatform | `com.soywiz.korge:korge` — current version **Unverified** | Use for KMP-style games; verify version on Maven Central first. |
| Godot + godot-kotlin/jvm | Full engine with Kotlin/JVM scripting | Engine download + `org.godotfoundation.godot-kotlin:*` (check repo) | Use when the team/project is already on Godot. |
| Play Games Services v2 | Sign-in, achievements, leaderboards, saves | `com.google.android.gms:play-services-games-v2` | The only PGS line for new games. **Never PGS v1.** |
| AGDK | Native game libraries (GameActivity, frame pacing) | Via NDK / prefab: `com.google.android.games:*` where published | Use for C/C++ or hybrid native games. |

## Backend

| Library | Purpose | Coordinates | When to use / avoid |
|---|---|---|---|
| Firebase BoM | Aligns Firebase libraries (Auth, Firestore, FCM, Analytics…) | `com.google.firebase:firebase-bom` — exact version **Unverified**, check firebase.google.com | Use when the backend is Firebase; pin via the BoM only. |

## Avoid list — do not start new code on these

| Thing | Why not | Use instead |
|---|---|---|
| Picasso | Maintenance-era image loader | Coil 3 (Compose) / Glide (Views) |
| Standalone ExoPlayer 2 (`com.google.android.exoplayer2`) | Superseded; security/feature fixes land in Media3 | Media3 (`androidx.media3`) |
| AsyncTask | Deprecated since API 30; leaks and lifecycle bugs | Coroutines / WorkManager |
| PGS v1 (legacy Games / GoogleSignIn APIs) | Legacy sign-in path, superseded by PGS v2 | Play Games Services v2 |
| SharedPreferences for new storage | Synchronous, no corruption safety, no Flow | DataStore |
| KAPT for new code | Slower, superseded by KSP | KSP |
| `kotlinCompilerExtensionVersion` | Kotlin 1.x Compose setup; wrong on Kotlin 2.x | Compose compiler Gradle plugin |
