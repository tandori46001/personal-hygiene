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
| L001 | Keep `ModelContainer` alive for the lifetime of any `ModelContext` built from it; never drop it from a helper | `SwiftDataRoutineRepositoryTests` exercises insert + cascade-delete + relationship-append (suite crashes if regressed) |
| L002 | A notification-identifier parser must recognize every module's prefix; model the prefix as an enum so adding a kind without updating the parser is a compile error | `BlockNotificationIdentifierTests.test_parse_recognizesAllKnownPrefixes` iterates `NotificationKind.allCases` and round-trips each |
| L003 | Files in `App/Shared/` using iOS-only APIs (UIGraphicsPDFRenderer, UIActivityViewController, etc.) must be `#if canImport(UIKit) && !os(watchOS)`-guarded — the watch target compiles `Shared/` too | `./scripts/deploy-watch.sh --no-install` builds the watch scheme; run after touching `Shared/` |
| L004 | Tab-root views inside iOS 18 TabView "More" overflow must NOT add their own `NavigationStack` (More provides one); doing so produces two stacked back chevrons on every push | Manual on-device check: open any overflowed tab → push into a child → exactly one back arrow |
| L005 | Test process crashes (signal-trap / "Restarting after unexpected exit") must NOT be filtered as the LLDB glitch in `check-tests.sh` — a real crash with no failed-test-method line silently passed CI | `scripts/check-tests.sh` counts process-crash lines separately; treats them as real failures regardless of exit code |
| L006 | `Text(LocalizedStringKey("foo.\(rawValue)"))` looks up `"foo.%@"`, not the runtime key — UI shows raw keys (`category.work` etc.). Use `Text(localizedKey: "foo.\(rawValue)")` for discrete-suffix lookups; xcstrings keys with placeholders must include the matching `%@` / `%lld` suffix | `BundleLocalizationLookupTests` resolves every enum-driven discrete-suffix key + every format-string key through `Bundle.main`; round-19 SwiftLint custom rule `dynamic_localized_key` rejects new `LocalizedStringKey("...\(...)")` at compile time; backup `scripts/check-localized-key-usage.py` and `scripts/check-xcstrings-format-consistency.py` static scans run alongside |
| L007 | **Inverse of L004**: a tab-root MISCLASSIFIED as More-overflow loses its system-provided `NavigationStack`. Without one, `.navigationTitle` and `.toolbar` don't render — view chrome silently disappears. Update `scripts/check-tabroots.py` `TAB_ROOTS` whenever the iOS 18 TabView grows or reorders | Manual `QA_MANUAL.md` checklist after every TabView reorder: open each direct tab (first 4) → confirm title + ≥1 toolbar item visible. Future: XCUITest smoke per direct tab |
| L008 | Prefer SwiftData `@Query` over repository-cached VM properties for **cross-tab reactive state**. `@Observable var activeTemplate` populated by `repository.fetch(...)` goes stale across iOS 18 TabView switches; `@Query` observes the modelContext directly and auto-refreshes. Repository pattern stays fine for one-shot writes | None automated yet. Future: XCUITest smoke "create entity in tab A → switch to tab B → assert reactive re-render <1s" |

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
| 0 — Bootstrap | ✅ Done | Repo + tooling ready · Xcode project · CI green |
| 1 — MVP daily routine | 🟡 ~99.99% | M1+M2+M3+M4 code-complete; rounds 12-25 polish layer (per-block followup, pause, theme, mute, bedtime auto-mute + plan check + variance verdict + consistency score + sleep debt tracker, quiet hours, dose history + adherence + skip-dose + 30-day chart + streak counter + monthly trend + missed-dose probe + CSV export, stale-day banner, conflict detector + overlap visualizer + gantt + long-press helper, undo preset, snooze-30, mood quick-log + Charts trend + week strip + emoji filter + weekly goal + localized CSV + streak caption + weeklyDelta + histogram + heatmap + share-as-image, tomorrow disclosure, about-build footer, now-marker tap-to-scroll, reset-day undo, block-title history + autocomplete v2, tag autocomplete, renumber starts, refresh-trace toast + recent summary, block CSV import + warnings sheet, ⌘D / ⌘N / ⌘⇧D shortcuts, ad-hoc Focus toggle, day-completion bar + chip + ring, cascade shift, archive store + UI + badge + filter + exporter, single-template backup share, sleep weekly average chart + delta + share-as-image, "Reset all caches" destructive + confirm dialog, backup v6 with archived templates + housekeeping log, restore-preview + checksum, diagnostics everything-v2 bundle + latency histogram + last-error log). Remaining: real-device validation + paid Apple Developer Program. |
| 2 — Apple Watch | ✅ ~99% | Round 19 added complication line-3, theme/pause mirrors, snooze-30 + skip-dose actions. Round 21 added Hydration glance + Mood quick-log + complication pause badge + mark-done undo capsule. Round 22 added hydration goal proportion, pending count + clear, complication mood emoji, settings mood week strip, swipe-back haptic + iPhone-side reconciler. Round 23 added mood-streak chip, custom hydration stepper, pause-from-watch buttons, complication theme tint, swipe-up skip-rest-of-day. Round 24 added BlockDetail snooze menu (5/10/15), settings reset-pending-taps, complication line-3 day-completion %. Watch deployed live to round-24. |
| 3 — Secondary modules | ✅ Done | M5 hydration (+ watch reconciler), M6 housekeeping (+ streak + auto-snooze helper + completion log + banner), M7 birthdays (+ relationship/idea stores + gift CSV exporter UI + global lead-time stepper UI), M8 deep focus (+ right-now + conflict + ad-hoc toggle + auto-mirror mute to watch). |
| 4 — TestFlight beta | 🔒 Blocked | Needs paid Apple Developer Program ($99/yr). |
| 5 — Vacation module | ✅ Feature-complete | M9 closed: trips + milestones + reminders + scanner + AI itinerary + marine + currency (+ CSV table copy) + 5-source advisory + PDF + notes (Markdown + weather forecast template) + archive + cost log + carbon estimate + 30-day footprint summary + emergency contacts + monthly expense summary + duplicate-with-shifted-dates + duplicate-to-next-year + milestone-defaults bundle + WeatherKit scaffolding (entitlement-gated bridge, 6h cache, itinerary forecast chip). Real-trip validation pending. |
| 6 — App Store | ⬜ | Submission + listing in 3 languages. |

