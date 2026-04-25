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

_(none yet — sections accrue per feature shipped)_

---

## Test environment

Manual QA is performed on:
- iPhone (primary device, latest iOS).
- Apple Watch (when paired) — Series 6+ for testing.
- iOS Simulator (Xcode latest) for edge cases not reachable on device.

Always test with: `MockHealthKit OFF` + real iCloud account on the device.

---

## Sections

_(append `## [T-001]`, `## [T-002]`, … below as features ship)_
