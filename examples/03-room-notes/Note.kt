package com.example.app.notes

import androidx.room.Entity
import androidx.room.PrimaryKey

/**
 * Example 03 — Room 2.x entity.
 *
 * One data class = one table ("notes"). Room generates the SQLite
 * schema from these annotations at compile time via KSP.
 *
 * Room 3 note: in Room 3.x the annotations live in the androidx.room3
 * packages and the setup differs — see this example's README before
 * porting.
 */
@Entity(tableName = "notes")
data class Note(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val title: String,
    val body: String,
    /** Epoch milliseconds; sort/display formatting is the UI's job. */
    val updatedAtMillis: Long = System.currentTimeMillis(),
)
