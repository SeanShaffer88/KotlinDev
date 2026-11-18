# Migration — Java and Views to Modern Kotlin

How to move an existing Android project forward in small, safe
steps: Java to Kotlin, Views to Compose, and the old async and
storage APIs to their modern replacements. Migrate
incrementally — big-bang rewrites are how projects die.

## Ground Rules for Any Migration

1. The app must build and pass tests after every step.
2. One migration axis at a time: language, UI, or storage —
   never all three in one change.
3. Keep the old and new code interoperable during the move.
   Kotlin and Views/Compose are both designed for this.
4. Add tests around behaviour before changing its technology,
   especially for data migrations.

## Java to Kotlin — Interop First

Kotlin and Java interoperate fully in one module. Convert file
by file, starting with leaf classes: models, utilities, and
small helpers, then activities and complex classes last.

### Nullability Is the Main Work

Java types arrive in Kotlin as platform types (`String!`),
which carry no null guarantee. Fix the boundary:

```java
// Java: annotate so Kotlin sees real nullability
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

public class User {
    @NonNull private final String id;
    @Nullable private String nickname;
    // getters...
}
```

```kotlin
// Kotlin caller now gets String and String? — no guessing.
fun greeting(user: User): String =
    user.nickname ?: user.id
```

In converted Kotlin code:
- Prefer `val` over `var`, data classes for models.
- Replace static utility classes with top-level functions or
  an `object` only where a singleton is truly intended.
- Watch SAM conversions, getters/setters becoming properties,
  and checked exceptions disappearing (Kotlin has none) —
  callers in Java may have relied on them.

Android Studio's Java-to-Kotlin converter is a starting point,
not a finish: review every converted file for platform types,
`lateinit` overuse, and Java idioms that have a cleaner Kotlin
form. Do not convert generated code or third-party sources.

## Views to Compose — Incremental by Design

Compose interoperates with the View system in both directions,
so migrate screen by screen.

### Compose Inside a View Screen

```kotlin
// In an existing Fragment/Activity layout, a ComposeView hosts Compose.
binding.composeView.setContent {
    MyTheme { ProfileHeader(user) }
}
```

### Views Inside Compose

```kotlin
@Composable
fun LegacyMap(modifier: Modifier = Modifier) {
    AndroidView(
        factory = { context -> MapView(context) },
        modifier = modifier,
        update = { view -> /* push new state into the view */ }
    )
}
```

Migration order that works well:
1. New screens in Compose first — no migration risk.
2. Simple existing screens (settings, about, lists) next.
3. Complex custom views last, or keep them wrapped in
   `AndroidView` if they work well.
4. Move navigation last, once most destinations are Compose.

Theme bridge: define colours/typography once and share them.
During transition, Compose's `MaterialTheme` can wrap migrated
screens inside View-based activities via `ComposeView`.

Do not migrate and redesign in the same step. First make the
Compose version look and behave like the View version; redesign
later, as its own change.

## AsyncTask and Loaders to Coroutines

`AsyncTask` is deprecated and `Loaders` are superseded. Replace
both with coroutines plus a ViewModel that survives rotation.

```kotlin
// Before (conceptual): AsyncTask doing network then updating UI.
// After:
class FeedViewModel(
    private val repo: FeedRepository
) : ViewModel() {
    private val _state = MutableStateFlow<UiState>(UiState.Loading)
    val state: StateFlow<UiState> = _state.asStateFlow()

    fun load() {
        viewModelScope.launch {
            _state.value = try {
                UiState.Data(repo.fetchFeed()) // suspend, off main thread in repo
            } catch (e: IOException) {
                UiState.Error("Could not load. Check your connection.")
            }
        }
    }
}
```

Rules:
- `viewModelScope` for UI work, repository dispatchers for IO.
- Never `GlobalScope`. Every launch has an owner.
- Loaders' job (survive config change, deliver once) is covered
  by ViewModel + `StateFlow` collection with lifecycle awareness.

