# Tests/

Test targets live here. Created alongside the Xcode project in Phase 0.

---

## Structure

```
Tests/
├── Unit/                  # XCTest — pure logic, view models, services
│   ├── Models/
│   ├── ViewModels/
│   └── Services/
├── Integration/           # XCTest — with in-memory ModelContainer + mock CloudKit
│   ├── Persistence/
│   └── Sync/
└── UI/                    # XCUITest — critical user flows only
    ├── OnboardingTests.swift
    ├── RoutineCreationTests.swift
    └── MedicationFlowTests.swift
```

---

## Conventions

- File name matches the unit under test: `RoutineViewModel.swift` → `RoutineViewModelTests.swift`.
- One test class per type under test.
- Test method naming: `test_<methodOrFlow>_<condition>_<expected>()`.
- Use `XCTAssertEqual` over `XCTAssertTrue(a == b)` for better failure messages.
- No `XCTSkip` to silence broken tests — fix or delete.

---

## Running tests

```bash
./scripts/check-tests.sh
```

Or directly with xcodebuild:

```bash
xcodebuild test \
  -project App/PersonalHygiene.xcodeproj \
  -scheme PersonalHygiene \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

---

## Coverage targets

| Area | Min coverage |
|---|---|
| `App/Shared/Models/` | 80% |
| `App/Shared/Services/` | 70% |
| `App/PersonalHygiene/Features/<Module>/ViewModels/` | 60% |
| Views | not measured (SwiftUI views tested via UI tests when needed) |
