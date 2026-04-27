import Foundation
import UserNotifications

/// Closure-bag passed into `DiagnosticsView` so the dev-only buttons can act
/// on the live app stores without `DiagnosticsView` knowing about concrete
/// service types. `ContentView` constructs this from `AppEnvironment`.
@MainActor
struct DiagnosticsActions {

    /// Schedules a routine-style notification 30s in the future, with the
    /// real `routine` category so snooze/mark-done actions appear when the
    /// user long-presses. Identifier is unique per call.
    let scheduleTestNotification: @MainActor () async -> Void

    /// Drops every pending request from `UNUserNotificationCenter`.
    let clearAllPending: @MainActor () async -> Void

    /// Marks the first block of today's active template as snoozed for today
    /// — no real notification fires, just the badge state. Returns the
    /// affected block title for confirmation.
    let injectSnoozeBadge: @MainActor () -> String?

    /// Wipes `BlockSkipStore` + `BlockSnoozeStore` (every entry, every day) +
    /// resets `SnoozeDurationStore` to default. Useful between test sessions.
    let resetDevStores: @MainActor () -> Void

    /// Reads the most-recently delivered notification and re-fires a copy at
    /// +5 seconds so the Recently-Delivered panel can be exercised quickly
    /// without waiting for a real schedule. Returns the title of the replayed
    /// item or `nil` if `deliveredNotifications()` is empty.
    let replayLastDelivered: @MainActor () async -> String?

    /// Schedules a fake medication block primary at +60s plus its follow-up
    /// reminder at +90s (M3.2 fallback path) so we can validate the
    /// MedicationFollowUpFactory wiring on real hardware in under 2 minutes.
    let scheduleMedicationTest: @MainActor () async -> Void

    /// Re-prompts the system notification authorization sheet. iOS only
    /// presents the sheet once per app lifetime; if the user already chose,
    /// this is a no-op aside from refreshing the authorization status.
    let requestAuthorization: @MainActor () async -> Void
}
