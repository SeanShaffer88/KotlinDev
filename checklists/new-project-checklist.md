# New Project Checklist

Run at project start, before feature work. Targets:
[`../docs/02-android-platform-and-versions.md`](../docs/02-android-platform-and-versions.md),
[`../docs/03-project-setup-gradle-and-tooling.md`](../docs/03-project-setup-gradle-and-tooling.md).

## Target first (`AGENTS.md` rule 2)

- [ ] Target stated in writing: app or game; for a game, the route
      (Compose Canvas / libGDX / KorGE / Godot / native AGDK —
      [`../reference/game-route-comparison.md`](../reference/game-route-comparison.md)).
- [ ] compileSdk / targetSdk / minSdk chosen and recorded
      (snapshot: compile 36, target 36, min 24–26 unless the audience
      says otherwise).
- [ ] Form factors in scope named (phone / tablet / foldable / Wear /
      TV / Auto) — [`../docs/21-form-factors-wear-tv-auto-foldables.md`](../docs/21-form-factors-wear-tv-auto-foldables.md).

## Project setup

- [ ] Created with the current Android Studio (snapshot: Rabbit 2,
      2026.2.2) or the matching templates in [`../templates/`](../templates/).
- [ ] Kotlin 2.x with the **Compose compiler plugin** applied; no
      `kotlinCompilerExtensionVersion` anywhere.
- [ ] Gradle wrapper at 9.6, AGP 9.5 line, JDK 17 toolchain.
- [ ] Versions centralized in `gradle/libs.versions.toml`; Compose
      imported via the BOM (2026.09.00 snapshot) — every version
      re-checked on Maven Central / Google Maven at setup time.
- [ ] KSP (not KAPT) configured for Room/Hilt/codegen.
- [ ] Package name / `applicationId` chosen (reverse-domain, permanent
      once published) and `namespace` set per module.
- [ ] Clean `./gradlew assembleDebug` build runs on an emulator at
      targetSdk and one at minSdk.

## Structure

- [ ] Architecture shape picked (single module vs modularized;
      UI / domain / data layers) — [`../docs/08-architecture-patterns.md`](../docs/08-architecture-patterns.md).
- [ ] DI approach picked (manual / Hilt / Koin) —
      [`../docs/09-dependency-injection.md`](../docs/09-dependency-injection.md).
- [ ] Git repo initialized; `.gitignore` covers `local.properties`,
      keystores, `*.jks`, build output; no secrets committed
      (`AGENTS.md` rule 9).
- [ ] License file and README skeleton in place.

## Early decisions (expensive to change later)

- [ ] Persistence plan: Room 2 **or** Room 3 (never both), DataStore
      for settings — [`../docs/11-data-persistence-room-datastore-files.md`](../docs/11-data-persistence-room-datastore-files.md).
- [ ] Navigation approach: Navigation 2 (stable) or Navigation 3.
- [ ] Monetization plan noted (Billing 8+ if purchases exist) and,
      for games, PGS v2 planned from the start.
- [ ] Baseline Profile + Macrobenchmark modules planned for
      performance-sensitive apps — [`../docs/17-performance-profiling-and-optimization.md`](../docs/17-performance-profiling-and-optimization.md).
