#!/usr/bin/env python3
"""
scripts/check-localized-string-resource.py — round 22 slice T1.7

Sister scan to `check-localized-key-usage.py`. Where that script catches
`LocalizedStringKey("...\\(...)")` (the SwiftUI `Text` footgun), this one
catches the same class of bug for `LocalizedStringResource`:

    LocalizedStringResource("foo.bar \\(value)")

When the literal contains an interpolation, the resolved key is
`"foo.bar %@"` (or `%lld`, etc.) — NOT the literal-with-value substring.
For each such site we verify the corresponding key with the right
placeholder suffix exists in `Localizable.xcstrings`. Sites whose key is
missing surface as offenders so the next session can fix them before they
ship as raw-key UI bugs.

Exit codes:
  0  no violations
  1  one or more sites reference a missing format key
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
APP_DIR = REPO / "App"
XCSTRINGS = APP_DIR / "Shared" / "Localization" / "Localizable.xcstrings"

# Match `LocalizedStringResource(` and capture the rest of the line; we walk
# the string manually because Swift interpolations may contain nested parens
# (`\(foo(bar))`) that a flat regex can't balance.
START_TOKEN = "LocalizedStringResource("

# Map common interpolation shapes to their xcstrings placeholder.
PLACEHOLDER_SUFFIXES = ("%@", "%lld", "%d")


def extract_literals_with_interpolation(line: str) -> list[str]:
    """Find every `LocalizedStringResource("...\\(...)...")` literal on a
    single source line. Returns the literal content (between the quotes)
    only when at least one `\\(` is present. Skips literals without
    interpolations (those need no format-key check)."""
    literals: list[str] = []
    cursor = 0
    while True:
        idx = line.find(START_TOKEN, cursor)
        if idx < 0:
            break
        cursor = idx + len(START_TOKEN)
        if cursor >= len(line) or line[cursor] != '"':
            continue
        cursor += 1  # past opening quote
        start = cursor
        while cursor < len(line):
            char = line[cursor]
            if char == "\\" and cursor + 1 < len(line):
                # Skip escape sequences (incl. \( interpolation marker).
                if line[cursor + 1] == "(":
                    depth = 1
                    cursor += 2
                    while cursor < len(line) and depth > 0:
                        if line[cursor] == "(":
                            depth += 1
                        elif line[cursor] == ")":
                            depth -= 1
                        cursor += 1
                    continue
                cursor += 2
                continue
            if char == '"':
                literal = line[start:cursor]
                if "\\(" in literal:
                    literals.append(literal)
                cursor += 1
                break
            cursor += 1
        else:
            break
    return literals


def skeleton(literal: str) -> str:
    """Replace each `\\(...)` interpolation (with balanced parens) with `{}`."""
    out: list[str] = []
    cursor = 0
    while cursor < len(literal):
        if literal[cursor] == "\\" and cursor + 1 < len(literal) and literal[cursor + 1] == "(":
            depth = 1
            cursor += 2
            while cursor < len(literal) and depth > 0:
                if literal[cursor] == "(":
                    depth += 1
                elif literal[cursor] == ")":
                    depth -= 1
                cursor += 1
            out.append("{}")
            continue
        out.append(literal[cursor])
        cursor += 1
    return "".join(out)


def expected_keys(literal: str) -> list[str]:
    """Produce candidate xcstrings keys by substituting each placeholder
    suffix uniformly across all interpolation positions."""
    sk = skeleton(literal)
    interpolations = sk.count("{}")
    if interpolations == 0:
        return [sk]
    parts = sk.split("{}")
    return [suffix.join(parts) for suffix in PLACEHOLDER_SUFFIXES]


def load_keys() -> set[str]:
    if not XCSTRINGS.exists():
        return set()
    try:
        data = json.loads(XCSTRINGS.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return set()
    return set((data.get("strings") or {}).keys())


def main() -> int:
    catalogue = load_keys()
    offenders: list[tuple[Path, int, str, list[str]]] = []
    for swift in APP_DIR.rglob("*.swift"):
        try:
            text = swift.read_text(encoding="utf-8", errors="ignore")
        except OSError:
            continue
        for lineno, line in enumerate(text.splitlines(), 1):
            stripped = line.strip()
            if stripped.startswith("//") or stripped.startswith("///"):
                continue
            for literal in extract_literals_with_interpolation(line):
                candidates = expected_keys(literal)
                if not any(key in catalogue for key in candidates):
                    offenders.append((swift, lineno, literal, candidates))

    if not offenders:
        print(
            "✓ no LocalizedStringResource interpolation violations "
            f"(scanned {len(catalogue)} keys in catalogue)"
        )
        return 0

    print(f"L006 sister-scan: {len(offenders)} site(s) reference a missing format key")
    for path, lineno, literal, candidates in offenders:
        rel = path.relative_to(REPO)
        print(f"  {rel}:{lineno}  literal=\"{literal}\"")
        print(f"     looked for any of: {candidates}")
    print("\nFix: add the matching key with the %@/%lld suffix to Localizable.xcstrings.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
