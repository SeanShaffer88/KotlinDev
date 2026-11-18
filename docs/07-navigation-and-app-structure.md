# Navigation and App Structure

Most modern Android apps use a single Activity and navigate between
composable destinations inside it. This guide covers Navigation
Compose with type-safe routes, the newer Navigation 3 library, deep
links, and how to choose between them deliberately.

Official references:
- Navigation Compose: https://developer.android.com/develop/ui/compose/navigation
- Type-safe navigation: https://developer.android.com/guide/navigation/design/type-safety
- Navigation 3: https://developer.android.com/guide/navigation/navigation-3
- Deep links: https://developer.android.com/training/app-links

## Single-Activity Structure

One `ComponentActivity` hosts everything:

```kotlin
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent { MyAppTheme { AppNavHost() } }
    }
}
```

Benefits: one lifecycle to manage, shared app bars and bottom
navigation are easy, transitions are consistent, and deep links land
in one place. Multiple Activities are still valid for strongly
separate flows (a share target, a standalone viewer), but they are
the exception.

## Navigation Compose — 2.10.2

Navigation Compose (version 2.10.2 in the 2.x line) is the mature,
widely used option. Since Navigation 2.8, routes are type-safe:
destinations and arguments are serializable Kotlin objects instead
of string routes with hand-parsed arguments.

Define routes:

```kotlin
@Serializable
object HomeRoute

@Serializable
data class DetailRoute(val itemId: Long)

@Serializable
data class SearchRoute(val query: String = "")
```

Build the graph:

```kotlin
@Composable
fun AppNavHost() {
    val navController = rememberNavController()
    NavHost(navController = navController, startDestination = HomeRoute) {
        composable<HomeRoute> {
            HomeScreen(onItemClick = { id ->
                navController.navigate(DetailRoute(id))
            })
        }
        composable<DetailRoute> { backStackEntry ->
            val route = backStackEntry.toRoute<DetailRoute>()
            DetailScreen(itemId = route.itemId)
        }
        composable<SearchRoute> { backStackEntry ->
            val route = backStackEntry.toRoute<SearchRoute>()
            SearchScreen(initialQuery = route.query)
        }
    }
}
```

Navigation rules:

- Navigate with route objects, never string concatenation.
- Read arguments with `toRoute<T>()` — no manual bundle parsing.
- Use `launchSingleTop`, `restoreState`, and `popUpTo` with
  `saveState` for bottom-navigation tabs so each tab keeps its stack:

```kotlin
navController.navigate(tabRoute) {
    popUpTo(navController.graph.findStartDestination().id) {
        saveState = true
    }
    launchSingleTop = true
    restoreState = true
}
```

- Handle results by sharing a ViewModel scoped to a navigation
  graph, or by passing IDs and re-reading data — not by stuffing
  objects into bundles.

## Navigation 3 — 1.2.1 (Stable, November 2026)

Navigation 3 reached stable 1.2.1 in November 2026. It is a new
library built around a simple idea: **you own the back stack.** The
back stack is a plain list of keys in your state; Navigation 3
renders the top entry and provides scene and transition machinery.

Core shape (simplified):

```kotlin
// Keys are your own serializable types
@Serializable data class HomeKey(val userId: Long) : NavKey
@Serializable data class DetailKey(val itemId: Long) : NavKey

@Composable
fun AppNavigation3() {
    val backStack = rememberNavBackStack(HomeKey(userId = 1))
    NavDisplay(
        backStack = backStack,
        onBack = { backStack.removeLastOrNull() },
        entryProvider = entryProvider {
            entry<HomeKey> { key -> HomeScreen(key.userId) }
            entry<DetailKey> { key -> DetailScreen(key.itemId) }
        }
    )
}
```

Key concepts:

- **Own the back stack** — navigate by adding a key, go back by
  removing one. Testing navigation is testing a list.
- **Scenes** — a Scene decides how entries are displayed: a single
  pane, a list-detail two-pane layout on large screens, or a dialog
  scene. Scenes are how adaptive layouts are expressed.
- **Entry providers** — map each key type to its content.
- State is saved and restored through the same serialization you
  already use for keys.

## Choosing Between Them — A Deliberate Choice

Navigation 3 is **not a mandatory migration**. Navigation Compose
remains fully supported. Choose deliberately:

| Situation | Sensible choice |
|-----------|-----------------|
| Existing app on Navigation Compose | Stay; migrate only for a clear payoff |
| New app, simple single-pane flow | Either — Navigation Compose is familiar and proven |
| New app needing list-detail / multi-pane scenes | Navigation 3 Scenes are a strong reason |
| Team wants direct control of the back stack as state | Navigation 3 |
| Heavy reliance on existing Navigation Compose integrations | Navigation Compose |

Do not run both libraries in one app graph. Pick one navigation
system per app and write it down in your architecture notes.

## Deep Links

Declare deep links in the manifest (see the app anatomy guide) and
mirror them on destinations so Navigation handles the intent:

```kotlin
composable<DetailRoute>(
    deepLinks = listOf(
        navDeepLink<DetailRoute>(basePath = "https://www.example.com/items")
    )
) { /* destination */ }
```

Guidelines:

- Every public content screen should be reachable by a stable URI.
- Deep link arguments are untrusted input — validate IDs and fall
  back to a safe screen when a link is malformed.
- Test links with `adb shell am start -a android.intent.action.VIEW -d "URL"`.
- App Links (verified HTTPS) need the `assetlinks.json` file; plain
  deep links work without it but may show an app chooser.

## App Structure Around Navigation

- **Bottom navigation** for 3–5 top-level destinations. On large
  screens, swap it for a navigation rail or drawer.
- **Nested graphs** group a feature's screens (checkout, onboarding)
  with their own start destination and shared ViewModel scope.
- **Dialogs and bottom sheets** are destinations too in Compose
  navigation (`dialog { }` in Navigation Compose), which keeps back
  behavior correct.
- Keep the NavController (or the Navigation 3 back stack) in the
  top-level app composable. Pass navigation callbacks down as
  lambdas (`onItemClick: (Long) -> Unit`) instead of passing the
  controller into every screen — screens stay testable and reusable
  in previews.

## Common Mistakes

- Passing whole objects as navigation arguments instead of an ID.
- Navigating from a composable body instead of an event handler or
  a `LaunchedEffect` — composition can re-run and double-navigate.
- Forgetting `saveState`/`restoreState` on tab navigation, which
  destroys each tab's scroll position and stack.
- Reading arguments as raw strings when type-safe routes exist.
- Treating Navigation 3 as an obligatory upgrade and rewriting a
  working Navigation Compose graph without a feature reason.
