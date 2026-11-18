# Testing Strategy for Android Apps
## TL;DR
Test in layers: many fast unit tests, fewer integration tests, and a small number of end-to-end tests. Run unit tests on every change, instrumented tests on a device or emulator in CI, and use screenshot and performance tests to catch problems unit tests cannot see.
Official guides: Testing overview https://developer.android.com/training/testing · Test apps https://developer.android.com/studio/test · Kotlin testing https://kotlinlang.org/docs/jvm-test-libraries.html
## 1. The test pyramid
```text
        /  E2E / UI   \      few, slow, run on device
       /  Integration  \     some, medium speed
      /     Unit        \    many, fast, run on JVM
```
- **Unit tests** (`src/test/`): run on the local JVM in seconds. Test ViewModels, repositories with fakes, mappers, and pure logic.
- **Integration tests**: test how pieces work together, for example Room DAOs, DataStore, Retrofit with a fake server, and WorkManager.
- **Instrumented / UI tests** (`src/androidTest/`): run on a device or emulator. Needed for real Android APIs, Compose UI, and navigation.
- **Screenshot tests**: compare a rendered screen to a reference image. **Performance tests**: Macrobenchmark for startup and scrolling.
Aim for roughly 70% unit, 20% integration, 10% UI/E2E as a starting point, then adjust: a game or drawing app needs more rendering tests; a data app needs more repository tests.
## 2. Local JVM tests: JUnit, Truth, and MockK
JUnit is the standard runner for local tests. Truth gives readable assertions. MockK is built for Kotlin and handles final classes, coroutines, and extension functions well.
```kotlin
// build.gradle.kts (module)
dependencies {
    testImplementation("junit:junit:4.13.2")
    testImplementation("com.google.truth:truth:1.4.4")
    testImplementation("io.mockk:mockk:1.13.13")
    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.9.0")
}
```
```kotlin
class CounterViewModelTest {
    private val repo = mockk<CounterRepository>()
    private lateinit var viewModel: CounterViewModel
    @Before fun setUp() {
        every { repo.load() } returns 41
        viewModel = CounterViewModel(repo)
    }
    @Test fun increment_addsOne() {
        viewModel.increment()
        assertThat(viewModel.count).isEqualTo(42)
        verify { repo.save(42) }
    }
    @Test fun emptyName_isRejected() {
        assertThat(validateName("")).isFalse()
        assertThat(validateName("Ada")).isTrue()
    }
}
```
Prefer fakes over mocks for repositories and DAOs: a fake is a simple working implementation you control and breaks less often when an interface changes. Use mocks for narrow collaborators like analytics or a clock.
Test coroutines and Flow with `runTest` and a test dispatcher. Reference: https://developer.android.com/kotlin/coroutines/test
```kotlin
@Test fun flow_emitsLoadingThenData() = runTest {
    val repo = FakeRepo(listOf("a", "b"))
    val vm = ListViewModel(repo, StandardTestDispatcher(testScheduler))
    advanceUntilIdle()
    assertThat(vm.state.value.items).containsExactly("a", "b").inOrder()
}
```
## 3. Note on JUnit 6 for JVM modules
JUnit 6, built on the JUnit Platform as the successor to JUnit 5 Jupiter, works well in pure Kotlin/JVM modules, desktop tools, and KMP shared code. Use `@Test` from `org.junit.jupiter.api`, `@BeforeEach`, and Jupiter parameterized tests there.
Android instrumented tests are different: the Android Gradle Plugin and `AndroidJUnitRunner` still target the JUnit 4 API on device. Keep `androidTest` code on JUnit 4 with `AndroidJUnit4`, keep JVM-only modules free to use JUnit 6, and do not mix the two runners in one source set.
Links: JUnit https://junit.org/ · AndroidJUnitRunner https://developer.android.com/training/testing/instrumented-tests
## 4. Instrumented tests with AndroidJUnit4
Instrumented tests run with `AndroidJUnit4` and have access to a real `Context`, real storage, and real UI thread rules.
```kotlin
@RunWith(AndroidJUnit4::class)
class SettingsDataStoreTest {
    @Test fun savesAndReadsTheme() = runBlocking {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val store = SettingsStore(context)
        store.setDarkMode(true)
        assertThat(store.darkMode.first()).isTrue()
    }
}
```
Run them with `./gradlew connectedAndroidTest`. In CI use a managed device, Firebase Test Lab, or an emulator with hardware acceleration. Shard large suites and always save failure screenshots and logcat.
## 5. Robolectric: fast tests with Android APIs
Robolectric 4.17 runs Android framework code on the JVM with shadows, so many tests that would need an emulator run in seconds. It is a good middle layer for Activity launch, Room, and resource loading.
```kotlin
testImplementation("org.robolectric:robolectric:4.17") // build.gradle.kts
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class MainActivityTest {
    @Test fun activity_showsTitle() {
        val scenario = ActivityScenario.launch(MainActivity::class.java)
        scenario.onActivity { assertThat(it.title.toString()).isEqualTo("Notes") }
    }
}
```
Limits: Robolectric is not a real device. Pixel rendering, sensors, Bluetooth, and exact timing still need instrumented tests. Site: https://robolectric.org/
## 6. UI tests: Espresso for Views
Espresso 3.7 is for View-based UI only. It waits for the UI thread to be idle before acting, which reduces flaky tests.
```kotlin
androidTestImplementation("androidx.test.espresso:espresso-core:3.7.0")
@Test fun typingName_showsGreeting() {
    onView(withId(R.id.nameField)).perform(typeText("Ada"), closeSoftKeyboard())
    onView(withId(R.id.saveButton)).perform(click())
    onView(withText("Hello, Ada")).check(matches(isDisplayed()))
}
```
Use `ViewMatchers`, keep selectors stable, and avoid `Thread.sleep`. For lists use `RecyclerViewActions`; for web content use Espresso Web. Do not use Espresso to test Compose UI — use the Compose test APIs below. Guide: https://developer.android.com/training/testing/espresso
## 7. UI tests: Compose with ui-test-junit4
Compose tests use semantics, not view IDs. Find nodes by text, content description, role, or a test tag.
```kotlin
androidTestImplementation("androidx.compose.ui:ui-test-junit4")
debugImplementation("androidx.compose.ui:ui-test-manifest")
class CounterScreenTest {
    @get:Rule val composeRule = createComposeRule()
    @Test fun increment_updatesLabel() {
        composeRule.setContent { CounterScreen() }
        composeRule.onNodeWithText("Count: 0").assertIsDisplayed()
        composeRule.onNodeWithText("Increment").performClick()
        composeRule.onNodeWithText("Count: 1").assertIsDisplayed()
    }
    @Test fun button_isEnabledAndClickable() {
        composeRule.setContent { CounterScreen() }
        composeRule.onNodeWithTag("increment").assertIsEnabled().assertHasClickAction()
    }
}
```
Use `onNodeWithTag` sparingly for elements with no good semantic label; prefer text and content description, which also help accessibility. For a full app use `createAndroidComposeRule<MainActivity>()`.
Guides: https://developer.android.com/jetpack/compose/testing · https://developer.android.com/jetpack/compose/testing-cheatsheet
## 8. Screenshot testing
Screenshot tests catch layout, theme, font, and locale regressions that assertions miss.
**Roborazzi** captures Compose and View screenshots in local Robolectric tests, so they run fast without an emulator:
```kotlin
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(sdk = [34], qualifiers = "w400dp-h800dp")
class ProfileScreenshotTest {
    @get:Rule val roborazziRule = RoborazziRule(options = RoborazziRule.Options())
    @Test fun profile_light() {
        captureRoboImage { ProfileScreen(user = sampleUser, dark = false) }
    }
}
```
Record references with `./gradlew recordRoborazziDebug` and verify in CI with `./gradlew verifyRoborazziDebug`. Commit the reference images. Project: https://github.com/takahirom/roborazzi
**Compose Preview Screenshot Testing** is an experimental Android Studio / AGP tool that turns `@Preview` functions into screenshot tests. Enable it per the official guide, keep previews small and deterministic (fixed data, fixed clock, no network), and treat its status as experimental — APIs and tasks may change between versions. Guide: https://developer.android.com/studio/preview/compose-screenshot-testing
Cover at least light and dark theme, large font, a long-text locale, and the smallest supported width for each main screen.
## 9. Performance tests in the strategy
Performance is a test concern, not a final check. Add Macrobenchmark tests for cold startup and a key scroll journey, Baseline Profile generation verified by a benchmark that runs with and without the profile, and startup/frame budgets that fail CI when they regress beyond an agreed threshold. Details: https://developer.android.com/topic/performance/benchmarking/macrobenchmark-overview
## 10. CI setup
A practical pipeline:
1. Lint, unit tests, and Robolectric tests on every pull request.
2. Screenshot verify on every pull request.
3. Instrumented tests on an emulator or managed devices nightly and on release branches.
4. Macrobenchmark on a physical device lab weekly or before release.
5. Publish test reports, screenshots, and logcat as build artifacts.
6. Fail the build on a failed test — never mark a flaky test as passed. Quarantine a flaky test with an issue, fix it, and restore it.
Use Gradle test sharding, use retry only to collect flakiness data, and keep total pull request feedback under about 15 minutes where possible. Managed devices: https://developer.android.com/studio/test/gradle-managed-devices
## Checklist
- [ ] Every ViewModel and repository has JVM unit tests with fakes.
- [ ] Room, DataStore, and navigation have integration coverage.
- [ ] Main user journeys have Compose or Espresso UI tests.
- [ ] Main screens have screenshot tests in light, dark, and large font.
- [ ] Cold start has a Macrobenchmark and a Baseline Profile.
- [ ] CI saves reports and screenshots for every failure.
