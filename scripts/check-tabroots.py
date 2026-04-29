#!/usr/bin/env python3
"""L004 guard — round-12 slice 6.

Tab-root views that live inside iOS 18 TabView "More" overflow must NOT
wrap their body in their own `NavigationStack`. The system already wraps
the overflow tab in a NavigationStack, so a second one yields two stacked
back chevrons when pushing into a child view (round-8 hotfix `5b038d0`).

This script greps the known set of "tab root" view files for an inner
`NavigationStack {` and fails CI if it finds one. Updating the list when
adding a new tab is part of the routine: any view that becomes a tab root
must be added here.

Exit codes:
  0  no offenders
  1  one or more offenders found
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
FEATURES = REPO / "App" / "PersonalHygiene" / "Features"

# Files that live as tab-root views inside the iOS 18 TabView **More**
# overflow. The first 4 tabs (Today / Templates / Medication / Sleep)
# are direct tabs — they DO need their own `NavigationStack` because
# the system does not wrap them, so they are NOT in this list.
# Tabs 5-9 (Hydration / Housekeeping / Birthdays / Trips / Settings)
# collapse into More, which provides a NavigationStack — those must
# NOT add their own (L004).
TAB_ROOTS = [
    FEATURES / "Hydration" / "Views" / "HydrationDashboardView.swift",
    FEATURES / "Housekeeping" / "Views" / "HousekeepingListView.swift",
    FEATURES / "Birthdays" / "Views" / "BirthdaysView.swift",
    FEATURES / "Vacation" / "Views" / "TripsListView.swift",
    FEATURES / "Settings" / "Views" / "SettingsView.swift",
]

PATTERN = re.compile(r"\bNavigationStack\s*\{")


def scan(path: Path) -> list[tuple[int, str]]:
    if not path.exists():
        return []
    offenders: list[tuple[int, str]] = []
    for lineno, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        # Inline-OK: presentation `sheet { NavigationStack { … } }` blocks
        # are fine because they live inside a sheet, not the tab body.
        # Heuristic: skip lines whose preceding non-comment context is a
        # `.sheet(` / `.fullScreenCover(` / inside a private struct.
        if "sheet" in line and "NavigationStack" in line:
            continue
        if PATTERN.search(line):
            offenders.append((lineno, line.strip()))
    return offenders


NAV_LINK_PATTERN = re.compile(r"\bNavigationLink\b")
SHEET_OR_COVER_PATTERN = re.compile(r"\.sheet|\.fullScreenCover|private struct |private var ")


def main() -> int:
    rc = 0
    for path in TAB_ROOTS:
        if not path.exists():
            continue
        text = path.read_text(encoding="utf-8")
        # The double-back-arrow bug only manifests when the tab-root view
        # both wraps itself in a NavigationStack AND pushes a child via
        # NavigationLink. View-only roots (no NavigationLink) are exempt
        # — Hydration / Housekeeping / Birthdays were intentionally kept
        # this way per the original L004 capture.
        if not NAV_LINK_PATTERN.search(text):
            continue
        offenders: list[tuple[int, str]] = []
        lines = text.splitlines()
        for lineno, line in enumerate(lines, 1):
            if not PATTERN.search(line):
                continue
            # Skip lines inside `.sheet { NavigationStack { … } }` —
            # presentation modifiers are fine.
            # Look back further so multi-line `private var sheet: some View {`
            # bodies followed by a `NavigationStack` line still register as
            # sheet-helper context.
            preceding = "\n".join(lines[max(0, lineno - 30): lineno - 1])
            if SHEET_OR_COVER_PATTERN.search(preceding):
                continue
            # Skip lines inside `private struct …` (preview helpers).
            full_preceding = "\n".join(lines[: lineno - 1])
            last_struct = full_preceding.rfind("private struct ")
            last_main_struct = full_preceding.rfind("struct ")
            if last_struct == last_main_struct and last_struct >= 0:
                continue
            offenders.append((lineno, line.strip()))
        if offenders:
            rc = 1
            print(f"L004 violation in {path.relative_to(REPO)}:")
            for lineno, line in offenders:
                print(f"  line {lineno}: {line}")
    if rc == 0:
        print("✓ tab-root views OK (no inner NavigationStack with NavigationLink)")
    return rc


if __name__ == "__main__":
    sys.exit(main())
