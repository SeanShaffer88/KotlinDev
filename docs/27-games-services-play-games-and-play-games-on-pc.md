# Games Services — Play Games and Play Games on PC

Google Play Games Services (PGS) gives an Android game player
identity, achievements, leaderboards, cloud saves, and reach
onto Windows PCs through Google Play Games on PC. This doc
covers the current v2 SDK only, plus PC requirements.

Docs: https://developer.android.com/games/playgames

## Use PGS v2 Only — v1 Is Removed

This is the most common integration mistake, so it comes first:

- **Use the v2 SDK: `com.google.android.gms:play-services-games-v2`.**
- The v1 SDK (`play-services-games`) has been removed as a
  supported path. **Do not treat play-services-games version
  25 or higher as a "v1 upgrade"** — the old v1 APIs are not
  carried forward that way. Migrate to v2 instead.
- New projects start on v2. Existing v1 projects must migrate:
  sign-in flow, client access, and several APIs changed shape.

Check the current v2 artifact version on the Play Games SDK
release notes before pinning; never copy a version from an old
tutorial.

## Setup Checklist

1. Create the game in Play Console and enable Play Games Services.
2. Add the Play Games app ID to the manifest as meta-data.
3. Add the v2 dependency (see the rule above).
4. Initialise the SDK once, early in app start.
5. Test with a licensed tester account listed in Play Console.

```kotlin
// build.gradle.kts — use the current v2 version from release notes
dependencies {
    implementation("com.google.android.gms:play-services-games-v2:<current>")
}
```

```xml
<!-- AndroidManifest.xml -->
<meta-data
    android:name="com.google.android.gms.games.APP_ID"
    android:value="@string/game_services_project_id" />
```

## Initialisation and Automatic Sign-In

```kotlin
class MyApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        PlayGamesSdk.initialize(this)
    }
}
```

In your main activity, check sign-in state through the games
sign-in client. v2 signs the player in automatically when
possible — there is no mandatory interactive sign-in screen.

```kotlin
val signInClient = PlayGames.getGamesSignInClient(this)
signInClient.isAuthenticated()
    .addOnCompleteListener { task ->
        val authenticated = task.isSuccessful &&
            task.result?.isAuthenticated == true
        if (authenticated) loadPlayerProfile()
        else showSignedOutUi() // game must still be playable
    }
```

Design rule: the game must remain playable signed out.
Achievements and leaderboards enhance the game; they must not
gate basic play.

## Player Identity

```kotlin
PlayGames.getPlayersClient(this).currentPlayer
    .addOnSuccessListener { player ->
        val id = player.playerId
        val name = player.displayName
    }
```

Use the Play Games player ID as the identity key for your own
backend, not the player's real name or email. Respect the
player's profile visibility choices.

## Achievements

- Define achievements in Play Console (hidden, incremental,
  and standard types).
- Unlock and increment from gameplay events, not from UI taps.

```kotlin
val client = PlayGames.getAchievementsClient(this)
client.unlock(achievementId)
client.increment(achievementId, steps)
client.showAchievementsIntent() // standard achievements UI
```

Cache progress locally so offline play still counts, then
submit when the player is authenticated again.

## Leaderboards

```kotlin
val client = PlayGames.getLeaderboardsClient(this)
client.submitScore(leaderboardId, score)
client.getLeaderboardIntent(leaderboardId) // standard UI
```

Submit scores only from verified gameplay results. If your
game has a server, validate scores server-side before trusting
them for prizes or rankings that matter.

## Snapshots — Saved Games

Snapshots are Play Games cloud saves tied to the player.

- One or more named snapshots per player (for example one per
  save slot, plus one for settings/progress metadata).
- Each snapshot holds your save bytes plus metadata: played
  time, progress value, and a cover image if you want one.
- Conflicts happen when two devices save offline. Resolve by
  policy: newest played time, highest progress, or ask the
  player. Never silently discard the longer play history.

See doc 28 for the full local + cloud save design.

## Recall API

The Recall API links your own game accounts to the player's
Play Games profile using recall tokens stored by Google. It
helps a returning player recover their in-game account on a
new device without another password. Use it when your game has
its own account system in addition to Play Games identity.

Server-side only: recall tokens are exchanged from your
backend, never purely from the client. Follow the official
Recall guide for the token flow.

## Play Games on PC

Google Play Games on PC runs Android games on Windows. Games
that meet the requirements earn visibility badges:

- **Playable** — the game runs and is playable on PC.
- **Optimized** — the game meets the higher bar for PC play.

Core requirements and expectations (check the current official
checklist before submitting — details evolve):

- **Frame rate: at least 30 FPS, stable**, on target PC hardware.
- **x86-64 support is strongly encouraged.** PC runs on x86-64;
  shipping the `x86_64` ABI dramatically improves compatibility
  and performance versus translation.
- **Mouse and keyboard must work well.** Menus, gameplay, and
  text input cannot require touch. Map keys sensibly and show
  PC-appropriate control hints.
- **Disable unsupported features on PC.** If a feature needs
  GPS, telephony, a rear camera, or other phone-only hardware,
  hide or replace it in the PC build — do not leave a broken button.
- Window resizing, focus loss, and PC display sizes must be
  handled gracefully.
- The game must meet standard Play Games on PC certification:
  correct lifecycle, no phone-only permission demands, and a
  working sign-out / account experience.

Practical approach: detect the PC form factor at runtime
(Play provides signals for the PC environment), then switch
input hints, default quality, and feature flags accordingly.

## Testing

- Test sign-in with tester accounts, not your developer account.
- Test signed-out, offline, and account-switch cases.
- Test achievement and leaderboard flows in the sandbox before
  publishing the Play Games configuration — publishing is a
  one-way door for some settings.
- Test the PC build on Play Games on PC itself if PC reach is
  a goal; an Android emulator does not prove PC behaviour.

## Common Mistakes

- Adding `play-services-games` (v1) to a new project.
- Blocking game start on sign-in success.
- Using the player's display name as a database key.
- Submitting leaderboard scores from the client for rewarded
  competitions with no server validation.
- Shipping an ARM-only build and expecting good PC performance.
- Leaving touch-only tutorials in the PC build.

## Official Links

- Play Games Services: https://developer.android.com/games/playgames
- PGS v2 migration: https://developer.android.com/games/playgames/unity/unity-start-signin (Android native guidance linked from the PGS hub)
- Android SDK setup: https://developer.android.com/games/playgames/android/android-start
- Achievements: https://developer.android.com/games/playgames/services/common/concepts/achievements
- Leaderboards: https://developer.android.com/games/playgames/services/common/concepts/leaderboards
- Saved games (Snapshots): https://developer.android.com/games/playgames/services/common/concepts/saved-games
- Recall API: https://developer.android.com/games/playgames/recall
- Play Games on PC: https://developer.android.com/games/playgames/pc
- PC requirements checklist: https://developer.android.com/games/playgames/pc/requirements
