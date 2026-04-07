#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/.build/release"
DIST_DIR="$ROOT_DIR/.dist"
APP_DIR="$DIST_DIR/WaterBar.app"
ICONSET_DIR="$DIST_DIR/AppIcon.iconset"
ICNS_PATH="$DIST_DIR/AppIcon.icns"
SOURCE_ICON="$ROOT_DIR/Support/water.png"
MENU_BAR_ICON="$ROOT_DIR/Sources/WaterBarKit/Resources/menuBarIcon.png"

swift "$ROOT_DIR/Scripts/generate-menu-bar-icon.swift" "$SOURCE_ICON" "$MENU_BAR_ICON"
swift build -c release --package-path "$ROOT_DIR"
rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"
sips -z 16 16 "$SOURCE_ICON" --out "$ICONSET_DIR/icon_16x16.png" >/dev/null
sips -z 32 32 "$SOURCE_ICON" --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null
sips -z 32 32 "$SOURCE_ICON" --out "$ICONSET_DIR/icon_32x32.png" >/dev/null
sips -z 64 64 "$SOURCE_ICON" --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null
sips -z 128 128 "$SOURCE_ICON" --out "$ICONSET_DIR/icon_128x128.png" >/dev/null
sips -z 256 256 "$SOURCE_ICON" --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null
sips -z 256 256 "$SOURCE_ICON" --out "$ICONSET_DIR/icon_256x256.png" >/dev/null
sips -z 512 512 "$SOURCE_ICON" --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null
sips -z 512 512 "$SOURCE_ICON" --out "$ICONSET_DIR/icon_512x512.png" >/dev/null
sips -z 1024 1024 "$SOURCE_ICON" --out "$ICONSET_DIR/icon_512x512@2x.png" >/dev/null
iconutil -c icns "$ICONSET_DIR" -o "$ICNS_PATH"

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cp "$BUILD_DIR/WaterBar" "$APP_DIR/Contents/MacOS/WaterBar"
cp "$ROOT_DIR/Support/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$ICNS_PATH" "$APP_DIR/Contents/Resources/AppIcon.icns"
resource_bundles=("$BUILD_DIR"/*.bundle(N))
if (( ${#resource_bundles} > 0 )); then
  cp -R "${resource_bundles[@]}" "$APP_DIR/Contents/Resources/"
fi
codesign --force --deep --sign - "$APP_DIR" >/dev/null

echo "Built $APP_DIR"
