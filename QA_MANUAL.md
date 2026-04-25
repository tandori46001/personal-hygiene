# QA Manual

> Living checklist of every shipped feature with a `[T-XXX]` test section.
> **HARD RULE:** Every bug fix and every new feature MUST update this file in the same commit. See [CONTRIBUTING.md § QA-mandatory rule](CONTRIBUTING.md).

---

## How to read this file

Each `[T-XXX]` section corresponds to a feature or shipped change. Sections are append-only — never edit history, only add new cases.

Format:

```markdown
## [T-XXX] — Feature title

**Module:** M1 / M2 / etc.
**Phase:** 1 / 2 / etc.
**Shipped in:** SHA / version

### Cases
1. Happy path — <what to verify>
2. Edge case — <…>
3. Empty state — <…>
4. Regression — <previous bug SHA + behavior>

### How to test
<step-by-step manual procedure>
```

---

## Index

| Section | Module | Phase | Shipped |
|---|---|---|---|
| [T-001](#t-001--block--routinetemplate-domain-models) | M1 | 1 | First slice |

---

## Test environment

Manual QA is performed on:
- iPhone (primary device, latest iOS).
- Apple Watch (when paired) — Series 6+ for testing.
- iOS Simulator (Xcode latest) for edge cases not reachable on device.

Always test with: `MockHealthKit OFF` + real iCloud account on the device.

---

## Sections

## [T-001] — Block + RoutineTemplate domain models

**Module:** M1 (routine templates)
**Phase:** 1 (first slice)
**Shipped in:** [pending commit]

### Cases (automated — `Tests/Unit/Models/`)
1. `Block.endMinutesFromMidnight` returns `start + duration`.
2. `Block` default initializer uses `notificationLeadMinutes = 15`, `isDeepFocus = false`, `notes = nil`.
3. `Block` Codable round-trip preserves all fields.
4. `RoutineTemplate.sortedBlocks` returns blocks in chronological order.
5. `RoutineTemplate` default initializer sets `version = 1` and empty blocks.

### How to test
```bash
./scripts/check-tests.sh
```
Expected: 5 tests green.

### Manual verification (sanity)
1. Open app in Simulator (iPhone 17 Pro or any iPhone 18+).
2. Verify `RoutineListView` renders 4 sample blocks in chronological order: Aseo (07:00), Desayuno (07:30), Medicación (08:00), Trabajo (09:00).
3. Verify each row shows title, category, and start time in HH:MM format.
4. Verify `routine.title` localizes correctly when device locale is `en` / `es` / `fr` ("My routine" / "Mi rutina" / "Ma routine").

