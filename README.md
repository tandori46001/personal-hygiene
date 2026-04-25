# personal-hygiene

> A personal daily-schedule app with military-precision time blocking.
> Native iOS + Apple Watch · Swift / SwiftUI · CloudKit · Apple Intelligence on-device.

[![CI](https://github.com/tandori46001/personal-hygiene/actions/workflows/ci.yml/badge.svg)](https://github.com/tandori46001/personal-hygiene/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Swift 6](https://img.shields.io/badge/Swift-6.0+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-iOS%2018+%20%7C%20watchOS%2011+-lightgrey.svg)](https://developer.apple.com)

---

## Status

⬜ Pre-bootstrap. Spec done, code not started.

| Phase | Status |
|---|---|
| 0 — Bootstrap (repo + tooling) | 🟡 In progress |
| 1 — MVP daily routine (iOS) | ⬜ Planned |
| 2 — Apple Watch companion | ⬜ Planned |
| 3 — Secondary modules | ⬜ Planned |
| 4 — TestFlight beta | ⬜ Planned |
| 5 — Vacation module | ⬜ Planned |
| 6 — App Store release | ⬜ Planned |
| 7 — Additional platforms | ⬜ Future |

See [ROADMAP.md](ROADMAP.md) for detailed status.

---

## What this is

A personal scheduling app that covers 100% of the user's day with **time blocks of military precision** — hygiene, breakfast, sport, work, meals, medical appointments, shopping, medication, social, sleep — and reliable notifications on iPhone + Apple Watch.

Differentiated by:

1. **Total day coverage**, not just tasks: includes meals, hydration, medication, sleep.
2. **Holistic Vacation module**: escalated reminders from 6 months out, AI itinerary, marine weather (diving, tides, swell), currency, official advisories, document checklist.
3. **Watch-first** UX: 1-2 second glanceable interactions on the wrist, not the pocket.

For full requirements, see [PRD.md](PRD.md).

---

## Tech stack

| Layer | Choice | Why |
|---|---|---|
| Language | Swift 6 | Native Apple |
| UI | SwiftUI (iOS 18+ / watchOS 11+) | One paradigm for both targets |
| Sync | CloudKit | Free, integrated, E2E |
| Health | HealthKit Medications + Sleep | Official APIs (WWDC25) |
| AI | Apple Intelligence (on-device) | Free, private; external providers later |
| Weather | WeatherKit + Open-Meteo Marine | Free tiers |
| Currency | Frankfurter | Free, no auth |

For technical decisions, see [ARCHITECTURE.md](ARCHITECTURE.md).

---

## Getting started

### Prerequisites

- macOS Sequoia or later
- Xcode 16+
- Apple Developer account (for HealthKit + CloudKit + Critical Alerts entitlements)

### Local setup

```bash
git clone https://github.com/tandori46001/personal-hygiene.git
cd personal-hygiene
./scripts/bootstrap.sh         # install SwiftLint, swift-format
open App/PersonalHygiene.xcodeproj  # once project is generated (Phase 0)
```

### Run tests

```bash
./scripts/check-tests.sh
```

---

## Repo layout

```
.
├── App/                  # Xcode project + iOS + watchOS targets (TBD in Phase 0)
├── Tests/                # Unit + integration + UI tests
├── docs/                 # Long-form architecture notes, design docs
├── scripts/              # Dev + CI helpers (bash 3.2 compatible)
├── .github/              # CI workflows, issue + PR templates, dependabot
├── PRD.md                # Product requirements
├── ARCHITECTURE.md       # Technical architecture
├── ROADMAP.md            # Milestone tracker
├── CLAUDE.md             # Instructions for Claude Code in this repo
├── LESSONS.md            # Numbered lessons learned (L001-L0NN)
├── QA_MANUAL.md          # Manual QA test checklist
└── README.md             # This file
```

---

## Documentation

| File | Purpose |
|---|---|
| [PRD.md](PRD.md) | Product requirements — what we're building and why |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Technical stack, module layout, data model |
| [ROADMAP.md](ROADMAP.md) | Phase-by-phase plan with status |
| [CLAUDE.md](CLAUDE.md) | Instructions Claude Code reads at session start |
| [LESSONS.md](LESSONS.md) | Captured lessons (numbered L0NN) |
| [QA_MANUAL.md](QA_MANUAL.md) | Manual test checklist (`[T-XXX]` sections) |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Dev workflow, branch + commit rules |
| [SECURITY.md](SECURITY.md) | Vulnerability disclosure policy |
| [CHANGELOG.md](CHANGELOG.md) | Notable changes per release |

---

## Privacy

This app does NOT send your data anywhere except:
- Apple iCloud (your private CloudKit container).
- Apple's WeatherKit (location coordinates only, when checking weather).
- Open-Meteo, Frankfurter (location coordinates / currency code only, when activated).

No backend. No tracking. No analytics. No third-party SDKs.

See [SECURITY.md](SECURITY.md) for vulnerability disclosure.

---

## License

[MIT](LICENSE) — see file for full text.
