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

---

## [T-043] — Dependabot GH-Actions bumps

**Module:** ci · **Shipped in:** session 7 slice 1

### Manual verification
1. After push, open the dependabot PRs (#1, #2, #3) and confirm they auto-close.
2. CI run on `main` after the push completes green (no warning about deprecated action versions).

---

## [T-044] — LESSONS.md L002 (notification-identifier prefix scope)

**Module:** dev-process · **Shipped in:** session 7 slice 3

### Cases (automated — `Tests/Unit/Services/BlockSnoozeStoreTests.swift`)
1. `test_parse_recognizesAllKnownPrefixes` iterates `BlockSnoozeSource.allCases` and round-trips each.
2. Adding a new `BlockSnoozeSource` case without updating `BlockNotificationIdentifier.parseAny` fails the test.

---

## [T-045] — Birthdays editor Stepper a11y

**Module:** birthdays · **Shipped in:** session 7 slice 4

### Manual verification
1. Settings → Accessibility → VoiceOver → On.
2. Birthdays tab → swipe a contact → "Edit lead time".
3. Focus on the Stepper. VoiceOver should read "Birthdays lead time, 7 days before" (or similar) as a single element.
4. Swipe up/down on the Stepper changes the value; VoiceOver re-announces the new lead.

---

## [T-046] — Deep Focus schedule editor a11y

**Module:** deep-focus · **Shipped in:** session 7 slice 5

### Manual verification
1. Settings → Deep Focus → existing schedule row.
2. With VoiceOver on, the row reads as "<title>, from HH:MM to HH:MM, <weekday symbols>" combined into one element.
3. The arrow glyph between start/end times is not spoken.

---

## [T-047] — Document scanner / preview a11y

**Module:** vacation · **Shipped in:** session 7 slice 6

### Manual verification
1. Open a Trip → Documents → tap a PDF document.
2. With VoiceOver on, the preview reads "PDF document, N pages, <name>".
3. Image documents read "Scanned document image, <name>".
4. Loading state reads "Loading document".

---

## [T-048] — Dynamic Type AX5 round-2 smoke

**Module:** a11y · **Shipped in:** session 7 slice 7

### Cases (automated — `Tests/Unit/Snapshots/RenderSmokeTests.swift`)
1. `test_birthdaysView_render_atAccessibilityXXXL`
2. `test_focusScheduleView_render_atAccessibilityXXXL`
3. `test_settingsView_render_atAccessibilityXXXL`

### Manual verification
1. Settings → Accessibility → Display & Text Size → Larger Text → AX5.
2. Open Birthdays / Settings → Deep Focus / Settings — no truncation, every row scrollable.

---

## [T-049] — `BlockNotificationIdentifier.parseAny`

**Module:** notifications · **Shipped in:** session 7 slice 8

### Cases (automated — `Tests/Unit/Services/BlockSnoozeStoreTests.swift`)
1. Routine, hydration, milestone identifiers all parse.
2. Snooze re-fire (`...snooze.<ts>` suffix) parses to original kind.
3. Garbage / malformed UUID / malformed hydration index → nil.
4. Exhaustive `BlockSnoozeSource.allCases` round-trip (L002 guard).

---

## [T-050] — `SnoozeDurationStore` boundary table

**Module:** notifications · **Shipped in:** session 7 slice 9

### Cases (automated — `Tests/Unit/Services/NotificationActionHandlerTests.swift`)
1. Default = 5 min when unset.
2. 5 / 10 / 15 are accepted and round-tripped.
3. Out-of-range (0, negative, 99) is rejected, last valid value preserved.
4. `seconds()` matches `minutes() * 60` for each allowed value.

---

## [T-051] — `DeepFocusFilter.activeWindow`

**Module:** deep-focus · **Shipped in:** session 7 slice 10

### Cases (automated — `Tests/Unit/Services/DeepFocusFilterTests.swift`)
1. Scheduled window covers `now` → returned.
2. No overlap → nil.
3. Block-derived + scheduled both cover → block wins (insertion order).
4. Scheduled with mismatched weekday → nil.

---

## [T-052] — `HydrationCompliance.bestStreakDays` edges

**Module:** hydration · **Shipped in:** session 7 slice 11

### Cases (automated — `Tests/Unit/Services/HydrationComplianceTests.swift`)
1. Single uninterrupted run → best == current.
2. One-day miss in middle resets streak; best is the longer half.
3. No day meets goal → 0.

---

## [T-053] — Backup v1.1 → v1 downgrade safety

**Module:** backup · **Shipped in:** session 7 slice 12

### Cases (automated — `Tests/Unit/Services/BackupServiceTests.swift`)
1. Strip `packingItems` from a v1.1 export, re-decode, every v1-era field intact.

### Manual verification
1. Settings → Export backup → save the file.
2. Open the JSON in a text editor; confirm `packingItems` is present.
3. Settings → Import the same file → all data restored.

---

## [T-054] — `BlockSnoozeStore` cross-module

**Module:** notifications · **Shipped in:** session 7 slice 13

### Cases (automated — `Tests/Unit/Services/BlockSnoozeStoreTests.swift`)
1. Per-source isolation: hydration "1" doesn't trigger milestone "1".
2. Legacy routine UUID entry readable via new `(source: .routine)` API.
3. `markSnoozed(parsed:on:)` dispatches each `ParsedNotificationIdentifier` to the right key.

### Manual verification (real device)
1. Wait for a hydration notification → snooze 5 min → no badge appears in Today (because hydration badges aren't surfaced in Today row — by design).
2. Wait for a routine block notification → snooze → return to Today → badge appears on that row.

---

## [T-055] — `DeepFocusHomeWidget` app-group prep

**Module:** deep-focus · **Shipped in:** session 7 slice 14

### Manual verification (no entitlement yet)
1. Add Deep Focus widget to the home screen.
2. Confirm it shows the right state (active / upcoming / idle) — currently reads from `UserDefaults.standard` because the App Group entitlement isn't configured.

### Pending validation
- After paid Apple Developer Program lands and the App Group entitlement is added, `UserDefaultsFocusScheduleStore.appGroupOrStandard()` should switch to the suite. Verify with `defaults read group.com.tandori46001.personalhygiene`.

---

## [T-056] — `WhatsNextDialogBuilder` watch share

**Module:** intent · **Shipped in:** session 7 slice 15

### Cases (automated — `Tests/Unit/Services/WhatsNextDialogBuilderTests.swift`)
1. Existing tests still pass after the move to `App/Shared/Services/`.

### Manual verification (real device + Apple Watch)
1. With VoiceOver on the watch, focus the NextBlockComplication. The spoken label uses the same phrasing as the Siri intent ("<title> at HH:MM").

---

## [T-057] — Settings → What's New + Onboarding restart

**Module:** settings · **Shipped in:** session 7 slices 16, 20

### Manual verification
1. Settings → About → "What's new" → sheet opens with widget / Siri / notifications tips.
2. Settings → About → "Show onboarding again" → confirmation dialog → tap "Show again" → relaunch the app → onboarding wizard fires again.

---

## [T-058] — Today X-of-N tap-to-expand

**Module:** today · **Shipped in:** session 7 slice 17

### Manual verification
1. Today → tap the X-of-N progress card.
2. Sheet appears listing every block of today's template with a circle/check-fill indicator + start time.
3. With VoiceOver on, the summary card has a hint "Tap to see each block's status".

---

## [T-059] — Hydration goal presets

**Module:** hydration · **Shipped in:** session 7 slice 18

### Manual verification
1. Hydration tab → Goal section.
2. Three buttons: 2.0L / 2.5L / 3.0L. Tap one → Stepper jumps to that value, button becomes filled (borderedProminent), others stay outlined.
3. Tap the Stepper → custom value works as before.

---

## [T-060] — Trip itinerary text Share

**Module:** vacation · **Shipped in:** session 7 slice 19

### Manual verification (real device — UIActivityViewController)
1. Open a Trip → Itinerary → Generate.
2. Once the itinerary appears, the toolbar shows a Share icon (top right).
3. Tap → standard iOS share sheet opens with the itinerary as plain text. Try Mail or Notes; the destination receives the trip name + summary + day-by-day bullets.

---

## [T-061] — Onboarding restart confirmation

**Module:** onboarding · **Shipped in:** session 7 slice 20

### Manual verification
1. Settings → About → "Show onboarding again".
2. Confirmation dialog appears with title "Replay the welcome flow next launch?".
3. Tap "Show again" (destructive) → confirms; cancel discards.
4. Force-quit the app and relaunch → onboarding shows.

---

## [T-062] — `OnboardingFlagStore` reset

**Module:** onboarding · **Shipped in:** session 7 slice 20

### Cases (automated — `Tests/Unit/Services/OnboardingFlagStoreTests.swift`)
*(added in round 6 slice 14)*

---

## [T-063] — Real-device: notifications fire

**Module:** notifications · **Real-device only**

### Manual verification
1. Settings → grant notification permission.
2. Today → ensure today's template has a block starting in ~2 minutes.
3. Wait for the notification to arrive on the iPhone lock screen.
4. Tap-and-hold → buttons "Snooze 5 min" + "Mark done" appear.

---

## [T-064] — Real-device: snooze action with custom interval

**Module:** notifications · **Real-device only**

### Manual verification
1. Settings → Scheduling → Snooze duration → 10 min.
2. Trigger a block notification (T-063).
3. Tap-hold → "Snooze 10 min".
4. Wait 10 min → notification re-appears.
5. Open the app → Today row for that block shows the alarm badge (snoozed-once indicator).

---

## [T-065] — Real-device: mark-done removes pending duplicate

**Module:** notifications · **Real-device only**

### Manual verification
1. Trigger a block notification.
2. Tap-hold → "Mark done".
3. Open Settings → Diagnostics → Pending notifications (round 6 T-066).
4. Confirm the original block's identifier is no longer in the list.

---

## [T-066] — Real-device: PendingNotifications view

**Module:** diagnostics · **Shipped in:** session 8 slice 7

### Manual verification (real device)
1. Settings → Diagnostics → Pending notifications.
2. List shows every pending notification grouped by kind (routine / hydration / milestone).
3. Each row: identifier suffix, fire time, body. Pull-to-refresh re-reads the center.

---

## [T-067] — Real-device: VisionKit document scanner

**Module:** vacation · **Real-device only** (camera not in simulator)

### Manual verification
1. Open a Trip → Documents → "Scan document" button.
2. Native VisionKit scanner takes over; align a document → tap shutter.
3. After capture, metadata sheet asks for name + kind.
4. Save → document appears in the list; tap to preview shows PDF.

---

## [T-068] — Real-device: Photos picker for trip cover photo

**Module:** vacation · **Real-device only**

### Manual verification
1. Open a Trip → Cover photo section → "Choose photo".
2. PhotosPicker opens the system photo library.
3. Pick a portrait photo → cover image appears at 200 px height (slice 15 round 6 — bumped from 160).
4. "Remove" button replaces the cover with the empty state.

---

## [T-069] — Watch Today: snooze badge mirror

**Module:** watch · **Shipped in:** round 8 (session 10)

### Manual verification (real device, requires paired Apple Watch + iPhone)
1. iPhone: open Settings → Diagnostics → Dev tools → "Inject snooze badge on first block".
2. Open watch app → Today.
3. The first block of today's template shows the `alarm` blue glyph at the row trailing edge.
4. iPhone: Diagnostics → "Reset all dev stores".
5. Bring the watch back to active (raise wrist). Glyph disappears within ~1s — verifies scenePhase refresh wired in round 8.

---

## [T-070] — Watch complication: Deep Focus moon glyph

**Module:** watch · **Shipped in:** round 7 / verified on-device round 8

### Manual verification
1. iPhone: Settings → Scheduling → Deep Focus → schedule a focus window covering "now".
2. Add the `NextBlock` watch complication to a watch face.
3. The glyph next to the title shows `moon.zzz.fill` in purple instead of the default bell.
4. End the focus window (or wait it out). Within the next system timeline refresh, the moon clears.

---

## [T-071] — Watch standalone install + cold launch

**Module:** watch · **Shipped in:** round 7 wrap (session 9)

### Manual verification
1. From CLI: `./scripts/deploy-watch.sh --clean`.
2. Watch boots into the app via `xcrun devicectl process launch`.
3. Force-quit (long-press Digital Crown → close), then launch again from the watch app drawer (no iPhone required).
4. App opens, today list renders, no missing-bundle errors. Standalone confirms `WKWatchOnly: true`.

---

## [T-072] — Medication follow-up at +30min

**Module:** medication · **Shipped in:** round 7 (Tier E)

### Manual verification (real device)
1. iPhone: pick a template with at least one `medication` block.
2. Settings → Diagnostics → Pending notifications.
3. Each medication block has TWO entries: the primary at the lead time + a `personal-hygiene.medication.followup.*` entry +30 min after the primary trigger date.
4. Snooze the primary from the lock screen → re-fire shape preserved (round 8 hardened the matching via `parseAny`).

---

## [T-073] — Diagnostics: Recently delivered panel

**Module:** diagnostics · **Shipped in:** round 8 (Tier B)

### Manual verification (real device, needs ≥1 delivered notification in the last 24h)
1. Settings → Diagnostics → "Recently delivered (N)" link.
2. Panel groups every notification fired in the last 24h by source: routine / hydration / milestone / medication follow-up / unknown.
3. Each row: title, body (2-line cap), delivered timestamp, identifier suffix.
4. Pull-to-refresh re-reads `UNUserNotificationCenter.deliveredNotifications`.

---

## [T-074] — Hydration undo toast on swipe-to-delete

**Module:** hydration · **Shipped in:** round 8 (Tier D)

### Manual verification
1. Hydration tab → log a quick 250ml.
2. Swipe-to-delete the row.
3. Undo toast appears at the top of the list with the deleted volume + an `Undo` button.
4. Tapping `Undo` restores the log with the original timestamp.
5. Letting the toast sit for 5s clears it automatically.

---

## [T-075] — Diagnostics: Replay last delivered notification

**Module:** diagnostics · **Shipped in:** round 9 (Tier B)

### Manual verification (real device, needs ≥1 delivered notification in the last 24h)
1. Trigger any test notification (e.g. T-064) and wait for it to fire.
2. Settings → Diagnostics → "Replay last delivered" button.
3. Within ~5s a copy of the most-recent delivered notification fires (same title + body + sound).
4. The dev-action footer reads "Replayed: <title>".
5. If no delivered notifications exist (post-reset / fresh install), the footer reads "No recent delivered notifications".

---

## [T-076] — Diagnostics: Schedule medication test (60s + follow-up at 90s)

**Module:** diagnostics · **Shipped in:** round 9 (Tier B)

### Manual verification (real device, notifications authorized)
1. Settings → Diagnostics → "Schedule medication test" button.
2. Pending count increments by 2 immediately.
3. After 60s the primary medication-shaped notification fires (long-press shows Snooze + Mark Done actions).
4. After another 30s the follow-up notification fires.
5. Marking the primary as done before the follow-up fires does NOT cancel the follow-up — it's a real M3.2 fallback test.

---

## [T-077] — Today: live "now" line between schedule rows

**Module:** today · **Shipped in:** round 9 (Tier D)

### Manual verification
1. Today tab with an active template covering the current hour.
2. Scroll to the schedule list.
3. A red horizontal divider with "Now · HH:MM" caption appears between the last-passed block and the next-upcoming block.
4. Background or close + reopen the app → the line repositions to the new current minute (refreshes on `scenePhase == .active`).
5. Outside the schedule's first/last block the line is hidden.

---

## [T-078] — Templates: drag-to-reorder blocks within an editor

**Module:** templates · **Shipped in:** round 9 (Tier D)

### Manual verification
1. Templates tab → tap any template → editor.
2. Tap "Edit" in the toolbar → drag handles appear next to each block row.
3. Drag block A from slot 1 to slot 3.
4. After release, block A's start time = original slot-3 start time; the previous slot-3 occupant moves into slot 1.
5. Each block's `durationMinutes` stays attached to the block (not the slot).
6. Pull-to-refresh / re-open the editor → the new order persists.

---

## [T-079] — Hydration: weekly 7-day bar chart

**Module:** hydration · **Shipped in:** round 9 (Tier D)

### Manual verification
1. Hydration tab → scroll to "Weekly" section.
2. 7 vertical bars, oldest day on the left, today on the right (narrow weekday letter axis).
3. Days that met the goal render green; days under goal render blue.
4. Dashed orange horizontal rule across the chart represents the goal.
5. Days with no logs render flat (zero) — chart stays dense.

---

## [T-080] — Watch: BlockDetail + Settings glance + reschedule-today

**Module:** watch · **Shipped in:** round 9 (Tier E)

### Manual verification (Apple Watch on wrist, app installed)
1. Open the watch app → Today list shows current schedule.
2. Tap any non-current row → BlockDetailWatchView pushes with title + category + time + duration.
3. "Mark done" button toggles completion + dismisses the detail. Watch widget timeline reloads (NextBlock complication updates within seconds).
4. "Skip today" button → row picks up the orange skip badge after dismiss.
5. Scroll to bottom of Today list → tap "Settings" row → SettingsGlanceWatchView shows snooze duration + notification auth status + build descriptor.
6. iPhone side: Settings → Scheduling → "Shift today by ±N min" stepper → "Reschedule today" button → all today's pending notifications shift by N minutes (verify via Diagnostics → Pending notifications panel).

## [T-081] — Diagnostics: Schedule-health + Refreshes + Observability sections (round 10)

**Module:** settings/diagnostics · **Shipped in:** round 10 (Tier B)

### Manual verification (iPhone, real device)
1. Settings → Diagnostics. Below the Notifications section the new sections appear in order: **Schedule health**, **Recent refreshes**, **Observability**.
2. Pull-to-refresh. **Schedule health** shows Expected, Pending, and a Diff row that reads `✓` when they match, otherwise `Δ N`.
3. Trigger a refresh (Settings → Refresh notifications). Re-open Diagnostics → **Recent refreshes** lists the just-fired entry at the top with timestamp + count.
4. Trigger reschedule-today (Settings → Reschedule today after Apply shift in the confirmation). Diagnostics shows a `↔` icon for that entry.
5. **Observability** shows: Widget reloads (a non-zero number after marking a block done from a notification action), Medication observer available `—` (entitlement gated), Registered concepts `0` (until medication blocks define `medicationConceptIdentifier`s), Trip documents stored `N`.

## [T-082] — Today summary: Done-for-today caption when day is complete (round 10)

**Module:** today · **Shipped in:** round 10 (Tier C)

### Manual verification
1. Open Today on a day where every scheduled block has already started + been marked done (or is past `endMinutesFromMidnight`).
2. Today summary row shows "Done for today 🎉" caption in place of the next-block preview.
3. Marking a block undone → caption flips back to the next-block preview.

## [T-083] — Settings: Reschedule confirmation + toast (round 10)

**Module:** settings · **Shipped in:** round 10 (Tier C)

### Manual verification
1. Settings → Scheduling. Set the shift to ±60 min. Tap "Reschedule today".
2. Confirmation dialog appears with the shift value spelled out + Apply / Cancel actions. Cancel → no change.
3. Tap "Reschedule today" → Apply shift. After completion a green-checkmark toast appears reading "N notifications rescheduled" with a dismiss `✕` button.
4. Tap dismiss → toast hides. Diagnostics → Recent refreshes shows the corresponding `↔` entry.

## [T-084] — Settings: Medication follow-up delay picker (round 10)

**Module:** settings/medication · **Shipped in:** round 10 (Tier F)

### Manual verification
1. Settings → Scheduling → "Medication follow-up delay" picker shows 15 / 30 / 45 / 60 min options.
2. Pick 45 → Settings → Refresh notifications → Diagnostics → Pending notifications: every medication follow-up is +45 min after its primary (was +30 min on default).
3. Switch back to 30 → next refresh restores the 30-min spacing.

## [T-085] — Trips: Countdown badge + duplicate swipe (round 10)

**Module:** trips · **Shipped in:** round 10 (Tier G)

### Manual verification
1. Trips tab → upcoming section shows a small "in N d" / "today" / "underway" badge next to the *closest* upcoming trip's name. Other rows have no badge.
2. Swipe a trip row from the leading edge → "Duplicate" action (blue chevron). Tap → a new "Copy of <name>" trip appears in the same section, packing items reset to unpacked, milestones cloned but incomplete.

## [T-086] — Trips: PDF export with cover photo (round 10)

**Module:** trips · **Shipped in:** round 10 (Tier G)

### Manual verification
1. Trip detail → set a cover photo via the picker (or use one already set).
2. Tap the share icon (top right) → PDF preview opens. The cover page now starts with the cover photo as a full-bleed banner above the title block.
3. Trips without a cover photo still produce a PDF — the title sits at the top, no banner.

## [T-087] — Currencies: Quick-pick chips for 7 codes (round 10)

**Module:** trips/currency · **Shipped in:** round 10 (Extra 1)

### Manual verification
1. Trip detail → Currency. Above each text field (From, To) a horizontal scroll of chip buttons appears: USD · EUR · GBP · CAD · CHF · AUD · JPY.
2. Currently-selected chip is filled (.borderedProminent); others are bordered.
3. Tap CAD chip on To → text field updates to "CAD". Convert button stays enabled. Conversion succeeds (Frankfurter / ECB supports all 7).
4. Repeat for GBP / CHF / AUD / JPY.

## [T-088] — Travel advisory: Multi-source list (round 10)

**Module:** trips/advisory · **Shipped in:** round 10 (Extra 2)

### Manual verification
1. Trip detail → "Travel advisory" navigation row.
2. The advisory screen shows "Sources" section with 4 rows in this order: exteriores.gob.es · travel.state.gov · travel.gc.ca · gov.uk · FCDO.
3. Each row's host appears as a caption underneath the source label.
4. Tap any row → Safari opens the corresponding country page (or search results page when the slug doesn't match).

## [T-089] — Today summary: counter no longer exceeds total (round 10)

**Module:** today · **Shipped in:** round 10 (Tier A)

### Manual verification
1. Mark all blocks of today's template as done.
2. Edit the active template → delete one of those blocks → Save.
3. Return to Today. Summary row shows `N-1 / N-1` (not `N / N-1`). Progress bar caps at 100% / 1.0.

## [T-090] — Diagnostics: process-crash detection in `check-tests.sh` (round 10)

**Module:** scripts · **Shipped in:** round 10 (Tier A, L005)

### Verification (developer machine)
1. Inject an artificial process crash in any test class (e.g. `precondition(false)` in a `setUp`).
2. Run `./scripts/check-tests.sh`.
3. Script must exit non-zero AND print "==> N test-process crash(es) detected (signal trap / unexpected exit) … See L005 in LESSONS.md."
4. Remove the injected crash. Re-run → script returns zero.

## [T-091] — Trips: search bar appears at 5+ trips (round 11)

**Module:** trips · **Shipped in:** round 11 (Tier B)

### Manual verification (iPhone)
1. With 4 or fewer trips: Trips tab does NOT show a search bar at the top.
2. Add a 5th trip → search bar appears at the top of the list.
3. Type a query that matches a trip name OR destination → list filters live, case-insensitive.
4. Clear the query → all trips return.

## [T-092] — Trips: duplicate-with-name confirmation alert (round 11)

**Module:** trips · **Shipped in:** round 11 (Tier B)

### Manual verification
1. Swipe a trip from the leading edge → tap "Duplicate" → an alert appears with a TextField pre-filled "Copy of <name>".
2. Edit the name (or leave default) → tap Duplicate → a new trip appears with that name. Packing items reset to unpacked, milestones cloned but incomplete.
3. Tap Cancel → no duplicate created.

## [T-093] — Currency: "Convert to all 7" + recent conversions (round 11)

**Module:** trips/currency · **Shipped in:** round 11 (Tier A)

### Manual verification
1. Trip detail → Currency. Enter 100, From=EUR. Tap "Convert to all 7" → a section "All rates" lists USD/GBP/CAD/CHF/AUD/JPY converted amounts (one network round-trip).
2. Tap regular Convert (single from→to) → the conversion appears under "Recent" with timestamp.
3. Repeat with different amounts/pairs → up to 5 most recent appear, dedupe by `(from, to, amount)`.
4. Tap a recent row → the form re-fills with that amount/from/to.
5. Tap "Clear recent" → list empties.

## [T-094] — Diagnostics: snapshot export + uptime + Advanced disclosure (round 11)

**Module:** settings/diagnostics · **Shipped in:** round 11 (Tier C)

### Manual verification
1. Settings → Diagnostics. The new "Recent refreshes / Schedule health / Observability / Snapshot export" sections live under a single "Advanced" disclosure (collapsed by default).
2. Above it, the new "Uptime" section shows launch timestamp + elapsed time (e.g. "12m 34s").
3. Expand Advanced → tap "Export diagnostics snapshot" → a share sheet opens with a `personal-hygiene-diagnostics-<ts>.json` file. Save to Files → opens as readable JSON containing build, refresh trace, pending notification identifiers (no titles/bodies).
4. Schedule health Δ now reads `✓` when only routine notifications are scheduled (not inflated by trip milestones).

## [T-095] — Today: block detail sheet + "in N min" + compact mode (round 11)

**Module:** today · **Shipped in:** round 11 (Tier D)

### Manual verification
1. Tap on any block in the schedule list → a bottom-sheet (medium detent) opens with start, duration, category, focus indicator, and (if a medication concept is set) the concept identifier as selectable text.
2. Sheet's "Mark done" / "Skip today" buttons act on the block + dismiss.
3. The "Next" row at the top of the schedule shows a colored caption like "in 12 min" / "in 1h 30 min" / "starting now".
4. Top-right toolbar has a list-icon toggle. Tap → schedule rows hide category dot, category text, and duration min. Tap again → restored. State persists across launches.

## [T-096] — Diagnostics: pending-by-category breakdown (round 12)

**Module:** settings/diagnostics · **Shipped in:** round 12 (Tier A)

### Manual verification
1. Settings → Diagnostics → expand Advanced. New "Pending by category" disclosure shows a per-prefix count (Routine / Medication follow-up / Hydration / Trip milestones / Housekeeping / Other).
2. The total at the right matches `pending` from the Schedule-health section.
3. Schedule a Trip with a milestone in the past → the milestones row goes up by one without inflating the routine drift.

## [T-097] — Today: context menu + filter chips + reset day + pull-to-refresh (round 12)

**Module:** today · **Shipped in:** round 12 (Tier D)

### Manual verification
1. Long-press a block row → context menu shows Mark done, Skip today, Details. All three commit + dismiss the menu.
2. Above the schedule there's a horizontal chip row. Default is "All" highlighted. Tap a category chip → schedule filters to blocks in that category. Tap "All" → restored.
3. Top-right toolbar `…` menu → Reset day. Confirms via dialog → completions + skips for today disappear; the schedule itself stays put.
4. Pull the schedule list down → "Refreshed" toast appears for ~1.5s, schedule is reloaded.

## [T-098] — Settings: pause notifications + theme + per-category mute (round 12)

**Module:** settings · **Shipped in:** round 12 (Tier D)

### Manual verification
1. Settings → "Pause notifications" → "Pause for…" → choose "1 hour". The section now shows "Paused until HH:MM" + a Resume button.
2. While paused, run `Refresh notifications`. Pending count drops to 0 in Diagnostics.
3. Tap Resume. Refresh notifications again — pending count climbs back up.
4. Settings → Appearance → Theme. Toggle Light / Dark / System. The whole app honors the override across navigation.
5. Settings → Notification categories → toggle Hydration off. New hydration notifications stop being scheduled.

## [T-099] — Trips: notes + completion bar + archive + packing categories (round 12)

**Module:** trips · **Shipped in:** round 12 (Tier B)

### Manual verification
1. Open a trip with at least one packing item + one milestone. The new "Trip readiness" card at the top shows a percentage that updates as items get checked.
2. Scroll to the "Notes" section. Type some Markdown (`**bold** [link](https://example.com)`) — after saving, the rendered version appears below the field.
3. The Trip detail toolbar `…` menu shows "Share" and (if the trip is still active) "Archive trip". Tap Archive → confirm. The trip moves to the Past Trips section.
4. Trip detail Packing list now shows category filter chips (All / Clothing / Electronics / Documents / Toiletries / Medication / Other). Add a new item with the Picker set to a category — it appears with the category icon.
5. The TripsListView row shows a `packed/total` badge for any trip with a packing list (e.g. `🧳 3/12`).

## [T-100] — Hydration: hot weather mode + Birthdays re-sync + Focus right now (round 12)

**Module:** hydration / birthdays / settings · **Shipped in:** round 12 (Tier E)

### Manual verification
1. Hydration → Goal section. Toggle "Hot weather mode" on → an orange "Effective goal: 2500 ml" caption appears. Progress recalculates against the bumped goal.
2. Birthdays → tap "Re-sync from Contacts" — even if the system permission was already granted, the list reloads. Each row shows a "Reminder on Mon, Apr 27" caption from the per-contact lead days.
3. Settings → Focus schedule → top "Focus right now (60 min)" — taps creates a one-day window starting at the current time. Returning to the list shows the new window.
4. Add an overlapping window on the same day → a yellow warning section appears at the top.

## [T-101] — Trip notes paragraphs render separately (round 13)

**Module:** trips · **Shipped in:** round 13 (Tier A)

### Manual verification
1. Open any trip · Notes section. Type "First paragraph." then a blank line then "Second paragraph.".
2. Save. The rendered area below shows two separate Text rows, not a single squashed paragraph.

## [T-102] — Trip Markdown share + cost log (round 13)

**Module:** trips · **Shipped in:** round 13 (Tier B)

### Manual verification
1. Open trip detail · `…` menu → "Share as Markdown" → share sheet shows a `.md` file with title, dates, milestones, packing, notes, expenses.
2. Add an expense via the new "Expenses" section (label "Hotel", amount "120", currency "USD"). It appears in the list with a per-entry currency badge.
3. Swipe a row trailing → Delete.

## [T-103] — Diagnostics: snapshot history + auth timeline + network activity (round 13)

**Module:** settings/diagnostics · **Shipped in:** round 13 (Tier C)

### Manual verification
1. Settings → Diagnostics → Advanced → tap "Export diagnostics snapshot" twice. The new "Snapshot history" disclosure shows both runs.
2. The "Auth timeline" section lists status changes since the last reset.
3. Tap any view that hits the network (Currency convert, marine forecast). The "Network activity" section count for that source goes up by 1.

## [T-104] — Today: hide completed blocks + minute-tick caption (round 13)

**Module:** today · **Shipped in:** round 13 (Tiers A + D)

### Manual verification
1. Today menu → "Hide completed blocks" → schedule rows you've checked disappear; toggle again → restored.
2. The "Next" row caption ("in N min") updates without forcing a reload after waiting >60s on the foreground.

## [T-105] — Bedtime auto-mute (round 13)

**Module:** notifications · **Shipped in:** round 13 (Tier F)

### Manual verification
1. Settings → Notification categories → enable "Bedtime auto-mute".
2. With a sleep block defined in the active template, refresh notifications → hydration reminders that would fire inside the sleep window (±15 min buffer) are not scheduled. Medication primaries + follow-ups remain regardless.

## [T-106] — Trip emergency contacts + per-currency expense totals (round 14)

**Module:** trips · **Shipped in:** round 14

### Manual verification
1. Open trip detail → scroll to "Emergency contacts". Add (label "Embassy", phone "+1 555 1234"). Long-press the phone → copy works.
2. Swipe a contact left → Delete confirms.
3. In the Expenses section, add 2+ expenses with mixed currencies (USD 100 hotel, EUR 30 cab). After the second, a per-currency "Total" row appears for each currency.

## [T-107] — Quiet hours store + bedtime auto-mute interplay (round 14)

**Module:** notifications · **Shipped in:** round 14

### Manual verification
1. Settings → Notification categories → enable Bedtime auto-mute (round 13 wire).
2. (Quiet hours UI is deferred to round 17 — store works but no toggle yet.) Verify via Diagnostics that medication notifications still fire even with bedtime mute on; hydration ones inside the sleep window don't.

## [T-108] — Template duration footer + milestone bundle one-tap (round 15)

**Module:** templates / trips · **Shipped in:** round 15

### Manual verification
1. Templates → open any template with blocks. Footer reads "Total: Xh Ym · N blocks" and updates as you add/remove.
2. Open a trip with no milestones. Empty state shows "Add 6m / 3m / 1m / 1w defaults" button. Tap once → 4 milestones appear (180/90/30/7 days). Tap again → idempotent, no duplicates.

## [T-109] — Hydration weekly average caption (round 15)

**Module:** hydration · **Shipped in:** round 15

### Manual verification
1. Hydration tab → with at least 1 day of logged data in the trailing 7 days, a "Weekly average: X ml/day" caption appears below the chart (rounded to nearest 10 ml).
2. With zero data → caption is hidden.

## [T-110] — Birthdays relationship filter chips (round 15)

**Module:** birthdays · **Shipped in:** round 15

### Manual verification
1. Birthdays tab → above the contact list, chip row shows All / Family / Friends / Coworkers / Other.
2. Tap a chip → list filters to contacts with that relationship tag (set via the lead-edit sheet — round 13 store).
3. "All" restores the full list.

## [T-111] — Medication dose history view (round 16)

**Module:** medication · **Shipped in:** round 16

### Manual verification
1. Mark a medication block as done from Today.
2. (Round 17 will add a NavigationLink from MedicationView → DoseHistoryView.) The list shows the dose with title + concept identifier (text-selectable, truncate-middle) + completion timestamp.
3. Empty state appears when no doses recorded in last 30 days.

## [T-112] — Trip carbon footprint section (round 16)

**Module:** trips · **Shipped in:** round 16

### Manual verification
1. Settings → Home location: set lat/lon (e.g., Madrid 40.4168, -3.7038).
2. Open a trip whose destination is geocoded (lat + lon set). The "Estimated round-trip CO₂" section appears at the top with a kg figure (e.g., Tokyo round-trip ~5,500 kg).
3. Open a trip without geocode → section is hidden silently.
4. Footer reads "Rough economy-class average. Set home location in Settings."

## [T-113] — Housekeeping room icons store (round 16)

**Module:** housekeeping · **Shipped in:** round 16

### Manual verification
1. (UI picker deferred to round 17.) Verify the store works via Diagnostics or UserDefaults — palette has 8 SF Symbols (bedroom / kitchen / bathroom / living / laundry / storage / house / outdoor).

## [T-114] — Focus filter preview helper (round 16)

**Module:** focus · **Shipped in:** round 16

### Manual verification
1. (UI surface deferred to round 17.) Helper is unit-tested. Once round-17 UI lands, it'll show "Currently silenced: X blocks" while a Focus window is active.

## [T-115] — Snapshot history + auth timeline + network activity (round 13 surfaces, validation pending)

**Module:** settings/diagnostics · **Shipped in:** round 13

### Manual verification
1. Settings → Diagnostics → Advanced → expand. Tap "Export diagnostics snapshot" twice → "Snapshot history" disclosure shows 2 entries with build SHA + pending count + widget reload count.
2. Toggle notification permission off in iOS Settings, back to app → "Auth timeline" section shows the change with timestamp.
3. Use Currency convert (with network) → "Network activity" section count for `frankfurter` goes up by 1. Cache hits don't increment.

## [T-116] — Medication tab → DoseHistoryView NavigationLink (round 17 wire)

**Module:** medication · **Shipped in:** round 17

### Manual verification
1. Open Medication tab while at least one block has `medicationConceptIdentifier` set. Below the 7-day compliance section, a "Dose history" row appears.
2. Tap the row → DoseHistoryView pushes onto the stack and lists every medication-only completion from the last 30 days, newest first. Concept identifiers truncate-middle and are text-selectable.
3. With no medication completions in 30 days, the empty state ("No dose recorded yet") renders instead of an empty list.

## [T-117] — TemplateEditor → "Insert preset bundle" menu (round 17 wire)

**Module:** routine · **Shipped in:** round 17

### Manual verification
1. Templates → open or create a template. In the blocks section, the "Insert preset bundle" menu sits below "Add block".
2. Tap "Workday" on a template whose last block ends before 9:00 → 3 blocks (Deep work / Stand-up / Lunch) append at 9:00 / 10:30 / 13:00.
3. Tap "Morning routine" on a template whose last block ends at 10:30 → 3 blocks (Wake up / Brush + shower / Breakfast) append shifted by `(10:30 − 7:00) = 3h 30min`, so first inserted block sits at 10:30, preserving 10/20-min spacing.
4. Inserted blocks survive a kill-launch cycle (SwiftData persistence).

## [T-118] — FocusScheduleView "Right now" preview (round 17 wire)

**Module:** focus/settings · **Shipped in:** round 17

### Manual verification
1. Settings → Focus → at least one window covering the current minute, with at least one deep-focus block + one non-deep-focus block in the active template scheduled inside that window.
2. The "Right now" section appears at the top with the active block's title + a "X silenced" caption matching `FocusFilterPreview.preview(...)`.
3. Outside any active focus window: section is hidden entirely.
4. With no `routineRepository` (e.g. directly previewed), section stays hidden — `blocksProvider` returns empty.

## [T-119] — Settings → Quiet hours section (round 17 wire)

**Module:** settings · **Shipped in:** round 17

### Manual verification
1. Settings → Quiet hours section: toggle off → only the toggle row + footer.
2. Toggle on → start (default 22:00) + end (default 07:00) DatePickers appear. Edit each — values persist across kill-launch.
3. Footer reads "Suppresses non-medication notifications during this window every day." Medication still fires.

## [T-120] — Settings → Backup schedule picker (round 17 wire)

**Module:** settings/backup · **Shipped in:** round 17

### Manual verification
1. Settings → Backup schedule section (below Backup actions): picker with Off / Weekly / Daily.
2. Pick a value → reopen Settings → value persists.
3. Footer notes the auto-backup engine is future-phase. (No actual backup runs yet — this only stores intent.)

## [T-121] — Diagnostics → Pending IDs by group disclosure (round 17 wire)

**Module:** settings/diagnostics · **Shipped in:** round 17

### Manual verification
1. Settings → Diagnostics → Advanced → expand. Below "Pending IDs" disclosure, a new "Pending IDs by group" disclosure renders with total count.
2. Expand → one sub-disclosure per non-empty category (Routine / Medication follow-up / Hydration / Trip milestones / Housekeeping / Other) with each category's identifier list.
3. With zero pending requests, the section is hidden entirely.

## [T-122] — Housekeeping → Room icon picker (round 17 wire)

**Module:** housekeeping · **Shipped in:** round 17

### Manual verification
1. Housekeeping tab → tap +. Sheet opens. Type a title.
2. Pick or type a room → "Room icon" picker appears below. Choose any of the 8 icons → row icon updates in the picker.
3. Save → row in the list shows the chosen SF Symbol next to the room name.
4. Re-open the new-task sheet, type the same room name → the picker auto-loads the previously-chosen icon (round-trip via `HousekeepingRoomIconStore`).

## [T-123] — Today: stale-day banner on time-zone change (round 18)

**Module:** today · **Shipped in:** round 18

### Manual verification
1. Settings → General → Date & Time → toggle off "Set Automatically" → change time zone manually. Return to the app.
2. Today tab shows a tap-to-dismiss banner "Day boundary shifted · Time zone changed — Today recalculated."
3. Tap the row → banner disappears.

## [T-124] — TemplateEditor: block conflict chip (round 18)

**Module:** routine · **Shipped in:** round 18

### Manual verification
1. Templates → editor → create two blocks whose time windows overlap (e.g. 09:00 + 30 min and 09:15 + 30 min).
2. Both rows render an orange triangle next to the title. Touching boundaries (09:00–09:30 + 09:30–10:00) do NOT trigger the chip.

## [T-125] — TemplateList: summary chip (round 18)

**Module:** routine · **Shipped in:** round 18

### Manual verification
1. Templates list → each non-empty template row shows a tertiary monospaced caption "HH:MM–HH:MM · N · Xh".

## [T-126] — TemplateEditor: undo preset insertion (round 18)

**Module:** routine · **Shipped in:** round 18

### Manual verification
1. Templates → editor → "Insert preset bundle" → pick any preset.
2. A row appears below "Insert preset bundle" with "Preset inserted · Undo" within 4 seconds.
3. Tap "Undo" → the inserted blocks disappear and the row collapses.
4. Wait 4 seconds without tapping → the row auto-dismisses (insertions stay).

## [T-127] — DoseHistoryView: pull-to-refresh + filter chips (round 18)

**Module:** medication · **Shipped in:** round 18

### Manual verification
1. Medication → Dose history → pull down to refresh. List re-fetches.
2. Chip row at top: tap a concept ID chip → only entries for that ID are shown. "All" clears the filter.

## [T-128] — Today: skip this dose (round 18)

**Module:** today/medication · **Shipped in:** round 18

### Manual verification
1. Today → tap a medication block → BlockDetailSheet opens.
2. New "Skip this dose" button visible (only for blocks with a medication concept identifier, only when the block is not already done).
3. Tap → block marked as skipped today; the medication-followup notification for today is suppressed (verify in Diagnostics → Pending IDs).

## [T-129] — Medication: 30-day adherence row (round 18)

**Module:** medication · **Shipped in:** round 18

### Manual verification
1. Medication tab → below "Overall" row a "30-day adherence" row appears (only when the view-model has loaded the data).

## [T-130] — Trip emergency contacts: tap-to-call (round 18)

**Module:** trip · **Shipped in:** round 18

### Manual verification
1. Trips → open any trip → Emergency contacts section. Each row with a phone shows a green phone icon.
2. Tap → iOS dialer prompts to call the (sanitized) number.

## [T-131] — Trip expenses: monthly summary disclosure (round 18)

**Module:** trip · **Shipped in:** round 18

### Manual verification
1. Trips → open any trip with ≥1 expense → Expenses section now ends with a "Monthly summary" disclosure.
2. Expand → one row per `(year, month, currency)` with total + count.

## [T-132] — Trip carbon: kg/lb toggle (round 18)

**Module:** trip · **Shipped in:** round 18

### Manual verification
1. Trips → open trip with destination geocoded + home location set → Carbon section shows segmented kg/lb picker.
2. Switch to lb → value updates to `kg × 2.2046` rounded.
3. Switch back to kg → value reverts.

## [T-133] — Trip itinerary: copy as plain text (round 18)

**Module:** trip · **Shipped in:** round 18

### Manual verification
1. Trips → open trip → toolbar `…` menu → "Copy as plain text".
2. Paste into Notes / Messages → output is plain (no `**bold**`, no `[ ]` checkboxes; uses `✓` and `•` instead).

## [T-134] — Settings → Quiet hours reset (round 18)

**Module:** settings · **Shipped in:** round 18

### Manual verification
1. Settings → Quiet hours → enable + change times → tap "Reset to defaults".
2. Toggle is off, start/end revert to 22:00 / 07:00.

## [T-135] — Diagnostics: tap-to-copy identifier (round 18)

**Module:** settings/diagnostics · **Shipped in:** round 18

### Manual verification
1. Diagnostics → Advanced → Pending IDs by group → expand a category → tap any identifier row.
2. Identifier is copied to clipboard (verify with paste).

## [T-136] — Diagnostics: export pending CSV (round 18)

**Module:** settings/diagnostics · **Shipped in:** round 18

### Manual verification
1. Diagnostics → Advanced → "Export pending IDs (CSV)" → share sheet opens with a `.csv` file.
2. Open the CSV → header is `category,identifier,triggerDate`; one row per pending identifier.

## [T-137] — Diagnostics: one-pager PDF (round 18)

**Module:** settings/diagnostics · **Shipped in:** round 18

### Manual verification
1. Diagnostics → Advanced → "Export one-pager (PDF)" → share sheet opens with a single-page PDF.
2. Page contains: title, build descriptor, snapshot history (≤3), refresh trace (≤50), auth timeline (≤10).

## [T-138] — Housekeeping: change room icon (round 18)

**Module:** housekeeping · **Shipped in:** round 18

### Manual verification
1. Housekeeping → long-press a task whose room is set → "Change room icon" context menu item.
2. Tap → sheet with the 8 SF Symbol palette + "No icon" option. Save → row icon updates.

## [T-139] — Hydration: comeback nudge (round 18)

**Module:** hydration · **Shipped in:** round 18

### Manual verification
1. Don't log hydration for 3+ days. Open the Hydration tab.
2. Top of the list shows a red caption "X days since last log — drink up." X matches actual day delta.
3. Log water → the caption disappears on next reload (since `daysSinceLastLog` falls below 3).

## [T-140] — Birthdays: copy gift ideas (round 18)

**Module:** birthdays · **Shipped in:** round 18

### Manual verification
1. Birthdays → store a gift idea for any contact (via existing flow).
2. Long-press that contact's row → "Copy gift ideas" context menu item appears (and only for contacts with ideas).
3. Tap → idea is on the clipboard.

## [T-141…T-145] — Round 18 test infrastructure (no manual case)

The following slices ship purely automated artifacts and have no manual case:
- Slice 1: 4 new render-smoke tests in `RenderSmokeTests.swift` (covered by `./scripts/check-tests.sh`).
- Slice 2: 2 new DynamicType tests at `.accessibility5` (same).
- Slice 3: `scripts/check-i18n-coverage.sh` — covered by running the script.
- Slice 4: `scripts/check-localization-orphans.py` — covered by running the script.

## [T-146] — Round 19 L006 lint guard (no manual case)

**Module:** ci/scripts · **Shipped in:** round 19 (T1.1, T1.2, T1.3)

Three preventive guards now block the L006 SwiftUI-dynamic-key trap:
- SwiftLint custom rule `dynamic_localized_key` flags any `LocalizedStringKey("...\(...)")` as build error.
- `./scripts/check-localized-key-usage.py` — backup static scan.
- `./scripts/check-xcstrings-format-consistency.py` — verifies `%@`/`%lld` parity between xcstrings keys and call sites.

Verify by running each script — must exit 0.

## [T-147] — Notification: snooze 30-min action (round 19)

**Module:** notifications · **Shipped in:** round 19 (T2.5)

### Manual verification
1. Today → snooze-eligible block (any non-medication routine, hydration, or trip-milestone notification).
2. Long-press the live notification → category sheet shows two snooze actions: 5-min (default) + new 30-min.
3. Tap "Snooze 30 min" → notification re-fires ~30 minutes later.

## [T-148] — Notification: skip dose action (round 19)

**Module:** notifications/medication · **Shipped in:** round 19 (T2.9)

### Manual verification
1. Trigger any medication notification (Diagnostics → Dev tools → "Send medication test").
2. Long-press the notification → category sheet shows "Mark done" + "Skip this dose" (red/destructive).
3. Tap "Skip this dose" → pending follow-up is removed (Diagnostics → Pending IDs has no medication-followup for that block today).

## [T-149] — Watch: complication line 2 (round 19)

**Module:** watch · **Shipped in:** round 19 (T2.6)

### Manual verification
*Requires watch redeploy.*
1. Add the rectangular `NextBlockComplication` to a watch face.
2. Verify line 1 = start time, line 2 = block title, line 3 = category + duration (e.g. `hygiene · 30 min`).

## [T-150] — Watch: theme + pause mirror (round 19)

**Module:** watch · **Shipped in:** round 19 (T2.7, T2.8)

### Manual verification
*Requires App Group entitlement to function across devices; falls back to standalone watch defaults until the entitlement ships.*
1. iPhone → Settings → set theme override to "Dark". Watch should respect the same value (when App Group is wired).
2. iPhone → Settings → "Pause notifications for 1h". Watch glance → settings page now shows "Paused until HH:MM".

## [T-151] — Backup includes diagnostics snapshot (round 19)

**Module:** settings/backup · **Shipped in:** round 19 (T3.11)

### Manual verification
1. Diagnostics → "Capture snapshot" twice (so `SnapshotHistoryStore` has ≥1 entry).
2. Settings → Backup → Export. Open the JSON file.
3. Top-level `diagnostics` field present, equal to the most recent snapshot.

## [T-152] — Diagnostics: copy snapshot diff (round 19)

**Module:** settings/diagnostics · **Shipped in:** round 19 (T3.12)

### Manual verification
1. Diagnostics → capture two snapshots (history count ≥ 2).
2. Expand "Snapshot history" → tap "Copy diff (last vs prev)".
3. Paste into Notes — single-line summary like `pending: +2 · widget reloads: +1`.

## [T-153] — Settings: reset onboarding tips (round 19)

**Module:** settings · **Shipped in:** round 19 (T3.13)

### Manual verification
1. Settings → scroll to bottom → "Reset onboarding tips" (red/destructive row).
2. Tap → next launch should re-trigger the "What's New" sheet automatically.

## [T-154] — Settings: about footer (round 19)

**Module:** settings · **Shipped in:** round 19 (T3.14)

### Manual verification
1. Settings → bottom "About this build" section.
2. Row shows `vX.Y.Z (build N) — sha` + `locale en_GB · keys 704`.
3. Tap → entire string copied to clipboard.

## [T-155] — Trip carbon: transport mode picker (round 19)

**Module:** trip · **Shipped in:** round 19 (T4.16)

### Manual verification
1. Trips → trip with destination geocoded + home location set → Carbon section now shows a transport-mode picker (Flight / Ferry / Public transport / Car).
2. Switch to Public transport → kg drops to ~16% of the flight value.
3. Switch back to Flight → original value restored.

## [T-156] — Trip expenses: copy converted totals (round 19)

**Module:** trip · **Shipped in:** round 19 (T4.15)

### Manual verification
1. Add ≥2 expenses in different currencies. In Currency tab, perform a conversion (e.g. EUR→USD). LastConversion is now stored.
2. Trip detail → Expenses → tap "Copy converted totals".
3. Paste into Notes → multi-line summary with `≈ NN.NN USD` header + per-currency lines.

## [T-157] — Trips: duplicate to next year (round 19)

**Module:** trips · **Shipped in:** round 19 (T4.18)

### Manual verification
1. Trips → upcoming trip → swipe-leading edge.
2. Two buttons: "Duplicate" (existing) + new "Duplicate next year" (purple, calendar icon).
3. Tap → new trip appears with start/end date shifted by exactly one calendar year.

## [T-158] — Today: tomorrow disclosure (round 19)

**Module:** today · **Shipped in:** round 19 (T5.19)

### Manual verification
1. Today → scroll past the schedule → "Tomorrow" disclosure (sun icon).
2. Expand → list of tomorrow's blocks (based on tomorrow's day-type).
3. If today is a weekday and tomorrow is a weekend, weekend template's blocks are shown.

## [T-159] — Today: mood quick-log (round 19)

**Module:** today · **Shipped in:** round 19 (T5.20)

### Manual verification
1. Today → "How do you feel?" section — 5 emoji chips (😄 🙂 😐 🙁 😞).
2. Tap one → chip is highlighted (subtle accent background).
3. Re-tap a different mood → highlight moves; today's record updates.
4. Re-launch app → highlight persists for the day's most-recent selection.

## [T-160] — TemplateEditor + TemplateList enhancements (round 19)

**Module:** routine · **Shipped in:** round 19 (T5.21, T5.22)

### Manual verification
1. **Duplicate block:** TemplateEditor → long-press any block → context menu "Duplicate block". A clone appears immediately after the source (start time = source start + source duration).
2. **Category legend:** TemplateList → bottom of the list → "Category legend" disclosure. Expand → 12 category dots with their localized names.

## [T-161…T-166] — Round 20 regression guards (no manual case)

**Module:** ci/tests · **Shipped in:** round 20 (T1.2, T1.3, T1.4, T1.5, T1.6)

Five new test files + extended existing tests cover the round-20 guards:
- `RenderSmokeTestsRound20`: AdvisoryView, CurrencyView quick-pick, HydrationDashboard empty, plus AX5 versions for those + TemplateEditor.
- `BlockNotifIDRoundTripTests`: 1000-input random round-trip across the 4 known notification identifier shapes.
- `DiagnosticsPendingByGroupCSVTests`: header-no-trailing-newline + comma sanitization regressions.
- `MoodLogStoreTests`: capacity cap, today-entry filter, clear behavior.

Verify by running `./scripts/check-tests.sh`.

## [T-167] — Today: mood "good days this week" caption (round 20)

**Module:** today · **Shipped in:** round 20 (T2.7)

### Manual verification
1. Tap the 😄 or 🙂 emoji on Today's mood row at least once today.
2. A small centered caption appears below the chips: "X good days this week" (X = count in the trailing 7 days, dedup-counted by entry, 1 here).
3. Repeat tomorrow → caption rises to 2.

## [T-168] — Settings: mood log disclosure + clear + CSV (round 20)

**Module:** settings · **Shipped in:** round 20 (T2.8, T2.9, T2.11)

### Manual verification
1. Settings → "Mood log" disclosure → expand. Last 30 entries shown (timestamp + emoji).
2. Tap "Copy mood log (CSV)" → paste into Notes → header `recordedAt,mood` + one row per entry.
3. Tap "Clear mood log" (red) → list collapses to "No moods recorded yet."

## [T-169] — Backup includes mood log (round 20)

**Module:** settings/backup · **Shipped in:** round 20 (T2.10)

### Manual verification
1. Tap a few mood emojis. Settings → Backup → Export. Open the JSON.
2. Top-level `mood` array present with one entry per mood log row.
3. Restore on a fresh state (or via clearing mood log first) → mood entries reappear.

## [T-170] — Trips: past-trips year filter chips (round 20)

**Module:** trips · **Shipped in:** round 20 (T3.12)

### Manual verification
*Requires ≥2 past trips spanning ≥2 distinct years (use round-19 "Duplicate next year" then back-date a trip if needed.)*
1. Trips → past section → year chip row visible at the top: "All · YYYY · YYYY-1 · …".
2. Tap any year chip → list filters to trips with `startDate.year == chip`.
3. Tap "All" → filter clears.

## [T-171] — Currency: JPY promoted to 3rd preset (round 20)

**Module:** trip/currency · **Shipped in:** round 20 (T3.13)

### Manual verification
1. Currency tab → quick-pick row → 3rd chip is now JPY (was 7th).

## [T-172] — Itinerary day marker (round 20)

**Module:** trip/itinerary · **Shipped in:** round 20 (T3.14)

### Manual verification
1. Trips → trip with itinerary generated → each day-section header shows a relative-day marker (`T-3` countdown · `D+1` in-trip · `✈` on start day).
2. Day 0 of the trip with start date today → marker is `✈`.

## [T-173] — Trip notes "Insert template" menu (round 20)

**Module:** trip · **Shipped in:** round 20 (T3.15)

### Manual verification
1. Trips → notes section → tap "Insert template" → 3 options (Preparation / Day D / Return).
2. Each appends Markdown bullet list to existing draftNotes (separator = blank line).
3. Tap a second template → appends below; existing content not overwritten.

## [T-174] — TripCarbon factor caption (round 20)

**Module:** trip/carbon · **Shipped in:** round 20 (T3.16)

### Manual verification
1. Trips → trip with destination geocoded + home set → carbon section.
2. Below the mode picker, caption shows `0.255 kg CO₂ / passenger·km · DEFRA 2023` (flight default; updates per mode toggle).

## [T-175] — Today: tap "Now" hairline to scroll (round 20)

**Module:** today · **Shipped in:** round 20 (T4.17)

### Manual verification
1. Today → scroll the schedule away from "Now" hairline.
2. Tap the red "Now · HH:MM" line → list smooth-scrolls so the current block is centered.

## [T-176] — TemplateEditor: renumber start times (round 20)

**Module:** routine · **Shipped in:** round 20 (T4.18)

### Manual verification
1. TemplateEditor with ≥2 blocks → tap "Renumber start times".
2. Blocks now sit back-to-back from the original first start (gaps collapse to zero).

## [T-177] — Today: reset-day undo toast (round 20)

**Module:** today · **Shipped in:** round 20 (T4.19)

### Manual verification
1. Mark some blocks done. Today → "Reset day" → Confirm.
2. Bottom of screen shows "Day reset · Undo" capsule.
3. Tap "Undo" within 10s → all completions + skips restore.
4. Wait 10s → capsule disappears; further state changes can't be undone.

## [T-178] — BlockEditor: suggest from history (round 20)

**Module:** routine · **Shipped in:** round 20 (T4.20)

### Manual verification
1. Open BlockEditor with any category that has ≥1 prior block in any template.
2. "Suggest from history" Menu visible below the category picker.
3. Tap → shows up to 5 distinct titles for that category (most-recent first).
4. Pick one → fills the title field.

## [T-179] — Diagnostics refresh trace CSV (round 20)

**Module:** settings/diagnostics · **Shipped in:** round 20 (T5.21)

### Manual verification
1. Diagnostics → Advanced → "Export refresh trace (CSV)".
2. Share sheet opens with `refresh-trace-<ts>.csv`. Header `timestamp,scheduledCount,kind`; one row per RefreshTraceLog entry.
3. Disabled when refreshTrace is empty.

## [T-180] — Round 20 wrap-ups: everything bundle + WhatsNew confirm

**Module:** settings · **Shipped in:** round 20 (T5.22, T5.23)

### Manual verification
1. **Everything bundle:** Settings → "Copy everything bundle" → paste in Notes → multi-section text with build descriptor + locale + key counts + mood entries + diagnostics snapshot count + mood CSV.
2. **WhatsNew confirm-dismiss:** Open WhatsNewSheet (Settings → "What's new") → tap Done *without scrolling to bottom* → confirm dialog appears. Scroll to bottom → tap Done → dismisses immediately.

## [T-181] — BackupSnapshot v3 mood payload round-trip (round 21)

**Module:** settings · **Shipped in:** round 21 (T1.3)

### Manual verification
1. Log a couple of mood entries (Today → emoji row).
2. Settings → Export backup → save the JSON.
3. Settings → Mood log → "Clear mood log".
4. Settings → Import backup → pick the JSON.
5. Today: the cleared mood entries reappear (newest-first preserved).

## [T-182] — BlockTitleSuggestions guard (round 21)

**Module:** routine · **Shipped in:** round 21 (T1.4)

### Manual verification (smoke)
1. Test suite ran: `BlockTitleSuggestionsTests` 5 cases pass.
2. Change `BlockTitleSuggestions.recent(...)` cap value → tests must regress.

## [T-183] — Mood CSV format guard (round 21)

**Module:** settings · **Shipped in:** round 21 (T1.5)

### Manual verification
1. Settings → "Copy mood log (CSV)".
2. Paste in Notes → header `recordedAt,mood`; no trailing newline; ISO-8601 timestamps; newest first.

## [T-184] — TodayViewModel undoResetDay replay guard (round 21)

**Module:** today · **Shipped in:** round 21 (T1.6)

### Manual verification
1. Mark blocks done + skip a few.
2. Today → Reset day → Confirm.
3. Tap "Undo" → both completions and skips restore exactly.

## [T-185] — L006 scan covers watch target (round 21)

**Module:** ci · **Shipped in:** round 21 (T1.7)

### Manual verification
1. Run `python3 scripts/check-localized-key-usage.py`.
2. Last line lists each scanned target including `PersonalHygieneWatch` + `PersonalHygieneWatchWidgets`.
3. Delete one of the scanned dirs temporarily → script exits non-zero with "missing" message.

## [T-186] — Mood log 30-day Swift Charts trend (round 21)

**Module:** settings · **Shipped in:** round 21 (T2.8)

### Manual verification
1. Log moods across multiple days (or use BackupSnapshot to seed).
2. Settings → Mood log → "Mood trend (30 days)" section appears.
3. Line + point marks plot the daily average; Y-axis labels render emoji at scores 1/3/5.

## [T-187] — Today 7-day mood emoji strip (round 21)

**Module:** today · **Shipped in:** round 21 (T2.9)

### Manual verification
1. Log moods for several recent days.
2. Today → below the schedule a row shows 7 columns (one per day, oldest → today).
3. Days without entries render as a faint dot; days with entries show the rounded mood emoji.

## [T-188] — Mood log emoji filter (round 21)

**Module:** settings · **Shipped in:** round 21 (T2.10)

### Manual verification
1. Settings → Mood log disclosure → "Filter" picker (segmented, All / 5 emojis).
2. Pick an emoji → only entries matching that mood remain visible.
3. Pick All → list returns to full.

## [T-189] — Mood weekly goal store + caption (round 21)

**Module:** settings · **Shipped in:** round 21 (T2.11)

### Manual verification
1. Settings → Mood log → "Weekly goal" stepper (0…7).
2. Set to 3 → "X of 3 this week" caption appears.
3. Set back to 0 → caption disappears.

## [T-190] — Mood CSV header localized (round 21)

**Module:** settings · **Shipped in:** round 21 (T2.12)

### Manual verification
1. Switch device language to ES.
2. Settings → "Copy mood log (localized CSV)".
3. Paste → header is `registradoEn,ánimo`; data rows still use English mood codes.

## [T-191] — WeatherKit forecast bridge (round 21)

**Module:** vacation · **Shipped in:** round 21 (T3.13)

### Manual verification (offline)
1. Inject `StubWeatherForecastService` in unit tests → returns 5 canned forecasts.
2. WeatherKit entitlement still gated; `WeatherKitForecastService` compiles via `#if canImport(WeatherKit)`.

## [T-192] — Forecast cache 6h TTL (round 21)

**Module:** vacation · **Shipped in:** round 21 (T3.14)

### Manual verification
1. Test suite covers store + retrieve within TTL + expiry past TTL + 2dp coordinate rounding.
2. Live: a future build with WeatherKit entitlement should hit the cache twice in <6h before refetching.

## [T-193] — Itinerary day forecast chip (round 21)

**Module:** vacation · **Shipped in:** round 21 (T3.15)

### Manual verification
1. Generate an AI itinerary for a trip with destination geocoded.
2. Each day-section header now has a chip with `T-N`/`D+N`/`✈` marker + (when forecast available) high/low + rain-prob.
3. Days with rain ≥20% surface a blue droplet + percentage.

## [T-194] — Trip notes "Insert weather forecast" (round 21)

**Module:** vacation · **Shipped in:** round 21 (T3.16)

### Manual verification
1. Trip detail → Notes → "Insert template" Menu → "Weather forecast".
2. Markdown block appended with one line per forecast day, including rain tag when ≥30% chance.

## [T-195] — Settings 30-day footprint summary (round 21)

**Module:** settings · **Shipped in:** round 21 (T3.17)

### Manual verification
1. Settings → with at least one trip ending in the last 30 days + home location set → "30-day footprint" section shows Total kg/lb CO₂ + Trips counted.
2. Hidden when no eligible trips exist.

## [T-196] — Currency "Copy rates as table" (round 21)

**Module:** vacation · **Shipped in:** round 21 (T3.18)

### Manual verification
1. CurrencyView → "Convert all" → table renders.
2. New "Copy rates as table" button → paste in Notes → CSV table `base,target,rate,converted`.

## [T-197] — TemplateEditor conflict overlap visualizer (round 21)

**Module:** routine · **Shipped in:** round 21 (T4.19)

### Manual verification
1. TemplateEditor with two overlapping blocks (e.g. 9:00-60min + 9:30-60min).
2. New "Overlapping blocks" section shows "A ↔ B · 30 min" lines.
3. Adjust durations to remove overlap → section disappears.

## [T-198] — Watch surfaces (round 21)

**Module:** watch · **Shipped in:** round 21 (T5.25, T5.26, T5.27, T5.29)

### Manual verification (post-deploy)
1. Watch Today → bottom rows now include "Hydration" + "Mood" links.
2. Hydration glance → today total + "+150/+250/+330 ml" buttons → tap appends pending tap.
3. Mood quick-log → 5 emojis → tap → success haptic.
4. Mark a block done from watch → 3-second "Marked done · Undo" capsule appears.
5. Complication: with iPhone notifications paused → orange `pause.circle.fill` glyph next to the time.

## [T-199] — Birthdays gift idea CSV export (round 21)

**Module:** birthdays · **Shipped in:** round 21 (T6.31)

### Manual verification (smoke)
1. Test suite covers header, sorting, comma/quote escaping, empty dictionary.
2. Wire-up to settings UI deferred to round 22.

## [T-200] — Round 21 housekeeping bundle (round 21)

**Module:** various · **Shipped in:** round 21 (T6.30, T6.32, T6.34)

### Manual verification (smoke)
1. **HousekeepingStreakAutoSnooze**: pure helper covered by 4 tests; threshold 7d, scales to 7d cap.
2. **BirthdayLeadDefaultStore**: 0…60 clamp + fallback to legacy constant covered by 3 tests.
3. **FocusCategoryMuteMirror**: writes iOS-side mute state to App Group suite; watch reads via `mirroredCategories(in:)`. 2 tests.

## [T-201] — MoodTrendAggregator.symbol rounding (round 22)

**Module:** mood · **Shipped in:** round 22 (T1.3)

### Manual verification (smoke)
1. Test suite: `MoodTrendAggregatorSymbolTests` 3 cases pass.
2. Boundary check: 4.6 rounds up to great, 4.5 rounds to good (banker's).

## [T-202] — RefreshTraceLog toast guard (round 22)

**Module:** today · **Shipped in:** round 22 (T1.4)

### Manual verification (smoke)
1. Test suite: `RefreshTraceToastTests` 4 cases pass.
2. Live: pull-to-refresh on Today shows kind + count after at least one refresh has been recorded.

## [T-203] — BlockConflict API consistency (round 22)

**Module:** routine · **Shipped in:** round 22 (T1.5)

### Manual verification (smoke)
1. Test suite: `BlockConflictAPIConsistencyTests` 4 cases pass.
2. Drift between detector and overlap APIs would now fail loudly in CI.

## [T-204] — TripFootprint deterministic tie-break (round 22)

**Module:** vacation · **Shipped in:** round 22 (T1.6)

### Manual verification (smoke)
1. Test suite: `TripFootprintTieBreakTests` 2 cases pass.
2. Two trips with equal CO₂ and different modes always pick the alphabetically smaller mode.

## [T-205] — LocalizedStringResource interpolation scan (round 22)

**Module:** ci · **Shipped in:** round 22 (T1.7)

### Manual verification
1. Run `python3 scripts/check-localized-string-resource.py`.
2. "✓ no LocalizedStringResource interpolation violations (scanned 801 keys in catalogue)".
3. Add a `LocalizedStringResource("foo.bar \(value)")` site referencing a missing key → script exits 1.

## [T-206] — Settings gift ideas CSV (round 22)

**Module:** birthdays · **Shipped in:** round 22 (T2.8)

### Manual verification
1. Add at least one gift idea.
2. Settings → "Copy gift ideas (N) as CSV".
3. Paste in Notes → header `contactID,idea` + rows; commas/newlines properly quoted.

## [T-207] — Settings global lead default (round 22)

**Module:** birthdays · **Shipped in:** round 22 (T2.9)

### Manual verification
1. Settings → "Default lead time" stepper.
2. Change to 14 → caption updates to "14 days before birthday".
3. Restart app → value persists; per-contact overrides still take precedence.

## [T-208] — Housekeeping streak banner (round 22)

**Module:** housekeeping · **Shipped in:** round 22 (T2.10)

### Manual verification
1. Mark a task done in the same room every day for 7+ consecutive days.
2. Top of HousekeepingListView shows "7-day streak — suggested snooze: 3 days" banner.
3. Banner disappears after the streak is broken or below threshold.

## [T-209] — Auto-mirror focus mute (round 22)

**Module:** focus/watch · **Shipped in:** round 22 (T2.11)

### Manual verification
1. Toggle a category mute on iPhone.
2. App Group suite contains updated `focus.categoryMute.mirror.v1` array (visible in Diagnostics if surfaced; tested in unit test).

## [T-210] — Watch hydration reconciler (round 22)

**Module:** watch/hydration · **Shipped in:** round 22 (T2.12)

### Manual verification
1. On watch: tap "+250 ml" three times.
2. Bring iPhone to foreground → pending taps are flushed into HydrationDashboard total.
3. Watch glance shows "0 pending taps" after reconciliation.

## [T-211] — Settings mood week strip (round 22)

**Module:** settings · **Shipped in:** round 22 (T2.13)

### Manual verification
1. Log moods for several recent days.
2. Settings → "This week" section shows 7 columns matching the Today week strip.

## [T-212] — ItineraryView injected forecast fetcher (round 22)

**Module:** vacation · **Shipped in:** round 22 (T3.14)

### Manual verification (smoke)
1. Default `StubWeatherForecastService` returns canned 24°C/18°C / 10% rain.
2. Production callers can swap in `WeatherKitForecastService()` at iOS 16+ runtime.

## [T-213] — Itinerary forecast chip per day (round 22)

**Module:** vacation · **Shipped in:** round 22 (T3.15)

### Manual verification
1. Generate AI itinerary for a trip with geocoded destination.
2. Each day section header shows the forecast chip from cached/stub data.

## [T-214] — Forecast unavailable variant (round 22)

**Module:** vacation · **Shipped in:** round 22 (T3.16)

### Manual verification
1. Force the fetcher to throw → chip falls back to `cachedIgnoringTTL` data with `forecastIsStale` opacity.

## [T-215] — Refresh forecast toolbar + last-updated caption (round 22)

**Module:** vacation · **Shipped in:** round 22 (T3.17)

### Manual verification
1. ItineraryView toolbar → "Refresh forecast".
2. Bottom safe-area inset shows "Last updated HH:mm" caption (orange when stale).

## [T-216] — Stale-graceful forecast cache (round 22)

**Module:** vacation · **Shipped in:** round 22 (T3.18)

### Manual verification (smoke)
1. Test suite: `WeatherForecastCacheTests` covers TTL respect.
2. New `cachedIgnoringTTL(...)` path returns last stored entry even when TTL expired.

## [T-217] — Mood trend 7d/30d toggle (round 22)

**Module:** settings · **Shipped in:** round 22 (T4.19)

### Manual verification
1. Settings → Mood trend → segmented Picker 7d / 30d.
2. Selection persists via @AppStorage across navigation.
3. Week-over-week delta caption appears below the chart when at least 2 weeks of data exist.

## [T-218] — Today positive streak caption (round 22)

**Module:** today · **Shipped in:** round 22 (T4.22)

### Manual verification
1. Log mood ≥ okay for 3+ consecutive days.
2. Today mood quick-log section shows "3-day positive streak" caption in green.

## [T-219] — Backup v4 + mood weekly goal (round 22)

**Module:** settings · **Shipped in:** round 22 (T4.23)

### Manual verification
1. Set mood weekly goal to 4.
2. Settings → Export backup → JSON contains `"version": 4` + `"moodWeeklyGoal": 4`.
3. Clear goal → restore from JSON → goal returns to 4.

## [T-220] — Round 22 visual + watch surfaces (round 22)

**Module:** various · **Shipped in:** round 22 (T5.24, T5.26, T5.27, T5.29, T6.30..T6.34)

### Manual verification
1. **CSV import**: TemplateEditor → "Import CSV from clipboard" with valid CSV → blocks inserted; sheet lists warnings if any.
2. **Conflict gantt**: TemplateEditor with overlapping blocks → "Day timeline" Gantt strip renders red bars over conflicts.
3. **Day completion bar**: Today below the progress summary → colored progress bar + "X% of day done" caption.
4. **Cascade shift**: TemplateEditor with ≥2 blocks → ±15 min buttons shift every block.
5. **Watch hydration goal proportion**: HydrationGlance shows `total / goal ml`.
6. **Watch pending count + clear**: pending taps row + destructive "Clear pending" button.
7. **Watch complication mood emoji**: complication line-2 shows today's mood emoji alongside title.
8. **Watch mood week strip**: Settings glance → 7-day mood emoji strip.
9. **Swipe-back haptic**: BlockDetailWatchView → swipe back → light click haptic.

## [T-221] — HousekeepingCompletionLog day-boundary + idempotency (round 23)

**Module:** housekeeping · **Shipped in:** round 23 (T1.3)

### Manual verification (smoke)
1. `HousekeepingLogIdempotencyTests` 4 cases pass — day boundary, double-tap idempotency, multi-room isolation, clear.

## [T-222] — WatchHydrationReconciler partial-failure tail (round 23)

**Module:** hydration/watch · **Shipped in:** round 23 (T1.4)

### Manual verification (smoke)
1. `WatchHydrationReconcilerTailTests` 3 cases pass — fail-on-first preserves queue exactly, fail-on-last keeps just the failing tap.

## [T-223] — ItineraryForecastBinning extracted helper (round 23)

**Module:** vacation · **Shipped in:** round 23 (T1.5)

### Manual verification (smoke)
1. `ItineraryForecastBinningTests` 4 cases pass — start-of-day key, last-write-wins, daysSpanned clamp, out-of-range index.
2. `ItineraryView` delegates to the helper for both cache + fetch paths.

## [T-224] — Backup v4 → v3 downgrade safety (round 23)

**Module:** backup · **Shipped in:** round 23 (T1.6)

### Manual verification (smoke)
1. `BackupSnapshotV4DowngradeTests` 3 cases pass — strip moodWeeklyGoal still decodes, restore preserves existing goal.

## [T-225] — SwiftLint do/catch warning (round 23)

**Module:** ci · **Shipped in:** round 23 (T1.7)

### Manual verification
1. `.swiftlint.yml` has new `do_catch_same_line` custom rule.
2. Run `./scripts/lint.sh` — no warnings on round-22+23 code.
3. Insert a `do { … }\n catch { }` block locally → SwiftLint fires the warning.

## [T-226] — Sectioned mood log disclosure (round 23)

**Module:** settings · **Shipped in:** round 23 (T2.8)

### Manual verification
1. Settings → Mood log → "By day" disclosure groups entries per calendar day; newest day on top.

## [T-227] — Mood histogram (round 23)

**Module:** settings · **Shipped in:** round 23 (T2.10)

### Manual verification
1. Settings → "Histogram" section renders one bar per emoji.

## [T-228] — Streak share image (round 23)

**Module:** settings · **Shipped in:** round 23 (T2.11)

### Manual verification
1. Hit a 3+ day positive mood streak.
2. Settings → "Share streak as image" copies a 320×320 PNG to clipboard.

## [T-229] — 6-week mood heatmap (round 23)

**Module:** settings · **Shipped in:** round 23 (T2.12)

### Manual verification
1. Log moods across multiple days.
2. Settings → "6-week heatmap" renders a 7×6 grid; greener cells = better days.

## [T-230] — Runtime-aware WeatherKit fetcher (round 23)

**Module:** vacation · **Shipped in:** round 23 (T3.13)

### Manual verification (smoke)
1. `RuntimeWeatherForecastFetcher.make()` returns `StubWeatherForecastService` until WeatherKit + iOS 16+ are both available.

## [T-231] — Itinerary forecast error banner (round 23)

**Module:** vacation · **Shipped in:** round 23 (T3.14)

### Manual verification
1. Force the fetcher to fail → ItineraryView shows orange triangle banner with the error description.

## [T-232] — Trip forecast summary helper (round 23)

**Module:** vacation · **Shipped in:** round 23 (T3.15)

### Manual verification (smoke)
1. `TripForecastSummaryTests` 2 cases pass — averages high/low, picks max rain probability.

## [T-233] — Currency rate change detector (round 23)

**Module:** vacation · **Shipped in:** round 23 (T3.16)

### Manual verification (smoke)
1. `CurrencyRateChangeDetectorTests` 5 cases pass — stable / up / down / nil-on-non-positive / custom threshold.

## [T-234] — Marine diving window helper (round 23)

**Module:** vacation · **Shipped in:** round 23 (T3.17)

### Manual verification (smoke)
1. `MarineDivingWindowTests` 4 cases pass — empty input, single contiguous run, longest run wins, all-rough returns nil.

## [T-235] — Trip notes CSV import (round 23)

**Module:** vacation · **Shipped in:** round 23 (T3.18)

### Manual verification (smoke)
1. `TripNotesCSVImporterTests` 3 cases pass — markdown bullets, skip empties, empty input warning.

## [T-236] — TemplateArchiveStore (round 23)

**Module:** routine · **Shipped in:** round 23 (T4.20)

### Manual verification (smoke)
1. `TemplateArchiveStoreTests` 3 cases pass — set/get persistence, unarchive removes, archivedIDs returns the full set.

## [T-237] — RefreshTraceLog recent summary (round 23)

**Module:** today · **Shipped in:** round 23 (T4.24)

### Manual verification (smoke)
1. `RefreshTraceLogRecentSummaryTests` 3 cases pass — empty, cap, newest-first.

## [T-238] — Round-23 watch surfaces bundle (round 23)

**Module:** watch · **Shipped in:** round 23 (T5.25..T5.29)

### Manual verification
1. Complication: positive mood streak count appended to the today mood emoji when streak ≥ 3.
2. Watch hydration: stepper-driven custom amount → "Log this amount" enqueues a pending tap.
3. Watch settings: "Pause for 1 hour" + "Resume notifications" buttons control PauseNotificationsStore.
4. Complication: theme-override tint applied based on `settings.theme` value.
5. BlockDetailWatchView: "Skip rest of day" button at the bottom.

## [T-239] — Diagnostics observability bundle (round 23)

**Module:** settings/diagnostics · **Shipped in:** round 23 (T6.32, T6.33, T6.34)

### Manual verification (smoke)
1. `WeatherForecastCacheCounters` increments hits/misses on cache reads.
2. `BackupSizeProjector.projectedSize(...)` returns a non-nil byte count for any container with templates.
3. `CacheResetter.resetAll()` clears weather forecast keys + counters + last-conversion entries.

## [T-240] — Cache reset destructive button (round 23)

**Module:** settings · **Shipped in:** round 23 (T6.34)

### Manual verification
1. `CacheResetter.resetAll()` should be wired to a destructive Settings button in round 24 — currently helper only.
2. Test smoke: helper does not throw.

## [T-241] — Mood log midnight boundary (round 24)

**Module:** mood · **Shipped in:** round 24 (T1.3)

### Manual verification (smoke)
1. `MoodLogGroupingMidnightTests` 3 cases pass — split across midnight, collapse same-day, today-section excludes prior-day late-night.

## [T-242] — Mood heatmap row guarantees (round 24)

**Module:** mood · **Shipped in:** round 24 (T1.4)

### Manual verification (smoke)
1. `MoodHeatmapAggregatorTests` 4 cases pass — exact week count, 7 columns each, future cells nil, scored cells present.

## [T-243] — Runtime WeatherKit fetcher (round 24)

**Module:** vacation · **Shipped in:** round 24 (T1.5)

### Manual verification (smoke)
1. `RuntimeWeatherForecastFetcherTests` 2 cases pass — make() returns a fetcher; stub injection round-trips.

## [T-244] — Backup size projector (round 24)

**Module:** settings/diagnostics · **Shipped in:** round 24 (T1.6)

### Manual verification (smoke)
1. `BackupSizeProjectorTests` 3 cases pass — positive bytes for seeded + empty container, formatted output uses KB units.

## [T-245] — Cache resetter preserves mood (round 24)

**Module:** settings · **Shipped in:** round 24 (T1.7)

### Manual verification
1. Log a mood + set a weekly goal.
2. Settings → "Reset all caches".
3. Mood log + weekly goal must remain intact.

## [T-246] — Diagnostics cache counters (round 24)

**Module:** diagnostics · **Shipped in:** round 24 (T2.8)

### Manual verification
1. DiagnosticsView → "Forecast cache" section shows hits/misses + reset button.
2. Reset → counters return to 0.

## [T-247] — Diagnostics housekeeping log dump (round 24)

**Module:** diagnostics · **Shipped in:** round 24 (T2.9)

### Manual verification
1. Mark a few housekeeping tasks done.
2. DiagnosticsView → "Housekeeping log" section shows day-key count per room.

## [T-248] — Diagnostics backup size projection (round 24)

**Module:** diagnostics · **Shipped in:** round 24 (T2.10)

### Manual verification
1. DiagnosticsView → "Next backup size" section shows projected KB.
2. Add data → projection updates on next view re-render.

## [T-249] — Diagnostics archived templates count (round 24)

**Module:** diagnostics · **Shipped in:** round 24 (T2.11)

### Manual verification
1. Archive a template via TemplateListView swipe.
2. DiagnosticsView shows the count.

## [T-250] — Settings reset all caches (round 24)

**Module:** settings · **Shipped in:** round 24 (T2.12)

### Manual verification
1. Settings → "Reset all caches" destructive button visible.
2. Tap → weather + currency caches cleared; mood log untouched (cross-check via T-245).

## [T-251] — Diagnostics mood streak record (round 24)

**Module:** diagnostics · **Shipped in:** round 24 (T2.13)

### Manual verification
1. Log moods on consecutive days.
2. DiagnosticsView shows current streak count.

## [T-252] — Sleep weekly average chart (round 24)

**Module:** sleep · **Shipped in:** round 24 (T3.14)

### Manual verification (smoke)
1. `SleepWeeklyAverageChart` renders one BarMark per data point; empty data hides the chart.
2. Wired into SleepDashboardView in round 25.

## [T-253] — Sleep weekly delta caption (round 24)

**Module:** sleep · **Shipped in:** round 24 (T3.15)

### Manual verification (smoke)
1. `SleepWeeklyDeltaTests` 3 cases pass — nil for empty windows, positive delta for better week, nil for empty prior week.

## [T-254] — Medication 30-day chart (round 24)

**Module:** medication · **Shipped in:** round 24 (T3.16)

### Manual verification (smoke)
1. `Medication30DayChartView` renders binary BarMark per day.
2. Wired into MedicationComplianceView in round 25.

## [T-255] — Medication adherence streak (round 24)

**Module:** medication · **Shipped in:** round 24 (T3.17)

### Manual verification (smoke)
1. `MedicationStreakCounterTests` 3 cases pass — current/best streak walk, gaps break, longest run wins.

## [T-256] — Sleep bedtime variance (round 24)

**Module:** sleep · **Shipped in:** round 24 (T3.18)

### Manual verification (smoke)
1. `SleepBedtimeVarianceTests` 4 cases pass — empty nil, identical-zero stddev, threshold verdicts, single-sample.

## [T-257] — Backup v5 + archive (round 24)

**Module:** backup · **Shipped in:** round 24 (T4.20+T4.21)

### Manual verification
1. Archive a template → Settings → Export backup → JSON contains `"version": 5` + `"archivedTemplateIDs": […]`.
2. Clear archive → Restore from JSON → archive returns to original set.
3. Strip `archivedTemplateIDs` field manually → Restore still succeeds (downgrade safe).

## [T-258] — Backup auto-frequency override (round 24)

**Module:** backup · **Shipped in:** round 24 (T4.22)

### Manual verification (smoke)
1. `BackupAutoFrequencyRecommendedTests` 3 cases pass — defaults to off, follows user choice, archive present forces 7d.

## [T-259] — Template archive UI (round 24)

**Module:** routine · **Shipped in:** round 24 (T5.25, T5.26, T5.28)

### Manual verification
1. TemplateListView toolbar gains "Show archived" toggle.
2. Swipe-action "Archive" hides the template; toggling Show archived reveals with 📁 badge.
3. `TemplateListFilterTests` covers the filtering helper.

## [T-260] — Watch round-24 surfaces bundle (round 24)

**Module:** watch · **Shipped in:** round 24 (T6.30, T6.31, T6.32, T6.33)

### Manual verification
1. BlockDetailWatchView snooze menu (5/10/15 min).
2. Watch settings: "Reset N pending taps" destructive button.
3. Complication: line-3 shows "X%" day-completion when ≥ 1 done.
4. `TodayCompletionPercent` helper covered by 3 tests.

## [T-261] — BlockEditor per-block follow-up override (round 24.5)

**Module:** medication · **Shipped in:** round 24.5 (T3.19, deferred from r24)

### Manual verification
1. Open BlockEditor on an existing medication block.
2. New "Follow-up override" section visible at the bottom; defaults to "Use default".
3. Pick "+45 min" → reopen the block → selection persists.
4. Open BlockEditor on a non-medication block → section hidden.

## [T-262] — MostRecentBackupStore (round 24.5)

**Module:** backup · **Shipped in:** round 24.5 (T4.24, deferred from r24)

### Manual verification (smoke)
1. `MostRecentBackupStoreTests` 3 cases pass — fresh store nil, record persists URL+name+timestamp, clear removes everything.

## [T-263] — TemplateEditor bulk category edit (round 24.5)

**Module:** routine · **Shipped in:** round 24.5 (T5.29, deferred from r24)

### Manual verification
1. TemplateEditor with ≥2 blocks → "Bulk edit category" button visible in blocks section.
2. Tap → sheet shows category picker + selectable block list.
3. Pick blocks (checkmarks toggle), pick target category, Apply.
4. Sheet dismisses; selected blocks now carry the new category; others untouched.
5. `TemplateEditorBulkCategoryTests` 2 cases cover the VM path.

## [T-264] — Round-25 regression depth (round 25)

**Module:** all · **Shipped in:** round 25 (T1.1–T1.8)

### Manual verification (test-only)
1. `BackupSnapshotV5RoundTripTests` (2), `MostRecentBackupStoreOrderTests` (1), `BulkCategoryEditorIdempotencyTests` (2), `BlockEditorFollowupOverrideTests` (3), `TodayCompletionPercentBoundaryTests` (4), `MedicationStreakRolloverTests` (3), `SleepWeeklyDeltaSignTests` (2), `ArchivedTemplateFilterPersistenceTests` (2) — all green.

## [T-265] — Sleep dashboard wires r24 helpers (round 25)

**Module:** sleep · **Shipped in:** round 25 (T2.9, T2.10, T2.14)

### Manual verification
1. SleepDashboard renders weekly average chart + delta caption when `recentNights` is non-empty.
2. Bedtime variance section renders verdict (consistent / driftSlight / driftSignificant) with a colored caption.
3. Share-as-image button appears when a delta summary is computable; tapping the button captures a PNG via `ImageRenderer`.

## [T-266] — Medication compliance wires r24 helpers (round 25)

**Module:** medication · **Shipped in:** round 25 (T2.11, T2.12, T2.13)

### Manual verification
1. MedicationComplianceView shows 30-day chart section when dose history is non-empty.
2. Streak section shows current + best from `MedicationStreakCounter`.
3. "Copy 30-day dose CSV" puts a CSV with the documented header on the clipboard.

## [T-267] — Today + Routine completion-percent chip (round 25)

**Module:** today, routine · **Shipped in:** round 25 (T2.15, T2.16)

### Manual verification
1. Today header shows a colored `XX%` pill when there are scheduled blocks.
2. TemplateListView header mirrors the same pill once `TodayViewModel.reload()` writes a snapshot.
3. Pill color tiers: green ≥85%, blue 50…84%, orange <50%.

## [T-268] — Sleep + medication deepening helpers (round 25)

**Module:** sleep, medication · **Shipped in:** round 25 (T3.17–T3.24)

### Manual verification (test-only)
1. `SleepConsistencyScoreTests`, `SleepDebtTrackerTests`, `MedicationDoseHistoryFilterTests`, `MedicationMissedDoseAlertHelperTests` — all green.

## [T-269] — Backup v6 + archive exporter + checksum (round 25)

**Module:** settings · **Shipped in:** round 25 (T4.25–T4.30)

### Manual verification
1. Export → JSON contains `version: 6` and (when housekeeping log is non-empty) a `housekeepingCompletionLog` map.
2. Restore from a v6 file replays per-room day keys into `HousekeepingCompletionLog`.
3. Restore from a v5 file (no `housekeepingCompletionLog`) decodes cleanly with the field absent.
4. `BackupSnapshotChecksum.sha256(of:)` returns a 64-char hex digest; `verify(_:matches:)` round-trips.

## [T-270] — Vacation polish helpers (round 25)

**Module:** trips · **Shipped in:** round 25 (T5.31–T5.38)

### Manual verification (test-only)
1. `TripCountdownTests`, `TripFootprintYTDTests`, `TripBudgetVsActualTests`, `ItineraryDayWeatherFallbackTests`, `TripDocumentExpiryReminderTests`, `EmergencyContactsExporterTests` — all green.

## [T-271] — Watch surfaces bundle (round 25)

**Module:** watch · **Shipped in:** round 25 (T6.39–T6.46)

### Manual verification
1. `WatchSleepWeeklyAverageGlance`, `WatchMedicationStreakGlance`, `WatchTodayCompletionRing` render gracefully when input is empty (sections collapse).
2. `ComplicationLine3Choice` defaults to `.dayCompletion`; setting persists.
3. `HydrationGoalReachedHaptic.shouldPlay(...)` returns true once per day-bucket and resets on day rollover.
4. `PauseRemainingCaption.caption(...)` shows `Nm` under an hour and `Nh MMm` over.
5. `WatchSettingsThemePicker` mirrors `settings.theme` AppStorage in the App Group suite.
6. `BlockDetailWatchSnoozeMenu` shows three Buttons (5/10/15) — `Menu` is unavailable on watchOS.

## [T-272] — Today/Routine QoL helpers (round 25)

**Module:** today, routine · **Shipped in:** round 25 (T7.47–T7.52)

### Manual verification
1. `BlockTitleHistoryAutocompleteV2.suggest(...)` ranks prefix > " word " > contains > recency.
2. `BlockTagAutocompleteStore.record(...)` normalizes lowercased + dedupes; capacity caps at 50.
3. ⌘N (TodayView) posts `.todayJumpToBlock` Notification.
4. ⌘⇧D (BlockEditorView) posts `.blockEditorDuplicateRequested` Notification.

## [T-273] — Diagnostics polish (round 25)

**Module:** settings · **Shipped in:** round 25 (T8.53–T8.56)

### Manual verification
1. DiagnosticsView "Recent refresh trace" lists the last 10 entries.
2. "Recent errors" lists the last 3 captures from `DiagnosticsErrorLog.shared`.
3. "Copy diagnostics bundle" copies a Markdown multi-section text via `DiagnosticsEverythingV2`.
4. Cache-counter reset surfaces a confirm dialog before wiping.


## [T-274] — Trip countdown reactive on Today (L008 reapplied · session 24)

**Module:** today, trips · **Shipped in:** `50fc7f5`

### Manual verification
1. From a clean install, create a future-dated trip (Trips tab → "+" → name + destination + start date later than today + end date later than start). Save.
2. Switch to Today tab. **Expected:** the upcoming-trip section appears between the focus banner and progress summary, showing the trip name + "in N days" (or "today" if start = today).
3. Edit the trip — change start date to today. Switch back to Today. **Expected:** countdown row updates to "today" without manually pulling-to-refresh.
4. Switch tabs Today → Routine → Today again, no app restart. **Expected:** trip section still visible (regression guard for the L008 cross-tab pattern).
5. Delete the trip. **Expected:** trip section disappears from Today on the next render (no app restart).

### Why this case exists
The pre-fix path went through `viewModel.upcomingTrip` ← `tripsRepository.allTrips()` on `reload()`. iOS 18 keeps tab views alive, and `.onAppear` doesn't reliably re-fire on tab switches, so the cached value went stale. Fix uses `@Query<Trip>` directly in TodayView — observed by SwiftData modelContext, auto-refreshes on every Trip mutation.

## [T-275] — AI itinerary wizard (round 27 WS-A)

**Module:** vacation, ai · **Shipped in:** round 27 commit (TBD)

### Manual verification
1. Trips → existing trip → tap "AI itinerary wizard". Wizard sheet slides up, stage 1/5 visible with progress bar.
2. Stage 1: tap travellers stepper → goes to 3. Type "Maya 7, Lucas 4" in names. Multi-select 2 relationships. Pick fitness "medium". Tap Next.
3. Stage 2: pick vibe "family", multi-select transport plane+car-self, pick pace "balanced", multi-select avoid "crowds, early mornings". Tap Next.
4. Stage 3: 1 night row per trip date appears auto. Each row has city pre-filled with destination, type Picker, booked toggle. Toggle one off, change another's type to airbnb. Tap Next.
5. Stage 4: multi-select 3 activities, 2 loved cuisines, 1 avoided. Free-text "must-see" → type "Coliseo, Trastevere". Tap Next.
6. Stage 5: budget mode → "perDay", amount stepper to 200. Priority = "balanced". Food = "mid". Visa = "alreadyHave". Insurance = "haveIt". Tap Generate.
7. Output sheet appears with prompt preview (monospace, scrollable). Two action buttons visible: "Generate with Apple Intelligence" (only on iOS 26+) and "Copy prompt to clipboard".
8. Tap "Copy prompt to clipboard" → toast "Copied!" appears top-of-sheet ~1.5s. Paste into Notes.app to verify the full prompt arrived.
9. Re-open the wizard for the same trip → all answers from steps 2-6 are pre-filled (TripItineraryRequest persisted in Trip.itineraryRequestJSON).
10. Tap Skip in any stage → advances without forcing answers; the prompt builder uses sensible defaults / omits the unfilled section.

### Failure modes to watch for
- Wizard fails to dismiss → check ItineraryWizardView.dismiss() in cancellation toolbar.
- Pre-fill doesn't restore → verify Trip.itineraryRequestJSON was saved on each onChange.
- "Apple Intelligence" button visible on iOS 18 → availability gate bug; should only appear on iOS 26+.
- Prompt preview truncates → ScrollView must wrap content; verify on long trips with many milestones.

## [T-276] — Birthdays + Important Days on Today (round 27 WS-B)

**Module:** today, birthdays · **Shipped in:** round 27 commit `a7218ea`

### Manual verification
1. Fresh-install or reset all data. Launch app. App seeds locale-appropriate ImportantDay rows (~11 for ES, ~11 for EN, ~12 for FR).
2. Today tab. **Expected:** if any seeded day matches today's month/day, it appears in "🎉 Días especiales" section with "¡Hoy!" caption. If none today, but one falls within lead-default window (default 7), it appears with "en N días". If none within window, section is hidden.
3. Settings → Días especiales. List shows 2 sections: empty "Personalizados" + populated "Predefinidos". Toggle off a seeded day → list updates, change persists across app relaunch.
4. Settings → Días especiales → "+" → Add a custom anniversary "Boda" with "Incluir año" on, date 2010-06-15. Save. Returns to list, "Personalizados" section now shows "Boda" with "15 jun. 2010" subtitle.
5. Today tab. **Expected:** if today is on or near June 15 within the lead window, the custom anniversary appears with star.fill icon.
6. Settings → toggle off `today.showImportantDays` → Today section disappears immediately (no relaunch).
7. Birthdays — needs Contacts permission. If Contacts.app has a contact with birthday today or within lead window, "🎂 Cumpleaños" section appears in Today with gift.fill icon, name + "¡Hoy!" or "en N días" + age if year known.
8. Settings → toggle off `today.showBirthdays` → birthdays section disappears.
9. Switch tabs Today → Routine → Today. **Expected:** important-days section still rendered (no L008 staleness). Birthdays section refreshes on scenePhase active (next foreground).

### Failure modes to watch for
- Seeded days don't appear after fresh install → ImportantDaySeeder.seedIfEmpty bundle path; verify seeds are in PersonalHygiene.app root (not subdirectory).
- Custom anniversary doesn't show on Today → DayRule.anniversary.matches() should ignore stored year, match by month+day only.
- Settings page doesn't update on toggle → @Query rebroadcast vs @Bindable mismatch.

## [T-277] — Wizard v2: persistence + deep-links (round 29)

**Module:** vacation, ai · **Shipped in:** round 29

### Manual verification
1. Trips → existing trip → AI itinerary wizard → fill all 5 stages → Generate. Output sheet shows prompt preview.
2. Verify three new buttons below "Copy prompt to clipboard": "Open in Claude.ai", "Open in ChatGPT", "Open in Perplexity" each with distinct system icon.
3. Tap "Open in Claude.ai". **Expected:** Safari/Claude.ai opens at `https://claude.ai/new`. Pasteboard now contains the full prompt. Toast at top of sheet says "Prompt copied — paste into the new chat" for ~1.5s. Paste in the chat input to confirm.
4. Repeat step 3 for ChatGPT (`https://chatgpt.com/`) and Perplexity (`https://www.perplexity.ai/`).
5. (iOS 26+ only) Tap "Generate with Apple Intelligence". Wait for the LanguageModelSession to respond. **Expected:** generated text appears in green-tinted card below actions, with abbreviated date+time caption above.
6. Dismiss the output sheet. Re-open the wizard for the same trip → tap Generate to land on the output sheet again. **Expected:** the previously-generated text is still visible (loaded from `Trip.itineraryGeneratedText` on .onAppear), with the original timestamp.
7. Tap the destructive "Clear saved itinerary" button below the result. **Expected:** the green card disappears immediately. Re-launch the app, re-open the wizard → no saved itinerary card, persistence cleared.
8. Switch app language ES → EN → FR. Re-open the output sheet. **Expected:** all 3 deep-link button labels + clear-button + open-hint toast are translated.

### Failure modes to watch for
- Saved itinerary text vanishes between sessions → modelContext.save() not called after assignment; check `runOnDevice()` and `clear`-button branches.
- Toast doesn't appear → `toastKey` State not updating, OR overlay alignment wrong.
- Deep-link opens Safari but pasteboard is empty → `UIPasteboard.general.string = prompt` ordered after `UIApplication.shared.open()` (race) — must be assigned first.
- "Open in ChatGPT" navigates to a logged-out wall and the prompt is lost when user signs in → known external limitation; the toast is the recovery path. Document this in the in-app help if reported.
- Foundation Models button visible on iOS 18 simulator → `isAppleFMAvailable` gate wrong; should `#available(iOS 26, *)` *and* `SystemLanguageModel.default.availability == .available`.

---

## [T-278] — Network rate-limit diagnostics (round 31 O02/O03)

**Module:** vacation, diagnostics · **Shipped in:** round 31

### Manual verification

The new diagnostic counter only shows up when at least one non-success outcome has been recorded for an upstream service. Default state: **invisible** — silence is the healthy signal.

1. Trips → any trip → Itinerary forecast or currency conversion. Pull-to-refresh.
2. Settings → Diagnostics → "Network activity" section. **Expected:** rows for `frankfurter` and/or `openMeteo` with raw call counts (e.g. `frankfurter: 3`, `openMeteo: 1`). No second-line breakdown yet.
3. Force a rate-limit hit (Frankfurter is unlikely in real traffic but you can simulate via Charles/Proxyman: rewrite `api.frankfurter.app` responses to 429 for one request). Re-run a currency conversion.
4. Settings → Diagnostics → "Network activity". **Expected:** the `frankfurter` row now shows a second caption-line `429:1` (or `429:N` if multiple hits). The same shape applies to `openMeteo` if the upstream is rate-limited (Open-Meteo Marine has a 10k req/day free quota).
5. Force a 5xx response (rewrite to 503). The breakdown line shows `5xx:1`. With multiple types: `429:2 · 5xx:1 · net:0 · dec:0` — outcomes with zero counts are omitted.
6. Kill network (airplane mode → currency call). The breakdown line shows `net:1`.
7. Reset diagnostics ("Reset cache counters" button). **Expected:** breakdown row disappears (zero failures); raw call count also zeroed.

### Failure modes to watch for
- Breakdown row shows when there are no failures → `hasFailureOutcome(for:)` logic broken; should return false if all outcomes are `.success` or empty.
- 429 response counts as `5xx` or `net` → `MarineWeatherService` / `CurrencyService` switch on `http.statusCode` is wrong; verify the case ordering (200..<300 first, then 429, then 500..<600, then default).
- `convertAll` (multi-target Frankfurter) doesn't emit outcome → check `convertAll` path mirrors `convert` (round 31 added both).
- Counter resets across app launches but breakdown line lingers → state reads from `NetworkActivityCounter.shared`; verify the section re-evaluates `hasFailureOutcome` on every view body.
- VoiceOver reads outcome breakdown twice → `accessibilityElement(children: .combine)` should already group; verify the row reads as a single element.

