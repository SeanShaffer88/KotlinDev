# App Anatomy, Lifecycle, and Components

Every Android app is a set of components the system starts and stops
as needed. Understanding the manifest, the Application class, the
Activity lifecycle, and the four component types prevents most
beginner bugs.

Official references:
- App components: https://developer.android.com/guide/components/fundamentals
- Activity lifecycle: https://developer.android.com/guide/components/activities/activity-lifecycle
- Manifest overview: https://developer.android.com/guide/topics/manifest/manifest-intro
- App links: https://developer.android.com/training/app-links

## The AndroidManifest

`AndroidManifest.xml` declares your app to the system: components,
permissions, features, and metadata. Gradle merges library manifests
into the final one.

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <application
        android:name=".MyApplication"
        android:label="@string/app_name"
        android:theme="@style/Theme.MyApp"
        android:icon="@mipmap/ic_launcher">
        <activity android:name=".MainActivity" android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
```

Key rules:

- `android:exported` is required on every component with an intent
  filter (API 31+). Set it deliberately: `true` only when other apps
  should start the component.
- Request permissions at the top level; use them at point of use.
- Declare foreground service types and hardware features here too.

## The Application Class

`Application` is created before any other component. Use it only for
app-wide setup that must happen first: the dependency injection
graph, logging, and crash reporting initialization.

```kotlin
class MyApplication : Application() {
    lateinit var appContainer: AppContainer
        private set
    override fun onCreate() {
        super.onCreate()
        appContainer = AppContainer(this)
    }
}
```

Do not store Activity references or mutable screen state here — that
leaks memory. Heavy work in `onCreate` delays startup; defer
anything not needed immediately.

## Activity and Its Lifecycle

An Activity hosts UI. In a Compose app there is usually one Activity
whose content is set once with `setContent`.

```kotlin
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent { MyAppTheme { AppNavigation() } }
    }
}
```

Lifecycle callbacks, in order:

1. `onCreate` — inflate UI, restore state, start observing data.
2. `onStart` — UI becomes visible.
3. `onResume` — UI is in the foreground and interactive.
4. `onPause` — losing focus; save light state, pause animations.
5. `onStop` — no longer visible; release heavier resources.
6. `onDestroy` — final teardown; not guaranteed if the process is
   killed first.
7. `onRestart` — returning from stopped to started.

In Compose, prefer `DisposableEffect` and lifecycle-aware collection
over overriding callbacks for UI work:

```kotlin
lifecycleScope.launch {
    repeatOnLifecycle(Lifecycle.State.STARTED) {
        viewModel.uiState.collect { render(it) }
    }
}
```

## Configuration Changes and Process Death

Rotating the device, switching dark mode, or changing locale are
configuration changes. By default the Activity is destroyed and
recreated. State survives three ways:

- **ViewModel** — survives configuration changes, not process death.
- **Saved state** — `SavedStateHandle`, `rememberSaveable`, and
  `onSaveInstanceState` survive recreation and process death. Keep
  only small, serializable values here (IDs, query text).
- **Persistent storage** — Room, DataStore, or files survive all.

Process death: the system can kill a backgrounded app's process at
any time. When the user returns, the app must restore from saved
state and storage. Test with "Don't keep activities" and by
backgrounding under memory pressure. Never rely on static fields or
the Application object to keep screen state alive across a kill.

## The Four Component Types

### Activities
One screen of UI. Modern apps use a single Activity with Compose
destinations or Fragments inside it.

### Services
Background work without UI. A **foreground service** does ongoing
work the user can see (music, navigation, upload with progress) and
requires a notification plus a declared FGS type and permission at
API 34+. For deferrable work, use WorkManager instead of a service.

### BroadcastReceivers
Respond to system or app broadcasts (boot completed, connectivity
changes). Many implicit broadcasts are restricted; prefer
context-registered receivers or platform callbacks in-app.

```kotlin
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            // Reschedule WorkManager work — keep this fast.
        }
    }
}
```

Receivers must finish quickly (about 10 seconds). Offload real work
to WorkManager.

### ContentProviders
Share structured data through a URI-based API (`content://…`). Most
apps consume providers (contacts, media) rather than publish one.
Publish one only when other apps genuinely need your data; guard it
with permissions and `exported=false` by default.

## Intents

Intents request an action from another component.

```kotlin
// Explicit — target a component in your own app
val intent = Intent(context, DetailActivity::class.java).apply {
    putExtra("item_id", 42L)
}
context.startActivity(intent)

// Implicit — let the system choose an app
val share = Intent(Intent.ACTION_SEND).apply {
    type = "text/plain"
    putExtra(Intent.EXTRA_TEXT, "Check this out")
}
context.startActivity(Intent.createChooser(share, null))
```

Prefer explicit intents inside your app. For implicit intents,
always handle the case where no app can respond.

## Deep Links and App Links

A deep link opens a specific screen from a URI. An App Link is a
verified HTTPS deep link that opens your app instead of the browser.

```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="https" android:host="www.example.com" />
</intent-filter>
```

App Links require a Digital Asset Links file at
`https://www.example.com/.well-known/assetlinks.json` with your
package name and signing certificate fingerprint. In Compose
Navigation, declare the same URI pattern as a `deepLink` on the
destination so handling stays in one place. Handle incoming links in
both cold start and `onNewIntent` — a running single-top Activity
receives later links through `onNewIntent`, not a fresh `onCreate`.

## Practical Rules

- One Activity, many destinations, is the default architecture.
- Keep `onCreate` fast; defer non-essential initialization.
- Save small state in saved state, big state in storage, and keep
  in-memory state in a ViewModel.
- Assume process death can happen whenever the app is backgrounded.
- Set `exported` deliberately on every component.
