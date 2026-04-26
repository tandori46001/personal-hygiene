import Foundation

/// Builds a +30-min follow-up notification for a medication block. Pure value
/// type — fed into `NotificationCoordinator.refreshForToday` so each
/// medication block fires twice: the primary alert at the lead time + a
/// follow-up at `triggerDate + offsetMinutes`. PRD M3.2 fallback for when
/// HealthKit `HKObserverQuery` isn't available (no entitlement).
public enum MedicationFollowUpFactory {

    public static let identifierPrefix = "personal-hygiene.medication.followup."
    public static let defaultOffsetMinutes = 30

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
