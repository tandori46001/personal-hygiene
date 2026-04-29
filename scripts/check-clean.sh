#!/usr/bin/env bash
# scripts/check-clean.sh — repo-safety gate
# Verifies: no committed PII, no leaked secrets, no forbidden file paths.
# bash 3.2 compatible.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

EXIT=0
WARN=0

# 1. gitleaks — known-secret patterns
if command -v gitleaks >/dev/null 2>&1; then
  echo "==> gitleaks (committed history)"
  mkdir -p build
  if ! gitleaks detect --no-banner --redact --report-format json --report-path build/gitleaks.json --source . 2>&1; then
    echo "  FAIL: gitleaks found committed secrets"
    EXIT=1
  fi
else
  echo "==> gitleaks not installed — skipping (run bootstrap.sh)"
  WARN=$((WARN + 1))
fi

# 2. PII regex scan — best-effort patterns
echo "==> PII pattern scan"

# Tracked files only — don't scan untracked / build dirs
TRACKED_FILES=$(git ls-files | grep -v -E '\.(png|jpg|jpeg|gif|pdf|ico|woff|woff2|ttf|otf|zip|tar|gz)$' || true)
if [ -z "$TRACKED_FILES" ]; then
  echo "  no tracked text files yet — skipping"
else
  # 2a. real-looking emails (excluding placeholders + intentionally-public app docs)
  # docs/PRIVACY.md + docs/LISTING.md legitimately publish a contact email
  # required by App Store Connect; allowlist them here, not by editing the regex.
  if echo "$TRACKED_FILES" | xargs grep -nIE '\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b' 2>/dev/null \
       | grep -vE 'example\.com|<.*-placeholder@|noreply@|@anthropic\.com' \
       | grep -vE '^docs/(PRIVACY|LISTING)\.md:' \
       | grep -E '@gmail|@yahoo|@outlook|@hotmail|@icloud|@proton'; then
    echo "  FAIL: real-looking personal email found in tracked files"
    EXIT=1
  fi

  # 2b. private-range IPs that aren't obvious examples
  if echo "$TRACKED_FILES" | xargs grep -nIE '\b(10|172\.(1[6-9]|2[0-9]|3[01])|192\.168)\.[0-9]{1,3}\.[0-9]{1,3}\b' 2>/dev/null \
       | grep -vE '192\.168\.1\.(1|100|200)\b|10\.0\.0\.1\b'; then
    echo "  WARN: private-range IP found — verify it's a placeholder"
    WARN=$((WARN + 1))
  fi

  # 2c. high-precision lat/lon sequences (8+ decimal digits suggest real coordinates)
  if echo "$TRACKED_FILES" | xargs grep -nIE '\b-?[0-9]{1,3}\.[0-9]{6,}\s*,\s*-?[0-9]{1,3}\.[0-9]{6,}\b' 2>/dev/null; then
    echo "  WARN: high-precision lat/lon pair found — verify it's not a real location"
    WARN=$((WARN + 1))
  fi
fi

# 3. forbidden file paths (no .DS_Store, ._*, *.env, etc. in git)
echo "==> forbidden path scan"
FORBIDDEN=$(git ls-files | grep -E '(^|/)(\.DS_Store|\._.+|.+\.env(\.|$)|secrets/|.+-secrets\.env)' || true)
if [ -n "$FORBIDDEN" ]; then
  echo "  FAIL: forbidden files committed:"
  echo "$FORBIDDEN" | sed 's/^/    /'
  EXIT=1
fi

# 4. Result summary
echo
if [ "$EXIT" = "0" ] && [ "$WARN" = "0" ]; then
  echo "==> clean"
elif [ "$EXIT" = "0" ]; then
  echo "==> clean (with $WARN warnings — review above)"
else
  echo "==> FAILED — see above"
fi

exit "$EXIT"
