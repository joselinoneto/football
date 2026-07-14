#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

BID="app.zeneto.football"
DD="build-screens"

# Pick the newest installed iOS runtime and the right device types, rather than
# hard-coding a version that drifts as Xcode updates.
RUNTIME=$(xcrun simctl list runtimes | grep -oE 'com\.apple\.CoreSimulator\.SimRuntime\.iOS-[0-9-]+' | tail -1)
IPHONE_TYPE=$(xcrun simctl list devicetypes | grep -oE 'com\.apple\.CoreSimulator\.SimDeviceType\.iPhone-17-Pro-Max' | head -1)
IPAD_TYPE=$(xcrun simctl list devicetypes | grep -oE 'com\.apple\.CoreSimulator\.SimDeviceType\.iPad-Pro-13-inch[A-Za-z0-9-]*' | head -1)
[ -n "$RUNTIME" ]     || { echo "No iOS simulator runtime found"; exit 1; }
[ -n "$IPHONE_TYPE" ] || { echo "iPhone 17 Pro Max device type not found"; exit 1; }
[ -n "$IPAD_TYPE" ]   || { echo "iPad Pro 13-inch device type not found"; exit 1; }
echo "==> runtime=$RUNTIME"
echo "==> iphone=$IPHONE_TYPE"
echo "==> ipad=$IPAD_TYPE"

# Pre-select a favorite team so screenshots show the team-tinted accent (a
# headline 1.3 feature). The app reads "-SeedFavorite <CODE>" only here.
FAVORITE="BRA"

# (re)create clean devices
for name in "JF-iPhone" "JF-iPad"; do
  old=$(xcrun simctl list devices | grep "$name (" | grep -oE '[0-9A-F-]{36}' | head -1 || true)
  [ -n "$old" ] && xcrun simctl delete "$old" || true
done
IPHONE=$(xcrun simctl create "JF-iPhone" "$IPHONE_TYPE" "$RUNTIME")
IPAD=$(xcrun simctl create "JF-iPad" "$IPAD_TYPE" "$RUNTIME")
echo "==> iPhone=$IPHONE  iPad=$IPAD"

echo "==> Building app for simulator..."
# Build against a concrete simulator (not 'generic/...') so the widget
# extension's local package deps resolve under a single arch.
xcodebuild -project football.xcodeproj -scheme football \
  -configuration Debug \
  -derivedDataPath "$DD" \
  -destination "id=$IPHONE" \
  build >/tmp/jf-build.log 2>&1 || { echo "BUILD FAILED"; tail -40 /tmp/jf-build.log; exit 1; }

APP="$DD/Build/Products/Debug-iphonesimulator/football.app"
[ -d "$APP" ] || { echo "App not found at $APP"; ls -R "$DD/Build/Products" | head; exit 1; }
echo "==> Built: $APP"

shoot() { # udid outfile lang appearance extraArgs...
  local udid="$1" out="$2" lang="$3" appr="$4"; shift 4
  xcrun simctl ui "$udid" appearance "$appr" >/dev/null 2>&1 || true
  xcrun simctl terminate "$udid" "$BID" >/dev/null 2>&1 || true
  xcrun simctl launch "$udid" "$BID" \
    -AppleLanguages "($lang)" -AppleLocale "${lang/-/_}" \
    -SeedFavorite "$FAVORITE" "$@" >/dev/null
  sleep 9
  local abs="$PWD/$out"
  mkdir -p "$(dirname "$abs")"
  xcrun simctl io "$udid" screenshot "$abs" >/dev/null
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
  # Warm-up launch: runs the first data sync (so later shots aren't caught on the
  # "Loading…" screen) and lets the simulator's first-run notification banner
  # ("Ready for Apple Intelligence") appear and auto-dismiss before any shot. It
  # also seeds the favorite, which then persists for every subsequent launch.
  xcrun simctl launch "$udid" "$BID" -SeedFavorite "$FAVORITE" >/dev/null 2>&1 || true
  sleep 16
  xcrun simctl terminate "$udid" "$BID" >/dev/null 2>&1 || true
  for L in en pt-BR; do
    echo "  -- $kind / $L"
    local d="docs/screenshots/$L/$kind"
    shoot "$udid" "$d/01-home.png"      "$L" light
    shoot "$udid" "$d/02-knockout.png"  "$L" light -ShowMatches
    shoot "$udid" "$d/03-groups.png"    "$L" light -ShowGroupStage
    shoot "$udid" "$d/04-match.png"     "$L" light -ShowSampleMatch
    shoot "$udid" "$d/05-settings.png"  "$L" light -ShowSettings
    shoot "$udid" "$d/06-home-dark.png" "$L" dark
  done
  xcrun simctl shutdown "$udid" >/dev/null 2>&1 || true
}

run_device "$IPHONE" iphone
run_device "$IPAD"   ipad

echo "==> DONE. Cleaning up devices."
xcrun simctl delete "$IPHONE" >/dev/null 2>&1 || true
xcrun simctl delete "$IPAD"   >/dev/null 2>&1 || true
echo "ALL SCREENSHOTS GENERATED"
