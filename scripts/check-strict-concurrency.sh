#!/usr/bin/env bash
# scripts/check-strict-concurrency.sh — preview of Batch Q migration
#
# Round 30 promoted L009 to LESSONS.md: local Xcode emits Swift 6
# language-mode warnings, while CI's macos-latest runner escalates them
# to errors. Resolution for the current main branch was to dial host
# SWIFT_VERSION back to 5 (matching watch + tests). The eventual Batch Q
# migration will re-flip to 6.0 and walk every diagnostic to ground.
#
# This script is a local-dev preview that runs
#   xcodebuild build SWIFT_STRICT_CONCURRENCY=complete
# against the current Xcode project + iOS scheme and prints the
# concurrency-related diagnostics that would surface under strict mode.
# It is NON-BLOCKING (always exits 0 unless xcodebuild itself fails for
# unrelated reasons) — the goal is to make the migration backlog
# inspectable, not to gate CI.
#
# Usage:
#   ./scripts/check-strict-concurrency.sh           # build + show counts
#   ./scripts/check-strict-concurrency.sh --files   # also list affected files
#   ./scripts/check-strict-concurrency.sh --raw     # full xcodebuild output
#
# Exit codes:
#   0  — script completed (regardless of how many diagnostics were found).
#   2  — Xcode project missing or xcodebuild not available.
#   3  — xcodebuild failed for non-concurrency reasons (true build error).

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

PROJECT="App/PersonalHygiene.xcodeproj"
SCHEME="PersonalHygiene"
SDK="iphonesimulator"
DESTINATION="generic/platform=iOS Simulator"

if [[ ! -d "$PROJECT" ]]; then
    echo "==> Xcode project not found at $PROJECT" >&2
    exit 2
fi
if ! command -v xcodebuild >/dev/null 2>&1; then
    echo "==> xcodebuild not on PATH (Xcode not installed?)" >&2
    exit 2
fi

MODE="${1:-summary}"
RAW_LOG="$(mktemp -t strict-concurrency.XXXXXX.log)"
trap 'rm -f "$RAW_LOG"' EXIT

echo "==> Running xcodebuild build SWIFT_STRICT_CONCURRENCY=complete (this can take 5+ min)..."
set +e
xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -sdk "$SDK" \
    -destination "$DESTINATION" \
    -configuration Debug \
    SWIFT_STRICT_CONCURRENCY=complete \
    SWIFT_VERSION=6.0 \
    -quiet \
    build 2>&1 \
    | tee "$RAW_LOG" >/dev/null
XCODE_EXIT=$?
set -e

# Check whether the failure (if any) is concurrency-related or a true error.
# Round 37 / L012: regex extended after round 36's CI saga revealed blind
# spots on test-target diagnostic phrasings the original keyword bag missed
# ("sending value of non-Sendable type 'XCTestCase' risks causing data
# races", "call to main actor-isolated initializer/instance method 'X' in a
# synchronous nonisolated context", "main actor-isolated property 'X' can
# not be (referenced|mutated) from a nonisolated context"). The strict-mode
# diagnostic surface is wider than the keywords in any single commit's
# regex; treat the regex as code that needs extension every time a new
# shape surfaces in CI. See LESSONS.md § L012.
CONCURRENCY_RE='(Sendable|actor-isolated|nonisolated|non-isolated|@MainActor|data race|Sending|preconcurrency|isolated context|concurrency|sending value of|risks causing data races|in a synchronous nonisolated context|cannot be (referenced|mutated|sent) from|across actor boundary|implicitly nonisolated|requires explicit isolation|sending main actor-isolated)'

# Count error and warning diagnostics related to concurrency.
ERR_COUNT=$(grep -cE "error:.*$CONCURRENCY_RE" "$RAW_LOG" 2>/dev/null || true)
WARN_COUNT=$(grep -cE "warning:.*$CONCURRENCY_RE" "$RAW_LOG" 2>/dev/null || true)

