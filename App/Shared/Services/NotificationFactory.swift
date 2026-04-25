import Foundation

/// A planned notification computed from a `Block`. Pure value type — no
/// dependency on `UNUserNotificationCenter` so it can be unit-tested freely.
public struct ScheduledNotification: Equatable, Sendable {
    public let identifier: String
    public let title: String
    public let body: String?
    public let triggerDate: Date
    public let isCritical: Bool

    public init(
        identifier: String,
        title: String,
        body: String? = nil,
        triggerDate: Date,
        isCritical: Bool
    ) {
        self.identifier = identifier
        self.title = title
        self.body = body
        self.triggerDate = triggerDate
        self.isCritical = isCritical
    }
}

/// Maps `Block`s to `ScheduledNotification`s for a given calendar day.
///
/// Notifications fire `block.notificationLeadMinutes` before the block start.
/// Blocks whose computed trigger lands before midnight (negative offset) are skipped.
public enum NotificationFactory {

    /// Identifier prefix for any notification this app schedules.
    public static let identifierPrefix = "personal-hygiene.block."

    public static func notifications(
        for blocks: [Block],
        on date: Date,
        calendar: Calendar = .autoupdatingCurrent
    ) -> [ScheduledNotification] {
        let dayStart = calendar.startOfDay(for: date)
        let dayKey = isoDayKey(for: date, calendar: calendar)

        return blocks.compactMap { block -> ScheduledNotification? in
            let triggerMinutes = block.startMinutesFromMidnight - block.notificationLeadMinutes
            guard triggerMinutes >= 0 else { return nil }
            guard let trigger = calendar.date(byAdding: .minute, value: triggerMinutes, to: dayStart) else {
                return nil
            }
            return ScheduledNotification(
                identifier: "\(identifierPrefix)\(block.id.uuidString).\(dayKey)",
                title: block.title,
                body: block.notes,
                triggerDate: trigger,
                isCritical: block.category == .medication
            )
        }
    }

    private static func isoDayKey(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%04d-%02d-%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
    }
}
