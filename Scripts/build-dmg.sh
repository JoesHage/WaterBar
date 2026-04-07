#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="$ROOT_DIR/.dist"
APP_PATH="$DIST_DIR/WaterBar.app"
DMG_STAGING="$DIST_DIR/dmg-root"
VOLUME_NAME="WaterBar"
DMG_PATH="$DIST_DIR/WaterBar.dmg"

"$ROOT_DIR/Scripts/build-app.sh"

rm -rf "$DMG_STAGING" "$DMG_PATH"
mkdir -p "$DMG_STAGING"

cp -R "$APP_PATH" "$DMG_STAGING/WaterBar.app"
ln -s /Applications "$DMG_STAGING/Applications"

hdiutil create \
  -volname "$VOLUME_NAME" \
  -srcfolder "$DMG_STAGING" \
  -ov \
  -format UDZO \
  "$DMG_PATH" >/dev/null

echo "Built $DMG_PATH"
