package com.example.app.counter

import androidx.lifecycle.ViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update

/** Immutable UI state for the counter screen. */
data class CounterUiState(
    val count: Int = 0,
)

/**
 * Example 02 — ViewModel half of unidirectional data flow.
 *
 * The ViewModel owns a private MutableStateFlow and exposes it as a
 * read-only StateFlow. The UI never mutates state directly; it calls
 * the event functions below, and the new state flows back down.
 */
class CounterViewModel : ViewModel() {

    private val _uiState = MutableStateFlow(CounterUiState())
    val uiState: StateFlow<CounterUiState> = _uiState.asStateFlow()

    fun onIncrement() {
        _uiState.update { it.copy(count = it.count + 1) }
    }

    fun onDecrement() {
        _uiState.update { it.copy(count = (it.count - 1).coerceAtLeast(0)) }
    }

    fun onReset() {
        _uiState.update { it.copy(count = 0) }
    }
}
