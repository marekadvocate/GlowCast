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

echo "==> signing"
# Prefer the stable self-signed identity so macOS TCC grants (Input Monitoring)
# persist across rebuilds; fall back to ad-hoc for anyone without that cert.
if security find-certificate -c "GlowCast Self Signed" >/dev/null 2>&1; then
    codesign --force --deep --sign "GlowCast Self Signed" "$APP"
else
    codesign --force --deep --sign - "$APP"
fi

echo "==> done: $APP"
