# Networking: Retrofit, Ktor Client, and kotlinx.serialization

Most Android apps talk to a web API over HTTPS. This guide covers the two most common Kotlin stacks, how to share one model layer between them, and how to handle caching, errors, and secrets safely.

- **Retrofit 3.0.0 + OkHttp 5.5.1** — Android-only, the default choice for a single-platform app.
- **Ktor Client 3.x** — Kotlin Multiplatform (KMP), the choice when code is shared with iOS, desktop, or server targets.
- **kotlinx.serialization** — works with both, and is the only serializer that runs natively in KMP code.

## 1. Pick a stack

| Question | Retrofit | Ktor Client |
| --- | --- | --- |
| Platforms | Android / JVM only | Android, iOS, JVM, JS, Wasm |
| Engine | OkHttp, always | Pluggable: OkHttp, Darwin, CIO |
| API style | Annotated interfaces | DSL calls, typed extensions |
| Learning curve | Low | Medium |
| Best for | Android-only apps | Shared KMP modules |

Do not mix both in one app without a reason. Pick one, wrap it behind a small repository interface, and keep the rest of the app unaware of which library is underneath.

## 2. Dependencies

Versions used in this guide: Retrofit 3.0.0, OkHttp 5.5.1, Ktor Client 3.x, kotlinx.serialization 1.x.

```kotlin
// build.gradle.kts — Retrofit (Android app module)
dependencies {
    implementation("com.squareup.retrofit2:retrofit:3.0.0")
    implementation("com.squareup.okhttp3:okhttp:5.5.1")
    implementation("com.squareup.okhttp3:logging-interceptor:5.5.1")
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.9.0")
    implementation("com.squareup.retrofit2:converter-kotlinx-serialization:3.0.0")
}
```

```kotlin
// build.gradle.kts — Ktor Client (KMP commonMain)
dependencies {
    implementation("io.ktor:ktor-client-core:3.3.0")
    implementation("io.ktor:ktor-client-content-negotiation:3.3.0")
    implementation("io.ktor:ktor-serialization-kotlinx-json:3.3.0")
    implementation("io.ktor:ktor-client-okhttp:3.3.0") // Android engine, in androidMain
    implementation("io.ktor:ktor-client-darwin:3.3.0") // iOS engine, in iosMain
}
```

Pin versions in a version catalog (`gradle/libs.versions.toml`) so every module agrees. See the version catalog guide in this series.
## 3. Models with kotlinx.serialization

One model definition serves both stacks and every platform.

```kotlin
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
@Serializable
data class ArticleDto(
    val id: Long, val title: String,
    @SerialName("published_at") val publishedAt: String,
    val summary: String? = null, // null when the server omits it
)
```

Rules that prevent most parsing bugs:

- Mark every network model `@Serializable`. Keep DTOs separate from UI models and map between them.
- Give nullable fields a default of `null` so missing keys do not crash parsing.
- Use `@SerialName` when the JSON name is not a valid or idiomatic Kotlin name.
- Configure `Json { ignoreUnknownKeys = true }` so a new server field does not break older app versions.
- Never parse JSON with string splitting or regular expressions.

Configure it once: `val json = Json { ignoreUnknownKeys = true; explicitNulls = false; coerceInputValues = true }`.

## 4. Retrofit: define the API as an interface

```kotlin
import retrofit2.http.GET
import retrofit2.http.Path
import retrofit2.http.Query
interface NewsApi {
    @GET("articles") suspend fun articles(@Query("page") page: Int): List<ArticleDto>
    @GET("articles/{id}") suspend fun article(@Path("id") id: Long): ArticleDto
}
```

```kotlin
import com.jakewharton.retrofit2.converter.kotlinx.serialization.asConverterFactory
import okhttp3.MediaType.Companion.toMediaType
import retrofit2.Retrofit

val retrofit = Retrofit.Builder()
    .baseUrl("https://api.example.com/v1/") // must end with /
    .client(okHttpClient)
    .addConverterFactory(json.asConverterFactory("application/json".toMediaType()))
    .build()
val api = retrofit.create(NewsApi::class.java)
```

Use `suspend` functions. Retrofit runs them on a background dispatcher and returns the result on the caller's dispatcher.

## 5. Ktor Client: one client, reused everywhere

```kotlin
import io.ktor.client.HttpClient
import io.ktor.client.call.body
import io.ktor.client.plugins.contentnegotiation.ContentNegotiation
import io.ktor.client.request.get
import io.ktor.client.request.parameter
import io.ktor.serialization.kotlinx.json.json
val client = HttpClient(OkHttp) { // engine differs per platform
    install(ContentNegotiation) { json(json) }
    expectSuccess = false // handle status codes yourself, see section 8
}

suspend fun articles(page: Int): List<ArticleDto> =
    client.get("https://api.example.com/v1/articles") {
        parameter("page", page)
    }.body()
```

