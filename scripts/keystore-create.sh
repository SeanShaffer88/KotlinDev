#!/usr/bin/env bash
# keystore-create.sh — Guided creation of a release (upload) keystore
# with keytool, plus a password-free keystore.properties template.
#
# Usage:
#   ./keystore-create.sh [options]
#
# Options:
#   --output PATH     Keystore file to create (default: ./upload-keystore.jks).
#                     Refuses to overwrite an existing file.
#   --alias NAME      Key alias (default: upload).
#   --validity DAYS   Key validity in days (default: 10000, ~27 years;
#                     Play App Signing expects long validity).
#   -h, --help        Show this help.
#
# Requirements: keytool on PATH (ships with the JDK).
#
# SAFETY — read this:
#   * Passwords are typed at hidden prompts and passed to keytool through
#     environment variables; they are never echoed and never written to disk
#     by this script. The keystore.properties it writes contains PLACEHOLDERS.
#   * If you lose this keystore or its password and you are NOT enrolled in
#     Play App Signing, you can never update your app again.
#   * Back the keystore up in at least two safe places OUTSIDE the repo, and
#     NEVER commit it (add *.jks / *.keystore and keystore.properties to
#     .gitignore).
set -euo pipefail

usage() { sed -n '2,26p' "$0"; }

OUTPUT="./upload-keystore.jks"; ALIAS="upload"; VALIDITY="10000"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --output) OUTPUT="${2:?--output needs a value}"; shift 2 ;;
    --alias) ALIAS="${2:?--alias needs a value}"; shift 2 ;;
    --validity) VALIDITY="${2:?--validity needs a value}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
  esac
done
command -v keytool >/dev/null || { echo "Error: keytool not found on PATH (install a JDK)." >&2; exit 1; }
[[ ! -e "$OUTPUT" ]] || { echo "Error: $OUTPUT already exists. Refusing to overwrite a keystore." >&2; exit 1; }

read -r -p "Your name (CN, e.g. Ada Lovelace): " CN
read -r -p "Organization (O, optional): " ORG
read -r -p "City (L, optional): " CITY
read -r -p "State/Province (ST, optional): " STATE
read -r -p "Country code (C, two letters, e.g. US): " COUNTRY
DNAME="CN=${CN}"
[[ -n "$ORG" ]] && DNAME+=", O=${ORG}"
[[ -n "$CITY" ]] && DNAME+=", L=${CITY}"
[[ -n "$STATE" ]] && DNAME+=", ST=${STATE}"
[[ -n "$COUNTRY" ]] && DNAME+=", C=${COUNTRY}"

read -r -s -p "Keystore password (min 6 chars, hidden): " STORE_PASS; echo
read -r -s -p "Repeat keystore password: " STORE_PASS2; echo
[[ "$STORE_PASS" == "$STORE_PASS2" ]] || { echo "Error: passwords do not match." >&2; exit 1; }
[[ ${#STORE_PASS} -ge 6 ]] || { echo "Error: password must be at least 6 characters." >&2; exit 1; }

# keytool reads passwords from the environment with :env — nothing is echoed,
# printed, or stored in shell history by this script.
export KS_STORE_PASS="$STORE_PASS" KS_KEY_PASS="$STORE_PASS"
keytool -genkeypair -v \
  -keystore "$OUTPUT" -storetype PKCS12 \
  -storepass:env KS_STORE_PASS -keypass:env KS_KEY_PASS \
  -alias "$ALIAS" -keyalg RSA -keysize 2048 -validity "$VALIDITY" \
  -dname "$DNAME"
unset KS_STORE_PASS KS_KEY_PASS STORE_PASS STORE_PASS2

PROPS="$(dirname "$OUTPUT")/keystore.properties"
if [[ ! -e "$PROPS" ]]; then
  cat > "$PROPS" <<EOF
# keystore.properties — fill in locally. NEVER commit this file with real
# passwords in it, and never commit the keystore itself.
storeFile=$(basename "$OUTPUT")
storePassword=REPLACE_ME_LOCAL_ONLY
keyAlias=$ALIAS
keyPassword=REPLACE_ME_LOCAL_ONLY
EOF
  echo ">> Wrote template $PROPS (placeholders only, no real passwords)."
fi

echo
echo "Done: $OUTPUT (alias: $ALIAS)"
echo "NOW: 1) Back this keystore up in two safe places OUTSIDE the repo."
echo "     2) Add '*.jks', '*.keystore' and 'keystore.properties' to .gitignore."
echo "     3) Keep the password in a password manager — it cannot be recovered."
