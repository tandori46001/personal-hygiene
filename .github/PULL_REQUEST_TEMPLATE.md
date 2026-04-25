# Pull Request

## Summary
<!-- 1-3 bullets: what changed and why -->

-
-

## Scope
<!-- Module(s) touched: routine / medication / sleep / vacation / watch / docs / ci / etc. -->

## Type
- [ ] feat (new feature)
- [ ] fix (bug fix)
- [ ] refactor (no behavior change)
- [ ] docs
- [ ] test
- [ ] chore / ci
- [ ] breaking change (describe migration in body)

## Pre-commit checklist
<!-- All boxes must be checked before merge -->
- [ ] Tests added / updated for this change
- [ ] `QA_MANUAL.md` updated with new or updated `[T-XXX]` case (if user-visible behavior changed)
- [ ] `./scripts/check-tests.sh` passes locally
- [ ] `./scripts/lint.sh` passes locally
- [ ] If new class of bug: `LESSONS.md` entry + guard test added
- [ ] `ROADMAP.md` / `PRD.md` / `README.md` updated if scope changed
- [ ] i18n: every new user-facing string lands in ES + EN + FR (Localizable.xcstrings)
- [ ] No secrets, real emails, real coordinates, or real names in committed files
- [ ] `CHANGELOG.md` updated under `[Unreleased]` if user-visible

## QA-coverage question
<!-- HARD RULE: every bug fix is also a QA gap. -->
If this PR is a bug fix:
- [ ] Did this bug escape `QA_MANUAL.md` coverage?
- [ ] If yes, what `[T-XXX]` section now covers it?

## Test plan
<!-- How a reviewer (or CI) verifies this works -->
- [ ]
- [ ]

## Screenshots / logs
<!-- If UI changed or behavior is hard to describe -->

## Linked issues / PRD references
<!-- e.g. closes #42, implements PRD § M3.5 -->
