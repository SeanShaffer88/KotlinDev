#!/usr/bin/env bash
# adb-logcat-app.sh — Stream logcat filtered to one app's process.
#
# Usage:
#   ./adb-logcat-app.sh --package com.example.app [options]
#
# Options:
#   --package ID    Application ID to follow (required). The app must be
#                   running; this script reads its PID with `pidof`.
#   --clear         Clear the log buffer before streaming.
#   --save FILE     Also write the stream to FILE (via tee).
#   --serial SERIAL adb device serial to target (optional).
#   -h, --help      Show this help.
#
# Requirements: adb on PATH; a connected device/emulator; the app installed
# and running (start it first, e.g. with adb-install-launch.sh).
# Stop with Ctrl+C.
set -euo pipefail

usage() { sed -n '2,17p' "$0"; }

PACKAGE=""; CLEAR=0; SAVE=""; SERIAL=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --package) PACKAGE="${2:?--package needs a value}"; shift 2 ;;
    --clear) CLEAR=1; shift ;;
    --save) SAVE="${2:?--save needs a value}"; shift 2 ;;
    --serial) SERIAL="${2:?--serial needs a value}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
  esac
done
[[ -n "$PACKAGE" ]] || { echo "Error: --package is required." >&2; usage; exit 2; }
command -v adb >/dev/null || { echo "Error: adb not found on PATH." >&2; exit 1; }

ADB=(adb); [[ -n "$SERIAL" ]] && ADB=(adb -s "$SERIAL")

[[ "$CLEAR" -eq 1 ]] && "${ADB[@]}" logcat -c && echo ">> Log buffer cleared."

PID="$("${ADB[@]}" shell pidof "$PACKAGE" 2>/dev/null | tr -d '\r' | awk '{print $1}')"
if [[ -z "$PID" ]]; then
  echo "Error: $PACKAGE is not running (pidof returned nothing)." >&2
  echo "Start the app first, then re-run this script." >&2
  exit 1
fi

echo ">> Streaming logcat for $PACKAGE (pid $PID). Ctrl+C to stop."
if [[ -n "$SAVE" ]]; then
  "${ADB[@]}" logcat --pid="$PID" | tee "$SAVE"
else
  "${ADB[@]}" logcat --pid="$PID"
fi
