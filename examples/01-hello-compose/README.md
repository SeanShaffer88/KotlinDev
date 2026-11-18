# 01 — Hello Compose

The smallest useful Compose app: one activity, one screen, Material 3.

## What it teaches

- `ComponentActivity.setContent { }` as the entry point (no XML layouts).
- Edge-to-edge with `enableEdgeToEdge()` and `Scaffold` insets.
- A stateless composable (`GreetingScreen`) separated from the activity,
  so it can be previewed and tested on its own.
- A `@Preview` for design-time rendering in Android Studio.

## Files

- `MainActivity.kt` — activity + theme wrapper + screen + preview.

## Try it

Copy `MainActivity.kt` over the template's `MainActivity.kt`
(`templates/compose-app/app/src/main/java/com/example/app/`) and run
the app. Change the greeting text and watch the preview update without
reinstalling.

> **Disclaimer:** this is a teaching excerpt, not a full Gradle
> project. The full skeleton is `templates/compose-app/` — see the
> note in [`../README.md`](../README.md).
