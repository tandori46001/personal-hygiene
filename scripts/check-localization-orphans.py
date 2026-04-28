#!/usr/bin/env python3
"""
scripts/check-localization-orphans.py — round 18 slice 4

Static check: any key in `App/Shared/Localization/Localizable.xcstrings`
that isn't referenced anywhere in Swift sources is reported as an orphan.

Reports orphans as a *warning* by default (exit 0). Pass `--fail-on-orphans`
to make orphans a hard error (exit 1). The hard-fail mode is intended for
explicit cleanup runs, not regular CI, because dynamic key construction
(e.g. `LocalizedStringKey("category.\\(raw)")`) intentionally produces keys
that match a prefix family and look orphaned to a literal scan.

Output: prints `==> N orphan keys (warning):` followed by each key.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
XCSTRINGS = REPO_ROOT / "App" / "Shared" / "Localization" / "Localizable.xcstrings"
APP_DIR = REPO_ROOT / "App"

LITERAL_PATTERNS = [
    re.compile(r'Text\("([a-zA-Z][^"]+)",\s*bundle:'),
    re.compile(r'LocalizedStringKey\("([a-zA-Z][^"]+)"\)'),
    re.compile(r'LocalizedStringResource\("([a-zA-Z][^"]+)"\)'),
    re.compile(r'String\(localized:\s*"([a-zA-Z][^"]+)"\)'),
]

# Keys that look like `prefix.\(value)` — captured loosely as `prefix.`
DYNAMIC_PREFIX = re.compile(r'(?:Text|LocalizedStringKey|LocalizedStringResource)\("([a-zA-Z][^"]*?)\\\(')


def collect_declared() -> set[str]:
    with XCSTRINGS.open("r", encoding="utf-8") as f:
        data = json.load(f)
    return set(data.get("strings", {}).keys())


def collect_referenced() -> tuple[set[str], set[str]]:
    """Returns (literal_keys, dynamic_prefixes)."""
    literal: set[str] = set()
    prefixes: set[str] = set()
    for swift in APP_DIR.rglob("*.swift"):
        try:
            text = swift.read_text(encoding="utf-8", errors="ignore")
        except OSError:
            continue
        for pattern in LITERAL_PATTERNS:
            for match in pattern.finditer(text):
                key = match.group(1)
                if "\\(" in key:
                    continue
                literal.add(key)
        for match in DYNAMIC_PREFIX.finditer(text):
            prefixes.add(match.group(1))
    return literal, prefixes


def matches_dynamic_prefix(key: str, prefixes: set[str]) -> bool:
    return any(key.startswith(prefix) for prefix in prefixes)


def main() -> int:
    parser = argparse.ArgumentParser(description="Report orphan i18n keys.")
    parser.add_argument("--fail-on-orphans", action="store_true")
    args = parser.parse_args()

    declared = collect_declared()
    literal, prefixes = collect_referenced()

    orphans = sorted(
        key
        for key in declared
        if key not in literal and not matches_dynamic_prefix(key, prefixes)
    )

    if not orphans:
        print(f"==> No orphan i18n keys (out of {len(declared)} declared).")
        return 0

    print(f"==> {len(orphans)} orphan keys (warning):")
    for key in orphans:
        print(f"    - {key}")

    if args.fail_on_orphans:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
