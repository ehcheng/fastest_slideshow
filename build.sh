#!/bin/bash
# Build "Fastest Slideshow.app" (Apple Silicon, macOS 13+) and zip it into builds/.
#   ./build.sh            ad-hoc signed (runs on this Mac)
#   ./build.sh --release  Developer ID signed + notarized + stapled (for other Macs)
# Release credentials: ~/.vpm-signing.json {identity, appleId, password, teamId}
set -euo pipefail
cd "$(dirname "$0")"

APP="build/Fastest Slideshow.app"
BIN="$APP/Contents/MacOS/FastestSlideshow"
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" Info.plist)
ZIP="builds/FastestSlideshow-$VERSION.zip"

rm -rf build
mkdir -p "$APP/Contents/MacOS" builds
cp Info.plist "$APP/Contents/Info.plist"
swiftc -Osize -wmo -swift-version 5 -target arm64-apple-macos13 \
  -Xlinker -dead_strip main.swift -o "$BIN"
strip -x "$BIN"

if [[ "${1:-}" == "--release" ]]; then
  cred() { /usr/bin/python3 -c "import json,os,sys;print(json.load(open(os.path.expanduser('~/.vpm-signing.json')))[sys.argv[1]])" "$1"; }
  codesign --force --options runtime --timestamp --sign "$(cred identity)" "$APP"
  ditto -c -k --keepParent "$APP" "$ZIP"
  xcrun notarytool submit "$ZIP" --wait \
    --apple-id "$(cred appleId)" --password "$(cred password)" --team-id "$(cred teamId)"
  xcrun stapler staple "$APP"
else
  codesign --force --sign - "$APP"
fi

rm -f "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"
echo "Built $ZIP ($(du -k "$ZIP" | cut -f1) KB)"
