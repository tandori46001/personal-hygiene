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

_(none yet — lessons accrue from real bugs encountered)_
