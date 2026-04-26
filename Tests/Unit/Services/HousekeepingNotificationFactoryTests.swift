import XCTest

@testable import PersonalHygiene

@MainActor
final class HousekeepingNotificationFactoryTests: XCTestCase {

    private func gregorianUTC() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    private func date(year: Int, month: Int, day: Int, hour: Int = 0) -> Date {
        let cal = gregorianUTC()
        return DateComponents(
            calendar: cal, timeZone: cal.timeZone,
            year: year, month: month, day: day, hour: hour
        ).date!
    }

    func test_notifications_skipsTasksNeverCompleted() {
        let neverDone = HousekeepingTask(title: "Vacuum", recurrence: .weekly)
        let result = HousekeepingNotificationFactory.notifications(
            for: [neverDone],
            on: date(year: 2026, month: 4, day: 25),
            calendar: gregorianUTC()
        )
        XCTAssertTrue(result.isEmpty)
    }

    func test_notification_firesAt09LocalOnDueDate() {
        let task = HousekeepingTask(
            title: "Vacuum",
            recurrence: .weekly,
            lastCompletedAt: date(year: 2026, month: 4, day: 18)
        )
        let notif = HousekeepingNotificationFactory.notification(
            for: task,
            on: date(year: 2026, month: 4, day: 20),  // 5 days before due
            calendar: gregorianUTC()
        )
        XCTAssertNotNil(notif)
        let cal = gregorianUTC()
        XCTAssertEqual(cal.component(.year, from: notif!.triggerDate), 2026)
        XCTAssertEqual(cal.component(.month, from: notif!.triggerDate), 4)
        XCTAssertEqual(cal.component(.day, from: notif!.triggerDate), 25)
        XCTAssertEqual(cal.component(.hour, from: notif!.triggerDate), 9)
    }

    func test_notification_overdueTask_bumpsToNextDay() {
        // last completed Apr 18 + weekly = due Apr 25 at 09:00.
        // Now is Apr 28 at 12:00 → already overdue → trigger should bump to
        // tomorrow (Apr 29) at 09:00.
        let task = HousekeepingTask(
            title: "Vacuum",
            recurrence: .weekly,
            lastCompletedAt: date(year: 2026, month: 4, day: 18)
        )
        let notif = HousekeepingNotificationFactory.notification(
            for: task,
            on: date(year: 2026, month: 4, day: 28, hour: 12),
            calendar: gregorianUTC()
        )
        XCTAssertNotNil(notif)
        let cal = gregorianUTC()
        XCTAssertEqual(cal.component(.day, from: notif!.triggerDate), 29)
        XCTAssertEqual(cal.component(.hour, from: notif!.triggerDate), 9)
    }

    func test_notification_identifierIsStablePerTaskID() {
        let task = HousekeepingTask(
            title: "Vacuum",
            recurrence: .weekly,
            lastCompletedAt: date(year: 2026, month: 4, day: 18)
        )
        let first = HousekeepingNotificationFactory.notification(
            for: task,
            on: date(year: 2026, month: 4, day: 20),
            calendar: gregorianUTC()
        )
        let second = HousekeepingNotificationFactory.notification(
            for: task,
            on: date(year: 2026, month: 4, day: 21),
            calendar: gregorianUTC()
        )
        XCTAssertEqual(first?.identifier, second?.identifier)
        XCTAssertTrue(first?.identifier.hasPrefix(HousekeepingNotificationFactory.identifierPrefix) ?? false)
    }

    func test_notifications_buildsOnePerEligibleTask() {
        let weekAgo = date(year: 2026, month: 4, day: 18)
        let nineDaysAgo = date(year: 2026, month: 4, day: 11)
        let tasks = [
            HousekeepingTask(title: "Vacuum", recurrence: .weekly, lastCompletedAt: weekAgo),
            HousekeepingTask(title: "Mop", recurrence: .biweekly, lastCompletedAt: nineDaysAgo),
            HousekeepingTask(title: "Never", recurrence: .daily),
        ]
        let result = HousekeepingNotificationFactory.notifications(
            for: tasks,
            on: date(year: 2026, month: 4, day: 20),
            calendar: gregorianUTC()
        )
        XCTAssertEqual(result.count, 2)
    }
}
