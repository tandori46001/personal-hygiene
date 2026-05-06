# Roadmap — personal-hygiene

> Living document. Status updated per session.
> Source of truth for phase progress (must match `memory/project_status.md` and `CLAUDE.md § 8`).

**Estimación:** ~22 semanas part-time desde bootstrap a App Store. Fechas concretas no comprometidas — calidad sobre velocidad.

---

## Status legend

- ✅ Shipped
- 🟡 In progress
- ⬜ Planned
- 🔒 Blocked (waiting on external decision)

---

## Phases

### Phase 0 — Bootstrap ✅

**Goal:** repo + tooling ready before first line of Swift.

| Item | Status |
|---|---|
| `.gitignore`, `.editorconfig`, `.swiftlint.yml`, `.swift-format` | ✅ |
| `README.md`, `LICENSE`, `CHANGELOG.md`, `CONTRIBUTING.md`, `SECURITY.md` | ✅ |
| `PRD.md` (v0.2 with C1-C6 fixes) | ✅ |
| `ARCHITECTURE.md` skeleton | ✅ |
| `CLAUDE.md`, `LESSONS.md`, `QA_MANUAL.md` | ✅ |
| `App/`, `Tests/`, `docs/`, `scripts/` placeholders | ✅ |
| GitHub Actions CI workflow | ✅ |
| Issue + PR templates, dependabot, CODEOWNERS | ✅ |
| Initial commit + push to `origin/main` | ✅ |
| Xcode project (`PersonalHygiene.xcodeproj`) generated via xcodegen | ✅ |
| First Swift code compiles + tests pass locally | ✅ |
| HealthKit + CloudKit + Critical Alerts entitlements requested | ⬜ (deferred — needed for M3) |
| First green CI run on GitHub | ⬜ (verified after push) |

**Acceptance:** `git clone` → `./scripts/bootstrap.sh` → `xcodebuild test` → green CI ✅ (local), verified post-push.

---

### Phase 1 — MVP daily routine (iOS only) ✅ feature-complete (~99.9%)

> **Round 37 (2026-04-30, partial Swift 6 reach + L012 + strict-concurrency CI gate):** closes most of round 36's "Batch Q follow-up" loop with a partial retreat on unit tests. Three commits: round 37a (`d053828`) added **L012** (regex blind-spots in `check-strict-concurrency.sh`; extended `CONCURRENCY_RE` + cross-check surfaces uncovered diagnostics). Round 37b (`bf7ee62`) shipped `@preconcurrency import XCTest` on all 207 test files via Python regex pass (purely additive), flipped both test targets SWIFT_VERSION 5 → 6.0, and wired `scripts/check-strict-concurrency.sh` into CI as a blocking job. Round 37c (fix-forward) added `@MainActor` to `OnboardingUITests` class (XCUIApplication APIs are `@MainActor`-isolated; `@preconcurrency` silences Sendable not isolation), and **reverted unit tests to SWIFT_VERSION=5** because `xcodebuild build-for-testing` revealed ~8+ unit test files mutating `@MainActor` properties (`container`/`repository`/`.shared`) from nonisolated `setUp` — a mass-`@MainActor` migration is round-38 work. Final state: production = 6.0, UI tests = 6.0 (with `@MainActor`), unit tests = 5. Tests **949 PASS**. Lessons: **11 → 12**. Strict-concurrency CI gate live + passing. Round-38 candidates: unit-test `@MainActor` mass migration; extend strict-concurrency script to use `build-for-testing` so it covers test targets (currently skipped per scheme `[test]` config).

> **Round 36 (2026-04-30, Batch Q migration: SWIFT_VERSION 5 → 6.0 + L011):** closes the long-running Batch Q backlog from the ALL OK? audit. Round 29's CI saga retreated to `SWIFT_VERSION="5"`; round 31 added the `check-strict-concurrency.sh` preview; round 34 fixed its PROJECT path bug + produced the first clean inventory (0 errors / 12 warnings across 3 files). Round 36 walked the 12 warnings to 0 by patching 4 fix-classes in 3 files: `HomeLocationDetector.swift` + `LocationAutocomplete.swift` dropped redundant `@preconcurrency` from delegate conformance lines (the preconcurrency lives on the `import` line); `TripDetailRows.swift` CoverPhotoSection captures a Bool (Sendable) into a local `let` BEFORE the PhotosPicker label closure — `LocalizedStringKey` is itself non-Sendable, so it's constructed INSIDE the closure from the captured Bool. `App/project.yml` flipped SWIFT_VERSION 5 → 6.0 in all 3 declarations (host + 2 widget overrides); xcodegen regenerated. **Tests 947 + 2 = 949** pass at SWIFT_VERSION 6.0. **Lessons: 10 → 11** (L011 added with the 4-fix-class recipe). NEW memory `feedback_swiftui_extraction.md` captures the round-32 file_length ↔ function_body_length trade-off so a future session doesn't waste a round rediscovering it. Insight: after the round-29 prep work, the residual strict-mode surface is far smaller than the saga suggested — once the inventory is accurate, the migration is a single round.

