# Critical Alerts Entitlement Request — personal-hygiene

> Apple requires a separate written request to grant `com.apple.developer.usernotifications.critical-alerts`. Submit via:
>
> https://developer.apple.com/contact/request/notifications-critical-alerts-entitlement
>
> Approval typically takes **1–3 weeks**. Apple may follow up with clarifying questions.

---

## What it unlocks

- `UNNotificationContent.interruptionLevel = .critical` plays the alert sound + bypasses Do Not Disturb / Silent Mode / Focus.
- Pairs with `MedicationFollowUpFactory` (already produces critical-flag follow-ups) and the round-12 medication block scheduling.

## Form fields — copy/paste

**App name:** personal-hygiene

**Bundle identifier:** com.tandori46001.personalhygiene

**App description:**

personal-hygiene is a single-user personal scheduling app that delivers
military-precision time-block reminders. Its primary medical purpose is
to ensure the user takes prescribed medication at exact intervals
(antihypertensive + chronic medication), where a missed or late dose has
documented adverse health consequences for the user.

**Why your app needs Critical Alerts:**

The user is the legitimate owner of the device and has prescribed
medication that must be taken at strict intervals. Standard notification
delivery is insufficient because:

1. The user routinely enables Sleep Focus / Do Not Disturb during evening
   medication windows, which silences regular notifications.
2. Late-evening and early-morning doses must override silent modes —
   missing a dose has real medical consequences (blood-pressure spike,
   adherence-streak break).
3. The app provides per-block opt-in: only blocks explicitly tagged as
   medication carry the critical interruption level. All other reminders
   (hydration, housekeeping, deep focus) use standard interruption.

The app is single-user (the developer = the user), built for personal
medication adherence, and is **not distributed publicly** beyond
TestFlight self-testing. The user has explicitly consented in-app to
critical-level alerts via a Settings toggle that defaults to OFF and
must be activated manually.

**Audience:** single user (developer-owned device) — not a multi-user
medical service. The app is currently preparing for App Store submission
under the same single-user model.

---

## Once approved

Add to `App/PersonalHygiene/PersonalHygiene.entitlements`:

```xml
<key>com.apple.developer.usernotifications.critical-alerts</key>
<true/>
```

Then regenerate provisioning profile in Xcode (`Signing & Capabilities` →
"Try Again" or just rebuild) — the new entitlement will appear in the
profile automatically.

## Verification on device

1. Block tagged as medication, with critical follow-up enabled.
2. Enable Sleep Focus.
3. Wait for the scheduled trigger.
4. Expected: alert plays full sound + appears on lock screen despite
   Focus being active.

---

## Status tracker

- [ ] Form submitted on YYYY-MM-DD
- [ ] Apple acknowledged receipt
- [ ] Approval email received
- [ ] Entitlement added to `.entitlements` file
- [ ] Verified on device with Sleep Focus active
