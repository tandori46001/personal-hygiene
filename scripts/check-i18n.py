#!/usr/bin/env python3
"""
Verify every key in `Localizable.xcstrings` has translations for all
three required locales (en, es, fr). Exits 1 with a per-key report on
the first missing translation.

Run:
    python3 scripts/check-i18n.py
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
CATALOG = REPO_ROOT / "App/Shared/Localization/Localizable.xcstrings"
REQUIRED_LOCALES = ("en", "es", "fr")


def main() -> int:
    if not CATALOG.exists():
        print(f"ERROR: catalog not found at {CATALOG}", file=sys.stderr)
        return 2

    catalog = json.loads(CATALOG.read_text(encoding="utf-8"))
    strings = catalog.get("strings", {})
    if not strings:
        print(f"ERROR: no strings in catalog {CATALOG}", file=sys.stderr)
        return 2

    missing: dict[str, list[str]] = {}
    untranslated: dict[str, list[str]] = {}

    for key, payload in strings.items():
        localizations = payload.get("localizations", {}) or {}
        for locale in REQUIRED_LOCALES:
            entry = localizations.get(locale)
            if not entry:
                missing.setdefault(key, []).append(locale)
                continue
            string_unit = entry.get("stringUnit", {})
            state = string_unit.get("state")
            value = string_unit.get("value")
            if not value:
                missing.setdefault(key, []).append(locale)
                continue
            if state and state != "translated":
                untranslated.setdefault(key, []).append(f"{locale}:{state}")

    if not missing and not untranslated:
        total = len(strings)
        locales = ", ".join(REQUIRED_LOCALES)
        print(f"==> i18n parity OK: {total} keys × {{{locales}}}")
        return 0

    if missing:
        print(f"ERROR: {len(missing)} keys missing translations:", file=sys.stderr)
        for key, locales in sorted(missing.items()):
            print(f"  {key}: missing {', '.join(locales)}", file=sys.stderr)
    if untranslated:
        print(f"ERROR: {len(untranslated)} keys not in 'translated' state:", file=sys.stderr)
        for key, descriptions in sorted(untranslated.items()):
            print(f"  {key}: {', '.join(descriptions)}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
