#!/usr/bin/env bash
# scripts/check-tests.sh — run the full test suite for personal-hygiene
# bash 3.2 compatible

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

PROJECT="App/PersonalHygiene.xcodeproj"
SCHEME="PersonalHygiene"

# Pick the iPhone simulator: explicit override > first available iPhone on
# this machine. Hard-coding a name burns when GitHub's macos-latest image
# rolls and the previous default disappears (round 29 incident: CI tried
# "iPhone 17 Pro" which the runner no longer ships).
if [ -n "${IOS_SIMULATOR_NAME:-}" ]; then
  DEVICE="$IOS_SIMULATOR_NAME"
else
  DEVICE=$(xcrun simctl list devices available 2>/dev/null \
    | grep -E '^[[:space:]]+iPhone ' \
    | head -1 \
    | sed -E 's/^[[:space:]]+(iPhone[^(]+) \(.*$/\1/' \
    | sed -E 's/[[:space:]]+$//')
  if [ -z "$DEVICE" ]; then
    echo "ERROR: no iPhone simulator available. Install one via Xcode → Settings → Platforms." >&2
    exit 1
  fi
fi
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

# Pre-clean the result bundle — xcodebuild refuses to overwrite an existing one.
rm -rf build/test-results.xcresult

# Tee output to a log so we can post-process the exit code below.
LOG_FILE="$(mktemp)"
trap 'rm -f "$LOG_FILE"' EXIT

# Use xcbeautify if available for cleaner output
set +e
if command -v xcbeautify >/dev/null 2>&1; then
  set -o pipefail
  xcodebuild test \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -resultBundlePath build/test-results.xcresult \
    2>&1 | tee "$LOG_FILE" | xcbeautify --renderer github-actions
  XB_EXIT=${PIPESTATUS[0]}
else
  xcodebuild test \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -resultBundlePath build/test-results.xcresult \
    2>&1 | tee "$LOG_FILE"
  XB_EXIT=${PIPESTATUS[0]}
fi
set -e

# Exit 65 + zero "Test Case '...' failed" lines == known DebuggerLLDB simulator
# glitch (DebuggerLLDB.DebuggerVersionStore.StoreError). Tripped sessions 5/6/7
# without a real failure. We treat it as success ONLY when no test method is
# reported failed AND no compile error is in the log. The glitch itself emits
# `error: failed to attach to xpc service` and `DebuggerVersionStore` lines
# which we filter out before counting (round 8) so they don't masquerade as
# real test failures.
REAL_FAILURES="$(grep -E "^Test Case '.*' failed|FAILED:|error:" "$LOG_FILE" \
    | grep -vE "DebuggerVersionStore|failed to attach to xpc service" \
    | wc -l \
    | tr -d ' ' || true)"
# Round 10 hardening: a "signal trap" / "Restarting after unexpected exit"
# line means the test PROCESS crashed mid-suite. Round 9 had a flake that
# emitted these without any "Test Case 'X' failed" line — the old filter
# treated it as success. Now we count those crashes as real failures.
PROCESS_CRASHES="$(grep -cE "Restarting after unexpected exit, crash, or test timeout|signal trap|Encountered an error \(Crash:" "$LOG_FILE" \
    | tr -d ' ' || true)"
if [ "$XB_EXIT" = "65" ] && [ "$REAL_FAILURES" = "0" ] && [ "$PROCESS_CRASHES" = "0" ]; then
  echo
  echo "==> xcodebuild exit 65 with zero test-method failures — treating as known"
  echo "    DebuggerLLDB simulator glitch (does not indicate a real failure)."
  XB_EXIT=0
elif [ "$PROCESS_CRASHES" != "0" ]; then
  echo
  echo "==> $PROCESS_CRASHES test-process crash(es) detected (signal trap / unexpected exit)"
  echo "    NOT treating as the LLDB glitch — see L005 in LESSONS.md."
fi

if [ "$XB_EXIT" != "0" ]; then
  echo
  echo "==> tests FAILED (xcodebuild exit $XB_EXIT)"
  exit "$XB_EXIT"
fi

echo
echo "==> tests complete"

echo
echo "==> i18n parity check"
python3 "$REPO_ROOT/scripts/check-i18n.py"
