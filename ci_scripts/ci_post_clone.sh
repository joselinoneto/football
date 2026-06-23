#!/bin/sh

#  ci_post_clone.sh
#
#  Xcode Cloud runs this automatically right after cloning the repository and
#  before resolving packages / building. It regenerates the git-ignored
#  Secrets.swift files (one per app target — iOS and watchOS) from secret
#  environment variables defined on the Xcode Cloud workflow, so the real
#  Airtable credentials never live in source history.
#
#  Set these as *secret* environment variables in App Store Connect:
#    Xcode Cloud  →  your workflow  →  Environment  →  Environment Variables
#      AIRTABLE_BASE_ID   e.g. appXXXXXXXXXXXXXX
#      AIRTABLE_TOKEN     a read-only personal access token (patXXXX…)
#  Tick "Secret" on both so they are encrypted and kept out of the build logs.
#
#  The script is also reusable locally to (re)generate the Secrets files, e.g.:
#    AIRTABLE_BASE_ID=app… AIRTABLE_TOKEN=pat… ./ci_scripts/ci_post_clone.sh

set -eu

# Xcode Cloud sets CI_PRIMARY_REPOSITORY_PATH to the cloned repo root; fall back
# to this script's parent directory so it also works when run by hand.
REPO="${CI_PRIMARY_REPOSITORY_PATH:-$(cd "$(dirname "$0")/.." && pwd)}"

# The app, the Watch app, and the widget extension each read
# AirtableConfiguration.current from their own git-ignored Secrets.swift; they
# all share the same credentials.
SECRETS_PATHS="football/Support/Secrets.swift footballWatch/Support/Secrets.swift footballWidget/Support/Secrets.swift"

if [ -z "${AIRTABLE_BASE_ID:-}" ] || [ -z "${AIRTABLE_TOKEN:-}" ]; then
  echo "ci_post_clone: AIRTABLE_BASE_ID / AIRTABLE_TOKEN not set — leaving Secrets.swift files untouched." >&2
  # Not fatal: a local build can rely on hand-made Secrets.swift files instead.
  exit 0
fi

for rel in $SECRETS_PATHS; do
  secrets="$REPO/$rel"
  mkdir -p "$(dirname "$secrets")"
  cat > "$secrets" <<EOF
// Generated at build time by ci_scripts/ci_post_clone.sh from Xcode Cloud
// secret environment variables. Do not commit — this file is git-ignored.
import FootballAPI

extension AirtableConfiguration {
    static let current = AirtableConfiguration(
        baseID: "${AIRTABLE_BASE_ID}",
        token: "${AIRTABLE_TOKEN}"
    )
}
EOF
  echo "ci_post_clone: generated $secrets"
done
