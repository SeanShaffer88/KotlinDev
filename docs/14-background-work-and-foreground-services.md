# Background Work and Foreground Services

Android limits what an app can do while it is not on screen, to protect battery and privacy. Almost all deferrable work belongs in WorkManager. Foreground services are a narrow exception for work the user can see and stop. This guide covers both, plus the older tools that still have a place.

Assumptions in this guide: WorkManager 2.12.0, `minSdk 24`, and apps targeting API 34, 35, and 36. Permission and timeout rules changed a lot in those releases, so the target version matters throughout.

## 1. Choose the right tool

| Need | Tool |
| --- | --- |
| Deferrable, must eventually run (sync, upload, cleanup) | WorkManager |
| User-started, must finish now even if app closes | WorkManager expedited / foreground service |
| Exact time matters (alarm clock, timer) | `AlarmManager` exact alarm, if eligible |
| System-scheduled job for a platform condition | JobScheduler (mostly via WorkManager) |
| Continuous user-visible work (music, navigation, call) | Foreground service with a declared type |

If the work can wait until conditions are good, it should. Work that "must run instantly in the background" usually does not, and the platform will throttle an app that insists on it.

## 2. WorkManager 2.12.0 basics

```kotlin
// build.gradle.kts
dependencies {
    implementation("androidx.work:work-runtime-ktx:2.12.0")
}
```

```kotlin
class UploadWorker(
    context: Context,
    params: WorkerParameters,
) : CoroutineWorker(context, params) {

    override suspend fun doWork(): Result {
        val id = inputData.getLong("article_id", -1)
        if (id < 0) return Result.failure()
        return try {
            repository.upload(id)
            Result.success()
        } catch (e: IOException) {
            if (runAttemptCount < 3) Result.retry() else Result.failure()
        }
    }
}

val request = OneTimeWorkRequestBuilder<UploadWorker>()
    .setInputData(workDataOf("article_id" to 42L))
    .setConstraints(
        Constraints.Builder()
            .setRequiredNetworkType(NetworkType.UNMETERED)
            .setRequiresCharging(false)
            .setRequiresBatteryNotLow(true)
            .build()
    )
    .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 30, TimeUnit.SECONDS)
    .build()

WorkManager.getInstance(context).enqueueUniqueWork(
    "upload-42", ExistingWorkPolicy.KEEP, request
)
```

Rules:

- Return `retry()` only for temporary failures (network, 5xx). Retrying a permanent failure (bad data, 4xx) wastes battery.
- Use unique work names for "the same job" so taps do not stack duplicate uploads.
- Keep `doWork()` idempotent: it may run again after a process death, so repeating it must be safe.
- WorkManager persists requests and survives reboots. Do not build your own persistence on top of it.

## 3. Constraints, expedited, and periodic work

**Constraints** describe when work may run: network type, charging, battery, storage, and device idle. Add every constraint the work truly needs, and no more — over-constrained work may wait for days.

**Expedited work** is for important, user-initiated tasks that should start quickly. It counts against a system quota (see section 6).

```kotlin
val expedited = OneTimeWorkRequestBuilder<UploadWorker>()
    .setExpedited(OutOfQuotaPolicy.RUN_AS_NON_EXPEDITED_WORK_REQUEST)
    .build()
```

Always set an out-of-quota fallback. Without one, the request fails when the quota is empty instead of running later.

**Periodic work** repeats at most once per interval, with a minimum interval of 15 minutes. It is not a timer: the system batches it.

```kotlin
val daily = PeriodicWorkRequestBuilder<SyncWorker>(24, TimeUnit.HOURS)
    .setConstraints(Constraints.Builder()
        .setRequiredNetworkType(NetworkType.CONNECTED).build())
    .build()
WorkManager.getInstance(context).enqueueUniquePeriodicWork(
    "daily-sync", ExistingPeriodicWorkPolicy.KEEP, daily
)
```

## 4. Foreground services: types and permissions

A foreground service (FGS) shows a persistent notification and is for work the user started and expects to continue: playback, navigation, a call, a file transfer they are watching.

