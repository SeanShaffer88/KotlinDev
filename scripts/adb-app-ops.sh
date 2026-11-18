#!/usr/bin/env bash
# adb-app-ops.sh — Everyday operations on one installed app.
#
# Usage:
#   ./adb-app-ops.sh --package com.example.app [operation ...]
#
# Operations (at least one required; they run in the order listed here):
#   --force-stop        Force-stop the app.
#   --grant PERMISSION  Grant a runtime permission (e.g. android.permission.CAMERA).
#   --revoke PERMISSION Revoke a runtime permission.
#   --settings          Open the app's system settings page.
#   --reset             DESTRUCTIVE: clear ALL app data (pm clear). Asks you to
#                       type the package ID to confirm before doing anything.
#   --serial SERIAL     adb device serial to target (optional).
#   -h, --help          Show this help.
#
# Note on cache: Android has no reliable adb command that clears ONLY an
# app's cache without touching its data. `pm clear` wipes both. To trim
# caches system-wide the system itself uses `pm trim-caches`; per-app cache
# clearing is done from Settings > Apps on the device. This script will not
# pretend otherwise.
#
# Requirements: adb on PATH; a connected device/emulator; the app installed.
set -euo pipefail

usage() { sed -n '2,21p' "$0"; }

PACKAGE=""; SERIAL=""; FORCE_STOP=0; SETTINGS=0; RESET=0
GRANTS=(); REVOKES=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --package) PACKAGE="${2:?--package needs a value}"; shift 2 ;;
    --serial) SERIAL="${2:?--serial needs a value}"; shift 2 ;;
    --force-stop) FORCE_STOP=1; shift ;;
    --settings) SETTINGS=1; shift ;;
    --reset) RESET=1; shift ;;
    --grant) GRANTS+=("${2:?--grant needs a permission}"); shift 2 ;;
    --revoke) REVOKES+=("${2:?--revoke needs a permission}"); shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
  esac
done
[[ -n "$PACKAGE" ]] || { echo "Error: --package is required." >&2; usage; exit 2; }
if [[ "$FORCE_STOP" -eq 0 && "$SETTINGS" -eq 0 && "$RESET" -eq 0 \
      && ${#GRANTS[@]} -eq 0 && ${#REVOKES[@]} -eq 0 ]]; then
  echo "Error: choose at least one operation." >&2; usage; exit 2
fi
command -v adb >/dev/null || { echo "Error: adb not found on PATH." >&2; exit 1; }
ADB=(adb); [[ -n "$SERIAL" ]] && ADB=(adb -s "$SERIAL")

if [[ "$RESET" -eq 1 ]]; then
  echo "WARNING: --reset deletes ALL data for $PACKAGE (accounts, saves, files)."
  read -r -p "Type the package ID to confirm: " CONFIRM
  [[ "$CONFIRM" == "$PACKAGE" ]] || { echo "Aborted: confirmation did not match."; exit 1; }
fi

[[ "$FORCE_STOP" -eq 1 ]] && { echo ">> Force-stopping $PACKAGE"; "${ADB[@]}" shell am force-stop "$PACKAGE"; }
for p in "${GRANTS[@]:-}";  do [[ -n "$p" ]] && { echo ">> Granting $p";  "${ADB[@]}" shell pm grant  "$PACKAGE" "$p"; }; done
for p in "${REVOKES[@]:-}"; do [[ -n "$p" ]] && { echo ">> Revoking $p"; "${ADB[@]}" shell pm revoke "$PACKAGE" "$p"; }; done
if [[ "$SETTINGS" -eq 1 ]]; then
  echo ">> Opening app settings for $PACKAGE"
  "${ADB[@]}" shell am start -a android.settings.APPLICATION_DETAILS_SETTINGS -d "package:$PACKAGE"
fi
[[ "$RESET" -eq 1 ]] && { echo ">> Clearing all data for $PACKAGE"; "${ADB[@]}" shell pm clear "$PACKAGE"; }
echo "Done."
