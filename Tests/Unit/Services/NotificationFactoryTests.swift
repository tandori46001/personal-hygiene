import XCTest

@testable import PersonalHygiene

final class NotificationFactoryTests: XCTestCase {

    private func gregorianUTC() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    private func date(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0) -> Date {
        let cal = gregorianUTC()
        return DateComponents(
            calendar: cal, timeZone: cal.timeZone,
            year: year, month: month, day: day, hour: hour, minute: minute
        ).date!
    }

    func test_notifications_emitsTriggerAtBlockStartMinusLead() {
        let block = Block(
            title: "Aseo",
            category: .hygiene,
            startMinutesFromMidnight: 7 * 60,
            durationMinutes: 30,
            notificationLeadMinutes: 15
        )
        let day = date(year: 2026, month: 4, day: 25)

        let result = NotificationFactory.notifications(for: [block], on: day, calendar: gregorianUTC())

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].title, "Aseo")
        XCTAssertEqual(result[0].triggerDate, date(year: 2026, month: 4, day: 25, hour: 6, minute: 45))
        XCTAssertFalse(result[0].isCritical)
    }

    func test_notifications_skipsBlocksWhereLeadCrossesMidnight() {
        let block = Block(
            title: "Early",
            category: .hygiene,
            startMinutesFromMidnight: 5,
            durationMinutes: 30,
            notificationLeadMinutes: 15
        )

        let result = NotificationFactory.notifications(
            for: [block],
            on: date(year: 2026, month: 4, day: 25),
            calendar: gregorianUTC()
        )

        XCTAssertTrue(result.isEmpty)
    }

    func test_notifications_marksMedicationAsCritical() {
        let block = Block(
            title: "Pastilla",
            category: .medication,
            startMinutesFromMidnight: 8 * 60,
            durationMinutes: 5,
            notificationLeadMinutes: 5
        )

        let result = NotificationFactory.notifications(
            for: [block],
            on: date(year: 2026, month: 4, day: 25),
            calendar: gregorianUTC()
        )

        XCTAssertEqual(result.count, 1)
        XCTAssertTrue(result[0].isCritical)
    }

    func test_notifications_identifierIsStableForBlockAndDay() {
        let block = Block(
            title: "Aseo",
            category: .hygiene,
            startMinutesFromMidnight: 7 * 60,
            durationMinutes: 30
        )
        let day = date(year: 2026, month: 4, day: 25)

        let first = NotificationFactory.notifications(for: [block], on: day, calendar: gregorianUTC())
        let second = NotificationFactory.notifications(for: [block], on: day, calendar: gregorianUTC())

        XCTAssertEqual(first[0].identifier, second[0].identifier)
        XCTAssertTrue(first[0].identifier.hasPrefix(NotificationFactory.identifierPrefix))
        XCTAssertTrue(first[0].identifier.contains("2026-04-25"))
    }

    func test_notifications_identifierDiffersAcrossDays() {
        let block = Block(
            title: "Aseo",
            category: .hygiene,
            startMinutesFromMidnight: 7 * 60,
            durationMinutes: 30
        )

        let day1 = NotificationFactory.notifications(
            for: [block], on: date(year: 2026, month: 4, day: 25), calendar: gregorianUTC()
        )
        let day2 = NotificationFactory.notifications(
            for: [block], on: date(year: 2026, month: 4, day: 26), calendar: gregorianUTC()
        )

        XCTAssertNotEqual(day1[0].identifier, day2[0].identifier)
    }
}
