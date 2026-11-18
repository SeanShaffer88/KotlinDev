# Games Overview — Choosing a Route

How to pick the right way to build an Android game in Kotlin.
There is no single best answer. The right choice depends on the
genre, how much custom rendering you need, your team size, and
whether the game must also ship on other platforms.

## TL;DR Decision Table

| Route | Best for | Language | Platforms |
|---|---|---|---|
| Compose Canvas | Simple 2D, puzzles, board games, casual | Kotlin only | Android only |
| libGDX + KTX | 2D and light 3D, cross-platform indie | Kotlin + KTX extensions | Android, desktop, iOS, web |
| KorGE | Pure Kotlin 2D, multiplatform from day one | Kotlin Multiplatform | Android, iOS, desktop, web |
| Godot via godot-jvm | Full engine, editor, 2D + 3D | Kotlin on JVM inside Godot | Android, desktop, consoles via Godot |
| Unity / Unreal | Large 3D, AAA-style, store assets | C# / C++ — Kotlin is glue only | All major platforms |
| Native C++ + AGDK | Maximum performance, custom engine | C/C++ core, Kotlin shell | Android focused |

If you are unsure, start with Compose Canvas for a prototype.
You can measure interest before committing to an engine.

## Route 1: Compose Canvas

Jetpack Compose can draw a game. `Canvas`, `DrawScope`, and
custom layouts give you full 2D drawing with normal Kotlin code.

Strengths:
- No engine to learn. If you know Compose, you know the basics.
- Normal Android lifecycle, navigation, and UI around the game.
- Easy to mix game screens with menus, settings, and stores.
- One codebase, one build system (Gradle).

Limits:
- No built-in physics, tile maps, particle system, or scene editor.
- Performance is fine for hundreds of sprites, not thousands.
- No cross-platform export.

Best genres: puzzles, word games, card games, board games,
turn-based strategy, simple arcade games, educational games.

See `24-games-2d-with-compose-canvas-and-custom-rendering.md`.

## Route 2: libGDX with KTX

libGDX is a mature, open-source, cross-platform game framework.
It is written in Java and has **no native Kotlin support built in**.
Kotlin support comes from KTX — a set of Kotlin extension libraries.

- Repository: https://github.com/libktx/ktx
- libGDX site: https://libgdx.com/
- KTX modules include `ktx-app`, `ktx-graphics`, `ktx-actors`,
  `ktx-scene2d`, `ktx-ashley` (entity-component), and more.

Strengths:
- Very mature, large community, many tutorials and examples.
- True cross-platform: one core module, thin platform launchers.
- Good 2D performance, capable 3D, Box2D physics via extensions.
- Free and open source (Apache 2.0).

Limits:
- You write more boilerplate than in a full editor engine.
- No visual scene editor comparable to Godot or Unity.
- Kotlin version support depends on the KTX release line.
  The KTX 1.13.1 line added support for Kotlin 2 — verify the
  current KTX and libGDX versions together before pinning.

Best genres: platformers, roguelikes, shooters, simulation,
any 2D game that must also run on desktop or iOS.

See `25-games-engines-libgdx-korge-godot.md`.

## Route 3: KorGE

KorGE is a pure Kotlin, multiplatform game engine.

- Site: https://korge.org/
- Repository: https://github.com/korlibs/korge

Strengths:
- Written in Kotlin, designed for Kotlin Multiplatform.
- Live reloading, integrated editor tooling, 2D focus.
- Targets Android, iOS, desktop, and web from shared code.

Limits:
- Smaller community than libGDX or Godot.
- API and versions have changed across major releases —
  always check the current version and migration notes on the
  official site before starting. Do not pin a KorGE version
  from memory.

Best genres: 2D multiplatform games where the team wants to
stay entirely in Kotlin and avoid Java or C#.

## Route 4: Godot via godot-jvm

Godot is a full open-source engine with a visual editor, scene
system, physics, animation, and export for many platforms.
The godot-jvm project lets you write game logic in Kotlin
(and Java) running on the JVM inside Godot.

