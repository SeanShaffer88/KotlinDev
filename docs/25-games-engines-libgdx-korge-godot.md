# Games Engines — libGDX, KorGE, and Godot

Engine routes for Kotlin game development beyond Compose Canvas:
libGDX with the KTX Kotlin extensions, the pure-Kotlin KorGE
engine, and Godot driven from Kotlin via godot-jvm. Read doc 23
first for the decision guide.

## libGDX — Java Framework, Kotlin via KTX

libGDX: https://libgdx.com/ — a mature cross-platform framework
for 2D and 3D games, written in Java, Apache 2.0 licensed.

Important fact: **libGDX itself has no native Kotlin support.**
Kotlin support comes from a separate project, KTX.

### KTX — The Kotlin Extensions for libGDX

- Repository: https://github.com/libktx/ktx
- KTX provides idiomatic Kotlin wrappers and extensions:
  - `ktx-app` — application lifecycle helpers
  - `ktx-graphics` — rendering, cameras, shapes
  - `ktx-actors` and `ktx-scene2d` — scene2d UI in Kotlin style
  - `ktx-ashley` — Ashley entity-component system helpers
  - `ktx-box2d` — Box2D physics helpers
  - `ktx-collections`, `ktx-math`, `ktx-async`, and others

```kotlin
// KTX style application skeleton
class MyGame : KtxGame<Screen>() {
    override fun create() {
        addScreen(PlayScreen())
        setScreen<PlayScreen>()
    }
}
```

Version note: the KTX 1.13.1 release line added support for
Kotlin 2. libGDX and KTX versions must be compatible with each
other and with your Kotlin version. Always check the KTX
releases page and the libGDX version together before pinning —
do not copy a version triple from an old tutorial.

### Project Shape

A typical libGDX + KTX project:
- `core` — shared game code (Kotlin, depends on libGDX + KTX)
- `android` — Android launcher, depends on `core`
- `desktop` — desktop launcher for fast iteration (optional)
- `ios` / `html` — additional launchers if needed

Setup tool: the official libGDX setup generates this layout.
Generate in Java mode if needed, then convert modules to
Kotlin and add the KTX dependencies for your modules only.

### What libGDX Gives You

- OpenGL ES rendering, sprite batching, texture atlases
- Scene2D UI, Box2D physics (via extension), particle effects
- Asset manager, audio (OpenAL on desktop, Android APIs on mobile)
- Large tutorial and example ecosystem built over a decade+

### Limits

- No visual editor comparable to Godot or Unity.
- UI and scene layout are code-driven.
- You own the game loop, screens, and asset pipeline.

## KorGE — Pure Kotlin Multiplatform

KorGE: https://korge.org/ — https://github.com/korlibs/korge

KorGE is a game engine written in Kotlin, for Kotlin
Multiplatform. One codebase targets Android, iOS, desktop
(JVM), and web (JS/Wasm).

Highlights:
- Kotlin-first APIs: scenes, views, tweens, tile maps, sprites
- Live reloading during development
- Gradle-based build integrated with Kotlin Multiplatform
- Part of the Korlibs ecosystem (Korio, Korim, Korau, Korge)

```kotlin
// KorGE scene sketch (API shape — verify against current docs)
suspend fun main() = Korge(windowSize = SizeInt(800, 600)) {
    val scene = sceneRoot
    // Build views, add sprites, run animations here.
}
```

**Version check warning:** KorGE has shipped major changes
across releases and its versioning has moved quickly. Before
starting a project, open https://korge.org/ and the GitHub
releases page, read the current getting-started guide, and pin
exactly the version that guide uses. Do not trust a KorGE
version number or API snippet from memory or an old blog post.

Choose KorGE when staying 100% in Kotlin Multiplatform matters
more than having the largest community.

## Godot with Kotlin — godot-jvm

Godot: https://godotengine.org/ — a full open-source engine
with editor, scene tree, physics, animation, and exporters.