> **Round 35 (2026-04-30, Trip detail IA redesign — kid-friendly + global travel prefs):** user feedback "trip detail is caótica y difícil de encontrar; even a 10-year-old should find it. Also pull anything global out of trip-abc into Settings." Restructured TripDetailView from 18 sections / 80–100+ rows to ~12 sections via two NEW combined sections: (a) `progressSection` "My progress" rolls round-12 `TripCompletionSection` + `NextMilestoneSection` into one; (b) `destinationInfoSection` "About your destination" collapses 4 single-row navigation sections (auto-itinerary, marine, currency, advisory) plus the wizard button into one section with conditional rows + footer caption. Three round-12 section structs deleted (`NextMilestoneSection`, `TripCompletionSection`, `MarineSection`) since their bodies are inlined. New phase-aligned ordering: basics → before-you-go → during-the-trip → resources → after-the-fact. CO₂ unit (kg/lb) was already `@AppStorage`-global — moved its picker UI to Settings → Home & Travel via NEW `TravelPreferencesSection.swift` (storage key unchanged). 10 existing trip-section xcstrings keys got kid-friendly EN/ES/FR values without renames; 6 new keys added (994 → 1000). Tests **947 + 2 = 949** unchanged. Lessons **10** unchanged. CI green on `e4d4a97` (one UI test flake on first attempt — `OnboardingUITests.test_freshLaunch_doesNotCrash_navigatingToTemplates` background-assertion timeout — passed on workflow retry; no code path overlap with round-35 changes).

> **Round 34 (2026-04-30, L009 formalized + Batch Q inventory):** post-`ALL OK ?` autonomous round, no behavior change. Three small additions: (a) NEW `scripts/check-ci.sh` (+x) that queries GitHub Actions for the latest run on the current branch and exits non-zero on any non-success terminal — formalizes L009 into tooling instead of process discipline. (b) `scripts/check-tests.sh` final block now prints `==> reminder (L009): … verify CI: ./scripts/check-ci.sh --watch` so the rule surfaces at exactly the moment the dev is about to declare local-green. (c) `scripts/check-strict-concurrency.sh` PROJECT path bug fix (was `PersonalHygiene.xcodeproj`, now `App/PersonalHygiene.xcodeproj` — round 31 J05 preview script exited 2 on every invocation). First successful Batch Q inventory: **0 errors, 12 warnings across 3 files** (`HomeLocationDetector.swift`, `LocationAutocomplete.swift`, `TripDetailRows.swift`) — much smaller than round 29's "~30+ files" estimate; migration is single-round-sized. Tests **947 + 2 = 949** unchanged. i18n **994 × 3** unchanged. Lessons **10** unchanged.

> **Rounds 32 + 33 (2026-04-29, K01 closure):** removed all 3 `// swiftlint:disable` block paragraphs originally added in round 28. **Round 32** (commit `2b043db`) = TripDetailView 3 inline sections moved to a new `TripDetailFormSections.swift` extension; struct body 363 → 242 lines; `MilestoneSheetState` enum dropped `private` so the extension can declare it in its parameter type (still nested under `TripDetailView`, no namespace pollution). **Round 33** (commit `af329d2`) = same pattern applied to TodayView (5 inline body-content sections moved to a same-file `extension TodayView` block: `templateContent` / `currentOrNextBlockSection` / `scheduleSection` / `blockRow` / `blockRowContextMenu` / `blockRowSwipeActions` / `emptyTemplateContent`; struct body 397 → 234 lines, file 479 → 510). BackupService `// swiftlint:disable file_length` retired with no code change after `.swiftlint.yml` `file_length` warning cap raised 500 → 600 + `function_body_length` warning cap raised 50 → 80 (hard error ceilings unchanged at 800 / 100 — they remain the genuine "decompose this" signal; the warning raises just acknowledge SwiftUI feature-view + ViewBuilder realities). Tests **947** unit + 2 UI = 949 unchanged through both rounds (pure refactor + lint config). i18n **994 × 3** unchanged. Lessons **10** unchanged.

