#!/usr/bin/env bash
# adb-capture.sh — Capture a screenshot, and optionally a screen recording,
# from a connected device/emulator into a local folder.
#
# Usage:
#   ./adb-capture.sh [options]
#
# Options:
#   --out DIR        Local output folder (default: ./captures). Created if needed.
#   --record SECONDS Also record the screen for SECONDS (1-180, device limit).
#                    Recording runs after the screenshot.
#   --serial SERIAL  adb device serial to target (optional).
#   -h, --help       Show this help.
#
# Requirements: adb on PATH; a connected, unlocked device/emulator.
# Files are timestamped: shot-YYYYmmdd-HHMMSS.png / rec-YYYYmmdd-HHMMSS.mp4
set -euo pipefail

usage() { sed -n '2,16p' "$0"; }

OUT="./captures"; RECORD=""; SERIAL=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --out) OUT="${2:?--out needs a value}"; shift 2 ;;
    --record) RECORD="${2:?--record needs a value}"; shift 2 ;;
    --serial) SERIAL="${2:?--serial needs a value}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
  esac
done
command -v adb >/dev/null || { echo "Error: adb not found on PATH." >&2; exit 1; }

ADB=(adb); [[ -n "$SERIAL" ]] && ADB=(adb -s "$SERIAL")
mkdir -p "$OUT"
STAMP="$(date +%Y%m%d-%H%M%S)"

SHOT="$OUT/shot-$STAMP.png"
echo ">> Capturing screenshot -> $SHOT"
"${ADB[@]}" exec-out screencap -p > "$SHOT"

if [[ -n "$RECORD" ]]; then
  if ! [[ "$RECORD" =~ ^[0-9]+$ ]] || [[ "$RECORD" -lt 1 || "$RECORD" -gt 180 ]]; then
    echo "Error: --record must be a whole number of seconds between 1 and 180." >&2; exit 2
  fi
  REC="$OUT/rec-$STAMP.mp4"
  REMOTE="/sdcard/kotlindev-rec-$STAMP.mp4"
  echo ">> Recording ${RECORD}s -> $REC (keep the device on the screen you want)"
  "${ADB[@]}" shell screenrecord --time-limit "$RECORD" "$REMOTE"
  "${ADB[@]}" pull "$REMOTE" "$REC" >/dev/null
  "${ADB[@]}" shell rm -f "$REMOTE"
fi
echo "Done. Captures in $OUT"
