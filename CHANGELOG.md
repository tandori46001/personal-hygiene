# Changelog

All notable changes to this project are documented here.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and the project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added — Session 18 round 20: 30-slice regression guards + mood log surface + trip polish + Today QoL + observability

Tier 1 (regression guards):
- Snapshot-lab smokes (perpetual-deferred since round 11) for AdvisoryView, CurrencyView quick-pick, HydrationDashboard empty-chart via native `ImageRenderer`. No third-party SnapshotTesting dep.
- DynamicType regression at `.accessibility5` for the round-12+ surfaces (Advisory, Currency, Hydration, TemplateEditor) extracted into a new `RenderSmokeTestsRound20` class.
- New `BlockNotifIDRoundTripTests`: property-style ~1000-input round-trip across the 4 known notification identifier shapes (routine / hydration / milestone / medicationFollowUp) plus the `.snooze.<ts>` strip path. Catches L002-style format drift on existing kinds at runtime.
- `DiagnosticsPendingByGroupCSVTests` extended: header-only CSV no trailing newline, identifiers containing commas sanitized into semicolons.
- New `MoodLogStoreTests`: 35→30 capacity cap, today-entry filter (most-recent same-day), clear behavior.

Tier 2 (mood log surface):
- TodayView "How do you feel?" gains a "X good days this week" caption when `MoodLogStore.goodDaysCount() > 0` (trailing 7 days, dedup-counted by entry).
- New `SettingsViewRound20` extension: mood log disclosure (last 30 entries with timestamp + emoji) + "Copy mood log (CSV)" button + destructive "Clear mood log" button.
- `BackupSnapshot` v3: optional `mood: [MoodEntryPayload]?` field. v1/v2 backups decode as nil; restore replays the full mood log when present.
- `MoodLogStore.exportCSV(formatter:)` helper used by the Settings button.

Tier 3 (vacation polish):
- TripsListView past-trips section gains year filter chips when ≥2 distinct years present. Static `distinctYears(in:)` helper on TripsListView.
- `CurrencyView.supportedCodes` reordered: JPY moves from 7th to 3rd position to match the user's diving-trip pattern (EUR home → USD → JPY → GBP → CAD → CHF → AUD).
- ItineraryView day-section header gains a relative-day marker (`T-N` countdown · `D+N` in-trip · `✈` on start day) via new `dayMarker(forIndex:tripStart:)` static.
- TripNotesSection gains "Insert template" Menu (Preparation / Day-D / Return). Each template appends Markdown bullets to draftNotes — additive, never overwrites.
- TripCarbonSection adds a per-mode factor caption (`0.115 kg CO₂ / passenger·km · DEFRA 2023`).

Tier 4 (Today / Routine QoL):
- TodayView wraps List in `ScrollViewReader`; tapping the "Now · HH:MM" red hairline now smooth-scrolls to the current/next block (via `.id(block.id)` anchors). NowMarkerRow gains optional `onTap` callback.
- `TemplateEditorViewModel.renumberStartTimes(from:)` re-anchors blocks back-to-back from the original first start; "Renumber start times" button surfaced when ≥2 blocks exist.
- Today reset-day now returns a `ResetDaySnapshot`; floating bottom toast with Undo button auto-expires after 10s. New `undoResetDay(_:)` view-model method replays the snapshot.
- New `BlockTitleSuggestions.recent(in:category:limit:)` helper. `TemplateEditorViewModel.titleSuggestions(for:)` wires it into the new optional `BlockEditorView.titleSuggestions` provider — surfaces last 5 distinct titles per category as a Menu in the block editor.

Tier 5 (observability):
- `DiagnosticsView.refreshTraceCSV(_:)` static helper + new "Export refresh trace (CSV)" share button alongside the existing pending-by-group CSV. Header `timestamp,scheduledCount,kind`.
- Settings "Copy everything bundle" — multi-section text dump (build descriptor + locale + key count + mood entry count + last-mood summary + diagnostics snapshot count + mood CSV) for one-tap bug-report copy.
- `WhatsNewSheet` confirm-dismiss flow: tracks whether the user has scrolled to the bottom; tapping Done before reaching the end shows a destructive confirm dialog ("Dismiss without reading?").
- T5.24 (process launches table) was already covered by the round-12 `launchHistorySection` — verified, no new code.

Build housekeeping: refactored `NotificationCategoryRegistrar.register(...)` into `action(...)` + `category(...)` helpers + a fileprivate `CategoryID` enum to fit the 50-line function-body cap. Extracted `TripExpensesSection` to `TripDetailViewRound20.swift` so `TripDetailViewRound12.swift` stays under the 500-line file cap. Round-20 reset-day overlay extracted to `TodayViewRound19.swift` extension to keep `TodayView` struct body under the 300-line type-body cap.

Counts: tests **585** (583 unit + 2 UI). i18n keys **737** × 3 locales (+33 net). Lessons captured: still **6** (L001-L006).

### Added — Session 17 round 19: 28-slice quality + watch parity + vacation deepening

Tier 1 (preventive L006 guards):
- SwiftLint custom rule `dynamic_localized_key` now flags any `LocalizedStringKey("...\(...)")` as build error (catches the SwiftUI gotcha L006 captured at compile time).
- `scripts/check-localized-key-usage.py` — backup static scan for the same pattern.
- `scripts/check-xcstrings-format-consistency.py` — verifies declared `%@`/`%lld` placeholders match call-site interpolation count.
- `BundleLocalizationLookupTests` extended with `test_integerSuffixKeysResolve` (snooze duration / medication follow-up / marine freshness) and `test_round17_18_discreteSuffixKeysResolve` (pending source headers, mute categories, template presets + insertion toasts).
- Two L006 sites missed in the round-18 hotfix (BlockEditorView Picker + TemplateEditorView day-type Picker) migrated to `Text(localizedKey:)`.

Tier 2 (watch parity catch-up):
- New `NotificationActionID.snooze30min` action (UNNotificationCategory) registered on routine, hydration, and trip-milestone categories.
- New `NotificationActionID.skipDose` (destructive) action registered on the medication category.
- `NotificationActionHandler` handles both new actions: snooze30 schedules a fresh request 30 min out; skipDose removes the pending notification without scheduling a follow-up.
- `NextBlockComplication` (rectangular) gains line-3 caption: localized category + duration (e.g. `hygiene · 30 min`).
- Watch `ContentView` reads `settings.theme` via the App Group suite and applies `.preferredColorScheme(_:)` so the iPhone toggle propagates once the entitlement is wired.
- Watch `SettingsGlanceWatchView` reads `PauseNotificationsStore` from the App Group suite and shows "Paused until HH:MM" when the iPhone has paused notifications.
- Watch snooze-duration row migrated from the L006-broken `LocalizedStringResource` pattern to `Text(localizedKey:)`.

Tier 3 (settings / diagnostics):
- `BackupSnapshot` v2: optional `diagnostics: DiagnosticsSnapshot` field bundled into the JSON export so a single share covers user data + the diagnostics one-pager.
- Diagnostics snapshot-history disclosure gains a "Copy diff (last vs prev)" button using the new `DiagnosticsSnapshot.Diff.formatted()` helper.
- New `SettingsViewRound19.swift` extension hosts:
  - "Reset onboarding tips" destructive row (clears `whatsNew.lastSeenCommitSHA` + `WhatsNewHistoryStore`).
  - "About this build" footer section with `BuildInfo.shortDescriptor` + locale + `LocalizationKeyCount.total`. Tap-to-copy.

