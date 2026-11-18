#!/usr/bin/env bash
# adb-install-launch.sh — Build (debug), install, and launch an Android app.
#
# Usage:
#   ./adb-install-launch.sh --package com.example.app [options]
#
# Options:
#   --package ID      Application ID to launch (required).
#   --project DIR     Project folder containing gradlew (default: .).
#   --apk PATH        Install this APK instead of building.
#   --skip-build      Skip the Gradle build; install the newest debug APK found.
#   --activity NAME   Fully-qualified activity to start with `am start`.
#                     Without it, the app is launched via monkey (launcher intent).
#   --serial SERIAL   adb device serial to target (optional).
#   -h, --help        Show this help.
#
# Requirements: adb on PATH; Gradle wrapper in the project (unless --apk/--skip-build);
# a connected device or running emulator (`adb devices`).
set -euo pipefail

usage() { sed -n '2,20p' "$0"; }

PACKAGE=""; PROJECT="."; APK=""; SKIP_BUILD=0; ACTIVITY=""; SERIAL=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --package) PACKAGE="${2:?--package needs a value}"; shift 2 ;;
    --project) PROJECT="${2:?--project needs a value}"; shift 2 ;;
    --apk) APK="${2:?--apk needs a value}"; shift 2 ;;
    --skip-build) SKIP_BUILD=1; shift ;;
    --activity) ACTIVITY="${2:?--activity needs a value}"; shift 2 ;;
    --serial) SERIAL="${2:?--serial needs a value}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
  esac
done
[[ -n "$PACKAGE" ]] || { echo "Error: --package is required." >&2; usage; exit 2; }
command -v adb >/dev/null || { echo "Error: adb not found on PATH." >&2; exit 1; }

ADB=(adb); [[ -n "$SERIAL" ]] && ADB=(adb -s "$SERIAL")

if [[ -z "$APK" && "$SKIP_BUILD" -eq 0 ]]; then
  echo ">> Building debug APK in $PROJECT ..."
  ( cd "$PROJECT" && ./gradlew assembleDebug )
fi
if [[ -z "$APK" ]]; then
  APK="$(find "$PROJECT" -path '*outputs/apk/debug/*.apk' -type f -printf '%T@ %p\n' 2>/dev/null \
        | sort -nr | head -n1 | cut -d' ' -f2- || true)"
fi
[[ -n "$APK" && -f "$APK" ]] || { echo "Error: no debug APK found. Build first or pass --apk." >&2; exit 1; }

echo ">> Installing $APK ..."
"${ADB[@]}" install -r "$APK"

if [[ -n "$ACTIVITY" ]]; then
  echo ">> Launching $PACKAGE/$ACTIVITY ..."
  "${ADB[@]}" shell am start -n "$PACKAGE/$ACTIVITY"
else
  # No activity given: monkey sends the LAUNCHER intent, which works for any
  # app with a launcher activity without knowing its class name.
  echo ">> Launching $PACKAGE (launcher intent via monkey) ..."
  "${ADB[@]}" shell monkey -p "$PACKAGE" -c android.intent.category.LAUNCHER 1
fi
echo "Done."
