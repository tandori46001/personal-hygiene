# Round 26 — Apple Developer Program Activation Checklist

> Sequenced steps to flip the project from "Personal Team free" signing to the paid Developer Program account, unlocking CloudKit / HealthKit / App Groups / TestFlight.
>
> **Order matters:** entitlements that the Personal Team can't provision will break the build until the team is switched. Follow top-to-bottom.

---

## Pre-flight

- [ ] Welcome email *"Welcome to the Apple Developer Program"* received.
- [ ] developer.apple.com/account → your Team ID visible + status "Active".
- [ ] In Xcode `Settings › Accounts`, your Apple ID shows `Apple Development` and `Apple Distribution` certificates present.

If any of the three are missing, **stop here** — the team isn't fully activated yet.

---

## Step 1 — Create Apple Developer Portal resources (~10 min)

These can be created via the **Apple Developer** iOS app or the web. Xcode will *also* auto-create most of them on first build, but explicit creation lets you set capabilities upfront.

### App IDs (one per target)

Go to https://developer.apple.com/account/resources/identifiers/list and create:

1. `com.tandori46001.personalhygiene`
   - Capabilities: HealthKit, iCloud (CloudKit), App Groups, Push Notifications, Time Sensitive Notifications.
2. `com.tandori46001.personalhygiene.widgets`
   - Capabilities: App Groups, iCloud.
3. `com.tandori46001.personalhygiene.watchkitapp`
   - Capabilities: HealthKit, App Groups, iCloud.
4. `com.tandori46001.personalhygiene.watchkitapp.widgets`
   - Capabilities: App Groups.

### App Group

5. Identifier: `group.com.tandori46001.personalhygiene` (matches `App/Shared/Services/AppGroup.swift`).
6. Associate it with all four App IDs above.

### iCloud Container

7. Identifier: `iCloud.com.tandori46001.personalhygiene`.
8. Associate it with all four App IDs above.

---

## Step 2 — Switch the Xcode team (~2 min)

In `App/PersonalHygiene.xcodeproj` → for each of the 4 targets:

1. Signing & Capabilities → **Team:** change from "Pingpong (Personal Team)" to "**Tu Nombre (XXXXXXXXXX)**" (the paid team).
2. Capabilities tab should now show the four App IDs created above resolved without errors.

> Alternative: edit `App/project.yml` once and re-run `xcodegen`:
>
> ```yaml
> # In settings.base for each target:
> DEVELOPMENT_TEAM: <new team id>
> ```
>
> The current `XC79TD476V` value in project.yml may be the Personal Team — confirm and replace.

---

## Step 3 — Wire entitlements files into project.yml (~3 min)

Round 25 already created the four `.entitlements` files. Add a `entitlements:` line per target in `App/project.yml`:

```yaml
PersonalHygiene:
  ...
  settings:
    base:
      ...
      CODE_SIGN_ENTITLEMENTS: PersonalHygiene/PersonalHygiene.entitlements

PersonalHygieneWidgets:
  ...
  settings:
    base:
      ...
      CODE_SIGN_ENTITLEMENTS: PersonalHygieneWidgets/PersonalHygieneWidgets.entitlements

PersonalHygieneWatch:
  ...
  settings:
    base:
      ...
      CODE_SIGN_ENTITLEMENTS: PersonalHygieneWatch/PersonalHygieneWatch.entitlements

PersonalHygieneWatchWidgets:
  ...
  settings:
    base:
      ...
      CODE_SIGN_ENTITLEMENTS: PersonalHygieneWatchWidgets/PersonalHygieneWatchWidgets.entitlements
```

Then:

```bash
cd App && xcodegen
./scripts/check-tests.sh
./scripts/deploy-iphone.sh
./scripts/deploy-watch.sh
```

If signing fails on first build, in Xcode click "Try Again" on each target — Xcode auto-creates the provisioning profiles after the first cloud round-trip.

---

## Step 4 — Wire CloudKit production container

Once entitlements provisioning succeeds, update `AppModelContainer` to opt into CloudKit when running on device:

```swift
// In the iOS app entry point
@main
struct PersonalHygieneApp: App {
    let modelContainer: ModelContainer = {
        do {
            return try AppModelContainer.makeProduction(cloudKit: true)
        } catch {
            // Graceful fallback to local-only on simulator
            return try! AppModelContainer.makeInMemory()
        }
    }()
    ...
}
```

Verify on device:

1. Mark a block done on iPhone.
2. Open the watch app — block status should sync within ~30s.
3. Settings → Diagnostics → CloudKit row should show `available` status.

---

## Step 5 — Wire `HKObserverQuery` real path

`MedicationObserverService.swift` already has the entitlement-gated runtime check. Once HealthKit entitlement provisions:

1. Trigger first launch on device → permission prompt for medication + sleep.
2. Tap "Grant" → check Diagnostics for "HealthKit medication observer: active".
3. Log a dose in Health → confirm the corresponding `MedicationFollowUpFactory` notification cancels.

---

## Step 6 — Submit Critical Alerts request

See `docs/critical-alerts-request.md` for the form copy. Submit while step 4-5 are in flight (Apple takes 1-3 weeks).

---

## Step 7 — TestFlight (Phase 4 unlock)

1. App Store Connect → personal-hygiene → TestFlight tab.
2. Archive in Xcode → Distribute App → App Store Connect → Upload.
3. Set yourself as internal tester.
4. Begin 30-day adherence validation against the Phase 4 acceptance criteria in ROADMAP.md.

---

## Rollback

If anything in steps 2-3 breaks signing and you need to demo on the Personal Team:

```bash
# Edit App/project.yml: remove the CODE_SIGN_ENTITLEMENTS lines.
# Edit each target's DEVELOPMENT_TEAM back to XC79TD476V.
cd App && xcodegen
./scripts/deploy-iphone.sh
```

The entitlements files stay on disk (harmless) — only the project.yml references control whether signing tries to use them.
