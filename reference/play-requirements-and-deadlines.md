# Reference — Play Requirements and Deadlines

The Google Play requirements that gate whether a submission is even
accepted. Snapshot checked November 2026. The binding text is always
the Play Console help / policy pages — re-check before every release
([`../SOURCES.md`](../SOURCES.md)).

## Target API timeline

| Requirement | Date | Detail |
|---|---|---|
| Target API 36 for new apps and app updates | **August 31, 2026** | New apps and updates must target API 36 (Android 16) or higher. Existing apps below the required target face discoverability/update restrictions per the Play target API policy. |
| Target API 35 era | Aug 31, 2025 (past) | The previous step (API 35, Android 15) — historical, superseded by the API 36 step above. |
| Wear OS / TV / Auto targets | Per-form-factor dates in Play Console help | Form-factor apps have their own target API steps — check the requirement page for each form factor you ship. |

Practical rule: set `targetSdk = 36` now, `compileSdk = 36` (37 only
where the newest Compose features require it), and start the next
target bump early — behavior changes (edge-to-edge, permission and
background limits, large-screen rules) are the real work, not the
number.

## Billing

| Requirement | Detail |
|---|---|
| Billing Library 8+ | Apps using Play Billing must integrate **Billing Library 8 or newer**; submissions/updates on older versions are rejected under the current Play billing requirements. Migrate per [`../docs/20-monetization-billing-and-ads.md`](../docs/20-monetization-billing-and-ads.md). |
| Subscriptions & pricing rules | Acknowledge purchases within 3 days or they auto-refund; test with license testers; declare offers/pricing in Play Console to match in-app claims. |

## 16 KB page size

| Milestone | Date | Detail |
|---|---|---|
| Requirement announced / tooling available | 2025 | Apps with native code (`.so` libraries) must support 16 KB memory page sizes on Android 15+ devices. |
| Play enforcement step-up | **February 1, 2027** | Play enforcement tightens: new apps and updates that ship native code not aligned for 16 KB pages face rejection. Rebuild native libraries (NDK r27+ defaults / explicit `-Wl,-z,max-page-size=16384`) and check every bundled `.so`, including third-party SDKs and game engines. |

Check with: `llvm-readelf -lW lib.so | grep LOAD` (alignment `0x4000`)
or the APK Analyzer 16 KB check in Android Studio. This applies to
libGDX/native/AGDK games and any app bundling native libraries.

## App Bundle and signing

| Requirement | Detail |
|---|---|
| Android App Bundle (AAB) | Required for new apps since August 2021; updates ship as AABs. Play generates the per-device APKs. |
| Play App Signing | Required for new apps: Google holds the final signing key; you sign uploads with your upload key. Keep the upload key + passwords in a secret store, never in the repo. |
| 64-bit native code | Native code must ship 64-bit (`arm64-v8a`, `x86_64`) variants. |

## Data safety and privacy

| Requirement | Detail |
|---|---|
| Data safety section | Every app must complete the Play Console data safety form: data collected, shared, purposes, encryption in transit, deletion path. It must match the privacy policy and the app's actual behavior. |
| Privacy policy | Required for apps that access personal/sensitive data (and all apps in several categories); hosted at a stable public URL. |
| Account deletion | Apps that let users create accounts must offer in-app account deletion and a web deletion link declared in Play Console. |
| Permissions declarations | Sensitive permissions (location background, health, photos/video, notifications, exact alarm, etc.) require Play Console declaration forms and a demo video in some cases — see [`permissions-table.md`](permissions-table.md). |
| Families / Designed for Families | Apps targeting children carry extra policy (ads SDK certification, content, data) — check before declaring a child target audience. |

## Release mechanics worth planning around

- **Review times vary** — new developer accounts and new apps can
  face longer review and a closed-testing requirement (personal
  accounts created after Nov 2023 need 12+ testers for 14 days of
  closed testing before production access — verify current terms in
  Play Console help).
- **Staged rollout** is the default safe path for updates: small
  percentage, watch crashes/ANRs in Android vitals, then expand.
- **Android vitals thresholds** (bad behavior): excessive crash/ANR
  rates hurt discoverability — monitor after every rollout step.

Related: [`../docs/19-build-signing-release-and-google-play.md`](../docs/19-build-signing-release-and-google-play.md),
[`../checklists/play-submission-checklist.md`](../checklists/play-submission-checklist.md).
