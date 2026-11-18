# Reference — Game Route Comparison

The route matrix from [`../docs/23-games-overview-choosing-a-route.md`](../docs/23-games-overview-choosing-a-route.md)
in table form. Every route ships as an AAB, targets API 36, uses
Billing 8+ and PGS v2 — the routes differ in rendering, language
surface, and effort, not in Play obligations.

| | Compose Canvas 2D | libGDX (+ KTX) | KorGE | Godot (+ godot-kotlin/jvm) | Native (AGDK / NDK) |
|---|---|---|---|---|---|
| **Language surface** | Pure Kotlin + Compose | Kotlin over Java framework (KTX idioms) | Pure Kotlin, multiplatform | GDScript / C# / Kotlin-JVM via plugin | C/C++ (+ Kotlin shell) |
| **Rendering** | Compose `Canvas` / draw scope | OpenGL ES via libGDX | OpenGL (Korge's AG layer) | Godot renderer (Vulkan/GLES) | OpenGL ES / Vulkan, hand-rolled or engine |
| **Best for** | Puzzle, board, card, word, light arcade; games that are mostly UI | 2D and mid 3D, cross-platform desktop+mobile | 2D multiplatform (Android/iOS/desktop/web) | Full games with editor-driven scenes, 2D and 3D | Performance-critical 3D, existing C++ engines |
| **Editor / tooling** | Android Studio only | Tiled + libGDX setup tools; no scene editor | KorGE editor tooling (lighter) | Full Godot editor | Android Studio + AGDE (Visual Studio) |
| **Team fit** | Android devs, no engine experience | JVM devs wanting one codebase | Kotlin devs wanting KMP reach | Designers + devs, scene-based workflow | Engine/native programmers |
| **Performance ceiling** | Modest — fine at puzzle/arcade loads; watch recomposition and allocations | High for its class | Moderate–high 2D | High | Highest — you own the frame |
| **App size / startup** | Smallest; normal app startup | Moderate | Moderate | Larger runtime | Varies; native libs must be 16 KB-aligned |
| **Play Games services** | PGS v2 from Kotlin directly | PGS v2 via Android backend glue | PGS v2 via Android target glue | PGS v2 via Android plugin/extension | PGS via Java/Kotlin shell or C API glue |
| **Google Play Games on PC** | Works if input/resizability rules met | Supported route — test keyboard/mouse + window sizes | Test carefully — **Unverified** per-title | Supported via Godot Android export — test per title | Supported — test per title |
| **Biggest risks** | Outgrowing Canvas (particles, many sprites) late | Java-era APIs leaking through KTX gaps; asset pipeline discipline | Smaller community; version churn — pin after Maven check | Kotlin plugin's Godot-version window; export preset upkeep | Build complexity, 16 KB alignment, crash symbolication |
| **Docs in this repo** | [`24`](../docs/24-games-2d-with-compose-canvas-and-custom-rendering.md) | [`25`](../docs/25-games-engines-libgdx-korge-godot.md) | [`25`](../docs/25-games-engines-libgdx-korge-godot.md) | [`25`](../docs/25-games-engines-libgdx-korge-godot.md) | [`26`](../docs/26-games-native-graphics-opengl-vulkan-agdk.md) |

## Choosing in one pass

1. Is the game mostly screens, boards, and UI? → **Compose Canvas**.
2. Is it a sprite-heavy 2D or modest 3D game in Kotlin? → **libGDX + KTX**
   (or **KorGE** if multiplatform reach matters more than community size).
3. Does the project need a visual scene editor / an existing Godot
   team? → **Godot**.
4. Is peak native performance or an existing C++ codebase the point?
   → **Native AGDK**.
5. Hybrid is legitimate: Compose menus/HUD over an engine/native
   surface is a common production shape — budget the interop work.

Cross-cutting game topics for every route:
[`../docs/27-games-services-play-games-and-play-games-on-pc.md`](../docs/27-games-services-play-games-and-play-games-on-pc.md) (PGS v2, Play Games on PC),
[`../docs/28-games-performance-input-audio-and-saves.md`](../docs/28-games-performance-input-audio-and-saves.md),
[`../checklists/game-release-checklist.md`](../checklists/game-release-checklist.md).
