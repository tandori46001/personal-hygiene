@preconcurrency import XCTest

@testable import PersonalHygiene

final class HydrationNotificationFactoryTests: XCTestCase {

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

    func test_notifications_emitsRemindersAtFixedInterval() {
        let schedule = HydrationReminderSchedule(windowStartHour: 9, windowEndHour: 12, intervalMinutes: 60)
        let day = date(year: 2026, month: 4, day: 25)
        let result = HydrationNotificationFactory.notifications(
            for: schedule,
            title: "Drink",
            body: "Sip 250 ml",
            on: day,
            calendar: gregorianUTC()
        )
        XCTAssertEqual(result.count, 4)
        XCTAssertEqual(result[0].triggerDate, date(year: 2026, month: 4, day: 25, hour: 9))
        XCTAssertEqual(result[3].triggerDate, date(year: 2026, month: 4, day: 25, hour: 12))
    }

    func test_notifications_emptyWhenWindowInverted() {
        let schedule = HydrationReminderSchedule(windowStartHour: 12, windowEndHour: 9, intervalMinutes: 60)
        let result = HydrationNotificationFactory.notifications(
            for: schedule,
            title: "Drink",
            body: nil,
            on: date(year: 2026, month: 4, day: 25),
            calendar: gregorianUTC()
        )
        XCTAssertTrue(result.isEmpty)
    }

    func test_notifications_emptyWhenIntervalIsZero() {
        let schedule = HydrationReminderSchedule(windowStartHour: 9, windowEndHour: 12, intervalMinutes: 0)
        let result = HydrationNotificationFactory.notifications(
            for: schedule,
            title: "Drink",
            body: nil,
            on: date(year: 2026, month: 4, day: 25),
            calendar: gregorianUTC()
        )
        XCTAssertTrue(result.isEmpty)
    }

    func test_notifications_identifierIncludesDayKey() {
        let schedule = HydrationReminderSchedule(windowStartHour: 9, windowEndHour: 9, intervalMinutes: 60)
        let result = HydrationNotificationFactory.notifications(
            for: schedule,
            title: "Drink",
            body: nil,
            on: date(year: 2026, month: 4, day: 25),
            calendar: gregorianUTC()
        )
        XCTAssertEqual(result.count, 1)
        XCTAssertTrue(result[0].identifier.contains("2026-04-25"))
        XCTAssertTrue(result[0].identifier.hasPrefix(HydrationNotificationFactory.identifierPrefix))
    }
}
