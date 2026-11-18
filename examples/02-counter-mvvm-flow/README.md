# 02 — Counter with MVVM + StateFlow (unidirectional data flow)

A counter that demonstrates the default Android architecture shape:
state flows **down** from the ViewModel, events flow **up** from the UI.

## What it teaches

- `StateFlow<UiState>` as the single source of truth in the ViewModel.
- `collectAsStateWithLifecycle()` — collection pauses when the UI is
  not in the foreground, so no work is wasted in the background.
- A stateless screen composable (`CounterScreen(count, onIncrement, …)`)
  that is trivial to preview and unit-test.
- A stateful wrapper (`CounterRoute`) that owns the ViewModel wiring —
  the standard route/screen split used in production apps.

## Files

- `CounterViewModel.kt` — UI state data class + ViewModel.
- `CounterScreen.kt` — route (stateful) + screen (stateless) + preview.

## Dependencies (already in the template catalog)

`androidx.lifecycle:lifecycle-viewmodel-compose`,
`androidx.lifecycle:lifecycle-runtime-ktx`, Compose BOM / Material 3.

> **Disclaimer:** this is a teaching excerpt, not a full Gradle
> project. The full skeleton is `templates/compose-app/` — see the
> note in [`../README.md`](../README.md).