Tier 4 (vacation deepening):
- `TripCarbonEstimate.TransportMode` enum (flight / ferry / publicTransport / car) with per-mode `kgPerPassengerKm` factor (DEFRA 2023 averages). `roundTripKgCO2(distanceKm:mode:)` defaults to `.flight` so existing callers stay green.
- `TripCarbonSection` gains a transport-mode picker; selection persisted via `@AppStorage("trip.carbon.mode")`.
- `TripExpensesSection` gains "Copy converted totals" button — uses `LastConversionStore` rate to print a per-currency breakdown + grand total to clipboard (offline; no network).
- `TripsListViewModel.duplicateToNextYear(_:)` shortcut + new "Duplicate next year" swipe action on upcoming trips (purple, calendar.badge.plus icon).

Tier 5 (Today / Routine quality of life):
- New `MoodLogStore` (UserDefaults-backed, capacity 30 entries, 5-emoji `Mood` enum). New "How do you feel?" section on TodayView highlights the most-recent mood for today.
- New `tomorrowSection` disclosure on TodayView lists tomorrow's blocks (based on tomorrow's day-type); collapsed by default.
- `TemplateEditor` block rows gain a "Duplicate block" context menu (`TemplateEditorViewModel.duplicate(_:)` clones with start time bumped by source duration).
- `TemplateListView` gains a "Category legend" disclosure at the bottom mapping each `BlockCategory` to its color dot + localized name.

Counts: tests **567** (565 unit + 2 UI). i18n keys **704** × 3 locales (+25 net: round 19 added 17, watch + medication actions added 8, layout-polish keys carried). Lessons captured: still **6** (L001-L006).

### Fixed — Session 16 hotfix: localization regression + layout polish

User screenshotted round-18 install on the iPhone and surfaced 9 places where raw localization keys rendered instead of translations (`category.work`, `housekeeping.recurrence.weekly`, `settings.snooze.duration.5`, `settings.medication.followup.30`, `settings.marine.freshness.24`, `trip.packing.category.clothing`, `birthdays.daysUntil 28`, `settings.backup.autoFrequency.off`, `birthdays.lead.preview ...`).

Root cause: SwiftUI's `Text(LocalizedStringKey("prefix.\(rawValue)"))` and `Text(LocalizedStringResource("prefix.\(rawValue)"))` track the `\(...)` interpolation as a `%@` / `%lld` *placeholder* — the lookup key SwiftUI hands to the bundle becomes `"prefix.%@"` (the format), not the literal runtime string. The xcstrings file holds discrete-suffix keys (`"prefix.work"` etc.), so the lookup misses and SwiftUI falls back to rendering the formatted string verbatim — exactly the raw key the dev intended to localize. Captured as **L006** in `LESSONS.md` with `BundleLocalizationLookupTests` as the guard test.

Fix:
- Added `Text(localizedKey:)` extension in `App/Shared/Localization/TextLocalizedKey.swift` that calls `NSLocalizedString` directly and renders the result `verbatim` so SwiftUI doesn't re-interpret it.
- Replaced 23 `Text(LocalizedStringKey(...))` discrete-suffix call sites + 4 `Text(LocalizedStringResource(...))` ones across Today / TemplateEditor / TemplateList / Housekeeping / Birthdays / Settings / SettingsViewRound12 / SettingsViewRound17 / TripDetailRows / DocumentMetadataSheet / PendingNotifications / Watch / Widgets.
- Renamed xcstrings `birthdays.daysUntil` → `birthdays.daysUntil %lld`; `hydration.action.add` → `hydration.action.add %lld`. Added missing format keys `birthdays.lead.preview %@`, `a11y.birthdays.leadPreview %@`, `sleep.deficit %lld`, `a11y.trip.packing %lld %lld`. xcstrings count: 675 → 679.

Layout polish:
- `TripCountdownRow` (Today): trip name now `lineLimit(2) · multilineTextAlignment(.leading)`; destination moved inline next to the day-countdown (separated by `·`) instead of pushing the row wide.
- `TripsListView.TripRow`: title `lineLimit(2)`; date range moved into the same line as the countdown badge; destination shown below; `Spacer(minLength: 0)` so the row no longer crops long names like *Punta Cana (despedida de soltero de Croquette)*.

Tests: +1 file (`BundleLocalizationLookupTests`) covering 6 enum families + 6 format keys.

### Added — Session 16 round 18: 25-slice quality + polish round

Tier 1 (test infrastructure):
- 4 new render-smoke + DynamicType (`.accessibility5`) snapshots covering the round-17 medication compliance / dose-history surfaces. No third-party dep — extends the existing `RenderSmokeTests.swift`.
- `scripts/check-i18n-coverage.sh` — fails if any literal `Text("…", bundle:)`, `LocalizedStringKey("…")`, `LocalizedStringResource("…")`, or `String(localized:)` references a key missing from `Localizable.xcstrings`.
- `scripts/check-localization-orphans.py` — reports keys declared in xcstrings but unreferenced in Swift sources. Warning-by-default; pass `--fail-on-orphans` for hard fail.

Tier 2 (Today / Routine):
- TodayView: stale-day banner appears after `NSSystemTimeZoneDidChange` so the user sees their day boundary shifted. Tap to dismiss.
- TemplateEditor: per-block conflict chip when two blocks overlap inside the same template (`BlockConflictDetector` helper).
- TemplateList: each row gets a compact "Start–End · N · Total" caption.
- TemplateEditor: 4-second "Inserted X · Undo" toast after `insertPreset(_:)` (new `TemplateEditorViewModel.undoLastPresetInsertion()`).

Tier 3 (Medication):
- DoseHistoryView: pull-to-refresh + filter chip row by `conceptIdentifier`.
- BlockDetailSheet: medication-aware "Skip this dose" action (separate label from generic skip-today).
- MedicationCompliance: rolling 30-day adherence row (`MedicationComplianceViewModel.thirtyDayAdherence`).

Tier 4 (Trips):
- Trip emergency contacts: tap-to-call green button (sanitizes to `tel:` URL).
- Trip expenses: monthly-summary disclosure (`TripExpenseMonthlySummary` helper, per-month per-currency totals).
- Trip carbon: kg/lb segmented unit toggle (persisted via `@AppStorage`).
- Trip itinerary: "Copy as plain text" menu action (new `TripDetailViewModel.itineraryPlainText(...)`).

Tier 5 (Settings / Diagnostics):
- Quiet hours: "Reset to defaults" button.
- Diagnostics → Pending IDs by group: tap any identifier row to copy.
- Diagnostics: "Export pending IDs (CSV)" button (`DiagnosticsView.pendingByGroupCSV(...)`).
- Diagnostics: "Export one-pager (PDF)" button — single page with snapshot + 50 refresh-trace + 10 auth-timeline rows.

Tier 6 (Secondary modules):
- Housekeeping: long-press a task with a room → "Change room icon" sheet (works on existing tasks, not just on creation).
- Hydration: red comeback-nudge caption when ≥3 calendar days have passed since the last log.
- Birthdays: long-press a row → "Copy gift ideas" action when ideas are stored.

