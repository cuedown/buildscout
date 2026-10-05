#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

VERSION="${1:-0.1.0}"
APP_NAME="BuildScout"
DIST="$ROOT/dist"
APP="$DIST/$APP_NAME.app"

echo "Building $APP_NAME $VERSION…"
swift build -c release

rm -rf "$DIST"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp ".build/release/$APP_NAME" "$APP/Contents/MacOS/$APP_NAME"

if [ -d "$ROOT/browser-extension" ]; then
    ditto "$ROOT/browser-extension" "$APP/Contents/Resources/BrowserExtension"
fi

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>BuildScout</string>
    <key>CFBundleIdentifier</key>
    <string>ca.buildscout.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>BuildScout</string>
    <key>CFBundleDisplayName</key>
    <string>BuildScout</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>$VERSION</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLName</key>
            <string>ca.buildscout.capture</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>buildscout</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
PLIST

if command -v codesign >/dev/null 2>&1; then
    codesign --force --deep --sign - "$APP"
fi

ditto -c -k --sequesterRsrc --keepParent "$APP" "$DIST/BuildScout-macOS.zip"

if [ -d "$ROOT/browser-extension" ]; then
    (
        cd "$ROOT"
        ditto -c -k --sequesterRsrc browser-extension "$DIST/BuildScout-Capture-Extension.zip"
    )
fi

echo "Created:"
echo "  $APP"
echo "  $DIST/BuildScout-macOS.zip"
if [ -f "$DIST/BuildScout-Capture-Extension.zip" ]; then
    echo "  $DIST/BuildScout-Capture-Extension.zip"
fi
