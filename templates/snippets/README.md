# VS Code Snippets — Compose / Kotlin Android

`compose.code-snippets` is a VS Code snippet file for the shapes
Android Kotlin code repeats all day. Snippets insert skeletons with
tab stops (`$1`, `$2`, …) — type the prefix, press Tab, fill in the
blanks.

## Install

- **Per project:** copy the file to `.vscode/compose.code-snippets`
  in your repo (VS Code picks up project snippet files with the
  `.code-snippets` extension automatically), or
- **Globally:** in VS Code, *Preferences: Configure User Snippets →
  New Global Snippets file*, and paste the contents.

Note for Android Studio users: the same shapes exist there as Live
Templates; these files are the VS Code form. The snippets are
teaching skeletons — imports are not included, so let the IDE's
auto-import resolve them, and check names against your project.

## What's included

| Prefix | Expands to |
|---|---|
| `comp-screen` | Compose screen pair: stateful Route collecting a `StateFlow` with `collectAsStateWithLifecycle`, stateless Screen, and a `@Preview` |
| `comp-viewmodel` | ViewModel with `StateFlow` UiState, sealed Event interface, and a `runCatching` refresh — the UDF pattern from `docs/08` |
| `stateflow` | The two-line `MutableStateFlow` + public `StateFlow` declaration |
| `room-dao` | Room `@Dao` with a `Flow` list query, suspend get-by-id, `@Upsert`, `@Delete` (Room 2 package in imports; Room 3 is `androidx.room3` — see `docs/11`) |
| `retrofit-service` | Retrofit interface with suspend endpoints plus a `@Serializable` DTO |
| `game-loop` | Compose Canvas game loop: `withFrameNanos`, clamped `dt`, bouncing-ball draw — the pattern from `docs/24` and `examples/04-canvas-game-loop` |

The file is plain JSON (VS Code snippet format); every snippet
declares `"scope": "kotlin"` so it only triggers in Kotlin files.
