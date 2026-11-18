# KotlinDev — Android App and Game Development Knowledge Base (Kotlin)

## TL;DR

A complete, self-contained knowledge base for developing Android apps
and games in Kotlin, written for AI agents and humans. It covers the
Kotlin language on Android, the Android platform and its versions,
project setup and Gradle, app anatomy and lifecycle, Jetpack Compose
and Views, navigation, architecture, dependency injection, coroutines
and Flow, data persistence, networking, images/media/camera,
background work, permissions/security/privacy, testing, performance,
accessibility/internationalization/theming, build/signing/Play release,
monetization and Play Billing, form factors, Kotlin Multiplatform and
Compose Multiplatform, and a full games track — Compose Canvas 2D,
libGDX / KorGE / Godot, native graphics and the Android Game
Development Kit (AGDK), Play Games services, and game performance,
input, audio, and saves — plus the working material itself:
copy-and-start **templates**, complete **examples**, helper **tools**,
and quick **reference** tables. Versions and policy dates in this repo
are a snapshot checked in November 2026; anything that could not be
verified is marked **Unverified** rather than repeated as fact. Always
re-check versions on Maven Central and policy on the Play Console
before shipping.

## The ground-truth hierarchy

When sources disagree, this order wins:

1. **The official docs and artifacts themselves** — developer.android.com,
   kotlinlang.org, the AndroidX release notes, and Maven Central /
   Google Maven for exact versions and coordinates.
2. **Google Play policy and requirements** — the Play Console help
   pages and the target API / billing / data safety requirements pages.
3. **This repo** — a distillation of 1 and 2 plus verified third-party
   material, with snapshot dates stated.
4. **Everything else** — blog posts, videos, forum answers, and model
   memory. Useful for patterns and history, never as proof that an
   API, version, or policy exists today.

## What this covers

**Apps and games, both, in Kotlin.** Docs 01–22 and 29–33 are the app
track (with the shared platform, language, and tooling foundations).
Docs 23–28 are the games track: choosing a route, building 2D games
with Compose Canvas, using an engine (libGDX, KorGE, Godot), going
native with AGDK / OpenGL ES / Vulkan, wiring Play Games services,
and handling game-specific performance, input, audio, and saves.
A game is still an Android app underneath — it ships as an Android
App Bundle, follows the same target API and billing rules, and needs
the same testing and release discipline.

## Current-versions snapshot (checked November 2026)

Re-check every row before starting a project; see
[`reference/gradle-and-versions-cheatsheet.md`](reference/gradle-and-versions-cheatsheet.md).

| Thing | Snapshot (Nov 2026) | Notes |
|---|---|---|
| Kotlin | **2.4.21** | Kotlin 2.x; Compose is enabled with the Compose compiler Gradle plugin, not `kotlinCompilerExtensionVersion` |
| Android Studio | **Rabbit 2 — 2026.2.2** | Use the bundled JDK unless a project pins its own |
| Android Gradle Plugin (AGP) | **9.5** | Pairs with Gradle 9.6 and JDK 17 |
| Gradle | **9.6** | Wrapper version in `gradle/wrapper/gradle-wrapper.properties` |
| JDK | **17** | Required by AGP 9.x |
| Jetpack Compose BOM | **2026.09.00** | Import the BOM; do not pin Compose library versions individually unless overriding deliberately |
| compileSdk | **36** (37 for the newest Compose features) | Newest Compose releases may require compileSdk 37 — check the Compose release notes for the BOM you use |
| targetSdk | **36** | API 36 target **required for new apps and app updates since August 31, 2026** |
| Play Billing Library | **8+** | Billing Library 8 or newer required; older versions are rejected for new submissions/updates per Play policy |
| Min SDK | Project choice (commonly 24–26) | State it explicitly; see [`docs/02-android-platform-and-versions.md`](docs/02-android-platform-and-versions.md) |

## How an AI should use this repo

