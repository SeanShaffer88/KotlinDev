# Architecture Patterns

Good architecture keeps an app testable and changeable as it grows.
This guide follows the official Android app architecture guidance:
a UI layer, a data layer, an optional domain layer, unidirectional
data flow, and offline-first data where it matters.

Official references:
- Guide to app architecture: https://developer.android.com/topic/architecture
- UI layer: https://developer.android.com/topic/architecture/ui-layer
- Data layer: https://developer.android.com/topic/architecture/data-layer
- Domain layer: https://developer.android.com/topic/architecture/domain-layer
- Modularization: https://developer.android.com/topic/modularization

## The Layers

```
UI layer        — screens, ViewModels, UI state (Compose observes it)
Domain layer    — use cases (optional; shared business logic)
Data layer      — repositories, data sources (network, database, files)
```

Data flows up as observable streams; events flow down as function
calls. Each layer depends only on the layer below it.

## UI Layer and MVVM

The standard pattern is MVVM: a ViewModel holds screen state and
exposes it as a `StateFlow` of immutable UI state. The UI renders
state and sends user events to the ViewModel.

```kotlin
data class HomeUiState(
    val isLoading: Boolean = false,
    val items: List<Item> = emptyList(),
    val errorMessage: String? = null
)

@HiltViewModel
class HomeViewModel @Inject constructor(
    private val repository: ItemRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(HomeUiState())
    val uiState: StateFlow<HomeUiState> = _uiState.asStateFlow()

    init { load() }

    fun load() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, errorMessage = null) }
            runCatching { repository.getItems() }
                .onSuccess { items ->
                    _uiState.update { it.copy(isLoading = false, items = items) }
                }
                .onFailure { e ->
                    _uiState.update { it.copy(isLoading = false, errorMessage = e.message) }
                }
        }
    }
}
```

Rules:

- One UI state object per screen (or a small set of flows combined
  into one). The UI must be renderable from state alone.
- The ViewModel never holds Views, Composables, or Contexts (an
  Application context through DI is acceptable where required).
- User actions are ViewModel functions: `onSaveClick`, `onQueryChange`.

## Unidirectional Data Flow (UDF)

UDF means state has one source and changes in one direction:

1. UI sends an event to the ViewModel.
2. ViewModel (through repositories) updates the data.
3. New state flows back to the UI, which re-renders.

UDF makes bugs traceable: if the UI is wrong, the state is wrong, and
there is exactly one place that produces state. Never mutate shared
state from the UI directly.

## MVI — When It Fits

MVI (Model-View-Intent) is a stricter UDF variant: all events go
through one `onEvent(intent)` entry point and state changes happen
in a single reducer. Consider MVI when:

- A screen has many interacting event sources.
- You need an auditable event log for debugging or replay.
- A team already standardizes on it.

For most screens, plain MVVM with explicit event functions is
simpler and equally safe. Do not adopt MVI machinery (stores,
reducers, effect channels) for a two-button screen.

## Data Layer and Repositories

A repository is the single source of truth for one kind of data. It
hides where data comes from — network, cache, or database — behind
a clean API of flows and suspend functions.

```kotlin
interface ItemRepository {
    fun observeItems(): Flow<List<Item>>
    suspend fun refresh()
    suspend fun getItem(id: Long): Item?
}

class DefaultItemRepository(
    private val api: ItemApi,
    private val dao: ItemDao,
    private val ioDispatcher: CoroutineDispatcher
) : ItemRepository {
    override fun observeItems(): Flow<List<Item>> =
        dao.observeAll().map { rows -> rows.map { it.toDomain() } }

    override suspend fun refresh() = withContext(ioDispatcher) {
        val remote = api.fetchItems()
        dao.replaceAll(remote.map { it.toEntity() })
    }

    override suspend fun getItem(id: Long): Item? =
        dao.getById(id)?.toDomain()
}
```

- Expose the repository as an interface; bind the implementation
  through dependency injection. Tests substitute a fake.
- Map between network DTOs, database entities, and domain models.
  Never let a DTO leak into the UI layer.
- The UI never calls an API client or DAO directly.

## Domain Layer and Use Cases

The domain layer is optional. Add use cases when business logic is
shared by several ViewModels or grows complex enough to deserve its
own tests.

```kotlin
class GetSortedItemsUseCase(
    private val repository: ItemRepository
) {
    operator fun invoke(): Flow<List<Item>> =
        repository.observeItems().map { items ->
            items.sortedBy { it.name }
        }
}
```

Skip the domain layer for a small app — repositories plus ViewModels
are enough. Add it when duplication appears, not in advance.

## Offline-First

Offline-first means the local database is the source of truth the UI
reads, and the network refreshes it in the background:

1. UI observes Room through the repository — it always has data to
   show, even offline.
2. A refresh fetches remote data and writes it into Room.
3. Room emits, the UI updates. No spinner-driven screens after the
   first load.

Write conflicts and sync rules (last-write-wins, server wins, queued
mutations) must be decided per data type and documented. Use
WorkManager for reliable background sync with retry and constraints.

## Modularization

Split code into modules when a single `:app` module gets slow to
build or hard to navigate. Common pattern (see the setup guide):
`:app`, `:core:*` shared modules, and one module per feature.

- Features expose only their navigation entry and public API.
- Features never depend on each other; shared needs go in core.
- Modularization pays off at scale and costs indirection at small
  size. A three-screen app in nine modules is over-engineered.

## State Holders Beyond ViewModel

Small, reusable UI logic (a searchable list header, a text field
with validation) can live in a plain state holder class remembered
in Compose, separate from the screen ViewModel. Keep screen and
business state in the ViewModel; keep purely presentational state
(scroll, expansion, draft text) close to the UI.

## Testing Shape

Architecture exists to make testing possible:

- ViewModels: unit test with fake repositories and a test dispatcher.
- Repositories: unit test with fake APIs and in-memory Room.
- Use cases: pure unit tests, no Android dependencies.
- UI: Compose tests drive the stateless screen with fixed state.

If a class cannot be tested without the whole app, a boundary is in
the wrong place.

## Anti-Patterns

- **God Activity / God ViewModel** — one class knowing everything.
- **Logic in composables** — network or database calls in UI code.
- **Repository per screen** — repositories are per data type.
- **Exposing mutable state** — publish `StateFlow`, keep the
  `MutableStateFlow` private.
- **Skipping the repository** "just for this one call" — that call
  becomes five, each with its own caching and error behavior.
