# Games 2D with Compose Canvas and Custom Rendering

How to build a real 2D game using only Jetpack Compose: Canvas
drawing, a frame-driven game loop, sprite handling, shaders,
sound, haptics, and gesture input. This route suits puzzles,
board games, card games, and simple arcade games.

Docs: https://developer.android.com/jetpack/compose/graphics

## When Compose Canvas Is Enough

Compose is enough when:
- Sprites on screen number in the tens or low hundreds.
- Movement is smooth but not physics-heavy.
- The game mixes normal UI (menus, dialogs) with the play field.
- You ship Android only.

Move to an engine (doc 25) when you need tile-map editors,
complex physics, particles at scale, or cross-platform export.

## Canvas and DrawScope Basics

`Canvas` gives you a `DrawScope`. Inside it you draw with
coordinates in pixels, with the origin at the top-left.

```kotlin
@Composable
fun PlayField(state: GameState) {
    Canvas(Modifier.fillMaxSize()) {
        drawRect(Color(0xFF101418), size = size)
        for (ball in state.balls) {
            drawCircle(
                color = ball.color,
                radius = ball.radius,
                center = Offset(ball.x, ball.y)
            )
        }
        drawLine(
            color = Color.White,
            start = Offset(0f, size.height / 2),
            end = Offset(size.width, size.height / 2),
            strokeWidth = 2f
        )
    }
}
```

Key `DrawScope` tools:
- `drawRect`, `drawCircle`, `drawOval`, `drawLine`, `drawPath`
- `drawImage` for bitmaps and sprites
- `withTransform { translate(...); rotate(...) }` for transforms
- `clipRect` / `clipPath` to limit drawing to a region
- `drawContext.canvas` for direct Android `Canvas` calls when
  you need a native API Compose does not wrap yet

Keep drawing code pure: read state, draw, return. Never mutate
game state inside the draw block.

## The Game Loop with withFrameNanos

Do not use a `while (true) { delay(16) }` loop. Use the frame
clock so updates sync with the display refresh.

```kotlin
@Composable
fun GameLoop(onTick: (deltaSeconds: Float) -> Unit) {
    var lastNanos by remember { mutableLongStateOf(0L) }
    LaunchedEffect(Unit) {
        while (true) {
            withFrameNanos { frameNanos ->
                if (lastNanos != 0L) {
                    val dt = (frameNanos - lastNanos) / 1_000_000_000f
                    onTick(dt.coerceAtMost(0.05f)) // clamp tab-switch spikes
                }
                lastNanos = frameNanos
            }
        }
    }
}
```

Rules for a stable loop:
- Clamp delta time so a pause does not teleport objects.
- Update physics in fixed steps if collisions matter:
  accumulate real time, step at 1/120 or 1/60, render the rest.
- Pause the loop when the screen is not visible. Tie the
  `LaunchedEffect` to a `playing` flag or the lifecycle.

## Holding Game State

Two good patterns:

1. Snapshot state for small games — a single state holder whose
   fields Compose observes.

```kotlin
class GameState {
    var playerX by mutableFloatStateOf(0f)
    var playerY by mutableFloatStateOf(0f)
    var score by mutableIntStateOf(0)
    val enemies = mutableStateListOf<Enemy>()
}
```

2. `StateFlow` for larger games — an engine class owns the
   state and the UI collects it.

```kotlin
data class Frame(val player: Offset, val score: Int, val enemies: List<Enemy>)

class GameEngine(viewModelScope: CoroutineScope) {
    private val _frame = MutableStateFlow(Frame(Offset.Zero, 0, emptyList()))
    val frame: StateFlow<Frame> = _frame.asStateFlow()
    fun step(dt: Float) { _frame.value = computeNext(_frame.value, dt) }
}
```

## Sprites and Images

Load images once, outside the draw loop.

```kotlin
val sprite = ImageBitmap.imageResource(R.drawable.ship)

Canvas(Modifier.fillMaxSize()) {
    drawImage(
        image = sprite,
        dstOffset = IntOffset(playerX.toInt(), playerY.toInt()),
        dstSize = IntSize(96, 96)
    )
}
```