1. Read [`AGENTS.md`](AGENTS.md) — the non-negotiable rules (never
   invent an API or version, target first, AAB + Play App Signing,
   Billing 8+, Play Games Services v2 only).
2. Identify the **target first**: state compileSdk / targetSdk /
   minSdk and whether the project is an app, a Compose Canvas game,
   an engine game, or a native game ([`docs/02-android-platform-and-versions.md`](docs/02-android-platform-and-versions.md),
   [`docs/23-games-overview-choosing-a-route.md`](docs/23-games-overview-choosing-a-route.md)).
3. Start from [`docs/01-kotlin-language-for-android.md`](docs/01-kotlin-language-for-android.md)
   and [`docs/03-project-setup-gradle-and-tooling.md`](docs/03-project-setup-gradle-and-tooling.md).
4. Check every API, library version, and coordinate against
   [`reference/library-directory.md`](reference/library-directory.md)
   and the official sources in [`SOURCES.md`](SOURCES.md) — and
   re-check Maven Central for anything version-sensitive.
5. Prefer the standard library / AndroidX solution and a maintained
   library over hand-rolling ([`reference/library-directory.md`](reference/library-directory.md)).
6. Start from a template or example instead of a blank page:
   [`templates/`](templates/), [`examples/`](examples/), and the
   helpers in [`tools/`](tools/).
7. Test per [`docs/16-testing-strategy.md`](docs/16-testing-strategy.md); release per
   [`docs/19-build-signing-release-and-google-play.md`](docs/19-build-signing-release-and-google-play.md)
   and the checklists in [`checklists/`](checklists/).

## Using this repo with ChatGPT or another AI, locally

This repo is built to be downloaded and used offline by an AI:

1. Download the repo (Code → Download ZIP) and unzip it anywhere.
2. Point the AI at the folder. It should start with
   [manifest.json](manifest.json) (the file map and reading order)
   and [AGENTS.md](AGENTS.md) (the rules), then read in the manifest's
   order.
3. No time to load a folder? Upload [ai-bundle.md](ai-bundle.md)
   instead — the entire knowledge base concatenated into one markdown
   file. (Generated by [tools/build-ai-bundle.py](tools/); the bundle
   covers the docs and references — templates, tools, and example
   code stay as files, listed in the manifest.)

Everything is plain text/markdown with relative links; nothing here
needs a server, an account, or this repository's website.

## Contents — the docs

