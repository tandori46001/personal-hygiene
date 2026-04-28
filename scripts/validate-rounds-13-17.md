# On-device validation walk-through — rounds 13-17

**Generated:** 2026-04-28 (session 15) · **Cases covered:** T-101 → T-122 (22 manual cases) · **Device:** iPhone 15 Pro Max running round 17 build (HEAD).

## How to use this document

1. Deploy round 17 to the iPhone: `./scripts/deploy-iphone.sh` from this repo. Do **not** auto-deploy the Apple Watch — per workflow policy, watch deploys require explicit request.
2. Walk top-to-bottom. Each case prints the entry path + the assertion. If a case fails, capture the screenshot, write the actual behavior under "Result", and stop until triaged.
3. Mark each case **PASS** / **FAIL** / **SKIP** with a one-line note.
4. When the whole list is PASS, paste the table from the bottom of this file into `memory/session_handoff.md` under "On-device validation pass".

---

## Round 13 cases (T-101…T-105)

### T-101 — Trip notes paragraphs render separately
**Path:** Trips → open any trip → Notes section.
**Assert:** A multi-paragraph note shows blank-line separators (Markdown-style paragraphs), not a single wall of text.
**Result:** ☐ PASS  ☐ FAIL  ☐ SKIP — _notes:_

### T-102 — Trip Markdown share + cost log
**Path:** Trips → open trip → "Share Markdown" toolbar action; then "Cost log" section.
**Assert:** (a) Share sheet contains the trip's Markdown (title, dates, milestones, expenses). (b) Adding a cost log line persists across a kill-launch and surfaces in the per-currency summary footer when ≥2 entries exist.
**Result:** ☐ PASS  ☐ FAIL  ☐ SKIP — _notes:_

### T-103 — Diagnostics: snapshot history + auth timeline + network activity
**Path:** Settings → Diagnostics → Advanced (expand).
**Assert:** (a) "Export diagnostics snapshot" twice → "Snapshot history" disclosure shows 2 entries with build SHA + pending count + widget reloads. (b) Toggle notification permission off in iOS Settings → return → "Auth timeline" gains a row. (c) Currency convert with network → `frankfurter` count in "Network activity" goes up by 1.
**Result:** ☐ PASS  ☐ FAIL  ☐ SKIP — _notes:_

### T-104 — Today: hide-completed toggle + minute-tick caption
**Path:** Today tab.
**Assert:** (a) Toggling "Hide completed blocks" hides done rows. (b) The "in N min" caption updates every minute (watch a 5-min boundary).
**Result:** ☐ PASS  ☐ FAIL  ☐ SKIP — _notes:_

### T-105 — Bedtime auto-mute
**Path:** Settings → Sleep / Bedtime.
**Assert:** Within the bedtime-mute window, non-medication categories suppress; medications still fire. Outside the window, all categories fire.
**Result:** ☐ PASS  ☐ FAIL  ☐ SKIP — _notes:_

## Round 14 cases (T-106…T-107)

### T-106 — Trip emergency contacts + per-currency expense totals
**Path:** Trips → trip detail → Emergency contacts section + Expenses section.
**Assert:** (a) Add a contact with phone-pad input → persists across kill-launch. (b) Two expenses in two currencies → footer shows totals split per currency.
**Result:** ☐ PASS  ☐ FAIL  ☐ SKIP — _notes:_

### T-107 — Quiet hours store + bedtime auto-mute interplay
**Path:** Settings → Quiet hours toggle (round 17 surfaces it; backing store landed in 14).
**Assert:** During quiet hours window: non-medication notifications suppressed regardless of bedtime-mute state.
**Result:** ☐ PASS  ☐ FAIL  ☐ SKIP — _notes:_

## Round 15 cases (T-108…T-110)

### T-108 — Template duration footer + milestone bundle one-tap
**Path:** Templates → editor footer; Trips → milestone empty-state.
**Assert:** (a) Editor footer reads "Total: Xh Ym · N blocks" matching the actual sum. (b) Trip milestone empty-state "Add 6m/3m/1m/1w defaults" is idempotent — tapping twice does not double-create.
**Result:** ☐ PASS  ☐ FAIL  ☐ SKIP — _notes:_

### T-109 — Hydration weekly average caption
**Path:** Hydration tab.
**Assert:** Caption "Weekly average: X ml/day" appears under the chart when ≥1 day in the trailing 7 has logs. Hidden when zero.
**Result:** ☐ PASS  ☐ FAIL  ☐ SKIP — _notes:_

### T-110 — Birthdays relationship filter chips
**Path:** Birthdays tab → filter chips row.
**Assert:** Chips reflect the user's tagged relationships (round 13 store). Tapping a chip filters the list.
**Result:** ☐ PASS  ☐ FAIL  ☐ SKIP — _notes:_

## Round 16 cases (T-111…T-114)

### T-111 — Medication dose history view (read-only)
**Path:** Medication tab — direct push (round 17 wire) OR snapshot the view from a preview.
**Assert:** Lists last 30 days of medication-only completions, newest first, with concept identifier text-selectable.
**Result:** ☐ PASS  ☐ FAIL  ☐ SKIP — _notes:_

