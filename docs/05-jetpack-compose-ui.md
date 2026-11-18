# Jetpack Compose UI

Jetpack Compose is the modern, declarative UI toolkit for Android. You describe what the UI should look like for a given state, and Compose updates it when the state changes. No XML layouts, no manual view lookups.

Official references:
- Compose docs: https://developer.android.com/develop/ui/compose
- Thinking in Compose: https://developer.android.com/develop/ui/compose/mental-model
- Material 3: https://developer.android.com/develop/ui/compose/designsystems/material3
- Compose BOM: https://developer.android.com/develop/ui/compose/bom

Use the Compose BOM (2026.09.00 verified) to align library versions, and the Compose compiler plugin — its version follows your Kotlin version since Kotlin 2.0.

## Composables

A composable is a function marked `@Composable` that emits UI.

```kotlin
@Composable
fun Greeting(name: String, modifier: Modifier = Modifier) {
    Text(text = "Hello, $name", modifier = modifier)
}

@Composable
fun ProfileCard(user: User, modifier: Modifier = Modifier) {
    Card(modifier = modifier.padding(16.dp)) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(user.name, style = MaterialTheme.typography.titleLarge)
            Text(user.email ?: "", style = MaterialTheme.typography.bodyMedium)
        }
    }
}
```

Conventions: every composable accepts `modifier: Modifier = Modifier` and applies it to its root element; composables are fast and side-effect free (no network, database, or file work inside them); names use PascalCase and read like nouns.

## State and Recomposition

When state a composable reads changes, Compose re-runs that composable — recomposition — and updates only what changed.

```kotlin
@Composable
fun Counter() {
    var count by remember { mutableIntStateOf(0) }
    Column {
        Text("Count: $count")
        Button(onClick = { count++ }) { Text("Add") }
    }
}
```

Core tools:

- `remember` — keeps a value across recompositions.
- `mutableStateOf` — observable state Compose tracks.
- `rememberSaveable` — also survives configuration changes and
process death for small, saveable values.
- `derivedStateOf` — computes state from other state, notifying
only when the result actually changes.

Use primitive state types (`mutableIntStateOf`, `mutableFloatStateOf`, `mutableLongStateOf`) for numbers to avoid boxing overhead.

## State Hoisting

State hoisting moves state up so a composable becomes stateless: it receives the value and an event callback.

```kotlin
// Stateless — reusable and testable
@Composable
fun NameField(name: String, onNameChange: (String) -> Unit) {
    TextField(value = name, onValueChange = onNameChange,
        label = { Text("Name") })
}
// Stateful wrapper owns the state
@Composable
fun NameForm() {
    var name by rememberSaveable { mutableStateOf("") }
    NameField(name = name, onNameChange = { name = it })
}
```

Pattern: **state flows down, events flow up.** Screen state normally lives in a ViewModel and reaches composables as a collected flow:

```kotlin
@Composable
fun HomeRoute(viewModel: HomeViewModel = viewModel()) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()
    HomeScreen(state = state, onRefresh = viewModel::refresh)
}
```

`collectAsStateWithLifecycle` pauses collection when the UI is not visible, saving battery and avoiding wasted work.

## Material 3

Material 3 is the default design system. Wrap your app in your theme and use Material components (`Button`, `Card`, `Scaffold`, `TopAppBar`, `NavigationBar`, `TextField`, `Switch`) instead of building equivalents from scratch.

```kotlin
@Composable
fun MyAppTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = lightColorScheme(
            primary = Color(0xFF6750A4),
            secondary = Color(0xFF625B71)),
        typography = Typography(),
        content = content)
}
```

Support dark theme with `darkColorScheme` and dynamic color on API 31+ (`dynamicLightColorScheme` / `dynamicDarkColorScheme`) when your brand allows it. Read colors and text styles from `MaterialTheme.colorScheme` and `MaterialTheme.typography` — never hardcode hex colors inside screens.

## Layouts

- `Column` — vertical arrangement.
- `Row` — horizontal arrangement.
- `Box` — stacked elements, like a frame layout.
- `Spacer` — empty space with a fixed size.
- `Modifier` chains control size, padding, alignment, behavior.

```kotlin
@Composable
fun PriceRow(label: String, price: String) {
    Row(
        modifier = Modifier.fillMaxWidth().padding(16.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(label)
        Text(price, style = MaterialTheme.typography.titleMedium)
    }
}
```

Modifier order matters: `padding` then `background` paints a different result than `background` then `padding`. Plain Row/Column/Box covers most apps; `ConstraintLayout` for Compose and custom `Layout` composables exist for complex cases.

## Lists with LazyColumn

Never put a long list in a regular `Column` — every item is composed at once. Lazy layouts compose only visible items.

```kotlin
@Composable
fun ItemList(items: List<Item>) {
    LazyColumn(
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        items(items = items, key = { it.id }) { item ->
            ItemRow(item = item)
        }
    }
}
```

Always provide a stable `key` so Compose tracks items correctly. Use `LazyRow` for horizontal lists and `LazyVerticalGrid` for grids. Add `contentPadding` instead of padding on the list itself so the first and last items can scroll clear of edges.

## Theming and Design Tokens

Define colors, typography, and shapes once in a `ui/theme` package. Screens reference tokens, not raw values. This makes dark mode, rebranding, and accessibility fixes one-place changes. Use `sp` for text and `dp` for layout so user font-size settings are respected.

## Previews

`@Preview` renders a composable in Android Studio without running the app. Preview the stateless version of each screen.

```kotlin
@Preview(showBackground = true)
@Preview(showBackground = true,
    uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun ProfileCardPreview() {
    MyAppTheme { ProfileCard(User(1, "Ada", null)) }
}
```

Add previews for light, dark, loading, empty, and error states — they double as living documentation of your design system.

## Graphics and Canvas — Introduction

`Canvas` gives you a `DrawScope` for custom drawing: charts, game boards, progress rings, and signatures.

```kotlin
@Composable
fun ProgressRing(progress: Float) {
    Canvas(modifier = Modifier.size(120.dp)) {
        drawArc(
            color = Color.Blue, startAngle = -90f,
            sweepAngle = 360f * progress, useCenter = false,
            style = Stroke(width = 12f))
    }
}
```

`drawLine`, `drawRect`, `drawCircle`, `drawPath`, and `drawText` cover most needs. Compose Canvas works well for turn-based and puzzle games; action games usually need a dedicated engine or surface — see the games guides in this knowledge base.

## Performance Basics

- Keep composables small so recomposition stays narrow.
- Pass stable, immutable data (data classes, immutable collections).
- Defer state reads: read changing state as low in the tree as
possible, or pass a lambda for values that change every frame.
- Use `key` in lazy lists and `remember` for expensive calculations.
- Measure before optimizing: Layout Inspector shows recomposition
counts, and Baseline Profiles improve startup and scroll.
- Avoid allocating objects in hot composables where a remembered
value would do.

## Common Mistakes

- Writing to state during composition (use event handlers or
`LaunchedEffect` instead).
- Using `collectAsState` where lifecycle-aware collection is needed.
- Forgetting the `modifier` parameter on reusable components.
- Building scrollable content in `Column` with `verticalScroll` for
hundreds of items instead of `LazyColumn`.
