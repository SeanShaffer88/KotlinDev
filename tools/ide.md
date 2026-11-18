# Android Studio — recommended settings and setup

Baseline: Android Studio **Rabbit 2 2026.2.2**, JDK **17** (the bundled
JetBrains Runtime is fine for most work; point Gradle at a local JDK 17
only when a build script requires it). Versions verified November 2026 —
see [`versions.json`](versions.json) and re-check before a production
project.

## Install / enable

- **Kotlin plugin** — bundled with Android Studio; keep it updated with
  the IDE. Do not install a second Kotlin plugin from the Marketplace.
- **Jetpack Compose tooling** — bundled: live preview, multi-preview,
  and the Compose compiler are part of the IDE + the Kotlin Compose
  compiler Gradle plugin (`org.jetbrains.kotlin.plugin.compose`).
  No separate plugin to install.
- **Git** — bundled Git integration is enough; enable
  *Settings → Version Control → Commit → Reformat code / Optimize
  imports* only if the whole team agrees (it rewrites diffs).

Useful Marketplace additions (optional, all free):

- **.ignore** — syntax + templates for `.gitignore`.
- **Key Promoter X** — teaches you the shortcut for anything you click.
- **Rainbow Brackets** — bracket matching help in dense Compose code.

Avoid random "Compose helper" plugins of unknown provenance; the
bundled tooling covers preview, inspection, and debugging.

## Settings worth changing

| Setting | Value | Why |
|---|---|---|
| Editor → Code Style → Kotlin | Use the Kotlin style guide; indent 4 | Matches `ktlint` / official style |
| Editor → Inlay Hints (Kotlin) | Parameter names on for Compose calls | Long Compose parameter lists stay readable |
| Build → Gradle | Gradle JDK = 17 | AGP 9.x requires JDK 17 |
| Build → Compiler | Add `--warning-mode all` while learning | Surfaces deprecations early |
| Appearance | New UI on; editor font = JetBrains Mono | Default modern layout |
| Editor → General → Auto Import (Kotlin) | Add unambiguous imports on the fly | Fewer manual import fixes |

## `.editorconfig` (copy to the project root)

```ini
# https://editorconfig.org
root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true

[*.{kt,kts}]
indent_style = space
indent_size = 4
max_line_length = 120
ij_kotlin_allow_trailing_comma = true
ij_kotlin_allow_trailing_comma_on_call_site = true

[*.md]
trim_trailing_whitespace = false

[*.{yml,yaml,toml,json}]
indent_style = space
indent_size = 2
```

## Compose preview habits

- Give every screen a `@Preview` with `showBackground = true` and one
  dark-mode preview (`uiMode = Configuration.UI_MODE_NIGHT_YES`).
- Preview the smallest phone size and a tablet/foldable width; overflow
  bugs hide at exactly one of those.
- Keep previews free of ViewModel / network calls — pass plain state
  in, which is also the testable shape (see `examples/02-counter-mvvm-flow/`).

## Emulator / device

- Keep one API 37 (compileSdk target) emulator image and one API 24
  image (the typical minSdk floor) for smoke checks.
- Prefer a real device for camera, sensors, billing, and game input —
  emulator behavior differs in all four.
