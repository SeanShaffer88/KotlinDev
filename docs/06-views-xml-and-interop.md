# Views, XML, and Interop

Jetpack Compose is the default for new UI, but the classic View
system is not gone. Existing apps, some libraries, and a few widget
types still use Views and XML. This guide covers when Views are still
the right choice and how the two systems work together.

Official references:
- View Binding: https://developer.android.com/topic/libraries/view-binding
- Compose in Views: https://developer.android.com/develop/ui/compose/migrate/interoperability-apis/compose-in-views
- Views in Compose: https://developer.android.com/develop/ui/compose/migrate/interoperability-apis/views-in-compose
- Migration strategy: https://developer.android.com/develop/ui/compose/migrate/strategy

## When Views Are Still Right

Keep or choose Views when:

- You are maintaining a large, working Views codebase. A rewrite is
  a cost, not an automatic improvement.
- A required library only ships a View (some map, chart, ad, and
  legacy SDK surfaces).
- A screen depends on a mature custom View with no Compose equal yet.
- The widget in question is a home-screen widget built on
  RemoteViews — Compose has Glance for widgets, but classic
  RemoteViews remains common in existing code.
- WebView-heavy screens: `WebView` itself is a View, wrapped in
  Compose with `AndroidView` when needed.

For all new screens in a new app, start with Compose.

## ViewBinding

ViewBinding generates a binding class per layout, replacing
`findViewById` with type-safe, null-safe references. It is the
standard for any Views code you still write.

Enable it in the module build file:

```kotlin
android {
    buildFeatures { viewBinding = true }
}
```

Use it in an Activity:

```kotlin
class ProfileActivity : AppCompatActivity() {
    private lateinit var binding: ActivityProfileBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityProfileBinding.inflate(layoutInflater)
        setContentView(binding.root)
        binding.nameText.text = "Ada"
        binding.saveButton.setOnClickListener { save() }
    }
}
```

In a Fragment, clear the binding in `onDestroyView` to avoid leaking
the view hierarchy:

```kotlin
private var _binding: FragmentHomeBinding? = null
private val binding get() = _binding!!

override fun onDestroyView() {
    super.onDestroyView()
    _binding = null
}
```

Data Binding is a separate, older feature. Do not adopt it for new
work; ViewBinding plus explicit code is simpler and is what current
guidance recommends.

## RecyclerView Essentials

RecyclerView remains the workhorse list for Views screens. Its pieces:

- **Adapter** — binds data to item views.
- **ViewHolder** — holds references for one item layout.
- **LayoutManager** — linear, grid, or staggered placement.
- **ListAdapter + DiffUtil** — computes minimal updates between list
  versions on a background thread. Always prefer `ListAdapter` over
  a plain adapter with `notifyDataSetChanged()`.

```kotlin
class ItemAdapter : ListAdapter<Item, ItemAdapter.Holder>(DiffCallback) {
    object DiffCallback : DiffUtil.ItemCallback<Item>() {
        override fun areItemsTheSame(o: Item, n: Item) = o.id == n.id
        override fun areContentsTheSame(o: Item, n: Item) = o == n
    }

    class Holder(val binding: ItemRowBinding) :
        RecyclerView.ViewHolder(binding.root)

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): Holder {
        val binding = ItemRowBinding.inflate(
            LayoutInflater.from(parent.context), parent, false)
        return Holder(binding)
    }

    override fun onBindViewHolder(holder: Holder, position: Int) {
        val item = getItem(position)
        holder.binding.title.text = item.title
    }
}
```

Submit new data with `adapter.submitList(newList)` and let DiffUtil
animate the changes.

## Compose in Views

Add Compose to an existing Views screen with a `ComposeView`. This
is the main incremental migration path: one screen, or even one
section of a screen, at a time.

```xml
<androidx.compose.ui.platform.ComposeView
    android:id="@+id/compose_section"
    android:layout_width="match_parent"
    android:layout_height="wrap_content" />
```

```kotlin
binding.composeSection.setContent {
    MyAppTheme { PromoBanner(onClick = { /* handle */ }) }
}
```

In Fragments, set a composition strategy appropriate to the view's
lifecycle (the default works in most cases; use
`DisposeOnViewTreeLifecycleDestroyed` when the ComposeView lives in
a Fragment view hierarchy).

## Views in Compose

Embed an existing View inside a composable with `AndroidView`:

```kotlin
@Composable
fun MapPlaceholder() {
    AndroidView(
        factory = { context -> MapView(context) },
        update = { view -> view.onResume() },
        modifier = Modifier.fillMaxWidth().height(240.dp)
    )
}
```

- `factory` creates the View once.
- `update` runs on recomposition to push new state into the View.
- You own the wrapped View's lifecycle: forward `onPause`,
  `onDestroy`, or release calls as the library requires.
- Use `AndroidViewBinding` when you want to embed an entire inflated
  XML layout instead of a single View.

## Sharing State Between the Two Systems

- A single ViewModel can serve both a Fragment and the composables
  inside it — collect its `StateFlow` in Compose and observe it in
  the Fragment with `repeatOnLifecycle`.
- Theme carefully: Compose inside a Views app needs its own
  `MaterialTheme` wrapper; Views inside Compose will follow the
  Activity's XML theme, not the Compose theme.
- Navigation: during migration, the host Fragment or Activity still
  owns navigation until the whole graph moves to Compose.

## Migration Stance

The recommended stance for an existing Views app:

1. New screens in Compose by default.
2. Migrate leaf screens (settings, about, detail) before complex
   core screens.
3. Keep shared design components in Compose once created; do not
   rebuild the same component in both systems.
4. Move navigation last, when most destinations are composables.
5. Remove XML layouts and adapters only when their last caller is
   migrated — dead code removal is a cleanup step, not a migration
   step.

Do not do a big-bang rewrite of a shipping app. Interop exists
precisely so migration can be gradual and reversible.

## What Not to Do

- Do not mix `findViewById` into new code — ViewBinding replaces it.
- Do not create a ComposeView per list item inside RecyclerView
  without measuring; composition per row has a cost. Prefer a full
  Compose list when a list is being rebuilt.
- Do not nest scrollable containers of the same direction (a
  RecyclerView inside a scrolling parent, or a LazyColumn inside a
  `verticalScroll` Column) — measure and restructure instead.
- Do not adopt Data Binding for new Views work.
