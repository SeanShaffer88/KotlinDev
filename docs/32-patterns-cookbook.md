# Patterns Cookbook

Short, copy-adaptable recipes for problems nearly every Kotlin
Android app hits. Each recipe is a sketch: adapt names, models,
and error handling to your project, and verify library versions
against the official release pages before pinning.

## 1. Offline-First Repository

UI reads the local database. Network refreshes the database.
The UI never talks to the network directly.

```kotlin
class ArticleRepository(
    private val dao: ArticleDao,
    private val api: ArticleApi,
    private val io: CoroutineDispatcher = Dispatchers.IO
) {
    val articles: Flow<List<Article>> =
        dao.observeAll().map { rows -> rows.map { it.toDomain() } }

    suspend fun refresh() = withContext(io) {
        val remote = api.fetchArticles() // throws on failure
        dao.replaceAll(remote.map { it.toEntity() })
    }
}
```

## 2. Paging with Paging 3

For long lists backed by network and/or Room. Paging 3 current
line at time of writing: **3.5.3** in the `3.5.x` series —
verify on the AndroidX Paging release page before pinning.

```kotlin
class ArticlePagingSource(private val api: ArticleApi) : PagingSource<Int, Article>() {
    override fun getRefreshKey(state: PagingState<Int, Article>) =
        state.anchorPosition?.let { pos ->
            state.closestPageToPosition(pos)?.prevKey?.plus(1)
                ?: state.closestPageToPosition(pos)?.nextKey?.minus(1)
        }

    override suspend fun load(params: LoadParams<Int>): LoadResult<Int, Article> {
        val page = params.key ?: 1
        return try {
            val data = api.fetchPage(page, params.loadSize)
            LoadResult.Page(
                data = data,
                prevKey = if (page == 1) null else page - 1,
                nextKey = if (data.isEmpty()) null else page + 1
            )
        } catch (e: IOException) {
            LoadResult.Error(e)
        }
    }
}

val pagerFlow: Flow<PagingData<Article>> = Pager(
    config = PagingConfig(pageSize = 20, enablePlaceholders = false),
    pagingSourceFactory = { ArticlePagingSource(api) }
).flow.cachedIn(viewModelScope)
```


## 3. Search with Debounced Flow

Wait until typing pauses, skip duplicate queries, cancel the
previous search when a new one starts.

```kotlin
class SearchViewModel(private val repo: SearchRepository) : ViewModel() {
    private val queries = MutableStateFlow("")
    val results: StateFlow<List<Result>> = queries
        .debounce(300)
        .map { it.trim() }
        .distinctUntilChanged()
        .flatMapLatest { q ->
            if (q.length < 2) flowOf(emptyList())
            else flow { emit(repo.search(q)) }
        }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    fun onQueryChange(text: String) { queries.value = text }
}
```

## 4. Upload with WorkManager

Uploads must survive process death and bad networks. WorkManager
with constraints and backoff is the tool.

```kotlin
class UploadWorker(
    context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {
    override suspend fun doWork(): Result {
        val fileId = inputData.getString(KEY_FILE_ID) ?: return Result.failure()
        return try {
            uploader.upload(fileId)
            Result.success()
        } catch (e: IOException) {
            if (runAttemptCount < 3) Result.retry() else Result.failure()
        }
    }
    companion object { const val KEY_FILE_ID = "file_id" }
}

fun enqueueUpload(context: Context, fileId: String) {
    val request = OneTimeWorkRequestBuilder<UploadWorker>()
        .setConstraints(
            Constraints.Builder()
                .setRequiredNetworkType(NetworkType.CONNECTED)
                .build()
        )
        .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 30, TimeUnit.SECONDS)
        .setInputData(workDataOf(UploadWorker.KEY_FILE_ID to fileId))
        .build()
    WorkManager.getInstance(context)
        .enqueueUniqueWork("upload-$fileId", ExistingWorkPolicy.KEEP, request)
}
```

## 5. In-App Update (Play Core)

