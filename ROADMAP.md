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

### Phase 1 — MVP daily routine (iOS only) 🟡

**Goal:** end user follows full daily routine on iPhone for 14 consecutive days using only this app's notifications.

Modules: M1 (templates) · M2 (notifications) · M3 (medication) · M4 (sleep).

| Acceptance | Status |
|---|---|
| Domain models for routine (`Block`, `RoutineTemplate`) with tests | ✅ |
| First UI slice — `RoutineListView` rendering blocks | ✅ |
| i18n catalog (`Localizable.xcstrings`) with EN+ES+FR | ✅ (1 key) |
| Routine template created and editable | ⬜ |
| Persistence (SwiftData + CloudKit) | ⬜ |
| Notifications arrive 15min before each block | ⬜ |
| HealthKit Medications integrated (Critical Alerts or fallback) | ⬜ |
| Sleep block with auto-bedtime calculation, HealthKit Sleep read | ⬜ |
| i18n complete — zero untranslated keys | ⬜ |
| 14 consecutive days of real personal use | ⬜ |

---

### Phase 2 — Apple Watch companion ⬜

**Goal:** glanceable schedule on the wrist + ability to mark blocks done from Watch.

| Acceptance | Status |
|---|---|
| watchOS app with current-day blocks list | ⬜ |
| At least one complication ("next block") | ⬜ |
| Haptic notifications mirror iPhone | ⬜ |
| Mark block done from Watch | ⬜ |

---

### Phase 3 — Secondary modules ⬜

Modules: M5 (hydration) · M6 (housekeeping) · M7 (contacts birthdays) · M8 (deep focus).

| Acceptance | Status |
|---|---|
| Hydration reminders configurable | ⬜ |
| Housekeeping tasks recurring + escalation | ⬜ |
| Birthdays imported from Contacts | ⬜ |
| Deep Focus mode silences non-critical alerts | ⬜ |

---

### Phase 4 — TestFlight beta ⬜

**Goal:** stable build for personal real-world use during 30 days.

| Acceptance | Status |
|---|---|
| TestFlight build accepted | ⬜ |
| 30 days bug-bashing on real device | ⬜ |
| ≥ 99% medication adherence over 30 days | ⬜ |

---

### Phase 5 — Vacation module ⬜

**Goal:** complete an international trip end-to-end with the app handling all preparation + on-trip + return.

Module M9 — see [PRD.md § 6 M9](PRD.md#m9--módulo-vacaciones-fase-final) for requirements breakdown.

| Acceptance | Status |
|---|---|
| Trip setup < 2 minutes | ⬜ |
| Escalated reminders (6m → day-D) generated | ⬜ |
| Documents scanned + Keychain-encrypted, offline-accessible | ⬜ |
| AI itinerary generated (on-device) | ⬜ |
| Marine weather + tides shown for marine activities | ⬜ |
| Currency conversion + cash estimate | ⬜ |
| Advisory from exteriores.gob.es for destination | ⬜ |
| PDF export shareable via Mail/SMS/WhatsApp | ⬜ |
| Validated with one real international trip | ⬜ |

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
