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

    /// Snapshot of recent `RefreshTraceLog` entries (newest-first) so
    /// DiagnosticsView can show what was scheduled and when. Process-local;
    /// cleared on relaunch.
    let refreshTrace: @MainActor () -> [RefreshTraceLog.Entry]

    /// Returns `(pendingCount, expectedCount)` for today — diff > 0 means the
    /// scheduler dropped or duplicated something vs the deterministic build.
    /// Throws if the build pipeline can't run (rare; surfaces upstream error).
    let scheduleDiff: @MainActor () async throws -> (pending: Int, expected: Int)

    /// Process-wide count of `widgetReloader` invocations from the
    /// `NotificationActionHandler` mark-done path. Confirms the wiring
    /// actually fires on real devices.
    let widgetReloadCount: @MainActor () -> Int

    /// Snapshot of the medication concept identifiers that are currently
    /// registered with the observer. `isAvailable` is `false` until the
    /// HealthKit entitlement lands, so registrations are intent-only for now.
    let medicationObserverSnapshot: @MainActor () -> (available: Bool, identifiers: [String])

    /// Count of trip documents stored across all trips — proxy for
    /// "Keychain footprint" until we add real byte-size accounting.
    let tripDocumentCount: @MainActor () -> Int

    /// Round-11: total Keychain bytes across all trip documents (approximate;
    /// reads each blob via the `KeychainStore` to measure actual byte length).
    /// Returns `nil` when `KeychainStore.read` fails for any blob — UI then
    /// falls back to the document count row.
    let tripDocumentByteFootprint: @MainActor () -> Int?

    /// Process uptime in seconds. Reset to 0 on relaunch — useful to detect
    /// silent OS-driven restarts (low-memory kills, system updates).
    let processUptimeSeconds: @MainActor () -> TimeInterval

    /// Builds a JSON snapshot of the current diagnostics state suitable for
    /// sharing via `UIActivityViewController`. Returns the temporary file URL
    /// the share sheet can then consume.
    let exportSnapshot: @MainActor () async throws -> URL

    /// Round-12 slice 1: per-category breakdown of pending notifications so
    /// drift in milestone/hydration/housekeeping schedules surfaces just
    /// like routine drift does. Replaces the single-number `Δ` reporting.
    let pendingByCategory: @MainActor () async -> PendingNotificationsByCategory

    /// Round-12 slice 2: per-document byte size for the trip docs section.
    /// Returns `[(name, bytes)]`. Empty when no docs / unable to read.
    let tripDocumentDetails: @MainActor () -> [(name: String, bytes: Int)]

    /// Round-12 slice 19: rolling launch history (last N launches with
    /// previous-launch duration so silent OS restarts surface).
    let launchHistory: @MainActor () -> [ProcessLaunchHistoryStore.Entry]

    /// Round-12 slice 18: rolling history of "What's new" commits the auto
    /// popup has shown — useful to verify the user actually saw a given
    /// release on this device.
    let whatsNewHistory: @MainActor () -> [WhatsNewHistoryStore.Entry]
}
