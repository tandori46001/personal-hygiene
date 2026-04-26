import Foundation

/// Maps `TripMilestone`s to `ScheduledNotification`s. Each milestone fires at
/// 09:00 local time on `trip.startDate - milestone.daysBefore`. Already-completed
/// milestones and milestones whose trigger date is in the past are skipped.
public enum TripMilestoneNotificationFactory {

    public static let identifierPrefix = "personal-hygiene.trip-milestone."

    /// Hour-of-day (24h) used as the firing time for every milestone reminder.
    public static let firingHour = 9

    public static func notifications(
        for trip: Trip,
        now: Date = Date(),
        calendar: Calendar = .autoupdatingCurrent
    ) -> [ScheduledNotification] {
        trip.milestones.compactMap { milestone in
            notification(for: milestone, of: trip, now: now, calendar: calendar)
        }
    }

    public static func notification(
        for milestone: TripMilestone,
        of trip: Trip,
        now: Date,
        calendar: Calendar
    ) -> ScheduledNotification? {
        guard !milestone.isComplete else { return nil }

        let dayBeforeStart = calendar.startOfDay(for: trip.startDate)
        guard
            let shifted = calendar.date(byAdding: .day, value: -milestone.daysBefore, to: dayBeforeStart),
            let trigger = calendar.date(byAdding: .hour, value: firingHour, to: shifted)
        else { return nil }

        guard trigger > now else { return nil }

        return ScheduledNotification(
            identifier: "\(identifierPrefix)\(milestone.id.uuidString)",
            title: trip.name,
            body: milestone.title,
            triggerDate: trigger,
            isCritical: false
        )
    }
}
