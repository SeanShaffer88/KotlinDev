# Reference — Android API Levels

Every Android platform version, its API level, and the
`Build.VERSION_CODES` constant. `compileSdk` / `targetSdk` /
`minSdk` in a project are these numbers. Snapshot checked November
2026 — the authoritative list is
https://developer.android.com/reference/android/os/Build.VERSION_CODES.

| API | Version | Codename | `VERSION_CODE` constant |
|---|---|---|---|
| 1 | 1.0 | — (Base) | `BASE` |
| 2 | 1.1 | — (Base 1.1) | `BASE_1_1` |
| 3 | 1.5 | Cupcake | `CUPCAKE` |
| 4 | 1.6 | Donut | `DONUT` |
| 5 | 2.0 | Eclair | `ECLAIR` |
| 6 | 2.0.1 | Eclair 0.1 | `ECLAIR_0_1` |
| 7 | 2.1 | Eclair MR1 | `ECLAIR_MR1` |
| 8 | 2.2 | Froyo | `FROYO` |
| 9 | 2.3–2.3.2 | Gingerbread | `GINGERBREAD` |
| 10 | 2.3.3–2.3.7 | Gingerbread MR1 | `GINGERBREAD_MR1` |
| 11 | 3.0 | Honeycomb | `HONEYCOMB` |
| 12 | 3.1 | Honeycomb MR1 | `HONEYCOMB_MR1` |
| 13 | 3.2 | Honeycomb MR2 | `HONEYCOMB_MR2` |
| 14 | 4.0–4.0.2 | Ice Cream Sandwich | `ICE_CREAM_SANDWICH` |
| 15 | 4.0.3–4.0.4 | Ice Cream Sandwich MR1 | `ICE_CREAM_SANDWICH_MR1` |
| 16 | 4.1 | Jelly Bean | `JELLY_BEAN` |
| 17 | 4.2 | Jelly Bean MR1 | `JELLY_BEAN_MR1` |
| 18 | 4.3 | Jelly Bean MR2 | `JELLY_BEAN_MR2` |
| 19 | 4.4 | KitKat | `KITKAT` |
| 20 | 4.4W | KitKat Watch | `KITKAT_WATCH` |
| 21 | 5.0 | Lollipop | `LOLLIPOP` |
| 22 | 5.1 | Lollipop MR1 | `LOLLIPOP_MR1` |
| 23 | 6.0 | Marshmallow | `M` |
| 24 | 7.0 | Nougat | `N` |
| 25 | 7.1 | Nougat MR1 | `N_MR1` |
| 26 | 8.0 | Oreo | `O` |
| 27 | 8.1 | Oreo MR1 | `O_MR1` |
| 28 | 9 | Pie | `P` |
| 29 | 10 | Quince Tart | `Q` |
| 30 | 11 | Red Velvet Cake | `R` |
| 31 | 12 | Snow Cone | `S` |
| 32 | 12L | Snow Cone v2 | `S_V2` |
| 33 | 13 | Tiramisu | `TIRAMISU` |
| 34 | 14 | Upside Down Cake | `UPSIDE_DOWN_CAKE` |
| 35 | 15 | Vanilla Ice Cream | `VANILLA_ICE_CREAM` |
| 36 | 16 | Baklava | `BAKLAVA` |
| 36.1 | 16 (QPR minor release) | Baklava 36.1 | `BAKLAVA_36_1` |
| 37 | 17 | Cinnamon Bun | `CINNAMON_BUN` |

## How to use this table

- **minSdk** — the oldest API the app installs on. Common modern
  choices: 24 (covers the large majority of active devices) or 26.
  Every API below minSdk never needs a runtime version check.
- **targetSdk** — the newest API whose behavior changes the app has
  opted into. Play requires target **36** for new apps and updates
  since August 31, 2026 (see
  [`play-requirements-and-deadlines.md`](play-requirements-and-deadlines.md)).
- **compileSdk** — the API the code compiles against; must be ≥
  targetSdk. Use 36 normally; the newest Compose features may
  require compileSdk **37**.
- Guard newer APIs with `if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.… )`
  checks, or use AndroidX compat helpers that do it for you.
- Codenames stopped being public dessert names after Android 9 (Pie);
  the internal dessert codenames above are still the `VERSION_CODE`
  names, which is why code refers to `TIRAMISU`, `BAKLAVA`, etc.

Related: [`../docs/02-android-platform-and-versions.md`](../docs/02-android-platform-and-versions.md).
