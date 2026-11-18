# Games Performance, Input, Audio, and Saves

The cross-cutting runtime concerns every Android game shares:
staying smooth, respecting thermals, handling controllers and
touch well, playing audio correctly, and never losing a save.

## Performance Targets and Android Vitals

Google Play measures game quality through Android Vitals.
The headline game metric is **slow sessions**:

- A session is "slow" when too many of its frames miss the
  target frame time. The slow-session threshold to watch is
  **more than 25% slow frames** in a session — crossing quality
  thresholds hurts discoverability on Play.
- Watch vitals per device group. A game that is smooth on a
  flagship and slow on a mid-range phone will show it there.

Set a frame budget and defend it:
- 60 FPS = 16.6 ms per frame total (CPU + GPU).
- 120 FPS = 8.3 ms. Only promise it if you can hold it.

## ADPF — Adaptive Performance APIs

The Android Dynamic Performance Framework (ADPF) is the set of
APIs for adapting to device conditions in real time.

### Thermal API

Read thermal status and react before throttling hits.

```kotlin
val powerManager = getSystemService(PowerManager::class.java)
powerManager.addThermalStatusListener(executor) { status ->
    when (status) {
        PowerManager.THERMAL_STATUS_SEVERE,
        PowerManager.THERMAL_STATUS_CRITICAL -> reduceQuality()
        else -> { /* hold current quality */ }
    }
}
```

Quality reductions that work: lower render resolution, fewer
particles, reduced draw distance, lower physics rate. Reduce
gradually and do not oscillate.

`getThermalHeadroom` (with a forecast window) lets you plan
ahead instead of only reacting. Guard by API level.

### Performance Hint API

`PerformanceHintManager` lets rendering and loading threads
tell the system how long work should take, so CPU frequencies
are scheduled efficiently instead of guessing.

- Create a session for your render thread group.
- Report the target duration per frame, then the actual
  duration after each frame.
- Most valuable on a native render loop; managed games benefit
  mainly through engine or ADPF integrations.

### Game Mode API

Players and OEMs can set a Game Mode (performance, battery
saver, or standard). Your game can:
- Read the current mode and adjust defaults.
- Offer Game Mode interventions you support (for example a
  resolution scaling intervention) via the Game Dashboard.

### Game State API

Tell the system what the game is doing — loading, gameplay,
cutscene, idle — with `GameState`. The system uses it for
power and performance decisions. Set it at real transitions,
not per frame.

Docs: https://developer.android.com/games/playgames/game-mode
and the ADPF guide at https://developer.android.com/games/adpf

## Frame Rate API and Refresh Rates

Displays run at 60, 90, 120 Hz and beyond, and can switch.
Two tools:

1. Preferred display mode / refresh rate hints for the window.
2. The Frame Rate API — `Surface.setFrameRate` (API 30+) and
   its AndroidX and View/Compose equivalents — tells the system
   the frame rate your content actually wants.

```kotlin
// View surface example (API 30+)
surfaceView.holder.surface.setFrameRate(
    60f,
    Surface.FRAME_RATE_COMPATIBILITY_DEFAULT
)
```

Rules:
- Request the rate you can actually sustain. Asking for 120
  while rendering at 40 wastes power and looks worse.
- Menus and static screens should request a low rate or none.
- Re-evaluate when quality level changes (see Thermal above).

## Input — Touch

- Minimise touch-to-photon latency: keep the input → update →
  render path short, avoid extra queued frames, prefer Frame
  Pacing (doc 26) in native games.
- Handle multi-touch correctly: track pointer IDs, not just
  "the touch position", so two-thumb controls work.
- Respect display cutouts and gesture insets; never place a
  critical control under the system gesture area.
- Test with real fingers on real hardware — emulator mouse
  input hides latency and multi-touch bugs.

## Input — Controllers and Gamepads

Many players use Bluetooth or USB controllers, and Play Games
on PC players use keyboard and mouse (doc 27).

- Read gamepad state via `InputDevice` and motion events;
  handle `KEYCODE_BUTTON_*` key events for buttons.
- Support hot-plug: controllers connect and disconnect mid-game.
- Show the right prompts: controller glyphs when a controller
  is active, touch hints when it is not, key names on PC.
