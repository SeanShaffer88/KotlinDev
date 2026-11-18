package com.example.app.macrobenchmark

import androidx.benchmark.macro.BaselineProfileMode
import androidx.benchmark.macro.CompilationMode
import androidx.benchmark.macro.FrameTimingMetric
import androidx.benchmark.macro.StartupMode
import androidx.benchmark.macro.StartupTimingMetric
import androidx.benchmark.macro.junit4.MacrobenchmarkRule
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.uiautomator.By
import androidx.test.uiautomator.Direction
import androidx.test.uiautomator.Until
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Macrobenchmark skeletons: cold startup + a scrollable-list scroll.
 *
 * Run against a release (non-debuggable, profileable) build of the app:
 *   ./gradlew :macrobenchmark:connectedBenchmarkAndroidTest
 *
 * Replace PACKAGE_NAME, the start destination, and the scrollable
 * selector with your app's real ones. The list benchmark assumes a
 * scrollable element tagged/content-described "item_list" — set that
 * testTag / content description on your LazyColumn (or RecyclerView).
 */
@RunWith(AndroidJUnit4::class)
class StartupBenchmark {
    @get:Rule
    val benchmarkRule = MacrobenchmarkRule()

    @Test
    fun startupNoCompilation() = startup(CompilationMode.None())

    @Test
    fun startupBaselineProfile() =
        startup(CompilationMode.Partial(baselineProfileMode = BaselineProfileMode.Require))

    private fun startup(compilationMode: CompilationMode) = benchmarkRule.measureRepeated(
        packageName = PACKAGE_NAME,
        metrics = listOf(StartupTimingMetric()),
        iterations = 5,
        startupMode = StartupMode.COLD,
        compilationMode = compilationMode,
    ) {
        pressHome()
        startActivityAndWait()
    }

    companion object {
        const val PACKAGE_NAME = "com.example.app"
    }
}

@RunWith(AndroidJUnit4::class)
class ScrollBenchmark {
    @get:Rule
    val benchmarkRule = MacrobenchmarkRule()

    @Test
    fun scrollList() = benchmarkRule.measureRepeated(
        packageName = StartupBenchmark.PACKAGE_NAME,
        metrics = listOf(FrameTimingMetric()),
        iterations = 5,
        startupMode = StartupMode.WARM,
        compilationMode = CompilationMode.Partial(
            baselineProfileMode = BaselineProfileMode.Require,
        ),
    ) {
        startActivityAndWait()

        val list = device.findObject(By.scrollable(true))
            ?: error("No scrollable element found — add one or adjust the selector")
        // Leave margin so flings don't hit the status/navigation bars.
        list.setGestureMargin(device.displayWidth / 5)
        repeat(3) {
            list.fling(Direction.DOWN)
            device.waitForIdle()
        }
        // Wait until content is present before the next iteration's measurement.
        device.wait(Until.hasObject(By.scrollable(true)), 5_000)
    }
}
