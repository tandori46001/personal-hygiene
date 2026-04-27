import Foundation

/// Builds a +30-min follow-up notification for a medication block. Pure value
/// type — fed into `NotificationCoordinator.refreshForToday` so each
/// medication block fires twice: the primary alert at the lead time + a
/// follow-up at `triggerDate + offsetMinutes`. PRD M3.2 fallback for when
/// HealthKit `HKObserverQuery` isn't available (no entitlement).
/// User-configurable +N min offset for the medication follow-up reminder.
/// Settings exposes a stepper bound to this; defaults to 30. Values outside
/// the allowed list fall back to default.
public enum MedicationFollowUpDelayStore {

    public static let key = "notifications.medication.followup.minutes"
    public static let allowedMinutes: [Int] = [15, 30, 45, 60]
    public static let defaultMinutes = 30

    public static func minutes(defaults: UserDefaults = .standard) -> Int {
        let stored = defaults.integer(forKey: key)
        guard allowedMinutes.contains(stored) else { return defaultMinutes }
        return stored
    }

    public static func set(_ minutes: Int, in defaults: UserDefaults = .standard) {
        guard allowedMinutes.contains(minutes) else { return }
        defaults.set(minutes, forKey: key)
    }
}

public enum MedicationFollowUpFactory {

    public static let identifierPrefix = "personal-hygiene.medication.followup."
    public static let defaultOffsetMinutes = 30

    /// Build the canonical follow-up identifier for a `(blockID, dayKey)` pair.
    /// Used by both the scheduler (when emitting the request) and the future
    /// `HKObserverQuery`-driven cancellation path (when the user logs the dose
    /// in Health and we want to drop the pending follow-up before it fires).
    public static func identifier(blockID: UUID, dayKey: String) -> String {
        "\(identifierPrefix)\(blockID.uuidString).\(dayKey)"
    }

    /// Cancel any pending follow-up notifications matching the given
    /// `(blockID, dayKey)` pairs. No-op when the pending list is empty or
    /// nothing matches. Call this from the medication-observer onChange path
    /// once the entitlement lands so a dose logged in Health silences the
    /// +30-min reminder.
    @MainActor
    public static func cancelFollowUps(
        for pairs: [(blockID: UUID, dayKey: String)],
        in pending: [String]
    ) -> [String] {
        let targets = Set(pairs.map { identifier(blockID: $0.blockID, dayKey: $0.dayKey) })
        return pending.filter { targets.contains($0) }
    }

    /// Returns a single follow-up `ScheduledNotification` for `block` if it's
    /// a medication block (has a `medicationConceptIdentifier`); `nil`
    /// otherwise.
    public static func notification(
        for block: Block,
        primaryTrigger: Date,
        offsetMinutes: Int = defaultOffsetMinutes,
        title: String,
        body: String?,
        dayKey: String,
        calendar: Calendar = .autoupdatingCurrent
    ) -> ScheduledNotification? {
        guard block.medicationConceptIdentifier != nil else { return nil }
        guard let trigger = calendar.date(byAdding: .minute, value: offsetMinutes, to: primaryTrigger) else {
            return nil
        }
        return ScheduledNotification(
            identifier: "\(identifierPrefix)\(block.id.uuidString).\(dayKey)",
            title: title,
            body: body,
            triggerDate: trigger,
            isCritical: true,
            threadIdentifier: NotificationThreadID.medication,
            categoryIdentifier: NotificationCategoryID.medication
        )
    }

    /// Convenience that derives the follow-up directly from an already-built
    /// primary `ScheduledNotification`. Reuses the primary's title; appends a
    /// localized "follow-up" suffix to the body so the user can tell them
    /// apart on the lock screen.
    public static func followUp(
        for primary: ScheduledNotification,
        block: Block,
        offsetMinutes: Int = defaultOffsetMinutes,
        dayKey: String,
        calendar: Calendar = .autoupdatingCurrent
    ) -> ScheduledNotification? {
        guard block.medicationConceptIdentifier != nil else { return nil }
        guard let trigger = calendar.date(byAdding: .minute, value: offsetMinutes, to: primary.triggerDate) else {
            return nil
        }
        let suffix = String(localized: "medication.notification.followup.suffix")
        let body = [primary.body, suffix]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " — ")
        return ScheduledNotification(
            identifier: "\(identifierPrefix)\(block.id.uuidString).\(dayKey)",
            title: primary.title,
            body: body,
            triggerDate: trigger,
            isCritical: true,
            threadIdentifier: NotificationThreadID.medication,
            categoryIdentifier: NotificationCategoryID.medication
        )
    }
}
