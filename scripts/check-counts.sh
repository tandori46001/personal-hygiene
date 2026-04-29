#!/usr/bin/env bash
# check-counts.sh — canonical file-count audit for personal-hygiene
#
# L010 guard: macOS writes ._*.swift AppleDouble resource-fork siblings on
# USB-mounted repos (this repo lives at /Volumes/USB1TBWD/...). Naive
# `find ... -name "*.swift" | wc -l` doubles the count. Always exclude `._*`.
#
# Usage:
#   ./scripts/check-counts.sh                 # print the canonical audit table
#   ./scripts/check-counts.sh --json          # machine-readable output
#   source scripts/check-counts.sh; count_swift App/Shared/Services
#
# When sourced, exposes:
#   count_swift PATH                 # *.swift files under PATH, no ._*
#   count_glob PATH PATTERN          # files matching PATTERN under PATH, no ._*
#   count_models PATH                # files containing @Model under PATH, no ._*

set -euo pipefail

count_glob() {
    local path="$1"
    local pattern="$2"
    if [[ ! -d "$path" ]]; then
        echo "0"
        return
    fi
    find "$path" -type f -name "$pattern" -not -name "._*" 2>/dev/null | wc -l | tr -d ' '
}

count_swift() {
    count_glob "$1" "*.swift"
}

count_models() {
    local path="$1"
    if [[ ! -d "$path" ]]; then
        echo "0"
        return
    fi
    grep -rlE '@Model\b' "$path" --include='*.swift' 2>/dev/null \
        | grep -v '/\._' \
        | wc -l \
        | tr -d ' '
}

# When the script is executed directly (not sourced), print the audit table.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    cd "$REPO_ROOT"

    SERVICES=$(count_swift "App/Shared/Services")
    SERVICE_TESTS=$(count_swift "Tests/Unit/Services")
    ALL_TESTS=$(count_swift "Tests")
    MODELS=$(count_models "App")
    SCRIPTS=$(count_glob "scripts" "*.sh")
    XCSTRINGS_KEYS=$(grep -c '"extractionState"' App/Shared/Localization/Localizable.xcstrings 2>/dev/null | tr -d ' ' || echo "0")
    LESSONS=$(grep -cE '^## L[0-9]+ —' LESSONS.md 2>/dev/null | tr -d ' ' || echo "0")

    if [[ "${1:-}" == "--json" ]]; then
        cat <<EOF
{
  "services": $SERVICES,
  "service_tests": $SERVICE_TESTS,
  "all_tests": $ALL_TESTS,
  "models": $MODELS,
  "scripts": $SCRIPTS,
  "xcstrings_keys": $XCSTRINGS_KEYS,
  "lessons": $LESSONS
}
EOF
    else
        cat <<EOF
==> personal-hygiene canonical counts (L010-safe, excludes ._* AppleDouble)

  App/Shared/Services/*.swift     : $SERVICES
  Tests/Unit/Services/*.swift     : $SERVICE_TESTS
  Tests/**/*.swift                : $ALL_TESTS
  @Model files under App/         : $MODELS
  scripts/*.sh                    : $SCRIPTS
  Localizable.xcstrings keys      : $XCSTRINGS_KEYS
  LESSONS.md L0NN entries         : $LESSONS

If your audit produced numbers ~2× these, you almost certainly forgot to
exclude AppleDouble resource forks (._*). See LESSONS.md § L010.
EOF
    fi
fi
