# Code Quality Templates — detekt + .editorconfig (+ ktlint)

Static analysis catches the boring bugs (swallowed exceptions,
`GlobalScope`, unsafe casts, magic numbers in logic) before review
does. This folder gives you a starting configuration for the two
tools Android Kotlin projects normally use together:

- **detekt** — bug/complexity/style analysis over Kotlin code
  (`detekt.yml` here).
- **ktlint** — formatting only: one true style, enforced. The
  `.editorconfig` here carries the shared style both Android Studio
  and ktlint read.

## Wire detekt into Gradle

In the root `build.gradle.kts` (versions via your version catalog):

```kotlin
plugins {
    alias(libs.plugins.detekt) apply false
}

subprojects {
    apply(plugin = "io.gitlab.arturbosch.detekt")
    detekt {
        config.setFrom("$rootDir/config/detekt.yml") // this file, wherever you keep it
        buildUponDefaultConfig = true
        allRules = false
        autoCorrect = true // only for rules marked correctable; review the diff
    }
    tasks.withType<Detekt>().configureEach {
        reports {
            html.required.set(true)
            sarif.required.set(true) // uploads nicely to GitHub code scanning
        }
    }
}
```

Run `./gradlew detekt`. Add it to CI after `test` so a red detekt
blocks a merge the same way a red test does. Generate a baseline
(`./gradlew detektBaseline`) only for a legacy codebase you are
adopting detekt into — a new project should start at zero issues
(`maxIssues: 0` in the config).

## Wire ktlint into Gradle

Either the ktlint Gradle plugin or a plain JavaExec task over the
ktlint CLI. The plugin route:

```kotlin
plugins {
    alias(libs.plugins.ktlint)
}
// ./gradlew ktlintCheck   — verify formatting (CI)
// ./gradlew ktlintFormat  — fix formatting locally
```

Keep ktlint and detekt responsibilities separate: ktlint owns
*formatting* (turn detekt's overlapping formatting rules off, as this
config does), detekt owns *analysis*.

## What this detekt config chooses

- Hard on real bugs: `SwallowedException`, `PrintStackTrace`,
  `GlobalCoroutineUsage`, `UnsafeCallOnNullableType`,
  `ImplicitDefaultLocale`, `TooGenericExceptionCaught`.
- Lenient on documentation theater: public app classes/functions do
  not need KDoc to pass.
- Composable-friendly: PascalCase function names are allowed in UI
  files; magic numbers are ignored in tests and build scripts.
- TODOs must carry an issue number: `TODO(#123)`.

## Version-check warning

**Verify current versions and rule names before use.** detekt and
ktlint both rename rules and config keys between releases, and this
snapshot was written in November 2026. Check the detekt and ktlint
release notes / Maven Central for the current plugin versions, run
`./gradlew detekt` once after wiring, and fix any "unknown rule"
warnings by name — never by deleting whole rule sets.
