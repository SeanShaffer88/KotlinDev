# Room Seed — Prepopulating a Database from `seed.sql`

`seed.sql` contains `INSERT` statements for a `notes` table that
match `../sample-data/notes.json` record for record (same ids,
userIds, titles, tags, timestamps). Two standard ways to use it:

## Option A — Ship a prebuilt database (`createFromAsset`)

Build a `.db` file once from the SQL, put it in `assets/`, and let
Room copy it on first launch:

```bash
sqlite3 notes.db < seed.sql   # after creating the table (schema in seed.sql header)
# place notes.db in app/src/main/assets/
```

```kotlin
Room.databaseBuilder(context, AppDatabase::class.java, "app.db")
    .createFromAsset("notes.db")
    .build()
```

The asset database's schema and version must match your entities and
Room's identity hash, or Room will reject it — rebuild the asset
whenever the schema changes.

## Option B — Prepopulate callback (run the SQL on first create)

Keep the data as SQL and execute it when Room first creates the
database. This keeps the seed readable and diff-able in git:

```kotlin
Room.databaseBuilder(context, AppDatabase::class.java, "app.db")
    .addCallback(object : RoomDatabase.Callback() {
        override fun onCreate(db: SupportSQLiteDatabase) {
            super.onCreate(db)
            // Execute each INSERT from seed.sql here, e.g. by reading
            // the file bundled in assets and calling db.execSQL(line)
            // for every statement. Do this off the main thread.
        }
    })
    .build()
```

(Exact callback/helper APIs differ between Room majors — see the
note below and verify against the version you use.)

## Room 2 vs Room 3

This fixture is just SQL, so it works with either major — but the
code around it does not transfer blindly:

- **Room 2.x** (`androidx.room`) is the maintenance line most existing
  apps use; `createFromAsset` and `RoomDatabase.Callback` /
  `SupportSQLiteDatabase` are the Room 2 shapes sketched above.
- **Room 3.x** (`androidx.room3`) is KMP-first and KSP-only, uses the
  `SQLiteDriver` / `BundledSQLiteDriver` world instead of
  `SupportSQLiteDatabase`, and its builder/callback APIs differ.
  Use the same `seed.sql`, but follow Room 3's own prepopulation
  documentation for the wiring — never mix Room 2 snippets into a
  Room 3 project (see `AGENTS.md` rule 7 and
  `docs/11-data-persistence-room-datastore-files.md`).

## Table shape assumed

```sql
notes(id INTEGER PRIMARY KEY, userId INTEGER NOT NULL,
      title TEXT NOT NULL, body TEXT NOT NULL, tags TEXT NOT NULL,
      pinned INTEGER NOT NULL, createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL)
```

`tags` is stored comma-joined in this fixture to keep the SQL simple;
in production prefer a `TypeConverter` to a list. Timestamps are
ISO-8601 UTC strings, matching `notes.json`.