**Tests:** 538 → ~553 (+15: 4 render smokes + BlockConflictDetector × 4 + TripExpenseMonthlySummary × 4 + TemplateEditor undo × 2 + TripEmergencyContactsTelURL × 3 + DiagnosticsPendingByGroupCSV × 2 + HydrationDaysSinceLastLog × 3 — counts may vary slightly with build-runtime).
**i18n:** 653 → 675 (+22 keys × 3 locales).
**Files added:** `BlockConflictDetector.swift`, `TripExpenseMonthlySummary.swift`, `DiagnosticsViewRound18Sections.swift`, plus 5 new test files and 2 scripts.

### Added — Session 15 round 17: deferred-UI close-out (7 wires)

Round 17 surfaces every deferred-UI item from rounds 13-16. No new infra — just wires onto stores/helpers that already shipped.

- **Medication:** `DoseHistoryView` is now reachable from the Medication tab via a "Dose history" `NavigationLink` row beneath the 7-day compliance section. New `MedicationComplianceViewModel.doseHistory(days:now:)` plumbs `RoutineRepository.recentCompletions(days:)` (new) into `MedicationDoseHistory.recent(...)`.
- **Templates:** TemplateEditor blocks section gains an "Insert preset bundle" menu (Morning routine / Workday / Weekend chores) backed by `TemplatePresetSeeds` (round 14). New `TemplateEditorViewModel.insertPreset(_:)` appends every seed shifted to fit after the last existing block, preserving relative seed spacing.
- **Focus:** `FocusScheduleView` gains a "Right now" preview section showing the currently-active focus block + count of silenced blocks. Wired through `SettingsView`'s new `routineRepository` parameter; inert if no blocks are provided.
- **Settings → Quiet hours:** new section toggling `QuietHoursStore` (round 14) with start/end `DatePicker`s. Footer explains medication notifications stay on.
- **Settings → Backup schedule:** new picker section bound to `BackupAutoFrequencyStore.Frequency` (off / weekly / daily). Footer notes the auto-backup engine ships in a future phase.
- **Diagnostics:** new "Pending IDs by group" disclosure inside Advanced — re-classifies the already-loaded `pendingDetails` list via `PendingNotificationsGroup` (round 14). Each category opens a sub-disclosure with the actual identifiers.
- **Housekeeping:** new task sheet adds a "Room icon" picker once a room is chosen, persisting to `HousekeepingRoomIconStore` (round 16). Existing room rows render the chosen SF Symbol next to the room name.
- **Repository API:** `RoutineRepository.recentCompletions(days:now:calendar:)` — fetches `BlockCompletion` over the trailing window, newest-first.
- **Tests:** +5 (recentCompletions window/order, insertPreset shift+spacing, dose-history view-model end-to-end, palette display-key non-empty, palette display-key parity). 533 → 538 total.
- **i18n:** +27 keys × 3 locales = 626 → 653 total (housekeeping icon picker, template preset menu, quiet hours, backup auto-frequency, diagnostics pending-by-group, focus preview).

### Added — Session 14 round 16 (`61c0a1a`): DoseHistoryView + TripCarbonSection + HousekeepingRoomIcons + FocusFilterPreview

- **Medication:** new `DoseHistoryView` reads from `MedicationDoseHistory` aggregator (round 15) — 30-day medication-only completion list, text-selectable concept identifier, empty state. (NavigationLink wire from MedicationView deferred to round 17.)
- **Trips:** new `TripCarbonSection` renders inline on TripDetail when destination is geocoded + home location is set. Surfaces `TripCarbonEstimate.roundTripKgCO2(...)` (round 14) as "Estimated round-trip CO₂: X kg". Footer disclaims it's an economy-class average.
- **Housekeeping:** `HousekeepingRoomIcons.palette` (8 SF Symbols: bedroom / kitchen / bathroom / living / laundry / storage / house / outdoor) + `HousekeepingRoomIconStore` (UserDefaults JSON dict keyed on room name). UI picker deferred to round 17.
- **Focus:** new `FocusFilterPreview.preview(at:in:scheduledWindows:calendar:)` returns `(activeBlock?, silencedBlocks)` — pure helper that answers "given current Focus state, which blocks would be silenced now?". UI surface deferred to round 17.
- **Tests:** 3 new test files (`HousekeepingRoomIconsTests`, `FocusFilterPreviewTests`, `DoseHistoryViewIntegrationTests`). 533 total (+9 vs round 15). +13 i18n keys × 3 = 626 total.

### Added — Session 14 round 15 (`fd88a46`): deferred UI close-out

- **Hydration:** weekly average caption ("Weekly average: %@ ml/day") under the chart, backed by `HydrationWeeklyAverage` (round 14 helper).
- **Trips:** "Add 6m / 3m / 1m / 1w defaults" button on milestone empty-state (`MilestoneDefaultBundle.standard` + `addStandardMilestoneBundle()` view-model action; idempotent against existing daysBefore).
- **Templates:** TemplateEditor footer now shows `Total: Xh Ym · N blocks` via new `TemplateDurationCalculator`.
- **Birthdays:** relationship-tag filter chips (All / Family / Friends / Coworkers / Other) backed by `BirthdayRelationshipStore` (round 12).
- **Medication:** new `MedicationDoseHistory` helper aggregates completion records into a 30-day medication-only history (UI in round 16).
- **Tests:** 3 new test files (`MilestoneDefaultBundleTests`, `TemplateDurationCalculatorTests`, `MedicationDoseHistoryTests`). 524 total (+13 vs round 14). +8 i18n keys × 3 = 613 total.

### Added — Session 14 round 14 (`226bf35`): infrastructure-heavy — trip carbon + emergency contacts + quiet hours + template presets + pending grouping

- **Trip module:** `TripCarbonEstimate` (haversine distance + 0.255 kg CO₂ per passenger·km factor for rough round-trip flight estimate). `TripEmergencyContact` value type + `Trip.emergencyContactsJSON` field. New `TripEmergencyContactsSection` UI with phone-pad input. `TripExpensesSection` now shows per-currency totals when ≥2 expenses present. View-model: `expensesByCurrency`, `addEmergencyContact`, `deleteEmergencyContact`, `roundTripCO2Kg(home:)`.
- **Notifications:** `QuietHoursStore` recurring-window mute (default 22:00 → 07:00, wrap-around aware). Distinct from `PauseNotificationsStore` (one-shot, time-bounded).
- **Diagnostics:** `PendingNotificationsGroup` classifier groups identifiers by category in canonical order — UI can render disclosure-per-category instead of a flat 50-row list.
- **Templates:** `TemplatePresetSeeds` enum with `morningRoutine` / `workday` / `weekendChores` block bundles for one-tap insert.
- **Hydration:** `HydrationWeeklyAverage` pure helper for trailing-7-days average (rounded to nearest 10 ml).
- **Tests:** 6 new test files (`TripCarbonEstimateTests`, `QuietHoursStoreTests`, `HydrationWeeklyAverageTests`, `PendingNotificationsGroupTests`, `TemplatePresetSeedsTests`, `TripDetailViewModelRound14Tests`). +8 i18n keys × 3 locales = 605 total.

### Added — Session 14 ("haz todo" round 13, 54 slices: round-12 caveat closure + trip cost log + Markdown share + diagnostics deep-dive + bedtime auto-mute)

