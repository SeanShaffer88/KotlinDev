# Performance Audit Checklist

Run periodically and before any performance-sensitive release.
Method: [`../docs/17-performance-profiling-and-optimization.md`](../docs/17-performance-profiling-and-optimization.md);
games also use [`../docs/28-games-performance-input-audio-and-saves.md`](../docs/28-games-performance-input-audio-and-saves.md).

## Startup

- [ ] Cold start measured with Macrobenchmark (median, not best run)
      and compared with the previous release — regression >10% is a
      release blocker until explained.
- [ ] Baseline Profile current (regenerated after UI/navigation
      changes) and shipped via ProfileInstaller.
- [ ] No blocking I/O, database, or network work on the main thread
      during startup; Application.onCreate is thin.
- [ ] Startup trace (Perfetto / Android Studio profiler) reviewed:
      no surprise library initializers doing heavy work.

## Frame rendering

- [ ] Main lists scroll without jank: stable item keys, no heavy work
      in item composables, images sized to their targets (Coil/Glide).
- [ ] Recomposition counts checked on hot screens (Layout Inspector /
      Compose tooling); state hoisted, unstable parameters fixed.
- [ ] `dumpsys gfxinfo framestats` or Macrobenchmark frame timing on
      the top flows shows p90 frame time inside the refresh budget.
- [ ] Games: frame pacing library / swapchain behavior verified;
      allocation-free hot loop confirmed in the profiler.

## Memory

- [ ] LeakCanary clean on the main flows; heap dump reviewed after a
      full user journey.
- [ ] Bitmap/image memory bounded (no full-resolution decode for
      thumbnails); caches have explicit size limits.
- [ ] Memory does not grow across repeated navigation to the same
      screens (leaked collectors / unregistered listeners).

## Network, battery, storage

- [ ] Requests batched/cached where possible; OkHttp cache and
      retry/backoff sane; no polling loops (WorkManager/FCM instead).
- [ ] Battery Historian / vitals: no excessive wake locks; FGS use
      justified and typed.
- [ ] Database queries indexed and explained (`EXPLAIN QUERY PLAN`
      on the hot ones); Paging used for unbounded lists.
- [ ] App size trend checked per release (apkanalyzer compare);
      growth explained in the release notes when it jumps.
