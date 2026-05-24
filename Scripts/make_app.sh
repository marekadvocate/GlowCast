#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/build/GlowCast.app"

echo "==> building release"
swift build -c release --package-path "$ROOT"
BIN="$ROOT/.build/release/GlowCast"

echo "==> assembling $APP"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/GlowCast"
cp "$ROOT/Scripts/Info.plist" "$APP/Contents/Info.plist"
cp "$ROOT/Scripts/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"

echo "==> ad-hoc signing"
codesign --force --deep --sign - "$APP"

echo "==> done: $APP"
