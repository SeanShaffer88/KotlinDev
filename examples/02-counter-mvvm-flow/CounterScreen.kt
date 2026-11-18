package com.example.app.counter

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel

/**
 * Example 02 — UI half of unidirectional data flow.
 *
 * CounterRoute is the stateful wrapper: it obtains the ViewModel and
 * collects its StateFlow in a lifecycle-aware way. CounterScreen is
 * stateless: it receives plain values and callbacks, which makes it
 * previewable and testable without any Android framework types.
 */
@Composable
fun CounterRoute(
    modifier: Modifier = Modifier,
    counterViewModel: CounterViewModel = viewModel(),
) {
    val uiState by counterViewModel.uiState.collectAsStateWithLifecycle()
    CounterScreen(
        count = uiState.count,
        onIncrement = counterViewModel::onIncrement,
        onDecrement = counterViewModel::onDecrement,
        onReset = counterViewModel::onReset,
        modifier = modifier,
    )
}

@Composable
fun CounterScreen(
    count: Int,
    onIncrement: () -> Unit,
    onDecrement: () -> Unit,
    onReset: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Column(
        modifier = modifier
            .fillMaxSize()
            .padding(24.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(text = "Count", style = MaterialTheme.typography.titleMedium)
        Text(text = count.toString(), style = MaterialTheme.typography.displayLarge)
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            OutlinedButton(onClick = onDecrement) { Text("−1") }
            Button(onClick = onIncrement) { Text("+1") }
            OutlinedButton(onClick = onReset) { Text("Reset") }
        }
    }
}

@Preview(showBackground = true)
@Composable
private fun CounterScreenPreview() {
    MaterialTheme {
        CounterScreen(count = 42, onIncrement = {}, onDecrement = {}, onReset = {})
    }
}
