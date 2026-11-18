# Kotlin Language for Android

Kotlin is the preferred language for Android. It is concise, null-safe by design, and fully interoperable with Java. This guide covers the features you will use every day in Android apps and games.

Official references: Kotlin docs: https://kotlinlang.org/docs/home.html
- Kotlin for Android: https://developer.android.com/kotlin
- Coding conventions: https://kotlinlang.org/docs/coding-conventions.html
## Why Kotlin on Android

Less boilerplate than Java; null safety in the type system; coroutines and Flow are first-class for async work; data classes, sealed types, and extensions model UI state cleanly; and 100% Java interoperability — Kotlin and Java can mix in one project.

## Variables and Types

```kotlin
val id: Long = 42L          // read-only, preferred
var counter: Int = 0        // mutable, only when needed
val name = "Ada"            // type inferred as String
val price: Double = 9.99
```

Prefer `val` over `var` — immutability makes state easier to reason about, especially with Compose and unidirectional data flow.

Use string templates instead of concatenation: 
```kotlin
val user = "Ada"
val greeting = "Hello, $user — you have ${items.size} items"
```

## Null Safety

Kotlin separates nullable and non-nullable types. A `String` can never be null. A `String?` may be null and must be handled.

```kotlin
val a: String = "hello"
// val b: String = null     // compile error — this is the point
val c: String? = null
val len1 = c?.length ?: 0          // safe call + Elvis operator
val len2 = c?.length ?: error("missing value")

fun printLength(s: String?) {
    if (s != null) {
        println(s.length)  // smart cast: s is String here
    }
}
```

Key operators: 
`?.` safe call (null if receiver is null); `?:` Elvis fallback; `!!` not-null assertion (throws if null — avoid in production); `?.let { }` runs a block only when not null; `requireNotNull(x)` fails fast with a clear message.

Never use `!!` to silence the compiler. Handle the null case, provide a default, or redesign the type to be non-nullable.

## Functions and Lambdas

```kotlin
fun greet(name: String, punctuation: String = "!"): String {
    return "Hello, $name$punctuation"
}
fun double(x: Int): Int = x * 2   // single-expression function
val msg = greet(name = "Sam", punctuation = ".")  // named arguments

repeatAction(3) { index -> println("Item $index") }  // lambda argument
```

Default arguments remove the need for most Java-style overloads.

## Data Classes

Data classes generate `equals`, `hashCode`, `toString`, `copy`, and destructuring automatically. Use them for models and UI state.

```kotlin
data class User(val id: Long, val name: String, val email: String?)
val u1 = User(1, "Ada", null)
val u2 = u1.copy(name = "Ada Lovelace")  // copy with one field changed
val (id, name, _) = u2                   // destructuring
```

## Sealed Classes and Interfaces

Sealed types restrict which subclasses can exist, so `when` can be exhaustive without an `else` branch. This is the standard way to model UI state and results.

```kotlin
sealed interface UiState {
    data object Loading : UiState
    data class Success(val items: List<String>) : UiState
    data class Error(val message: String) : UiState
}
fun render(state: UiState): String = when (state) {
    UiState.Loading -> "Loading…"
    is UiState.Success -> "Loaded ${state.items.size} items"
    is UiState.Error -> "Error: ${state.message}"
}
```

Use sealed types for screen states, navigation events, network results, and game states (menu, playing, paused, game over).

## Classes, Objects, and Companion Objects

```kotlin
class Counter(private var value: Int = 0) { fun increment() { value++ } }
object AppConfig { const val MAX_RETRIES = 3 }   // singleton
class Repository {
    companion object {
        const val TAG = "Repository"  // like Java static
        fun create(): Repository = Repository()
    }
}
```

Prefer constructor injection over singletons for testable code.

## Scope Functions

Scope functions run a block with an object as context. Choose by the context (`this` or `it`) and what you return.

