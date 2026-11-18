# Examples

Small, focused teaching examples. Each folder isolates one pattern so
it can be read in a few minutes and copied into a real project.

> **Disclaimer (applies to every example):** each example is a teaching
> excerpt, not a full Gradle project — files are trimmed to the pattern
> being taught and will not compile standalone without a host project.
> The full, buildable skeleton is [`../templates/compose-app/`](../templates/compose-app/);
> drop the example's files into a copy of that template (matching the
> package name) to run them. Versions follow
> [`../tools/versions.json`](../tools/versions.json) (verified
> November 2026).

| Example | Pattern |
|---|---|
| [`01-hello-compose/`](01-hello-compose/) | Smallest Compose screen: `ComponentActivity`, `setContent`, Material 3, a `@Preview`. Start here. |
| [`02-counter-mvvm-flow/`](02-counter-mvvm-flow/) | MVVM + unidirectional data flow: `StateFlow` in the ViewModel, stateless composable, events flow up. |
| [`03-room-notes/`](03-room-notes/) | Local persistence: Room 2.x entity / DAO / repository with a `Flow` query. Includes the Room 3 package-change note. |
| [`04-canvas-game-loop/`](04-canvas-game-loop/) | Game basics in pure Compose: `Canvas`, a `withFrameNanos` frame loop, delta-time movement, pause on lifecycle stop. |