## SQLite to Room

Moving from raw `SQLiteOpenHelper` to Room:

1. Keep the same database name and version history. Room can
   open the existing database if the schema matches.
2. Define entities to match existing tables exactly, export the
   schema, and compare with the live schema.
3. Reuse your existing migrations: wrap the same SQL in Room
   `Migration` objects so upgrades behave identically.

```kotlin
val MIGRATION_3_4 = object : Migration(3, 4) {
    override fun migrate(db: SupportSQLiteDatabase) {
        db.execSQL("ALTER TABLE notes ADD COLUMN pinned INTEGER NOT NULL DEFAULT 0")
    }
}

Room.databaseBuilder(context, AppDb::class.java, "app.db")
    .addMigrations(MIGRATION_3_4)
    .build()
```

Note the AGENTS.md rule: Room 2 and Room 3 are different
majors. Decide which major the project uses first (doc 11)
and use only that major's setup and migration APIs.

Test migrations with real old-version database files — a
migration bug destroys user data, the worst failure class.

## SharedPreferences to DataStore

DataStore replaces SharedPreferences for settings and small
key-value state: it is asynchronous, transactional, and does
not block the main thread.

```kotlin
val Context.settingsStore by preferencesDataStore(name = "settings")

val darkModeKey = booleanPreferencesKey("dark_mode")

suspend fun setDarkMode(context: Context, enabled: Boolean) {
    context.settingsStore.edit { prefs -> prefs[darkModeKey] = enabled }
}

val darkModeFlow: Flow<Boolean> = context.settingsStore.data
    .map { prefs -> prefs[darkModeKey] ?: false }
```

Migration path:
- DataStore provides a `SharedPreferencesMigration` that moves
  existing preferences once. Use it so users keep settings.
- Move simple flags to Preferences DataStore.
- Move structured settings (multiple related fields) to Proto
  DataStore when the schema matters.
- Keep secrets out of plain DataStore files; encrypt sensitive
  values or use a keystore-backed store (see doc 29 rules).

## Other Common Replacements

| Old | Modern replacement |
|---|---|
| `AsyncTask` | Coroutines + ViewModel |
| `Loaders` | ViewModel + StateFlow |
| Raw `SQLiteOpenHelper` | Room |
| `SharedPreferences` | DataStore |
| Java `Executor` plumbing | Coroutine dispatchers |
| `LiveData` (new code) | `StateFlow` / `SharedFlow` |
| Standalone ExoPlayer 2 | Media3 (`androidx.media3`) |
| `findViewById` | View Binding, then Compose |
| Listeners everywhere | Flow / coroutines channels where apt |

## A Safe Migration Plan (Template)

1. Baseline: green build, tests, a release you can roll back to.
2. Convert Java leaf classes to Kotlin; ship.
3. Replace AsyncTask/Loader hotspots with coroutines; ship.
4. Move SharedPreferences to DataStore with migration; ship.
5. Wrap SQLite in Room with tested migrations; ship.
6. Migrate screens to Compose one by one; ship each.
7. Remove View-era leftovers only when nothing references them.

Each "ship" can be an internal track if the app is sensitive.
The point is small, reversible steps with a working app between.

## Official Links

- Kotlin/Java interop: https://kotlinlang.org/docs/java-interop.html
- Calling Kotlin from Java: https://kotlinlang.org/docs/java-to-kotlin-interop.html
- Compose/View interop: https://developer.android.com/jetpack/compose/migrate/interoperability-apis
- Migration strategy to Compose: https://developer.android.com/jetpack/compose/migrate/strategy
- Coroutines: https://developer.android.com/kotlin/coroutines
- Room migrations: https://developer.android.com/training/data-storage/room/migrating-db-versions
- DataStore: https://developer.android.com/topic/libraries/architecture/datastore
- DataStore migration from SharedPreferences: https://developer.android.com/topic/libraries/architecture/datastore#preferences-migration
