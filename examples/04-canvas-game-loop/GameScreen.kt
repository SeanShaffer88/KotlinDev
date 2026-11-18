package com.example.app.game

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.unit.dp
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver

/**
 * Example 04 — Compose Canvas game loop.
 *
 * Structure used by every frame-based game, engine or not:
 *   1. wait for the next frame (withFrameNanos),
 *   2. compute dt = time since the previous frame,
 *   3. update the world by speed * dt,
 *   4. draw the world (here: invalidate the Canvas by reading state).
 *
 * The loop pauses when the lifecycle stops (app backgrounded) and on
 * tap, and resumes on tap. Speeds are in pixels per second so motion
 * is refresh-rate independent.
 */
@Composable
fun GameScreen(modifier: Modifier = Modifier) {
    // --- World state (positions in pixels, speeds in px/second) ---
    var ballX by remember { mutableFloatStateOf(120f) }
    var ballY by remember { mutableFloatStateOf(120f) }
    var velocityX by remember { mutableFloatStateOf(260f) }
    var velocityY by remember { mutableFloatStateOf(190f) }
    val ballRadius = 36f
    var running by remember { mutableStateOf(true) }

    // --- Pause automatically when the app leaves the foreground ---
    val lifecycleOwner = LocalLifecycleOwner.current
    DisposableEffect(lifecycleOwner) {
        val observer = LifecycleEventObserver { _, event ->
            if (event == Lifecycle.Event.ON_STOP) running = false
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        onDispose { lifecycleOwner.lifecycle.removeObserver(observer) }
    }

    // Bounds are learned from the Canvas size each frame; kept here so
    // the update step and the draw step agree on them.
    var boundsWidth by remember { mutableFloatStateOf(0f) }
    var boundsHeight by remember { mutableFloatStateOf(0f) }

    // --- Frame loop ---
    LaunchedEffect(Unit) {
        var lastFrameNanos = -1L
        while (true) {
            withFrameNanos { frameNanos ->
                if (lastFrameNanos < 0L) {
                    lastFrameNanos = frameNanos
                    return@withFrameNanos
                }
                // Clamp dt: a stalled frame (GC, debugger) must not
                // teleport the ball across the screen.
                val dtSeconds = ((frameNanos - lastFrameNanos) / 1_000_000_000f)
                    .coerceIn(0f, 0.05f)
                lastFrameNanos = frameNanos
                if (!running || boundsWidth <= 0f || boundsHeight <= 0f) {
                    return@withFrameNanos
                }
                ballX += velocityX * dtSeconds
                ballY += velocityY * dtSeconds
                if (ballX - ballRadius < 0f) {
                    ballX = ballRadius
                    velocityX = -velocityX
                } else if (ballX + ballRadius > boundsWidth) {
                    ballX = boundsWidth - ballRadius
                    velocityX = -velocityX
                }
                if (ballY - ballRadius < 0f) {
                    ballY = ballRadius
                    velocityY = -velocityY
                } else if (ballY + ballRadius > boundsHeight) {
                    ballY = boundsHeight - ballRadius
                    velocityY = -velocityY
                }
            }
        }
    }

    Box(modifier = modifier.fillMaxSize()) {
        Canvas(
            modifier = Modifier
                .fillMaxSize()
                .pointerInput(Unit) {
                    detectTapGestures { running = !running }
                },
        ) {
            boundsWidth = size.width
            boundsHeight = size.height
            drawCircle(
                color = Color(0xFF960018),
                radius = ballRadius,
                center = Offset(ballX, ballY),
            )
        }
        Text(
            text = if (running) "Tap to pause" else "Paused — tap to resume",
            style = MaterialTheme.typography.labelLarge,
            modifier = Modifier.padding(16.dp),
        )
    }
}
