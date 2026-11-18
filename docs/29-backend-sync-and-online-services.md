# Backend, Sync, and Online Services

How an Android app or game talks to a backend: Firebase as the
default Google-stack option, open self-hosted alternatives,
offline-first sync design, conflict handling, and key safety.

## Do You Need a Backend at All?

Not every app does. You need a backend when you have:
- Accounts shared across devices
- Multiplayer, leaderboards with anti-cheat, or social features
- Content that updates without an app release
- Purchases or entitlements validated server-side
- Cross-device sync beyond Play Games Snapshots

If none apply, ship local-only. A backend is ongoing cost,
privacy duty, and attack surface — add it for a reason.

## Firebase — The Default Option

Firebase: https://firebase.google.com/docs/android/setup

Firebase covers auth, database, storage, messaging, crash
reporting, and remote configuration in one console.

### The BoM Rule — Never Pin Individual Versions

**Always import the Firebase Bill of Materials (BoM) and never
pin individual Firebase library versions.**

```kotlin
// build.gradle.kts
dependencies {
    // Import the BoM — always use the LATEST BoM version.
    // Check https://firebase.google.com/support/release-notes/android
    implementation(platform("com.google.firebase:firebase-bom:<latest>"))

    // Declare libraries WITHOUT versions — the BoM supplies them.
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.firebase:firebase-messaging")
    implementation("com.google.firebase:firebase-crashlytics")
    implementation("com.google.firebase:firebase-config")
}
```

Why: Firebase libraries are released together and tested
against the BoM. Pinning one library to an old version while
others move creates runtime conflicts that are hard to debug.
When you upgrade Firebase, you change one number: the BoM.

Also apply the Google Services plugin and, for Crashlytics
and Performance, their Gradle plugins per the current setup
docs. Add `google-services.json` per the console flow — it
identifies the project; it is not a secret key, but treat the
console itself as sensitive.

### Firebase Auth

- Email/password, Google sign-in, phone, and anonymous auth.
- Anonymous auth first, upgrade later is a good game pattern:
  the player starts instantly and links an identity when ready.
- On Android, integrate with Credential Manager for sign-in.
- All authorisation decisions happen server-side (Firestore
  rules / your backend), never trust a client-side flag.

### Cloud Firestore and Offline Cache

Firestore caches data locally and syncs when online. That
makes it naturally offline-tolerant for reads and queued writes.

```kotlin
val db = FirebaseFirestore.getInstance()
db.collection("players").document(playerId)
    .addSnapshotListener { snapshot, error ->
        if (error != null) return@addSnapshotListener
        val data = snapshot?.toObject(PlayerProfile::class.java)
        if (data != null) renderProfile(data)
    }
```

Rules to follow:
- Design collections around your screens' queries. Firestore
  has no joins; denormalise deliberately.
- Write security rules before launch and test them in the
  emulator suite. Default-open rules are a breach waiting.
- Watch read/write pricing: chatty snapshot listeners on large
  collections cost real money at scale.

The Realtime Database is the older option; prefer Firestore
for new projects unless you specifically need its latency
profile for presence-style data.

### Cloud Messaging (FCM)

FCM delivers push notifications and lightweight data messages.
- Request the notification permission at a sensible moment
  (Android 13+ requires runtime `POST_NOTIFICATIONS`).
- Handle token refresh; send the token to your backend.
- Data messages wake background handling within platform limits;
  do not design critical sync around push delivery timing.

### Crashlytics

- Add the SDK via the BoM and the Crashlytics Gradle plugin.
- Upload mapping files from release builds so stack traces
  de-obfuscate. Automate it in CI (doc 30).
- Add custom keys and logs at key flows (sign-in, purchase,
  save/load) — they make crash reports actionable.

### Remote Config

- Ship safe defaults in the app; Remote Config overrides them.
- Good uses: feature flags, difficulty tuning, event switches,
  minimum-version prompts.
- Bad uses: secrets (values are visible to clients) and
  anything the app cannot run without on first launch.

