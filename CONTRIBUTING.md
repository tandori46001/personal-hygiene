# Contributing

This is a single-developer personal project, but contributions / suggestions / bug reports are welcome via GitHub Issues.

---

## Workflow

### Branches
- `main` — always green, always deployable.
- `feat/<short-name>` — new feature.
- `fix/<short-name>` — bug fix.
- `chore/<short-name>` — tooling, deps, docs.

### Commits
[Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) format:

```
<type>(<scope>): <subject>

<body — what + why, never how>
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `ci`, `perf`.
Scopes: module name (`routine`, `medication`, `sleep`, `vacation`, `watch`, `prd`, `ci`, etc.).

### QA-mandatory rule

**Every bug fix and every new feature MUST update the test suite in the same commit.**

No "I'll add the test later." If the tests don't catch the regression, the fix didn't happen. See [QA_MANUAL.md](QA_MANUAL.md) for the manual test checklist; the automated suite must stay green per `scripts/check-tests.sh`.

### Pre-commit checklist

```
[ ] Tests added / updated for this change?
[ ] Updated QA_MANUAL.md with a new or updated [T-XXX] case?
[ ] Ran the full test suite — green? (./scripts/check-tests.sh)
[ ] Ran linter? (./scripts/lint.sh)
[ ] If new class of bug: added LNNN lesson + guard test in LESSONS.md?
[ ] Updated ROADMAP.md / README.md / PRD.md if scope changed?
```

### Pull requests

PRs require:
1. Green CI (`ci.yml`).
2. PR description filled per [PULL_REQUEST_TEMPLATE.md](.github/PULL_REQUEST_TEMPLATE.md).
3. At least one self-review pass before requesting merge.
4. Squash-merge to `main` (linear history).

### Push policy

**Do NOT push to `origin/main` without explicit user authorization.**
Feature branches may push freely; `main` only on green CI + explicit OK.

---

## Code style

### Swift
- Follow [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/).
- Lint: `swiftlint` (config: `.swiftlint.yml`).
- Format: `swift-format` (config: `.swift-format`).

### Naming
- Types: `UpperCamelCase`.
- Properties / methods / variables: `lowerCamelCase`.
- Files: one type per file, file name = type name.
- Tests: `<TypeUnderTest>Tests.swift`.

### Localization
- All user-facing strings go through `Localizable.xcstrings`.
- **Every new key MUST land in all three locales (ES + EN + FR) in the same commit.** A key that's missing in one locale renders as the raw key string at runtime.

---

## Reporting bugs

Use [.github/ISSUE_TEMPLATE/bug_report.yml](.github/ISSUE_TEMPLATE/bug_report.yml) — fill all fields. Include:
- iOS / watchOS version.
- Steps to reproduce.
- Expected vs. actual.
- Screenshots / logs if helpful.

---

## License

By contributing, you agree your contributions are licensed under [MIT](LICENSE).
