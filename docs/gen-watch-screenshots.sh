#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

BID="app.zeneto.football.watch"
RUNTIME="com.apple.CoreSimulator.SimRuntime.watchOS-26-4"
WATCH_TYPE="com.apple.CoreSimulator.SimDeviceType.Apple-Watch-Ultra-3-49mm"
DD="build-watch-screens"

echo "==> Building Watch app for simulator..."
xcodebuild -project football.xcodeproj -scheme footballWatch \
  -configuration Debug -sdk watchsimulator \
  -derivedDataPath "$DD" \
  -destination "generic/platform=watchOS Simulator" \
  build >/tmp/jf-watch-build.log 2>&1 || { echo "BUILD FAILED"; tail -40 /tmp/jf-watch-build.log; exit 1; }

APP="$DD/Build/Products/Debug-watchsimulator/footballWatch.app"
[ -d "$APP" ] || { echo "App not found at $APP"; exit 1; }
echo "==> Built: $APP"

old=$(xcrun simctl list devices | grep "JF-Watch (" | grep -oE '[0-9A-F-]{36}' | head -1 || true)
[ -n "$old" ] && xcrun simctl delete "$old" || true
WATCH=$(xcrun simctl create "JF-Watch" "$WATCH_TYPE" "$RUNTIME")
echo "==> Watch=$WATCH"

xcrun simctl boot "$WATCH"
xcrun simctl bootstatus "$WATCH" -b >/dev/null 2>&1 || sleep 5
xcrun simctl install "$WATCH" "$APP"

for L in en pt-BR; do
  echo "  -- watch / $L"
  xcrun simctl terminate "$WATCH" "$BID" >/dev/null 2>&1 || true
  xcrun simctl launch "$WATCH" "$BID" -AppleLanguages "($L)" -AppleLocale "${L/-/_}" >/dev/null
  sleep 10
  out="$PWD/docs/screenshots/$L/watch/01-schedule.png"
  mkdir -p "$(dirname "$out")"
  xcrun simctl io "$WATCH" screenshot "$out" >/dev/null
  echo "    saved $out"
done

xcrun simctl shutdown "$WATCH" >/dev/null 2>&1 || true
xcrun simctl delete "$WATCH" >/dev/null 2>&1 || true
echo "WATCH SCREENSHOTS GENERATED"
