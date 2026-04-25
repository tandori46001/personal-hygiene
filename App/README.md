# App/

The Xcode project lives here. Created in Phase 0 (not yet generated as of repo bootstrap).

---

## Expected structure (post-Phase 0)

```
App/
├── PersonalHygiene.xcodeproj/      # Xcode project file
├── PersonalHygiene/                # iOS app target
│   ├── App/
│   │   ├── PersonalHygieneApp.swift   # @main entry point
│   │   └── ContentView.swift          # root container
│   ├── Features/                   # one folder per module
│   │   ├── Routine/                # M1
│   │   ├── Notifications/          # M2
│   │   ├── Medication/             # M3
│   │   ├── Sleep/                  # M4
│   │   ├── Hydration/              # M5
│   │   ├── Housekeeping/           # M6
│   │   ├── Birthdays/              # M7
│   │   ├── DeepFocus/              # M8
│   │   └── Vacation/               # M9
│   ├── Resources/
│   │   └── Assets.xcassets/
│   ├── Localization/
│   │   └── Localizable.xcstrings   # ES + EN + FR
│   ├── Info.plist
│   └── PersonalHygiene.entitlements
├── PersonalHygieneWatch/           # watchOS app target
│   ├── App/
│   ├── Features/                   # subset of iOS modules
│   ├── Complications/
│   └── Resources/
└── Shared/                         # used by both targets
    ├── Models/                     # Block, RoutineTemplate, Trip, …
    ├── Persistence/                # SwiftData schema + CloudKit
    ├── Services/                   # HealthKit, EventKit, Contacts wrappers
    └── Utils/
```

---

## Generating the Xcode project

When ready (Phase 0 final step):

```bash
# In Xcode: File → New → Project
#   → iOS App
#   → Product Name: PersonalHygiene
#   → Interface: SwiftUI
#   → Language: Swift
#   → Use Core Data: NO (we use SwiftData)
#   → Include Tests: YES
# Then: File → New → Target → watchOS App for iOS App
```

Project location: `App/PersonalHygiene.xcodeproj`.
Bundle identifier: `com.<your-org>.personalhygiene` (placeholder).

Required entitlements (request in Apple Developer Portal):
- `com.apple.developer.healthkit`
- `com.apple.developer.healthkit.background-delivery`
- `com.apple.developer.icloud-services` (CloudKit)
- `com.apple.developer.usernotifications.critical-alerts` (request with justification)
- `com.apple.developer.applesignin` (if user authentication added later)

---

## Conventions

- One type per file. File name matches type name.
- Feature folders contain `Views/`, `ViewModels/`, `Models/`, `Services/`.
- Cross-feature types live in `Shared/`.
- See [../CLAUDE.md § 4](../CLAUDE.md) and [../ARCHITECTURE.md § 3](../ARCHITECTURE.md) for full conventions.
