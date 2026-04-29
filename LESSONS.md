# Lessons learned

> Numbered, immutable record of bug classes that bit twice + their guard tests.
> See [CLAUDE.md § 5](CLAUDE.md#5-technical-lessons--quick-reference) for the quick-reference table.
> See [PRD-START-NEW-PROJECT.md § 5](https://github.com/) for the lesson-capture loop methodology.

---

## When to lift a bug to a lesson

ALL of the following must be true:
- The bug class could plausibly recur (cross-cutting, easy to repeat, hard to spot in review).
- A guard test (static-scan or automated regression check) can fail the build if the bug returns.
- The fix is not just "rewrite this one function" — there's a pattern other code paths could repeat.

Do NOT lift one-off mistakes. A typo is not a lesson.

---

## Entry format

```markdown
## L0NN — One-line title

**Trigger pattern.** What code shape causes the bug.
**Symptom.** What the user / build / test sees.
**Root cause.** Why it happens.
**Fix.** Concrete change to apply.
**Guard test.** Where the regression check lives.
**Where it was caught.** Date + context.
**Interaction with other lessons.** Cross-references.
```

Mirror as a one-line entry in:
- `CLAUDE.md` quick-reference table.
- `~/.claude/projects/<repo-slug>/memory/lessons.md`.

---

## Lessons

## L001 — SwiftData `ModelContainer` must outlive its `ModelContext`

**Trigger pattern.** Helper function creates a `ModelContainer`, extracts `mainContext`, returns only the context. The container is deallocated when the helper returns; the orphan context can satisfy a few operations and then crash the host process on later writes / fetches / deletes.

**Symptom.** First SwiftData test passes. Subsequent tests using a repository or context built from the same helper start, but the test/simulator host dies with one of: "Invalid device state", "(ipc/mig) server died", "The system shell probably crashed", `NSPOSIXErrorDomain Code=64 "Host is down"`. The crash often happens during cascade-delete or relationship append and is reported AFTER several seemingly unrelated tests have already passed, making bisection misleading.

**Root cause.** `ModelContext` does not strongly retain its `ModelContainer`. SwiftData's in-memory store and SQLite store live inside the container; once it deallocates, the context's underlying coordinator is gone.

**Fix.** Keep the container alive for the entire lifetime of any context built from it.
- In tests: store both `container` and `context` as XCTestCase instance properties via `setUp`/`tearDown` (NOT in a helper that returns just the context).
- In the running app: hold the container in `@main` app state or a long-lived `@Environment` singleton.

**Guard test.** Added regression cases in `SwiftDataRoutineRepositoryTests` that cover insert + cascade-delete + relationship-append; the suite as a whole crashes the simulator if a future refactor reintroduces the orphan-context pattern.

**Where it was caught.** 2026-04-25, Phase 1 Slice 1+3 — bringing up `SwiftDataRoutineRepository` with a `makeSubject() -> (Repo, Context)` helper that dropped the container.

**Interaction with other lessons.** None yet — first L0NN.

---

## L002 — Notification-identifier parsers must enumerate every module's prefix

**Trigger pattern.** A central helper parses a notification identifier produced by *one* feature (e.g. routine blocks) and returns a domain ID. A second feature later starts producing notifications with a *different* prefix (hydration, trip milestones, medication). The parser silently returns `nil` for the new prefix, so any UI that depends on the parser (snooze badges, completion tracking, deep-link routing) goes dark for the new feature without compiling-time error.

**Symptom.** No crash, no warning. The new feature appears to "work" because the notification fires + actions still respond — but downstream state (snooze badge, last-fired timestamps, etc.) is silently never recorded. The bug is found only when a user reports "I snoozed it but no badge."

**Root cause.** The parser hard-codes a single `identifierPrefix` constant. Adding a new prefix requires editing the parser; nothing in the type system or lint enforces that.

**Fix.**
- Treat the identifier prefix as an *enumeration* (`enum NotificationKind { case routine, hydration, milestone, medication }`), not a string constant.
- The parser returns the kind alongside the parsed payload so callers can branch.
- When a new module is added, the parser's switch is non-exhaustive → compile error.

**Guard test.** `BlockNotificationIdentifierTests.test_parse_recognizesAllKnownPrefixes` enumerates every kind via `NotificationKind.allCases` and asserts that `parse` round-trips an identifier built for that kind. Adding a kind without updating `parse` fails the test.

**Where it was caught.** 2026-04-26, session 7 round 5 slice 13 — extending `BlockSnoozeStore` to record hydration + milestone snoozes revealed that the existing `BlockNotificationIdentifier.parse` only matched the routine prefix.

**Interaction with other lessons.** None.

---

## L003 — Files in `App/Shared/` that use platform-specific APIs must be `#if`-guarded for the *non-supporting* platform

**Trigger pattern.** A file lives in `App/Shared/` (compiled into iOS + watchOS + widget targets) but imports a framework or uses an API that exists on iOS but not watchOS (or vice versa). Common offenders: `UIGraphicsPDFRenderer`, `UIActivityViewController`, `MKDirections`, anything from `VisionKit`, `PhotosUI`, `CoreLocation` SignificantChange, full `UIKit` symbols not present on watch.

**Symptom.** iOS builds and tests are green for ages because the shared file compiles fine into the iOS target. The first time someone builds a watchOS target (or watch widget extension), the compiler errors with `'UIGraphicsPDFRendererContext' is unavailable in watchOS` (or similar). Often shows up months after the file was written, when adding watch features touches the same scheme.

**Root cause.** `Shared/` is compiled into every target. Apple's frameworks vary by platform; Swift surfaces this as `unavailable` errors only at compile time *for the offending target*. Without a watch build in CI, the error never trips.

**Fix.**
- Wrap iOS-only files in `#if canImport(UIKit) && !os(watchOS)` … `#endif` (or equivalent for the platform the file supports). Keeps a single source of truth, simply omits the file from non-supporting targets at compile time.
- Alternative: move the file out of `Shared/` into the iOS-specific feature folder. Cleaner if no other platform will ever want it; less flexible.

**Guard test.** `./scripts/deploy-watch.sh --no-install` (round 7) builds the `PersonalHygieneWatch` scheme. Running it after touching `App/Shared/` catches a regression immediately. CI is iOS-only today; consider adding a watchOS build job once Apple Developer Program lands and the Watch widgets settle.

**Where it was caught.** 2026-04-26, session 9 watch deploy — `TripPDFExporter.swift` (uses `UIGraphicsPDFRenderer`) lived in `Shared/Services/` since session 4 (M9 vacation PDF export); first watch build attempt during round 7 deploy surfaced four `unavailable in watchOS` errors. Same fix applied: `#if canImport(UIKit) && !os(watchOS)`.

**Interaction with other lessons.** None.

---

## L005 — Test process crashes (signal-trap) must NOT be filtered as the LLDB glitch in `check-tests.sh`

**Trigger pattern.** `xcodebuild test` exits non-zero with no `Test Case '...' failed` lines because the test PROCESS crashed mid-suite (signal trap, segfault, "Restarting after unexpected exit, crash, or test timeout"). `scripts/check-tests.sh` had a single condition — exit 65 + zero failed test methods — that classified the run as the harmless DebuggerLLDB glitch and returned exit 0. A real process-level crash silently passed CI.

**Symptom.** `./scripts/check-tests.sh` reports green; the xcresult bundle and the raw log show the suite restarted mid-run. Round 9's `TripsListViewModelArchiveTests` flake (an L001 regression — orphan ModelContext crashing the process) was masked this way. Bug surfaces only when someone opens the xcresult or notices a missing test in the count.

**Root cause.** The script's "treat as success" branch only counted `Test Case 'X' failed` lines + `error:` lines + `FAILED:`. None of those appear when the process itself dies — xcodebuild emits a generic "Restarting after unexpected exit" and exits 65, indistinguishable from the LLDB glitch by exit code alone.

**Fix.** Count `Restarting after unexpected exit, crash, or test timeout|signal trap|Encountered an error \(Crash:` matches separately. The "treat as success" branch now requires `PROCESS_CRASHES == 0` in addition to `REAL_FAILURES == 0`. Otherwise the script preserves the original exit code and surfaces a count of process crashes for the next session to investigate.

**Guard test.** Manual: introduce an L001-style orphan-context crash in any test class, run `./scripts/check-tests.sh`, verify exit code is non-zero and the script prints the crash count. (No automated test here — it would require provoking a real process crash, which is what the regression itself is.)

**Where it was caught.** 2026-04-26, session 12 round 10 — investigating the round-9 `TripsListViewModelArchiveTests` flake. Found that `makeListViewModel()` in `TripDetailViewModelTests.swift` returned `(vm, repo)` without retaining the `ModelContainer`. Fixed by storing `container` as a test-class property (the L001 fix) and hardened `check-tests.sh` so this class of regression can no longer pass silently.

**Interaction with other lessons.** Reinforces L001 — the orphan-container pattern was the *bug*; this lesson is about the *guard* that should have caught it.

---

## L004 — Tab-root views inside iOS 18 TabView "More" overflow must NOT add their own `NavigationStack`

**Trigger pattern.** A SwiftUI app has more tabs than iOS shows on the bar (5+ on iPhone). iOS 18 promotes the overflow into a system-provided "More" tab, which wraps each overflowed tab's content in its own `NavigationStack` so list-style navigation works. If the tab-root view *also* declares `NavigationStack { … }` at its top level, the two stacks nest. Every internal `NavigationLink` push then renders **two** stacked back chevrons in the navigation bar (one per stack).

**Symptom.** Tab-root view looks fine in isolation (visible tab, preview, simulator). The bug only shows up after enough tabs exist to trigger the More overflow + the user pushes from the overflowed tab into a child screen. Two circular `<` buttons appear stacked vertically; tapping the upper one pops twice, the lower one pops once. Looks like a styling glitch but is structural.

**Root cause.** iOS 18's More tab is implemented as a `NavigationStack` that pushes the picked tab's root onto its own stack. SwiftUI happily composes nested stacks, but each stack contributes its own back button when not at root.

**Fix.**
- Remove `NavigationStack { … }` from any view that's a tab root expected to live in More overflow. Keep `.navigationTitle()`, sheets, dialogs, and `NavigationLink` — they all work off the parent (More-provided) stack.
- For visible tab roots that NEVER overflow into More, keep the `NavigationStack` so previews and standalone presentation still work.
- Pragmatic rule for this repo: with 9 tabs, only the visible 4 (Today, Templates, Medication, Sleep) should keep `NavigationStack`; the overflowed 5 (Hydration, Housekeeping, Birthdays, Trips, Settings) should drop it.

**Guard test.** None automated — would need a UI test that detects two-back-button rendering, which XCUITest doesn't surface cleanly. Manual: open Settings → Diagnostics on a real device; should show one back arrow, not two. Add to `QA_MANUAL.md` as part of the on-device pass.

**Where it was caught.** 2026-04-26, session 10 round 8 deploy — user took a screenshot of `Settings → Diagnostics` showing two stacked `<` chevrons. Fixed in commit `5b038d0` by dropping the inner `NavigationStack` from `SettingsView`.

**Interaction with other lessons.** None.

---

## L006 — `Text(LocalizedStringKey("prefix.\(rawValue)"))` looks up `"prefix.%@"`, not the runtime key

**Class of bug.** SwiftUI's `LocalizedStringKey` (and `LocalizedStringResource`) initializers built from a string with interpolation **track the interpolation as a `%@` / `%lld` placeholder**, not as part of the lookup key. The runtime then asks the bundle for the format key — e.g. `"category.%@"` — instead of the literal runtime string `"category.work"`. If the xcstrings file stores discrete suffix keys (`"category.work"`, `"category.hygiene"`), the lookup misses and SwiftUI falls back to rendering the *raw resolved string verbatim* (`"category.work"`), which is exactly the user-facing key the developer intended to localize.

**Symptom.** UI shows raw localization keys like `category.work`, `housekeeping.recurrence.weekly`, `settings.snooze.duration.5`, `birthdays.relationship.family`. The xcstrings file contains all of those keys translated correctly, but they never resolve.

**Fix.**
- For dynamic enum-rawValue keys (discrete suffix), bypass `LocalizedStringKey`/`LocalizedStringResource` entirely. Use `NSLocalizedString` directly via the `Text(localizedKey: String)` extension shipped in `App/Shared/Localization/TextLocalizedKey.swift`. Always pass the runtime-built string; the extension resolves against `Bundle.main` and renders the result `verbatim`.
- For format-string keys (`"prefix \(int)"`), make sure the xcstrings file stores the key with the matching placeholder suffix — e.g. `"birthdays.daysUntil %lld"`, NOT `"birthdays.daysUntil"`. SwiftUI's lookup converts interpolations into `%@` (string), `%lld` (Int), `%f` (Double), etc.

**Guard test.** `BundleLocalizationLookupTests` in `Tests/Unit/Services/` exercises both the discrete-suffix and format-string variants against the live `Bundle.main` lookup. Adding a new dynamic key without translating it (or with a typo) fails the suite.

**Where it was caught.** 2026-04-28, session 16 post-round-18 deploy — user ran the app on the iPhone and screenshotted Today / Settings / Trips / Birthdays showing 9 separate raw keys: `category.work`, `category.hygiene`, `housekeeping.recurrence.weekly`, `settings.snooze.duration.5`, `settings.medication.followup.30`, `settings.marine.freshness.24`, `trip.packing.category.clothing`, `birthdays.daysUntil 28`, `settings.backup.autoFrequency.off`.

**Interaction with other lessons.** Independent of L001-L005. Reinforces the analysis-first workflow: dynamic keys must be paired with a deliberate xcstrings shape (discrete suffix vs format) and the call-site initializer must match.

---

## L007 — Misclassifying a tab-root as More-overflow silently breaks the entire view chrome

**Class of bug.** L004 told us tab-roots inside iOS 18 TabView's "More" overflow must NOT add their own `NavigationStack`. Round-12 added `scripts/check-tabroots.py` to enforce this. The script's `TAB_ROOTS` list pinned the views that were assumed to be in the More overflow. Any view in that list is rejected if it both has a `NavigationStack` AND uses `NavigationLink`. **But the script only knows what was true on the day it was written.** If the tab order changes (a new tab gets prepended, or a tab moves out of the overflow into the visible 4), a view that was once correctly NavigationStack-less becomes a *direct* tab — and direct tabs do NOT receive a system-provided `NavigationStack`. The view body then renders without any `.navigationTitle` or `.toolbar`, but it still compiles, runs, and passes tests because the failure mode is purely visual.

**Symptom.** A tab opens to a list view with **no title bar at all**, no toolbar buttons (no "+" to add, no overflow menu), no back arrow on push navigation. Visible on real device, easy to miss in simulator if you don't scroll-test. User-reported: "no puedo añadir template y los que importé no funcionan" — the "+" button was missing because the toolbar wasn't rendering, and pushing into the editor broke because there was no navigation chrome.

**Fix.**
- Keep `NavigationStack` in tab-roots that render as a *direct* tab in iOS 18 TabView (the first 4 by `.tag` order: Today, Templates, Medication, Sleep).
- Remove `NavigationStack` from tab-roots that land in the More overflow (Hydration, Housekeeping, Birthdays, Trips, Settings).
- Update `scripts/check-tabroots.py`'s `TAB_ROOTS` list **whenever the TabView reorders or grows**. The script only catches L004 violations in the listed views; it can't detect L007's *opposite* failure mode (a direct tab that's missing a NavigationStack).

**Guard test.** None automated. The script `scripts/check-tabroots.py` only enforces L004 (no inner NavigationStack on More-tab roots). For L007 we'd need either:
1. A runtime `XCUITest` smoke that asserts each direct tab renders a non-empty `.navigationTitle`, OR
2. A manual checklist entry in `QA_MANUAL.md` after every TabView reorder: "open each direct tab → confirm title bar + at least one toolbar item visible".

Option 2 added as part of round-26.

**Where it was caught.** 2026-04-29, session 23 — user reported imports working but the "+" button missing on Templates. Screenshot showed `TemplateListView` rendering without title or toolbar. Round-12's L004 fix removed the inner `NavigationStack` from `TemplateListView` because the script's `TAB_ROOTS` listed it as a More-tab. By session 23, the TabView's first 4 tabs were Today/Templates/Medication/Sleep — `TemplateListView` was actually a direct tab, not in More. Fixed in commit `d954bfd` by restoring `NavigationStack` and removing `TemplateListView` from the script's `TAB_ROOTS` list.

**Interaction with other lessons.** Direct inverse of L004. Together they say: a tab-root needs *exactly one* NavigationStack — either the system's (if in More) or its own (if direct). Guard scripts that pin "this view is in category X" need an audit step every time the tab structure changes.

---

## L008 — Prefer SwiftData `@Query` for cross-tab reactive state, not repository-cached VM properties

**Class of bug.** A `@Observable` ViewModel that caches a SwiftData fetch result (e.g. `var activeTemplate: RoutineTemplate?` populated by `repository.activeTemplate(for:)` inside `reload()`) goes stale across tab switches in iOS 18 TabView. Several factors compound:

1. iOS 18 TabView keeps tab views alive in the hierarchy. `.onAppear` doesn't reliably re-fire on subsequent tab switches.
2. SwiftUI may recreate the VM on every parent body re-evaluation when the VM is passed in via parameter (`viewModel: TodayViewModel(repository: env.routineRepository)`) instead of owned via `@State`.
3. `AppEnvironment` is rebuilt on every `ContentView.body` evaluation, creating fresh `SwiftDataRoutineRepository` instances.
4. Even though all repository instances wrap the *same* `ModelContext`, the fetch path can return stale or empty results across instances under unclear conditions.

The combined effect: data clearly visible in one tab (Templates shows green ✓ for an active template) is invisible in another tab (Today shows "No active template") because the fetch returns nil. Adding `NotificationCenter` broadcasts on every save partially helps but doesn't fully close the race.

**Symptom.** A view conditional on `viewModel.someEntity` shows the empty state even when the entity exists in SwiftData and is visible from a sibling tab. User-reported: "I must do back and forward between Today and Templates in order to see the templates created · In Today still no active templates."

**Fix.**
Bypass the VM/repository cache for cross-tab reactive state. Use SwiftData's `@Query` directly in the View:

```swift
struct TodayView: View {
    @Query(sort: \RoutineTemplate.name) private var allTemplates: [RoutineTemplate]

    private var queriedActiveTemplate: RoutineTemplate? {
        let dayType = TodayViewModel.dayType(for: Date(), in: .autoupdatingCurrent)
        return allTemplates.first { $0.dayType == dayType && $0.isActive }
    }

    var body: some View {
        if let template = queriedActiveTemplate { … }
        else { … }
    }
}
```

`@Query` is a reactive observer of the `ModelContext`. It auto-refreshes when any matching `@Model` is inserted, deleted, or has a tracked property mutated. No notifications, no cache invalidation, no VM coordination needed. The repository pattern is still fine for one-shot writes (`upsert`, `delete`, `markDone`); just not for view-driving reactive reads.

If the VM has derived state that needs the active template (`currentBlock()`, `nextBlock()`, completion sets), push the `@Query` result into the VM via `.onAppear` + `.onChange(of: queriedActiveTemplate?.id)`.

**Guard test.** None automated yet. Possible runtime `XCUITest` smoke: create template in tab A, switch to tab B, assert tab B's body re-renders with the new state in <1s. Added to round-26 backlog.

**Where it was caught.** 2026-04-29, session 23 — user reported Today's empty state persisted after creating + activating a template in the Templates tab. Diagnostic line `dayType=weekday · active=nil` confirmed the fetch returned nil despite the template being visible elsewhere. 4 fixes attempted before the `@Query` refactor:
1. Revert round-25 toolbar chip (no effect — wrong cause).
2. Restore `NavigationStack` (fixed L007 but not the active-template fetch).
3. `NotificationCenter.default.post(.routineDataChanged)` on every repository save + `TodayView.onReceive` (didn't close the race).
4. Diagnostic line + manual Refresh button (deployed to surface the bug — confirmed `active=nil`).
5. **`@Query` refactor in TodayView** (commit `ec105a5`) — bug closed.

**Interaction with other lessons.** Independent of L001-L007. Reinforces the architectural rule: SwiftData is the source of truth for `@Model` data; ViewModels are appropriate for derived/aggregated state but not for caching a fetch result that needs to react to writes from elsewhere.

---

## L009 — Local Xcode and CI runner produce different Swift 6 verdicts; local-pass is not proof CI will pass

**Trigger pattern.** A file uses a pre-Swift-6 Apple SDK that overrides a delegate method whose closure parameter is annotated `@Sendable` (or implies sendability). Examples seen in this repo: `UNUserNotificationCenterDelegate.userNotificationCenter(_:willPresent:withCompletionHandler:)`, `MKLocalSearchCompleterDelegate`, HealthKit query result handlers, `CLLocationManagerDelegate`, `CNContactStore` predicates, `WeatherKit` async APIs. Same pattern can also surface in SwiftUI `ViewBuilder` closures when a `@Bindable` or computed property crosses an isolation boundary inside the builder.

**Symptom.** `./scripts/check-tests.sh` reports `Test Succeeded` locally on Xcode 26.4.1 / Swift 6.3.1. The same toolchain on GitHub Actions `macos-latest` rejects the build with `##[error]` lines pointing at the same file. CI is red while local is green; multiple sessions can pass without anyone noticing because the round-completion ritual treats local-test-pass as proof of correctness.

**Root cause.** The host target's `SWIFT_VERSION="6.0"` enforces Swift 6 LANGUAGE-MODE checks. Local Xcode emits these as warnings (visible in the issue navigator but invisible to `check-tests.sh`'s grep-based pass/fail). The CI runner's static-checker tier escalates the same diagnostic to error severity. Result: a strict-mode skew that makes "local green" a misleading signal.

**Fix.**
- Defensive: add `@preconcurrency import <Framework>` at the top of any file that overrides delegate methods with closure parameters from a pre-Swift-6 Apple SDK. Purely additive; keeps local green; silences CI. Round 29 applied this to UserNotifications (1 site), MapKit (2), HealthKit (1), Contacts (1), CoreLocation (2), WeatherKit (1). It also applied `@MainActor` to 7 SwiftUI View structs and `MainActor.assumeIsolated` to 3 UIKit dismiss call-sites.
- Pragmatic short-term: dial host `SWIFT_VERSION` back to `5` (matching watch + tests). Toolchain stays at Swift 6.x; only the language-mode flag dials back. Round 29 settled here as the resolution after 9 incremental defensive fixes failed to clear every CI error.
- Strategic: full Swift 6 strict-mode migration is its own future round (Batch Q in `ALL OK?` audit). Walk every CI error to ground, document the migration as a follow-up lesson, and add a local guard script (`scripts/check-strict-concurrency.sh`) that runs `xcodebuild build SWIFT_STRICT_CONCURRENCY=complete` so future rounds catch new violations locally before push.

**Guard test.** Process: after every "lint cleanup" or "concurrency adjustment" round, **always run `gh run list --limit 3`** before declaring CI green; do not trust local-pass alone. The `feedback_repo_quirks.md` memory file documents the pattern so future sessions inherit the rule. Future automation: `scripts/check-strict-concurrency.sh` will fail locally on any diagnostic the CI runner would also fail on.

**Where it was caught.** 2026-04-29, session 25 round 29 — round 28 lint cleanup pushed `d17f3dc` claiming a clean CI; the actual CI runs were red on `2c67da7`/`d17f3dc`/`8ec08c4` (4 consecutive failures) for `UNUserNotificationCenterDelegate` sendability mismatches. Local `check-tests.sh` reported green throughout. The whack-a-mole that followed (12 commits of Swift-6-strict fixes) eventually revealed the structural cause; resolved at `f34f17b` with host `SWIFT_VERSION=5` and the 9 defensive fixes preserved as front-loaded prep for the eventual Batch Q migration.

**Interaction with other lessons.** Reinforces L005 — that lesson hardened `check-tests.sh` against silent process crashes; L009 hardens the *post-test* step (you must verify CI directly). Together they say: green-from-script is necessary but not sufficient — both the script's classification AND the upstream CI verdict have to agree before declaring victory.

---

## L010 — Repo on USB drive: `find` overcounts ~2× because of macOS `._*` AppleDouble resource forks

**Trigger pattern.** The repo is mounted from a USB drive (`/Volumes/USB1TBWD/...`). macOS-native filesystems silently shadow every `*.swift` file with a `._*.swift` AppleDouble resource-fork sibling that stores extended attributes the USB filesystem can't represent natively. Naive `find ... -name "*.swift" | wc -l` matches both, doubling the count. Same applies to `*.md`, `*.json`, etc.

**Symptom.** A drift-audit step that compares against memory's recorded counts (e.g. "163 services in `App/Shared/Services/`") reports massive false drift: `find App/Shared/Services -name "*.swift" | wc -l` returns 326. Author panics, files an issue, spends round-trips investigating "phantom services" that don't exist. Memory was correct all along; the audit was wrong.

**Root cause.** The USB filesystem (likely exFAT or FAT32 historically used for cross-platform drives) doesn't natively store macOS extended attributes. macOS works around this by writing a parallel `._<filename>` file containing the metadata. These files are real entries in the directory listing; `find` matches them; `wc -l` counts them; nothing in stock POSIX tooling filters them out.

**Fix.**
- Always pass `-not -name "._*"` to `find` invocations that count or list files for audit purposes:
  ```bash
  find App/Shared/Services -name "*.swift" -not -name "._*" | wc -l
  ```
- Centralize the pattern in `scripts/check-counts.sh` and route every audit script + ALL OK? audit through it. Single point of truth; impossible to forget the filter.
- Long-term: consider migrating the repo off the USB drive, or formatting the drive as APFS / HFS+. Out of scope for the fix itself.

**Guard test.** `scripts/check-counts.sh` exposes `count_swift PATH` and `count_glob PATH PATTERN` shell functions that always exclude `._*`. Run `./scripts/check-counts.sh` standalone to print the canonical counts the next session should see (services, models, test files, i18n keys). CI calls it as a hygiene step so any future audit script that re-introduces the unfiltered pattern fails fast.

**Where it was caught.** 2026-04-29, session 25 round 29 — initial `ALL OK?` audit reported "326 services vs memory's 162" as drift; user pointed out the AppleDouble inflation was inflating the count. Reported a second time during round 30's drift-cleanup audit, this time with the fix in hand (`-not -name "._*"` filter). Real counts at end of round 30: 163 services, 184 service-test files, 14 `@Model` files (memory had said 16-17 — separate, smaller drift addressed in the same round).

**Interaction with other lessons.** Independent of L001-L009. Specific to this filesystem; would not apply on a clean APFS-formatted Mac. Documented for completeness because the bug-class is *audit-correctness*, not *runtime-correctness* — and false-drift audits cost time + erode confidence in the memory system.
