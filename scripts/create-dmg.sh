#!/bin/bash
set -euo pipefail

# macthecat - Fancy DMG Creator
# Creates a branded drag-to-Applications DMG installer

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
APP_NAME="MenuBarCat"
VOL_NAME="macthecat"
DMG_OUTPUT="$PROJECT_DIR/macthecat.dmg"
BG_IMAGE="$PROJECT_DIR/dmg-background@2x.png"

# Find the built .app
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "${APP_NAME}.app" -path "*/Build/Products/*" -type d 2>/dev/null | head -1)

if [ -z "$APP_PATH" ]; then
    echo "Error: ${APP_NAME}.app not found in DerivedData. Build the project in Xcode first."
    exit 1
fi

echo "Using app: $APP_PATH"

# Clean up any previous DMG
rm -f "$DMG_OUTPUT"

# Create DMG with create-dmg
create-dmg \
    --volname "$VOL_NAME" \
    --background "$BG_IMAGE" \
    --window-pos 200 120 \
    --window-size 660 400 \
    --icon-size 128 \
    --icon "${APP_NAME}.app" 170 200 \
    --app-drop-link 490 200 \
    --no-internet-enable \
    --hide-extension "${APP_NAME}.app" \
    "$DMG_OUTPUT" \
    "$APP_PATH"

echo ""
echo "DMG created: $DMG_OUTPUT"
echo "Size: $(du -h "$DMG_OUTPUT" | cut -f1)"