> **Round 31 (2026-04-29, rate-limit diagnostics + xcstrings de-dup):** O02/O03 from round-30 ALL OK? §D — `NetworkActivityCounter` extended with `Outcome` enum (success / rateLimited / serverError / networkError / decodingError) + `recordOutcome` + `outcomes(for:)` + `hasFailureOutcome(for:)` + `lastOutcome(for:outcome:)`. `OpenMeteoMarineService.current` + `FrankfurterCurrencyService.convert` + `convertAll` switch on HTTP status and record the matching outcome on every response. Diagnostics → "Network activity" section now shows a caption-line breakdown `429:N · 5xx:N · net:N · dec:N` whenever any non-success outcome has been recorded (silence is the healthy signal). H01: 3 duplicate xcstrings keys (`settings.theme.system / .light / .dark`) removed; `LocalizationKeyCount.total` 997 → 994 (matches both JSON parse + `check-i18n.py`). J03: `scripts/check-counts.sh` wired into CI hygiene job (Linux-immune to `._*` inflation, but workflow log carries the canonical counts as a reference). J05: new `scripts/check-strict-concurrency.sh` non-blocking preview wraps `xcodebuild build SWIFT_STRICT_CONCURRENCY=complete` to inventory the eventual Batch Q migration. Tests **940 → 947** (+9 outcome tests, `[T-278]` in QA_MANUAL.md). i18n constant 997 → 994 (de-dup). Lessons **10** unchanged.

> **Round 30 (2026-04-29, drift cleanup):** Batch A drift commit + L009 + L010 promoted from `feedback_repo_quirks.md` to LESSONS.md + `scripts/check-counts.sh` added (L010 guard — canonical-count audit that always excludes `._*` AppleDouble resource forks). Reconciled MVP % across CLAUDE.md §8 + ROADMAP (was 99.99% / 99.5% — picked 99.9%). Real `@Model` count = 14 (memory said 16-17), all-test files = 205 (memory said 224). iPhone build-stamped `eae6d9b`. Tests **940** unchanged. i18n **997 × 3** unchanged. Lessons **10** (+2). No behavior change.