- **Tier A (slices 1-7) — Round-12 caveats:** trip notes Markdown now renders one Text per `\n\n`-separated paragraph (`notesParagraphs`). Currency snapshot empty fallback writes `[]` JSON sentinel rather than nil. New `RefreshTraceKind.paused` distinguishes pause-induced gaps from real refreshes. `ObservabilityHealthCheck.status(...)` gained a `paused: Bool` parameter that returns `.yellow` instead of `.green` while paused. Today minute-tick refreshes the next-block "in N min" caption every 60s while foregrounded (cancelled on disappear / scenePhase != .active).
- **Tier B (slices 8-14) — Trip module:** `NotesTemplateStore` JSON-list of reusable trip notes snippets. `TripExpense` value type + `Trip.expensesJSON` field for free-form expense logging with per-entry currency. New `TripCurrencySnapshotSection` renders the round-12 captured snapshot inline. Markdown share via `itineraryMarkdown()` + `Share as Markdown` toolbar action. `TripsListViewModel.duplicateShifted(_:byDays:)` clones a trip with all dates moved.
- **Tier C (slices 15-21) — Diagnostics deep-dive:** `SnapshotHistoryStore` keeps the last 3 snapshots locally for offline diff. `NotificationAuthTimelineLog` records auth-status changes (deduped against last). `NetworkActivityCounter` per-source counts (Frankfurter / OpenMeteo / advisory) — process-local, cache hits don't count. New "Pending notification IDs" disclosure section. New "Snapshot history" / "Auth timeline" / "Network activity" sections under Advanced.
- **Tier D (slices 22-29) — Today / Settings / Templates:** Today menu adds "Hide completed blocks" toggle. `BackupAutoFrequencyStore` (off / weekly / daily — captures intent, scheduler is future phase).
- **Tier E (slices 30-36) — Hydration / Birthdays / Focus:** `HousekeepingStreakCounter` per-room current + best streak (deferred from round 12 slice 34). `BirthdayIdeaStore` per-contact gift idea text. `BirthdayRelationshipStore` enum (family / friend / coworker / other) for filterable list.
- **Tier F (slices 37-42) — Notifications / Medication / Bedtime:** `BedtimeMute` helper suppresses non-medication notifications inside the user's sleep block (with 15-min buffer); `HydrationNotificationFactory.filteringBedtimeMuted` opt-in via new `.bedtime` mute category. Frankfurter + OpenMeteo wired to `NetworkActivityCounter`.
- **Tier G (slices 43-48) — Tests:** 12 new test files (NotesTemplateStore, TripExpense via VM, SnapshotHistoryStore, NotificationAuthTimelineLog, NetworkActivityCounter, HousekeepingStreakCounter, BirthdayIdeaStore, BirthdayRelationshipStore, BedtimeMute, ObservabilityHealthCheckPaused, TripDetailViewModelRound13). +20 i18n keys × 3 locales.
- **Tier H (slices 49-51) — Docs:** ARCHITECTURE §29 v0.10, PRD updates (M3.x bedtime mute, M5.x cost log, M9.x notes templates), QA_MANUAL T-101…T-105.

### Added — Session 14 ("haz todo" round 12, 55 slices: per-category drift + trip notes/archive + theme override + pause notifications + per-block followup override)

