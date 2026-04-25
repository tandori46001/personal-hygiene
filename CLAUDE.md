# CLAUDE.md — instructions for Claude Code

This file is read automatically at the start of every Claude Code session in this repository.

---

## 1. MANDATORY SESSION STARTUP — read these first

In order, before responding to any user request:

1. `~/.claude/projects/-Volumes-USB1TBWD--develop--repos-personal-hygiene/memory/MEMORY.md` → index of memory files
2. `~/.claude/projects/-Volumes-USB1TBWD--develop--repos-personal-hygiene/memory/session_handoff.md` → what happened last (when present)
3. `~/.claude/projects/-Volumes-USB1TBWD--develop--repos-personal-hygiene/memory/project_status.md` → roadmap progress (when present)
4. `~/.claude/projects/-Volumes-USB1TBWD--develop--repos-personal-hygiene/memory/feedback_working_style.md` → how this user works
5. `PRD.md` → product requirements
6. `ROADMAP.md` → current phase + acceptance criteria
7. `LESSONS.md` → numbered lessons (never repeat past mistakes)

---

## 2. PROJECT IDENTITY

**What:** Native iOS + watchOS personal scheduling app with military-precision time blocks. Single-user. Reliable medication reminders. Holistic vacation module. CloudKit sync.

**What it is NOT:** not multi-user, not a calendar replacement, not a habit gamifier, not analytics-heavy, not for sale (yet), no backend.

**Privacy stance:** All data stays in the user's Apple ecosystem. No telemetry. No third-party SDKs.

**Languages:** UI in ES + EN + FR. Documentation in English. Conversation in user's preferred language (Spanish currently).

---

## 3. TECH STACK (verified 2026-04-25)

| Layer | Choice | Version |
|---|---|---|
| Language | Swift | 6.0+ |
| UI | SwiftUI | iOS 18+, watchOS 11+ |
| Persistence | SwiftData (preferred) or CoreData + CloudKit | iOS 18+ |
| Sync | CloudKit Private Database | — |
| Health | HealthKit (Medications + Sleep) | iOS 18+ |
| Calendar | EventKit | — |
| Contacts | Contacts framework | — |
| OCR | VisionKit + Vision | — |
| AI | Apple Intelligence Foundation Models | iOS 18.1+ |
| Weather | WeatherKit | — |
| Marine | Open-Meteo Marine API | — |
| Currency | Frankfurter API | — |
| CI | GitHub Actions (`macos-latest`) | — |
| Lint | SwiftLint + swift-format | latest |

---

## 4. ARCHITECTURE PATTERNS

- **One type per file.** File name = type name.
- **MVVM with SwiftUI.** Views observe `@Observable` view models. No business logic in views.
- **Shared module** for code used by both iOS + watchOS targets (in `App/Shared/`).
- **Feature-folder layout** (`App/PersonalHygiene/Features/<Module>/`), not type-folder layout.
- **Async/await first.** No completion handlers in new code.
- **No third-party dependencies** unless absolutely necessary — prefer Apple frameworks.
- **i18n: every UI string** goes through `Localizable.xcstrings`. Hardcoded user-facing strings = build error (SwiftLint custom rule TBD).

---

## 5. TECHNICAL LESSONS — quick reference

See [LESSONS.md](LESSONS.md) for full text. Quick table:

| L0NN | Rule | Guard |
|---|---|---|
| (none yet) | Lessons accrue from real bugs encountered | — |

---

## 6. DEVELOPMENT WORKFLOW

### Branches
- `main` — always green.
- `feat/*`, `fix/*`, `chore/*`, `docs/*`, `ci/*`.

