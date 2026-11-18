# 03 — Room notes (entity, DAO, repository)

A notes data layer in three files: what gets stored, how it is
queried, and the repository the UI actually talks to.

## What it teaches

- `@Entity` / `@PrimaryKey(autoGenerate = true)` for the table shape.
- A DAO with a `Flow<List<Note>>` query — the UI observes the database
  and updates automatically when rows change; no manual refresh.
- Suspend functions for one-shot writes (Room runs them off the main
  thread; calling a blocking DAO method on the UI thread crashes).
- The repository pattern: the UI layer depends on `NotesRepository`,
  never on the DAO directly, so the data source can change (or be
  faked in tests) without touching screens.

## Room version — read this first

This example uses the **Room 2.x API** (`androidx.room:room-runtime`
**2.8.5**, KSP with `androidx.room:room-compiler`), matching
`tools/versions.json`.

**Room 3 (3.0.3) is a different major, not a drop-in upgrade:** Room 3
moves to `androidx.room3` packages / artifacts, is KMP-ready and
KSP-only, and changes database-builder and migration APIs. Do not mix
Room 2 tutorials or imports into a Room 3 project (or vice versa) —
pick one major per project and use its coordinates consistently.

## Files

- `Note.kt` — the entity.
- `NoteDao.kt` — queries and writes.
- `NotesRepository.kt` — repository wrapper + the database builder
  snippet (in a comment-shaped factory) the app calls once.

## Wiring (in your app)

```kotlin
val db = NotesRepository.createDatabase(applicationContext)
val repository = NotesRepository(db.noteDao())
// In a ViewModel: repository.notes.collect { /* render */ }
```

> **Disclaimer:** this is a teaching excerpt, not a full Gradle
> project. The full skeleton is `templates/compose-app/` — see the
> note in [`../README.md`](../README.md). Add the Room libraries and
> the KSP plugin from the template's version catalog to build it.