Create the client once and inject it. Creating a client per request wastes connections and threads.

## 6. OkHttp interceptors

Interceptors see every request and response. Use them for headers, logging (debug builds only), and retry policy — not for business logic.

```kotlin
import okhttp3.Interceptor
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor

val authInterceptor = Interceptor { chain ->
    val request = chain.request().newBuilder()
        .header("Accept", "application/json")
        // Token comes from secure storage at runtime, never source code.
        .header("Authorization", "Bearer ${tokenProvider.current()}")
        .build()
    chain.proceed(request)
}

val okHttpClient = OkHttpClient.Builder().addInterceptor(authInterceptor).apply {
    if (BuildConfig.DEBUG) addInterceptor(HttpLoggingInterceptor().apply {
        level = HttpLoggingInterceptor.Level.BASIC; redactHeader("Authorization")
    })
}.build()
```

Ktor has the same idea: use `defaultRequest { header(...) }` and the `Logging`, `Auth`, and `HttpRequestRetry` plugins.

## 7. Caching

Two layers, used together:

1. **HTTP cache** — OkHttp caches responses that carry cache headers. Give it a bounded disk cache, for example 10 MB.
2. **App cache** — store the last good response in Room or a file, and show it while a fresh request runs or when the device is offline.

```kotlin
import okhttp3.Cache
import java.io.File
val cache = Cache(File(context.cacheDir, "http_cache"), 10L * 1024 * 1024)
val cachedClient = okHttpClient.newBuilder().cache(cache).build()
```

Respect the server's `Cache-Control` headers. Do not cache responses that contain private user data on a shared cache key, and never cache `POST` results by hand unless the API defines it as safe.

## 8. Error modelling

Callers should get a small, typed result — not raw exceptions from three different layers.

```kotlin
sealed interface ApiResult<out T> {
    data class Success<T>(val data: T) : ApiResult<T>
    data class HttpError(val code: Int, val message: String?) : ApiResult<Nothing>
    data object Offline : ApiResult<Nothing>
    data class Unknown(val cause: Throwable) : ApiResult<Nothing>
}

suspend fun <T> safeCall(block: suspend () -> T): ApiResult<T> = try {
    ApiResult.Success(block())
} catch (e: IOException) { ApiResult.Offline
} catch (e: HttpException) { ApiResult.HttpError(e.code(), e.response()?.errorBody()?.string())
} catch (e: Exception) { ApiResult.Unknown(e) }
```

Guidance:

- Map 401 to a re-login flow, 404 to an empty state, 429 and 5xx to a retry with backoff, and other 4xx to a message the user can act on.
- Retry only idempotent requests (safe to repeat), such as `GET`.
- Show a plain-language message in the UI; log the technical detail.
- Test the error paths with a fake server or MockWebServer.

## 9. API keys and secrets: never in the repo

- **Never commit an API key** to source control, even in a private repo, even once. History keeps it forever.
- A key shipped inside an APK can be extracted. Treat client keys as public identifiers, not secrets. Real secrets belong on your server, with the app calling your server instead of the third party directly.
- For local builds, read keys from `local.properties` (git-ignored) or an environment variable, and pass them in via `buildConfigField`.
- For CI, store keys in the CI secret store, never in workflow files.
- Restrict keys in the provider console by package name and signing certificate fingerprint where the provider supports it.
- If a key leaks, rotate it first, then clean history.

Store the local key in git-ignored `local.properties` as `EXAMPLE_API_KEY=...`, never in a tracked file.

## 10. Checklist

- [ ] One HTTP stack, wrapped behind a repository interface.
- [ ] DTOs are `@Serializable`, nullable where the server is optional.
- [ ] `ignoreUnknownKeys = true` is set.
- [ ] One shared client instance, injected, not recreated per call.
- [ ] Logging is debug-only and redacts authorization headers.
- [ ] HTTP cache is bounded; offline shows the last good data.
- [ ] Errors are a typed result; retries are idempotent with backoff.
- [ ] No key, token, or password exists anywhere in the repo.

## Official links

- Retrofit: https://square.github.io/retrofit/
- OkHttp: https://square.github.io/okhttp/
- Ktor Client: https://ktor.io/docs/client-create-and-configure.html
- kotlinx.serialization: https://kotlinlang.org/docs/serialization.html
- Android networking overview: https://developer.android.com/training/basics/network-ops
- Network security config: https://developer.android.com/privacy-and-security/security-config