- Godot: https://godotengine.org/
- godot-jvm: https://github.com/utopia-rise/godot-kotlin-jvm
  (published as utopia-rise / godot-jvm)

Strengths:
- Full editor, visual scene building, strong 2D and 3D.
- Kotlin for gameplay code instead of GDScript or C#.
- Godot handles rendering, physics, audio, and input.

Limits:
- Android export runs via ART; there are platform constraints
  covered in doc 25 (no web export, no 32-bit in that route).
- Larger runtime and build complexity than Compose Canvas.
- You must match Godot, godot-jvm, JDK, and Kotlin versions.

Best genres: 2D and 3D games that need an editor, complex
scenes, animation tooling, or a small team moving fast visually.

## Route 5: Unity or Unreal with Kotlin as a Plugin Layer

Be clear about this route: **you do not write a Unity or Unreal
game in Kotlin.** Unity uses C#. Unreal uses C++ and Blueprints.

Kotlin's role here is only on the Android side:

- A Kotlin Android library (AAR) wrapped as a Unity plugin.
- Android-specific features Unity does not expose cleanly:
  Play Games, billing edge cases, notifications, widgets.
- JNI bridges between the engine and Android APIs.

Choose Unity/Unreal when:
- The game is large 3D and needs their asset stores or tooling.
- The team already knows C# or C++.
- Console or high-end 3D is a requirement.

Do not choose this route to "use Kotlin for games" — the game
itself will not be Kotlin.

## Route 6: Native C++ with AGDK

The Android Game Development Kit (AGDK) is Google's set of
libraries for high-performance native games.

- Docs: https://developer.android.com/games/agdk

The game core is C or C++. Kotlin's role is the shell:

- Activity and lifecycle glue with GameActivity.
- Jetpack features, Play Games, billing, and UI overlays.
- Downloadable content, settings, and account screens.

Choose this when you have an existing C++ engine, need the
lowest latency, or need fine control over rendering and threads.

See `26-games-native-graphics-opengl-vulkan-agdk.md`.

## Genre / Complexity / Team Matrix

| Genre | Solo, simple | Small team | Larger / 3D heavy |
|---|---|---|---|
| Puzzle / board / cards | Compose Canvas | Compose Canvas | Compose or Godot |
| 2D platformer | KorGE / libGDX | libGDX + KTX | Godot |
| 2D shooter / roguelike | libGDX + KTX | libGDX + KTX | Godot / native |
| Simulation / strategy | Compose / libGDX | libGDX / Godot | Godot / Unity |
| 3D adventure | Godot | Godot | Unity / Unreal |
| Racing / FPS | Godot (light) | Unity | Unreal / native |
| Hyper-casual | Compose / KorGE | libGDX / Unity | Unity |
| Educational / kids | Compose Canvas | Compose / Godot | Godot |

## Questions to Answer Before You Commit

1. Android only, or must it ship elsewhere?
2. 2D or 3D? How many objects on screen at once?
3. Do you need a visual editor, or is code-only fine?
4. Does the team know Kotlin only, or also C# / C++?
5. Do you need physics, tile maps, particles, skeletal animation?
6. How important is small APK/AAB size?
7. Will you use Play Games, leaderboards, and cloud saves?
8. What is the update plan — content in code, or downloadable?

## Common Mistakes

- Picking a heavy engine for a puzzle game that Compose handles.
- Picking Compose Canvas for a fast action game with thousands
  of sprites and particles.
- Assuming libGDX "supports Kotlin" without adding KTX.
- Assuming Unity games can be written in Kotlin. They cannot.
- Ignoring Play Games on PC requirements until launch week.
  See doc 27 early if PC reach matters.

## Official Links

- Android Games overview: https://developer.android.com/games
- AGDK: https://developer.android.com/games/agdk
- Compose graphics: https://developer.android.com/jetpack/compose/graphics
- libGDX: https://libgdx.com/
- KTX: https://github.com/libktx/ktx
- KorGE: https://korge.org/
- Godot: https://godotengine.org/
- Godot JVM: https://github.com/utopia-rise/godot-kotlin-jvm

Next: doc 24 for building 2D games with Compose Canvas, or
doc 25 for engine setup details.
