// Macrobenchmark module — copy this module into your project as
// `:macrobenchmark`, add it to settings.gradle.kts, and point
// targetProjectPath at your app module.
//
// Versions come from your version catalog. The shape below matches
// benchmark-macro-junit4 1.5.0 (see README.md — re-check the current
// Benchmark release before use).
plugins {
    id("com.android.test")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.example.app.macrobenchmark"
    compileSdk = 37

    defaultConfig {
        minSdk = 24 // macrobenchmark requires API 24+ devices/emulators
        targetSdk = 37

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        // Benchmarks must run against a profileable/debuggable=false build of the
        // TARGET app; this module's own build type just needs to be consistent.
        create("benchmark") {
            isDebuggable = true // the test module may be debuggable; the app must not rely on it
            signingConfig = signingConfigs.getByName("debug")
            matchingFallbacks += listOf("release")
        }
    }
    targetProjectPath = ":app"
    experimentalProperties["android.experimental.self-instrumenting"] = true
}

dependencies {
    implementation(libs.androidx.benchmark.macro.junit4)
    implementation(libs.androidx.test.ext.junit)
    implementation(libs.androidx.test.runner)
    implementation(libs.androidx.uiautomator)
}

// Library versions this expects in gradle/libs.versions.toml:
//   benchmarkMacroJunit4 = "1.5.0"  -> androidx.benchmark:benchmark-macro-junit4
//   uiautomator = "2.3.0"           -> androidx.test.uiautomator:uiautomator
// Verify both on the AndroidX Benchmark / Test release pages before use.