Prompt for updates through Play instead of shipping your own
updater. Use the Play In-App Updates API (AppUpdateManager).

```kotlin
val updateManager = AppUpdateManagerFactory.create(context)
updateManager.appUpdateInfo.addOnSuccessListener { info ->
    if (info.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE &&
        info.isUpdateTypeAllowed(AppUpdateType.FLEXIBLE)
    ) {
        updateManager.startUpdateFlowForResult(
            info, AppUpdateType.FLEXIBLE, activity, REQUEST_CODE
        )
    }
}
```

Flexible for minor updates (downloads in background), Immediate
for critical fixes. Always handle the user declining: the app
must keep working on the old version unless policy truly forbids it.

## 6. Deep Link Handling

Declare intent filters for your links, prefer App Links
(verified https links) over custom schemes, and route in
navigation.

```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="https" android:host="example.com" android:pathPrefix="/item/" />
</intent-filter>
```

```kotlin
// Navigation Compose destination with a deep link
composable(
    route = "item/{id}",
    deepLinks = listOf(navDeepLink { uriPattern = "https://example.com/item/{id}" })
) { entry -> ItemScreen(id = entry.arguments?.getString("id").orEmpty()) }
```

Host `assetlinks.json` on the domain for verification. Test
links with `adb shell am start -a android.intent.action.VIEW -d <url>`.

## 7. Error UI State

One sealed state type per screen keeps loading, content, and
error handling honest.

```kotlin
sealed interface UiState<out T> {
    data object Loading : UiState<Nothing>
    data class Data<T>(val value: T) : UiState<T>
    data class Error(val message: String, val retry: () -> Unit) : UiState<Nothing>
}

@Composable
fun <T> StateHost(state: UiState<T>, content: @Composable (T) -> Unit) {
    when (state) {
        is UiState.Loading -> LoadingIndicator()
        is UiState.Error -> ErrorPanel(state.message, state.retry)
        is UiState.Data -> content(state.value)
    }
}
```

Error messages say what happened and what to do next, in plain
words. Never show a raw exception message to the user.

## 8. Settings Screen with DataStore

```kotlin
val Context.store by preferencesDataStore(name = "settings")
val KEY_DARK = booleanPreferencesKey("dark_mode")
val KEY_NAME = stringPreferencesKey("display_name")

class SettingsRepository(private val context: Context) {
    val settings: Flow<Settings> = context.store.data.map { prefs ->
        Settings(darkMode = prefs[KEY_DARK] ?: false, name = prefs[KEY_NAME] ?: "")
    }
    suspend fun setDarkMode(enabled: Boolean) {
        context.store.edit { it[KEY_DARK] = enabled }
    }
    suspend fun setName(name: String) {
        context.store.edit { it[KEY_NAME] = name }
    }
}

@Composable
fun SettingsScreen(repo: SettingsRepository) {
    val settings by repo.settings.collectAsStateWithLifecycle(
        initialValue = Settings(darkMode = false, name = "")
    )
    val scope = rememberCoroutineScope()
    Switch(
        checked = settings.darkMode,
        onCheckedChange = { scope.launch { repo.setDarkMode(it) } }
    )
}
```

## Recipe Rules

- Every recipe assumes coroutines + Flow; add the lifecycle
  collection (`collectAsStateWithLifecycle`) in real screens.
- Versions shown are orientation, not gospel: check the
  library's release page on the day you copy a recipe.
- Add the failure path before the happy path ships. Every
  recipe above has one — keep it when you adapt the code.

## Official Links

- Paging: https://developer.android.com/topic/libraries/architecture/paging/v3-overview
- WorkManager: https://developer.android.com/topic/libraries/architecture/workmanager
- In-app updates: https://developer.android.com/guide/playcore/in-app-updates
- App Links: https://developer.android.com/training/app-links
- DataStore: https://developer.android.com/topic/libraries/architecture/datastore
- Flow: https://developer.android.com/kotlin/flow
