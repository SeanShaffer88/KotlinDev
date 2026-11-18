# Kotlin Multiplatform and Compose Multiplatform
Kotlin Multiplatform (KMP) lets you share Kotlin code between Android, iOS, desktop, and the web while still writing native apps on each platform. Compose Multiplatform extends Jetpack Compose so you can also share UI. This guide explains what is stable, what is still beta, the `expect`/`actual` mechanism, what is worth sharing, and the libraries that fit the model. The guiding idea: share the logic that is the same everywhere, keep the parts that should feel native on each platform native.
## Timeline and stability
Key milestones, so you can judge maturity for yourself:
- **Kotlin Multiplatform went stable in Kotlin 1.9.20** (November 2023). The core technology — Gradle model, shared source sets, and `expect`/`actual` — has been stable since then and is suitable for production use.
- **In May 2024, Google announced official support for Kotlin Multiplatform** for sharing business logic between Android and iOS, with tooling support in Android Studio and KMP support in selected Jetpack libraries (Room, DataStore, Collection, and others). Google's recommendation is to share business logic incrementally, not to rewrite the whole app.
- **Compose Multiplatform for iOS went stable in version 1.8.0** (May 2025). Android, iOS, and desktop are the stable Compose Multiplatform targets.
- **Compose Multiplatform for Web (Wasm)** is still in **beta** at the time of writing. It is usable for experiments and new projects that accept beta risk, but check the current status before committing a production web UI to it.
Status pages: https://kotlinlang.org/docs/multiplatform.html and https://www.jetbrains.com/compose-multiplatform/ and https://developer.android.com/kotlin/multiplatform
## How a KMP project is structured
Code lives in source sets:
```
src/
  commonMain/    — shared Kotlin, no platform APIs
  androidMain/   — Android actual implementations
  iosMain/       — iOS actual implementations
  desktopMain/   — JVM desktop (a "jvm" target)
  wasmJsMain/    — Web, when used
```
Gradle declares the targets, and the shared module is consumed by each native app — on Android as a library module, on iOS as a framework linked into the Xcode project.
```kotlin
// shared/build.gradle.kts
plugins {
    alias(libs.plugins.kotlinMultiplatform)
    alias(libs.plugins.androidLibrary)
}
kotlin {
    androidTarget()
    iosArm64()
    iosSimulatorArm64()
    jvm("desktop")
    sourceSets {
        commonMain.dependencies {
            implementation(libs.ktor.client.core)
            implementation(libs.sqldelight.runtime)
        }
        androidMain.dependencies { implementation(libs.ktor.client.okhttp) }
        iosMain.dependencies { implementation(libs.ktor.client.darwin) }
    }
}
```
Start a new project with the official wizard, which generates a working structure with current plugin versions: https://kmp.jetbrains.com/
## expect / actual
`commonMain` cannot call platform APIs directly — there is no Android `Context` on iOS and no `UIDevice` on Android. The bridge is:
- `expect` in common code declares what must exist.
- `actual` in each platform source set provides it.
```kotlin
// commonMain
expect fun platformName(): String
expect class UuidGenerator() { fun newId(): String }
```
```kotlin
// androidMain
actual fun platformName(): String = "Android ${Build.VERSION.SDK_INT}"
actual class UuidGenerator {
    actual fun newId(): String = java.util.UUID.randomUUID().toString()
}
```
```kotlin
// iosMain
actual fun platformName(): String =
    UIDevice.currentDevice.systemName() + " " + UIDevice.currentDevice.systemVersion
actual class UuidGenerator {
    actual fun newId(): String = NSUUID().UUIDString()
}
```
Keep `expect` declarations small and few. A large surface of platform hooks means the code was not really common. Prefer common interfaces with platform implementations injected (see dependency injection below) for anything complex.
Docs: https://kotlinlang.org/docs/multiplatform-expect-actual.html
## What to share, and what not to share
**Good to share — business logic:**
- Data models, validation, and business rules
- Networking (API clients, request/response mapping)
- Local database and caching logic
- Repository layer and use cases / interactors
- Session, sync, and offline-queue logic
- Pure calculations: pricing, scoring, and formatting rules you define yourself (not platform date/number formatting)
**Usually keep native:**
- UI, unless you deliberately choose Compose Multiplatform (see next section) — SwiftUI on iOS and Compose on Android give the most native feel and best platform integration.
- Navigation, notifications, widgets, and OS integrations
- Camera, Bluetooth, background execution, and permissions — the platform models differ too much to hide behind one API.
- Anything that wraps a platform SDK one-to-one; the wrapper costs as much as using the SDK directly.
Google's guidance matches this: adopt KMP **incrementally**, starting with a low-risk shared module such as networking or a single feature's logic, and expand only where it pays off.
See: https://developer.android.com/kotlin/multiplatform
## Compose Multiplatform
Compose Multiplatform reuses the Jetpack Compose programming model — composables, state, modifiers — across platforms:
- **Android** — it *is* Jetpack Compose; fully stable.
- **Desktop (Windows, macOS, Linux)** — stable, JVM-based. Good for tools and companion apps sharing an Android UI.
- **iOS** — stable since 1.8.0 (May 2025). Rendering feels native, with accessibility and platform interop, but test text input, gestures, and performance on real devices for a production app.
- **Web (Wasm)** — beta. Uses WebAssembly and Canvas rendering; browser support and tooling are still evolving.
```kotlin
// commonMain — the same composable runs on Android, iOS, desktop
@Composable
fun App() {
    MaterialTheme {
        var count by remember { mutableStateOf(0) }
        Column {
            Text("Count: $count on ${platformName()}")
            Button(onClick = { count++ }) { Text("Increment") }
        }
    }
}
```
Interop goes both ways: you can embed a Compose Multiplatform screen inside a SwiftUI app, and embed native views (maps, video players, platform pickers) inside Compose with `UIKitView` on iOS and `AndroidView` on Android.
A sensible strategy many teams use: share UI for internal tools, settings, and simple content screens; keep flagship screens native where platform polish matters most.
Docs: https://kotlinlang.org/docs/compose-multiplatform.html and https://developer.android.com/develop/ui/compose/multiplatform
## Libraries that fit KMP
Prefer libraries designed for multiplatform (common code with per-platform engines/adapters):
- **Ktor** — networking. One common client API, with a platform engine underneath: OkHttp on Android/JVM, Darwin on iOS. Also offers a KMP server, if you need one.
- **SQLDelight** — type-safe SQL. You write `.sq` files, it generates Kotlin APIs; drivers exist for Android (SQLite), iOS (native SQLite), JVM, and web. It fits KMP well. (Room also has KMP support in recent versions for teams already invested in it.)
- **Koin** — dependency injection written in Kotlin and built for KMP. Declare modules in common code, provide platform objects at startup on each target.
- **kotlinx.serialization** — JSON and other formats, common-first.
- **kotlinx.coroutines** — structured concurrency everywhere; remember the iOS main thread model for UI work.
- **kotlinx.datetime** — date and time for common code; do not use `java.time` in `commonMain`, it does not exist on iOS.
```kotlin
// Ktor in commonMain — engine supplied by the platform source set
val client = HttpClient { install(ContentNegotiation) { json() } }
suspend fun loadItems(): List<Item> =
    client.get("https://example.com/api/items").body()
```
```kotlin
// Koin: common module + a platform module at startup
val commonModule = module {
    single { ApiClient(get()) }
    single { ItemsRepository(get(), get()) }
}
```
Library directory: https://kotlinlang.org/docs/multiplatform-library.html
## Testing and build notes
- Put tests for shared logic in `commonTest` and run them on every target — a test that only passes on JVM may still fail on iOS (threading, number formatting, file paths differ).
- iOS builds require a Mac with Xcode. CI for iOS targets must run on macOS runners; Android and desktop can build anywhere.
- Binary size and startup on iOS are worth measuring early if you share a lot of code.
- Version the Kotlin, Compose Multiplatform, and library stack together in the version catalog — KMP libraries are sensitive to Kotlin version mismatches.
## Decision checklist
1. Is the shared code really the same logic on every platform? If not, KMP adds cost without the payoff.
2. Start with one module (networking or a feature's logic).
3. Keep `expect`/`actual` small; inject the rest with Koin.
4. Choose UI sharing deliberately: native UI + shared logic is the lowest-risk start; Compose Multiplatform is stable for Android, iOS, and desktop if you want shared UI too.
5. Treat Web/Wasm as beta and isolate it from the core app.
6. Test common code on all targets, including a real iOS device.
## Summary
KMP has been stable since Kotlin 1.9.20, Google supports it for shared business logic between Android and iOS, and Compose Multiplatform reached iOS stability in 1.8.0, with desktop and Android stable and Web/Wasm in beta. Share models, networking, storage, and rules with Ktor, SQLDelight, and Koin; keep OS integration native; and grow the shared surface only where the logic is genuinely identical.
