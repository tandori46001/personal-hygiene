#!/usr/bin/env python3
"""
scripts/check-localized-key-usage.py — round 19 slice 2

Backup static scan for L006 (the SwiftUI dynamic-key gotcha). Runs alongside
the SwiftLint custom rule `dynamic_localized_key` so the check is enforced
even on contributors who skip lint, and so it can run inside `check-tests.sh`
without spawning SwiftLint twice.

Flags any source line that constructs `LocalizedStringKey("...\\(...)")`
because SwiftUI re-interprets `\\(...)` as a `%@` placeholder and looks up
the *format* key, not the literal runtime string.

Allowed patterns:
- `Text(localizedKey: "prefix.\\(rawValue)")` — the round-19 helper.
- `LocalizedStringResource("foo.bar %lld", ... \\(N))` — only when xcstrings
  has the matching `%@`/`%lld` format key (verified by check-xcstrings-format-consistency.py).

Exit codes:
  0  no violations
  1  one or more violations found
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
APP_DIR = REPO / "App"
ALLOWLIST = {
    REPO / "App" / "Shared" / "Localization" / "TextLocalizedKey.swift",
}

# Match LocalizedStringKey("...\(...)") — the unsafe pattern.
PATTERN = re.compile(r'LocalizedStringKey\("[^"]*\\\([^"]*"\)')


def main() -> int:
    offenders: list[tuple[Path, int, str]] = []
    for swift in APP_DIR.rglob("*.swift"):
        if swift in ALLOWLIST:
            continue
        try:
            text = swift.read_text(encoding="utf-8", errors="ignore")
        except OSError:
            continue
        for lineno, line in enumerate(text.splitlines(), 1):
            stripped = line.strip()
            if stripped.startswith("//") or stripped.startswith("///"):
                continue
            if PATTERN.search(line):
                offenders.append((swift, lineno, stripped))

    if not offenders:
        print("✓ no LocalizedStringKey dynamic-key violations (L006 clean)")
        return 0

    print(f"L006 violations: {len(offenders)} site(s)")
    for path, lineno, line in offenders:
        rel = path.relative_to(REPO)
        print(f"  {rel}:{lineno}  {line}")
    print("\nFix: replace with Text(localizedKey: \"prefix.\\(rawValue)\")")
    return 1


if __name__ == "__main__":
    sys.exit(main())
