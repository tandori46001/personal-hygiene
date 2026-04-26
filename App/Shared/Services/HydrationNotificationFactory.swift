import Foundation

/// Hydration reminder schedule — every `intervalMinutes` between
/// `windowStartHour:00` and `windowEndHour:00` of the given day.
public struct HydrationReminderSchedule: Equatable, Sendable {
    public let windowStartHour: Int
    public let windowEndHour: Int
    public let intervalMinutes: Int

    public init(windowStartHour: Int, windowEndHour: Int, intervalMinutes: Int) {
        self.windowStartHour = windowStartHour
        self.windowEndHour = windowEndHour
        self.intervalMinutes = intervalMinutes
    }

    public static let `default` = Self(
        windowStartHour: 9,
        windowEndHour: 21,
        intervalMinutes: 90
    )
}

/// Builds `ScheduledNotification`s for hydration reminders. Pure value-type
/// builder — no `UNUserNotificationCenter` dependency so it's freely testable.
public enum HydrationNotificationFactory {

    public static let identifierPrefix = "personal-hygiene.hydration."

    public static func notifications(
        for schedule: HydrationReminderSchedule,
        title: String,
        body: String?,
        on date: Date,
        calendar: Calendar = .autoupdatingCurrent
    ) -> [ScheduledNotification] {
        guard schedule.intervalMinutes > 0 else { return [] }
        let dayStart = calendar.startOfDay(for: date)
        let dayKey = isoDayKey(for: date, calendar: calendar)
        let startMinutes = schedule.windowStartHour * 60
        let endMinutes = schedule.windowEndHour * 60
        guard endMinutes >= startMinutes else { return [] }

        var result: [ScheduledNotification] = []
        var minute = startMinutes
        var index = 0
        while minute <= endMinutes {
            guard let trigger = calendar.date(byAdding: .minute, value: minute, to: dayStart) else { break }
            result.append(
                ScheduledNotification(
                    identifier: "\(identifierPrefix)\(dayKey).\(index)",
                    title: title,
                    body: body,
                    triggerDate: trigger,
                    isCritical: false,
                    threadIdentifier: NotificationThreadID.hydration,
                    categoryIdentifier: NotificationCategoryID.hydration
                )
            )
            minute += schedule.intervalMinutes
            index += 1
        }
        return result
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
