# Changelog

All notable changes to this project are documented here.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and the project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added — Phase 0 (bootstrap)
- Repository scaffolding: README, LICENSE (MIT), CHANGELOG, CONTRIBUTING, SECURITY, `.editorconfig`, `.gitignore`, `.swiftlint.yml`, `.swift-format`.
- `PRD.md` v0.2 — product requirements (9 modules, 7 delivery phases) post C1-C6 logical audit.
- `ARCHITECTURE.md` skeleton, `ROADMAP.md`, `CLAUDE.md`, `LESSONS.md`, `QA_MANUAL.md`.
- GitHub Actions: `ci.yml` (3 conditional jobs), dependabot, CODEOWNERS, PR + issue templates, BRANCH_PROTECTION.md.
- 5 dev scripts (`bootstrap`, `check-tests`, `check-clean`, `lint`, `format`) — bash 3.2 compatible.
- **Xcode project** generated from `App/project.yml` via xcodegen — iOS app + watchOS app + unit-test target.

### Added — Phase 1 (slices 1, 3-11, 13-14, 16-20)
- **Slice 1+3 (persistence):** `Block` and `RoutineTemplate` as `@Model` with cascade-delete relationship. `AppModelContainer` factory (production / in-memory). `RoutineRepository` protocol + `SwiftDataRoutineRepository`.
- **Slice 4 (Block editor):** `BlockEditorView` + `BlockEditorViewModel` with title, category picker (12 categories), time pickers, duration stepper, lead-time, deep-focus toggle, notes.
- **Slice 5 (Template editor):** `TemplateEditorView` + `TemplateEditorViewModel` — manage block list with add / edit / delete / cascade.
- **Slice 6 (Template list):** `TemplateListView` + `TemplateListViewModel` — browse + create + activate (one active per day type) + delete.
- **Slice 7 (Today):** `TodayView` + `TodayViewModel` — pulls active template for today's `DayType` (weekday/weekend); shows current/next block.
- **Slice 8 (Onboarding):** first-launch wizard backed by `@AppStorage`; seeds two starter templates (weekday + weekend) with localized block titles.
- **Slice 9-11 (notifications):** `NotificationFactory` (pure value-type builder), `UserNotificationsService` (UNUserNotificationCenter wrapper), `NotificationCoordinator`. Settings tab with permission flow + manual refresh. Critical Alerts level set on medication blocks.
- **Slice 13-14 (medication infra):** `MedicationService` protocol + `InMemoryMedicationService` (tests/previews) + `HealthKitMedicationService` (placeholder — not bridged into simulator). `Block.medicationConceptIdentifier` field added.
- **Slice 16 (Critical Alerts):** medication notifications get `interruptionLevel = .critical` (effective when entitlement is granted).
- **Slice 17 (compliance dashboard):** `MedicationCompliance` arithmetic (pure) + `MedicationComplianceView` showing last 7 days + colour-coded overall adherence.
- **Slice 18-19 (sleep):** `SleepService` protocol + impls. `BedtimeCalculator` (pure modular-arithmetic for wake-up → bedtime). `SleepDashboardView` with target bedtime + last-night actual + deficit indicator.
- **Slice 20 (Sleep Focus):** deep-link button to iOS Focus settings (no public API to activate Focus programmatically).

### Added — meta-system
- **L001 lesson:** ModelContainer must outlive ModelContext. Captured during slice 1+3 — orphan-context pattern crashed the simulator with "Invalid device state" / "Host is down" during cascade-delete.

### Deferred (documented in `ROADMAP.md`)
- Slice 2 (CloudKit sync) — needs Apple Developer Program ($99/yr).
- Slice 12 (Travel-time MKDirections) — needs `Block.location` field.
- Slice 15 (HKObserverQuery sync) — needs real device + HealthKit entitlement.
- Slice 16 fallback (re-notification on missed dose) — pairs with HKObserverQuery.

### Fixed
- `scripts/check-clean.sh` now `mkdir -p build` before invoking `gitleaks --report-path build/gitleaks.json`. Without this, every CI run since `4d62a8c` failed because the Ubuntu runner does not pre-create the build/ directory.

### Tests
- 39 unit tests, all green: `BlockTests`×3, `RoutineTemplateTests`×4, `SwiftDataRoutineRepositoryTests`×4, `BlockEditorViewModelTests`×8, `TodayViewModelTests`×5, `NotificationFactoryTests`×5, `MedicationComplianceTests`×4, `BedtimeCalculatorTests`×6.

### i18n
- `Localizable.xcstrings`: ~110 keys × 3 locales (EN + ES + FR). Categories (12), day types (4), tab labels (5), common actions (6), per-feature strings.

---

## Version conventions

- **MAJOR** — breaking changes to data model, public API, or supported OS minimums.
- **MINOR** — new modules / features (additive).
- **PATCH** — bug fixes, dependency bumps, doc updates.

Pre-1.0 versions (`0.x.y`) bump MINOR for any user-visible change and PATCH for fixes.
