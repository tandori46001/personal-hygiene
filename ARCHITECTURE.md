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

---

**Version history:**

- **v0.6 (2026-04-26)** — added §25 reflecting round 9: `MedicationObserving` scaffolding (entitlement-gated), `NotificationCoordinator.rescheduleToday(shiftedByMinutes:)`, `WidgetCenter` reload wiring in `NotificationActionHandler`, watch `BlockDetailWatchView` + `SettingsGlanceWatchView`, L004 propagated to Trips, Today timeline now-line, drag-to-reorder for blocks, Hydration weekly chart.
- **v0.5 (2026-04-26)** — added §23 (build identity pipeline) + §24 (CI watchOS guard) reflecting session 10 (round 8). Robust medication follow-up matching via `BlockNotificationIdentifier.parseAny`; `RecentlyDeliveredNotificationsView` + `DeliveredNotificationsGrouper`; `removeAll()` on snooze/skip stores.
- **v0.4 (2026-04-26)** — added §21-§22 reflecting session 9 (round 7): Diagnostics dev tools (`DiagnosticsActions`), `MedicationFollowUpFactory`, `BlockSnoozeSource.medicationFollowUp`, build-time `CommitSHA.txt` injection, watch complication focus indicator + watch app snooze badge.
- **v0.3 (2026-04-26)** — added §18-§20 reflecting session 8 (round 6): cross-module shared services, notification-identifier registry pattern, diagnostics + deploy automation.
- **v0.2 (2026-04-26)** — added §13-§17 reflecting session 5: widget extension target, value-type registry, service decorator convention, current notification architecture.
- **v0.1 (2026-04-25)** — esqueleto inicial. Detalle a rellenar en Fase 0 (creación del proyecto Xcode + schema SwiftData concreto).