Sprite sheets: draw a sub-rectangle with `srcOffset` and
`srcSize` on `drawImage`. Precompute frame rects; do not
allocate them per frame.

## Paths and Shapes with graphics-shapes


```kotlin
// Conceptual shape usage — check current graphics-shapes API
val star = RoundedPolygon(numVertices = 5, radius = 80f, centerX = 100f, centerY = 100f)
// Convert to a Path via toPath() and drawPath(...) inside Canvas.
```

## AGSL RuntimeShader (API 33+)

Android Graphics Shading Language (AGSL) lets you write small
shader programs that run on the GPU. In Compose, use
`RuntimeShader` and apply it as a brush or render effect.

```kotlin
@RequiresApi(33)
val shader = RuntimeShader(
    """
    uniform float2 iResolution;
    uniform float iTime;
    half4 main(float2 fragCoord) {
        float2 uv = fragCoord / iResolution;
        return half4(uv.x, uv.y, 0.5 + 0.5 * sin(iTime), 1.0);
    }
    """.trimIndent()
)

// Inside DrawScope or a Modifier.graphicsLayer renderEffect,
// set uniforms per frame: shader.setFloatUniform("iTime", t)
```

Uses: water, glow, distortion, transitions, animated
backgrounds. Guard with an API 33 check and provide a plain
fallback brush on older devices.

Docs: https://developer.android.com/develop/ui/views/graphics/agsl

## Sound: SoundPool and Media3

- `SoundPool` — short, low-latency effects (taps, hits, coins).
  Load a small set of sounds at start, play by sound id.
- Media3 / ExoPlayer — music and longer audio, streaming, and
  playback with a media session.

```kotlin
val soundPool = SoundPool.Builder().setMaxStreams(8).build()
val hitId = soundPool.load(context, R.raw.hit, 1)
// Later:
soundPool.play(hitId, 1f, 1f, 1, 0, 1f)
```

Release `SoundPool` when the screen closes. Respect audio
focus: pause music when another app takes focus. See doc 28.

## Haptics and Input Gestures

Haptics: use `LocalHapticFeedback` in Compose.

```kotlin
val haptics = LocalHapticFeedback.current
// On a meaningful event:
haptics.performHapticFeedback(HapticFeedbackType.LongPress)
```

Gestures: Compose gesture modifiers cover most game input.

```kotlin
Modifier
    .pointerInput(Unit) {
        detectTapGestures(onTap = { pos -> onTap(pos) })
    }
    .pointerInput(Unit) {
        detectDragGestures(
            onDrag = { change, drag -> onDrag(drag) }
        )
    }
```

- `detectTapGestures` — taps, double taps, long press.
- `detectDragGestures` — dragging pieces or panning.
- `detectTransformGestures` — pinch zoom and rotation.
- For fast action games, handle raw `PointerEvent` changes in
  a custom `pointerInput` and read all pointers for multi-touch.

## Performance Tips

- Keep allocations out of the frame loop and draw block.
- Reuse `Path`, `Paint`-equivalents, and rect objects.
- Draw only what is visible; skip off-screen sprites.
- Use `Modifier.graphicsLayer` for cheap transforms of whole
  layers instead of redrawing them.
- Test at 60 Hz and 90/120 Hz. High refresh is now common.
- Watch slow frames in Android Vitals (see doc 28).

## Official Links

- Compose graphics: https://developer.android.com/jetpack/compose/graphics
- Canvas and drawing: https://developer.android.com/jetpack/compose/graphics/draw/overview
- AGSL: https://developer.android.com/develop/ui/views/graphics/agsl
- Graphics shapes: https://developer.android.com/jetpack/androidx/releases/graphics
- Gestures: https://developer.android.com/jetpack/compose/touch-input
- SoundPool: https://developer.android.com/reference/android/media/SoundPool
- Media3: https://developer.android.com/media/media3
