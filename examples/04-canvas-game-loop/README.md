# 04 — Canvas game loop (Compose)

A bouncing ball rendered with Compose `Canvas`, driven by a real
frame loop — the smallest honest game structure in pure Compose.

## What it teaches

- `withFrameNanos` inside `LaunchedEffect`: the loop runs once per
  display frame and hands you the frame timestamp.
- **Delta time**: movement is `speed × dt`, never a fixed step per
  frame, so the ball moves at the same real-world speed on 60 Hz,
  90 Hz, and 120 Hz screens.
- Game state in `remember` + `mutableFloatStateOf`: position lives
  outside the `Canvas` draw block; the draw block only reads it.
- **Pause on lifecycle stop**: a `LifecycleEventObserver` sets
  `running = false` on `ON_STOP`, so the loop idles when the app is
  backgrounded instead of burning battery; tap to pause/resume by hand.

## When Compose Canvas is (and is not) the right tool

Right for: 2D casual games, puzzles, board games, prototypes, and any
game whose draw calls fit comfortably in one `Canvas`. For demanding
2D use libGDX or KorGE; for 3D use Godot, Unity, or the native AGDK
route — see the games docs in `docs/`. This example deliberately uses
no game engine so the loop mechanics stay visible.

## Files

- `GameScreen.kt` — loop, physics step, and rendering in one file.

> **Disclaimer:** this is a teaching excerpt, not a full Gradle
> project. The full skeleton is `templates/compose-app/` — see the
> note in [`../README.md`](../README.md).
