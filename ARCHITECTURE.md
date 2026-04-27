# Architecture — personal-hygiene

> **Versión:** v0.1 (2026-04-25) — esqueleto inicial. El detalle se rellena en Fase 0 cuando se cree el proyecto Xcode.

---

## 1. High-level overview

```
┌──────────────────────────────────────────────────────────────────┐
│                     User devices (Apple ecosystem)               │
│                                                                  │
│  ┌─────────────────┐         ┌─────────────────┐                 │
│  │  iPhone (iOS)   │ ◄────►  │ Apple Watch     │                 │
│  │                 │  Watch  │  (watchOS)      │                 │
│  │  Main app +     │  Conn   │                 │                 │
│  │  notifications  │  Frwk   │  Companion +    │                 │
│  │  + UI           │         │  complications  │                 │
│  └────────┬────────┘         └────────┬────────┘                 │
│           │                           │                          │
│           ▼                           ▼                          │
│  ┌─────────────────────────────────────────────┐                 │
│  │  Local persistence (SwiftData)              │                 │
│  │  Keychain (sensitive docs)                  │                 │
│  └────────────────────┬────────────────────────┘                 │
│                       │                                          │
└───────────────────────┼──────────────────────────────────────────┘
                        │ CloudKit Private Database
                        ▼
              ┌─────────────────────┐
              │  iCloud (E2E)       │
              └─────────────────────┘

External services (no PII sent — only coordinates / currency codes):
  WeatherKit · Open-Meteo Marine · Frankfurter · exteriores.gob.es RSS
```

---

## 2. Repo layout

```
personal-hygiene/
├── App/                           # Xcode workspace lives here
│   ├── PersonalHygiene.xcodeproj/ # (TBD in Phase 0)
│   ├── PersonalHygiene/           # iOS app target
│   │   ├── App/                   # @main entry, root container
│   │   ├── Features/              # one folder per module (Routine, Medication, …)
│   │   ├── Resources/             # Assets.xcassets, Info.plist
│   │   └── Localization/          # Localizable.xcstrings
│   ├── PersonalHygieneWatch/      # watchOS app target
│   │   ├── App/
│   │   ├── Features/
│   │   ├── Complications/
│   │   └── Resources/
│   └── Shared/                    # code used by both targets
│       ├── Models/                # domain models (Codable, Sendable)
│       ├── Persistence/           # SwiftData schema + CloudKit config
│       ├── Services/              # HealthKit, EventKit, Contacts wrappers
│       └── Utils/
├── Tests/
│   ├── Unit/                      # XCTest — pure logic
│   ├── Integration/               # XCTest with in-memory CloudKit
│   └── UI/                        # XCUITest — critical flows only
├── docs/                          # design notes, ADRs, diagrams
├── scripts/                       # bash 3.2-compatible
└── .github/                       # CI/CD, issue + PR templates
```

---

## 3. Module structure (per-feature)

Each module under `App/PersonalHygiene/Features/<Module>/` follows:

```
<Module>/
├── Views/                # SwiftUI views
├── ViewModels/           # @Observable view models
├── Models/               # module-local types (cross-module types live in Shared/)
└── Services/             # module-local services
```

Cross-module types and services live in `App/Shared/`.

---

## 4. Data model (high-level — detailed schema in §6 once Xcode project exists)

### Core entities

- **Block** — a time block in the daily routine. Fields: `id`, `title`, `category`, `start`, `duration`, `notes`, `location?`, `notificationLeadMinutes`, `isDeepFocus`, `templateID?`, `medicationConceptID?`.
- **RoutineTemplate** — reusable template per day type. Fields: `id`, `dayType` (weekday/weekend/vacation/custom), `blocks: [Block]`, `version`.
- **Trip** — a vacation. Fields: `id`, `name`, `destination`, `startDate`, `endDate`, `tripType`, `activities`, `documents: [SecureDoc]`, `itinerary?`.
- **SecureDoc** — encrypted document reference. Fields: `id`, `kind` (passport/insurance/etc.), `keychainRef`, `expiryDate?`, `ocrText?`.
- **MedicationLink** — links a Block to a HealthKit `HKMedicationConcept`. Fields: `id`, `blockID`, `healthKitConceptID`, `windowMinutes`.
- **HousekeepingTask** — recurring housekeeping. Fields: `id`, `title`, `cadenceDays`, `lastDone?`, `nextDue`.

### Storage

- **SwiftData** for all routine + trip data (synced via CloudKit).
- **Keychain** for SecureDoc binary content (PDFs, scans).
- **HealthKit** holds medication adherence + sleep data — read via API, never duplicated locally.
- **EventKit** holds external appointments — read via API.
- **Contacts** holds birthdays — read via API.

---

## 5. External integrations

| Integration | Direction | When | Privacy |
|---|---|---|---|
| HealthKit Medications | read + write (dose taken/skipped) | M3, daily | Local only |
| HealthKit Sleep | read | M4, daily | Local only |
| EventKit | read | M9 (medical appointments) | Local only |
| Contacts | read | M7 (birthdays) | Local only |
| WeatherKit | read | M9 vacation | Coordinates only |
| Open-Meteo Marine | read | M9 vacation w/ marine activities | Coordinates only |
| Frankfurter | read | M9 vacation | Currency codes only |
| exteriores.gob.es | read | M9 vacation | Country code only |
| Apple Intelligence | local only | M9 itinerary | Never leaves device |

---

