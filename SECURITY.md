# Security policy

## Supported versions

Pre-1.0: only the latest commit on `main` is supported.
After 1.0: only the latest minor version receives security fixes.

---

## Reporting a vulnerability

**Please do NOT open a public GitHub issue for security vulnerabilities.**

Instead, email: `<security-contact-placeholder@example.com>` (to be replaced before public release).

Include:
- A description of the vulnerability.
- Steps to reproduce (or a proof-of-concept).
- Affected versions or commits.
- Any suggested mitigation.

You will receive an acknowledgement within 5 business days. A fix and disclosure timeline will be coordinated with you before any public discussion.

---

## Scope

In scope:
- Source code in this repository.
- CI/CD configuration (`.github/workflows/`).
- Build + release scripts (`scripts/`).

Out of scope:
- Vulnerabilities in third-party dependencies (please report upstream and notify us).
- Vulnerabilities in Apple frameworks (HealthKit, CloudKit, etc.) — report via [Apple's security disclosure](https://support.apple.com/en-us/HT201220).
- Issues requiring a jailbroken / rooted device.
- Social engineering of the project maintainer.

---

## Sensitive data

This app handles potentially sensitive data:
- Medication schedules (HealthKit).
- Sleep patterns (HealthKit).
- Passport / visa scans (Vacation module — Keychain-encrypted, on-device only).
- Calendar appointments (EventKit).

**No data leaves the user's Apple ecosystem.** No backend. No analytics. No third-party SDKs. See [README.md § Privacy](README.md#privacy).

If you observe data exfiltration, treat it as a critical vulnerability and report immediately.

---

## Build provenance

- All binaries are built from tagged commits on `main`.
- Releases are signed with the project's Apple Developer ID (Phase 6+).
- `scripts/check-clean.sh` is run pre-release to verify no committed PII or secrets.

---

## Acknowledgements

Reporters who follow responsible disclosure may be credited in [CHANGELOG.md](CHANGELOG.md) under the relevant release (with consent).
