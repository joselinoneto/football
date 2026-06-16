#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

BID="app.zeneto.football"
RUNTIME="com.apple.CoreSimulator.SimRuntime.iOS-26-5"
IPHONE_TYPE="com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro-Max"
IPAD_TYPE="com.apple.CoreSimulator.SimDeviceType.iPad-Pro-13-inch-M4-8GB"
DD="build-screens"

echo "==> Building app for simulator..."
xcodebuild -project football.xcodeproj -scheme football \
  -configuration Debug -sdk iphonesimulator \
  -derivedDataPath "$DD" \
  -destination 'generic/platform=iOS Simulator' \
  build >/tmp/jf-build.log 2>&1 || { echo "BUILD FAILED"; tail -40 /tmp/jf-build.log; exit 1; }

APP="$DD/Build/Products/Debug-iphonesimulator/football.app"
[ -d "$APP" ] || { echo "App not found at $APP"; ls -R "$DD/Build/Products" | head; exit 1; }
echo "==> Built: $APP"

# (re)create clean devices
for name in "JF-iPhone" "JF-iPad"; do
  old=$(xcrun simctl list devices | grep "$name (" | grep -oE '[0-9A-F-]{36}' | head -1 || true)
  [ -n "$old" ] && xcrun simctl delete "$old" || true
done
IPHONE=$(xcrun simctl create "JF-iPhone" "$IPHONE_TYPE" "$RUNTIME")
IPAD=$(xcrun simctl create "JF-iPad" "$IPAD_TYPE" "$RUNTIME")
echo "==> iPhone=$IPHONE  iPad=$IPAD"

shoot() { # udid bundle outfile lang appearance extraArg
  local udid="$1" out="$3" lang="$4" appr="$5" extra="${6:-}"
  xcrun simctl ui "$udid" appearance "$appr" >/dev/null 2>&1 || true
  xcrun simctl terminate "$udid" "$BID" >/dev/null 2>&1 || true
  if [ -n "$extra" ]; then
    xcrun simctl launch "$udid" "$BID" -AppleLanguages "($lang)" -AppleLocale "${lang/-/_}" "$extra" >/dev/null
  else
    xcrun simctl launch "$udid" "$BID" -AppleLanguages "($lang)" -AppleLocale "${lang/-/_}" >/dev/null
  fi
  sleep 9
  mkdir -p "$(dirname "$out")"
  xcrun simctl io "$udid" screenshot "$out" >/dev/null
  echo "    saved $out"
}

run_device() { # udid kind(iphone|ipad)
  local udid="$1" kind="$2"
  echo "==> Booting $kind ($udid)"
  xcrun simctl boot "$udid"
  xcrun simctl bootstatus "$udid" -b >/dev/null 2>&1 || sleep 5
  xcrun simctl install "$udid" "$APP"
  xcrun simctl status_bar "$udid" override --time "09:41" \
    --batteryState charged --batteryLevel 100 \
    --cellularBars 4 --wifiBars 3 --dataNetwork wifi >/dev/null 2>&1 || true
  for L in en pt-BR; do
    echo "  -- $kind / $L"
    shoot "$udid" "$BID" "docs/screenshots/$L/$kind/01-schedule.png"      "$L" light
    shoot "$udid" "$BID" "docs/screenshots/$L/$kind/02-about.png"         "$L" light "-ShowAbout"
    shoot "$udid" "$BID" "docs/screenshots/$L/$kind/03-schedule-dark.png" "$L" dark
  done
  xcrun simctl shutdown "$udid" >/dev/null 2>&1 || true
}

run_device "$IPHONE" iphone
run_device "$IPAD"   ipad

echo "==> DONE. Cleaning up devices."
xcrun simctl delete "$IPHONE" >/dev/null 2>&1 || true
xcrun simctl delete "$IPAD"   >/dev/null 2>&1 || true
echo "ALL SCREENSHOTS GENERATED"
