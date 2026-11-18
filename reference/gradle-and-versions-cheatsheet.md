# Reference — Gradle and Versions Cheatsheet

Sample version catalog and build files at the November 2026 snapshot
(Kotlin 2.4.21, AGP 9.5, Gradle 9.6, JDK 17, Compose BOM 2026.09.00).

> **Warning: re-check Maven before building.** Versions move. Confirm
> every version below on Google Maven (https://maven.google.com) or
> Maven Central (https://central.sonatype.com) and the Compose BOM
> mapping page before pinning a real project. Items marked
> **Unverified** were not pinned to an exact value in this snapshot.

## `gradle/libs.versions.toml`

```toml
[versions]
kotlin = "2.4.21"
agp = "9.5.0"            # AGP 9.5 line — confirm exact patch on Google Maven
ksp = "2.3.0"            # KSP line matching Kotlin 2.4.x — confirm on Maven Central
composeBom = "2026.09.00"
coreKtx = "1.17.0"       # confirm on Google Maven
lifecycle = "2.9.0"      # confirm on Google Maven
activityCompose = "1.11.0" # confirm on Google Maven
room2 = "2.8.4"          # Room 2 line — OR room3 below, never both
room3 = "3.0.0"          # Room 3 line — confirm current 3.x on Google Maven
navigation = "2.9.0"     # Navigation 2 line — confirm on Google Maven
paging = "3.5.3"
cameraX = "1.6.2"
media3 = "1.11.1"
workManager = "2.11.0"   # confirm on Google Maven
retrofit = "3.0.0"
okhttp = "5.5.1"
ktor = "3.3.0"           # Ktor 3.x line — confirm patch on Maven Central
coroutines = "1.11.0"
serialization = "1.9.0"  # confirm on Maven Central
coil = "3.3.0"           # Coil 3 line — confirm patch on Maven Central
glide = "5.0.0"          # Glide 5 line — confirm on Maven Central
billing = "8.0.0"        # Billing Library 8+ required
gamesV2 = "20.0.0"       # PGS v2 — confirm on Google Maven
# hilt = "..."           # Unverified — read current version at dagger.dev/hilt
# firebaseBom = "..."    # Unverified — read current BoM at firebase.google.com

[libraries]
androidx-core-ktx = { group = "androidx.core", name = "core-ktx", version.ref = "coreKtx" }
androidx-lifecycle-runtime-ktx = { group = "androidx.lifecycle", name = "lifecycle-runtime-ktx", version.ref = "lifecycle" }
androidx-lifecycle-viewmodel-compose = { group = "androidx.lifecycle", name = "lifecycle-viewmodel-compose", version.ref = "lifecycle" }
androidx-activity-compose = { group = "androidx.activity", name = "activity-compose", version.ref = "activityCompose" }
androidx-compose-bom = { group = "androidx.compose", name = "compose-bom", version.ref = "composeBom" }
androidx-compose-ui = { group = "androidx.compose.ui", name = "ui" }
androidx-compose-ui-graphics = { group = "androidx.compose.ui", name = "ui-graphics" }
androidx-compose-ui-tooling-preview = { group = "androidx.compose.ui", name = "ui-tooling-preview" }
androidx-compose-ui-tooling = { group = "androidx.compose.ui", name = "ui-tooling" }
androidx-compose-ui-test-junit4 = { group = "androidx.compose.ui", name = "ui-test-junit4" }
androidx-compose-material3 = { group = "androidx.compose.material3", name = "material3" }
androidx-navigation-compose = { group = "androidx.navigation", name = "navigation-compose", version.ref = "navigation" }
androidx-room-runtime = { group = "androidx.room", name = "room-runtime", version.ref = "room2" }
androidx-room-ktx = { group = "androidx.room", name = "room-ktx", version.ref = "room2" }
androidx-room-compiler = { group = "androidx.room", name = "room-compiler", version.ref = "room2" }
androidx-datastore-preferences = { group = "androidx.datastore", name = "datastore-preferences", version = "1.2.0" } # confirm
androidx-paging-compose = { group = "androidx.paging", name = "paging-compose", version.ref = "paging" }
androidx-camera-camera2 = { group = "androidx.camera", name = "camera-camera2", version.ref = "cameraX" }
androidx-camera-lifecycle = { group = "androidx.camera", name = "camera-lifecycle", version.ref = "cameraX" }
androidx-camera-view = { group = "androidx.camera", name = "camera-view", version.ref = "cameraX" }
androidx-media3-exoplayer = { group = "androidx.media3", name = "media3-exoplayer", version.ref = "media3" }
androidx-media3-ui = { group = "androidx.media3", name = "media3-ui", version.ref = "media3" }
androidx-media3-session = { group = "androidx.media3", name = "media3-session", version.ref = "media3" }
androidx-work-runtime-ktx = { group = "androidx.work", name = "work-runtime-ktx", version.ref = "workManager" }
retrofit = { group = "com.squareup.retrofit2", name = "retrofit", version.ref = "retrofit" }
retrofit-kotlinx-serialization = { group = "com.squareup.retrofit2", name = "converter-kotlinx-serialization", version.ref = "retrofit" }
okhttp = { group = "com.squareup.okhttp3", name = "okhttp", version.ref = "okhttp" }
okhttp-logging = { group = "com.squareup.okhttp3", name = "logging-interceptor", version.ref = "okhttp" }
ktor-client-core = { group = "io.ktor", name = "ktor-client-core", version.ref = "ktor" }
ktor-client-okhttp = { group = "io.ktor", name = "ktor-client-okhttp", version.ref = "ktor" }
kotlinx-coroutines-android = { group = "org.jetbrains.kotlinx", name = "kotlinx-coroutines-android", version.ref = "coroutines" }
kotlinx-serialization-json = { group = "org.jetbrains.kotlinx", name = "kotlinx-serialization-json", version.ref = "serialization" }
coil-compose = { group = "io.coil-kt.coil3", name = "coil-compose", version.ref = "coil" }
coil-network-okhttp = { group = "io.coil-kt.coil3", name = "coil-network-okhttp", version.ref = "coil" }
play-billing = { group = "com.android.billingclient", name = "billing-ktx", version.ref = "billing" }
play-games-v2 = { group = "com.google.android.gms", name = "play-services-games-v2", version.ref = "gamesV2" }
junit = { group = "junit", name = "junit", version = "4.13.2" }
truth = { group = "com.google.truth", name = "truth", version = "1.4.4" } # confirm
turbine = { group = "app.cash.turbine", name = "turbine", version = "1.2.1" } # confirm
mockk = { group = "io.mockk", name = "mockk", version = "1.14.0" } # confirm
leakcanary = { group = "com.squareup.leakcanary", name = "leakcanary-android", version = "2.14" } # confirm

[plugins]
android-application = { id = "com.android.application", version.ref = "agp" }
android-library = { id = "com.android.library", version.ref = "agp" }
kotlin-android = { id = "org.jetbrains.kotlin.android", version.ref = "kotlin" }
kotlin-compose = { id = "org.jetbrains.kotlin.plugin.compose", version.ref = "kotlin" }
kotlin-serialization = { id = "org.jetbrains.kotlin.plugin.serialization", version.ref = "kotlin" }
ksp = { id = "com.google.devtools.ksp", version.ref = "ksp" }
# hilt = { id = "com.google.dagger.hilt.android", version.ref = "hilt" }
```

Room 3 alternative (replace the three Room 2 entries — never both):

```toml
androidx-room3-runtime = { group = "androidx.room3", name = "room-runtime", version.ref = "room3" }
```

## Root `build.gradle.kts`

```kotlin
plugins {
    alias(libs.plugins.android.application) apply false
    alias(libs.plugins.android.library) apply false
    alias(libs.plugins.kotlin.android) apply false
    alias(libs.plugins.kotlin.compose) apply false
    alias(libs.plugins.ksp) apply false
}
```

## App module `build.gradle.kts`

```kotlin
plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.compose)   // Kotlin 2.x: this replaces kotlinCompilerExtensionVersion
    alias(libs.plugins.ksp)
}

android {
    namespace = "com.example.app"
    compileSdk = 36        // use 37 only when the chosen Compose BOM requires it

    defaultConfig {
        applicationId = "com.example.app"
        minSdk = 24
        targetSdk = 36     // required for Play since Aug 31, 2026
        versionCode = 1
        versionName = "1.0"
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            // signing via Play App Signing; upload key configured outside the repo
        }
    }
    buildFeatures { compose = true }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

kotlin { jvmToolchain(17) }

dependencies {
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.lifecycle.runtime.ktx)
    implementation(libs.androidx.activity.compose)
    implementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.compose.ui)
    implementation(libs.androidx.compose.ui.graphics)
    implementation(libs.androidx.compose.ui.tooling.preview)
    implementation(libs.androidx.compose.material3)
    implementation(libs.androidx.navigation.compose)
    implementation(libs.kotlinx.coroutines.android)
    debugImplementation(libs.androidx.compose.ui.tooling)
    debugImplementation(libs.leakcanary)
    testImplementation(libs.junit)
    testImplementation(libs.turbine)
}
```

## `gradle/wrapper/gradle-wrapper.properties`

```properties
distributionUrl=https\://services.gradle.org/distributions/gradle-9.6-bin.zip
```

## Settings `settings.gradle.kts` repositories

```kotlin
pluginManagement { repositories { google(); mavenCentral(); gradlePluginPortal() } }
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories { google(); mavenCentral() }
}
```

Related: [`../docs/03-project-setup-gradle-and-tooling.md`](../docs/03-project-setup-gradle-and-tooling.md),
[`library-directory.md`](library-directory.md).