### T-112 — Trip carbon footprint section
**Path:** Trips → open a trip with destination geocoded AND home location set in Settings.
**Assert:** "Estimated round-trip CO₂: X kg" inline section visible. Hidden if either endpoint missing — verify by clearing home location.
**Result:** ☐ PASS  ☐ FAIL  ☐ SKIP — _notes:_

### T-113 — Housekeeping room icons store
**Path:** Round-17 wires this with a picker (T-122). For round 16, store can only be exercised programmatically.
**Assert:** N/A — covered by T-122 below.
**Result:** ☐ PASS  ☐ FAIL  ☐ SKIP — _notes:_

### T-114 — Focus filter preview helper
**Path:** Round-17 wires this (T-118).
**Assert:** N/A — covered by T-118 below.
**Result:** ☐ PASS  ☐ FAIL  ☐ SKIP — _notes:_

### T-115 — Snapshot history + auth timeline + network activity (re-run)
Same as T-103. Re-validate that the round-13 surfaces still work after rounds 14-17 layered on top.
**Result:** ☐ PASS  ☐ FAIL  ☐ SKIP — _notes:_

## Round 17 cases (T-116…T-122)

### T-116 — Medication tab → DoseHistoryView NavigationLink
**Path:** Medication tab → tap "Dose history" row beneath the 7-day section.
**Assert:** Pushes DoseHistoryView with last-30-days medication completions newest-first. Empty state when zero.
**Result:** ☐ PASS  ☐ FAIL  ☐ SKIP — _notes:_

### T-117 — TemplateEditor → "Insert preset bundle" menu
**Path:** Templates → editor → "Insert preset bundle" menu.
**Assert:** Tapping "Workday" on a template ending before 9:00 inserts 3 blocks at 9:00/10:30/13:00. Tapping "Morning routine" on a template ending at 10:30 shifts seeds so first inserted block sits at 10:30.
**Result:** ☐ PASS  ☐ FAIL  ☐ SKIP — _notes:_

### T-118 — FocusScheduleView "Right now" preview
**Path:** Settings → Focus → with at least one window covering the current minute.
**Assert:** "Right now" section appears with active block title + "X silenced" caption. Hidden outside any active window.
**Result:** ☐ PASS  ☐ FAIL  ☐ SKIP — _notes:_

### T-119 — Settings → Quiet hours section
**Path:** Settings → Quiet hours.
**Assert:** Toggle off → only toggle row + footer. Toggle on → start/end DatePickers appear and persist across kill-launch.
**Result:** ☐ PASS  ☐ FAIL  ☐ SKIP — _notes:_

### T-120 — Settings → Backup schedule picker
**Path:** Settings → Backup schedule (below Backup actions).
**Assert:** Picker with Off / Weekly / Daily. Selection persists across kill-launch. Footer notes future-phase engine.
**Result:** ☐ PASS  ☐ FAIL  ☐ SKIP — _notes:_

### T-121 — Diagnostics → Pending IDs by group disclosure
**Path:** Settings → Diagnostics → Advanced → expand → "Pending IDs by group".
**Assert:** Disclosure shows total count. Expand → one sub-disclosure per non-empty category with raw identifiers (truncate-middle).
**Result:** ☐ PASS  ☐ FAIL  ☐ SKIP — _notes:_

### T-122 — Housekeeping → Room icon picker
**Path:** Housekeeping tab → +.
**Assert:** Type title + room → "Room icon" picker appears with 8 SF Symbol choices. Saving persists icon. Row in list renders chosen symbol next to room name. Re-opening the sheet for the same room auto-loads the chosen icon.
**Result:** ☐ PASS  ☐ FAIL  ☐ SKIP — _notes:_

---

## Summary table — paste into `memory/session_handoff.md` after the run

| Case | Result | Notes |
|---|---|---|
| T-101 | | |
| T-102 | | |
| T-103 | | |
| T-104 | | |
| T-105 | | |
| T-106 | | |
| T-107 | | |
| T-108 | | |
| T-109 | | |
| T-110 | | |
| T-111 | | |
| T-112 | | |
| T-113 | covered by T-122 | |
| T-114 | covered by T-118 | |
| T-115 | | |
| T-116 | | |
| T-117 | | |
| T-118 | | |
| T-119 | | |
| T-120 | | |
| T-121 | | |
| T-122 | | |

---

## Hot path (if you only have 5 minutes)

1. **T-102** — trip Markdown share is the easiest visual smoke test of round-13 cost log.
2. **T-103** / **T-115** — Diagnostics snapshot history confirms the observability spine.
3. **T-105** — bedtime auto-mute is the highest-risk silencer to validate.
4. **T-112** — round-16 carbon estimate is brand new on the trip detail screen.
5. **T-117** — TemplatePresets insertion is the most complex round-17 wire.
6. **T-119** + **T-120** — confirm the new Settings sections are reachable without crashing.

After the hot path, spread the rest over a longer session.