## 6. Detailed schema (TBD in Phase 0)

Will be populated when the Xcode project is bootstrapped. Includes:
- SwiftData `@Model` definitions.
- CloudKit zone + record types.
- Migration policy (lightweight migrations only in 0.x; numbered migrations from 1.0).

---

## 7. Threading model

- All UI updates on `MainActor`.
- All external service calls (HealthKit, WeatherKit, etc.) `async`.
- Background tasks (sync + observer queries) on dedicated actors.
- No `DispatchQueue` in new code.

---

## 8. Notification architecture

- **UserNotifications** for all scheduled alerts.
- Pre-block notifications scheduled 24h ahead in batches.
- Critical Alerts (medication) re-registered on app launch + on Health changes.
- Background sync via `BGAppRefreshTask` + CloudKit subscriptions.

---

## 9. Security

- Data Protection class `complete` for all SwiftData stores.
- Keychain accessibility: `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` for SecureDoc.
- Face ID / Touch ID prompt before showing SecureDoc content.
- No keychain item synchronizes to iCloud (`kSecAttrSynchronizable = false`).
- App Transport Security: HTTPS-only, no exceptions.

---

## 10. Testing strategy

- **Unit tests:** every view model + every service. Target: ≥ 70% line coverage on Shared/.
- **Integration tests:** persistence + CloudKit sync. Use in-memory ModelContainer with mock CloudKit.
- **UI tests:** critical paths only — onboarding, create routine, mark medication, create trip.
- **Snapshot tests:** consider for stable views once UI stabilizes (Phase 4+).

---

## 11. CI/CD

- `.github/workflows/ci.yml` — on push/PR: lint + build + unit tests.
- `release.yml` (Phase 6) — on `v*` tag: archive + upload to TestFlight via `xcodebuild` + `altool`.
- Secret management: GitHub Actions secrets for `APP_STORE_CONNECT_KEY`, `APPLE_TEAM_ID`, etc.

---

## 12. ADRs (Architecture Decision Records)

