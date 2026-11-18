# Games Native Graphics — OpenGL, Vulkan, and AGDK

Native graphics on Android for game teams with a C/C++ engine
or maximum-performance needs. Kotlin does not draw the game in
this route — it provides the Android shell and Jetpack glue
around a native core.

Docs hub: https://developer.android.com/games/agdk

## Vulkan Is the Primary Graphics API

Google's current guidance for new native games:

- **Vulkan is the primary low-level graphics API on Android.**
  Prefer Vulkan for new native rendering work.
- **OpenGL ES is supported but not actively developed.** Existing
  OpenGL ES engines keep working; new features land in Vulkan.
- Vulkan 1.1 is available on 64-bit devices running Android 10
  and above. Check device capabilities at runtime — do not
  assume a Vulkan version from the OS version alone.
- **ANGLE in Android 15:** Android 15 routes OpenGL ES through
  ANGLE (a translation layer over Vulkan) on many devices.
  This keeps OpenGL ES apps working while the platform moves
  to Vulkan underneath. Test OpenGL ES games on Android 15+
  devices because behaviour now flows through that layer.

Practical rule: new engine work targets Vulkan; maintenance
work on an existing OpenGL ES engine continues, with testing
on current Android versions.

## The Android Game Development Kit (AGDK)

AGDK is Google's collection of libraries and tools for native
games. The parts that matter most:

### GameActivity — Use It Instead of NativeActivity

GameActivity is the AGDK replacement for the old
`NativeActivity`. It is a Jetpack-style component you extend,
with better input handling, lifecycle behaviour, and
integration with modern Android features.

- Artifact family: `androidx.games:games-activity`
- Recent stable line: games-activity 4.4.2 — verify the current
  version on the AndroidX games release page before pinning.
- Docs: https://developer.android.com/games/agdk/game-activity

```cpp
// Native entry point shape with GameActivity (C++)
#include <game-activity/native_app_glue/android_native_app_glue.h>

void android_main(android_app* app) {
    // Create your engine, run the render loop,
    // handle APP_CMD_INIT_WINDOW / APP_CMD_TERM_WINDOW.
}
```

```kotlin
// Kotlin/Java side: declare the activity in the manifest and
// load the native library.
class MainActivity : GameActivity() {
    companion object {
        init { System.loadLibrary("game") }
    }
}
```

GameActivity handles text input, game controller input, and
surface lifecycle in ways NativeActivity did not. New native
games should start here, not with NativeActivity.

### Frame Pacing — Swappy

The Frame Pacing library (Swappy) helps a native game render
at a smooth, consistent rate matched to the display, reducing
jitter and input latency.

- Artifact: `androidx.games:games-frame-pacing`
- Recent stable line: games-frame-pacing 2.1.3 — verify before pinning.
- Integrate Swappy's swap call in place of a raw `eglSwapBuffers`
  or Vulkan queue present, and report the display refresh period.

### Performance Tuner

Android Performance Tuner (part of Play Games tooling with
AGDK) records frame time and fidelity data from real players
and surfaces it in Play Console, so you can see which devices
struggle at which quality settings.

Use it to:
- Define fidelity levels (low / medium / high / ultra).
- Annotate scenes (menu, gameplay, loading) for breakdowns.
- Find device groups that need a lower default quality.

### Other AGDK Pieces

- **Game Text Input** — on-screen keyboard input for native games.
- **Game Controller library** — consistent gamepad handling.
- **Memory advice / performance tooling** — watch memory pressure
  before the system kills the game.
- **Android Game Development Extension (AGDE)** — Visual Studio
  tooling for building and debugging Android native games.

## Kotlin's Role in a Native Game

Kotlin is the shell, not the renderer:

| Responsibility | Where it lives |
|---|---|
| Rendering, physics, game logic | C/C++ core |
| Activity, lifecycle, surface | GameActivity + thin Kotlin class |
| Play Games sign-in, achievements | Kotlin (PGS v2 SDK is Kotlin/Java) |
| Billing (Play Billing Library) | Kotlin |
| Menus, settings, account UI | Kotlin + Compose |
| Notifications, widgets, deep links | Kotlin |
| Crash reporting glue | Kotlin + native crash handling |

Communication between layers:
- JNI for direct calls (keep the boundary narrow and coarse).
- A shared save/config format both sides can read.
- Engine events posted to the Kotlin side for UI updates.

Keep JNI calls infrequent and batched. Per-frame JNI chatter
for every sprite will cost more than it saves.

## Rendering Loop Rules (Native)

- Render on a dedicated thread; never block the UI thread.
- Handle window creation and destruction — the surface can
  disappear (backgrounding, rotation, foldables) at any time.
- Query the actual refresh rate and adapt pacing; 90/120 Hz
  displays are common (see Frame Rate API in doc 28).
- Recreate GPU resources after context/device loss.
- Cap work when the device reports thermal pressure (doc 28).

## When to Go Native — and When Not To

Go native when:
- You already have a C/C++ engine or codebase.
- You need every millisecond of latency or thread control.
- You are porting a desktop/console engine to Android.

Stay managed (Compose, libGDX, KorGE, Godot) when:
- The team is Kotlin-only.
- The game is 2D or moderate 3D.
- Development speed matters more than peak performance.

Native code multiplies build, debug, and crash-analysis cost.
Pay it only when the game truly needs it.

## Build and Packaging Notes

- Build native code with the NDK and CMake via the Android
  Gradle Plugin's `externalNativeBuild` block.
- Ship only the ABIs you support. 64-bit (`arm64-v8a`, and
  `x86_64` for ChromeOS / Play Games on PC) is the baseline;
  Play requires 64-bit for new submissions.
- Use AAB delivery: Play splits native libraries per ABI,
  keeping each user's download small.
- Symbolicate native crashes: keep unstripped symbols per
  release and upload them to Play Console / your crash tool.

## Official Links

- AGDK overview: https://developer.android.com/games/agdk
- GameActivity: https://developer.android.com/games/agdk/game-activity
- Frame Pacing: https://developer.android.com/games/sdk/frame-pacing
- Performance Tuner: https://developer.android.com/games/sdk/performance-tuner
- Vulkan on Android: https://developer.android.com/games/graphics/vulkan
- OpenGL ES on Android: https://developer.android.com/games/graphics/opengl
- NDK: https://developer.android.com/ndk
- AndroidX games releases: https://developer.android.com/jetpack/androidx/releases/games

Next: doc 27 covers Play Games services, and doc 28 covers
performance, input, audio, and saves in depth.