## Open and Self-Hosted Alternatives

Choose these when you need data ownership, predictable cost,
or to avoid a single-vendor dependency.

| Option | What it is | Notes |
|---|---|---|
| Supabase | Hosted/self-hosted Postgres + Auth + Storage + Realtime | Open source core; SQL data model; Kotlin client via supabase-kt |
| Appwrite | Self-hosted backend: auth, DB, storage, functions | Open source; Docker deploy; Android SDK available |
| PocketBase | Single-binary Go backend: auth, DB, realtime, admin UI | **Pre-1.0** — APIs may change between versions; pin carefully and read changelogs before upgrading |
| Parse Server | Open-source Node backend, successor to hosted Parse | Mature; MongoDB/Postgres storage; self-host or hosted providers |

Evaluation checklist for any alternative:
- Is there a maintained Kotlin/Android client, or will you
  write a REST layer yourself with Ktor/Retrofit?
- How are auth tokens stored and refreshed on Android?
- What is the offline story? (Most alternatives are online-first;
  you will build the local cache and sync queue yourself.)
- Backup, export, and exit: can you get all data out?

## Offline-First Sync Design

The pattern that works for apps and games alike:

1. **Local database is the source of truth for the UI.**
   The UI reads and writes Room only. It never waits on network.
2. **A sync layer moves data.** A repository queues outbound
   changes and applies inbound changes to Room.
3. **WorkManager runs sync** with network constraints and
   backoff, plus an immediate sync attempt on local writes
   when online.
4. **Every record carries sync metadata:** a stable ID (UUID),
   `updatedAt`, a version or revision counter, and a deleted
   flag (tombstone) instead of hard deletes.

```kotlin
@Entity(tableName = "notes")
data class NoteEntity(
    @PrimaryKey val id: String, // UUID, client-generated
    val title: String,
    val body: String,
    val updatedAt: Long,
    val revision: Int,
    val deleted: Boolean = false,
    val dirty: Boolean = true // needs upload
)
```

## Conflict Handling

Conflicts are guaranteed once a user has two devices or edits
offline. Pick a policy per data type, in advance:

- **Last-write-wins** by `updatedAt` — fine for settings and
  profile fields; risky for documents.
- **Server revision check** — upload carries the revision it
  edited; the server rejects stale writes, the client re-fetches
  and reapplies or asks the user.
- **Merge** — for counters (add deltas) and sets (union).
- **Ask the user** — for saves and documents with real work in
  both copies. Show both, let them choose, keep the loser as a
  recoverable copy.

Never resolve by silently dropping data. Log conflicts during
development; they reveal design mistakes early.

## Security Rules That Never Bend

- **Never ship admin keys, service account keys, or database
  root credentials in the app.** Anything inside an AAB can be
  extracted. Admin access belongs on a server you control.
- Client keys that are designed to be public (Firebase API key,
  publishable keys) still get restricted: Android app
  restrictions in Google Cloud, API restrictions, and backend
  security rules do the real protection.
- Validate everything server-side: scores, purchases, currency,
  inventory. The client reports; the server decides.
- Use HTTPS only. No cleartext traffic in release builds.
- Store auth tokens in encrypted storage / DataStore with
  platform keystore backing, not plain SharedPreferences.

## Official Links

- Firebase Android setup: https://firebase.google.com/docs/android/setup
- Firebase BoM and releases: https://firebase.google.com/support/release-notes/android
- Firestore: https://firebase.google.com/docs/firestore
- Firebase Auth: https://firebase.google.com/docs/auth/android/start
- FCM: https://firebase.google.com/docs/cloud-messaging/android/client
- Crashlytics: https://firebase.google.com/docs/crashlytics/android/get-started
- Remote Config: https://firebase.google.com/docs/remote-config
- Supabase: https://supabase.com/docs
- Appwrite: https://appwrite.io/docs
- PocketBase: https://pocketbase.io/docs/
- Parse Server: https://docs.parseplatform.org/parse-server/guide/
