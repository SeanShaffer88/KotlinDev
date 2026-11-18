# R8 / ProGuard Rules Template

R8 shrinks, optimizes, and obfuscates release builds. It is on by
default for release (`isMinifyEnabled = true` in the app module);
`proguard-rules.pro` in this folder is the app-level rule file AGP
reads alongside every library's own consumer rules.

## How to use

1. Copy `proguard-rules.pro` to `app/proguard-rules.pro` (or merge
   its sections into your existing file).
2. Wire it in the app module:

   ```kotlin
   buildTypes {
       release {
           isMinifyEnabled = true
           isShrinkResources = true
           proguardFiles(
               getDefaultProguardFile("proguard-android-optimize.txt"),
               "proguard-rules.pro"
           )
       }
   }
   ```

3. Build the release AAB and **test the release build itself** —
   R8 breakage (missing class, stripped serializer, Room `*_Impl`
   not found) only shows up in release, never in debug.

## What the rules cover, and why

- **Stack traces:** `SourceFile,LineNumberTable` kept so Play vitals
  / Crashlytics traces stay readable after deobfuscation. Upload or
  archive the `mapping.txt` from every release build
  (`app/build/outputs/mapping/release/mapping.txt`) — without it the
  traces are useless.
- **kotlinx.serialization:** generated serializers and companions are
  reached reflectively, so they get explicit keeps.
- **Retrofit:** service interfaces are dynamic proxies; their HTTP
  annotations must survive. OkHttp/Okio need no keeps (their consumer
  rules handle it) — only two well-known `-dontwarn`s.
- **Room:** generated `*_Impl` classes are instantiated by name.
  Room 2 (`androidx.room`) and Room 3 (`androidx.room3`) variants
  are both in the file, one commented out — enable the one matching
  your major, never both blindly.

## Rules of thumb

- Libraries ship consumer rules; your file should stay short. Every
  rule here has a comment saying why it exists — keep that habit.
- Fix the smallest surface that breaks: a single class keep beats
  `-keep class com.example.** { *; }`, which silently disables
  shrinking for your whole app.
- Prefer `@Keep` on a class over a rule in this file when the class
  is yours — the instruction travels with the code.
- After changing rules, re-run the release build and a smoke pass of
  the risky flows: first launch, database open, every network call,
  and any screen using reflection/serialization.
