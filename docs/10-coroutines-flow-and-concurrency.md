# Coroutines, Flow, and Concurrency

Kotlin coroutines are the standard way to do asynchronous work on
Android without blocking the UI thread. Flow adds an observable
stream on top. Together they cover networking, databases, UI state,
and events.

Official references:
- Coroutines on Android: https://developer.android.com/kotlin/coroutines
- Kotlin coroutines guide: https://kotlinlang.org/docs/coroutines-guide.html
- Flow: https://developer.android.com/kotlin/flow
- Testing coroutines: https://developer.android.com/kotlin/coroutines/test

Verified version: kotlinx.coroutines 1.11.0. Use the matched set —
`kotlinx-coroutines-core`, `kotlinx-coroutines-android`, and
`kotlinx-coroutines-test` all at the same version. A version mismatch
between core and test artifacts is a common source of strange errors.

## Suspend Functions

A `suspend` function can pause without blocking a thread. It must be
called from a coroutine or another suspend function.

```kotlin
suspend fun loadUser(id: Long): User {
    return api.fetchUser(id)      // network call, main-safe by design
}

class UserRepository(private val api: UserApi) {
    suspend fun user(id: Long): User = withContext(Dispatchers.IO) {
        api.fetchUserBlocking(id) // blocking library moved off main
    }
}
```

Design data-layer functions to be **main-safe**: callers on the main
thread should not need to think about threading. The data layer
switches dispatchers internally.

## Dispatchers

A dispatcher decides which thread pool a coroutine runs on:

- `Dispatchers.Main` — UI thread. All UI updates and most app code.
- `Dispatchers.IO` — blocking I/O: files, databases, blocking network.
- `Dispatchers.Default` — CPU-heavy work: sorting, parsing, image work.
- `Dispatchers.Unconfined` — testing and special cases only.

```kotlin
suspend fun parseLargeFile(file: File): Report =
    withContext(Dispatchers.Default) { heavyParse(file) }
```

Inject dispatchers into repositories instead of hardcoding them, so
tests can substitute a test dispatcher.

## Structured Concurrency

Coroutines live inside a scope with a lifetime. When the scope is
cancelled, its children are cancelled. This prevents leaks.

Android provides scopes tied to lifecycles:

- `viewModelScope` — cancelled when the ViewModel clears. The default
  for ViewModel work.
- `lifecycleScope` — in Activities and Fragments, cancelled on destroy.
- Application-level scope — create one deliberately in the Application
  or a singleton for work that must outlive screens, and own it.

```kotlin
class HomeViewModel(private val repo: ItemRepository) : ViewModel() {
    fun refresh() {
        viewModelScope.launch {
            repo.refresh()   // auto-cancelled if the screen goes away
        }
    }
}
```

Rules:

- Never use `GlobalScope`. It has no lifetime and leaks by design.
- `launch` starts work whose result you do not need (returns a Job).
- `async` starts work whose result you need (returns a Deferred);
  always `await` it inside the same structured scope.
- Exceptions in `launch` propagate to the scope's handler; exceptions
  in `async` surface at `await`. Use `supervisorScope` only when one
  child's failure must not cancel its siblings, and handle errors
  explicitly there.

```kotlin
suspend fun loadDashboard(): Dashboard = coroutineScope {
    val user = async { api.fetchUser() }
    val feed = async { api.fetchFeed() }
    Dashboard(user.await(), feed.await())   // parallel, structured
}
```

## Flow Basics

A `Flow<T>` is a cold stream: it produces values only while collected,
and restarts for each collector. Perfect for database observation and
search-as-you-type.

```kotlin
fun search(query: String): Flow<List<Item>> =
    dao.search(query).map { rows -> rows.map { it.toDomain() } }

val debounced: Flow<String> = queryFlow
    .debounce(300)
    .distinctUntilChanged()
    .flatMapLatest { search(it) }
```

Useful operators: `map`, `filter`, `combine`, `flatMapLatest`,
`debounce`, `distinctUntilChanged`, `catch`, `onStart`, `onEach`,
and `stateIn` / `shareIn`.

## StateFlow and SharedFlow

- **StateFlow** — holds one current value, always has a value, and
  conflates (slow collectors skip intermediates). This is the UI
  state holder: `val uiState: StateFlow<UiState>`.
- **SharedFlow** — a broadcast stream with configurable replay and
  buffer. Use it for one-shot events consumers may briefly miss
  (with `replay = 0` and careful design), or shared expensive streams.

```kotlin
private val _uiState = MutableStateFlow(HomeUiState())
val uiState: StateFlow<HomeUiState> = _uiState.asStateFlow()

fun onRetry() { _uiState.update { it.copy(isLoading = true) } }
```

Prefer modeling one-shot effects (snackbars, navigation) as state
the UI consumes and clears, rather than event streams — state
survives rotation and is easier to test. When you do need events,
a `SharedFlow` with explicit acknowledgement or a `Channel` consumed
as flow is the common pattern.

## Collecting in the UI

In Compose, collect with lifecycle awareness:

```kotlin
val state by viewModel.uiState.collectAsStateWithLifecycle()
```

In Views code, collect inside `repeatOnLifecycle(STARTED)` so
collection pauses when the UI is hidden. Collecting a flow in a bare
`lifecycleScope.launch` without lifecycle repetition wastes work and
can update hidden UI.

Convert a cold flow to state at the ViewModel boundary with
`stateIn`:

```kotlin
val items: StateFlow<List<Item>> = repo.observeItems()
    .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())
```

`WhileSubscribed(5000)` keeps the upstream alive briefly across
configuration changes, avoiding restart churn on rotation.

## Testing Coroutines and Flow

Use `kotlinx-coroutines-test` (same 1.11.0 version) and Turbine for
flow assertions.

```kotlin
@Test
fun refreshUpdatesState() = runTest {
    val repo = FakeItemRepository()
    val vm = HomeViewModel(repo)
    vm.refresh()
    advanceUntilIdle()
    assertFalse(vm.uiState.value.isLoading)
}

@Test
fun emitsLoadingThenContent() = runTest {
    vm.uiState.test {
        assertEquals(HomeUiState(isLoading = true), awaitItem())
        // trigger load, then:
        assertTrue(awaitItem().items.isNotEmpty())
        cancelAndIgnoreRemainingEvents()
    }
}
```

- `runTest` runs suspend code on a test dispatcher with a virtual
  clock — delays are skipped, not waited through.
- Set `Dispatchers.setMain(StandardTestDispatcher())` when code uses
  `viewModelScope`, and reset it afterwards.
- Turbine's `test { awaitItem() }` is the readable way to assert a
  sequence of flow emissions.

## Common Mistakes

- Blocking the main thread with network, database, or file work.
- `GlobalScope.launch` for anything.
- Swallowing `CancellationException` in a broad `catch (Exception)` —
  always rethrow it so structured concurrency keeps working.
- Collecting the same cold flow in several places and duplicating
  its work; share it with `shareIn` or `stateIn`.
- Using `SharedFlow` for UI state (no guaranteed current value) or
  `StateFlow` for events that must never be conflated away.
- Mismatched coroutines artifact versions between main and test.