- Never require a controller, and never require touch, unless
  the genre truly demands it — and say so on the store listing.
- The AGDK Game Controller library can normalise behaviour
  across devices for native games.

## Audio

### Focus and Routing

- Request audio focus for music/gameplay audio; duck or pause
  when you lose it (calls, alarms, other media apps).
- Use `STREAM_MUSIC` semantics via `AudioAttributes` with
  `USAGE_GAME` so the system routes and ducks correctly.

```kotlin
val attrs = AudioAttributes.Builder()
    .setUsage(AudioAttributes.USAGE_GAME)
    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
    .build()
```

### Latency and Choice of Player

- Short effects: `SoundPool` (low latency, small samples).
- Music and long tracks: Media3 / ExoPlayer with a proper
  playback service if music continues outside the screen.
- Native low-latency audio: Oboe (C++) for rhythm games or
  instruments where every millisecond counts.
- Keep sample rates consistent (48 kHz is the safe default) to
  avoid resampling cost and artefacts.

### Volume and Safety

- Respect the device media volume; never force maximum volume.
- Provide separate music / effects / voice sliders in settings.
- Fade music on pause instead of cutting it abruptly.

## Saves — Local Design

A save system must survive crashes, updates, and low storage.

Local rules:
- Save to app-private storage (`filesDir`), never shared storage.
- Write atomically: write to a temp file, flush, then rename
  over the real save. A crash mid-write must not corrupt it.
- Version your save format (`saveVersion` field) and migrate
  upward on load. Never silently discard an unreadable save —
  keep a backup copy and tell the player.
- Keep at least one rotating backup of the previous good save.
- Save at natural points: level end, checkpoint, app pause.
  Autosave quietly; show a subtle indicator, not a modal dialog.

```kotlin
@Serializable
data class SaveGame(
    val saveVersion: Int = 3,
    val level: Int,
    val score: Int,
    val inventory: List<String>,
    val playedSeconds: Long
)

suspend fun writeSave(file: File, save: SaveGame) {
    val tmp = File(file.parent, file.name + ".tmp")
    tmp.writeText(json.encodeToString(save))
    tmp.renameTo(file) // atomic on the same filesystem
}
```

## Saves — Cloud with Snapshots

Layer Play Games Snapshots (doc 27) on top of local saves:
- Local save is the source of truth during play.
- Upload to a Snapshot when online and authenticated, at the
  same natural save points (throttled — not every frame/event).
- On start, if a cloud save exists and differs, resolve the
  conflict by policy: longest played time usually wins for
  progression games; ask the player when both saves have real
  progress on different branches.
- Offline play must work fully. Cloud sync is a bonus, never a
  requirement to play.

## Offline Play Design

- All core gameplay works with no network.
- Queue outbound events (score submits, achievement progress,
  analytics you control) and flush when connectivity returns.
- Cache remote config and content with a last-known-good copy.
- Show offline state honestly in UI ("will sync when online"),
  never with a blocking error dialog.

## Pre-Launch Performance Checklist

- Profile on a low-end and a mid-range device, not only flagships.
- Hold target FPS for a 15-minute session (thermal soak test).
- Slow-session risk reviewed in a pre-release report / vitals.
- Controller, touch, and (if relevant) keyboard all tested.
- Audio focus loss (incoming call simulation) tested.
- Save → kill app mid-write → relaunch: save still loads.
- Airplane-mode full playthrough: nothing blocks.

## Official Links

- ADPF: https://developer.android.com/games/adpf
- Thermal API: https://developer.android.com/games/adpf/thermal
- Game Mode: https://developer.android.com/games/gamemode
- Frame Rate API: https://developer.android.com/games/graphics/frame-rate
- Android Vitals: https://developer.android.com/games/sdk/performance-tuner (quality thresholds linked from Play Console help)
- Game controllers: https://developer.android.com/games/playgames/controllers
- Audio focus: https://developer.android.com/media/optimize/audio-focus
- Oboe: https://developer.android.com/games/sdk/oboe
- Saved games: https://developer.android.com/games/playgames/services/common/concepts/saved-games
