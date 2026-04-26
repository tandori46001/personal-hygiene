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
