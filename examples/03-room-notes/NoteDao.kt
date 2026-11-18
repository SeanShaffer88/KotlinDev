package com.example.app.notes

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Query
import androidx.room.Upsert
import kotlinx.coroutines.flow.Flow

/**
 * Example 03 — Room 2.x DAO.
 *
 * Reads that the UI observes return Flow: Room re-runs the query and
 * emits a fresh list whenever the table changes. One-shot writes are
 * suspend functions so they run on Room's background executor.
 */
@Dao
interface NoteDao {

    @Query("SELECT * FROM notes ORDER BY updatedAtMillis DESC")
    fun observeNotes(): Flow<List<Note>>

    @Query("SELECT * FROM notes WHERE id = :id")
    suspend fun getById(id: Long): Note?

    /** Insert when id == 0, update when the row already exists. */
    @Upsert
    suspend fun upsert(note: Note): Long

    @Delete
    suspend fun delete(note: Note)
}
