#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="File Time Edit"
EXECUTABLE_NAME="FileTimeEdit"
VERSION="${VERSION:-0.1.0}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"
BUNDLE_IDENTIFIER="${BUNDLE_IDENTIFIER:-io.github.filetimeedit}"
IDENTITY="${IDENTITY:--}"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"

cd "$ROOT_DIR"
swift build -c release
BIN_DIR="$(swift build -c release --show-bin-path)"

rm -rf "$APP_DIR"
mkdir -p "$CONTENTS_DIR/MacOS" "$CONTENTS_DIR/Resources"
cp "$BIN_DIR/$EXECUTABLE_NAME" "$CONTENTS_DIR/MacOS/$EXECUTABLE_NAME"
cp "$ROOT_DIR/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"

/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_IDENTIFIER" "$CONTENTS_DIR/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$CONTENTS_DIR/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$CONTENTS_DIR/Info.plist"

swift "$ROOT_DIR/Scripts/make-icon.swift" "$CONTENTS_DIR/Resources/AppIcon.icns"
codesign --force --options runtime --timestamp --sign "$IDENTITY" "$APP_DIR"

rm -f "$DIST_DIR/FileTimeEdit-$VERSION.zip"
ditto -c -k --sequesterRsrc --keepParent \
    "$APP_DIR" "$DIST_DIR/FileTimeEdit-$VERSION.zip"

echo "Created: $APP_DIR"
echo "Created: $DIST_DIR/FileTimeEdit-$VERSION.zip"