| File | What it covers |
|---|---|
| [01-kotlin-language-for-android.md](docs/01-kotlin-language-for-android.md) | 01 Kotlin language — Kotlin 2.x on Android: null safety, data/sealed classes, scope functions, collections, delegation, KSP vs KAPT |
| [02-android-platform-and-versions.md](docs/02-android-platform-and-versions.md) | 02 Platform and versions — API levels, compile/target/min SDK, version policy, behavior changes per release |
| [03-project-setup-gradle-and-tooling.md](docs/03-project-setup-gradle-and-tooling.md) | 03 Project setup/Gradle — new project layout, Gradle 9.6 + AGP 9.5, version catalogs, build types, flavors, modules |
| [04-app-anatomy-lifecycle-and-components.md](docs/04-app-anatomy-lifecycle-and-components.md) | 04 App anatomy/lifecycle — Application, Activity, lifecycle, process death, configuration changes, saved state |
| [05-jetpack-compose-ui.md](docs/05-jetpack-compose-ui.md) | 05 Compose UI — composables, state, recomposition, layouts, Material 3, previews, performance |
| [06-views-xml-and-interop.md](docs/06-views-xml-and-interop.md) | 06 Views/interop — the View system, Compose ↔ Views interop both directions, RecyclerView, custom views |
| [07-navigation-and-app-structure.md](docs/07-navigation-and-app-structure.md) | 07 Navigation — Navigation 2 and Navigation 3, type-safe routes, deep links, multi-module navigation |
| [08-architecture-patterns.md](docs/08-architecture-patterns.md) | 08 Architecture — layered architecture, MVVM/MVI, repositories, use cases, unidirectional data flow |
| [09-dependency-injection.md](docs/09-dependency-injection.md) | 09 DI — manual DI, Hilt, Koin: setup, scoping, testing with fakes |
| [10-coroutines-flow-and-concurrency.md](docs/10-coroutines-flow-and-concurrency.md) | 10 Coroutines/Flow — structured concurrency, dispatchers, StateFlow/SharedFlow, lifecycle-aware collection |
| [11-data-persistence-room-datastore-files.md](docs/11-data-persistence-room-datastore-files.md) | 11 Data persistence — Room 2 vs Room 3, DataStore, files, SQLDelight, migrations, backups |
| [12-networking-retrofit-ktor-serialization.md](docs/12-networking-retrofit-ktor-serialization.md) | 12 Networking — Retrofit 3, OkHttp 5, Ktor client, kotlinx.serialization, offline-first sync |
| [13-images-media-camera-and-playback.md](docs/13-images-media-camera-and-playback.md) | 13 Images/media/camera — Coil 3, Glide, Media3, CameraX, photo picker, media permissions |
| [14-background-work-and-foreground-services.md](docs/14-background-work-and-foreground-services.md) | 14 Background work — WorkManager, foreground services and their types, exact alarms, background limits |
| [15-permissions-security-and-privacy.md](docs/15-permissions-security-and-privacy.md) | 15 Permissions/security/privacy — runtime permissions, Play data safety, encryption, network security config |
| [16-testing-strategy.md](docs/16-testing-strategy.md) | 16 Testing — JUnit, Turbine, MockK, Truth, Robolectric, Compose tests, screenshot tests (Roborazzi), LeakCanary |
| [17-performance-profiling-and-optimization.md](docs/17-performance-profiling-and-optimization.md) | 17 Performance — startup, Baseline Profiles, Macrobenchmark, jank, memory, battery, app size |
| [18-accessibility-internationalization-and-theming.md](docs/18-accessibility-internationalization-and-theming.md) | 18 Accessibility/i18n/theming — TalkBack, semantics, localization, RTL, Material 3 theming, dark theme, dynamic color |
| [19-build-signing-release-and-google-play.md](docs/19-build-signing-release-and-google-play.md) | 19 Build/signing/Play release — AAB, Play App Signing, release builds, R8, Play Console tracks, staged rollout |
| [20-monetization-billing-and-ads.md](docs/20-monetization-billing-and-ads.md) | 20 Monetization/billing — Play Billing Library 8+, products, subscriptions, testing purchases, policy |
| [21-form-factors-wear-tv-auto-foldables.md](docs/21-form-factors-wear-tv-auto-foldables.md) | 21 Form factors — phones, tablets, foldables, Wear OS, TV, Auto, ChromeOS, large screens |
| [22-kotlin-multiplatform-and-compose-multiplatform.md](docs/22-kotlin-multiplatform-and-compose-multiplatform.md) | 22 KMP/Compose Multiplatform — Kotlin Multiplatform, shared logic, Compose Multiplatform targets |
| [23-games-overview-choosing-a-route.md](docs/23-games-overview-choosing-a-route.md) | 23 Games overview — the four routes (Compose Canvas, engine, native, hybrid) and how to choose |
| [24-games-2d-with-compose-canvas-and-custom-rendering.md](docs/24-games-2d-with-compose-canvas-and-custom-rendering.md) | 24 Games 2D Compose Canvas — game loop, Canvas drawing, sprites, input, sound in pure Compose |
| [25-games-engines-libgdx-korge-godot.md](docs/25-games-engines-libgdx-korge-godot.md) | 25 Games engines libGDX/KorGE/Godot — libGDX + KTX, KorGE, Godot (incl. godot-kotlin/jvm): setup and Android export |
| [26-games-native-graphics-opengl-vulkan-agdk.md](docs/26-games-native-graphics-opengl-vulkan-agdk.md) | 26 Games native graphics/AGDK — AGDK, GameActivity, OpenGL ES, Vulkan, NDK, frame pacing |
| [27-games-services-play-games-and-play-games-on-pc.md](docs/27-games-services-play-games-and-play-games-on-pc.md) | 27 Play Games services/PC — Play Games Services v2 (sign-in, achievements, leaderboards, cloud save), Google Play Games on PC |
| [28-games-performance-input-audio-and-saves.md](docs/28-games-performance-input-audio-and-saves.md) | 28 Games performance/input/audio/saves — frame budgets, controllers, low-latency audio, save systems |
| [29-backend-sync-and-online-services.md](docs/29-backend-sync-and-online-services.md) | 29 Backend/sync — Firebase, custom backends, offline-first sync, push (FCM), remote config |
| [30-ci-cd-and-automation.md](docs/30-ci-cd-and-automation.md) | 30 CI/CD — GitHub Actions, Gradle caching, lint in CI, Play publishing automation, Fastlane |
| [31-migration-java-and-views-to-modern-kotlin.md](docs/31-migration-java-and-views-to-modern-kotlin.md) | 31 Migration — Java → Kotlin, Views → Compose, Groovy → Kotlin DSL, version upgrades, deprecated API exits |
| [32-patterns-cookbook.md](docs/32-patterns-cookbook.md) | 32 Patterns cookbook — the recurring code shapes: Result wrappers, repositories, paging, forms, search, offline cache |
| [33-ai-assisted-development.md](docs/33-ai-assisted-development.md) | 33 AI-assisted development — the ground-truth discipline, and how AI help goes wrong on Android code |

