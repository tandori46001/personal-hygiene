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

PROJECT="PersonalHygiene.xcodeproj"
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
# Concurrency diagnostics include keywords like "Sendable", "actor-isolated",
# "non-isolated", "@MainActor", "data race", "Sending", "preconcurrency".
CONCURRENCY_RE='(Sendable|actor-isolated|non-isolated|@MainActor|data race|Sending|preconcurrency|isolated context|concurrency)'

# Count error and warning diagnostics related to concurrency.
ERR_COUNT=$(grep -cE "error:.*$CONCURRENCY_RE" "$RAW_LOG" 2>/dev/null || true)
WARN_COUNT=$(grep -cE "warning:.*$CONCURRENCY_RE" "$RAW_LOG" 2>/dev/null || true)

if [[ "$MODE" == "--raw" ]]; then
    cat "$RAW_LOG"
    exit 0
fi

echo ""
echo "==> Strict-concurrency diagnostic summary (Batch Q preview)"
echo "    errors:   $ERR_COUNT"
echo "    warnings: $WARN_COUNT"
echo ""

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

echo "==> Non-blocking preview complete. See LESSONS.md § L009 for migration plan."
echo "    To inspect a specific file: ./scripts/check-strict-concurrency.sh --raw | grep <file>"
exit 0
