package com.example.app.notes

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import kotlinx.coroutines.flow.Flow

/**
 * Example 03 — Room 2.x database + repository.
 *
 * The repository is the only type the UI layer talks to. It exposes
 * the DAO's Flow unchanged here (the mapping point, if domain models
 * ever diverge from entities, is this class) and keeps write calls
 * one line each.
 */
@Database(entities = [Note::class], version = 1, exportSchema = false)
abstract class NotesDatabase : RoomDatabase() {
    abstract fun noteDao(): NoteDao
}

class NotesRepository(private val dao: NoteDao) {

    /** Hot stream of all notes, newest first. Collect it in a ViewModel. */
    val notes: Flow<List<Note>> = dao.observeNotes()

    suspend fun note(id: Long): Note? = dao.getById(id)

    suspend fun save(title: String, body: String, existing: Note? = null): Long =
        dao.upsert(
            (existing ?: Note(title = title, body = body)).copy(
                title = title,
                body = body,
                updatedAtMillis = System.currentTimeMillis(),
            ),
        )

    suspend fun delete(note: Note) = dao.delete(note)

    companion object {
        /** Build the database once per process (Application class or DI). */
        fun createDatabase(context: Context): NotesDatabase =
            Room.databaseBuilder(
                context.applicationContext,
                NotesDatabase::class.java,
                "notes.db",
            ).build()
    }
}
