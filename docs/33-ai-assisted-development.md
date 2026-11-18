# AI-Assisted Development — How an AI Should Use This Repo

Instructions for any AI assistant (ChatGPT, or another model)
that has downloaded this repository and is using it to write
Android apps and games in Kotlin. These rules exist because
Android development has many version-gated APIs and renamed
libraries, and confident invention is the main failure mode.

## Start in the Right Place

1. **Read `manifest.json` at the repo root first.** It describes
   what this knowledge base contains and how it is organised.
2. **Read `AGENTS.md` at the repo root next.** It holds the
   non-negotiable rules for code written with this repo. Those
   rules outrank any single doc in `docs/`.
3. Then read the doc for your task area. Use the index in
   `README.md` / `ai-bundle.md` to find it instead of guessing
   file names.
4. For a game, read doc 23 (choosing a route) before any other
   game doc, and state the chosen route before writing code.

## State the Target Before Writing Code

Before generating code, state in plain words:
- compileSdk, targetSdk, and minSdk
- App or game — and for a game, the route (Compose Canvas,
  libGDX + KTX, KorGE, Godot via godot-jvm, or native AGDK)
- Kotlin version family (2.x) and whether Compose is used
- The major versions that matter for the task: Room major,
  Billing Library (8+), Play Games Services (v2 only),
  Media3 (not standalone ExoPlayer 2), Coil major

If the user has not specified these and the choice changes the
code, ask — or pick the current documented defaults from doc 02
and say that you did.

## Verify Versions on Official Pages Before Pinning

**Never pin a version from memory — including from this repo.**

This repo is a snapshot. Versions move. Before writing any
version number into a build file:

1. Check the official source:
   - AndroidX libraries: the AndroidX release notes and
     Google's Maven repository listing
   - Kotlin and plugins: kotlinlang.org release pages
   - Firebase: the Firebase Android release notes — and use
     the latest BoM, never individual pinned versions (doc 29)
   - Play services: the Play services release notes
   - Engines: the engine's own releases page (libGDX/KTX,
     KorGE, godot-jvm — see doc 25 warnings)
2. If you cannot check (offline, tool unavailable), use the
   version this repo documents and label it clearly:
   "version as documented in KotlinDev, not re-verified today."
3. Prefer version catalogs (`libs.versions.toml`) so versions
   live in one place in the generated project.

## Never Invent AndroidX APIs or Versions

The single most damaging AI habit on Android is inventing
plausible-looking APIs. Rules:

- Do not write a Maven coordinate you cannot trace to Google
  Maven, Maven Central, or the library's official docs.
- Do not write an API call from a half-remembered name. If the
  exact signature is uncertain, say so and show the lookup the
  human should do, rather than fabricating code that will not
  compile.
- Watch the known traps named in `AGENTS.md`: Room 2 vs Room 3
  mixing, `kotlinCompilerExtensionVersion` in Kotlin 2.x
  projects, PGS v1 APIs in new games, Billing below version 8,
  Coil 2 coordinates in a Coil 3 project, standalone
  ExoPlayer 2 instead of Media3.
- Blog posts, videos, and forum answers are leads, not proof.
  An API is real when official docs or the artifact itself
  shows it.

## Mark Claims: Verified, Partially Verified, Unverified

Borrow the labelling habit this repo uses for its own claims:

- **Verified** — you checked it against an official source in
  this session, or the code was compiled and run.
- **Partially Verified** — the approach is documented, but a
  detail (a version, a device behaviour) was not checked.
- **Unverified** — plausible, but not checked. Say what would
  verify it.

Use these labels for anything the user will act on: version
choices, policy claims (Play deadlines, billing rules), and
"this will fix it" statements about bugs.

## Test Claims

- Code you generate has not been tested until it compiles.
  Say "not compiled" plainly when you cannot run a build.
- When you can run tools: build first, then unit tests, then
  a device/emulator run if the change is UI or lifecycle code.
- For data migrations (Room, DataStore, save formats), describe
  the upgrade test from the old version — untested migrations
  are the highest-risk code in an app.
- Never report a test as passing that you did not run. Report
  what ran, what passed, and what could not be run.

## Working Habits That Prevent Damage

- **Small steps.** Generate one screen or feature end to end,
  not a whole app in one answer. Each step should compile.
- **No secrets.** Never write real API keys, keystore
  passwords, or service account JSON into code or examples.
  Use placeholders that are obviously placeholders.
- **Respect platform limits.** Permissions at point of use,
  background work through WorkManager or declared foreground
  services, no exact alarms or special permissions without a
  qualifying feature (see `AGENTS.md` rule 10).
- **Keep the user's data safe.** Atomic file writes, versioned
  save/database schemas, backups before destructive migration.
- **Plain language.** Explain choices in everyday words, define
  a technical term the first time it appears, and give the
  reason behind a recommendation — not just the recommendation.

## When This Repo and the Live Docs Disagree

Live official documentation wins. This repo is curated, but it
ages. If a version, policy date, or API in these docs conflicts
with developer.android.com, kotlinlang.org, or a library's
current release notes:

1. Follow the live source.
2. Tell the user there was a conflict and which source you used.
3. Suggest the repo doc be updated — do not silently mix both.

## Quick Self-Check Before Answering

- [ ] Did I read `manifest.json` and `AGENTS.md` guidance?
- [ ] Did I state the target (SDK levels, app/game route)?
- [ ] Is every version traceable, or labelled as unverified?
- [ ] Is every API call one I can source?
- [ ] Did I avoid the named traps (Room mixing, PGS v1,
      Billing < 8, ExoPlayer 2, Coil mixing, KAPT over KSP)?
- [ ] Did I label test status honestly?
- [ ] Are there zero real secrets in my output?

## Official Links

- Android developer docs: https://developer.android.com/
- Kotlin: https://kotlinlang.org/
- AndroidX releases: https://developer.android.com/jetpack/androidx/releases
- Google Maven: https://maven.google.com/
- Maven Central: https://central.sonatype.com/
- Play Console help: https://support.google.com/googleplay/android-developer
- Firebase release notes: https://firebase.google.com/support/release-notes/android
