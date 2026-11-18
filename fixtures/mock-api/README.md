# Mock API — the Fixtures, Over HTTP

A zero-dependency mock server (Python 3 standard library only) that
serves everything in `../sample-data/` as REST endpoints, so Retrofit
or Ktor code can be built and tested end-to-end before any real
backend exists.

## Run it

```bash
python3 mock-server.py                # http://127.0.0.1:8080
python3 mock-server.py --port 9000    # custom port
```

## Endpoints

| Endpoint | Returns | Filters |
|---|---|---|
| `GET /health` | `{"status": "ok", ...}` | — |
| `GET /users`, `GET /users/{id}` | `users.json` | — |
| `GET /notes`, `GET /notes/{id}` | `notes.json` | `?userId=1` |
| `GET /products`, `GET /products/{id}` | `products.json` | `?category=audio` |
| `GET /game-scores`, `GET /game-scores/{id}` | `game-scores.json` | `?levelId=level-001`, `?userId=3` |
| `GET /levels/{levelId}` | `levels/{levelId}.json` | — |

Unknown paths and missing ids return a JSON `404` body, never HTML.
All responses carry `Access-Control-Allow-Origin: *`.

`openapi-lite.json` next to the server is a small hand-written spec
of these endpoints and the User / Note / Product / GameScore / Level
shapes — enough for code generation experiments or for an AI to write
a client from. It is a "lite" spec, not a full OpenAPI document to
validate a production API against.

## Point an Android client at it

- **Emulator:** the host machine is `10.0.2.2` from inside the
  emulator, so your debug base URL is `http://10.0.2.2:8080/`.
- **Real device on the same Wi-Fi:** run with `--host 0.0.0.0` and use
  the host's LAN address.
- **Cleartext:** plain `http://` to a local address needs a debug-only
  network security config entry (`cleartextTrafficPermitted` for that
  host) — keep it in the `debug` source set, never in release.

```kotlin
// Retrofit sketch (debug build only)
Retrofit.Builder()
    .baseUrl("http://10.0.2.2:8080/")
    .addConverterFactory(json.asConverterFactory("application/json".toMediaType()))
    .build()
```

This server is read-only and in-memory: restarting it resets nothing
because it changes nothing — edits go in the JSON files under
`../sample-data/`.