Since target API 34, every foreground service must:

1. Declare a **type** in the manifest, for example `dataSync`, `mediaPlayback`, `location`, `connectedDevice`, `health`.
2. Request the matching type permission, for example `FOREGROUND_SERVICE_DATA_SYNC`.
3. Pass the same type when starting the service.
4. Request any runtime permission the type needs (for example location) before starting.

```xml
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_DATA_SYNC" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<service
    android:name=".sync.SyncService"
    android:foregroundServiceType="dataSync"
    android:exported="false" />
```

```kotlin
ServiceCompat.startForeground(
    this, 1001, notification,
    ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC,
)
```

Other target 34+ changes:

- An app in the background generally cannot start a foreground service. Start it while the app is visible, or from an allowed exemption such as a user interaction or a high-priority message.
- Google Play requires a declaration for each FGS type used, with a video showing the feature. Budget time for that review step.
- The notification must be shown promptly and must let the user understand, and where possible stop, the work.

## 5. Timeouts on target API 35

On target API 35, some FGS types gained system timeouts:

- `dataSync` — about 6 hours total per day across all such services; when the limit is reached the system stops the service.
- `mediaProcessing` — about 6 hours total per day; this type replaced `dataSync` for transcoding and similar media conversion work.

When a timeout approaches, the system calls `Service.onTimeout(startId, fgsType)` (API 35). Implement it: finish or checkpoint the work, call `stopSelf()`, and do not let the system kill the process mid-write.

Design for the limit instead of fighting it: move long sync and media conversion into WorkManager, which can resume, and keep the foreground service only for the part the user is watching.

## 6. Battery quotas and throttling

- **Expedited job quota:** the system gives each app a shared quota of expedited runtime, based on its standby bucket. Apps the user rarely opens get very little. Exhausted quota means delays.
- **Standby buckets:** active, working set, frequent, rare, and restricted. Restricted apps lose background privileges broadly.
- **Battery saver and Doze** defer network and jobs. Test with deviceidle commands rather than assuming timings.
- Batch network calls, prefer constraints over polling, and never hold a wake lock for work WorkManager could schedule.

## 7. JobScheduler and alarms

**JobScheduler** is the low-level system scheduler WorkManager is built on. Use it directly only for platform jobs WorkManager cannot express, such as a job tied to a specific system condition in a system or preloaded app. For normal apps, prefer WorkManager.

**Alarms** are for time, not for work scheduling:

- Inexact alarms (`setAndAllowWhileIdle` and friends) are the default and are batched by the system.
- Exact alarms need `SCHEDULE_EXACT_ALARM` or, for alarm-clock apps, `USE_EXACT_ALARM`. Since target API 31+, exact alarm access is denied by default; since API 33 the permission is not granted automatically and Play restricts it to apps whose core job is alarms, timers, or calendar reminders.
- If exact access is denied, offer the user an inexact fallback and explain the timing difference in plain words.
- Never use exact alarms as a heartbeat or sync timer.

## 8. Checklist

- [ ] Deferrable work is WorkManager, with sensible constraints.
- [ ] Workers are idempotent and retry only temporary failures.
- [ ] Expedited work sets an out-of-quota fallback policy.
- [ ] Periodic intervals are 15 minutes or longer.
- [ ] Every FGS declares a type, its permission, and a notification.
- [ ] `onTimeout` is handled for `dataSync` / `mediaProcessing`.
- [ ] Exact alarms are used only where the feature qualifies.
- [ ] No polling loops, no hand-held wake locks for deferred work.

## Official links

- WorkManager: https://developer.android.com/topic/libraries/architecture/workmanager
- WorkManager versions: https://developer.android.com/jetpack/androidx/releases/work
- Foreground services: https://developer.android.com/develop/background-work/services/fgs
- FGS types: https://developer.android.com/develop/background-work/services/fgs/types
- Background work overview: https://developer.android.com/develop/background-work
- Exact alarms: https://developer.android.com/training/alarms-and-reminders/exact-alarms
- Battery optimization: https://developer.android.com/training/monitoring-device-state/battery-monitoring
