# Dependency Injection

Dependency injection (DI) means a class receives the objects it needs
from outside instead of creating them itself. That one habit makes
code testable, swappable, and honest about what it depends on.

Official references:
- DI on Android: https://developer.android.com/training/dependency-injection
- Hilt: https://developer.android.com/training/dependency-injection/hilt-android
- Hilt cheat sheet: https://developer.android.com/training/dependency-injection/hilt-android#hilt-cheat-sheet
- Koin for Android: https://insert-koin.io/docs/reference/koin-android/

## Manual DI — Always an Option

Manual DI is constructor parameters plus a container you write. For
small apps it is enough, and every developer should understand it
before using a framework.

```kotlin
class AppContainer(context: Context) {
    private val database: AppDatabase by lazy { buildDatabase(context) }
    val itemRepository: ItemRepository by lazy {
        DefaultItemRepository(api = RetrofitItemApi.create(), dao = database.itemDao())
    }
}

// Usage in a ViewModel factory or Composition root:
val viewModel = HomeViewModel(container.itemRepository)
```

Constructor injection is the core idea, with or without a framework:

```kotlin
class CheckoutViewModel(
    private val cartRepository: CartRepository,
    private val payments: PaymentGateway
) : ViewModel()
```

Never use service-locator calls scattered through business logic
(`App.instance.repository`) — the dependency becomes invisible and
untestable.

## Hilt — The Recommended Framework

Hilt is the standard DI library for Android, built on Dagger. It
generates the wiring code from annotations. Verified versions for
this knowledge base: androidx.hilt 1.4.0 and Dagger Hilt 2.57.x.
Use KSP for Hilt's compiler — not kapt — in new projects.

Setup sketch:

```kotlin
// Application
@HiltAndroidApp
class MyApplication : Application()

// Activity
@AndroidEntryPoint
class MainActivity : ComponentActivity()

// ViewModel
@HiltViewModel
class HomeViewModel @Inject constructor(
    private val repository: ItemRepository
) : ViewModel()
```

Provide dependencies Hilt cannot construct itself (interfaces,
library classes) in modules:

```kotlin
@Module
@InstallIn(SingletonComponent::class)
abstract class RepositoryModule {
    @Binds
    abstract fun bindItemRepository(impl: DefaultItemRepository): ItemRepository
}

@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {
    @Provides
    @Singleton
    fun provideApi(): ItemApi = RetrofitItemApi.create()
}
```

- `@Binds` — bind an implementation to its interface (preferred,
  less generated code).
- `@Provides` — build an object with a function body.
- Install components decide lifetime: `SingletonComponent` lives as
  long as the app; `ActivityComponent` and `ViewModelComponent` are
  scoped shorter.

## Scoping

A scope controls how many instances exist and how long they live.

```kotlin
@Singleton
class AnalyticsTracker @Inject constructor() { /* one for the app */ }

@ActivityScoped
class ShareHelper @Inject constructor() { /* one per Activity */ }
```

Rules:

- Unscoped (no annotation) means a new instance at each injection
  site — right for cheap, stateless helpers.
- Scope deliberately. Making everything `@Singleton` creates hidden
  shared mutable state and memory that never clears.
- Never inject a short-lived scoped object into a longer-lived one;
  Hilt reports this as a compile error, which is a feature.

Compose integration: obtain Hilt ViewModels with
`hiltViewModel()` from `androidx.hilt.lifecycle.viewmodel.compose`
inside a navigation destination or route composable.

```kotlin
@Composable
fun HomeRoute(viewModel: HomeViewModel = hiltViewModel()) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()
    HomeScreen(state)
}
```

## Koin — The KMP-Friendly Alternative

Koin (4.x) is a lightweight, pure-Kotlin DI library with no code
generation. It is popular in Kotlin Multiplatform projects because
it works identically on Android and other targets.

```kotlin
val dataModule = module {
    single<ItemRepository> { DefaultItemRepository(get(), get()) }
    factory { ItemApi.create() }
}
val uiModule = module {
    viewModel { HomeViewModel(get()) }
}

// Application.onCreate:
startKoin {
    androidContext(this@MyApplication)
    modules(dataModule, uiModule)
}

// In Compose:
val viewModel: HomeViewModel = koinViewModel()
```

Trade-offs versus Hilt:

- Koin resolves at runtime — a missing binding fails at runtime,
  not compile time. Its verification tools (`checkModules`) help in
  tests.
- Hilt checks the graph at compile time and is the official
  recommendation for Android-only apps.
- Choose Koin when KMP sharing is a real requirement, or a team
  already standardizes on it. Choose Hilt otherwise.

## Testing with DI

DI pays off in tests: replace real dependencies with fakes.

```kotlin
class FakeItemRepository : ItemRepository {
    private val items = MutableStateFlow<List<Item>>(emptyList())
    override fun observeItems(): Flow<List<Item>> = items
    suspend fun add(item: Item) { items.value += item }
    override suspend fun refresh() {}
    override suspend fun getItem(id: Long) = items.value.find { it.id == id }
}

@Test
fun loadsItems() = runTest {
    val fake = FakeItemRepository()
    val vm = HomeViewModel(fake)
    assertTrue(vm.uiState.value.items.isEmpty())
}
```

With Hilt, use `@TestInstallIn` to swap modules in instrumented
tests, and prefer constructing ViewModels directly with fakes in
plain unit tests — no framework needed for the fastest tests.

## Decision Guide

| Situation | Choice |
|-----------|--------|
| Tiny app or sample | Manual DI |
| Android app, any real size | Hilt |
| Kotlin Multiplatform shared DI | Koin |
| Learning DI concepts | Manual first, then Hilt |

## Common Mistakes

- Field injection everywhere instead of constructor injection.
- Scoping everything as singleton.
- Putting business logic inside `@Provides` functions — modules
  wire objects; they do not implement features.
- Two DI systems in one app. Pick one and remove the other.
- Injecting `Context` broadly. Inject the narrowest thing needed,
  and prefer the Application context for singletons to avoid leaking
  an Activity.
