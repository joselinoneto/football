#!/bin/sh

#  ci_pre_xcodebuild.sh
#
#  Xcode Cloud runs this just before each `xcodebuild` invocation. It sets the
#  build number (CFBundleVersion) dynamically from Xcode Cloud's own monotonic
#  CI_BUILD_NUMBER, so every build gets a unique, increasing build number with
#  no commits. The marketing version (MARKETING_VERSION, e.g. 1.1) is left
#  alone — bump that by hand only when you actually ship a new version.
#
#  This project has GENERATE_INFOPLIST_FILE = YES, so CFBundleVersion is derived
#  from the CURRENT_PROJECT_VERSION build setting; we rewrite that setting in the
#  ephemeral CI checkout only. Nothing is committed.
#
#  Optional: set BUILD_NUMBER_OFFSET (a plain env var on the workflow) if you
#  need to clear build numbers already used on App Store Connect — the final
#  number is CI_BUILD_NUMBER + BUILD_NUMBER_OFFSET.

set -eu

# CI_BUILD_NUMBER is only set inside Xcode Cloud. Locally, leave the committed
# build number as-is so normal Xcode builds are unaffected.
if [ -z "${CI_BUILD_NUMBER:-}" ]; then
  echo "ci_pre_xcodebuild: no CI_BUILD_NUMBER (not Xcode Cloud) — leaving build number unchanged."
  exit 0
fi

OFFSET="${BUILD_NUMBER_OFFSET:-0}"
BUILD=$((CI_BUILD_NUMBER + OFFSET))

REPO="${CI_PRIMARY_REPOSITORY_PATH:-$(cd "$(dirname "$0")/.." && pwd)}"
PROJECT="$REPO/football.xcodeproj/project.pbxproj"

# Set CURRENT_PROJECT_VERSION for every build configuration. MARKETING_VERSION
# is intentionally not matched, so the marketing version stays manual.
/usr/bin/sed -i '' -E "s/CURRENT_PROJECT_VERSION = [^;]+;/CURRENT_PROJECT_VERSION = ${BUILD};/g" "$PROJECT"

echo "ci_pre_xcodebuild: build number set to ${BUILD} (CI_BUILD_NUMBER=${CI_BUILD_NUMBER}, offset=${OFFSET})"
