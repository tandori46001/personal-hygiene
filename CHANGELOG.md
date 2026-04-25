# Changelog

All notable changes to this project are documented here.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and the project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added
- Repository bootstrap: README, LICENSE, CHANGELOG, CONTRIBUTING, SECURITY.
- `.gitignore`, `.editorconfig`, `.swiftlint.yml`, `.swift-format`.
- `PRD.md` v0.2 — product requirements (9 modules, 7 delivery phases).
- `ARCHITECTURE.md` placeholder — technical architecture skeleton.
- `ROADMAP.md` — phase tracker.
- `CLAUDE.md` — instructions for Claude Code.
- `LESSONS.md` + `QA_MANUAL.md` — meta-system stubs.
- `App/`, `Tests/`, `docs/`, `scripts/` directory placeholders.
- GitHub Actions CI workflow + dependabot + issue / PR templates + CODEOWNERS.

---

## Version conventions

- **MAJOR** — breaking changes to data model, public API, or supported OS minimums.
- **MINOR** — new modules / features (additive).
- **PATCH** — bug fixes, dependency bumps, doc updates.

Pre-1.0 versions (`0.x.y`) bump MINOR for any user-visible change and PATCH for fixes.
