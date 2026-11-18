# Project Setup, Gradle, and Tooling

A well-structured Gradle setup saves hours on every later change.
This guide covers Android Studio, the SDK, Gradle with Kotlin DSL,
version catalogs, AGP and Kotlin versions, the Compose BOM, and
module layout.

Official references:
- Create a project: https://developer.android.com/studio/projects/create-project
- Configure your build: https://developer.android.com/build
- Version catalogs: https://developer.android.com/build/migrate-to-catalogs
- AGP release notes: https://developer.android.com/build/releases/gradle-plugin
- Compose BOM: https://developer.android.com/develop/ui/compose/bom

## Android Studio and the SDK

Install Android Studio (Rabbit 2, 2026.2.2 verified) and use its SDK
Manager to install:

- The latest stable SDK Platform (API 36, and 37 when available).
- Build Tools 36.
- Android Emulator and at least one system image for testing.
- Command-line Tools — needed for CI and scripted builds.

Keep the SDK in one known location and set `ANDROID_HOME` (or
`sdk.dir` in `local.properties`) so command-line builds work. Never
commit `local.properties` — it is machine-specific and generated.
Create projects from the Studio templates (Empty Activity for
Compose is the usual start). Templates wire correct AGP, Kotlin, and
Compose versions together, which is safer than assembling by hand.

## Gradle with Kotlin DSL

Modern projects use Gradle build scripts in Kotlin DSL
(`build.gradle.kts`): autocomplete, type checking, same language as
the app. Verified baseline: AGP 9.5 requires Gradle 9.6 and JDK 17.
Since AGP 9.0, Kotlin support is built into AGP.

Root `settings.gradle.kts`:

```kotlin
pluginManagement {
    repositories { google(); mavenCentral(); gradlePluginPortal() }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories { google(); mavenCentral() }
}
rootProject.name = "MyApp"
include(":app")
```

App module `build.gradle.kts`:

```kotlin
plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.compose)
}
android {
    namespace = "com.example.myapp"
    compileSdk = 36
    defaultConfig {
        applicationId = "com.example.myapp"
        minSdk = 26
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"
    }
    buildTypes {
        release {
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro")
        }
    }
    buildFeatures { compose = true }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}
dependencies {
    implementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.activity.compose)
    implementation(libs.androidx.compose.material3)
    implementation(libs.androidx.lifecycle.viewmodel.compose)
}
```

Key rules: one repository list in `settings.gradle.kts` only, never
hardcode versions in module files, and keep `namespace` in Gradle —
the manifest `package` attribute is gone.

## Version Catalogs

The version catalog (`gradle/libs.versions.toml`) is the single
source of truth for every version and dependency coordinate.

```toml
[versions]
agp = "9.5"
kotlin = "2.4.21"
coreKtx = "1.17.0"
composeBom = "2026.09.00"
lifecycle = "2.9.4"

[libraries]
androidx-core-ktx = { group = "androidx.core", name = "core-ktx", version.ref = "coreKtx" }
androidx-compose-bom = { group = "androidx.compose", name = "compose-bom", version.ref = "composeBom" }
androidx-activity-compose = { group = "androidx.activity", name = "activity-compose", version = "1.11.0" }
androidx-lifecycle-viewmodel-compose = { group = "androidx.lifecycle", name = "lifecycle-viewmodel-compose", version.ref = "lifecycle" }
androidx-compose-material3 = { group = "androidx.compose.material3", name = "material3" }

[plugins]
android-application = { id = "com.android.application", version.ref = "agp" }
kotlin-compose = { id = "org.jetbrains.kotlin.plugin.compose", version.ref = "kotlin" }
```

In build files you reference `libs.androidx.core.ktx` and
`libs.plugins.android.application`. Update a version once, everywhere.

## AGP, Kotlin, and the Compose Compiler

- **AGP ↔ Gradle ↔ JDK:** AGP 9.5 needs Gradle 9.6 and JDK 17. The
  Gradle wrapper pins the Gradle version — always build through
  `./gradlew`, never a system Gradle, so every machine and CI uses
  the same version.
- **Compose compiler = Kotlin version:** since Kotlin 2.0, the
  Compose compiler ships with Kotlin and is applied with the
  `org.jetbrains.kotlin.plugin.compose` plugin. Its version is the
  Kotlin version — there is no separate compiler version to align.
  Never set `kotlinCompilerExtensionVersion` in a Kotlin 2.x project.
- **Compose libraries ↔ BOM:** the Compose BOM aligns all Compose
  versions. Use BOM 2026.09.00 (verified) as a platform dependency
  and declare Compose libraries without versions.

```kotlin
dependencies {
    implementation(platform(libs.androidx.compose.bom))
    androidTestImplementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.compose.ui)
    implementation(libs.androidx.compose.material3)
}
```

## Build Types, Flavors, and Signing

- `debug` — debuggable, no minification, fast iteration.
- `release` — minified with R8, signed with your upload key.
- Product flavors (optional) for variants such as `free` / `paid`
  or `dev` / `prod` environments.

Store signing keys outside the repo. Reference them through
environment variables or a `keystore.properties` file that is never
committed. Prefer Play App Signing, where Google holds the final
signing key and you hold the upload key.

Useful commands:

```bash
./gradlew assembleDebug        # debug APK
./gradlew bundleRelease        # release AAB for Play
./gradlew test                 # unit tests
./gradlew connectedAndroidTest # instrumented tests
./gradlew lint                 # static analysis
```

## Module Layout

Start with a single `:app` module. Split when build time, team size,
or clear boundaries justify it — not before.

```
:app            — entry point, navigation graph, DI wiring
:core:ui        — shared Compose components and theme
:core:data      — repositories, database, network
:core:model     — shared model classes (plain Kotlin module)
:feature:home   — one feature per module
:feature:settings
```

Rules: feature modules depend on core modules, never on each other;
`:app` depends on everything and wires it together; pure Kotlin
modules build fastest — put models and pure logic there when
Android APIs are not needed; keep module APIs small.

## Tooling Beyond Gradle

- **Lint** — run in CI; fix or explicitly baseline warnings.
- **KSP** — Kotlin Symbol Processing runs annotation processors
  such as Room and Hilt compilers, much faster than kapt. Prefer
  KSP libraries; kapt is legacy.
- **R8** — shrinks and obfuscates release builds. Test release
  builds before shipping.
- **Baseline Profiles** — generated profiles that measurably
  improve startup and scroll performance.
- **Android Studio tools** — Layout Inspector, App Inspection,
  Profiler, and APK Analyzer are the first stop for performance
  and size questions.

## Common Setup Mistakes

- Versions scattered across module files instead of the catalog.
- Building with a system Gradle instead of the wrapper.
- Committing `local.properties` or signing keys.
- Adding a repository block in a module file, conflicting with
  `FAIL_ON_PROJECT_REPOS`.
- Raising `targetSdk` without reading that version's behavior changes.
- Splitting into many modules on day one, then fighting coupling.
