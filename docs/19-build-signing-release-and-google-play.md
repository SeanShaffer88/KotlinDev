# Build, Signing, Release, and Google Play
How to take an Android app from a debug build to a signed release on Google Play. Covers build types, variants, signing, the Android App Bundle, versioning, release tracks, and key Play Console policies. When a rule here and an official page disagree, the official page wins.
## Build types
A build type controls how an app is compiled for a purpose. Most projects start with two:
- `debug` — for development. Debuggable, signed with a debug key, optimizations off for fast builds.
- `release` — for users. Not debuggable, code/resources shrunk and optimized, signed with your release key.
```kotlin
android {
    buildTypes {
        getByName("debug") {
            applicationIdSuffix = ".debug"
            isDebuggable = true
        }
        getByName("release") {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```
`isMinifyEnabled` turns on R8, which removes unused code and obfuscates names. Always test the release build on a real device before uploading — R8 problems do not show up in debug builds.
See: https://developer.android.com/build/build-variants
## Product flavors and variants
A product flavor is an edition of the app, for example `free` and `paid`, or `demo` and `full`. Flavors plus build types produce **build variants**: `freeDebug`, `freeRelease`, `paidDebug`, `paidRelease`.
```kotlin
android {
    flavorDimensions += "tier"
    productFlavors {
        create("free") { dimension = "tier"; applicationIdSuffix = ".free" }
        create("paid") { dimension = "tier" }
    }
}
```
Give each flavor its own source folder when code differs, e.g. `src/free/kotlin/` and `src/paid/kotlin/`. Keep shared code in `src/main/`. Do not copy whole screens between flavors — share logic and vary only the part that differs.
See: https://developer.android.com/build/build-variants#product-flavors
## Version code and version name
Every upload to Google Play needs two version values:
- `versionCode` — a whole number that must **increase** with every upload. Play uses it to decide which build is newer. Users never see it.
- `versionName` — the text users see, such as `1.4.0`. It can follow semantic versioning: major.minor.patch.
```kotlin
android {
    defaultConfig {
        versionCode = 42
        versionName = "1.4.0"
    }
}
```
A common pattern is to generate `versionCode` in CI from the build number so it never repeats. Never reuse a version code, even for a different track — Play will reject the upload.
## App signing and Play App Signing
Android requires every app to be digitally signed. **Play App Signing** is required for new apps published as bundles:
- You hold an **upload key** and sign the bundle you upload.
- Google holds the final **app signing key** and signs the APKs delivered to devices.
- If you lose your upload key, Google can reset it after verifying your identity. Losing an old self-managed signing key meant you could never update the app again.
Enroll in Play Console under **Release > Setup > App signing**. Generate the upload key with `keytool`, store it outside the repo, and never commit the keystore or its passwords to version control. Use environment variables or a secrets store in CI.
```kotlin
// build.gradle.kts — read secrets from the environment, not source
android {
    signingConfigs {
        create("release") {
            storeFile = file(System.getenv("KEYSTORE_PATH") ?: "missing")
            storePassword = System.getenv("KEYSTORE_PASSWORD")
            keyAlias = System.getenv("KEY_ALIAS")
            keyPassword = System.getenv("KEY_PASSWORD")
        }
    }
}
```
See: https://developer.android.com/studio/publish/app-signing and https://support.google.com/googleplay/android-developer/answer/9842756
## Android App Bundle (AAB)
New apps must be published as an **Android App Bundle** (`.aab`), not a plain APK. A bundle contains all code and resources. Play uses it to generate split APKs so each device downloads only what it needs: its language, screen density, and CPU type. That makes downloads smaller.
Build one from Android Studio with **Build > Generate Signed App Bundle / APK**, or from the command line:
```bash
./gradlew :app:bundleRelease
# Output: app/build/outputs/bundle/release/app-release.aab
```
Use `bundletool` locally to test what Play will generate from the bundle before you upload.
See: https://developer.android.com/guide/app-bundle
## Target API requirement
Google Play raises the minimum target API level every year. Apps must target a recent Android version to be discoverable and updatable.
**Rule to plan for:** From **31 August 2026**, new apps and app updates must target **Android 16 (API level 36) or higher** to be submitted to Google Play, with limited extensions available in Play Console for apps that need more time. Existing apps targeting older levels may stop being available to devices running newer Android versions.
Check the current deadline before every release — the date and level move each year:
- https://developer.android.com/google/play/requirements/target-sdk
- https://support.google.com/googleplay/android-developer/answer/11926878
```kotlin
android {
    compileSdk = 36
    defaultConfig { targetSdk = 36; minSdk = 26 }
}
```
Raising `targetSdk` can change behavior (permissions, background work, edge-to-edge display), so test the upgrade — do not just change the number.
## Release tracks and testing tracks
Play Console tracks are separate channels for builds:
| Track | Who sees it | Use it for |
| --- | --- | --- |
| Internal testing | Up to 100 testers you list | Fast daily checks |
| Closed testing | Tester lists or Google Groups | Beta groups, QA |
| Open testing | Anyone who opts in on Play | Public beta |
| Production | All users in chosen countries | The real release |
New personal developer accounts must run a closed test with a minimum number of testers for a set period before applying for production access. Check the current requirement in Play Console.
Promote the **same bundle** from testing to production instead of rebuilding. A rebuild gets a new version code and has not been tested in the exact form users will receive.
## Staged rollout
A production release does not have to reach everyone at once. A **staged rollout** releases to a percentage of users first, for example 10%, then 50%, then 100% over several days.
- Watch crash and ANR (app not responding) rates in Android vitals while rolling out.
- You can halt a rollout at any time if a problem appears.
- Users who already got the new version keep it; everyone else stays on the previous version.
- Releasing a fix requires a new version code.
Start small for any release that touches startup, storage, payments, or background work.
See: https://support.google.com/googleplay/android-developer/answer/6346149
## Play Console policies overview
All apps must follow the Google Play Developer Program Policies. Areas that catch the most developers out:
- **User data and permissions** — request only permissions the feature needs; explain why in the app and in the privacy policy.
- **Deceptive behavior** — no misleading claims, fake system dialogs, or hidden functionality.
- **Malware and security** — no code downloaded after install that changes behavior outside Play's update mechanism.
- **Families** — apps aimed at children have stricter ad, data, and content rules (see the monetization guide in this set).
- **Health, financial, and news apps** — extra declarations and review apply.
Read the policy center before building a feature in a sensitive area, not after review rejects it: https://play.google.com/about/developer-content-policy/
Violations are handled with warnings, rejections, or suspensions depending on severity. Appeals are possible from Play Console.
## Data safety section
Every app must complete the **Data safety** section in Play Console (**Policy and programs > App content**). It is the label users see on the store listing, so it must match reality:
- Which data types you collect, share, and why.
- Whether data is encrypted in transit.
- Whether users can request deletion, and how.
- Data collected by third-party SDKs counts as your data.
"Collect" includes data sent off the device by any library in your app. Audit your SDK list before answering, and update the section whenever you add analytics, ads, or crash reporting.
See: https://support.google.com/googleplay/android-developer/answer/10787469
## Ratings, reviews, and store listing
- **Content rating** — complete the rating questionnaire in Play Console. Answers produce ratings for each region (IARC system). An inaccurate rating can get the app removed in that region.
- **Target audience** — declare who the app is for. Declaring children as an audience triggers the Families policies.
- **Store listing** — title, descriptions, screenshots, and feature graphic must not make claims the app cannot back up, and must not use misleading keywords or fake review quotes.
Respond to reviews in Play Console, and treat repeated reports of the same crash or confusion as a bug report, not noise.
## Pre-launch checklist
1. Release build tested on a real device, including upgrade from the previous production version.
2. `versionCode` increased; `targetSdk` meets the current rule.
3. Bundle built from the release variant and signed for upload.
4. Internal test track passed, then closed test if required.
5. Data safety, content rating, and target audience are current.
6. Privacy policy URL is live and matches the app's behavior.
7. Staged rollout percentage and halt criteria decided in advance.
8. Crash reporting checked in Android vitals after each stage.
## Summary
Build types separate debug from release, flavors create editions, and variants are the combination. Sign with an upload key and let Play App Signing hold the final key. Ship a bundle, keep the version code climbing, target API 36 or higher for submissions from 31 August 2026, test on the testing tracks, and roll out in stages while watching vitals. Policies, data safety, and ratings are part of the release, not paperwork after it.
