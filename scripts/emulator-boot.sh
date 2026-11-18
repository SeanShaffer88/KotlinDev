#!/usr/bin/env bash
# emulator-boot.sh — List Android Virtual Devices (AVDs) and boot one,
# waiting until Android has fully started.
#
# Usage:
#   ./emulator-boot.sh --list
#   ./emulator-boot.sh --avd NAME [options]
#
# Options:
#   --list            List available AVD names and exit.
#   --avd NAME        AVD to boot (required unless --list).
#   --headless        Boot with no window (-no-window), for CI/scripts.
#   --snapshot NAME   Load a named snapshot on boot (-snapshot NAME).
#                     Omit it for a normal boot; add --no-snapshot-load
#                     behaviour by passing --cold for a cold boot instead.
#   --cold            Cold boot: ignore snapshots (-no-snapshot-load).
#   --timeout SECONDS Max seconds to wait for boot (default: 300).
#   -h, --help        Show this help.
#
# Requirements: Android SDK emulator on PATH or ANDROID_HOME / ANDROID_SDK_ROOT
# set; adb on PATH; at least one AVD created in Android Studio (AVD Manager).
set -euo pipefail

usage() { sed -n '2,20p' "$0"; }

LIST=0; AVD=""; HEADLESS=0; SNAPSHOT=""; COLD=0; TIMEOUT=300
while [[ $# -gt 0 ]]; do
  case "$1" in
    --list) LIST=1; shift ;;
    --avd) AVD="${2:?--avd needs a value}"; shift 2 ;;
    --headless) HEADLESS=1; shift ;;
    --snapshot) SNAPSHOT="${2:?--snapshot needs a value}"; shift 2 ;;
    --cold) COLD=1; shift ;;
    --timeout) TIMEOUT="${2:?--timeout needs a value}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
  esac
done

EMULATOR=""
if command -v emulator >/dev/null 2>&1; then EMULATOR="emulator";
elif [[ -n "${ANDROID_HOME:-}" && -x "$ANDROID_HOME/emulator/emulator" ]]; then EMULATOR="$ANDROID_HOME/emulator/emulator";
elif [[ -n "${ANDROID_SDK_ROOT:-}" && -x "$ANDROID_SDK_ROOT/emulator/emulator" ]]; then EMULATOR="$ANDROID_SDK_ROOT/emulator/emulator";
else echo "Error: emulator binary not found (PATH, ANDROID_HOME, ANDROID_SDK_ROOT all checked)." >&2; exit 1; fi

if [[ "$LIST" -eq 1 ]]; then "$EMULATOR" -list-avds; exit 0; fi
[[ -n "$AVD" ]] || { echo "Error: --avd is required (or use --list)." >&2; usage; exit 2; }
command -v adb >/dev/null || { echo "Error: adb not found on PATH." >&2; exit 1; }

ARGS=(-avd "$AVD")
[[ "$HEADLESS" -eq 1 ]] && ARGS+=(-no-window)
[[ -n "$SNAPSHOT" ]] && ARGS+=(-snapshot "$SNAPSHOT")
[[ "$COLD" -eq 1 ]] && ARGS+=(-no-snapshot-load)

echo ">> Booting AVD '$AVD' in the background..."
nohup "$EMULATOR" "${ARGS[@]}" >/dev/null 2>&1 &

echo ">> Waiting for a device..."
adb wait-for-device
echo ">> Waiting for boot to complete (timeout ${TIMEOUT}s)..."
ELAPSED=0
until [[ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" == "1" ]]; do
  sleep 5; ELAPSED=$((ELAPSED + 5))
  if [[ "$ELAPSED" -ge "$TIMEOUT" ]]; then
    echo "Error: emulator did not finish booting within ${TIMEOUT}s." >&2; exit 1
  fi
done
# Unlock the keyguard so the home screen is usable.
adb shell wm dismiss-keyguard >/dev/null 2>&1 || true
echo "Done: '$AVD' is booted and ready."