# Round 37 / L012 cross-check: total diagnostics minus concurrency-classified
# subset. If the gap exceeds the build-system noise floor (~5), the regex is
# missing diagnostic shapes and we surface the first uncovered ones so the
# regex can be extended. This converts a silent classification gap into a
# noisy alert (the very gap that cost round 36 two surprise fix-forwards).
TOTAL_ERR=$(grep -cE "^[^:]+\.swift:[0-9]+:[0-9]+: error:" "$RAW_LOG" 2>/dev/null || true)
TOTAL_WARN=$(grep -cE "^[^:]+\.swift:[0-9]+:[0-9]+: warning:" "$RAW_LOG" 2>/dev/null || true)
UNCOVERED_ERR=$((TOTAL_ERR - ERR_COUNT))
UNCOVERED_WARN=$((TOTAL_WARN - WARN_COUNT))

if [[ "$MODE" == "--raw" ]]; then
    cat "$RAW_LOG"
    exit 0
fi

echo ""
echo "==> Strict-concurrency diagnostic summary (Batch Q preview)"
echo "    errors:   $ERR_COUNT (concurrency-classified) / $TOTAL_ERR (total)"
echo "    warnings: $WARN_COUNT (concurrency-classified) / $TOTAL_WARN (total)"
echo ""

# Build-noise floor: 5 unclassified diagnostics is acceptable (xcodebuild
# emits some non-concurrency warnings about deprecated APIs, etc.). Above
# that, the regex is probably missing a Swift-6 shape — preview them.
if (( UNCOVERED_ERR + UNCOVERED_WARN > 5 )); then
    echo "==> ⚠️  $((UNCOVERED_ERR + UNCOVERED_WARN)) diagnostics not matched by CONCURRENCY_RE."
    echo "    First 5 uncovered (extend regex if these look concurrency-shaped):"
    grep -E "^[^:]+\.swift:[0-9]+:[0-9]+: (error|warning):" "$RAW_LOG" \
        | grep -vE "(error|warning):.*$CONCURRENCY_RE" \
        | head -5 \
        | sed 's/^/      /'
    echo ""
fi

if [[ "$MODE" == "--files" ]] && (( ERR_COUNT + WARN_COUNT > 0 )); then
    echo "==> Files with concurrency diagnostics (deduped, sorted):"
    grep -E "(error|warning):.*$CONCURRENCY_RE" "$RAW_LOG" \
        | sed -E 's/^([^:]+\.swift):.*/\1/' \
        | grep -E '\.swift$' \
        | sort -u \
        | sed 's/^/    /'
    echo ""
fi

if (( XCODE_EXIT != 0 )) && (( ERR_COUNT == 0 )); then
    # xcodebuild failed but no concurrency errors — likely a real build
    # problem (signing, dependencies, simulator missing). Surface that.
    echo "::warning::xcodebuild exited $XCODE_EXIT but no concurrency errors found." >&2
    echo "Likely a non-concurrency build issue. Run with --raw to see the log." >&2
    exit 3
fi

# Round 37 [37-3]: gate CI on concurrency errors. Production code is on
# Swift 6 strict mode after Batch Q; this script is a regression guard.
# Errors fail the job; warnings stay informational (local devs may have
# in-progress code that emits warnings during a refactor).
if (( ERR_COUNT > 0 )); then
    echo "::error::$ERR_COUNT concurrency error(s) found at SWIFT_STRICT_CONCURRENCY=complete + SWIFT_VERSION=6.0." >&2
    echo "See LESSONS.md § L011 for the four common fix-classes." >&2
    exit 1
fi

# Round 37 [37-3] cross-check: if uncovered-diagnostic gap exceeds the
# build-noise floor, the regex needs extension (L012). Fail the job so
# the gap can't silently widen between rounds.
UNCOVERED_TOTAL=$((UNCOVERED_ERR + UNCOVERED_WARN))
if (( UNCOVERED_TOTAL > 5 )); then
    echo "::error::$UNCOVERED_TOTAL diagnostics not matched by CONCURRENCY_RE." >&2
    echo "Extend the regex per L012 — see the uncovered preview above." >&2
    exit 1
fi

echo "==> Strict-concurrency guard passed (errors=$ERR_COUNT, uncovered=$UNCOVERED_TOTAL)."
echo "    See LESSONS.md § L011 (fix-classes) + L012 (regex coverage)."
exit 0
