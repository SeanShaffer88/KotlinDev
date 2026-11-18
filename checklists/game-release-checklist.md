# Game Release Checklist

Run in addition to [`pre-release-checklist.md`](pre-release-checklist.md)
and [`play-submission-checklist.md`](play-submission-checklist.md) for
any game, on any route ([`../reference/game-route-comparison.md`](../reference/game-route-comparison.md)).

## Game services and identity

- [ ] Play Games Services **v2** integrated (automatic sign-in works;
      no PGS v1 code paths remain) —
      [`../docs/27-games-services-play-games-and-play-games-on-pc.md`](../docs/27-games-services-play-games-and-play-games-on-pc.md).
- [ ] Play Console game project linked; achievements/leaderboards in
      the build are published (not left in draft) and vice versa.
- [ ] Saved games / cloud save conflict flow tested (two devices or
      reinstall): newest-progress wins, no silent overwrite.
- [ ] Sign-in declined path works — the game is fully playable signed
      out, with services features degrading cleanly.

## Performance and devices

- [ ] Frame budget held on a mid-range device at targetSdk: stable
      frame pacing, no per-frame allocation spikes in the hot loop —
      [`../docs/28-games-performance-input-audio-and-saves.md`](../docs/28-games-performance-input-audio-and-saves.md).
- [ ] Thermal pass: 20+ minute session without sustained throttling
      collapse; quality scaling (if any) engages.
- [ ] Low-end device at minSdk tested; high-refresh (90/120 Hz)
      device tested — game speed is frame-rate independent.
- [ ] Native builds: all `.so` files 64-bit and 16 KB page-aligned;
      symbols archived for crash symbolication.
- [ ] Download size checked (bundletool); asset delivery (Play Asset
      Delivery) used where the game exceeds comfortable base size.

## Input, display, audio

- [ ] Touch, and (where claimed) game controller, keyboard/mouse all
      tested; controller disconnect mid-game handled.
- [ ] Foldable posture changes, resize, and aspect ratios from
      4:3 to ultra-wide render without stretched or cut-off gameplay.
- [ ] Google Play Games on PC checks done if opting in: resizable
      window, keyboard/mouse, no touch-only blockers.
- [ ] Audio: focus loss (call/notification) pauses or ducks; silent
      mode and Bluetooth latency cases sane; no audio after the app
      is backgrounded.

## Monetization and policy

- [ ] Billing 8+ flows tested with license testers (purchase,
      restore, refund/revoke handling); prices in-game match Play
      Console exactly.
- [ ] No loot-box / gacha mechanics without the required odds
      disclosure where policy demands it; ratings questionnaire
      answers reflect the game's actual content and monetization.
- [ ] Offline play works where promised; server-dependent features
      fail with a clear message, not a hang.
- [ ] Anything not run on a real device is recorded as
      **Unverified** in the release notes.