Kotlin support comes from godot-jvm:
- Repository: https://github.com/utopia-rise/godot-kotlin-jvm
- Published under the `utopia-rise` organisation as godot-jvm.

Facts to plan around (verify on the project page before a
release, as requirements move with Godot versions):
- The project describes its 1.0 line as production-ready.
- It targets Godot 4.x — recent work tracks Godot 4.7.2+.
- JDK 17 is the required Java level for the toolchain.
- The default Kotlin version in recent releases is in the
  Kotlin 2.3.x line (2.3.20 in the latest documented setup).
- On Android, code runs via ART (the Android runtime).
- There is **no web export** for the JVM route, and
  **no 32-bit** Android support in that route. If you need web
  export or 32-bit devices, this route does not cover them.

```kotlin
// Godot-Kotlin node sketch — class registered with the engine
@RegisterClass
class Player : CharacterBody2D() {
    @RegisterProperty
    var speed: Float = 200f

    @RegisterFunction
    override fun _physicsProcess(delta: Double) {
        // Read input, move the body with Godot physics APIs.
    }
}
```

Workflow:
1. Write Kotlin classes annotated for registration.
2. The godot-jvm Gradle plugin generates the bindings Godot needs.
3. Build and attach scenes in the Godot editor as usual.
4. Export to Android from Godot with the JVM runtime included.

Choose Godot when you want the editor and engine features and
prefer Kotlin over GDScript for gameplay logic.

## What About Cocos?

Cocos (Cocos Creator) is sometimes asked about in Kotlin
discussions. Be clear: **Cocos is a TypeScript / JavaScript
and C++ engine. It is not a Kotlin engine.** There is no
supported route to write a Cocos game in Kotlin. If a plan
requires Kotlin, choose libGDX, KorGE, or Godot instead.

## Side-by-Side Comparison

| | libGDX + KTX | KorGE | Godot + godot-jvm |
|---|---|---|---|
| Language | Kotlin via KTX ext. | Pure Kotlin | Kotlin on JVM |
| Editor | No (code only) | Light tooling | Full visual editor |
| 2D | Excellent | Excellent | Excellent |
| 3D | Capable | Limited focus | Strong |
| Physics | Box2D extension | Built-in basics | Built-in engine |
| Platforms | Android/desktop/iOS/web | Android/iOS/desktop/web | Android/desktop + Godot targets* |
| Community | Large, mature | Smaller, Kotlin-focused | Large (Godot overall) |
| Learning curve | Medium | Medium | Medium (editor + Kotlin) |

*Godot JVM route excludes web and 32-bit Android — see above.

## Choosing Between Them

- Already know libGDX or need its ecosystem? libGDX + KTX.
- Want one Kotlin Multiplatform codebase, web included? KorGE
  (after the version check) or libGDX HTML launcher.
- Want a visual editor and scene workflow? Godot + godot-jvm.
- Need web export from Godot? Use GDScript or C# in Godot —
  the JVM route does not export to web.

## Version Discipline for Engines

Engines move independently of AndroidX. For every engine:
1. Open the official releases page on the day you set up.
2. Record engine + Kotlin + JDK versions together in the repo.
3. Upgrade engine and Kotlin as a pair, in a dedicated change,
   with a device test pass after.
4. Never mix a tutorial's old Gradle snippets with a new engine.

## Official Links

- libGDX: https://libgdx.com/
- KTX: https://github.com/libktx/ktx
- libGDX wiki: https://libgdx.com/wiki/
- KorGE: https://korge.org/
- KorGE GitHub: https://github.com/korlibs/korge
- Godot: https://godotengine.org/
- Godot JVM: https://github.com/utopia-rise/godot-kotlin-jvm
- Godot Kotlin docs: https://godot-kotlin.com/

Next: doc 26 covers native graphics and AGDK for teams that
outgrow these engines or bring their own C++ engine.
