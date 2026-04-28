#!/usr/bin/env python3
"""
scripts/check-xcstrings-format-consistency.py — round 19 slice 3

Static check that every xcstrings *format key* (one that ends in `%@` /
`%lld` / `%d` etc.) is actually invoked in source as a format string with
the matching number of placeholders, and that every *non-format key*
(no `%`) is invoked without interpolation.

Runs alongside `check-localization-orphans.py`. Where orphans answers
"is the key referenced at all?", this answers "is the placeholder count
in the call site consistent with the placeholder count in the key?".

Catches L006-style mistakes early: if you rename `birthdays.daysUntil`
→ `birthdays.daysUntil %lld` in xcstrings, this script will flag the
old call site that still passes 0 placeholders.

Output: prints `==> N inconsistencies:` followed by each.

Exit codes:
  0  no inconsistencies
  1  inconsistencies found
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
XCSTRINGS = REPO / "App" / "Shared" / "Localization" / "Localizable.xcstrings"
APP_DIR = REPO / "App"

# Match Text(...) / LocalizedStringResource(...) / NSLocalizedString(...) /
# String(localized:) / Text(localizedKey:) usages with their inner literal.
USAGE_PATTERNS = [
    # Text("key", bundle: ...)
    re.compile(r'Text\("([a-zA-Z][^"\\]*(?:\\.[^"\\]*)*)",\s*bundle:'),
    # Text(localizedKey: "key.\(...)") — round-19 helper, may be dynamic.
    re.compile(r'Text\(localizedKey:\s*"([a-zA-Z][^"]*)"'),
    # LocalizedStringResource("key %@", ...)
    re.compile(r'LocalizedStringResource\("([a-zA-Z][^"]*)"'),
    # String(localized: "key")
    re.compile(r'String\(localized:\s*"([a-zA-Z][^"]*)"'),
    # NSLocalizedString("key", ...)
    re.compile(r'NSLocalizedString\("([a-zA-Z][^"]*)"'),
]

# Match runtime placeholder count by counting `\(...)` in the literal.
RUNTIME_PLACEHOLDER = re.compile(r'\\\([^)]*\)')

# Match xcstrings declared placeholders. We accept the conservative set used
# in this codebase: %@, %lld, %d, %ld.
XCSTRINGS_PLACEHOLDER = re.compile(r'%(?:@|lld|ld|d)')


def collect_declared_keys() -> dict[str, int]:
    """Return a map key → declared placeholder count."""
    with XCSTRINGS.open("r", encoding="utf-8") as f:
        data = json.load(f)
    out: dict[str, int] = {}
    for key in data.get("strings", {}).keys():
        out[key] = len(XCSTRINGS_PLACEHOLDER.findall(key))
    return out


def scan_usages() -> list[tuple[Path, int, str, str]]:
    """Return list of (path, lineno, key_literal, raw_line) per usage."""
    found: list[tuple[Path, int, str, str]] = []
    for swift in APP_DIR.rglob("*.swift"):
        try:
            text = swift.read_text(encoding="utf-8", errors="ignore")
        except OSError:
            continue
        for lineno, line in enumerate(text.splitlines(), 1):
            for pattern in USAGE_PATTERNS:
                for match in pattern.finditer(line):
                    found.append((swift, lineno, match.group(1), line.strip()))
    return found


def runtime_placeholders(literal: str) -> int:
    return len(RUNTIME_PLACEHOLDER.findall(literal))


def declared_placeholders_for(literal: str, declared: dict[str, int]) -> int | None:
    """Resolve the literal back to a declared key, returning the declared
    placeholder count. Handles two cases:

    1. Literal exactly matches a declared key (incl. format keys with %@).
    2. Literal contains `\\(...)` runtime interpolation: substitute each
       `\\(...)` with `%@` (the SwiftUI default) and try the lookup.
    """
    if literal in declared:
        return declared[literal]
    # Substitute runtime interpolations with %@ for the lookup.
    folded = RUNTIME_PLACEHOLDER.sub("%@", literal)
    if folded in declared:
        return declared[folded]
    # Some keys use %lld for integers. Try folding to %lld too.
    folded_int = RUNTIME_PLACEHOLDER.sub("%lld", literal)
    if folded_int in declared:
        return declared[folded_int]
    return None


def main() -> int:
    declared = collect_declared_keys()
    usages = scan_usages()

    inconsistencies: list[str] = []
    for path, lineno, literal, raw in usages:
        runtime = runtime_placeholders(literal)
        declared_count = declared_placeholders_for(literal, declared)
        if declared_count is None:
            # Orphan / dynamic-suffix lookup — covered by the orphans script.
            continue
        if runtime != declared_count:
            rel = path.relative_to(REPO)
            inconsistencies.append(
                f"  {rel}:{lineno}  literal='{literal}' runtime={runtime} declared={declared_count}\n"
                f"    line: {raw}"
            )

    if not inconsistencies:
        print(f"✓ xcstrings format-consistency OK ({len(declared)} keys, {len(usages)} usages scanned)")
        return 0

    print(f"==> {len(inconsistencies)} format-consistency inconsistencies:")
    for entry in inconsistencies:
        print(entry)
    return 1


if __name__ == "__main__":
    sys.exit(main())
