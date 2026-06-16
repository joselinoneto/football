#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

BID="app.zeneto.football"
IPHONE_TYPE="com.apple.CoreSimulator.SimDeviceType.iPhone-13-Pro-Max"  # 1284x2778 (6.5")
DD="build-screens"

# pick a runtime the 13 Pro Max can pair with
RT=$(xcrun simctl list runtimes available | grep -oE 'com.apple.CoreSimulator.SimRuntime.iOS-[0-9-]+' | tail -1)
echo "==> runtime $RT"

echo "==> Building app for simulator..."
xcodebuild -project football.xcodeproj -scheme football \
  -configuration Debug -sdk iphonesimulator \
  -derivedDataPath "$DD" \
  -destination 'generic/platform=iOS Simulator' \
  build >/tmp/jf-build65.log 2>&1 || { echo "BUILD FAILED"; tail -40 /tmp/jf-build65.log; exit 1; }
APP="$DD/Build/Products/Debug-iphonesimulator/football.app"
[ -d "$APP" ] || { echo "App not found"; exit 1; }

old=$(xcrun simctl list devices | grep "JF-iPhone65 (" | grep -oE '[0-9A-F-]{36}' | head -1 || true)
[ -n "$old" ] && xcrun simctl delete "$old" || true
UDID=$(xcrun simctl create "JF-iPhone65" "$IPHONE_TYPE" "$RT")
echo "==> device $UDID"

xcrun simctl boot "$UDID"
xcrun simctl bootstatus "$UDID" -b >/dev/null 2>&1 || sleep 5
xcrun simctl install "$UDID" "$APP"
xcrun simctl status_bar "$UDID" override --time "09:41" \
  --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3 --dataNetwork wifi >/dev/null 2>&1 || true

shoot() { # out lang appearance extra
  local out="$1" lang="$2" appr="$3" extra="${4:-}"
  xcrun simctl ui "$UDID" appearance "$appr" >/dev/null 2>&1 || true
  xcrun simctl terminate "$UDID" "$BID" >/dev/null 2>&1 || true
  if [ -n "$extra" ]; then
    xcrun simctl launch "$UDID" "$BID" -AppleLanguages "($lang)" -AppleLocale "${lang/-/_}" "$extra" >/dev/null
  else
    xcrun simctl launch "$UDID" "$BID" -AppleLanguages "($lang)" -AppleLocale "${lang/-/_}" >/dev/null
  fi
  sleep 9
  mkdir -p "$(dirname "$out")"
  xcrun simctl io "$UDID" screenshot "$out" >/dev/null
  echo "    saved $out"
}

for L in en pt-BR; do
  echo "  -- 6.5in / $L"
  shoot "docs/screenshots/$L/iphone-6.5/01-schedule.png"      "$L" light
  shoot "docs/screenshots/$L/iphone-6.5/02-about.png"         "$L" light "-ShowAbout"
  shoot "docs/screenshots/$L/iphone-6.5/03-schedule-dark.png" "$L" dark
done

xcrun simctl shutdown "$UDID" >/dev/null 2>&1 || true
xcrun simctl delete "$UDID" >/dev/null 2>&1 || true
rm -rf "$DD"
echo "DONE 6.5in SET"
