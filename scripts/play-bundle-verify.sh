#!/usr/bin/env bash
# play-bundle-verify.sh — Sanity-check an Android App Bundle (.aab) the way
# Play will consume it: build a universal APK with bundletool and install it.
#
# Usage:
#   ./play-bundle-verify.sh --aab app-release.aab --bundletool bundletool.jar [options]
#   ./play-bundle-verify.sh --aab app-release.aab        # prints the exact commands
#
# Options:
#   --aab PATH         The .aab to verify (required).
#   --bundletool PATH  Path to the bundletool jar (e.g. bundletool-all-x.y.z.jar,
#                      from https://github.com/google/bundletool/releases).
#                      Without it, the script prints the exact commands to run
#                      yourself and exits without doing anything.
#   --out DIR          Working/output folder (default: ./bundle-verify).
#   --no-install       Build the universal APK but do not install it.
#   --serial SERIAL    adb device serial for the install step (optional).
#   -h, --help         Show this help.
#
# Requirements: java on PATH and adb on PATH (install step); a connected
# device/emulator for the install step. Signing: a universal APK built from a
# release AAB needs the AAB's signing key to install — pass bundletool your
# keystore via the printed manual commands if the debug-key fallback fails.
# This script never asks for or stores keystore passwords.
set -euo pipefail

usage() { sed -n '2,24p' "$0"; }

AAB=""; BUNDLETOOL=""; OUT="./bundle-verify"; INSTALL=1; SERIAL=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --aab) AAB="${2:?--aab needs a value}"; shift 2 ;;
    --bundletool) BUNDLETOOL="${2:?--bundletool needs a value}"; shift 2 ;;
    --out) OUT="${2:?--out needs a value}"; shift 2 ;;
    --no-install) INSTALL=0; shift ;;
    --serial) SERIAL="${2:?--serial needs a value}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
  esac
done
[[ -n "$AAB" && -f "$AAB" ]] || { echo "Error: --aab must point to an existing .aab file." >&2; usage; exit 2; }

if [[ -z "$BUNDLETOOL" ]]; then
  cat <<EOF
bundletool jar not given — nothing was run. To verify $AAB yourself:

  # 1. Download bundletool (single jar) from:
  #    https://github.com/google/bundletool/releases
  # 2. Build a universal APK set from the bundle:
  java -jar bundletool.jar build-apks --bundle=$AAB \\
      --output=$OUT/app.apks --mode=universal
  #    (signed release AAB? add: --ks=upload-keystore.jks --ks-key-alias=upload \\
  #     --ks-pass=pass:YOUR_PASSWORD --key-pass=pass:YOUR_PASSWORD)
  # 3. Extract and install the universal APK:
  unzip -o $OUT/app.apks universal.apk -d $OUT/
  adb install -r $OUT/universal.apk

Or re-run this script with --bundletool <path-to-jar>.
EOF
  exit 0
fi

[[ -f "$BUNDLETOOL" ]] || { echo "Error: bundletool jar not found: $BUNDLETOOL" >&2; exit 1; }
command -v java >/dev/null || { echo "Error: java not found on PATH." >&2; exit 1; }
mkdir -p "$OUT"

echo ">> Building universal APK set from $AAB ..."
java -jar "$BUNDLETOOL" build-apks --bundle="$AAB" --output="$OUT/app.apks" --mode=universal --overwrite

echo ">> Extracting universal.apk ..."
if command -v unzip >/dev/null 2>&1; then
  unzip -o "$OUT/app.apks" universal.apk -d "$OUT" >/dev/null
else
  ( cd "$OUT" && jar xf app.apks universal.apk )
fi
[[ -f "$OUT/universal.apk" ]] || { echo "Error: universal.apk not produced." >&2; exit 1; }
echo ">> Universal APK: $OUT/universal.apk ($(du -h "$OUT/universal.apk" | cut -f1))"

if [[ "$INSTALL" -eq 1 ]]; then
  command -v adb >/dev/null || { echo "Error: adb not found on PATH." >&2; exit 1; }
  ADB=(adb); [[ -n "$SERIAL" ]] && ADB=(adb -s "$SERIAL")
  echo ">> Installing universal APK ..."
  "${ADB[@]}" install -r "$OUT/universal.apk"
  echo "Done: bundle verified and installed. Launch the app and smoke-test it."
else
  echo "Done: bundle verified (install skipped with --no-install)."
fi
