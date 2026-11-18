# Reference — Permissions Table

Runtime ("dangerous") permissions, the API levels that changed them,
and the foreground service (FGS) types. Snapshot checked November
2026; the binding list is
https://developer.android.com/reference/android/Manifest.permission
and the FGS types page on developer.android.com.

## Dangerous permissions by area

| Permission | Added / changed | Notes |
|---|---|---|
| `POST_NOTIFICATIONS` | Runtime since API 33 | Notifications are opt-in on Android 13+. Ask after the user sees value, not at first launch. |
| `READ_MEDIA_IMAGES` / `READ_MEDIA_VIDEO` / `READ_MEDIA_AUDIO` | API 33 | Replace `READ_EXTERNAL_STORAGE` for media on Android 13+. Prefer the **photo picker** (no permission at all) for user-selected media. |
| `READ_MEDIA_VISUAL_STORIES` | API 35-era addition — verify on the permission reference | Granular media categories keep splitting; check before requesting broad media access. |
| `READ_EXTERNAL_STORAGE` | Max SDK 32 in practice | Legacy. On API 33+ use the media permissions or the picker; scoped storage is the model since API 29/30. |
| `WRITE_EXTERNAL_STORAGE` | Legacy | No effect on modern targets — shared storage writes go through MediaStore / app-specific dirs / SAF. |
| `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` | Runtime since API 23 | Request coarse first where it suffices; the system offers approximate location. |
| `ACCESS_BACKGROUND_LOCATION` | API 29+ | Separate, later request; requires a Play Console declaration and a clear user benefit. Never bundle with the foreground request. |
| `CAMERA` | Runtime since API 23 | Declare `android.hardware.camera` features as `required=false` where the camera is optional. |
| `RECORD_AUDIO` | Runtime since API 23 | Same pattern as camera. |
| `BODY_SENSORS` / `BODY_SENSORS_BACKGROUND` | Split in API 36-era health changes — verify current form | Health/body data moved toward Health Connect permissions; check the current guidance before requesting. |
| `ACTIVITY_RECOGNITION` | API 29+ | Runtime permission for step/activity detection. |
| `BLUETOOTH_SCAN` / `BLUETOOTH_CONNECT` / `BLUETOOTH_ADVERTISE` | API 31 | Replace the old `BLUETOOTH`/`BLUETOOTH_ADMIN` + location pairing for BLE on Android 12+. `neverForLocation` flag available on scan. |
| `NEARBY_WIFI_DEVICES` | API 33 | For Wi-Fi peer discovery without location. |
| `SCHEDULE_EXACT_ALARM` | API 31+ (special) | Not a normal runtime grant on API 33+ targets — user grants in Settings; Play declaration needed for most uses. |
| `USE_FULL_SCREEN_INTENT` | Restricted API 34+ | Limited to calling/alarm-style apps; Play declaration required. |
| `REQUEST_INSTALL_PACKAGES` | Special | Outside-Play installs; heavily policy-restricted. Games/apps on Play should not need it. |

## Normal / signature highlights

- `INTERNET` and `ACCESS_NETWORK_STATE` are normal (install-time),
  declared in the manifest, no runtime prompt.
- `VIBRATE`, `WAKE_LOCK`, `FOREGROUND_SERVICE` (+ per-type
  permissions below) are normal but FGS use is policy-checked.

## Foreground service types (declare type + permission)

Since API 34 every foreground service declares a type in the manifest
(`android:foregroundServiceType`) and the matching permission; Play
also requires an FGS declaration in Play Console.

| Type | Permission | Typical use |
|---|---|---|
| `dataSync` | `FOREGROUND_SERVICE_DATA_SYNC` | Upload/download/sync started by the user or app logic |
| `mediaPlayback` | `FOREGROUND_SERVICE_MEDIA_PLAYBACK` | Media3 playback sessions |
| `mediaProjection` | `FOREGROUND_SERVICE_MEDIA_PROJECTION` | Screen capture/sharing |
| `phoneCall` | `FOREGROUND_SERVICE_PHONE_CALL` | Call management |
| `location` | `FOREGROUND_SERVICE_LOCATION` | Navigation / tracking with a visible notification |
| `connectedDevice` | `FOREGROUND_SERVICE_CONNECTED_DEVICE` | Bluetooth/USB companion work |
| `health` | `FOREGROUND_SERVICE_HEALTH` | Sensor/health recording |
| `remoteMessaging` | `FOREGROUND_SERVICE_REMOTE_MESSAGING` | Message relay |
| `microphone` | `FOREGROUND_SERVICE_MICROPHONE` | Foreground recording (needs `RECORD_AUDIO` granted first) |
| `camera` | `FOREGROUND_SERVICE_CAMERA` | Foreground camera use (needs `CAMERA` granted first) |
| `systemExempted` / `specialUse` | Restricted | Only for qualifying system roles / declared special use — expect Play scrutiny |

API 35+ adds time limits to some types (notably `dataSync` media
processing windows) — check the FGS changes page for your targetSdk.

## Rules of thumb

1. Prefer **no-permission alternatives** first: photo picker (media),
   app-specific storage (files), approximate location, exact-alarm
   alternatives (WorkManager / inexact alarms).
2. Request **in context**, one purpose at a time, with an in-app
   rationale shown before the system dialog.
3. Handle **denial and "don't ask again"** gracefully — the feature
   degrades, the app keeps working.
4. Every sensitive permission in the manifest must be justified in
   the Play data safety form and, where required, a permissions
   declaration form.

Related: [`../docs/15-permissions-security-and-privacy.md`](../docs/15-permissions-security-and-privacy.md),
[`../docs/14-background-work-and-foreground-services.md`](../docs/14-background-work-and-foreground-services.md).
