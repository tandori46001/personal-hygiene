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

**Version history:**

- **v0.1 (2026-04-25)** — esqueleto inicial. Detalle a rellenar en Fase 0 (creación del proyecto Xcode + schema SwiftData concreto).
