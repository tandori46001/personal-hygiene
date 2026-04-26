import Foundation

/// Builds `ScheduledNotification`s for housekeeping tasks. Pure value-type
/// builder — no `UNUserNotificationCenter` dependency so it's freely
/// testable. Each task that has a `nextDueDate` (i.e. has been completed at
/// least once) produces one notification at 09:00 local on its due date.
/// Tasks that are already overdue at scheduling time fire at the next
/// non-quiet hour (also 09:00 local on the *next* day).
public enum HousekeepingNotificationFactory {

    public static let identifierPrefix = "personal-hygiene.housekeeping."
    public static let firingHour = 9  // 09:00 local

    public static func notifications(
        for tasks: [HousekeepingTask],
        on now: Date,
        calendar: Calendar = .autoupdatingCurrent
    ) -> [ScheduledNotification] {
        tasks.compactMap { task in
            notification(for: task, on: now, calendar: calendar)
        }
    }

    public static func notification(
        for task: HousekeepingTask,
        on now: Date,
        calendar: Calendar = .autoupdatingCurrent
    ) -> ScheduledNotification? {
        guard let due = HousekeepingScheduler.nextDueDate(for: task, calendar: calendar) else {
            return nil
        }
        let dueDay = calendar.startOfDay(for: due)
        guard let triggerDate = calendar.date(
            byAdding: .hour,
            value: firingHour,
            to: dueDay
        ) else {
            return nil
        }
        // If the natural trigger has already passed (overdue task), bump to the
        // next day at the same hour so iOS doesn't reject a past-dated trigger.
        let effective: Date
        if triggerDate <= now {
            let tomorrowDay = calendar.startOfDay(for: now.addingTimeInterval(24 * 60 * 60))
            effective = calendar.date(byAdding: .hour, value: firingHour, to: tomorrowDay) ?? triggerDate
        } else {
            effective = triggerDate
        }
        return ScheduledNotification(
            identifier: "\(identifierPrefix)\(task.id.uuidString)",
            title: task.title,
            body: String(localized: "housekeeping.notification.body"),
            triggerDate: effective,
            isCritical: false,
            threadIdentifier: "personal-hygiene.thread.housekeeping",
            categoryIdentifier: nil
        )
    }
}
