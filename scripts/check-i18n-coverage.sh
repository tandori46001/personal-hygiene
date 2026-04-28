#!/usr/bin/env bash
# scripts/check-i18n-coverage.sh — round 18 slice 3
#
# Static check: every literal `Text("…", bundle: .main)` and
# `LocalizedStringKey("…")` referenced from Swift sources must have a
# matching key in `App/Shared/Localization/Localizable.xcstrings`.
#
# Skips `Text(verbatim: …)` (those are non-localized by intent) and skips
# any literal that contains an interpolation `\(…)` (xcstrings stores those
# under `key.%lld` / `key %@` shapes that need separate handling).
#
# Exit codes:
#   0  — every literal key resolves.
#   1  — missing keys; lists each one.
#   2  — usage error / xcstrings missing.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

XCSTRINGS="App/Shared/Localization/Localizable.xcstrings"
if [ ! -f "$XCSTRINGS" ]; then
  echo "==> xcstrings file not found at $XCSTRINGS" >&2
  exit 2
fi

# Build the set of declared keys (one per line).
DECLARED_KEYS_FILE="$(mktemp -t i18n-declared.XXXXXX)"
trap 'rm -f "$DECLARED_KEYS_FILE" "$REFERENCED_KEYS_FILE"' EXIT
python3 - "$XCSTRINGS" >"$DECLARED_KEYS_FILE" <<'PYEOF'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as f:
    data = json.load(f)
for key in data.get("strings", {}).keys():
    print(key)
PYEOF

REFERENCED_KEYS_FILE="$(mktemp -t i18n-referenced.XXXXXX)"

# Scan Swift sources under App/ for literal keys.
# Patterns:
#   Text("foo.bar", bundle: .main)
#   Text("foo.bar", bundle: ...)
#   LocalizedStringKey("foo.bar")
#   LocalizedStringResource("foo.bar")
#   String(localized: "foo.bar")
#
# Strip interpolated literals (they contain `\(`).
{
  grep -RhoE 'Text\("[a-zA-Z][^"]+",[[:space:]]*bundle:' App/ --include='*.swift' || true
  grep -RhoE 'LocalizedStringKey\("[a-zA-Z][^"]+"\)'      App/ --include='*.swift' || true
  grep -RhoE 'LocalizedStringResource\("[a-zA-Z][^"]+"\)' App/ --include='*.swift' || true
  grep -RhoE 'String\(localized:[[:space:]]*"[a-zA-Z][^"]+"\)' App/ --include='*.swift' || true
} \
  | sed -E 's/.*"([^"]+)".*/\1/' \
  | grep -v '\\(' \
  | sort -u > "$REFERENCED_KEYS_FILE"

# Diff: referenced keys that aren't declared.
MISSING="$(comm -23 "$REFERENCED_KEYS_FILE" <(sort -u "$DECLARED_KEYS_FILE"))"

if [ -n "$MISSING" ]; then
  echo "==> Missing i18n keys (referenced from Swift but not in $XCSTRINGS):"
  echo "$MISSING" | sed 's/^/    - /'
  echo "==> Total missing: $(echo "$MISSING" | wc -l | tr -d ' ')"
  exit 1
fi

DECLARED_COUNT="$(wc -l < "$DECLARED_KEYS_FILE" | tr -d ' ')"
REFERENCED_COUNT="$(wc -l < "$REFERENCED_KEYS_FILE" | tr -d ' ')"
echo "==> i18n coverage OK: $REFERENCED_COUNT referenced keys, all declared (out of $DECLARED_COUNT total)."
