# AGENTS.md — Instructions for AI agents writing Kotlin Android code

You are using this repository as your knowledge base for creating
Android apps and games in Kotlin. Follow these rules exactly.

## Non-negotiable rules

1. **Never invent APIs, library versions, or Maven coordinates.**
   Every Android/Kotlin API call, Gradle plugin, and library version
   you write must be traceable to one of: developer.android.com,
   kotlinlang.org, the AndroidX release notes, or the artifact's page
   on Maven Central / Google Maven. If you cannot trace it, do not
   write it — say it is **Unverified** instead. Android APIs are
   version-gated and libraries rename artifacts between majors; a
   plausible-sounding coordinate is the single most common AI failure
   on Android code.
2. **Target/flavor first.** Before writing code, state the target:
   compileSdk, targetSdk, and minSdk; app vs game; and for games the
   route (Compose Canvas / libGDX / KorGE / Godot / native AGDK).
   Behavior changes, permission rules, and available APIs all depend
   on these numbers ([`docs/02-android-platform-and-versions.md`](docs/02-android-platform-and-versions.md)).
   Snapshot at time of writing: target API 36 (required for new apps
   and updates since August 31, 2026), compileSdk 36 — 37 where the
   newest Compose features require it.
3. **Kotlin 2.x + the Compose compiler plugin.** Kotlin 2.x projects
   enable Compose with the Compose compiler Gradle plugin
   (`org.jetbrains.kotlin.plugin.compose`) applied alongside the
   Kotlin Android plugin. Never set `kotlinCompilerExtensionVersion`
   in a Kotlin 2.x project — that property belongs to the Kotlin 1.x
   era and breaks or misconfigures modern builds. Use KSP, not KAPT,
   for new annotation processing.
4. **Ship an Android App Bundle (AAB) with Play App Signing.** Release
   builds are `.aab`, signed through Play App Signing (Google holds
   the final signing key; you hold the upload key). Do not plan a
   release around a directly-distributed release APK except for
   sideload/testing builds, and never put a production keystore or
   its passwords in the repo.
5. **Play Billing Library 8 or newer.** Any in-app purchase or
   subscription code targets Billing Library 8+. Older billing
   versions are rejected by Play for new submissions and updates.
   Test purchases with license testers and the Play Billing test
   tracks, never with real charges ([`docs/20-monetization-billing-and-ads.md`](docs/20-monetization-billing-and-ads.md)).
6. **Play Games Services v2 only.** New integrations use Play Games
   Services (PGS) v2 — automatic sign-in, the v2 SDK and APIs. Do
   not write new code against PGS v1 (`GoogleSignIn`-era Games APIs);
   it is the legacy path ([`docs/27-games-services-play-games-and-play-games-on-pc.md`](docs/27-games-services-play-games-and-play-games-on-pc.md)).
7. **Room 3 is not Room 2.** Room 3.x and Room 2.x are different
   majors with different artifacts and setup (Room 3 is KMP-ready
   and KSP-only). Name which one a project uses and use that major's
   coordinates and migration APIs consistently — never mix Room 2
   tutorials into a Room 3 project or vice versa
   ([`docs/11-data-persistence-room-datastore-files.md`](docs/11-data-persistence-room-datastore-files.md),
   [`reference/library-directory.md`](reference/library-directory.md)).
8. **Media3 is the media library.** Video/audio playback uses
   **Jetpack Media3** (`androidx.media3`) — standalone ExoPlayer 2
   (`com.google.android.exoplayer2`) is its predecessor and is not
   used for new code. Image loading default is **Coil 3** with its
   `io.coil-kt.coil3` coordinates — Coil 2 coordinates
   (`io.coil-kt:coil-compose`) in a new project are a version mix-up.
9. **No secrets in code.** No API keys, keystore passwords, service
   account JSON, or tokens committed to the repo or hard-coded in
   source. Use `local.properties` / environment variables locally and
   CI secrets in automation; anything user-sensitive at runtime is
   encrypted at rest. A key that shipped in an APK/AAB is public.
10. **Respect the platform limits.** Runtime permissions are requested
    at point of use with a rationale; background work goes through
    WorkManager or a declared foreground service type; exact alarms,
    full-screen intents, and special permissions are used only where
    the feature genuinely qualifies. Check
    [`reference/permissions-table.md`](reference/permissions-table.md)
    and [`reference/play-requirements-and-deadlines.md`](reference/play-requirements-and-deadlines.md)
    before writing permission or background code.
11. **Verify before declaring done.** Run the matching checklist in
    [`checklists/`](checklists/). State plainly which checks ran
    (build, unit tests, instrumented tests, a device/emulator run)
    and which could not be run — label those **Unverified** rather
    than claiming success. Code that has never compiled is not done.

## Build order (always in this sequence)

1. Name the target: compileSdk / targetSdk / minSdk + app or game
   route (rule 2).
2. Set up the project and version catalog
   ([`docs/03-project-setup-gradle-and-tooling.md`](docs/03-project-setup-gradle-and-tooling.md),
   [`reference/gradle-and-versions-cheatsheet.md`](reference/gradle-and-versions-cheatsheet.md));
   confirm a clean debug build runs on an emulator.
3. Lay out the architecture: UI layer, repository layer, data sources
   ([`docs/08-architecture-patterns.md`](docs/08-architecture-patterns.md)).
4. Build the smallest end-to-end slice (one screen/feature, real
   data path); confirm it runs.
5. Add features one at a time, checking each new API call and library
   version against the ground-truth sources (rule 1) and testing as
   you go.
6. Add persistence, background work, billing/games services, and
   polish as the feature list needs them.
7. Release build: AAB + Play App Signing, R8, Baseline Profile; run
   [`checklists/pre-release-checklist.md`](checklists/pre-release-checklist.md).

## Things that are always wrong

- An API, plugin, or Maven coordinate that appears in no official
  source or artifact repository for the stated version.
- `kotlinCompilerExtensionVersion` in a Kotlin 2.x project.
- A release plan built on a raw APK instead of an AAB for Play.
- Billing code below Billing Library 8, or PGS v1 code in a new game.
- Room 2 and Room 3 coordinates/APIs mixed in one project.
- New playback code on standalone ExoPlayer 2 instead of Media3, or
  new image code on Picasso (maintenance-era) instead of Coil 3/Glide.
- `AsyncTask` (deprecated), `GlobalScope` launches, or network/database
  work on the main thread.
- Secrets, keystores, or passwords committed to version control.
- Requesting every permission at first launch "just in case".
- Treating a blog post, video, or model memory as proof a version or
  policy is current — re-check Maven Central / Play Console help.
