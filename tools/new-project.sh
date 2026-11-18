#!/usr/bin/env bash
# new-project.sh — scaffold a minimal Compose app from templates/compose-app.
#
# Usage: ./new-project.sh <ProjectName> <package.id> [destination-dir]
#   ./new-project.sh MyApp com.example.myapp ~/AndroidStudioProjects
#
# Copies templates/compose-app into <destination>/<ProjectName>, renames the
# com.example.app package folders to the requested package id, and substitutes
# the placeholders in settings.gradle.kts, app/build.gradle.kts and
# MainActivity.kt. Bash + coreutils only; no network access.
set -euo pipefail

if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
  echo "Usage: $0 <ProjectName> <package.id> [destination-dir]" >&2
  exit 2
fi

PROJECT_NAME="$1"
PACKAGE_ID="$2"
DEST_PARENT="${3:-.}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$(cd "$SCRIPT_DIR/../templates/compose-app" && pwd)"
DEST="$DEST_PARENT/$PROJECT_NAME"

case "$PACKAGE_ID" in
  *.*) ;;
  *) echo "Error: package id must contain a dot, e.g. com.example.myapp" >&2; exit 2 ;;
esac
if [ -e "$DEST" ]; then
  echo "Error: destination already exists: $DEST" >&2
  exit 1
fi

mkdir -p "$DEST"
cp -R "$TEMPLATE_DIR/." "$DEST/"

# Move the template package (com/example/app) to the requested package path.
OLD_PKG_DIR="$DEST/app/src/main/java/com/example/app"
NEW_PKG_DIR="$DEST/app/src/main/java/$(echo "$PACKAGE_ID" | tr '.' '/')"
mkdir -p "$(dirname "$NEW_PKG_DIR")"
if [ "$OLD_PKG_DIR" != "$NEW_PKG_DIR" ]; then
  mv "$OLD_PKG_DIR" "$NEW_PKG_DIR"
  # Remove now-empty template parents when they are not part of the new path.
  rmdir "$DEST/app/src/main/java/com/example" 2>/dev/null || true
  rmdir "$DEST/app/src/main/java/com" 2>/dev/null || true
fi

# Substitute placeholders (portable sed -i).
replace() {
  local file="$1" from="$2" to="$3"
  [ -f "$file" ] || return 0
  if sed --version >/dev/null 2>&1; then
    sed -i "s|$from|$to|g" "$file"
  else
    sed -i '' "s|$from|$to|g" "$file"
  fi
}
while IFS= read -r -d '' f; do
  replace "$f" "com.example.app" "$PACKAGE_ID"
  replace "$f" "ComposeApp" "$PROJECT_NAME"
done < <(find "$DEST" -type f \( -name '*.kts' -o -name '*.kt' -o -name '*.xml' -o -name '*.toml' \) -print0)

echo "Created $DEST"
echo "  package: $PACKAGE_ID"
echo "Open the folder in Android Studio, let Gradle sync, then run the app."
echo "Validate any time with: python3 tools/check-project.py \"$DEST\""
