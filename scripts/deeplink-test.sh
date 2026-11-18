#!/usr/bin/env bash
# deeplink-test.sh — Test deep links / Android App Links from adb.
#
# Usage:
#   ./deeplink-test.sh --url URL [options]
#   ./deeplink-test.sh --package ID --list-links
#
# Options:
#   --url URL        The link to open with a VIEW intent (e.g.
#                    https://example.com/item/42 or myapp://item/42).
#   --package ID     Restrict the VIEW intent to this app, and/or the app
#                    whose link verification state is listed.
#   --list-links     Print the app's App Links verification state and exit:
#                    runs `pm get-app-links` and the domain-verify dumpsys.
#   --re-verify      Ask the system to re-run App Links verification
#                    (`pm verify-app-links --re-verify`) for --package.
#   --serial SERIAL  adb device serial to target (optional).
#   -h, --help       Show this help.
#
# Requirements: adb on PATH; a connected device/emulator; the app installed.
# For https App Links to open the app directly, the domain must serve a valid
# assetlinks.json and the app must declare the intent-filter with
# android:autoVerify="true" — verification state is what --list-links shows.
set -euo pipefail

usage() { sed -n '2,20p' "$0"; }

URL=""; PACKAGE=""; LIST_LINKS=0; RE_VERIFY=0; SERIAL=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --url) URL="${2:?--url needs a value}"; shift 2 ;;
    --package) PACKAGE="${2:?--package needs a value}"; shift 2 ;;
    --list-links) LIST_LINKS=1; shift ;;
    --re-verify) RE_VERIFY=1; shift ;;
    --serial) SERIAL="${2:?--serial needs a value}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
  esac
done
command -v adb >/dev/null || { echo "Error: adb not found on PATH." >&2; exit 1; }
ADB=(adb); [[ -n "$SERIAL" ]] && ADB=(adb -s "$SERIAL")

if [[ "$RE_VERIFY" -eq 1 ]]; then
  [[ -n "$PACKAGE" ]] || { echo "Error: --re-verify needs --package." >&2; exit 2; }
  echo ">> Re-running App Links verification for $PACKAGE ..."
  "${ADB[@]}" shell pm verify-app-links --re-verify "$PACKAGE" || true
fi

if [[ "$LIST_LINKS" -eq 1 ]]; then
  [[ -n "$PACKAGE" ]] || { echo "Error: --list-links needs --package." >&2; exit 2; }
  echo ">> App Links state for $PACKAGE:"
  "${ADB[@]}" shell pm get-app-links "$PACKAGE" || true
  echo
  echo ">> Domain verification detail:"
  "${ADB[@]}" shell dumpsys package domain-preference "$PACKAGE" 2>/dev/null \
    | grep -A3 -i "$PACKAGE" || echo "(no domain-preference output for this package)"
  exit 0
fi

[[ -n "$URL" ]] || { echo "Error: --url is required (or use --list-links)." >&2; usage; exit 2; }
echo ">> Firing VIEW intent for: $URL"
if [[ -n "$PACKAGE" ]]; then
  "${ADB[@]}" shell am start -a android.intent.action.VIEW -d "$URL" -p "$PACKAGE"
else
  "${ADB[@]}" shell am start -a android.intent.action.VIEW -d "$URL"
fi
echo "Done. Watch the device: the app (or a chooser) should now be in front."
