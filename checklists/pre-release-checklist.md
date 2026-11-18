# Pre-Release Checklist

Run on the release candidate before uploading anything.
Release process: [`../docs/19-build-signing-release-and-google-play.md`](../docs/19-build-signing-release-and-google-play.md).

## Build

- [ ] Version code incremented; version name matches the release notes.
- [ ] `./gradlew bundleRelease` produces the AAB from a clean checkout
      of the release commit (not a dirty working tree).
- [ ] Release build has R8 minification + resource shrinking on;
      mapping file (`mapping.txt`) archived for crash deobfuscation.
- [ ] Baseline Profile generated and included; startup checked with
      Macrobenchmark against the previous release.
- [ ] App size reviewed with apkanalyzer / bundletool
      ([`../reference/adb-and-tooling-commands.md`](../reference/adb-and-tooling-commands.md));
      no accidental test assets, debug libraries, or duplicate media.
- [ ] Native libraries (if any) are 64-bit and 16 KB page-aligned
      ([`../reference/play-requirements-and-deadlines.md`](../reference/play-requirements-and-deadlines.md)).

## Code and quality

- [ ] Full test suite green: unit, Flow (Turbine), repository/fakes,
      Compose UI tests; screenshot tests (Roborazzi) updated and reviewed.
- [ ] Lint clean on the release variant (no new errors; baseline not
      grown without a recorded reason).
- [ ] LeakCanary shows no leaks on the main flows (debug build pass).
- [ ] No debug logging of personal data, no test endpoints, no
      placeholder keys in the release build.
- [ ] Offline / airplane-mode pass: core flows degrade gracefully;
      WorkManager sync resumes.

## Behavior

- [ ] Fresh install, upgrade-from-previous-release, and
      clear-data flows all tested on a real device or emulator.
- [ ] Process death + rotation + dark theme + font scale 1.3x pass on
      the top screens.
- [ ] Permissions: every prompt appears in context; denial paths work
      ([`../reference/permissions-table.md`](../reference/permissions-table.md)).
- [ ] Billing (if present): license-tester purchase, restore,
      pending, and subscription states verified on a test track.
- [ ] Anything not actually run on a device/emulator is recorded as
      **Unverified** in the release notes — not silently implied.

## Signing

- [ ] Upload key + passwords pulled from the secret store (not the
      repo); Play App Signing enrollment confirmed in Play Console.
- [ ] AAB signature verified (`jarsigner -verify` / Play Console
      upload check) before the rollout starts.
