# Reference — adb and Tooling Commands

Everyday command-line tools. `adb`, `bundletool`, `apkanalyzer`, and
`lint` ship with the Android SDK (platform-tools / cmdline-tools);
paths below assume they are on `PATH`. Snapshot checked November 2026.

## adb — devices and install

```bash
adb devices -l                       # list connected devices/emulators
adb -s <serial> install -r app.apk   # install (replace) on one device
adb -s <serial> uninstall com.example.app
adb shell pm clear com.example.app   # wipe app data
adb shell am start -n com.example.app/.MainActivity
adb shell pidof com.example.app
adb kill-server && adb start-server  # restart a wedged adb
```

## adb — debugging

```bash
adb logcat -v threadtime --pid=$(adb shell pidof com.example.app)
adb logcat *:E                       # errors only (noisy — prefer pid filter)
adb shell dumpsys activity top       # what is on screen / activity state
adb shell dumpsys meminfo com.example.app
adb shell dumpsys gfxinfo com.example.app framestats   # jank data
adb shell dumpsys battery
adb bugreport bugreport.zip          # full device report for hard bugs
adb shell screencap -p /sdcard/shot.png && adb pull /sdcard/shot.png
adb shell screenrecord /sdcard/demo.mp4   # Ctrl-C to stop, then adb pull
adb shell input tap 500 500          # synthetic input
adb shell settings get global animator_duration_scale
```

## adb — files, permissions, app info

```bash
adb push local.txt /sdcard/Download/
adb pull /sdcard/Download/remote.txt .
adb shell pm list packages | grep example
adb shell dumpsys package com.example.app | grep -A5 permissions
adb shell pm grant com.example.app android.permission.POST_NOTIFICATIONS
adb shell pm revoke com.example.app android.permission.CAMERA
adb shell appops set com.example.app POST_NOTIFICATION allow
adb reverse tcp:8080 tcp:8080        # device localhost -> dev machine (local servers)
adb forward tcp:8080 tcp:8080        # dev machine -> device
```

## Emulator (AVD)

```bash
emulator -list-avds
emulator -avd Pixel_9_API_36 -no-snapshot-load     # cold boot
emulator -avd Pixel_9_API_36 -wipe-data
sdkmanager --list | grep "system-images;android-36"
sdkmanager "platforms;android-36" "platform-tools" "emulator"
avdmanager list device | grep pixel
# Inside the emulator: extended controls give location, network
# throttling, battery, foldable posture, and snapshot control.
```

Useful emulator habits: keep one API 36 AVD for the target, one at
minSdk for compatibility, and one large-screen/foldable AVD for form
factor checks ([`../docs/21-form-factors-wear-tv-auto-foldables.md`](../docs/21-form-factors-wear-tv-auto-foldables.md)).

## bundletool — AAB inspection and testing

Play ships AABs; bundletool turns one into testable APKs locally.

```bash
# Build a universal APK for quick device testing
java -jar bundletool.jar build-apks --bundle=app-release.aab \
  --output=app.apks --mode=universal \
  --ks=upload.jks --ks-key-alias=upload --ks-pass=pass:... --key-pass=pass:...

java -jar bundletool.jar install-apks --apks=app.apks   # device-specific set
java -jar bundletool.jar get-size total --apks=app.apks # download-size estimate
java -jar bundletool.jar validate --bundle=app-release.aab
java -jar bundletool.jar dump manifest --bundle=app-release.aab
```

Never commit the keystore or its passwords (see `AGENTS.md` rule 9);
the commands above take them from your local secret store.

## apkanalyzer — APK/AAB contents

```bash
apkanalyzer apk summary app.apk                 # package, versionCode/Name
apkanalyzer manifest print app.apk | head -n 80
apkanalyzer dex packages app.apk | sort -k3 -rn | head   # method/size hotspots
apkanalyzer files list app.apk
apkanalyzer apk compare old.apk new.apk         # size diff between builds
```

## Lint

```bash
./gradlew lintRelease                 # full lint on the release variant
./gradlew :app:lintDebug
# Reports: app/build/reports/lint-results-release.html (+ .xml / .sarif)
```

Treat new lint errors as build failures in CI; baseline only known,
accepted issues (`lint-baseline.xml`) and burn the baseline down over
time ([`../docs/30-ci-cd-and-automation.md`](../docs/30-ci-cd-and-automation.md)).

## Gradle everyday

```bash
./gradlew assembleDebug               # debug APK
./gradlew bundleRelease               # release AAB (the Play artifact)
./gradlew test                        # JVM unit tests, all modules
./gradlew connectedDebugAndroidTest   # instrumented tests on a device/emulator
./gradlew :app:dependencies --configuration releaseRuntimeClasspath
./gradlew --refresh-dependencies ...  # after a repository/version fix
./gradlew clean
```

## scrcpy — mirror a real device

[scrcpy](https://github.com/Genymobile/scrcpy) (free, open source)
mirrors and controls a physical device over adb from the dev machine —
the fastest way to demo, record, and test touch/controller flows on
real hardware without extra tooling.

```bash
scrcpy                       # mirror the connected device
scrcpy --record demo.mp4     # mirror + record
scrcpy -m 1024 --video-bit-rate 4M   # lighter stream for slow links
```

Related: [`../docs/16-testing-strategy.md`](../docs/16-testing-strategy.md),
[`../docs/19-build-signing-release-and-google-play.md`](../docs/19-build-signing-release-and-google-play.md).