> Source of truth for phase progress — must match `memory/project_status.md` and `ROADMAP.md § Phases`. Last synced: round 25.

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

## 10. `ALL OK?` — UNIFIED SESSION PULSE (expanded round 25 / session 23)

When the user says `ALL OK?` / `pulse?` / `que tal va?` / `estado?`, run a full system audit. **Verify EVERYTHING.** No skipping. The user expects this to surface bugs, incoherencies, and a forward-looking 100-task backlog every time.

### A. Per-platform completion %

Compute the % of *acceptance criteria delivered* per surface, not lines of code. Cite source: `ROADMAP.md`, `memory/project_status.md`, what's actually built vs what's blocked.

| Surface | % | Source-of-truth |
|---|---|---|
| iPhone (iOS) | x% | Phase 1+3+5 acceptance |
| Apple Watch (watchOS) | x% | Phase 2 acceptance |
| Backend | x% | None planned (CloudKit private DB only — see PRD §2) |
| Web | x% | Phase 7d (future, not started) |
| Android | x% | Phase 7c (future, not started) |
| macOS | x% | Phase 7b (future, not started) |
| TestFlight beta | x% | Phase 4 acceptance |
| App Store listing | x% | Phase 6 acceptance |

If a surface is *deliberately not in scope*, mark **n/a** and link to the PRD line that excludes it.

### B. Drift + incoherencies + bugs check

- **Git state:** branch, ahead/behind, uncommitted, untracked.
- **Memory files:** `memory/MEMORY.md` index, `memory/session_handoff.md` recency, `memory/project_status.md` recency. Flag anything >7 days stale.
- **Doc parity:** `ROADMAP.md` phase line == `CLAUDE.md §8` line == `memory/project_status.md`. Three-way sync.
- **Test + lint state:** last `./scripts/check-tests.sh` exit; counts; process-crash count.
- **i18n parity:** `LocalizationKeyCount.total` matches `grep -c '"extractionState"' Localizable.xcstrings`.
- **Lessons:** any new class-of-bug observed without an L0NN entry?
- **Cross-code consistency:**
  - `XC79TD476V` (or current `DEVELOPMENT_TEAM`) — Personal vs paid?
  - `CommitSHA.txt` on device == HEAD?
  - `.tint(.tint)`, `Menu`, or other watchOS-incompatible API surfaces in `Shared/`?
  - `LocalizationKeyCount.total` constant updated since last xcstrings change?
- **Deferred items:** anything in `session_handoff.md` "next step" that didn't ship; carry forward.
- **Stale TODO/FIXME/XXX comments** in code.
- **Apple Developer Program gate:** which features are still gated? List explicitly.

### C. 100 forward tasks — classified + batched

Produce a numbered list of the next **≥100 tasks** classified by:
- **Surface** (iPhone / Watch / Backend / Web / Android / macOS / DevOps / Docs / QA)
- **Batch** (groups of tasks deliverable end-to-end at 100% with NO inter-batch dependencies — explicit "depends on Batch X" notes for sequencing)

Each task = one line: `[ID] [Surface] [Batch] short description`. Include an **estimated effort** when relevant (S/M/L). When a task is gated by Apple (entitlement, review), mark it 🔒.

Batch organization rules:
- A batch must be *atomically deliverable* — if you ship the batch, all its tasks land together with no half-finished state.
- A batch must explicitly state its dependencies (e.g., "Batch C depends on Batch B's Apple Developer Program activation").
- Each batch should fit in **one round** (≤40 slices) when possible.

### D. "Anything else?" — proactive flags

Before closing, surface anything observed during the audit that doesn't fit cleanly above:
- Risk: external dependencies (Apple review queues, weather API rate limits, Frankfurter availability).
- Tech debt: places where shortcuts were taken that should be paid back.
- L007+ candidates: bug classes that haven't earned an L-entry yet but probably should.
- Memory gaps: things that should be in `memory/` but aren't.
- Privacy / security: any change that touched user data flow worth reviewing.

### E. Action menu

Numbered options the user can pick (each a one-liner). Include "do nothing — just commit", "run round N", "validate on device", "deploy", etc.

### Subset triggers

- `no hace falta nada?` — runs only §B (drift half).
- `pulse?` (short) — §A + §B + §E only (skip 100-task list).
- `ALL OK ?` (full) — A through E, complete.

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
