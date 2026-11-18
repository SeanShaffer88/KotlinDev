# Data Persistence: Room, DataStore, and Files

Android offers three persistence tiers: a real database (Room) for
structured data, DataStore for settings and preferences, and files
for documents, media, and caches. Choosing the right tier per data
type keeps apps fast and migrations manageable.

Official references:
- Room: https://developer.android.com/training/data-storage/room
- Room migrations: https://developer.android.com/training/data-storage/room/migrating-db-versions
- DataStore: https://developer.android.com/topic/libraries/architecture/datastore
- App storage overview: https://developer.android.com/training/data-storage
- Scoped storage: https://developer.android.com/about/versions/11/privacy/storage

## Room — The Local Database

Room is a SQLite abstraction with compile-time checked queries,
coroutine and Flow support, and a migration system. Verified version
for the established line: **Room 2.8.5 stable**. There is also a new
major: **Room 3.0.3**, published under `androidx.room3`, rebuilt
KMP-first (Kotlin Multiplatform) with KSP-only processing.

**Room 2 and Room 3 are different majors.** Their artifacts,
packages, and setup differ. Name which major a project uses and
never mix the two in one project or copy setup code across majors.

### Room 2.x Shape (androidx.room)

```kotlin
@Entity(tableName = "items")
data class ItemEntity(
    @PrimaryKey val id: Long,
    val title: String,
    val updatedAt: Long
)

@Dao
interface ItemDao {
    @Query("SELECT * FROM items ORDER BY title")
    fun observeAll(): Flow<List<ItemEntity>>

    @Query("SELECT * FROM items WHERE id = :id")
    suspend fun getById(id: Long): ItemEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertAll(items: List<ItemEntity>)

    @Query("DELETE FROM items")
    suspend fun clearAll()
}

@Database(entities = [ItemEntity::class], version = 1, exportSchema = true)
abstract class AppDatabase : RoomDatabase() {
    abstract fun itemDao(): ItemDao
}
```

Build with KSP (Room's compiler runs on KSP; kapt is legacy):

```kotlin
val db = Room.databaseBuilder(context, AppDatabase::class.java, "app.db")
    .build()
```

Guidelines:

- Observe with `Flow` queries — the UI updates automatically when
  tables change. This is what makes offline-first easy.
- Keep entities as storage models; map to domain models in the
  repository. Do not expose entities to the UI layer.
- All DAO suspend and Flow work is main-safe — Room runs queries
  off the main thread for you.

### Room 3.0.3 (androidx.room3)

Room 3 moves to the `androidx.room3` group, is KMP-first (common
code can define the database for Android and other targets), and is
KSP-only. Choose Room 3 for new KMP-oriented projects; choose the
2.8.5 line when following the widest body of existing Android-only
guidance and libraries. Either way, commit to one major per project
and use that major's documentation.

### Migrations

Every schema change bumps the database `version` and needs a
migration, or users lose data on upgrade.

```kotlin
val MIGRATION_1_2 = object : Migration(1, 2) {
    override fun migrate(db: SupportSQLiteDatabase) {
        db.execSQL("ALTER TABLE items ADD COLUMN priority INTEGER NOT NULL DEFAULT 0")
    }
}

Room.databaseBuilder(context, AppDatabase::class.java, "app.db")
    .addMigrations(MIGRATION_1_2)
    .build()
```

- Set `exportSchema = true` and commit schema JSON files — Room
  validates migrations against them.
- Write a migration test for every version pair you ship.
- `fallbackToDestructiveMigration` deletes user data. Acceptable
  only for a pure cache database, never for user content.
- Auto-migrations cover simple changes (added columns with
  defaults); manual migrations handle renames and data transforms.

## DataStore — Settings and Preferences

DataStore replaces SharedPreferences. It is asynchronous (coroutine
and Flow based), type-safe in its Proto form, and cannot block the
UI thread or lose writes the way SharedPreferences could.

Verified version: **DataStore 1.3.0**.

### Preferences DataStore

```kotlin
private val Context.dataStore by preferencesDataStore(name = "settings")

object SettingsKeys {
    val DARK_MODE = booleanPreferencesKey("dark_mode")
    val SORT_ORDER = stringPreferencesKey("sort_order")
}

class SettingsRepository(private val context: Context) {
    val darkMode: Flow<Boolean> = context.dataStore.data
        .map { prefs -> prefs[SettingsKeys.DARK_MODE] ?: false }

    suspend fun setDarkMode(enabled: Boolean) {
        context.dataStore.edit { prefs ->
            prefs[SettingsKeys.DARK_MODE] = enabled
        }
    }
}
```

### Choosing Between the Two DataStore Forms

- **Preferences DataStore** — key-value pairs, no schema. Right for
  settings, flags, and small user choices.
- **Proto DataStore** — a typed schema (protobuf) with migrations.
  Right when settings grow structured or are shared with a backend.

Do not store large or relational data in DataStore — that is Room's
job. Do not keep using SharedPreferences in new code; migrate reads
to DataStore once and keep the old file as the migration source
(DataStore ships a SharedPreferences migration helper).

## Files and Scoped Storage

Android uses scoped storage: your app freely accesses its own
private directories, and shared storage (photos, downloads) goes
through the MediaStore or the system file picker.

Private storage — no permissions needed:

- `context.filesDir` — internal files that persist (documents,
  downloaded models).
- `context.cacheDir` — internal cache; the system may clear it.
  Anything here must be re-creatable.
- External app-specific dirs (`getExternalFilesDir`) — larger files
  visible when the device is connected, still permission-free.

```kotlin
suspend fun saveReport(context: Context, text: String) =
    withContext(Dispatchers.IO) {
        File(context.filesDir, "report.txt").writeText(text)
    }
```

Shared storage rules:

- Use the Storage Access Framework picker (`ActivityResultContracts
  .OpenDocument` / `CreateDocument`) to let the user choose files —
  no broad storage permission needed.
- Use MediaStore to read and write shared photos, video, and audio.
- Broad permissions like `READ_EXTERNAL_STORAGE` are legacy; modern
  versions use per-media permissions and partial access instead.
  Request the narrowest access the feature needs.

## SQLDelight — A Note

SQLDelight is a JetBrains library that generates type-safe Kotlin
APIs from `.sq` SQL files. It is KMP-first and a credible choice
when a database is shared across Android and iOS/desktop targets.
For Android-only apps, Room remains the default recommendation —
larger community, official support, and Flow integration out of the
box. As with Room majors, pick one database stack per project.

## Choosing the Right Tier

| Data | Store |
|------|-------|
| Lists, records, anything queried or related | Room |
| Settings, flags, last-used choices | DataStore |
| Documents, exports, downloaded assets | Files (app-private) |
| Rebuildable downloads and thumbnails | Cache dir |
| Secrets and tokens | Encrypted storage — never plain files or DataStore |

## Common Mistakes

- Storing structured, growing data in DataStore or SharedPreferences.
- Destructive migrations on a database holding user content.
- Writing files on the main thread.
- Assuming cache files still exist — the system can delete them.
- Keeping two database stacks (Room and SQLDelight) in one app.
- Mixing Room 2 artifacts with Room 3 setup code copied from a
  different tutorial.
