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
| [T-012](#t-012--hydration-tab) | M5 | 3 | Slice 9-10 (S3) |
| [T-013](#t-013--housekeeping-tab) | M6 | 3 | Slice 11-12 (S3) |
| [T-014](#t-014--birthdays-tab) | M7 | 3 | Slice 13-14 (S3) |
| [T-015](#t-015--deep-focus-filter) | M8 | 3 | Slice 15-16 (S3) |
| [T-016](#t-016--trip-crud--documents-keychain) | M9 | 5 | Slice 20-21 (S3) |
| [T-017](#t-017--trip-detail--milestones-ui) | M9 | 5 | Slices 1-2 (S4) |
| [T-018](#t-018--milestone-notifications) | M9 | 5 | Slice 3 (S4) |
| [T-019](#t-019--document-scanner--preview) | M9 | 5 | Slices 4-5 (S4) |
| [T-020](#t-020--ai-itinerary--marine--currency--advisory) | M9 | 5 | Slices 6-9 (S4) |
| [T-021](#t-021--trip-pdf-export) | M9 | 5 | Slice 10 (S4) |
| [T-022](#t-022--today-completion--summary--countdown) | M1+M9 | 1 | Slices 11-13 (S4) |
| [T-023](#t-023--itinerary-persistence) | M9 | 5 | Slice 1 (S5) |
| [T-024](#t-024--marine-cache) | M9 | 5 | Slice 2 (S5) |
| [T-025](#t-025--currency-cache) | M9 | 5 | Slice 3 (S5) |
| [T-026](#t-026--advisory-cache) | M9 | 5 | Slice 4 (S5) |
| [T-027](#t-027--past-trips-archive) | M9 | 5 | Slice 5 (S5) |
| [T-028](#t-028--trip-detail-cancelsave-draft) | M9 | 5 | Slice 6 (S5) |
| [T-029](#t-029--swiftlint-hardcoded-ui-strings) | infra | — | Slice 7 (S5) |
| [T-030](#t-030--today-empty-state-cta) | M1 | 1 | Slice 8 (S5) |
| [T-031](#t-031--block-skip-today) | M1+M2 | 1 | Slice 9 (S5) |
| [T-032](#t-032--notification-snooze-5min) | M2 | 1 | Slice 10 (S5) |
| [T-033](#t-033--notification-thread-grouping) | M2 | 1 | Slice 11 (S5) |
| [T-034](#t-034--whatsnextintent-siri-shortcut) | M1 | 1 | Slice 12 (S5) |
| [T-035](#t-035--ios-nextblock-home-widget) | M1 | 1 | Slice 13 (S5) |
| [T-036](#t-036--trip-cover-photo) | M9 | 5 | Slice 14 (S5) |
| [T-037](#t-037--packing-list) | M9 | 5 | Slice 15 (S5) |
| [T-038](#t-038--hydration-streak) | M5 | 3 | Slice 16 (S5) |
| [T-039](#t-039--housekeeping-room-filter) | M6 | 3 | Slice 17 (S5) |
| [T-040](#t-040--birthdays-per-contact-lead) | M7 | 3 | Slice 18 (S5) |
| [T-041](#t-041--scheduled-focus-windows) | M8 | 3 | Slice 19 (S5) |
| [T-042](#t-042--voiceover-natural-language-time) | a11y | — | Slice 20 (S5) |

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

---

## [T-012] — Hydration tab

**Module:** M5 · **Phase:** 3

### Cases (automated)
- `Tests/Unit/Services/HydrationServiceTests.swift` — log/append/total flows.
- `Tests/Unit/Services/HydrationComplianceTests.swift` — 7-day adherence math.
- `Tests/Unit/Services/HydrationNotificationFactoryTests.swift` — reminder cadence.
- `Tests/Unit/ViewModels/HydrationDashboardViewModelTests.swift` — VM logging.

### Manual verification
1. Hydration tab → verify default goal = 2000 mL.
2. Tap +250 mL three times → progress bar advances; today's history lists 3 entries.
3. Adjust goal stepper down → progress percentage recomputes.
4. Restart app → today's logs persist; yesterday's are absent (separate calendar day).
5. Empty state appears the next day before any log is added.

---

## [T-013] — Housekeeping tab

**Module:** M6 · **Phase:** 3

### Cases (automated)
- `Tests/Unit/Services/HousekeepingSchedulerTests.swift` — pending/dueToday/overdue arithmetic.
- `Tests/Unit/Services/HousekeepingServiceTests.swift` — CRUD flows.
- `Tests/Unit/ViewModels/HousekeepingListViewModelTests.swift` — VM CRUD + status badges.

### Manual verification
1. Housekeeping tab → tap "+" → create "Vacuum" with 7-day cadence.
2. Mark complete → status badge flips to OK; next-due date is +7d.
3. Skip-time-forward 8 days → badge flips to "overdue".
4. Swipe-to-delete a task → it's gone; relaunching confirms it's removed.

---

## [T-014] — Birthdays tab

**Module:** M7 · **Phase:** 3

### Cases (automated)
- `Tests/Unit/Services/UpcomingBirthdaysTests.swift` — 60-day window, year-rollover, sorting.
- `Tests/Unit/Services/ContactsServiceTests.swift` — InMemory service stub.
- `Tests/Unit/ViewModels/BirthdaysViewModelTests.swift` — permission flow + denied state.

### Manual verification
1. Birthdays tab on first launch → permission CTA visible.
2. Tap "Allow" → grant Contacts permission → list populates with upcoming birthdays.
3. Tap "Deny" → denied state explains how to grant access in Settings.
4. List shows "in N d" countdown for each contact.

---

## [T-015] — Deep Focus filter

**Module:** M8 · **Phase:** 3

### Cases (automated — `Tests/Unit/Services/DeepFocusFilterTests.swift`)
1. `focusWindows(for:on:)` produces a window per `block.isDeepFocus == true`.
2. `suppressing(_:focusWindows:)` removes non-critical notifications inside windows.
3. Medication-critical notifications always pass (interruptionLevel = .critical).

### Manual verification
1. Mark a non-medication block as Deep Focus → its notification is suppressed during the window.
2. Today view banner shows "Deep focus on <block>" while inside the window.
3. Block rows that are Deep Focus show a moon.zzz badge.

---

## [T-016] — Trip CRUD + documents (Keychain)

**Module:** M9 · **Phase:** 5

### Cases (automated)
- `Tests/Unit/Persistence/TripsRepositoryTests.swift` — upsert / cascade delete.
- `Tests/Unit/Services/KeychainStoreTests.swift` — read/write/delete + missing-item.
- `Tests/Unit/Services/TripDocumentStoreTests.swift` — paired metadata + bytes.

### Manual verification
1. Trips tab → tap "+" → create "Crucero" Mallorca, dates ahead.
2. Tap row → trip detail opens; edit name + Save (auto-saved on disappear).
3. Add a milestone "Pack" with 1 day before. Verify it appears in the milestones list.
4. Swipe-delete trip → trip + milestones + documents are all gone.

---

## [T-017] — Trip detail + milestones UI

**Module:** M9 · **Phase:** 5

### Cases (automated — `Tests/Unit/ViewModels/TripDetailViewModelTests.swift`)
1. `sortedMilestones` orders by `daysBefore` descending (farthest-first).
2. `addMilestone(title:daysBefore:)` trims title and clamps days to ≥ 0.
3. `addMilestone` with blank title is a no-op.
4. `updateMilestone(...)` applies title / days / completion.
5. `toggleMilestoneCompletion(_:)` flips the bool.
6. `deleteMilestone(_:)` removes from the trip.
7. `daysUntilDeparture` returns positive Int when target is in the future.

### Manual verification
1. Trip detail → tap "Add milestone" → fill form → Save. Row appears.
2. Tap a milestone row → editor opens with prefilled fields → edit → Save → row updates.
3. Tap the circle icon on a milestone row → it flips to ✓ without opening the sheet.
4. Pull title down to a longer name → blocks save action.
5. Days-stepper clamps at 0 lower bound, 365 upper bound.

---

## [T-018] — Milestone notifications

**Module:** M9 · **Phase:** 5

### Cases (automated — `Tests/Unit/Services/TripMilestoneNotificationFactoryTests.swift`)
1. Each milestone fires at 09:00 local on `tripStart - daysBefore`.
2. `isComplete` milestones produce no notification.
3. Past-trigger milestones are skipped.
4. Identifiers are stable for the same milestone.
5. Each milestone in a trip yields exactly one notification.

### Manual verification
1. Create a trip starting in 14 days; add milestones at 7d / 1d / 0d.
2. Background the app → relaunch → check pending notifications via Settings → personal-hygiene.
3. Confirm three pending alerts at 09:00 on day −7, −1, and trip start.
4. Mark the 7d milestone done → relaunch → that notification disappears from pending.

---

## [T-019] — Document scanner + preview

**Module:** M9 · **Phase:** 5

### Manual verification (real device — camera required)
1. Trip detail → tap "Scan document" → grant Camera permission once.
2. Scan a passport-shaped sheet → tap "Save" in the system scanner UI.
3. Metadata sheet appears → set name = "Passport", kind = passport → Save.
4. Document row appears under Documents. Tap it → PDF preview opens via PDFKit.
5. Force-quit app → relaunch → document still visible (Keychain-persisted).
6. Swipe-delete the document row → both metadata and Keychain bytes are gone.

---

## [T-020] — AI itinerary / Marine / Currency / Advisory

**Module:** M9 · **Phase:** 5

### Cases (automated)
- `Tests/Unit/Services/StubItineraryGeneratorTests.swift` — deterministic per-day count.
- `Tests/Unit/Services/OpenMeteoMarineServiceTests.swift` — JSON parse + offshore-only fallback.
- `Tests/Unit/Services/FrankfurterCurrencyServiceTests.swift` — rate computation + missing-target error.
- `Tests/Unit/Services/TravelAdvisoryServiceTests.swift` — URL synthesis.

### Manual verification
1. **Itinerary**: Trip detail → "AI itinerary" → "Generate". On iOS 26+ device with Apple Intelligence, real plan appears; on older OS, deterministic stub appears.
2. **Marine**: Trip detail → "Marine conditions" (only visible if trip has lat/lon). Wave height + sea temp populate or show "offshore only" error.
3. **Currency**: Trip detail → "Currency" → enter amount → Convert. Verify rate + amount converted.
4. **Advisory**: Trip detail → "Travel advisory" → tap "Open advisory page" → opens Safari at exteriores.gob.es with destination as `?q=…`.

---

## [T-021] — Trip PDF export

**Module:** M9 · **Phase:** 5

### Cases (automated — `Tests/Unit/Services/TripPDFExporterTests.swift`)
1. `render(trip:)` returns non-empty Data that PDFKit can parse.
2. Rendered PDF text contains trip name, destination, milestone titles, and document names.

### Manual verification
1. Trip detail → toolbar share button (square.and.arrow.up).
2. Share sheet appears with a PDF preview.
3. Save to Files / send via Mail → verify the PDF opens with cover + Milestones + Documents sections.

---

## [T-022] — Today: completion / summary / trip countdown

**Module:** M1 + M9 · **Phase:** 1

### Cases (automated — `Tests/Unit/ViewModels/TodayViewModelTests.swift`)
1. `toggleDone(_:)` marks then unmarks idempotently.
2. `reload(now:)` rehydrates today's completions into `completedBlockIDs`.
3. `nextUpcoming(...)` picks the earliest future trip, ignoring past trips.

### Manual verification
1. Today tab → each block row has a circle icon. Tap → it flips to ✓ + title strikes-through.
2. Summary card above the now-row shows "X of N blocks done"; ProgressView fills as you check off rows.
3. Create an upcoming trip → return to Today → the trip countdown card shows the trip name + days-until-departure.
4. Restart app → completions and countdown still accurate (depends on calendar day).


---

## [T-023] — Itinerary persistence

**Module:** M9 · **Phase:** 5 · **Shipped in:** session 5 slice 1

### Cases (automated — `Tests/Unit/Services/ItineraryStoreTests.swift`)
1. `save(_:for:)` writes a JSON file under the app's documents dir keyed by trip id.
2. `load(for:)` returns the previously-saved itinerary.
3. `load(for:)` returns nil after `clear(for:)`.
4. `clear(for:)` is a no-op when no itinerary exists for that trip.

### Manual verification
1. Open a trip → AI itinerary → Generate. An itinerary appears.
2. Force-quit app → relaunch → reopen the same trip → itinerary is still there.

---

## [T-024] — Marine cache

**Module:** M9 · **Phase:** 5 · **Shipped in:** session 5 slice 2

### Cases (automated — `Tests/Unit/Services/CachedMarineWeatherServiceTests.swift`)
1. First call delegates to underlying service and caches result.
2. Second call within TTL returns cached result without delegating.
3. Different (lat, lon) keys do not collide.
4. After TTL expiry the cache refreshes from underlying service.

### Manual verification
1. Open a trip with coordinates → Marine conditions panel loads (network call).
2. Close + reopen panel within 30 minutes → no network spinner; data is instant.

---

## [T-025] — Currency cache

**Module:** M9 · **Phase:** 5 · **Shipped in:** session 5 slice 3

### Cases (automated — `Tests/Unit/Services/CachedCurrencyServiceTests.swift`)
1. First convert delegates and caches the per-unit rate.
2. Second convert with same (from, to) pair within TTL applies cached rate locally to the new amount.
3. Different currency pairs do not collide.

### Manual verification
1. Trip → Currency → enter 100 EUR → JPY → Convert (network).
2. Change amount to 200 → Convert. No network call; result is double the previous amount.

---

## [T-026] — Advisory cache

**Module:** M9 · **Phase:** 5 · **Shipped in:** session 5 slice 4

### Cases (automated — `Tests/Unit/Services/CachedTravelAdvisoryServiceTests.swift`)
1. First `advisoryURL(for:)` call memoizes the URL for the destination.
2. Subsequent calls within TTL return the cached URL.
3. Different destinations do not collide.

### Manual verification
1. Trip → Advisory → Open advisory page. Safari opens at exteriores.gob.es.
2. Reopen the trip → URL builder hits the in-memory cache (no perceptible difference; verify via test).

---

## [T-027] — Past trips archive

**Module:** M9 · **Phase:** 5 · **Shipped in:** session 5 slice 5

### Cases (automated — extends `TripsRepositoryTests` / view-layer manual)
- `Trip.endDate < today` → goes to "Past" section.
- `Trip.endDate >= today` → stays under "Upcoming".

### Manual verification
1. Create a trip with endDate yesterday → it appears in Past section, not Upcoming.
2. Create a trip with future startDate → it appears in Upcoming section.
3. Both sections show counts in their headers.

---

## [T-028] — Trip detail Cancel/Save (draft)

**Module:** M9 · **Phase:** 5 · **Shipped in:** session 5 slice 6

### Cases (automated — `Tests/Unit/ViewModels/TripDetailViewModelTests.swift`)
1. `commitDraft()` writes draft scalar buffers back to the SwiftData model.
2. `revertDraft()` restores the draft buffers from the persisted trip.
3. Editing a draft field without committing leaves persisted trip unchanged.

### Manual verification
1. Trip detail → edit name → tap "Cancel" → name reverts.
2. Edit name + dates → tap "Save" → values persist after app restart.

---

## [T-029] — SwiftLint hardcoded UI strings

**Module:** infra · **Shipped in:** session 5 slice 7

### Cases (regression)
1. Add a `Text("foo")` literal to any view file → `./scripts/lint.sh --strict` fails with `hardcoded_text_view`.
2. Repeat with `.navigationTitle("foo")`, `.accessibilityLabel("foo")`, button label literals.
3. Removing the literals (replacing with `LocalizedStringKey`) makes lint green again.

### Manual verification
None — purely build-time guard.

---

## [T-030] — Today empty-state CTA

**Module:** M1 · **Phase:** 1 · **Shipped in:** session 5 slice 8

### Cases (automated — view-layer manual)
1. With no active template for today's day type, Today shows empty state + "Create template" button.
2. Tapping the button switches the tab bar selection to Templates.

### Manual verification
1. Delete all templates (or de-activate weekday template on a weekday).
2. Open Today → empty state appears with CTA.
3. Tap "Create template" → app navigates to Templates tab.

---

## [T-031] — Block skip-today

**Module:** M1 + M2 · **Phase:** 1 · **Shipped in:** session 5 slice 9

### Cases (automated — `Tests/Unit/Services/BlockSkipStoreTests.swift` + `TodayViewModelTests`)
1. `toggleSkip(blockID:on:)` toggles a `(blockID, dayKey)` entry.
2. `isSkipped(...)` returns true after toggle, false after second toggle.
3. Entries older than 7 days auto-purge on next read.
4. `NotificationCoordinator.refreshForToday` excludes skipped blocks from scheduling.

### Manual verification
1. Today row → swipe → tap "Skip today". Row dims + skip badge appears.
2. Pending notifications: open iOS Settings → personal-hygiene → that block's pending alert is gone.
3. Next calendar day: row appears un-skipped again.

---

## [T-032] — Notification snooze 5 min

**Module:** M2 · **Phase:** 1 · **Shipped in:** session 5 slice 10

### Cases (automated — `Tests/Unit/Services/NotificationActionHandlerTests.swift`)
1. `didReceive(snooze)` schedules a new notification via `UNTimeIntervalNotificationTrigger` with the configured interval.
2. `didReceive(markDone)` removes the original pending notification.
3. Default interval is 300s; reads `UserDefaults` override when present.

### Manual verification (real device)
1. Receive a routine notification → swipe-down → tap "Snooze 5 min".
2. ~5 min later a fresh alert with the same title fires.

---

## [T-033] — Notification thread grouping

**Module:** M2 · **Phase:** 1 · **Shipped in:** session 5 slice 11

### Cases (automated — `Tests/Unit/Services/NotificationFactoryTests.swift`)
1. Routine factory sets `threadIdentifier = "routine"`.
2. Medication factory sets `threadIdentifier = "medication"` + `categoryIdentifier = "medication"`.
3. Hydration factory sets `threadIdentifier = "hydration"`.
4. Milestone factory sets `threadIdentifier = "trip-milestone"`.

### Manual verification
1. Receive 3 routine alerts in a row → iOS groups them under one stack.
2. A medication alert appears in its own stack alongside routine alerts.

---

## [T-034] — WhatsNextIntent (Siri Shortcut)

**Module:** M1 · **Phase:** 1 · **Shipped in:** session 5 slice 12

### Cases (automated — `Tests/Unit/Services/WhatsNextIntentTests.swift`)
1. `perform()` returns the title + start time of the current block when one is active.
2. Returns the next block when none is active.
3. Returns a localized "no template" dialogue when no template is active.

### Manual verification (real device)
1. Hey Siri → "What's next?" → reads out current/next block.
2. Shortcuts app → personal-hygiene → "What's next?" → tap → result appears.

---

## [T-035] — iOS NextBlock home widget

**Module:** M1 · **Phase:** 1 · **Shipped in:** session 5 slice 13

### Cases (automated — `Tests/Unit/Services/NextBlockResolverTests.swift`)
1. With no template active → returns `.empty`.
2. With template + current block → returns `.now(block)`.
3. With template + only future blocks → returns `.next(block)`.
4. After last block of the day → returns `.empty` (no wrap to tomorrow).

### Manual verification (real device)
1. Add the NextBlock widget (small + medium families) to the home screen.
2. Verify the widget shows current block while one is active.
3. Verify the widget shows next block (with start time) otherwise.

---

## [T-036] — Trip cover photo

**Module:** M9 · **Phase:** 5 · **Shipped in:** session 5 slice 14

### Cases (automated — view-layer manual; persistence covered by SwiftData round-trip)
1. `Trip.coverPhotoData: Data?` uses `@Attribute(.externalStorage)`.
2. `CoverPhotoSection` re-encodes JPEG at 0.7 quality before persisting.

### Manual verification
1. Trip detail → Cover photo → pick from photo library.
2. Photo appears in the section. Save. Force-quit + relaunch → photo persists.
3. Tap "Remove" → photo gone, `coverPhotoData` becomes nil.

---

## [T-037] — Packing list

**Module:** M9 · **Phase:** 5 · **Shipped in:** session 5 slice 15

### Cases (automated — view-layer + `BackupServiceTests`)
1. `Trip.packingItems` is a `[PackingItem]` value-type array.
2. `BackupService` v1.1 round-trips packing items through JSON.
3. v1 backups (without `packingItems`) decode without error (optional field).

### Manual verification
1. Trip detail → Packing list → add "Passport". Toggle done. Add "Sunscreen".
2. Footer shows "1 of 2 packed".
3. Swipe-delete an item → it's gone.
4. Settings → Export backup → re-import on a clean state → packing items return.

---

## [T-038] — Hydration streak

**Module:** M5 · **Phase:** 3 · **Shipped in:** session 5 slice 16

### Cases (automated — `Tests/Unit/Services/HydrationComplianceTests.swift`)
1. `currentStreakDays(on:logs:goal:)` returns 0 when today's intake < goal.
2. Returns N for N consecutive past days each meeting the goal.
3. Streak breaks when any day in the chain falls below goal.

### Manual verification
1. Hydration tab → log enough water to meet today's goal → flame badge appears with "1".
2. Skip a day → flame disappears next time you check on a goal-met day.

---

## [T-039] — Housekeeping room filter

**Module:** M6 · **Phase:** 3 · **Shipped in:** session 5 slice 17

### Cases (automated — `Tests/Unit/ViewModels/HousekeepingListViewModelTests.swift`)
1. `RoomFilter.all` shows every task.
2. `RoomFilter.unsorted` shows tasks where `room == nil`.
3. `RoomFilter.named(value)` shows tasks with `task.room == value`.

### Manual verification
1. Housekeeping tab → assign a room to a task ("Kitchen").
2. Picker at top → "Kitchen" → only kitchen tasks visible.
3. Picker → "Unsorted" → only tasks without a room.
4. Picker → "All" → full list.

---

## [T-040] — Birthdays per-contact lead

**Module:** M7 · **Phase:** 3 · **Shipped in:** session 5 slice 18

### Cases (automated — `Tests/Unit/Services/BirthdayLeadStoreTests.swift`)
1. `daysBefore(for:)` returns the global default (7) when no override exists.
2. `setDaysBefore(_:for:)` persists per-contact overrides.
3. Reset removes the override.

### Manual verification
1. Birthdays tab → swipe a contact row → "Lead days" → set 30.
2. Verify pending notification fires 30 days before.
3. Other contacts unaffected.

---

## [T-041] — Scheduled focus windows

**Module:** M8 · **Phase:** 3 · **Shipped in:** session 5 slice 19

### Cases (automated — `Tests/Unit/Services/FocusScheduleTests.swift`)
1. `ScheduledFocusWindow.matches(weekday:)` honors selected weekdays.
2. `DeepFocusFilter.focusWindows(scheduledWindows:)` merges block-derived + schedule-derived windows.
3. Empty schedule → result equals block-derived windows alone.

### Manual verification
1. Settings → Deep Focus → add window: Mon-Fri, 09:00 → 12:00. Save.
2. During a Mon-Fri 10:00 → only critical (medication) notifications fire.
3. Outside the window → all notifications fire normally.

---

## [T-042] — VoiceOver natural-language time

**Module:** a11y · **Shipped in:** session 5 slice 20

### Cases (manual — VoiceOver only)
1. Today row time → VoiceOver reads "08 hours 30 minutes" instead of "08:30".
2. Trips list → arrow glyphs (→) are not spoken.
3. Block now-row time → VoiceOver speaks natural language.

### Manual verification
1. Settings → Accessibility → VoiceOver → On.
2. Open Today → tap a block row → VoiceOver pronounces the time naturally.
3. Open Trips → swipe across rows → arrow glyphs are silent.
