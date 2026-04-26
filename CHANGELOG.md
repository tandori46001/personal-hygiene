# Changelog

All notable changes to this project are documented here.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and the project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added — Session 7 ("haz todo" round 5, 20 slices: dependabot triage + a11y completeness + tests + cross-module polish)

- **Slice 1 — Dependabot triage:** bumped `actions/checkout` → v6, `actions/cache` → v5, `actions/upload-artifact` → v7 in `.github/workflows/ci.yml`. Open dependabot PRs (#1, #2, #3) auto-close on next dependabot run.
- **Slice 2 — ROADMAP session-6 polish note + CHANGELOG round-5 entries:** documented round 4's a11y/UX/widget shipments under Phase 1.
- **Slice 3 — LESSONS.md L002:** captured the `BlockNotificationIdentifier.parse` cross-module identifier collision risk + guard test.
- **Slice 4 — Birthdays editor a11y:** `BirthdayLeadEditorView` form rows combine into single VoiceOver elements, lead-time stepper has explicit accessibility label.
- **Slice 5 — Deep Focus schedule editor a11y:** `FocusScheduleEditorView` window rows group title + day-of-week + time range; weekday toggle pills get spoken state.
- **Slice 6 — Document scanner a11y:** `DocumentScannerView` post-scan preview labels each page; thumbnail row groups page index + delete control.
- **Slice 7 — AX5 round-2 smoke tests:** added `test_birthdayLeadEditor_render_atAccessibilityXXXL`, `test_focusScheduleEditor_render_atAccessibilityXXXL`, `test_settings_render_atAccessibilityXXXL`.
- **Slice 8 — `BlockNotificationIdentifier.parse` exhaustive table tests:** round-trip + malformed identifiers + non-routine prefixes all covered.
- **Slice 9 — `SnoozeDurationStore` boundary tests:** 5/10/15 boundary values + invalid persisted value falls back to 5.
- **Slice 10 — `DeepFocusFilter.activeWindow` tests:** schedule beats block, no-overlap returns nil, midnight-spanning windows.
- **Slice 11 — `HydrationCompliance.bestStreakDays` edge tests:** empty history, current-equals-best, gap resets streak.
- **Slice 12 — Backup v1.1 → v1 downgrade-safety test:** v1.1 backup re-decoded by v1 path keeps every user-visible item.
- **Slice 13 — `BlockSnoozeStore` cross-module:** new `BlockSnoozeSource` enum (routine / hydration / milestone) so per-source badges scope cleanly; `BlockNotificationIdentifier.parse` recognizes all three prefixes.
- **Slice 14 — `DeepFocusHomeWidget` app-group prep:** `AppGroup.suiteName` constant introduced; `UserDefaultsFocusScheduleStore` accepts an injected suite name (defaults to `.standard`).
- **Slice 15 — `WhatsNextDialogBuilder` watch share:** pure formatting helper moved to `App/Shared/Intents/`; iOS intent + watch widget now use the same dialog phrasing.
- **Slice 16 — Settings → "What's new" sheet:** lists widget + Siri + snooze indicator; reuses onboarding tip strings.
- **Slice 17 — Today X-of-N tap-to-expand:** summary card now shows a `Popover`/`Sheet` listing each block with done state.
- **Slice 18 — Hydration goal preset chooser:** Settings → Hydration adds 2.0 / 2.5 / 3.0 L quick-tap row above the custom field.
- **Slice 19 — Trip itinerary plain-text Share:** `TripDetailView` adds a "Copy / Share itinerary as text" action that builds a plain-text rendering and presents `UIActivityViewController`.
- **Slice 20 — Onboarding skip/restart in Settings:** `OnboardingFlagStore` exposes `reset()`; Settings adds a "Show onboarding again" entry.

### Added — Session 6 ("haz todo" round 4, 20 slices: docs hygiene + a11y + tests + UX polish)

- **Slice 1 — ROADMAP refresh:** Phase 1 → ✅ ~98%, Phase 2 → ✅ ~95%, Phase 3 → ✅, with session-5 polish notes added under Phase 1 and Phase 5.
- **Slice 2 — QA_MANUAL T-023…T-042:** 20 new sections cover every session-5 slice with cases + manual verification.
- **Slice 3 — ARCHITECTURE §13-§17:** documents the `PersonalHygieneWidgets` target, value-type registry, `Cached*Service` decorator convention, current notification architecture, and widget extension trade-offs.
- **Slice 4 — Templates editor a11y:** `BlockSummaryRow` now speaks natural-language time via `Text(date, format: .dateTime.hour().minute())`; BlockEditor's hour/minute pickers gain explicit accessibility labels via `a11y.startTime.{hour,minute}`.
- **Slice 5 — Settings a11y:** notifications-status row combined into one VoiceOver element.
- **Slice 6 — Hydration a11y:** progress bar gets a spoken percentage label; "today total" + "today goal" rows combine into single VoiceOver elements.
- **Slice 7 — Trips a11y + thumbnail:** `TripRow` gains a 44×44 cover-photo thumbnail (or airplane glyph fallback) and explicit `accessibilityHidden(true)` on decorative chevrons. Milestone row groups its title + days-before subtitle.
- **Slice 8 — Dynamic Type smoke tests:** added `test_templateList_render_atAccessibilityXXXL`, `test_tripsList_render_atAccessibilityXXXL`, `test_emptyTrips_render_smoke`, `test_pastTripsArchive_render_smoke`.
- **Slice 9 — NextBlockResolver edge cases:** 5 new tests cover empty template, exact-start = current, exact-end = next, no-wrap-after-midnight, before-first-block, and overlapping blocks.
- **Slice 10 — WhatsNextDialogBuilder:** intent's dialog logic extracted into a pure helper + 4 unit tests (no template / empty / current / upcoming).
- **Slice 11 — NotificationActionHandler refactor + tests:** snooze interval is now injectable via `snoozeIntervalProvider`; mark-done now removes the original pending notification; 8 new tests cover snooze-request building + `SnoozeDurationStore` (UserDefaults-backed, allows 5/10/15 min).
- **Slice 12 — BackupService v1.1 tests:** new round-trip test for `packingItems`; retro-compat decoder test confirms a v1 backup without `packingItems` decodes successfully.
- **Slice 13 — Snoozed-once indicator:** new `BlockSnoozeStore` + `BlockNotificationIdentifier.parse` (parses routine block notification IDs into `(blockID, dayKey)`). `NotificationActionHandler` records snooze taps via an injected `snoozeRecorder`. `TodayViewModel.isSnoozedToday(_:)` exposes it; Today row shows an alarm badge.
- **Slice 14 — Custom snooze duration:** Settings → Scheduling section gains a Picker (5/10/15 min) backed by `SnoozeDurationStore`; the action handler reads the stored value at fire time.
- **Slice 15 — Trip thumbnails:** see slice 7.
- **Slice 16 — Hydration best streak:** new `HydrationCompliance.bestStreakDays(...)` + view-model `bestStreakDays()`. UI shows a trophy badge when best > current streak. 3 new tests.
- **Slice 17 — Birthdays auto-refresh:** `BirthdaysView` re-runs `reloadStatus()` + `reload()` on `scenePhase == .active` so re-granted Contacts permission is picked up without a relaunch.
- **Slice 18 — Deep Focus widget (small):** new `DeepFocusHomeWidget` exposes three states (active / upcoming / idle), uses the same `UserDefaultsFocusScheduleStore` + `DeepFocusFilter.activeWindow` as the app.
- **Slice 19 — Housekeeping room picker:** new-task sheet auto-suggests existing rooms via Picker derived from `availableRooms`, with an "Add new room…" escape hatch that switches to free-text input.
- **Slice 20 — Onboarding tips:** welcome screen now lists three tips (add the widget, try the Siri shortcut, allow notifications) so the user discovers the new platform extensions.

### Added — Session 5 ("haz todo" round 3, 20 slices)

- **Slice 1 — Itinerary persistence:** `ItineraryStore` (file-on-disk JSON keyed by `Trip.id`) so the last AI-generated itinerary survives app restarts. `TripItinerary` is now `Codable`.
- **Slice 2-4 — API caching:** Decorator wrappers `CachedMarineWeatherService`, `CachedCurrencyService`, `CachedTravelAdvisoryService` add 30-min TTL caching for the three external/deep-link services.
- **Slice 5 — Past trips archive:** `TripsListView` splits into "Upcoming" + "Past" sections via `upcomingTrips()` / `pastTrips()` helpers.
- **Slice 6 — Trip detail Cancel/Save:** `TripDetailViewModel` exposes draft scalar fields with `commitDraft()` / `revertDraft()`; auto-save on disappear is gone.
- **Slice 7 — SwiftLint hardcoded UI strings:** Custom rules (`hardcoded_text_view`, `…_navigationTitle`, `…_accessibilityLabel`, `…_button_label`) are now `error`-level, blocking builds when a literal slips into UI code.
- **Slice 8 — Today empty-state CTA:** When no template is active, the empty state shows a "Create template" button that switches to the Templates tab via a new `selection` binding in `MainTabs`.
- **Slice 9 — Skip block today:** `BlockSkipStore` (UserDefaults-backed) records `(blockID, dayKey)` skips; swipe-action on Today rows toggles them. `NotificationCoordinator` filters skipped blocks before scheduling.
- **Slice 10 — Notification snooze 5 min:** `UNNotificationCategory`s registered at launch; `NotificationActionHandler` reschedules with a `UNTimeIntervalNotificationTrigger`.
- **Slice 11 — Notification grouping:** Routine, medication, milestone, hydration each get their own `threadIdentifier` + `categoryIdentifier`.
- **Slice 12 — "What's next?" Siri Shortcut:** `WhatsNextIntent` reads the active template + `NextBlockResolver` and reports the current/next block via Siri / Shortcuts.
- **Slice 13 — iOS WidgetKit extension:** New `PersonalHygieneWidgets` target with `NextBlockHomeWidget` (small + medium families). Reuses `NextBlockResolver`.
- **Slice 14 — Trip cover photo:** `Trip.coverPhotoData` (external storage) + `PhotosPicker` in Trip detail; JPEG-compressed at 0.7 quality before persisting.
- **Slice 15 — Packing list:** `Trip.packingItems` (value-type array) + `PackingListSection` with toggle/delete + summary footer; persists across `BackupService` (v1.1).
- **Slice 16 — Hydration streak:** `HydrationCompliance.currentStreakDays(...)` counts consecutive goal-meeting days; rendered as a flame badge.
- **Slice 17 — Housekeeping room filter:** `HousekeepingTask.room` (free text) + Picker filter (`.all` / `.unsorted` / `.named`).
- **Slice 18 — Birthdays per-contact heads-up:** `BirthdayLeadStore` (UserDefaults-backed) overrides the global default; sheet editor reachable via swipe action.
- **Slice 19 — Scheduled focus windows:** `ScheduledFocusWindow` + `FocusScheduleStore`; Settings → Deep Focus opens an editor with weekday toggles and time pickers. `DeepFocusFilter.focusWindows` merges block-derived + schedule-derived windows.
- **Slice 20 — VoiceOver pass:** Time-only displays speak natural-language time via `Text(date, format: .dateTime.hour().minute())`; arrow glyphs hidden from VoiceOver.

### Added — Phase 5 (M9 vacation, session 4)

- **Slice 1 — Trip detail view:** `TripDetailViewModel` + `TripDetailView` with editable name/destination/dates, milestones list, documents list, and days-until-departure footer.
- **Slice 2 — Milestone editor sheet:** `MilestoneEditorView` (create + edit modes); inline circle-toggle for done state.
- **Slice 3 — Milestone notifications:** `TripMilestoneNotificationFactory` fires at 09:00 local on `tripStart - daysBefore`; `TripMilestoneScheduler` walks every trip on launch. `NotificationService` gained prefix-aware `scheduleAll(_:cancellingPrefix:)` so block + milestone schedules coexist.
- **Slice 4 — VisionKit document scanner:** `DocumentScannerView` wraps `VNDocumentCameraViewController`; flattens scanned pages into a single PDF via `PDFKit`. Camera usage description added.
- **Slice 5 — Document preview:** `DocumentPreviewView` reads bytes from Keychain and renders PDFs via `PDFView` or images via `Image(uiImage:)`.
- **Slice 6 — AI itinerary:** `ItineraryGenerator` protocol with `StubItineraryGenerator` (deterministic, used in tests) and `FoundationModelsItineraryGenerator` (iOS 26+ `@Generable` Apple Intelligence).
- **Slice 7 — Marine weather:** `OpenMeteoMarineService` + `MarineConditionsView` for trips with destination coordinates.
- **Slice 8 — Currency conversion:** `FrankfurterCurrencyService` + `CurrencyView` (free, key-less, ECB-sourced rates).
- **Slice 9 — Travel advisory:** `ExterioresAdvisoryService` deep-links into the Spanish foreign ministry's recommendations page with destination as query.
- **Slice 10 — Trip PDF export:** `TripPDFExporter` renders cover + milestones + documents inventory; share via `UIActivityViewController`.

### Added — Phase 1 (iOS UI gaps, session 4)

- **Slice 11 — Block-completion toggle:** Each Today row gets a tappable circle/check icon backed by `RoutineRepository.markDone` / `unmarkDone`; title strikes-through when done.
- **Slice 12 — X of N done summary:** New summary card above the now-row with linear `ProgressView`.
- **Slice 13 — Trip countdown card:** Today view shows the next upcoming trip with days-until-departure (or "Departing today").

### Added — Phase 4 prep (QA / tests, session 4)

- **Slice 14 — QA_MANUAL.md:** Added T-012 → T-022 covering Hydration, Housekeeping, Birthdays, Deep Focus, Trip CRUD + Keychain, Trip detail UI, milestone notifications, document scanner, AI/marine/currency/advisory, PDF export, and Today completion/summary/countdown.
- **Slice 15 — Render smoke tests:** `RenderSmokeTests` exercises Today (populated + empty), Templates, Trips list, Trip detail via SwiftUI's `ImageRenderer` to catch missing environment dependencies and infinite-layout failures.
- **Slice 16 — XCUITest target:** New `PersonalHygieneUITests` target. App reads `-uiTestReset` launch arg and mounts an in-memory container for deterministic onboarding tests. Two cases cover the fresh-launch onboarding flow and post-onboarding tab navigation.

### Added — Infra / polish (session 4)

- **Slice 17 — CloudKit-ready schema:** `AppModelContainer.makeProduction(cloudKit:)` accepts a flag; `cloudKitDatabase: .private("iCloud.com.tandori46001.personalhygiene")` is wired but defaults to `.none` until the entitlement is added.
- **Slice 18 — JSON backup:** `BackupService` round-trips routine + completions + hydration + housekeeping + trips + milestones via a versioned `BackupSnapshot`. Settings tab gained Export / Import (destructive) flows.
- **Slice 19 — App icon variants:** `scripts/generate-app-icons.py` writes light / dark / tinted 1024×1024 PNGs; `Contents.json` declares iOS 18 luminosity appearances.
- **Slice 20 — i18n parity + Dynamic Type:** `scripts/check-i18n.py` (called from `check-tests.sh`) verifies every key has en/es/fr translations and is in `translated` state. Two new render-smoke tests at `dynamicTypeSize = .accessibility5` catch AX5 layout breakage.

### Added — Phase 0 (bootstrap)
- Repository scaffolding: README, LICENSE (MIT), CHANGELOG, CONTRIBUTING, SECURITY, `.editorconfig`, `.gitignore`, `.swiftlint.yml`, `.swift-format`.
- `PRD.md` v0.2 — product requirements (9 modules, 7 delivery phases) post C1-C6 logical audit.
- `ARCHITECTURE.md` skeleton, `ROADMAP.md`, `CLAUDE.md`, `LESSONS.md`, `QA_MANUAL.md`.
- GitHub Actions: `ci.yml` (3 conditional jobs), dependabot, CODEOWNERS, PR + issue templates, BRANCH_PROTECTION.md.
- 5 dev scripts (`bootstrap`, `check-tests`, `check-clean`, `lint`, `format`) — bash 3.2 compatible.
- **Xcode project** generated from `App/project.yml` via xcodegen — iOS app + watchOS app + unit-test target.

### Added — Phase 2 (slice 21)
- **Slice 21 (watchOS bootstrap):** PersonalHygieneWatch app now hosts a today-blocks list using the same shared `RoutineRepository` + `TodayViewModel`. `TodayViewModel` moved from iOS feature folder to `App/Shared/ViewModels/`. `Localizable.xcstrings` moved from iOS feature folder to `App/Shared/Localization/` so both targets share localizations.

### Added — Phase 1 (slices 1, 3-14, 16-20)
- **Slice 1+3 (persistence):** `Block` and `RoutineTemplate` as `@Model` with cascade-delete relationship. `AppModelContainer` factory (production / in-memory). `RoutineRepository` protocol + `SwiftDataRoutineRepository`.
- **Slice 4 (Block editor):** `BlockEditorView` + `BlockEditorViewModel` with title, category picker (12 categories), time pickers, duration stepper, lead-time, deep-focus toggle, notes.
- **Slice 5 (Template editor):** `TemplateEditorView` + `TemplateEditorViewModel` — manage block list with add / edit / delete / cascade.
- **Slice 6 (Template list):** `TemplateListView` + `TemplateListViewModel` — browse + create + activate (one active per day type) + delete.
- **Slice 7 (Today):** `TodayView` + `TodayViewModel` — pulls active template for today's `DayType` (weekday/weekend); shows current/next block.
- **Slice 8 (Onboarding):** first-launch wizard backed by `@AppStorage`; seeds two starter templates (weekday + weekend) with localized block titles.
- **Slice 9-11 (notifications):** `NotificationFactory` (pure value-type builder), `UserNotificationsService` (UNUserNotificationCenter wrapper), `NotificationCoordinator`. Settings tab with permission flow + manual refresh. Critical Alerts level set on medication blocks.
- **Slice 12a (travel-time infra):** `BlockLocation` value type + `Block.latitude/longitude/locationName` fields. `TravelTimeService` protocol with `StaticTravelTimeService` (test/preview) and `MKDirectionsTravelTimeService` (production). `NotificationFactory` async variant computes `effectiveLead = staticLead + ⌈travelTime/60⌉` when a block has `location` and an `origin` is configured; falls back to static lead on service errors. `NotificationCoordinator` accepts optional `homeLocation` + `travelTimeService` and routes to the async path.
- **Slice 12b (travel-time UI):** `BlockEditor` gains a Location section (place name + lat/lon) with validation. Settings tab gains a Home location section persisted via `@AppStorage` (`HomeLocationStore`). `ContentView` wires `MKDirectionsTravelTimeService` + the stored home location into every `NotificationCoordinator`. ~12 i18n keys × 3 locales added.
- **Slice 13-14 (medication infra):** `MedicationService` protocol + `InMemoryMedicationService` (tests/previews) + `HealthKitMedicationService` (placeholder — not bridged into simulator). `Block.medicationConceptIdentifier` field added.
- **Slice 16 (Critical Alerts):** medication notifications get `interruptionLevel = .critical` (effective when entitlement is granted).
- **Slice 17 (compliance dashboard):** `MedicationCompliance` arithmetic (pure) + `MedicationComplianceView` showing last 7 days + colour-coded overall adherence.
- **Slice 18-19 (sleep):** `SleepService` protocol + impls. `BedtimeCalculator` (pure modular-arithmetic for wake-up → bedtime). `SleepDashboardView` with target bedtime + last-night actual + deficit indicator.
- **Slice 20 (Sleep Focus):** deep-link button to iOS Focus settings (no public API to activate Focus programmatically).

### Added — meta-system
- **L001 lesson:** ModelContainer must outlive ModelContext. Captured during slice 1+3 — orphan-context pattern crashed the simulator with "Invalid device state" / "Host is down" during cascade-delete.

### Deferred (documented in `ROADMAP.md`)
- Slice 2 (CloudKit sync) — needs Apple Developer Program ($99/yr).
- Slice 15 (HKObserverQuery sync) — needs real device + HealthKit entitlement.
- Slice 16 fallback (re-notification on missed dose) — pairs with HKObserverQuery.

### Fixed
- `scripts/check-clean.sh` now `mkdir -p build` before invoking `gitleaks --report-path build/gitleaks.json`. Without this, every CI run since `4d62a8c` failed because the Ubuntu runner does not pre-create the build/ directory.

### Tests
- **168 unit + 2 UI = 170 automated** at end of session 4 (was 65 at end of Phase 0). Covers all model, persistence, service, view-model layers + render smoke + onboarding XCUITest.

### i18n
- `Localizable.xcstrings`: **251 keys × 3 locales** (EN + ES + FR). Parity verified by `scripts/check-i18n.py` (called from `check-tests.sh`).

---

## Version conventions

- **MAJOR** — breaking changes to data model, public API, or supported OS minimums.
- **MINOR** — new modules / features (additive).
- **PATCH** — bug fixes, dependency bumps, doc updates.

Pre-1.0 versions (`0.x.y`) bump MINOR for any user-visible change and PATCH for fixes.