| Function | Context | Returns | Typical use |
|----------|---------|---------|-------------|
| `let` | `it` | block result | transform a nullable value |
| `run` | `this` | block result | compute a result from an object |
| `with` | `this` | block result | group calls on one object |
| `apply` | `this` | the object | configure an object |
| `also` | `it` | the object | side effects, logging |

```kotlin
val text = user?.let { "Name: ${it.name}" } ?: "Unknown"
val paint = Paint().apply { color = Color.RED; textSize = 48f }
list.also { println("Loaded ${it.size} items") }
```

Do not chain scope functions deeply. If the code needs a comment to explain which function does what, write plain statements instead.

## Collections

Kotlin collections are read-only by default. `List`, `Set`, and `Map` are immutable interfaces; `MutableList` and friends allow changes.

```kotlin
val names = listOf("Ada", "Sam", "Jo")
val doubled = listOf(1, 2, 3).map { it * 2 }          // [2, 4, 6]
val adults = users.filter { it.age >= 18 }
val total = listOf(1, 2, 3).fold(0) { acc, n -> acc + n }
val grouped = users.groupBy { it.team }
val first = names.firstOrNull() ?: "none"
val sorted = users.sortedBy { it.name }
```

Common operations: `map`, `filter`, `flatMap`, `firstOrNull`, `any`, `all`, `count`, `sumOf`, `maxByOrNull`, `associateBy`, `partition`, `zip`, `chunked`. Prefer these over manual loops. Sequences (`asSequence()`) defer work for large collections, but for typical Android list sizes a plain collection is simpler and faster.

## Delegation

Delegation forwards interface implementation to another object:

```kotlin
interface SoundPlayer { fun play() }
class MediaSoundPlayer : SoundPlayer {
    override fun play() { /* play sound */ }
}
class GameAudio(player: SoundPlayer) : SoundPlayer by player
```

Property delegates:

```kotlin
val lazyDb: Database by lazy { openDatabase() }  // init on first use
var observed: String by Delegates.observable("init") { _, old, new ->
    println("$old -> $new")
}
```

In Android, `by viewModels()`, `by remember`, and delegated Compose state are all delegation in action.

## Inline and Value Classes

A value class wraps a single value with a distinct type and little or no runtime overhead. Use it to prevent mixing up IDs and units.

```kotlin
@JvmInline value class UserId(val value: Long)
@JvmInline value class Milliseconds(val value: Long)
fun loadUser(id: UserId) { /* ... */ }
// loadUser(Milliseconds(5))  // compile error — types protect you
```

`inline` functions inline the lambda body at the call site — this is how `let`, `run`, and reified generics work:

```kotlin
inline fun <reified T> parse(json: String): T =
    parser.fromJson(json, T::class.java)  // T known at runtime
```

## Extension Functions

Extensions add functions to existing types without inheritance:

```kotlin
fun String.isValidEmail(): Boolean = contains("@") && contains(".")
fun View.show() { visibility = View.VISIBLE }
fun View.hide() { visibility = View.GONE }
```

Keep extensions close to the type they extend, and avoid surprising behavior. An extension cannot access private members of the receiver.

## When Java Interop Matters

- Calling Java libraries without nullability annotations — treat
returns as platform types (`String!`) and validate at the boundary.
- Exposing Kotlin to Java callers — use `@JvmStatic`, `@JvmField`,
`@JvmOverloads`, and `@Throws` where needed.
- Working with reflection-based libraries and older mixed codebases
during a gradual migration.

```kotlin
class Analytics {
    companion object {
        @JvmStatic fun track(event: String) { /* ... */ }
    }
    @JvmField var enabled: Boolean = true
}
```
## Idioms Summary

Prefer `val`, data classes, and immutable collections. Model state with sealed types and exhaustive `when`. Handle nulls with `?.`, `?:`, and smart casts — not `!!`. Use default and named arguments instead of overload chains, and `copy()` to update immutable state. Let the compiler check what Java would check at runtime.
