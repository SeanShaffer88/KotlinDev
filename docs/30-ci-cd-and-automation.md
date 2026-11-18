# CI/CD and Automation

Automating builds, tests, and releases for Kotlin Android
projects: GitHub Actions as the reference setup, Gradle
caching, Play publishing automation, and device testing.

## What CI Should Do on Every Change

1. Check out the code.
2. Set up JDK 17 (the current Android Gradle Plugin baseline).
3. Build debug and run lint + unit tests.
4. On release branches/tags: build a signed AAB.
5. Optionally: run instrumented tests on Firebase Test Lab
   or an emulator, and distribute to testers.

A red build blocks merging. Never normalise a failing pipeline.

## GitHub Actions — Core Workflow

Android builds run on Linux runners (`ubuntu-latest`). Use a
Windows runner only if a step genuinely needs Windows (rare
for Android; the Android SDK and Gradle are cross-platform).

```yaml
name: Android CI
on:
  push:
    branches: [ main ]
  pull_request:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '17'

      - name: Set up Gradle
        uses: gradle/actions/setup-gradle@v4

      - name: Lint and unit tests
        run: ./gradlew lintDebug testDebugUnitTest

      - name: Build debug APK
        run: ./gradlew assembleDebug
```

Notes:
- Pin actions to current major versions and review updates.
  Check each action's releases page when you adopt it.
- `gradle/actions/setup-gradle` handles the Gradle cache
  correctly, including cache keys per dependency state. Prefer
  it over hand-rolled cache steps.
- Make `gradlew` executable in the repo (`chmod +x gradlew`)
  or add a step that does it.

## Gradle Cache and Speed

- Enable the Gradle build cache and configuration cache in
  `gradle.properties` once the build is stable with them.
- Keep dependency versions in the version catalog so CI and
  local builds resolve identically.
- Avoid downloading the Android SDK manually; the runner image
  and AGP handle SDK components. If you must pin SDK tools,
  use the Android SDK setup action from a trusted publisher
  and record why.
- Split jobs when the pipeline grows: lint/test in parallel
  with assemble, instead of one long serial job.

## Release Builds in CI

```yaml
  release:
    if: startsWith(github.ref, 'refs/tags/')
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '17'
      - uses: gradle/actions/setup-gradle@v4

      - name: Build release AAB
        run: ./gradlew bundleRelease
        env:
          KEYSTORE_BASE64: ${{ secrets.KEYSTORE_BASE64 }}
          KEY_ALIAS: ${{ secrets.KEY_ALIAS }}
          KEY_PASSWORD: ${{ secrets.KEY_PASSWORD }}
          STORE_PASSWORD: ${{ secrets.STORE_PASSWORD }}
```

Signing design:
- The **upload keystore** lives only as CI secrets (base64 in
  an encrypted secret) and in your offline backup. It is never
  committed to the repo.
- Decode it to a temp file in the job, sign, and let the runner
  be destroyed. Play App Signing holds the final app signing
  key (see AGENTS.md rule 4).
- Read passwords from secrets in the Gradle signing config via
  environment variables — never hard-code them in build files.

## Play Publishing Automation

The Gradle Play Publisher plugin automates uploads to Play
Console: AAB upload, release notes, track promotion.

- Plugin: `com.github.triplet.play` (Gradle Play Publisher)
- Docs: https://github.com/Triple-T/gradle-play-publisher

```kotlin
// build.gradle.kts (app module) — shape only; check current docs
play {
    serviceAccountCredentials.set(file("play-service-account.json"))
    track.set("internal")
    releaseStatus.set(com.github.triplet.gradle.androidpublisher.ReleaseStatus.DRAFT)
}
```

Safety rules:
- The Play service account JSON is a **secret**: store it in CI
  secrets, never in the repo. Grant it only the permissions the
  release job needs, for only this app.
- Default to **draft** releases and internal/closed tracks.
  Promote to production deliberately, ideally as a manual step.
- Keep release notes in the repo per locale
  (`src/main/play/release-notes/...`) so they are reviewed in PRs.

Alternatives: Fastlane (`supply`) can drive Play publishing
from Ruby, and the Play Developer API can be called directly
from a script. Pick one route and document it; do not mix.

## Device Testing — Firebase Test Lab and Alternatives

Unit tests do not prove an app runs on real devices.

Options:
- **Firebase Test Lab** — real and virtual devices, Robo tests
  and instrumented tests, results in the Firebase console.
  Trigger from CI with the `gcloud` CLI or a Test Lab action.
- **Firebase App Distribution** — sends test builds to tester
  groups; a good middle step before Play tracks.
- **Play internal testing track** — real Play delivery to up
  to 100 testers; closest to production behaviour.
- **GitHub Actions emulator runner** — the Android emulator
  action on a macOS or Linux runner for instrumented tests
  without an external service. Slower, but self-contained.

Pragmatic split used by many teams:
- Every PR: lint + unit tests + assemble.
- Nightly or pre-release: instrumented tests on Test Lab.
- Release candidate: internal track, then staged rollout.

## Secrets Handling — The Full List

| Secret | Where it lives |
|---|---|
| Upload keystore file | CI secret (base64) + offline backup |
| Keystore / key passwords | CI secrets |
| Play service account JSON | CI secret |
| Firebase config for CI jobs | CI secret if sensitive in context |
| API keys for third-party services | CI secrets for builds; runtime keys via backend or restricted keys |

Never:
- Print secrets in logs (masking helps, not printing is better).
- Put secrets in Gradle files, `gradle.properties` in the repo,
  or workflow YAML in plain text.
- Reuse a production service account for pull-request builds
  from forks. Fork PRs should run without release secrets.

## Versioning in Automation

- Derive `versionCode` from a single source: a checked-in
  counter bumped by the release job, or CI run numbers mapped
  carefully. It must always increase.
- `versionName` follows your scheme (for example semantic
  versioning) and is set in the release commit/tag.
- Tag releases in git (`v1.4.0`) and let the tag trigger the
  release workflow, so the shipped AAB is traceable to a commit.

## Common Pipeline Failures

- JDK mismatch: AGP needs JDK 17 for current versions. A runner
  defaulting to an older JDK fails with confusing errors.
- Missing SDK licenses on a fresh runner setup.
- Lint treated as optional until it blocks a release — run it
  on every PR instead.
- Flaky instrumented tests retried until green. Fix or quarantine
  flaky tests; do not hide them behind retries.

## Official Links

- GitHub Actions: https://docs.github.com/en/actions
- setup-java: https://github.com/actions/setup-java
- Gradle setup action: https://github.com/gradle/actions
- Gradle build cache: https://docs.gradle.org/current/userguide/build_cache.html
- Gradle Play Publisher: https://github.com/Triple-T/gradle-play-publisher
- Play Developer API: https://developers.google.com/android-publisher
- Firebase Test Lab: https://firebase.google.com/docs/test-lab
- Firebase App Distribution: https://firebase.google.com/docs/app-distribution
- Fastlane supply: https://docs.fastlane.tools/actions/supply/