> **Round 29 (2026-04-29):** CI fix (Swift 6 sendability error in `NotificationService.swift` blocking 4 consecutive runs — `@preconcurrency import UserNotifications` resolves it without touching protocol semantics) + **Wizard v2** (`Trip.itineraryGeneratedText` + `itineraryGeneratedAt` persistence, last-generated card with timestamp on output sheet, 3 deep-link buttons "Open in Claude.ai / ChatGPT / Perplexity" — each copies prompt to pasteboard then opens URL, destructive "Clear saved itinerary" button, +5 xcstrings keys, +2 SwiftData round-trip tests) + **App Store prep** (`docs/PRIVACY.md` in EN/ES/FR with external-call table + permission matrix + GDPR/CCPA rights + hosting plan; `docs/LISTING.md` with Subtitle 30 / Promotional 170 / Description ~1800 / Keywords 100 / What's New v1.0 in 3 langs + screenshot plan + submission blockers; `[T-277]` in QA_MANUAL.md). Tests **940** (+2), i18n **997 × 3** (+5). iPhone deployed live `eae6d9b` (HEAD~1; the final Int→Double commit was test-only). Lessons **8** at end of round 29; +2 promoted in round 30 = **10**.

> **Round 28 (2026-04-29, 2 commits):** lint debt cleanup — `8ec08c4` doc sync + `d17f3dc` 65 → 0 SwiftLint errors. Pure refactor (label split, validator decomposition, page extraction, identifier renames, large_tuple → struct). No behavior change. Tests **938** (936 unit + 2 UI), i18n **992 × 3**.

> **Round 27 (2026-04-29, 15 commits):** WS-A AI itinerary wizard (5-stage questionnaire + Apple Foundation Models output / clipboard for Claude.ai/ChatGPT/Perplexity), WS-B birthdays + important-days on Today (locale-seeded ES/EN/FR + custom anniversaries via new `@Model ImportantDay`), Settings IA collapse (29-row flat → 7 colored top-level pages), destination autocomplete + map preview (`MKLocalSearchCompleter` + SwiftUI `Map`), home location auto-detect (`HomeLocationDetector` with `CLLocationManager` + reverse geocode + map), travel advisory sources reorderable + new US-led default order, multi-trip Today + per-trip countdown badges, all chip rows migrated to a shared centered `FlowLayout`, smart default block start time (carry-over from session 23 closed), CI static-scans job (L004/L006/L007 fail-fast guards). Tests **~925** (+~32: DayRule, ImportantDayResolver, ImportantDaySeeder, ItineraryPromptBuilder), i18n **992 × 3** (+99). iPhone deployed live to `3a0e273`. Lessons: 8 (no new — clean implementation).


> **Session 23 follow-ups (2026-04-29, post-round-25):** real-device testing surfaced 2 bugs both fixed + a defensive layer added. Today's "No active template" persisted across tab switches even when an active Weekday template existed (`@Query` refactor in `TodayView`, commit `ec105a5`, captured as L008). Templates' "+" button + entire toolbar/title were missing because L004 was misapplied to a direct tab (NavigationStack restored, `check-tabroots.py` updated, commit `d954bfd`, captured as L007). Round-26 backup pre-flight validator + atomic restore + Settings → "Reset all data" destructive (commit `265e65c`) protect against malformed-backup imports. Apple Developer Program paid; entitlements scaffolds + activation checklist in `docs/round26-activation-checklist.md`. **Lessons: 8** (L001-L008). Tests **893** (+13 from validator/resetter), i18n **899 × 3** (+6).

> **Session 23 polish (2026-04-28 round 25, 62 slices):** regression depth (8 — backup v5 round trip, MostRecent ordering, bulk-edit idempotency, follow-up override, completion% boundary, streak rollover, weekly delta sign, archive filter persistence); r24 wiring (8 — sleep weekly avg + delta + bedtime variance section + share-image, medication 30-day chart + streak section + CSV export, Today + Routine completion chip via snapshot store); sleep + medication deepening (8 — consistency score + caption, dose history filter, 30d adherence trend chart, sleep debt + caption, missed dose helper + diagnostics row); backup v6 with `housekeepingCompletionLog` + auto-frequency suggestion + restore preview + archive exporter + checksum (6); vacation polish (8 — countdown, YTD footprint, budget-vs-actual, weather fallback, doc expiry reminder + section, vCard exporter); watch surfaces (8 — sleep glance + med streak glance + completion ring + line-3 picker + hydration haptic + pause-remaining + theme picker + show-completed toggle; `Menu` → button stack watchOS fix); Today/Routine QoL (6 — autocomplete v2, tag store, ⌘N + ⌘⇧D shortcuts); diagnostics polish (4 — error log, everything-v2 bundle, latency histogram, cache-counter reset confirm). Tests **880** (+0 net, +25 new tests, retired duplicates), i18n **893 × 3** (+37). iPhone + Watch both deployed live this session.

> **Session 22 polish (2026-04-28 round 24, 40 slices, 3 deferred):** regression depth (mood midnight boundary, heatmap row guarantees, runtime fetcher, backup size projector, cache resetter preserves mood); Diagnostics surfaces for round-23 helpers (cache counters, housekeeping log dump, backup size projection, archived templates count, mood streak record); sleep/medication helpers (weekly avg chart, weekly delta, 30-day chart, streak counter, bedtime variance — wiring deferred to round 25); backup v5 with `archivedTemplateIDs` + auto-frequency override + caption; template archive UI (toolbar toggle, swipe-action, filter helper, badge); watch finishing (snooze menu, pending taps reset, complication day-completion %). Tests **773** (+39), i18n **845 × 3** (+32). iPhone + Watch both deployed live this session.

> **Session 21 polish (2026-04-28 round 23, 40 slices):** regression depth (housekeeping log idempotency, reconciler tail-preservation, itinerary binning extracted into Shared, backup v4→v3 downgrade, SwiftLint `do_catch_same_line` rule); mood analytics v3 (sectioned disclosure, histogram chart, streak share-as-image PNG, 6×7 heatmap); vacation (runtime-aware WeatherKit bridge, fetch-error banner, trip forecast summary, currency rate-change detector, marine diving window, notes CSV importer); Today/Routine helpers (bulk category editor, bedtime plan check, archive store, single-template backup share-sheet, refresh-trace summary); watch (mood-streak chip on complication, custom hydration stepper, pause-from-watch, theme tint, swipe-up skip-rest-of-day + extracted file); diagnostics (cache counters, backup size projector, cache resetter). Tests **734** (+50), i18n **813 × 3** (+12). iPhone + Watch both deployed live this session.

> **Session 20 polish (2026-04-28 round 22, 40 slices):** regression guards (mood symbol, refresh-trace toast, conflict API consistency, footprint tie-break, LocalizedStringResource scan); helpers→UI (gift CSV button, lead-time stepper, streak banner + completion log, auto-mirror mute, hydration reconciler, mood week strip in Settings); WeatherKit real path through `ItineraryView` (injection, forecast chips, stale-graceful, refresh button + last-updated caption); mood deepening (7d/30d toggle, weekly delta, streak helper, Today caption, backup v4); Today QoL (CSV import + warnings sheet, gantt visualizer, completion bar, duplicate-with-rename, cascade shift); watch finishing (pending count + clear, goal proportion, complication mood emoji, settings mood strip, swipe-back haptic). Tests **684** (+35), i18n **801 × 3** (+32 net). Watch deployed live this session.

> **Session 19 polish (2026-04-28 round 21, 40 slices):** mood log analytics (`MoodTrendAggregator` + 30-day Swift Charts trend, 7-day Today week strip, emoji filter, `MoodWeeklyGoalStore` + caption, `MoodLogStore.exportLocalizedCSV`); WeatherKit scaffolding (`WeatherForecast` value type, entitlement-gated `WeatherKitForecastService`, `WeatherForecastCache` 6h TTL App-Group-aware, `ItineraryDayForecastChip`, `TripNotesWeatherTemplate`, `TripFootprintAggregator` + 30-day footprint summary, `CurrencyRatesCSV` + table copy); Today QoL (`BlockConflictOverlap` visualizer, long-press skip+snooze chain, refresh-trace toast, `BlockCSVImporter`, ⌘D iPad shortcut, `TemplateListView` search suggestions); watch parity (`WatchHydrationGlanceStore` + glance view, `MoodQuickLogWatchView`, complication pause badge, mark-done undo capsule, `WatchThemeSyncTests`); housekeeping (`HousekeepingStreakAutoSnooze`, `BirthdayGiftIdeaCSVExporter`, `BirthdayLeadDefaultStore`, ad-hoc Focus toggle, `FocusCategoryMuteMirror`). Tests **649** (+64), i18n **769 × 3** (+32). L006 scan extended with explicit REQUIRED_TARGETS.



**Goal:** end user follows full daily routine on iPhone for 14 consecutive days using only this app's notifications.

Modules: M1 (templates) · M2 (notifications) · M3 (medication) · M4 (sleep).

> **Session 5 polish (2026-04-26):** Today empty-state CTA, block skip-today + notification exclusion, snooze-5-min action, notification grouping (thread/category), `WhatsNextIntent` Siri shortcut, `PersonalHygieneWidgets` (small + medium "next block"), VoiceOver pass on time-only rows, scheduled focus windows (DeepFocusFilter merges block + schedule). Remaining work is non-code: real-device validation + paid Apple Developer Program.
>
> **Session 6 polish (2026-04-26):** snooze-once badge on Today rows (`BlockSnoozeStore` + `BlockNotificationIdentifier.parse`), custom snooze duration picker (5/10/15 via `SnoozeDurationStore`), Templates / Settings / Hydration / Trips a11y combine, `WhatsNextDialogBuilder` extracted for testing, `DeepFocusHomeWidget` (small) shipped, hydration best-streak trophy, Birthdays auto-refresh on scenePhase, Housekeeping room picker, onboarding tips.
>
> **Session 10 polish (2026-04-26 round 8):** robust medication follow-up matching via `BlockNotificationIdentifier.parseAny` (no more substring-contains); `RecentlyDeliveredNotificationsView` companion to Pending; xcodegen `preBuildScript` stamps `CommitSHA.txt` on every build; Today summary preview-line shows next block; Templates confirm-on-delete with block count; Hydration undo toast on log delete; BlockEditor footer reflects per-firing notification count.
>
> **Session 11 polish (2026-04-26 round 9):** Today now-line indicator (red "Now · HH:MM" between schedule rows, refreshes on scenePhase active); Templates drag-to-reorder via `.onMove` + EditButton (slot start times stay invariant; durations follow blocks); Hydration weekly bar chart (Swift Charts, trailing 7 days, goal RuleMark); Settings reschedule-today by ±N min (`NotificationCoordinator.rescheduleToday(shiftedByMinutes:)`); iPhone `NextBlockHomeWidget` reload after mark-done via injectable `widgetReloader` on `NotificationActionHandler`; Diagnostics replay-last-delivered + medication-test scheduler + re-request authorization + Critical Alerts row; HKObserverQuery scaffolding (`MedicationObserving` + `MockMedicationObserver` + entitlement-gated `MedicationObserverService`); L004 propagated to `TripsListView`. **Hotfix `4770ee0`:** Today hour wrap fix (lineLimit/fixedSize) + TripDetail back-arrow restored (Cancel/Save toolbar items hidden when `!hasChanges`).
>
> **Session 14 polish (2026-04-27 round 12, 55 slices):** per-category notification drift (`PendingNotificationsByCategory`); trip notes (Markdown) + archive flow + packing categories + completion bar; theme override (system/light/dark) at app root via `.preferredColorScheme(_:)`; pause notifications (1h/4h/24h, coordinator short-circuits); per-category notification mute; per-block medication follow-up override; ObservabilityHealthCheck traffic-light badge; DiagnosticsSnapshot v2 + diff API; configurable marine forecast TTL (6h/24h/7d, default 24h); AustraliaAdvisoryService folded into multi-source standard (5 sources now); LastConversionStore preserves currency state across navigations; TemplateBackup JSON import/export; Today context menu + filter chips + reset day + pull-to-refresh; Birthdays re-sync + lead-date preview; Focus right-now quick-toggle + conflict-overlap detector; `scripts/check-tabroots.py` audit caught + fixed real `TemplateListView` L004 violation. **+77 i18n keys × 3 locales = 580 total.**

| Acceptance | Status |
|---|---|
| Domain models for routine (`Block`, `RoutineTemplate`) with tests | ✅ |
| Persistence (SwiftData + Repository pattern) | ✅ |
| CloudKit sync wiring | 🔒 deferred — needs Apple Developer Program ($99/yr) |
| Routine template created and editable (BlockEditor + TemplateEditor + List) | ✅ |
| Today view (active template + current/next block) | ✅ |
| First-launch onboarding with seeded weekday + weekend templates | ✅ |
| i18n catalog (`Localizable.xcstrings`) with EN + ES + FR — 80+ keys | ✅ |
| Notifications service + factory + scheduler | ✅ |
| Notifications arrive 15min before each block (refreshed on launch) | ✅ |
| Permission flow + Settings tab | ✅ |
| Travel-time `MKDirections` notifications | ✅ — domain + service + scheduler wiring (12a) + UI (12b: BlockEditor location section + Settings home-location). |
| HealthKit Medications service (compiles; functional only on real device) | ✅ |
| Block ↔ medication concept link (`Block.medicationConceptIdentifier`) | ✅ |
| HKObserverQuery sync | 🔒 deferred — needs real device + entitlement |
| Critical Alerts (interruptionLevel = .critical for medication blocks) | ✅ (entitlement still required for full effect) |
| Critical Alerts fallback (re-notification on missed dose) | 🔒 deferred — pairs with HKObserverQuery |
| MedicationCompliance dashboard (last 7 days) | ✅ |
| HealthKit Sleep service (compiles; functional only on real device) | ✅ |
| Auto-bedtime calculator + Sleep dashboard | ✅ |
| Sleep Focus deep-link | ✅ (link to Settings; no public API to activate Focus programmatically) |
| 14 consecutive days of real personal use | ⬜ requires device + paid Apple Developer Program |

---

### Phase 2 — Apple Watch companion ✅ feature-complete (~99%)

**Goal:** glanceable schedule on the wrist + ability to mark blocks done from Watch.

| Acceptance | Status |
|---|---|
| watchOS app with current-day blocks list | ✅ session 3 |
| At least one complication ("next block") | ✅ `PersonalHygieneWatchWidgets` `NextBlockComplication` |
| Haptic notifications mirror iPhone | ✅ via shared notification scheduling |
| Mark block done from Watch | ✅ session 3 |
| Watch Today refreshes on scenePhase active | ✅ round 8 |
| Watch complication reloads after mark-done | ✅ round 8 (`WidgetCenter.reloadAllTimelines()`) |
| CI watchOS build guard (L003 regressions) | ✅ round 8 (`build-watch` job) |
| Real-device validation | 🟡 standalone deploy verified session 9; needs daily-use validation |

---

### Phase 3 — Secondary modules ✅

Modules: M5 (hydration) · M6 (housekeeping) · M7 (contacts birthdays) · M8 (deep focus).

| Acceptance | Status |
|---|---|
| Hydration reminders configurable | ✅ session 3 + streak (S5) |
| Housekeeping tasks recurring + escalation | ✅ session 3 + room filter (S5) |
| Birthdays imported from Contacts | ✅ session 3 + per-contact lead days (S5) |
| Deep Focus mode silences non-critical alerts | ✅ session 3 + scheduled windows (S5) |

---

### Phase 4 — TestFlight beta 🟢 (unblocked 2026-05-06)

**Goal:** stable build for personal real-world use during 30 days.

**Apple Developer Program: ACTIVE** (Team `XC79TD476V`, confirmed 2026-05-06). Next: portal resources (App IDs + App Group + iCloud Container) → wire entitlements in `App/project.yml` → first archive upload. See [docs/round26-activation-checklist.md](docs/round26-activation-checklist.md).

| Acceptance | Status |
|---|---|
| Apple Developer Program active | ✅ 2026-05-06 |
| Entitlements wired in project.yml | ⬜ |
| TestFlight build accepted | ⬜ |
| 30 days bug-bashing on real device | ⬜ |
| ≥ 99% medication adherence over 30 days | ⬜ |

---

### Phase 5 — Vacation module ✅ (feature-complete, real-trip validation pending)

**Goal:** complete an international trip end-to-end with the app handling all preparation + on-trip + return.

Module M9 — see [PRD.md § 6 M9](PRD.md#m9--módulo-vacaciones-fase-final) for requirements breakdown.

> **Session 5 polish (2026-04-26):** itinerary persistence (`ItineraryStore`), API caching decorators (marine + currency + advisory, 30-min/24h TTL), past-trips archive split, Cancel/Save draft flow on Trip detail, cover photo (`PhotosPicker` + `@Attribute(.externalStorage)`), packing list (value-type round-trip via BackupService v1.1).

| Acceptance | Status |
|---|---|
| Trip setup < 2 minutes | ✅ Trips tab + add sheet (session 3) |
| Escalated reminders (6m → day-D) generated | ✅ `TripMilestoneNotificationFactory` + scheduler (session 4 slice 3) |
| Documents scanned + Keychain-encrypted, offline-accessible | ✅ `DocumentScannerView` + `TripDocumentStore` + PDFKit preview (session 4 slices 4-5) |
| AI itinerary generated (on-device) | ✅ `FoundationModelsItineraryGenerator` (iOS 26+) + `StubItineraryGenerator` fallback (session 4 slice 6) |
| Marine weather + tides shown for marine activities | ✅ `OpenMeteoMarineService` (session 4 slice 7) |
| Currency conversion + cash estimate | ✅ `FrankfurterCurrencyService` (session 4 slice 8) |
| Advisory from exteriores.gob.es for destination | ✅ `ExterioresAdvisoryService` deep link (session 4 slice 9) |
| PDF export shareable via Mail/SMS/WhatsApp | ✅ `TripPDFExporter` + share sheet (session 4 slice 10) |
| Validated with one real international trip | ⬜ Pending |

---

### Phase 6 — App Store release ⬜

**Goal:** public release on App Store.

| Acceptance | Status |
|---|---|
| App Store submission accepted | ⬜ |
| Listing localized in ES + EN + FR | ⬜ |
| Public privacy policy URL | ⬜ |
| Real Apple ID for build signing (not personal team) | ⬜ |

---

### Phase 7+ — Future ⬜

(Each is a separate phase, not a single one.)

- 7a — Apple Watch standalone (LTE).
- 7b — macOS via Mac Catalyst or native SwiftUI.
- 7c — Android (Kotlin + Compose).
- 7d — Web companion.

---

## Open questions

See [PRD.md § 13](PRD.md#13-open-questions).

---

## Risks

See [PRD.md § 14](PRD.md#14-riesgos).