Place future ADRs under `docs/adr/NNNN-title.md` using the [Michael Nygard format](https://github.com/joelparkerhenderson/architecture-decision-record/blob/main/locales/en/templates/decision-record-template-by-michael-nygard/index.md).

---

## 13. Targets (current — verified 2026-04-26)

| Target | Type | Platform | Notes |
|---|---|---|---|
| `PersonalHygiene` | application | iOS 18+ | Main app. |
| `PersonalHygieneWidgets` | app-extension | iOS 18+ | Home-screen widgets (small + medium "next block"). Uses `SWIFT_VERSION: "5"` because Swift 6 strict mode rejects calling `@MainActor` SwiftData APIs from synchronous `TimelineProvider` callbacks; the widget builds its own `ModelContainer` + `ModelContext` directly to bypass the `@MainActor` repo wrapper. |
| `PersonalHygieneWatch` | application | watchOS 11+ | Today list + mark-done. |
| `PersonalHygieneWatchWidgets` | app-extension | watchOS 11+ | NextBlock complication. |
| `PersonalHygieneTests` | unit-test | iOS | XCTest. |
| `PersonalHygieneUITests` | UI-test | iOS | XCUITest. |

## 14. Value types (Codable + Sendable)

The app prefers `@Model` for entities that need CloudKit sync, but uses **value types** for tightly-coupled data that lives on the parent record:

- `BlockCategory`, `BlockLocation`, `DayType`, `HydrationGoal` — primitive form data on routine entities.
- `BirthdayContact` (Identifiable) — surface model for the Contacts wrapper.
- `TripItinerary` (Codable) — persisted as JSON via `ItineraryStore` (file-on-disk, keyed by `Trip.id`).
- `PackingItem` — appears as `Trip.packingItems: [PackingItem]` and round-trips through `BackupService`.
- `ScheduledFocusWindow` — UserDefaults-backed via `FocusScheduleStore` (intentionally not in the SwiftData backup).

## 15. Service decorator convention

External HTTP services are wrapped in a `Cached*Service` decorator that conforms to the same protocol as the underlying service. The cache key is whatever uniquely identifies a request; the TTL depends on the volatility of the data:

| Service | Decorator | TTL | Key |
|---|---|---|---|
| Marine weather | `CachedMarineWeatherService` | 30 min | rounded (lat, lon) |
| Currency | `CachedCurrencyService` | 30 min | (from, to) — amount applied locally on hits |
| Travel advisory | `CachedTravelAdvisoryService` | 24 h | destination string |

The decorator pattern keeps the underlying service free of caching concerns and lets tests target either layer in isolation.

## 16. Notification architecture (current)

- **Categories** (registered at app launch in `NotificationCategoryRegistrar`):
  - `routine` — supports snooze + mark-done actions.
  - `medication` — critical-alert level, supports mark-done.
- **Threads** (group notifications visually in iOS):
  - `routine`, `medication`, `hydration`, `trip-milestone` — set on `ScheduledNotification.threadIdentifier`.
- **Actions** are dispatched by `NotificationActionHandler` (UNUserNotificationCenterDelegate, non-MainActor):
  - Snooze 5 min → schedules a fresh `UNTimeIntervalNotificationTrigger` at +N seconds.
  - Mark done → removes the original pending notification.
- **Skip-today** is honored upstream of factory: `NotificationCoordinator.refreshForToday` consults `BlockSkipStore` and excludes any `(blockID, dayKey)` pair found there.

## 17. Widget architecture (iOS — `PersonalHygieneWidgets`)

- `NextBlockHomeWidget` exposes small + medium families.
- `DeepFocusHomeWidget` (small) shows active / upcoming / idle focus state, reads from `UserDefaultsFocusScheduleStore.appGroupOrStandard()` so it can promote to an App-Group suite once the entitlement is added without code changes.
- `NextBlockResolver` is the shared brain (also used by `WhatsNextIntent`); it returns `.empty` / `.now(block)` / `.next(block)` from the active `RoutineTemplate`.
- The widget's `TimelineProvider` constructs its own `ModelContainer` + `ModelContext` directly because the `@MainActor`-isolated `RoutineRepository` cannot be called from synchronous WidgetKit callbacks under Swift 6 strict mode.

## 18. Cross-module shared services (`App/Shared/Services/`)

Single sources of truth pulled out of feature folders so iOS, watch, and the
widget extension see the same constants:

- **`AppGroup`** — `suiteName = "group.com.tandori46001.personalhygiene"`. `UserDefaults(suiteName:)` returns nil until the entitlement is added; callers fall back to `.standard`. The constant means a single line changes when the entitlement lands.
- **`OnboardingFlagStore`** — owns the `hasCompletedOnboarding` UserDefaults key. `reset()` re-arms the welcome flow on next launch (used by Settings → "Show onboarding again", and by `-uiTestReset` for XCUITest).
- **`WhatsNextDialogBuilder`** — pure formatter that turns `RoutineTemplate?` + `Date` into a localized one-liner. Lives in Shared so the watch complication can build the same accessibility label as the Siri intent. Two overloads: full `(template:at:calendar:)` for the iOS intent + `(resolved:)` for callers that already computed the next block.
- **`BuildInfo`** — reads `CFBundleShortVersionString` + `CFBundleVersion` from the main bundle and an optional `PERSONAL_HYGIENE_COMMIT_SHA` Info.plist key (defaults to `"dev"`). `BuildInfo.shortDescriptor` is shown in the Settings footer.

## 19. Notification identifier registry + per-source snooze tracking

When multiple modules emit notifications and a central handler reasons about
them, parsers must enumerate every kind exhaustively or features go silently
dark for the unparsed kind (LESSONS L002).

- **`BlockSnoozeSource`** (enum) — single registry of notification kinds: `.routine`, `.hydration`, `.milestone`. Adding a kind here forces a compile error in `BlockNotificationIdentifier.parseAny` (switch is non-exhaustive).
- **`ParsedNotificationIdentifier`** — enum with payload per kind: `.routine(blockID, dayKey)`, `.hydration(dayKey, index)`, `.milestone(milestoneID)`. Returned from `parseAny`; carries a `.source: BlockSnoozeSource` accessor.
- **`BlockNotificationIdentifier.parseAny(_:)`** — accepts a raw `UNNotificationRequest.identifier` (including snooze re-fire suffixes `.snooze.<ts>`); recognizes the prefix of any registered kind. Guarded by `test_parse_recognizesAllKnownPrefixes` which iterates `BlockSnoozeSource.allCases`.
- **`BlockSnoozeStore`** — per-source isolation. Routine entries can use either the legacy `{uuid}|{dayKey}` format (pre-session-7 user data) or the new `{source}|{key}|{dayKey}` format; new APIs read both.
- **`NotificationActionHandler`** — `snoozeRecorder: (ParsedNotificationIdentifier) -> Void` is dispatched on every kind; the production wiring in `PersonalHygieneApp` calls `BlockSnoozeStore.markSnoozed(parsed:on:)` which routes to the right key. `markDoneObserver: (String) -> Void` is the test seam for the Mark-done flow.

## 20. Diagnostics + deploy automation (round 6)

- **`DiagnosticsView`** (Settings → About → Diagnostics) — surfaces version, build, commit SHA, notification authorization status, last refresh, pending notification count, link into `PendingNotificationsView`.
- **`PendingNotificationsView`** — pulls `UNUserNotificationCenter.pendingNotificationRequests()` and groups by `BlockSnoozeSource` derived from `parseAny`. Pull-to-refresh re-reads. Critical for verifying schedule on real device without waiting hours.
- **`scripts/deploy-iphone.sh`** — one-shot iPhone install: injects `DEVELOPMENT_TEAM` into `project.yml` if empty, regenerates the project, builds with `-allowProvisioningUpdates`, strips macOS `._*` metadata files (USB-mounted volume artifact), installs via `xcrun devicectl`, launches via `xcrun devicectl process launch`. Defaults are baked from `memory/session_handoff.md` (round 5/6); override via `DEVICE_UDID` / `TEAM_ID` env vars.
- **`scripts/check-tests.sh`** — exits 0 when xcodebuild returns 65 *and* there are zero `Test Case '...' failed` lines in the log (the known `DebuggerLLDB.DebuggerVersionStore.StoreError` simulator glitch present since session 5).

---

## 21. Dev tools + medication follow-up (round 7)

- **`DiagnosticsActions`** — closure-bag passed into `DiagnosticsView` so the dev-only buttons (schedule test notification, clear all pending, inject snooze badge, reset stores) can act on live app stores without `DiagnosticsView` knowing about concrete types. `ContentView.makeDiagnosticsActions()` builds it from `AppEnvironment`.
- **`Settings → Diagnostics → Dev tools`** section is dev-only. Production guard: lives behind the optional `diagnosticsActions:` SettingsView parameter; if not wired, the section is hidden.
- **`MedicationFollowUpFactory`** — pure value-type that, given a primary medication notification, builds a +30 min follow-up `ScheduledNotification` with prefix `personal-hygiene.medication.followup.`. Wired into `NotificationCoordinator.refreshForToday` so every medication block fires twice. PRD M3.2 fallback for users without HealthKit `HKObserverQuery` entitlement.
- **`BlockSnoozeSource.medicationFollowUp`** — fourth case in the registry (alongside routine / hydration / milestone). `BlockNotificationIdentifier.parseAny` recognizes the new prefix; the L002 guard test (`test_parse_recognizesAllKnownPrefixes`) iterates `allCases` and would fail without the parser update — the original goal of L002.
- **Build identity**: `App/PersonalHygiene/Resources/CommitSHA.txt` is stamped at build time by `scripts/deploy-iphone.sh` (`git rev-parse --short HEAD`). Read by `BuildInfo.commitSHA`. Checked-in default is `"dev"` so plain `xcodebuild` runs without the script still produce a readable footer. The file is gitignored to avoid noise.
- **`scripts/check-tests.sh` exit-65 filter** (round 6) keeps reading the test log for `Test Case '...' failed` lines; if zero, the DebuggerLLDB simulator glitch is treated as success.

## 22. Watch parity (round 7)

- **`NextBlockComplication`** now exposes `isFocusActive` in its snapshot; the entry view shows a small `moon.zzz.fill` glyph when a Deep Focus window is in effect. Focus state is computed via `DeepFocusFilter.isFocusActive(at:in:scheduledWindows:)` reading `UserDefaultsFocusScheduleStore.appGroupOrStandard()` — same store the iOS widget uses.
- **`TodayWatchView` rows** show the `alarm` badge when `viewModel.isSnoozedToday(_:)` is true, mirroring the iPhone Today list. The watch app passes `UserDefaultsBlockSnoozeStore()` into `TodayViewModel` via `ContentView`; once an App Group entitlement lands, both targets can share the same `UserDefaults` suite.

## 23. Build identity pipeline (round 8)

The short git SHA is stamped into `App/PersonalHygiene/Resources/CommitSHA.txt` from three places, in priority order:

1. **`./scripts/deploy-iphone.sh`** + **`./scripts/deploy-watch.sh`** — CLI deploys overwrite the file before the xcodebuild step. Authoritative for installs onto physical devices.
2. **`PersonalHygiene` target preBuildScript in `App/project.yml`** (round 8) — runs on every build (incl. plain ▶ in Xcode). Falls back to `dev` when run outside a git checkout. `basedOnDependencyAnalysis: false` keeps Xcode from caching the script away.
3. **Bundled fallback** — `BuildInfo.commitSHA` reads the resource at runtime; if missing, returns `"dev"`.

`CommitSHA.txt` is gitignored so the file is reproducible-from-checkout, not committed.

## 24. CI watchOS guard (round 8)

L003 (Shared/ files using iOS-only APIs need `#if !os(watchOS)` gating) was caught manually in session 9 by a local watch deploy. The CI workflow now has a `build-watch` job (`.github/workflows/ci.yml`) that runs `xcodebuild build -scheme PersonalHygieneWatch -destination 'generic/platform=watchOS'` on `macos-latest` for every push and PR. Code-signing is disabled for the CI build so it doesn't need credentials. Failure here means a Shared/ file probably regressed; resolve by guarding the offending file with `#if canImport(UIKit) && !os(watchOS)`.

## 25. MedicationObserving scaffolding + reschedule-today (round 9)

### MedicationObserving (PRD M3.2 entitlement-gated future)

`MedicationObserving` is a `@MainActor` protocol with `start(for:onChange:)` / `stop(for:)` / `stopAll()`. The shipped implementations are:

- **`MockMedicationObserver`** — in-memory test double. Records `start`/`stop` calls; `simulateChange(for:)` fires the registered handler. Duplicate `start` calls are last-writer-wins per protocol contract.
- **`MedicationObserverService`** — production shell with `isAvailable: false` until the `health.records.medications` HealthKit entitlement ships. `start` records the registration but never fires a callback; the push-reminder fallback (`MedicationFollowUpFactory`, scheduled by `NotificationCoordinator.refreshForToday`) is the source of truth for M3.2 in the meantime.

Once the paid Apple Developer Program lands, swap `MedicationObserverService.isAvailable` to a real `HKHealthStore.isHealthDataAvailable()` check, wire `HKObserverQuery` per concept identifier, and gate the follow-up factory on observer presence.

### Reschedule-today (jet-lag / late-wake recovery)

`NotificationCoordinator.rescheduleToday(shiftedByMinutes:now:)` builds today's nominal schedule via the new `buildTodayNotifications(now:)` helper, applies a ±N-minute shift in-memory (pure `shifted(_:byMinutes:dropPastBefore:)` mapping, exposed for testing), drops triggers that land in the past, and sends the result back through `NotificationService.scheduleAll`. Block start times in storage are not modified — re-running `refreshForToday` later restores the nominal schedule.

### iPhone widget reload after mark-done

`NotificationActionHandler` gained an injectable `widgetReloader` defaulting to `WidgetCenter.shared.reloadAllTimelines()`; the production handler invokes it in the mark-done branch so `NextBlockHomeWidget` reflects the just-completed block immediately. Tests inject a counter to verify the wiring.

### L004 propagation

Trips list view (`TripsListView`) drops its inner `NavigationStack` (matches the Settings fix from round 8 post-deploy). Hydration / Housekeeping / Birthdays keep their inner stacks for now since they have zero internal `NavigationLink`s and would risk breakage if the user reorders tabs out of the More overflow.

## 26. Diagnostics observability + multi-source advisory + L005 (round 10)

### Process-local diagnostics surfaces

Round 10 introduces three small process-local services that feed `DiagnosticsView` so an on-device user can answer "what just happened?" without attaching Xcode:

- **`RefreshTraceLog.shared`** — ring buffer (capacity 20) of `(timestamp, scheduledCount, kind: refresh|reschedule)` entries. `NotificationCoordinator.refreshForToday` and `rescheduleToday` write here on every successful schedule. Cleared on relaunch; not persisted.
- **`WidgetReloadCounter.shared`** — counts how many times the default `widgetReloader` closure (passed into `NotificationActionHandler`) has invoked `WidgetCenter.shared.reloadAllTimelines()`. Confirms the round-9 mark-done → widget reload wiring fires in production.
- **`MedicationObserverService.registeredIdentifiers`** — DiagnosticsView surfaces the count + availability so the user can see which medication concepts the app *would* observe once HealthKit lands. Pre-entitlement, `start(_:onChange:)` records the registration but never fires a callback (M3.2 push fallback stays the source of truth).

`DiagnosticsActions` is the single closure-bag through which the view reads these — no concrete service types leak into the view layer.

### Multi-source travel advisory

The `TravelAdvisoryService` protocol grew an `advisories(forDestination:)` method (default impl wraps the single-source `advisory(forDestination:)` for backward compat). New implementations cover US (`StateDepartmentAdvisoryService`), Canada (`CanadaTravelAdvisoryService`), UK (`UKFCDOAdvisoryService`); existing `ExterioresAdvisoryService` (Spain) is kept as the lead source. `MultiSourceAdvisoryService` aggregates them in fixed order (ES → US → CA → UK). `CachedTravelAdvisoryService` was extended with a parallel list cache (same 24h TTL). `AdvisoryView` is now list-shaped — every source becomes a tappable row. Single-link consumers (previews, legacy tests) keep working via the back-compat init.

### Schedule-health diff

`scheduleDiff` (in `DiagnosticsActions`) returns `(pending, expected)` where `expected = coordinator.buildTodayNotifications().count`. The Diagnostics view renders the delta and badges it `Δ ≠ 0` so drift between the deterministic build and what's actually pending is visible without an Xcode debugger.

### Configurable medication follow-up delay

`MedicationFollowUpDelayStore` (UserDefaults-backed, allowed values 15/30/45/60, default 30) lets the user adjust the M3.2 follow-up delay from Settings → Scheduling. `NotificationCoordinator.medicationFollowUps` reads the stored value via a default arg so tests can override deterministically.

### Trip module polish

`TripsListViewModel.duplicate(_:)` clones a trip (packing items reset to unpacked, milestones cloned as incomplete). `daysUntilNearest()` powers a small "in N d" / "today" / "underway" badge on the closest upcoming `TripRow`. `TripPDFExporter` renders `coverPhotoData` as a 200pt full-bleed banner above the title block when present.

### Currency quick-pick

`CurrencyView` shows a horizontal chip row of the seven supported codes (USD, EUR, GBP, CAD, CHF, AUD, JPY) above each text field so the user doesn't have to type. The Frankfurter API supports all seven (ECB-sourced).

### L005 — process crashes vs LLDB glitch

`scripts/check-tests.sh` previously treated *every* exit-65 with zero `Test Case 'X' failed` lines as the harmless DebuggerLLDB glitch and returned 0. Round 9's `TripsListViewModelArchiveTests` flake (an L001 regression — orphan `ModelContainer` deallocating mid-test) fired exactly that pattern: process-level crash, no failed-test-method line. Round 10 adds a separate count of `Restarting after unexpected exit, crash, or test timeout|signal trap|Encountered an error \(Crash:` matches; the success branch now requires *both* the failure count and the crash count to be zero. See `LESSONS.md` L005.

## 27. Round 11 — caveat closure + observability export + Today/trip polish

### Schedule-health Δ filtered to routine prefixes

Round 10's diff between `pendingNotificationRequests().count` and `coordinator.buildTodayNotifications().count` always read non-zero whenever any trip-milestone or hydration notification was pending — the `expected` side only counts routine + medication-followup. Round 11 filters the `pending` side to those same two prefixes (`NotificationFactory.identifierPrefix` + `MedicationFollowUpFactory.identifierPrefix`) so Δ reflects real drift only.

### `DestinationSlug` + `PreferredAdvisorySourceStore`

`DestinationSlug` centralizes URL slug generation: `auto(_:)` for the default (lowercase + hyphen), plus `ukFCDO(_:)` and `canada(_:)` overrides for destinations whose canonical slug differs from the auto form (e.g. gov.uk uses `the-united-states-of-america`). `PreferredAdvisorySourceStore` (UserDefaults, `AdvisorySource` enum) lets the user pick a lead source for the advisory list; `TripDetailViewModel.advisoryLinks` reorders accordingly via `PreferredAdvisorySourceStore.reorder(_:preferred:)`.

### `RecentConversionsStore` + `convertAll`

`RecentConversionsStore` is a UserDefaults-backed JSON array (capacity 5, dedupe by `(from, to, amount)`). `CurrencyView` shows the recents as tap-to-restore rows. `CurrencyService.convertAll(amount:from:to:)` is a new protocol method (default impl loops `convert(_:from:to:)`); `FrankfurterCurrencyService` overrides with a single round-trip — Frankfurter accepts `to=USD,GBP,…` — so the "Convert to all 7" button doesn't fan out to seven HTTP requests. `CachedCurrencyService` populates per-target rates after a multi-target call.

### Diagnostics: snapshot export + uptime + bytes + Advanced disclosure

`ProcessLaunchTimer` captures process launch time via the `let launchedAt = Date()` static idiom; DiagnosticsView surfaces it + uptime via `DateComponentsFormatter`. `DiagnosticsSnapshot` is a `Codable` value type that captures every diagnostics surface (build identity, pending/delivered counts, refresh trace, observer state, trip docs, pending notification identifiers + trigger dates) — body is *structural only* (no notification titles/bodies) so a leaked snapshot doesn't expose private medication identifiers. `DiagnosticsActions.exportSnapshot` writes the snapshot to a temp `.json` file; the view binds to a `sheet(item:)` that opens `ShareSheet`. New `tripDocumentByteFootprint` walks every trip → every document → reads via `TripDocumentStore.bytes(for:)` and sums byte length — gives a real Keychain occupancy number (formatted via `ByteCountFormatter`). The new round-10 sections (Schedule health, Recent refreshes, Observability, Snapshot export) all live under one "Advanced" `DisclosureGroup` (collapsed by default) so the Diagnostics view stays scannable for non-developer users.

### Trip module: search + next-milestone card + packing bulk + duplicate-with-name

`TripsListView` attaches `.searchable` only when the user has 5+ trips (`TripsSearchModifier` view modifier); `TripsListViewModel.filtered(_:)` is a pure helper exposed for tests. `TripDetailViewModel.nextDueMilestone(now:calendar:)` computes the next-due, still-incomplete milestone (skipping past-due that should already be marked complete) — surfaced as a prominent card at the top of TripDetailView. `markAllPacked()` / `resetAllPacking()` are new bulk actions exposed via a `Menu` in the packing-section header. `TripsListViewModel.duplicate(_:name:)` takes an optional explicit name; `TripsListView` presents a confirm-with-editable-name `.alert` with default `Copy of <source.name>`. `TripPDFExporter` gained packing-list + recent-currency-snapshot sections (the latter reads `RecentConversionsStore.recent()` so no service injection is needed).

### Today: block detail sheet + "in N min" caption + compact mode

`BlockDetailSheet` (presented via `sheet(item: $detailBlock)`) shows the full block info — start, duration, category, optional medication concept identifier (text-selectable for copy/paste), focus indicator — plus Mark-done + Skip-today actions. Triggered by tap-on-block (full-row `contentShape` + `onTapGesture`). `BlockNowRow` for the next block now shows a "in N min" / "in 1h N min" / "starting now" caption via `BlockNowRow.untilCaption(minutes:)` (returns a `LocalizedStringKey` so the formatting can vary per locale). `@AppStorage("today.compactMode")` toggle in the Today toolbar makes `BlockTimelineRow` hide the category dot, the category caption, and the duration text — useful when the schedule grows long.

### Reset-all-customizations

Settings → Diagnostics gained a destructive "Reset all customizations" button that goes through a confirm dialog. Resets snooze duration + medication follow-up delay + preferred advisory source + home location + focus schedule windows in one go. Backup snapshot data + completed templates are NOT touched — only user-tunable preferences.

### What's-new auto-popup

`ContentView.task` reads `BuildInfo.commitSHA` and compares it against the `whatsNew.lastSeenCommitSHA` `@AppStorage` key. If they differ (and the user has completed onboarding), `WhatsNewSheet()` auto-presents. Dismissing the sheet writes the current commit SHA back so the popup only fires once per build.

---

## 28. Round 12 — pending-by-category drift, trip notes/archive, theme override, pause notifications

### Pending-by-category drift

`PendingNotificationsByCategory` (value type) classifies a list of identifiers by their factory prefix (`personal-hygiene.block.`, `.medication.followup.`, `.hydration.`, `.trip-milestone.`, `.housekeeping.`, plus "other"). DiagnosticsView's Advanced disclosure now expands a per-category breakdown; round-11 closed only the routine drift, so milestone/housekeeping/hydration drift was previously silent. The classifier matches the follow-up prefix first since it shares a parent with `personal-hygiene.medication.` — same idea as L002 (model the prefix as a typed enum so adding a new kind without updating the classifier is a compile error).

### Trip lifecycle: notes + archive + currency snapshot

`Trip` gained `notes: String` (Markdown via `Text(LocalizedStringKey)`) and `currencySnapshotJSON: String?`. The Trip detail toolbar `…` menu offers "Archive trip" — confirm-gated, shifts `endDate` to yesterday so the trip falls into Past Trips, and persists `RecentConversionsStore.recent()` as JSON onto the trip itself so the printable record survives even when the user later clears the recents store. `PackingItem.category` (optional, defaults to `.other`) drives horizontal filter chips on the packing list and a per-item icon. `TripCompletionSection` shows a single combined "Trip readiness" % over packing + milestones at the top of the detail screen.

### Pause + theme + per-category mute

`PauseNotificationsStore` (UserDefaults, single key `notifications.pausedUntil` with absolute Date). `NotificationCoordinator.refreshForToday` short-circuits while `isPaused(now:) == true` — it cancels everything previously scheduled and records a `RefreshTraceLog.shared.record(scheduledCount: 0, kind: .refresh, ...)` so the gap is auditable. `@AppStorage("settings.theme")` ("system" / "light" / "dark") applied at app root via `.preferredColorScheme(_:)`. `NotificationCategoryMuteStore` (per-category boolean toggles) — `medicationFollowUps` short-circuits to an empty array when `.medication` is muted; the rest is hooked at the factory layer where applicable.

### Per-block follow-up override

`PerBlockFollowUpOverrideStore` (UserDefaults, single JSON dict keyed on `blockUUID`) lets a single block override the global medication follow-up delay. `NotificationCoordinator.medicationFollowUps` reads the override before falling back to `MedicationFollowUpDelayStore.minutes()`. Allowed-value enforcement happens at the store boundary; only 15/30/45/60 are accepted.

### Diagnostics v2 — health badge + snapshot diff + launch history

`ObservabilityHealthCheck.status(...)` collapses schedule drift / observer state / widget reloads / auth status into a green/yellow/red enum that DiagnosticsView shows as a top-of-screen badge. `DiagnosticsSnapshot.diff(from:to:)` returns scalar deltas (pending / delivered / widget reloads / trip-doc count) plus observer-id additions/removals + a `buildChanged` flag. `ProcessLaunchHistoryStore` is a 10-entry ring buffer of `(launchedAt, previousDurationSeconds)` so the user can detect silent OS-driven restarts. `WhatsNewHistoryStore` keeps the last 5 commit SHAs the auto-popup acknowledged on this device.

### MarineForecastFreshnessStore

`MarineForecastFreshnessStore.allowedHours = [6, 24, 24*7]` controls the TTL fed into `CachedMarineWeatherService(upstream:defaults:)`. Default jumped from 30 min to 24 h so marine forecasts stay readable offline mid-trip.

### TemplateBackup

`TemplateBackup.encode(_:)` / `decode(_:)` round-trips a single template through a versioned JSON envelope (`Payload` → `TemplateDTO` → `[BlockDTO]`). Decoupled from `BackupService` so a user can share a single template via copy/paste without the entire app state.

### L004 audit script

`scripts/check-tabroots.py` reads a fixed list of tab-root view files and flags any that contain both an inner `NavigationStack` and a `NavigationLink` (the second condition is what makes the double-back-arrow visible). Sheet- and preview-helper contexts are excluded via a 30-line look-back for `private struct` / `private var` / `.sheet` / `.fullScreenCover`. Caught a real regression in `TemplateListView`.

---

**Version history:**

## 29. Round 13 — caveat closure, cost log + Markdown share, diagnostics deep-dive, bedtime mute

### Round-12 caveat closure

`TripDetailViewModel.notesParagraphs` splits `trip.notes` on `\n\n` so the renderer can show one `Text(.init(paragraph))` per visual block instead of collapsing everything into one. `captureCurrencySnapshotWithFallback()` always writes a JSON value (even an empty `[]`) so a future reader can distinguish "trip never archived" from "trip archived with no recents". `RefreshTraceKind.paused` is a new third case so observability code doesn't read the deliberate gap from `PauseNotificationsStore` as drift; `ObservabilityHealthCheck.status(...)` now takes a `paused: Bool = false` arg and returns `.yellow` while paused. Today's minute-tick `Task` keeps `nowMinutes` fresh every 60s while the view is foregrounded — cancelled on `onDisappear` and on `scenePhase != .active` so it doesn't burn battery in background.

### Trip cost log + Markdown share + shifted-dates duplication

`Trip.expensesJSON` (String?) holds a JSON-encoded `[TripExpense]`. `TripExpense` is a new value type with `(label, amount, currencyCode, occurredAt)`. The `expenses` getter/setter on the view-model decodes/encodes through this single field — keeps SwiftData migrations cheap. `TripExpensesSection` renders the list + an inline add row with TextFields for label/amount/currency. `itineraryMarkdown()` builds a printable Markdown string covering title, dates, milestones, packing, notes, expenses; the toolbar `…` menu's "Share as Markdown" action writes a `.md` file to temp + opens a share sheet (mirror of round-11 PDF flow). `TripDetailViewModel.duplicateShifted(_:byDays:calendar:)` clones a trip with every date moved by N days, resetting packing-pack state + skipping the cost snapshot.

### Diagnostics deep-dive

`SnapshotHistoryStore` keeps the last 3 `DiagnosticsSnapshot` objects as JSON bytes in UserDefaults. The export action (`DiagnosticsActionsFactory.exportSnapshot`) records every snapshot it writes so the user can compare against earlier runs without leaving the app. `NotificationAuthTimelineLog` is a deduped rolling history of `(timestamp, statusRawValue)` pairs — only logs *changes*, not periodic resamples. `NetworkActivityCounter.shared` (singleton, process-local, resets at relaunch) is incremented from each `URLSession.data(from:)` call into Frankfurter / OpenMeteo / advisory services. Cache hits don't count (the cached service decorators short-circuit before reaching `URLSession`). Diagnostics gained four new disclosure sections: Snapshot history, Auth timeline, Network activity, Pending notification IDs (identifier + trigger date — no titles/bodies, same privacy bar as the snapshot).

### BedtimeMute

`BedtimeMute.shouldSuppress(notification:sleepBlock:on:calendar:)` returns `true` when the notification's trigger date falls inside the user's sleep block ±15 min. `HydrationNotificationFactory.filteringBedtimeMuted(_:sleepBlock:on:calendar:)` is a static helper the coordinator can call before scheduling. Gated on `NotificationCategoryMuteStore.isMuted(.bedtime)` so users can opt in/out from Settings. Medication notifications (primaries + follow-ups) are NEVER suppressed — the helper is only called on hydration/housekeeping/birthday/milestone payloads.

### Housekeeping streak + birthday metadata

`HousekeepingStreakCounter` is a pure helper (current streak + best streak ever) over a `Set<String>` of `yyyy-MM-dd` keys. `BirthdayIdeaStore` and `BirthdayRelationshipStore` are UserDefaults-backed dicts keyed on Contact ID — each surface adds a non-disruptive sidecar to existing `BirthdayContact` value-type rendering.

### Trip notes templates

`NotesTemplateStore` (JSON array in UserDefaults) holds reusable `(title, body)` snippets the user can paste into any trip's notes field. Decoupled from the per-trip `notes` field so a snippet edit doesn't leak into trips that already used it.

### TodayView extraction

Round 13 hit SwiftLint's 300-line type-body cap on `TodayView` again. `visibleBlocks(_:filter:collapseDone:)`, `shouldInsertNowMarker(...)`, the toolbar `@ToolbarContentBuilder` `todayToolbar`, and the static `makeMinuteTicker(_:)` all live in `TodayViewRound12.swift`'s extension now. Same pattern for `TripDetailViewModel` — round-13 notes/expenses/markdown helpers live in `TripDetailViewModelRound13.swift`.

---

**Version history:**

- **v0.10 (2026-04-27)** — added §29 reflecting round 13: round-12 caveat closure (notes paragraphs, snapshot fallback, `RefreshTraceKind.paused`, ObservabilityHealthCheck pause-aware, Today minute-tick); trip cost log + Markdown share + duplicate-with-shifted-dates + notes templates; SnapshotHistoryStore + NotificationAuthTimelineLog + NetworkActivityCounter + pending-details disclosure; HousekeepingStreakCounter + BirthdayIdeaStore + BirthdayRelationshipStore; BedtimeMute helper.
- **v0.9 (2026-04-27)** — added §28 reflecting round 12: pending-by-category drift, trip notes/archive/packing categories, pause notifications, theme override, per-category mute toggles, per-block follow-up override, ObservabilityHealthCheck + snapshot diff + launch history, MarineForecastFreshnessStore, TemplateBackup, L004 audit script.
- **v0.8 (2026-04-26)** — added §27 reflecting round 11: Schedule-health Δ filtered to routine-prefix only; `DestinationSlug` + `PreferredAdvisorySourceStore` for multi-source advisory; `RecentConversionsStore` + `convertAll(amount:from:to:)` (single Frankfurter round-trip for the seven supported currencies); `ProcessLaunchTimer` + `DiagnosticsSnapshot` (JSON export to share sheet); `tripDocumentByteFootprint` (real Keychain bytes); Diagnostics Advanced disclosure group; trips searchable + duplicate-with-name + next-milestone card + packing bulk actions; Today block-detail bottom sheet + "in N min" caption + compact mode.
- **v0.7 (2026-04-26)** — added §26 reflecting round 10: process-local diagnostics surfaces (`RefreshTraceLog`, `WidgetReloadCounter`, observer status), multi-source travel advisory, schedule-health diff in DiagnosticsView, configurable medication follow-up delay, currency quick-pick chips, trip duplication + countdown badge + PDF cover photo, L005 (signal-trap detection in `check-tests.sh`).
- **v0.6 (2026-04-26)** — added §25 reflecting round 9: `MedicationObserving` scaffolding (entitlement-gated), `NotificationCoordinator.rescheduleToday(shiftedByMinutes:)`, `WidgetCenter` reload wiring in `NotificationActionHandler`, watch `BlockDetailWatchView` + `SettingsGlanceWatchView`, L004 propagated to Trips, Today timeline now-line, drag-to-reorder for blocks, Hydration weekly chart.
- **v0.5 (2026-04-26)** — added §23 (build identity pipeline) + §24 (CI watchOS guard) reflecting session 10 (round 8). Robust medication follow-up matching via `BlockNotificationIdentifier.parseAny`; `RecentlyDeliveredNotificationsView` + `DeliveredNotificationsGrouper`; `removeAll()` on snooze/skip stores.
- **v0.4 (2026-04-26)** — added §21-§22 reflecting session 9 (round 7): Diagnostics dev tools (`DiagnosticsActions`), `MedicationFollowUpFactory`, `BlockSnoozeSource.medicationFollowUp`, build-time `CommitSHA.txt` injection, watch complication focus indicator + watch app snooze badge.
- **v0.3 (2026-04-26)** — added §18-§20 reflecting session 8 (round 6): cross-module shared services, notification-identifier registry pattern, diagnostics + deploy automation.
- **v0.2 (2026-04-26)** — added §13-§17 reflecting session 5: widget extension target, value-type registry, service decorator convention, current notification architecture.
- **v0.1 (2026-04-25)** — esqueleto inicial. Detalle a rellenar en Fase 0 (creación del proyecto Xcode + schema SwiftData concreto).
