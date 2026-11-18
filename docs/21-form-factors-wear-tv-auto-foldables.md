# Form Factors: Large Screens, Foldables, Wear, TV, Auto, and XR
Android runs on far more than phones: tablets, foldables, Chromebooks, watches, TVs, cars, and headsets. This guide covers how to build one app that adapts well to each shape, what changes with target API 36 for large screens, and which parts need a dedicated experience instead of a scaled-up phone screen. Start with adaptive layouts on phones and tablets. Add a form factor only when your users are actually there — each one adds design, testing, and review work.
## Large screens and the API 36 change
Large-screen devices have a smallest width of **600 dp or more** (`sw600dp`): tablets, foldable inner displays, Chromebooks, and phones in desktop windowing.
**What changed with target API 36:** On large screens, apps targeting Android 16 (API 36) can no longer opt out of resizing and orientation flexibility in the old way. Restrictions such as locked orientation (`android:screenOrientation`), fixed aspect ratio, and `android:resizeableActivity="false"` are **ignored** on `sw >= 600dp` displays. Your app will be resizable and may be shown in portrait or landscape regardless of those manifest values.
In practice this means:
- Do not design a tablet layout that only works in one orientation.
- Handle configuration changes and activity recreation correctly — save state; do not assume the activity lives forever.
- Test in split-screen, freeform windows, and both orientations.
- Letterboxing (black bars around a fixed-size app) is not a design strategy anymore on large screens.
See: https://developer.android.com/guide/practices/device-compatibility-mode-changes and https://developer.android.com/develop/ui/compose/layouts/adaptive
Small phones keep the old behavior — the change is scoped to large screens only.
## Adaptive layouts with WindowSizeClass
Build one layout that adapts, not separate phone and tablet apps. Jetpack Compose Material 3 adaptive APIs classify the window by width (and height) instead of by device model:
- **Compact** — most phones in portrait (width < 600 dp)
- **Medium** — foldables, small tablets, phones in landscape (600–839 dp)
- **Expanded** — tablets, desktops (840 dp and up)
```kotlin
@Composable
fun HomeScreen(windowSizeClass: WindowSizeClass) {
    when (windowSizeClass.widthSizeClass) {
        WindowWidthSizeClass.Compact -> {
            ItemList(onItemClick = { /* navigate to detail */ })
        }
        WindowWidthSizeClass.Medium, WindowWidthSizeClass.Expanded -> {
            Row {
                ItemList(modifier = Modifier.weight(1f), onItemClick = {})
                ItemDetail(modifier = Modifier.weight(2f))
            }
        }
    }
}
```
Get the class at the activity level:
```kotlin
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            val windowSizeClass = calculateWindowSizeClass(this)
            AppTheme { HomeScreen(windowSizeClass) }
        }
    }
}
```
Prefer the Material 3 adaptive scaffolds for common patterns:
- `ListDetailPaneScaffold` — list + detail (email, settings)
- `SupportingPaneScaffold` — main content + side panel
- `NavigationSuiteScaffold` — switches between bottom bar, navigation rail, and drawer by window size
Docs: https://developer.android.com/develop/ui/compose/layouts/adaptive and https://developer.android.com/jetpack/androidx/releases/compose-material3-adaptive
Layout rules that help everywhere:
- Cap text line length on wide screens; full-width paragraphs are hard to read.
- Use panes, rails, and side sheets instead of stretching cards.
- Keep touch targets at least 48 dp, with extra spacing on TV and in cars (see below).
## Foldables: postures and hinges
Foldables add states a normal phone does not have:
| Posture | Shape | Good use |
| --- | --- | --- |
| Flat | Fully open, one large screen | Two-pane layouts |
| Half-opened (tabletop) | Horizontal fold, like a laptop | Video on top, controls below |
| Half-opened (book) | Vertical fold | Reading, dual-page views |
| Closed | Cover screen only | Compact phone layout |
Use Jetpack WindowManager to observe the fold:
```kotlin
lifecycleScope.launch {
    WindowInfoTracker.getOrCreate(this@MainActivity)
        .windowLayoutInfo(this@MainActivity)
        .collect { layoutInfo ->
            val foldingFeature = layoutInfo.displayFeatures
                .filterIsInstance<FoldingFeature>().firstOrNull()
            // Use foldingFeature?.state, .orientation,
            // .occlusionType, and .bounds for the hinge
        }
}
```
Key points:
- Never place a button or key text under the hinge. Use the hinge bounds to split content into two areas.
- Tabletop posture is ideal for hands-free video, video calls, and timers — content on the top half, controls on the bottom.
- Test on a foldable emulator with posture overrides; hinge and posture bugs do not appear on a flat phone emulator.
See: https://developer.android.com/develop/ui/compose/layouts/foldables and https://developer.android.com/guide/topics/large-screens/learn-about-foldables
## Wear OS
Watches are glanceable, small, and used in seconds. Do not port a phone UI — design a separate, minimal Wear experience.
- **Compose for Wear OS** is the UI toolkit, with watch-specific components: `ScalingLazyColumn` for lists, curved text, and time text.
- **Tiles** are swipeable cards reached from the watch face — perfect for "next train", "today's steps", or a quick start button. Build them with the Tiles API (ProtoLayout).
- **Complications** put a small data point on the watch face itself (next event, heart rate, battery).
- Keep interactions to one or two taps. Use voice and haptics (vibration feedback).
- Sync data with the phone through the Data Layer API; the watch app should still show last-known data offline.
```kotlin
@Composable
fun WatchHome() {
    val listState = rememberScalingLazyListState()
    Scaffold(timeText = { TimeText() }) {
        ScalingLazyColumn(state = listState) {
            item { Text("Today") }
            items(3) { index -> Chip(label = { Text("Item $index") }, onClick = {}) }
        }
    }
}
```
Wear apps are reviewed against Wear OS quality guidelines, and heavy background work drains a tiny battery fast — keep work short and batched.
Docs: https://developer.android.com/training/wearables and https://developer.android.com/develop/ui/compose/wear-os
## Android TV
TV is a 10-foot experience: big screen, D-pad remote, no touch.
- Build with **Compose for TV** (the TV Material APIs) or the older **Leanback** library for existing projects. New projects should start with Compose for TV.
- Every interactive element must be focusable, with a clear focus highlight. Test the whole app with only D-pad up/down/left/right, Select, and Back — if you need a pointer, it is broken.
- Use rows of cards for browsing, large text, and safe margins (overscan) around screen edges.
- Playback should support pause from the remote, next/previous, and resume where the user left off.
- TV apps go through extra Play review and need a TV banner and Leanback launcher intent to appear in the TV store.
```xml
<uses-feature android:name="android.software.leanback" android:required="false" />
<uses-feature android:name="android.hardware.touchscreen" android:required="false" />
```
```kotlin
LazyRow {
    items(movies) { movie ->
        Card(onClick = { open(movie) }) { Text(movie.title) }
    }
}
```
Docs: https://developer.android.com/training/tv and https://developer.android.com/develop/ui/compose/tv
## Android Automotive and Android Auto
Two different things share the "car" name:
- **Android Auto** — the phone projects a driver-safe UI onto the car screen. You build templates (media, navigation, messaging, and point-of-interest categories such as parking, charging, and fuel) with the Car App Library. Templates are fixed by Google for safety; you supply content, not custom layouts.
- **Android Automotive OS (AAOS)** — Android runs natively in the car. Apps are closer to tablet apps but must follow driver distraction rules, use car-ready UI, and handle car hardware (multiple displays, rotary controls).
Rules for both: minimal text, large targets, voice first, no video or complex input while driving, and strict category and quality review on Play. Most apps should only consider Auto if they are media, navigation, or messaging apps.
Docs: https://developer.android.com/training/cars and https://developer.android.com/training/cars/apps
## XR note
Android XR extends Android to headsets and glasses, built on familiar Android and Jetpack Compose XR APIs with spatial panels, 3D content, and hand/eye input. It is a newer platform: treat it as an experimental extension of your adaptive work, not a starting point for a first app. Follow the platform docs as APIs stabilize, and do not assume phone interaction patterns (precise touch, small text) work in a headset.
See: https://developer.android.com/develop/xr
## Testing checklist
1. Phone: compact layout, portrait and landscape.
2. Tablet/foldable flat: expanded layout, both orientations, split-screen at several window sizes.
3. Foldable: tabletop and book postures, nothing under the hinge.
4. State survives rotation, folding, and window resizing.
5. Wear: glanceable in under 5 seconds, works offline.
6. TV: complete task with D-pad only, focus always visible.
7. Car: only if in an approved category, templates reviewed.
## Summary
Design adaptive first: WindowSizeClass on phones and tablets, correct resizing on large screens under target API 36, and hinge-aware layouts on foldables. Wear, TV, and cars each need their own focused experience — Compose for Wear OS and Tiles, Compose for TV with D-pad focus, and template-based Car App Library apps. XR is the emerging extension to watch.
