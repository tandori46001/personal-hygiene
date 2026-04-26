#!/usr/bin/env bash
# scripts/check-tests.sh — run the full test suite for personal-hygiene
# bash 3.2 compatible

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

PROJECT="App/PersonalHygiene.xcodeproj"
SCHEME="PersonalHygiene"
# Pick the first available iPhone simulator (iPhone 17 Pro on dev, iPhone 17 on CI, etc.)
DEVICE="${IOS_SIMULATOR_NAME:-iPhone 17 Pro}"
DESTINATION="platform=iOS Simulator,name=${DEVICE}"

# Pre-flight: project must exist
if [ ! -d "$PROJECT" ]; then
  echo "==> Xcode project not found at $PROJECT"
  echo "    Phase 0 not yet complete — no tests to run."
  echo "    See App/README.md for instructions to generate the project."
  exit 0
fi

# Verify xcodebuild
if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "ERROR: xcodebuild not found." >&2
  exit 1
fi

echo "==> running tests"
echo "    project:     $PROJECT"
echo "    scheme:      $SCHEME"
echo "    destination: $DESTINATION"
echo

# Use xcbeautify if available for cleaner output
if command -v xcbeautify >/dev/null 2>&1; then
  set -o pipefail
  xcodebuild test \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -resultBundlePath build/test-results.xcresult \
    | xcbeautify --renderer github-actions
else
  xcodebuild test \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -resultBundlePath build/test-results.xcresult
fi

echo
echo "==> tests complete"

echo
echo "==> i18n parity check"
python3 "$REPO_ROOT/scripts/check-i18n.py"
