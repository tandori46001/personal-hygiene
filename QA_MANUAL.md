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
| [T-002](#t-002--swiftdata-persistence--routinerepository) | M1 | 1 | Slice 1+3 |
| [T-003](#t-003--blockeditorview--blockeditorviewmodel) | M1 | 1 | Slice 4 |
| [T-004](#t-004--templateeditorview) | M1 | 1 | Slice 5 |
| [T-005](#t-005--templatelistview) | M1 | 1 | Slice 6 |
| [T-006](#t-006--todayview) | M1 | 1 | Slice 7 |
| [T-007](#t-007--onboardingview) | M1 | 1 | Slice 8 |
| [T-008](#t-008--notificationservice--scheduling) | M2 | 1 | Slices 9-11 |
| [T-009](#t-009--medicationcomplianceview) | M3 | 1 | Slice 17 |
| [T-010](#t-010--bedtimecalculator--sleepdashboard) | M4 | 1 | Slices 18-20 |
| [T-011](#t-011--travel-time-notifications-domain--service) | M2 | 1 | Slice 12a |

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

---

## [T-002] — SwiftData persistence + RoutineRepository

**Module:** M1 · **Phase:** 1 · **Shipped in:** `b5aeb07`

### Cases (automated — `Tests/Unit/Persistence/SwiftDataRoutineRepositoryTests.swift`)
1. `upsert(template)` persists and `allTemplates()` returns it.
2. `setActive` marks only one template per `DayType` active.
3. `upsert(block, in: template)` appends the block via the relationship.
4. `delete(template)` cascades and removes child blocks.

### Regression guard (L001)
The suite as a whole crashes the simulator if `ModelContainer` is allowed to deallocate while a `ModelContext` derived from it is still in use. See `LESSONS.md § L001`.

---

## [T-003] — BlockEditorView + BlockEditorViewModel

**Module:** M1 · **Phase:** 1 · **Shipped in:** `cad6f17`

### Cases (automated — `Tests/Unit/ViewModels/BlockEditorViewModelTests.swift`)
1. `isValid` false when title empty / whitespace-only.
2. `isValid` true with sensible defaults + non-empty title.
3. `isValid` false when duration is 0 or hour out of range.
4. `init(editing:)` populates all fields from an existing `Block`.
5. `snapshot()` returns a `Block` matching the form state (trimmed title).
6. `apply(to:)` mutates an existing `Block` in place.

### Manual verification
- Open Templates → tap a template → tap "Add block" → fill fields → Save. Block appears.
- Tap an existing block → edit title → Save. Title updates.
- Try to Save with an empty title — Save button is disabled.

---

## [T-004] — TemplateEditorView

**Module:** M1 · **Phase:** 1 · **Shipped in:** `cad6f17`

### Manual verification
1. Tap a template from the list. Editor opens with name + day-type pickers + block list.
2. Tap "Add block" → BlockEditor sheet opens. Save → block appears in list.
3. Tap an existing block → BlockEditor opens with fields prefilled. Edit → Save → updates.
4. Swipe-to-delete a block. The block is removed and not in the database after restart.
5. Edit name + Save. Verify `template.version` bumps (DB inspection if available).

---

## [T-005] — TemplateListView

**Module:** M1 · **Phase:** 1 · **Shipped in:** `cad6f17`

### Manual verification
1. Templates tab — list shows all templates.
2. Tap "+" → New template sheet → enter name + day type → Create. Appears in list.
3. Tap "Activate" on an inactive weekday template — green checkmark appears, previous active loses it.
4. Swipe-to-delete a template. Confirm removed and its blocks cascade-deleted.
5. Empty state appears when no templates exist (delete all).

---

## [T-006] — TodayView

**Module:** M1 · **Phase:** 1 · **Shipped in:** `cad6f17`

### Cases (automated — `Tests/Unit/ViewModels/TodayViewModelTests.swift`)
1. `dayType` returns `.weekend` for Sunday and Saturday.
2. `dayType` returns `.weekday` for Monday through Friday.
3. `reload` pulls the active template for today's day type.
4. `currentBlock(at:)` returns the block whose interval contains the given time.
5. `nextBlock(after:)` returns the first block starting strictly after the given time.

### Manual verification
- Open Today tab. Title bar = "Today" (locale-dependent).
- If a block is in progress, "Now" section shows it.
- Otherwise, "Next up" section shows the next upcoming block.
- Empty state appears when no template is active for today's day type.

---

## [T-007] — OnboardingView

**Module:** M1 · **Phase:** 1 · **Shipped in:** `cad6f17`

### Manual verification
1. Fresh app install (or wipe SwiftData store + clear `hasCompletedOnboarding` UserDefault).
2. Onboarding screen appears on launch.
3. Tap "Get started". Two seeded templates appear in the Templates tab — "Weekday routine" (active) + "Weekend routine" (active).
4. Today tab shows the appropriate template based on the current weekday.
5. Restart the app — onboarding does NOT appear again.

---

## [T-008] — NotificationService + scheduling

**Module:** M2 · **Phase:** 1 · **Shipped in:** `fc43f97`

### Cases (automated — `Tests/Unit/Services/NotificationFactoryTests.swift`)
1. `notifications(for:on:)` emits a trigger at `block.start - lead`.
2. Blocks where the lead crosses midnight are skipped.
3. Medication-category blocks are marked `isCritical = true`.
4. Identifiers are stable for the same block + day.
5. Identifiers differ across days for the same block.

### Manual verification (real device or simulator with notifications enabled)
1. Settings tab → "Request permission" → grant. Status flips to "Granted".
2. Tap "Refresh today's notifications". Verify pending notifications appear in iOS Settings → Notifications → personal-hygiene → Pending (or via developer console).
3. For a block at 08:00 with 15 min lead, expect a notification at 07:45.
4. Wait or skip-time-forward — notification fires with the block title.

---

## [T-009] — MedicationComplianceView

**Module:** M3 · **Phase:** 1 · **Shipped in:** `ebd00ec`

### Cases (automated — `Tests/Unit/Services/MedicationComplianceTests.swift`)
1. `dailySummaries` buckets logs by `startOfDay` and counts taken vs scheduled.
2. `overallAdherence` returns 1.0 when no logs.
3. `overallAdherence` computes `taken / total`.
4. `overallAdherence` excludes logs outside `[start, end]`.

### Manual verification (real device required for end-to-end)
1. Simulator: Medication tab shows "Health data unavailable" empty state.
2. Real device: link a medication block to a HealthKit concept. Take doses for several days. Open Medication tab — daily summaries + overall adherence appear.

---

## [T-010] — BedtimeCalculator + SleepDashboard

**Module:** M4 · **Phase:** 1 · **Shipped in:** `ebd00ec`

### Cases (automated — `Tests/Unit/Services/BedtimeCalculatorTests.swift`)
1. Wake-up 07:00, default target → bedtime 23:15 (previous evening).
2. Wake-up 08:00, default target → bedtime 00:15.
3. Custom target (8h) → wake 06:00, bedtime 22:00.
4. Bedtime is always within `[0, 24*60)` for any wake-up minute.
5. Deficit positive when actual < target.
6. Deficit negative when actual > target.

### Manual verification
1. Sleep tab opens. Default wake-up = 06:30 → bedtime = 22:45.
2. Adjust wake-up via steppers → bedtime recomputes live.
3. "Open Focus settings" link opens iOS Settings → Focus.
4. Real device with sleep data: "Last night actual" + deficit warning appear.

---

## [T-011] — Travel-time notifications (domain + service)

**Module:** M2 · **Phase:** 1 · **Shipped in:** slice 12a

### Cases (automated)
- `Tests/Unit/Models/BlockLocationTests.swift` — coordinate exposure, validity, Codable roundtrip.
- `Tests/Unit/Models/BlockTests.swift` — location getter/setter mirrors lat/lon/name; SwiftData roundtrip preserves location fields.
- `Tests/Unit/Services/TravelTimeServiceTests.swift` — `StaticTravelTimeService` returns default vs override; overrides are directional.
- `Tests/Unit/Services/NotificationFactoryTests.swift` — async path adds travel-time on top of static lead, rounds seconds up to the next minute, falls back to static lead when no location / when service throws, skips blocks where the combined lead would cross midnight.

### Manual verification (deferred to slice 12b — UI)
1. Slice 12b will add a location picker on `BlockEditor` and a home-location field in Settings; this section will gain step-by-step coverage at that time.
2. Until then, travel-time wiring is exercised only via tests + by passing `homeLocation` + `MKDirectionsTravelTimeService()` to `NotificationCoordinator` programmatically.

