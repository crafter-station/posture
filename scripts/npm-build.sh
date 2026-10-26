#!/bin/sh
set -e
cd "$(dirname "$0")/.."
swift build -c release --arch arm64 --arch x86_64
products=.build/apple/Products/Release
rm -rf dist
mkdir -p dist/bin dist/Posture.app/Contents/MacOS
cp "$products/posture" dist/bin/posture
cp "$products/PostureBar" dist/Posture.app/Contents/MacOS/PostureBar
cp bar/Info.plist dist/Posture.app/Contents/Info.plist
version=$(node -p "require('./package.json').version")
plutil -replace CFBundleShortVersionString -string "$version" dist/Posture.app/Contents/Info.plist
codesign --force --sign - dist/bin/posture
codesign --force --sign - dist/Posture.app