### Commits
[Conventional Commits](https://www.conventionalcommits.org/). Scopes match module names (`routine`, `medication`, `sleep`, `vacation`, `watch`, `prd`, `ci`, etc.).

### QA-mandatory protocol
**Every bug fix and every new feature MUST update tests in the same commit.** No exceptions. See [CONTRIBUTING.md § QA-mandatory rule](CONTRIBUTING.md).

### Pre-commit checklist
```
[ ] Tests added / updated for this change?
[ ] QA_MANUAL.md updated with [T-XXX] case?
[ ] ./scripts/check-tests.sh — green?
[ ] ./scripts/lint.sh — green?
[ ] If new class of bug: LNNN entry + guard test in LESSONS.md?
[ ] Updated ROADMAP.md / PRD.md if scope changed?
[ ] memory/session_handoff.md updated if shipping work?
```

### Push policy
**Default: do NOT push to `origin/main` without explicit user authorization.** Feature branches may push freely.

---

## 7. QA & TESTING STRATEGY

### Test pyramid

| Layer | Tool | Target |
|---|---|---|
| Unit | XCTest | Pure functions, view models, services |
| Integration | XCTest + in-memory CloudKit container | Persistence + sync flows |
| UI | XCUITest | Critical user flows only |
| Static scan | shell script under `scripts/check-*.sh` | Cross-cutting bug classes (L0NN guards) |

### What NOT to do
- ❌ Don't mock HealthKit at integration boundaries — use a fake real store with seeded data.
- ❌ Don't use `XCTSkip` to silently disable broken tests — fix or delete them.
- ❌ Don't auto-commit AI-generated tests without human review (hollow assertions risk).

---

## 8. WHAT'S BUILT

| Phase | Status | Acceptance |
|---|---|---|
| 0 — Bootstrap | 🟡 In progress | Repo + tooling ready |
| 1 — MVP daily routine | ⬜ | See [PRD.md § 11](PRD.md#11-acceptance-criteria-por-fase) |
| 2 — Apple Watch | ⬜ | Watch app + complications |
| 3 — Secondary modules | ⬜ | Hydration, housekeeping, contacts, deep focus |
| 4 — TestFlight beta | ⬜ | 30 days personal use |
| 5 — Vacation module | ⬜ | Full international trip end-to-end |
| 6 — App Store | ⬜ | Submission + listing in 3 languages |

---

## 9. DEV ENVIRONMENT COMMANDS

| User says | Action |
|---|---|
| `bootstrap` | Run `./scripts/bootstrap.sh` (install SwiftLint + swift-format) |
| `lint` | Run `./scripts/lint.sh` |
| `format` | Run `./scripts/format.sh` |
| `run all tests` / `check tests` | Run `./scripts/check-tests.sh` |
| `commit` (alone) | Confirm scope, commit, do NOT push unless asked |
| `push` | Push current branch to upstream (NEVER `main` without explicit OK) |
| `continua` | Read `memory/session_handoff.md` next-step and continue |

---

## 10. `ALL OK?` — UNIFIED SESSION PULSE

When the user says `ALL OK?` / `pulse?` / `que tal va?` / `estado?`, run a full drift check + forward-look:

**A. Drift check:** git state · memory files · ROADMAP status · PRD/ARCH staleness · QA_MANUAL coverage · test status · env sanity · cross-code consistency.
**B. Next:** active milestone + open follow-ups + recommended next slice.
**C. Session:** continue here / soft yes (after next commit) / yes new session now.
**D. Action menu:** numbered options for the user to pick.

Subset trigger `no hace falta nada?` runs only the drift half (§A).

---

## 11. SESSION END CHECKLIST

When wrapping up:
1. Update `memory/session_handoff.md` — what was done, git state, next step.
2. Update `memory/project_status.md` if any phase status changed.
3. Update `LESSONS.md` if a new technical mistake was made + fixed.
4. Update `ROADMAP.md` if a phase advanced.
5. Verify `CHANGELOG.md` reflects any user-visible change.

---

## 12. DOCUMENTATION FILES

| File | Purpose |
|---|---|
| [README.md](README.md) | Project overview, status, getting started |
| [PRD.md](PRD.md) | Product requirements |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Technical architecture |
| [ROADMAP.md](ROADMAP.md) | Phase tracker |
| [LESSONS.md](LESSONS.md) | Numbered lessons |
| [QA_MANUAL.md](QA_MANUAL.md) | Manual test checklist |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Dev workflow |
| [SECURITY.md](SECURITY.md) | Vuln disclosure policy |
| [CHANGELOG.md](CHANGELOG.md) | Notable changes |
