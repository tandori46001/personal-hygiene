#!/usr/bin/env bash
# scripts/check-ci.sh — formalize L009 post-push CI verification
#
# L009 (LESSONS.md) says local Xcode and CI's macos-latest produce different
# Swift 6 verdicts: local emits warnings, CI escalates to errors. Local
# `check-tests.sh` green is necessary but NOT sufficient to declare CI green.
# After every push, run this to query GitHub Actions for the latest run on
# the current branch and surface its terminal state.
#
# Usage:
#   ./scripts/check-ci.sh                 # latest run on current branch
#   ./scripts/check-ci.sh --watch         # poll until terminal (success/failure/cancelled)
#   ./scripts/check-ci.sh --branch main   # explicit branch
#
# Exit codes:
#   0  — latest run completed successfully (or in_progress when not --watch).
#   1  — latest run failed / cancelled / timed out.
#   2  — gh CLI missing or no runs found.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

BRANCH=""
WATCH=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        --watch) WATCH=1; shift ;;
        --branch) BRANCH="$2"; shift 2 ;;
        --branch=*) BRANCH="${1#*=}"; shift ;;
        -h|--help)
            sed -n '2,18p' "$0"; exit 0 ;;
        *) echo "unknown arg: $1" >&2; exit 2 ;;
    esac
done

if ! command -v gh >/dev/null 2>&1; then
    echo "==> gh CLI not on PATH (install: brew install gh)" >&2
    exit 2
fi

if [[ -z "$BRANCH" ]]; then
    BRANCH="$(git rev-parse --abbrev-ref HEAD)"
fi

fetch_latest() {
    # gh's --jq runs jq filter; @tsv emits tab-separated fields for shell split.
    # databaseId stays an integer (gh's --template Go-floats large ints to e+10).
    local out
    out="$(gh run list --branch "$BRANCH" --limit 1 \
        --json databaseId,status,conclusion,displayTitle,headSha \
        --jq '.[] | [.databaseId, .status, (.conclusion // ""), .headSha[:7], .displayTitle] | @tsv' 2>/dev/null)"
    if [[ -z "$out" ]]; then
        echo "NONE"
    else
        echo "$out"
    fi
}

echo "==> Querying GitHub Actions for branch '$BRANCH' (L009 post-push verify)"

if (( WATCH )); then
    while :; do
        line="$(fetch_latest)"
        if [[ "$line" == "NONE" ]]; then
            echo "    no runs found." >&2
            exit 2
        fi
        # bash 3.2 collapses adjacent tabs when IFS contains whitespace, which
    # mangles fields when CONCL is empty (in-flight runs). awk -F'\t' is
    # collapse-safe and handles the empty-field case correctly.
    RID="$(awk -F'\t' '{print $1}' <<< "$line")"
    STATUS="$(awk -F'\t' '{print $2}' <<< "$line")"
    CONCL="$(awk -F'\t' '{print $3}' <<< "$line")"
    SHA="$(awk -F'\t' '{print $4}' <<< "$line")"
    TITLE="$(awk -F'\t' '{print $5}' <<< "$line")"
        echo "    #$RID  status=$STATUS  conclusion=${CONCL:-—}  sha=$SHA  $TITLE"
        case "$STATUS" in
            completed) break ;;
            *) sleep 20 ;;
        esac
    done
else
    line="$(fetch_latest)"
    if [[ "$line" == "NONE" ]]; then
        echo "    no runs found." >&2
        exit 2
    fi
    # bash 3.2 collapses adjacent tabs when IFS contains whitespace, which
    # mangles fields when CONCL is empty (in-flight runs). awk -F'\t' is
    # collapse-safe and handles the empty-field case correctly.
    RID="$(awk -F'\t' '{print $1}' <<< "$line")"
    STATUS="$(awk -F'\t' '{print $2}' <<< "$line")"
    CONCL="$(awk -F'\t' '{print $3}' <<< "$line")"
    SHA="$(awk -F'\t' '{print $4}' <<< "$line")"
    TITLE="$(awk -F'\t' '{print $5}' <<< "$line")"
    echo "    #$RID  status=$STATUS  conclusion=${CONCL:-—}  sha=$SHA  $TITLE"
fi

case "${CONCL:-}" in
    success) echo "==> CI green ✅"; exit 0 ;;
    "")
        if [[ "$STATUS" == "completed" ]]; then
            echo "==> completed but no conclusion field — investigate" >&2; exit 1
        fi
        echo "==> in flight — re-run with --watch to block until terminal"; exit 0 ;;
    failure|cancelled|timed_out|action_required|startup_failure|stale)
        echo "==> CI not green: $CONCL ❌" >&2
        echo "    open: gh run view $RID --log-failed" >&2
        exit 1 ;;
    *)
        echo "==> unknown conclusion '$CONCL' — surface to user" >&2; exit 1 ;;
esac