## Reference

| File | What it covers |
|---|---|
| [api-levels.md](reference/api-levels.md) | Every Android API level 1–37 with codenames and `VERSION_CODE` constants |
| [library-directory.md](reference/library-directory.md) | Categorized library table: purpose, coordinates, license, when to use / avoid |
| [gradle-and-versions-cheatsheet.md](reference/gradle-and-versions-cheatsheet.md) | Sample `libs.versions.toml` + `build.gradle.kts` snippets at the verified snapshot versions |
| [adb-and-tooling-commands.md](reference/adb-and-tooling-commands.md) | adb, emulator, bundletool, apkanalyzer, lint, and scrcpy command cheatsheet |
| [play-requirements-and-deadlines.md](reference/play-requirements-and-deadlines.md) | Target API timeline, Billing 8+, 16 KB page size enforcement, AAB, data safety |
| [permissions-table.md](reference/permissions-table.md) | Dangerous permissions by API level, foreground service types, special permissions |
| [game-route-comparison.md](reference/game-route-comparison.md) | The game-route matrix from doc 23 in table form |

## Working material

| Folder | What it holds |
|---|---|
| [templates/](templates/) | Starter project skeleton: a Compose app (Gradle wrapper files, version catalog, manifest, MainActivity), plus GitHub Actions CI and release-AAB workflow templates |
| [examples/](examples/) | Worked examples: Hello Compose, a Counter MVVM + Flow screen, Room notes (entity/DAO/repository), and a Compose Canvas game loop |
| [tools/](tools/) | `build-ai-bundle.py` bundle generator, `new-project` scaffolders (bash + PowerShell), `check-project.py` validator, `versions.json`, IDE notes |
| [checklists/](checklists/) | [New project](checklists/new-project-checklist.md), [pre-release](checklists/pre-release-checklist.md), [Play submission](checklists/play-submission-checklist.md), [game release](checklists/game-release-checklist.md), [performance audit](checklists/performance-audit-checklist.md), [security and privacy](checklists/security-and-privacy-checklist.md) |

## Root files

| File | What it covers |
|---|---|
| [AGENTS.md](AGENTS.md) | Hard rules for AI agents writing Kotlin Android code from this repo |
| [SOURCES.md](SOURCES.md) | Curated, verified source list — official docs, samples, books, communities, games sources |
| [manifest.json](manifest.json) | Machine-readable file map and reading order (generated) |
| [ai-bundle.md](ai-bundle.md) | The whole knowledge base in one file for upload to an AI (generated) |
