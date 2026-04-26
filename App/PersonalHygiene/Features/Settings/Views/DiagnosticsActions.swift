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
}
