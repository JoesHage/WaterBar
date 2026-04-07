#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="$ROOT_DIR/.dist"
APP_PATH="$DIST_DIR/WaterBar.app"
DMG_ASSETS_DIR="$DIST_DIR/dmg-assets"
BACKGROUND_PATH="$DMG_ASSETS_DIR/background.png"
BACKGROUND_2X_PATH="$DMG_ASSETS_DIR/background@2x.png"
VOLUME_NAME="WaterBar"
DMG_PATH="$DIST_DIR/WaterBar.dmg"
SPEC_PATH="$ROOT_DIR/appdmg.json"

"$ROOT_DIR/Scripts/build-app.sh"

rm -rf "$DMG_ASSETS_DIR" "$DMG_PATH"
mkdir -p "$DMG_ASSETS_DIR"

swift "$ROOT_DIR/Scripts/generate-dmg-background.swift" "$BACKGROUND_PATH" 640 400
swift "$ROOT_DIR/Scripts/generate-dmg-background.swift" "$BACKGROUND_2X_PATH" 1280 800

npx appdmg "$SPEC_PATH" "$DMG_PATH"

echo "Built $DMG_PATH"
