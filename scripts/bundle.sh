#!/bin/sh
set -e
cd "$(dirname "$0")/.."
swift build -c release
app="${1:-$HOME/Applications}/Posture.app"
pkill -x PostureBar 2>/dev/null || true
rm -rf "$app"
mkdir -p "$app/Contents/MacOS"
cp .build/release/PostureBar "$app/Contents/MacOS/PostureBar"
cp bar/Info.plist "$app/Contents/Info.plist"
codesign --force --sign - "$app"
echo "$app"