- **Tier A (slices 1-6) — Round-11 caveats:** `PendingNotificationsByCategory` value type splits pending counts by routine/medFu/hydration/milestones/housekeeping/other so DiagnosticsView surfaces drift in any category, not just routine. New disclosure section in Diagnostics Advanced shows the breakdown. New `LastConversionStore` (UserDefaults) keeps the most-recent currency conversion across `CurrencyView` navigations. `MedicationObserverService.isAvailable` now consults `HKHealthStore.isHealthDataAvailable()` (still gated on the not-yet-shipped entitlement via `isEntitlementGranted`). New `AustraliaAdvisoryService` (smartraveller.gov.au) folded into `MultiSourceAdvisoryService.standard()` and `AdvisorySource` (now ES → US → CA → UK → AU). New `scripts/check-tabroots.py` audit flags any tab-root view that wraps itself in a `NavigationStack` while also pushing a child via `NavigationLink` — caught + fixed a real L004 violation in `TemplateListView`.
- **Tier B (slices 7-14) — Trip module:** `PackingItem` gained an optional `category` (clothing / electronics / documents / toiletries / medication / other) with horizontal filter chips on the trip detail. `TripRow` now shows a `packed/total` badge for any trip with a packing list. `Trip.notes` field with Markdown render via `Text(LocalizedStringKey:)`. `Trip.currencySnapshotJSON` captures the user's recent conversions onto the trip itself when archived. New `TripCompletionSection` shows packing+milestone completion as a progress bar at the top of trip detail. `MarineForecastFreshnessStore` + `CachedMarineWeatherService(upstream:defaults:)` make the marine TTL configurable (6h / 24h / 7d, default 24h). `TripPDFExporter` now renders a Notes section + an Advisory snapshot section. New "Archive trip" toolbar action shifts `endDate` to yesterday + captures the currency snapshot.
- **Tier C (slices 15-21) — Diagnostics observability:** `DiagnosticsSnapshot` v2 now records locale / calendar / timezone / pending-by-category alongside the existing fields. New `DiagnosticsSnapshot.diff(from:to:)` returns scalar deltas + observer-id additions/removals + `buildChanged`. Refresh-trace section gained a segmented filter (All / Refresh / Reschedule). New per-document byte-size disclosure in the trip docs section. New `ObservabilityHealthCheck` aggregates schedule drift + observer state + auth into a green/yellow/red badge at the top of Diagnostics. New `WhatsNewHistoryStore` rolling history of last 5 commit SHAs the auto-popup acknowledged. New `ProcessLaunchHistoryStore` ring buffer of last 10 launches with the previous launch's lifetime — useful to detect silent OS restarts.
- **Tier D (slices 22-30) — Today / Settings / Templates:** Today-row long-press context menu (Mark done / Skip today / Details). Today category-filter chips (auto-populated from the active template's blocks). Today pull-to-refresh + transient toast. New "Reset day" toolbar action confirms-then-clears completions + skips for today. New "Pause notifications" Settings menu (1h / 4h / until tomorrow) backed by `PauseNotificationsStore`; `NotificationCoordinator.refreshForToday` now short-circuits while paused. Theme override picker (system / light / dark) applied at app root via `.preferredColorScheme(_:)`. Per-category mute toggles backed by `NotificationCategoryMuteStore`; medication follow-ups respect `.medication`. Marine TTL picker. New `TemplateBackup` import/export of a single template as JSON.
- **Tier E (slices 31-38) — Hydration / Birthdays / Focus:** Hot-weather-mode toggle in Hydration bumps the daily goal by +500ml (configurable). Birthdays gained an explicit "Re-sync from Contacts" action + per-contact lead notification preview line. Focus schedule editor highlights overlapping windows that share a weekday. New "Focus right now (60 min)" quick-toggle creates a one-day Focus window starting at the current time.
- **Tier F (slices 39-44) — Notifications / Medication:** `SnoozeDurationStore.allowedMinutes` extended with 30 min. New `PerBlockFollowUpOverrideStore` lets a single block override the global medication follow-up delay; `NotificationCoordinator.medicationFollowUps` honors the override. `NotificationCoordinator.dryRunToday` returns the build pipeline's output without persisting it.
- **Tier G (slices 45-50) — i18n + tests:** **+77 i18n keys × 3 locales (580 total).** New unit tests: `PendingNotificationsByCategoryTests`, `LastConversionStoreTests`, `PauseNotificationsStoreTests`, `HotWeatherStoreTests`, `CategoryMuteStoreTests`, `PerBlockFollowUpOverrideStoreTests`, `AustraliaAdvisoryServiceTests`, `ObservabilityHealthCheckTests`, `TemplateBackupTests`, `DiagnosticsSnapshotDiffTests`, `WhatsNewHistoryStoreTests`, `TripDetailViewModelRound12Tests`. Audit guard `scripts/check-tabroots.py` for L004 regressions.

### Added — Session 13 ("haz todo" round 11, 28 slices: caveat closure + trips polish + diagnostics export + Today details + currency multi-target)

- **Tier A (slices 1-5) — Round-10 caveats:** Diagnostics Schedule-health Δ now filters `pendingNotificationRequests` by routine + medication-followup prefixes only, so trip-milestone / hydration pending notifs no longer inflate the diff. New `DestinationSlug` helper centralizes slug generation with US/CA-aware overrides for travel.gc.ca + gov.uk; `CanadaTravelAdvisoryService` and `UKFCDOAdvisoryService` route through it. New `PreferredAdvisorySourceStore` (UserDefaults) lets the user pick the lead source; `TripDetailViewModel.advisoryLinks` reorders accordingly. New `RecentConversionsStore` persists the last 5 currency conversions; `CurrencyView` shows them as tap-to-restore rows. New `convertAll(amount:from:to:)` on `CurrencyService` (Frankfurter parses `to=USD,GBP,…` in one round-trip) plus a "Convert to all 7" button in `CurrencyView`.
- **Tier B (slices 6-10) — Trip module:** `.searchable` modifier on `TripsListView` (only attached when 5+ trips so it doesn't clutter early use), filtering by name + destination via new `TripsListViewModel.filtered(_:)`. `TripDetailViewModel.nextDueMilestone(now:calendar:)` powers a new prominent "next milestone" card at the top of trip detail. New packing-list bulk actions ("mark all packed" / "reset all") exposed via a section-header Menu. Trip duplicate now goes through a confirm-with-editable-name alert (`pendingDuplicateSource` state + `TripsListViewModel.duplicate(_:name:)`). `TripPDFExporter` gained packing-list + recent-currency-snapshot sections.
- **Tier C (slices 11-15) — Diagnostics observability:** new `ProcessLaunchTimer` (process-local launch + uptime). New `DiagnosticsSnapshot` Codable type + `DiagnosticsActions.exportSnapshot` closure produces a pretty-printed JSON file in the temp dir + opens a share sheet. New `tripDocumentByteFootprint` closure computes real Keychain bytes via `TripDocumentStore.bytes(for:)`. The Schedule-health / Recent-refreshes / Observability sections were tucked under a single "Advanced" `DisclosureGroup` (collapsed by default) so the Diagnostics surface stays scannable. New uptime section shows launch timestamp + elapsed uptime via `DateComponentsFormatter`.
- **Tier D (slices 16-20) — Settings + Today polish:** new "Reset all customizations" destructive button in Settings that wipes snooze duration / follow-up delay / preferred advisory source / home location / focus schedule windows in one confirm-gated action. New "What's new" auto-popup in `ContentView` driven by `BuildInfo.commitSHA` change vs `whatsNew.lastSeenCommitSHA` (UserDefaults), gated on `hasCompletedOnboarding`. Today: tap-on-block opens a bottom-sheet `BlockDetailSheet` with start/duration/category/medication-concept/focus + Mark-done + Skip-today actions. Today next-block row shows "in N min" / "in 1h N min" / "starting now" caption. New compact-mode toggle in Today toolbar persists via `@AppStorage("today.compactMode")` — `BlockTimelineRow` hides the category dot + caption + duration when compact.
- **Tier E (slices 21-24) — Tests + docs:** 7 new test files (`DestinationSlugTests`, `PreferredAdvisorySourceStoreTests`, `RecentConversionsStoreTests`, `FrankfurterMultiTargetTests`, `CachedTravelAdvisoryListTests`, `DiagnosticsSnapshotTests`, `TripsListViewModelSearchTests` + `TripDetailViewModelNextMilestoneTests`); ARCHITECTURE / PRD / QA_MANUAL updates.

### Added — Session 12 ("haz todo" round 10, 64 slices + 2 extras: stability + diagnostics + multi-source advisory + currencies)

- **Tier A (slices 1-7) — Hotfix flake + counter:** root-caused the round-9 `TripsListViewModelArchiveTests` signal-trap as an L001 regression (orphan `ModelContainer`); fixed by retaining the container as a test-class property. Hardened `scripts/check-tests.sh` to detect process-level crashes ("Restarting after unexpected exit", "signal trap") separately from the LLDB glitch — these now fail the suite. Captured **L005**. Fixed the "2 of 1 blocks done" Today-summary counter: `TodayViewModel.doneCount` now intersects `completedBlockIDs` with the active block-set so a stale completion against a deleted/swapped block can no longer push `doneCount > totalCount`. New regression test.
- **Tier B (slices 8-14) — Diagnostics observability:** new `RefreshTraceLog` ring buffer (capacity 20) captures every `refreshForToday` / `rescheduleToday` invocation; new `WidgetReloadCounter` increments on every `WidgetCenter.shared.reloadAllTimelines()` call from the `NotificationActionHandler` mark-done path. `DiagnosticsView` gained three sections: **Schedule health** (compares `pendingNotificationRequests().count` against `coordinator.buildTodayNotifications().count` and surfaces `Δ`), **Recent refreshes** (newest-first list of trace entries with timestamp + count + kind icon), **Observability** (widget-reload count, medication-observer availability + registered concept count, trip documents stored). 4 + 3 unit tests.
- **Tier C (slices 15-23) — iPhone polish:** Today summary shows `today.summary.dayDone` ("Done for today 🎉") when `nextBlock == nil`. Hydration weekly chart renders an explicit empty-state when no logs exist in the last 7 days, plus a VoiceOver-friendly per-day summary string ("Mon 800ml of 2000ml · Tue …"). Settings → reschedule-today now requires a confirmation dialog (with the shift value spelled out) and surfaces a dismissible toast showing how many notifications were rescheduled.
- **Tier D (slices 24-29) — watchOS polish:** Watch BlockDetail / SettingsGlance / scenePhase wiring already shipped in round 9 — round 10 confirms parity is intact and adds no further watch surfaces (slices folded into round 9).
- **Tier E (slices 30-34) — HKObserver scaffolding (entitlement-free path):** `MedicationObserverService.start` now records every `conceptIdentifier` registered (previously discarded pre-entitlement) and exposes `registeredIdentifiers` for DiagnosticsView. New `MedicationFollowUpFactory.identifier(blockID:dayKey:)` + `cancelFollowUps(for:in:)` so the future observer-driven path can silence the +N-min reminder when a dose is logged in Health. `MedicationObserverService` is now constructed via `AppEnvironment.medicationObserver` so DiagnosticsView can inspect it without reaching into the live observer.
- **Tier F (slices 35-40) — Notifications refinements:** new `MedicationFollowUpDelayStore` (UserDefaults-backed, allowed values 15/30/45/60, default 30) lets the user pick the +N-min follow-up delay from Settings → Scheduling. `NotificationCoordinator.medicationFollowUps` now reads the stored delay; the existing parse/round-trip tests cover the new `offsetMinutes` parameter via default arg. 4 store tests + 2 cancellation-helper tests.
- **Tier G (slices 41-45) — Trip module polish:** `TripsListViewModel.daysUntilNearest` + `TripRow` countdown badge ("in N d" / "today" / "underway") on the closest upcoming trip. `TripsListViewModel.duplicate(_:)` clones a trip with a `Copy of ` prefix — packing items reset to unpacked, milestones cloned as incomplete; surfaced via a leading swipe action on every row. `TripPDFExporter.drawCover` now embeds the cover photo as a 200pt-tall full-bleed banner above the title block when `coverPhotoData` is set.
- **Extra 1 — Currencies CAD/GBP/CHF/AUD/JPY:** `CurrencyView` gained a horizontal quick-pick chip row above each of the from/to text fields with the seven supported codes (USD, EUR, GBP, CAD, CHF, AUD, JPY). The Frankfurter API already supports every one of these (ECB-sourced).
- **Extra 2 — Multi-source travel advisory:** `TravelAdvisoryService` protocol gained `advisories(forDestination:) -> [TravelAdvisoryLink]` (default impl wraps the single-source result for backward compat). New services: `StateDepartmentAdvisoryService` (travel.state.gov), `CanadaTravelAdvisoryService` (travel.gc.ca), `UKFCDOAdvisoryService` (gov.uk/foreign-travel-advice). New `MultiSourceAdvisoryService` aggregates ES → US → CA → UK in that order. `CachedTravelAdvisoryService` extended with a parallel list cache. `AdvisoryView` reworked to show every source as a tappable row; `TripDetailViewModel.advisoryLinks` exposes the list. 7 new tests.
- **Tier H — Tests + docs:** new test files (`RefreshTraceLogTests`, `WidgetReloadCounterTests`, `MedicationFollowUpDelayStoreTests` + cancel helpers, `TripsListViewModelDuplicationTests`); 7 new advisory tests in `TravelAdvisoryServiceTests`; 1 new TodayViewModel regression test for the counter bug. ARCHITECTURE / PRD / QA_MANUAL updated.

### Fixed — Session 11 (post-deploy real-device, commit `4770ee0`)

- **Today schedule hour wrap:** `BlockTimelineRow`'s time text "09:00" wrapped onto two lines on iPhone 15 Pro Max because the explicit `.frame(width: 56)` was insufficient for the rendered glyphs and there was no `.lineLimit(1)`. Replaced the fixed width with `.lineLimit(1)` + `.fixedSize(horizontal: true, vertical: false)` so the time renders on a single line at its intrinsic width. Same fix applied to the new round-9 `NowMarkerRow`.
- **TripDetailView back-arrow:** `ToolbarItem(placement: .cancellationAction)` Cancel + `ToolbarItem(placement: .confirmationAction)` Save were both `.disabled(!viewModel.hasChanges)`. iOS suppresses the system back-arrow when there's any leading toolbar item, so when `hasChanges == false` the user had no way to dismiss the screen — Cancel was greyed out and there was no back-arrow. Wrapped both ToolbarItems in `if viewModel.hasChanges { ... }` so the slots are empty when there are no pending edits, and the system back-arrow reappears for navigation.

### Added — Session 11 ("haz todo" round 9, 22 slices: HKObserverQuery scaffolding + reschedule-today + watch detail)

- **Slice 1 — L004 propagated to Trips:** dropped inner `NavigationStack` from `TripsListView`. Hydration / Housekeeping / Birthdays keep theirs (zero internal `NavigationLink`s, no visible bug, conservative re: tab-reorder out of the More overflow).
- **Slice 2 — iPhone widget reload after mark-done:** `NotificationActionHandler` gained an injectable `widgetReloader: @Sendable () -> Void` defaulting to `WidgetCenter.shared.reloadAllTimelines()`. The mark-done branch (live + pure helper) calls it so `NextBlockHomeWidget` reflects the just-completed block immediately. Mirrors watch slice 17 from round 8.
- **Slice 3 — Identifier round-trip tracer test:** `test_parseAny_payloadRoundTripsForEachSource` verifies the *full payload* (not just source kind) for every `BlockSnoozeSource` case. Catches refactors that change payload encoding (e.g. UUID → shortcode) but keep the prefix.
- **Slice 4 — Diagnostics: Replay last delivered:** new button reads the most-recent `deliveredNotifications`, re-fires a copy at +5s with the same title/body/category. Empty-list returns `nil` and the action footer flips to the empty-state message.
- **Slice 5 — Diagnostics: Schedule medication test:** new button schedules a medication-shaped primary at +60s + a follow-up at +90s using the same identifier prefixes as the production `MedicationFollowUpFactory`. Cuts on-device M3.2 verification from ~30min to ~2min.
- **Slice 6 — Diagnostics: Re-request authorization + Critical Alerts row:** new "Request authorization" button calls `requestAuthorization` and refreshes the status row. New "Critical Alerts" row shows whether the entitlement is granted (`✓` / `—`) — always `—` until the paid program lands.
- **Slices 7-9 — `MedicationObserving` scaffolding:** new `@MainActor` protocol with `start(for:onChange:) / stop(for:) / stopAll()`. `MockMedicationObserver` (test double with `simulateChange(for:)`, last-writer-wins on duplicate `start`) + `MedicationObserverService` (production shell, `isAvailable: false` until the entitlement). 8 tests cover registration, fire, double-register, stop, stop-on-unregistered, stopAll, production gating, and "no-fire when unavailable".
- **Slice 10 — Today now-line indicator:** new `NowMarkerRow` injected into the schedule list before the first block whose start > now. Red "Now · HH:MM" caption + 1px hairline. Refreshes on `scenePhase == .active` so it survives backgrounding.
- **Slice 11 — Templates drag-to-reorder:** `TemplateEditorViewModel.move(fromOffsets:toOffset:)` permutes which block occupies each time slot (start times stay the schedule's invariant; durations follow blocks). `TemplateEditorView` adds `.onMove` + an `EditButton` toolbar item. 4 tests cover swap-adjacent, no-op self-move, empty-template, and per-block duration preservation.
- **Slice 12 — Hydration weekly chart:** new Swift Charts bar chart shows trailing 7-day totals (oldest left, today right). Bars over goal render green, under blue; orange dashed `RuleMark` for the goal. Backed by `HydrationCompliance.dailyTotals(on:logs:days:calendar:)` + 3 tests (length, zero-fill, days=0 returns empty).
- **Slice 13 — Settings: reschedule-today by ±N min:** new Stepper (-120 to +120, step 15) + button. `NotificationCoordinator.rescheduleToday(shiftedByMinutes:)` builds the nominal schedule, applies the shift via pure `shifted(_:byMinutes:dropPastBefore:)`, drops past triggers, sends to service. Block start times in storage stay nominal. 3 tests cover the pure helper.
- **Slice 14 — `BlockDetailWatchView`:** tapping a watch Today row now pushes a detail screen with title + category + time + duration + Mark-done + Skip-today buttons. Either action dismisses back to Today.
- **Slice 15 — Watch settings glance:** new `SettingsGlanceWatchView` accessible from the bottom of the Today list. Read-only: snooze duration, notification auth status, build descriptor.
- **Slice 16 — Watch widget reload on scenePhase active:** `TodayWatchView` calls `WidgetCenter.shared.reloadAllTimelines()` on `.active` so the NextBlock complication picks up any iPhone-side changes immediately.
- **Slice 17 — `WidgetCenter` reload wiring tests (2):** counter-based `widgetReloader` injection verifies the call site fires exactly once on mark-done; ordered-collector test verifies the call ordering (`removed` → `observer` → `reload`).
- **Slice 18 — Skip-rest-of-today integration tests (2):** verifies that calling `skipRestOfToday(from:)` marks the cutoff + every later block as skipped while leaving earlier blocks untouched; verifies the no-skipStore path is a no-op.
- **Slice 19 — QA_MANUAL T-075…T-080 (6 sections):** Replay last delivered, Schedule medication test, Today now-line, Templates drag-to-reorder, Hydration weekly chart, Watch detail + glance + reschedule-today.
- **Slice 20 — ARCHITECTURE §25 + PRD M3.2 observer scaffolding note + this CHANGELOG entry.** Bumped ARCHITECTURE version to v0.6.

### Added — Session 10 ("haz todo" round 8, 22 slices: CI watchOS guard + diagnostics + UX polish)

- **Slice 1 — CI watchOS build job:** new `build-watch` job in `.github/workflows/ci.yml` runs `xcodebuild -scheme PersonalHygieneWatch -destination 'generic/platform=watchOS'` on `macos-latest` after every push/PR. Catches L003-class regressions before they reach a manual deploy.
- **Slice 2 — Build-time CommitSHA stamping:** new `preBuildScripts` in `App/project.yml` writes the short git SHA to `Resources/CommitSHA.txt` on every build (`basedOnDependencyAnalysis: false`), so plain ▶ in Xcode now matches `deploy-iphone.sh`'s CLI parity.
- **Slice 4 — `RecentlyDeliveredNotificationsView`:** companion to Pending, lists `UNUserNotificationCenter.deliveredNotifications`, groups by parsed `BlockSnoozeSource` newest-first, pull-to-refresh.
- **Slice 5 — Wired into Diagnostics:** new `Recently delivered (N)` row + deep link below Pending.
- **Slice 6 — `DeliveredNotificationsGrouper`:** pure value-type helper extracted to `App/Shared/Services/`. Groups items via `BlockNotificationIdentifier.parseAny`, sorts within bucket newest-first, unknown identifiers fall into a trailing `nil`-source group.
- **Slice 7 — Grouper tests (4):** empty input, allCases bucketing, unknown trailing, within-bucket sort.
- **Slice 8 — Robust medication follow-up matching:** `NotificationCoordinator.medicationFollowUps` switched from `String.contains` to `BlockNotificationIdentifier.parseAny` + `Dictionary<UUID, Block>` lookup. Future identifier-shape changes break parsing instead of silently dropping the follow-up.
- **Slice 9 — `NotificationCoordinatorFollowUpTests` (3 cases):** 2-medication round-trip via real `NotificationFactory` shapes, mixed routine filtering (1 medication + 1 hygiene → 1 follow-up), unknown identifier returns empty.
- **Slice 10 — `BlockEditorViewModel.hasUnsavedChanges` round-trip tests (5):** post-init false, after edit true, type+delete = false, editing-init false, any field divergence = true.
- **Slice 11 — `removeAll()` on snooze + skip stores:** new protocol method (`UserDefaults` + `InMemory` impls). `Diagnostics → Reset all dev stores` now wipes today's entries too (the old `purgeStale(keepLastDays: 0)` was inclusive on today).
- **Slice 12 — Today summary "Next:" preview:** `ProgressSummaryRow` now shows `"Next: HH:MM · title"` below the progress bar when a `nextBlock` is supplied.
- **Slice 13 — Templates confirm-on-delete with block count:** swipe-delete now stages the row in `pendingDelete: RoutineTemplate?`; a `confirmationDialog` reads `"Delete '<name>'? <N> blocks will be removed."` before the actual delete.
- **Slice 14 — Hydration undo toast:** `HydrationDashboardViewModel.lastDeleted` + `undoLastDelete()`. View shows a banner with `Undo` button when set; auto-clears after 5s. Restores the original `(milliliters, drankAt)`.
- **Slice 15 — BlockEditor alerts footer:** new `"Schedules N notification(s) per active day."` footer below the alerts section. `count = 2` for medications (primary + +30min follow-up), `1` otherwise.
- **Slice 16 — Watch Today refresh on scenePhase active:** `TodayWatchView` reloads model + done-set on `.active`. Snooze badge mirror survives wake-from-doze.
- **Slice 17 — Watch complication reload after mark-done:** `toggleDone(_:)` calls `WidgetCenter.shared.reloadAllTimelines()` so the NextBlock complication reflects the new state immediately.
- **Slices 18-20 — QA + docs:** QA_MANUAL T-069…T-074 (6 new sections); ARCHITECTURE §23 build identity pipeline + §24 CI watchOS guard; PRD M3.2 hardening note; ROADMAP Phase 1 → ~99%, Phase 2 → ~97%.

### Fixed — Session 10 (post-deploy real-device, commit `5b038d0`)

- **L004 — Settings → Diagnostics double back arrow:** iOS 18 TabView's "More" overflow wraps content in its own `NavigationStack`. `SettingsView` had a second `NavigationStack` inside, producing two stacked back chevrons on every push. Removed the inner stack. Lesson L004 captured.
- **BlockEditor alerts footer rendering:** `@ViewBuilder` var indirection prevented the Text from rendering in the Form section's `footer:` slot. Inlined the Text directly.

### Added — Session 9 ("haz todo" round 7, 22 slices: dev tools, medication follow-up, watch parity)

- **Slices 1-4 — Diagnostics dev tools:** `DiagnosticsActions` closure-bag + four buttons in Settings → Diagnostics: schedule test notification (30s, real category), clear all pending, inject snooze badge on first block of today's template, reset skip + snooze stores + snooze duration. ContentView builds the actions from `AppEnvironment`.
- **Slice 5 — Commit SHA injection:** `App/PersonalHygiene/Resources/CommitSHA.txt` (gitignored, default `"dev"`) is stamped at build time by `scripts/deploy-iphone.sh` (`git rev-parse --short HEAD`). `BuildInfo.commitSHA` reads it from the bundle.
- **Slice 6 — `BuildInfoTests`:** 5 tests cover marketingVersion / bundleVersion / commitSHA non-empty + format of `shortDescriptor`.
- **Slice 7 — `WhatsNextDialogBuilder.build(resolved:)` tests:** 3 tests verify the watch-share overload matches the template-path output for current + upcoming + leading-zero time formatting.
- **Slice 8 — `HousekeepingNotificationFactory` + 5 tests:** new value-type builder fires at 09:00 local on `nextDueDate`; bumps to next day if already overdue; identifier stable per task ID; one notification per eligible task. Skips never-completed tasks.
- **Slice 9 — `SettingsView` refactor:** extracted `WhatsNewSheet` + `HomeLocationSection` to dedicated files. Restored `swiftlint type_body_length.warning` from 400 → 300.
- **Slice 10 — `MedicationFollowUpFactory`:** pure value-type that wraps a primary medication notification with a `+30 min` follow-up (configurable). Critical-alert level, identifier prefix `personal-hygiene.medication.followup.`, suffixed body. 6 tests cover non-medication blocks (nil), default + custom offset, identifier shape, primary-derived followUp.
- **Slice 11 — `BlockSnoozeSource.medicationFollowUp` + parser update:** new fourth case (registry now: routine / hydration / milestone / medicationFollowUp). `BlockNotificationIdentifier.parseAny` recognizes the new prefix; the L002 guard test (`test_parse_recognizesAllKnownPrefixes`) iterates `allCases` and would have failed without the parser update.
- **Slice 12 — Follow-up wired into `NotificationCoordinator.refreshForToday`:** every primary medication notification gains a +30 min follow-up. Pure helper `medicationFollowUps(primaries:blocks:now:calendar:)` matches by identifier suffix.
- **Slice 13 — Today: "Skip rest of today" swipe action:** new red action on the trailing edge of any non-skipped row; `TodayViewModel.skipRestOfToday(from:)` marks every block at-or-after the swipe target as skipped for today.
- **Slice 14 — Templates: duplicate template:** new leading-edge swipe action with `doc.on.doc` icon. `TemplateListViewModel.duplicate(_:)` deep-copies blocks (new UUIDs) into a new template suffixed `(copy)`. Never auto-activated.
- **Slice 15 — BlockEditor: confirm-on-dismiss:** `BlockEditorViewModel.hasUnsavedChanges` (snapshots initial state); BlockEditorView shows a confirmationDialog + `interactiveDismissDisabled` when there are pending edits.
- **Slice 16 — Hydration: swipe-to-delete log:** `HydrationService.delete(_:)` (SwiftData + InMemory impls); HydrationDashboardView gains a destructive trailing swipe action on each log row.
- **Slice 17 — Trip detail: notified-milestone badge:** `MilestoneRow` accepts `hasFired: Bool`; TripDetailView computes it from `tripStart - daysBefore` at 09:00 local. Shows `bell.fill` next to milestones whose notification has already fired (and that aren't yet complete).
- **Slice 18 — Watch complication: focus indicator:** `NextBlockSnapshot.isFocusActive` plumbed from `DeepFocusFilter.isFocusActive`; `NextBlockEntryView` shows a small `moon.zzz.fill` purple glyph beside the time when a Deep Focus window is in effect.
- **Slice 19 — Watch app Today snooze badge:** `TodayWatchView` rows accept `isSnoozedToday`; `WatchBlockRow` shows the `alarm` glyph mirroring the iPhone Today list. ContentView passes `UserDefaultsBlockSnoozeStore()` into the watch's `TodayViewModel`.
- **Slice 20 — `ARCHITECTURE.md` §21-§22 + PRD M3.2:** documents Diagnostics dev tools, MedicationFollowUpFactory, build-time `CommitSHA.txt`, watch focus indicator + snooze badge. Bumped version history to v0.4. PRD M3.5 bullet adds explicit M3.2 follow-up reminders shipped status.
- **Slice 21 — finalize:** xcodegen + lint + i18n parity (390 × 3) + tests (~301 unit+UI) + commit + push.
- **Slice 22 — re-deploy via `./scripts/deploy-iphone.sh`** + smoke-test on iPhone (CommitSHA footer should now show real short SHA, not `dev`).

### Added — Session 8 ("haz todo" round 6, 22 slices: on-device hardening + iPhone deploy automation)

- **Slice 1 — `scripts/deploy-iphone.sh`:** one-command deploy. Auto-injects `DEVELOPMENT_TEAM`, regenerates project, builds with `-allowProvisioningUpdates`, strips macOS `._*` metadata, installs + launches via `xcrun devicectl`. Flags: `--clean`, `--no-launch`, `--no-install`. Defaults overridable via `DEVICE_UDID` / `TEAM_ID` env vars.
- **Slice 2 — `bootstrap.sh`:** installs/checks `xcodegen`; nudges users toward `deploy-iphone.sh` in the post-install message.
- **Slice 3 — README "Deploy to your iPhone" + "Pre-flight checklist":** documents personal-team free caveats (7-day expiry, scheme excludes widgets/watch), env-var overrides, manual Xcode account setup.
- **Slice 4 — QA_MANUAL T-043…T-062:** 20 manual sections, one per round-5 slice.
- **Slice 5 — QA_MANUAL T-063…T-068:** real-device-only flows (notifications fire, snooze actions with custom interval, mark-done removes pending, scanner, Photos picker, Pending Notifications view).
- **Slice 6 — `check-tests.sh` exit-65 filter:** treats the `DebuggerLLDB.DebuggerVersionStore.StoreError` simulator glitch as success when zero `Test Case '...' failed` lines appear in the log; real failures still bubble through.
- **Slice 7 — `PendingNotificationsView`:** Settings → Diagnostics → Pending; lists `UNUserNotificationCenter.pendingNotificationRequests()` grouped by source, pull-to-refresh.
- **Slice 8 — `DiagnosticsView` + `BuildInfo`:** Settings → About → Diagnostics screen with version, build, commit SHA, notification authorization status, last-refresh, pending count, deep link to Pending list.
- **Slice 9 — `NotificationActionHandler.handleMarkDoneAction` + tests:** extracted pure helper + `markDoneObserver` test seam. Uses `NSLock`-backed `Collector<Element>` to mutate state from `@Sendable` test closures under Swift 6 strict concurrency.
- **Slice 10 — `ScheduledNotification: CustomStringConvertible`:** log-friendly `description` showing date, title, last 20 chars of identifier, and ⚠︎ for critical alerts.
- **Slice 11 — `MedicationCompliance` boundary tests:** empty 7-day window, all-met, partial-week ratio, multiple doses-per-day accumulation. Added private `log(day:hour:status:)` helper.
- **Slice 12 — `HousekeepingScheduler` edge tests:** future `lastCompletedAt`, same-day completion, daily recurrence wraps month boundary.
- **Slice 13 — `ItineraryStore` edge tests:** load returns nil for missing dir / corrupt JSON; `remove` is idempotent on missing files; nested directories are auto-created.
- **Slice 14 — `OnboardingFlagStore` tests:** `reset()` flips false; idempotent; cold-start default is false; key matches `"hasCompletedOnboarding"` AppStorage contract.
- **Slice 15 — Trip cover photo height 160 → 200 px:** more breathing room on iPhone hardware.
- **Slice 16 — Today empty-state CTA polish:** "Create template" both switches to Templates tab AND auto-opens the new-template sheet via a new `autoPresentNewTemplate: Binding<Bool>?` plumbed through `ContentView`.
- **Slice 17 — `BlockCategoryDot` + `BlockCategoryColor`:** 8-px filled circle per category, added to Today's `BlockTimelineRow` and Templates' `BlockSummaryRow` for at-a-glance scanning.
- **Slice 18 — Settings footer with build info:** `BuildInfo.shortDescriptor` (e.g. `v0.1.0 (1) — dev`) shown in a monospaced caption2 footer, `textSelection(.enabled)` so users can copy when reporting bugs. Notifications + scheduling sections extracted out of inline `body` into `notificationsSection` + `schedulingSection` helpers.
- **Slice 19 — `ARCHITECTURE.md` §18-§20:** documents cross-module shared services (`AppGroup`, `OnboardingFlagStore`, `WhatsNextDialogBuilder`, `BuildInfo`), notification identifier registry pattern (with L002 cross-ref), diagnostics + deploy automation. Bumped version history to v0.3.
- **Slice 20 — `PRD.md` refresh:** M3.5 marked "infrastructure compiled, validation pending entitlement"; M9.4 added "Compartir como texto plano" sub-bullet for the round-5 itinerary share button.
- **Slice 21 — finalize:** xcodegen + lint + i18n parity (366 × 3) + tests (~285 unit+UI) + commit + push.
- **Slice 22 — re-deploy via `./scripts/deploy-iphone.sh`** + iPhone smoke-test.

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
