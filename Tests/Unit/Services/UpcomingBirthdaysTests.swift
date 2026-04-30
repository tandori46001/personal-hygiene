@preconcurrency import XCTest

@testable import PersonalHygiene

final class UpcomingBirthdaysTests: XCTestCase {

    private func gregorianUTC() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    private func date(year: Int, month: Int, day: Int) -> Date {
        let cal = gregorianUTC()
        return DateComponents(calendar: cal, timeZone: cal.timeZone, year: year, month: month, day: day).date!
    }

    func test_upcoming_includesTodaysBirthday() {
        let contact = BirthdayContact(identifier: "1", displayName: "Sara", month: 4, day: 25, year: 1990)
        let result = UpcomingBirthdays.upcoming(
            from: [contact],
            on: date(year: 2026, month: 4, day: 25),
            windowDays: 30,
            calendar: gregorianUTC()
        )
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.daysUntil, 0)
    }

    func test_upcoming_rollsToNextYearWhenBirthdayPassed() {
        let contact = BirthdayContact(identifier: "1", displayName: "Pablo", month: 1, day: 1, year: nil)
        let result = UpcomingBirthdays.upcoming(
            from: [contact],
            on: date(year: 2026, month: 4, day: 25),
            windowDays: 365,
            calendar: gregorianUTC()
        )
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.nextOccurrence, date(year: 2027, month: 1, day: 1))
    }

    func test_upcoming_filtersOutsideWindow() {
        let contact = BirthdayContact(identifier: "1", displayName: "Distant", month: 12, day: 31, year: nil)
        let result = UpcomingBirthdays.upcoming(
            from: [contact],
            on: date(year: 2026, month: 4, day: 25),
            windowDays: 30,
            calendar: gregorianUTC()
        )
        XCTAssertTrue(result.isEmpty)
    }

    func test_upcoming_sortedByDate() {
        let alice = BirthdayContact(identifier: "1", displayName: "Alice", month: 5, day: 10, year: nil)
        let bob = BirthdayContact(identifier: "2", displayName: "Bob", month: 5, day: 1, year: nil)
        let result = UpcomingBirthdays.upcoming(
            from: [alice, bob],
            on: date(year: 2026, month: 4, day: 25),
            windowDays: 60,
            calendar: gregorianUTC()
        )
        XCTAssertEqual(result.map(\.contact.identifier), ["2", "1"])
    }
}
