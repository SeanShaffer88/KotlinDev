# Fixtures — Sample Data, Mock API, and Database Seeds

Fixtures are ready-made fake data and services you develop and test
against, so you never need a real backend, real user data, or a
production database while building. Everything here is small,
human-readable, and safe to commit.

**Licensing / safety note: all data in this folder is synthetic.**
Names, emails (`@example.com`), products, scores, and notes were
invented for this repo. No real person, account, or transaction is
represented. Use it freely in tests, previews, screenshots, and demos;
never replace it with dumps of real user data.

## What's here

| Path | What it is | Use it for |
|---|---|---|
| `sample-data/users.json` | 12 users, ids 1–12 | Lists, profiles, leaderboard names, `@Preview` data |
| `sample-data/notes.json` | 15 notes, `userId` points at `users.json` | Room/RecyclerView/Compose list practice, search tests |
| `sample-data/products.json` | 12 products with `priceCents`, stock, rating | Shop UI, cart math (integer cents — no float money bugs), empty-stock states (`SKU-007` has `stock: 0`) |
| `sample-data/game-scores.json` | 15 scores, `userId` + `levelId` (`level-001` / `level-002`) | Leaderboards, results screens, sorting/filtering tests |
| `sample-data/levels/level-001.json`, `level-002.json` | 2D tile levels (see below) | Canvas/custom-rendering games in the style of `docs/24` |
| `mock-api/` | The same data served over HTTP | Retrofit/Ktor integration tests without a backend |
| `room/seed.sql` | `INSERT`s matching `notes.json` exactly | Prepopulating a Room database |

Ids are **consistent across files**: note 1 belongs to user 1, score 3
was set by user 3 on `level-001`, and so on. Joins and lookups in your
test code will line up.

## Level format

Each level file is plain JSON a game can load with
kotlinx.serialization (or any JSON parser):

- `world` — grid size in tiles and `tileSizePx` (multiply tile
  coordinates by it to get pixels for a Canvas `DrawScope`, origin
  top-left, as in `docs/24`).
- `tiles.rows` — the map as strings, one character per tile, with
  `tiles.legend` explaining each character (`#` wall, `.` floor,
  `~` hazard, plus `P` player start and `E` exit drawn into the rows).
- `playerSpawn` / `exit` — tile coordinates (also marked in the rows).
- `entities` — things placed on the map: `ball` (position in tiles,
  `radiusPx`, `color`, velocity `vx`/`vy` in px/s — the bouncing-ball
  shape from the Canvas game-loop example), `coin` (with `value`),
  `enemy-patrol` (moves between `xTiles` and `toXTiles`).
- `goals` — win conditions: `reach-exit`, `collect-all`,
  `time-bonus`. `parScore` and `timeLimitSeconds` drive star ratings
  like the ones in `game-scores.json`.

## How to use each fixture

- **In Compose previews / unit tests:** copy a JSON file into
  `src/test/resources/` or `assets/`, parse it, and feed the objects
  to your composables or ViewModel tests.
- **Against a live (fake) API:** run the mock server in `mock-api/`
  and point Retrofit/Ktor at it — see `mock-api/README.md`.
- **In Room:** ship `room/seed.sql` (or a database built from it) and
  prepopulate — see `room/README.md`.
- **In a game:** load a level JSON from `assets/`, build your game
  state from `playerSpawn` + `entities`, render tiles and entities in
  one Canvas pass, and check `goals` each frame.

Keep fixtures deterministic: if a test needs a new record, add it
here with the next id instead of generating random data in the test.
