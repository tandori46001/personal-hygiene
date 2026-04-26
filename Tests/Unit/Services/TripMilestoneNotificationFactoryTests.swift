import XCTest

@testable import PersonalHygiene

final class TripMilestoneNotificationFactoryTests: XCTestCase {

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

    private func tripFixture(daysBefore: [Int]) -> Trip {
        let trip = Trip(
            name: "Mediterráneo",
            startDate: date(year: 2026, month: 6, day: 1),
            endDate: date(year: 2026, month: 6, day: 8),
            destinationName: "Mallorca"
        )
        trip.milestones = daysBefore.enumerated().map { idx, days in
            TripMilestone(title: "Milestone \(idx)", daysBefore: days)
        }
        return trip
    }

    func test_notifications_firesAt09LocalOnDayMinusN() {
        let trip = tripFixture(daysBefore: [7])
        let result = TripMilestoneNotificationFactory.notifications(
            for: trip,
            now: date(year: 2026, month: 4, day: 25),
            calendar: gregorianUTC()
        )
        XCTAssertEqual(result.count, 1)
        // Trip starts 2026-06-01 → milestone at -7d → 2026-05-25 09:00.
        XCTAssertEqual(result[0].triggerDate, date(year: 2026, month: 5, day: 25, hour: 9))
        XCTAssertEqual(result[0].title, "Mediterráneo")
        XCTAssertEqual(result[0].body, "Milestone 0")
        XCTAssertFalse(result[0].isCritical)
    }

    func test_notifications_skipsMilestonesAlreadyComplete() {
        let trip = tripFixture(daysBefore: [7])
        trip.milestones[0].isComplete = true
        let result = TripMilestoneNotificationFactory.notifications(
            for: trip,
            now: date(year: 2026, month: 4, day: 25),
            calendar: gregorianUTC()
        )
        XCTAssertTrue(result.isEmpty)
    }

    func test_notifications_skipsMilestonesInThePast() {
        let trip = tripFixture(daysBefore: [7])
        // Now is past the milestone's trigger date — the trip has already started.
        let result = TripMilestoneNotificationFactory.notifications(
            for: trip,
            now: date(year: 2026, month: 5, day: 30),
            calendar: gregorianUTC()
        )
        XCTAssertTrue(result.isEmpty)
    }

    func test_notifications_identifierIsStable() {
        let trip = tripFixture(daysBefore: [7])
        let first = TripMilestoneNotificationFactory.notifications(
            for: trip, now: date(year: 2026, month: 4, day: 25), calendar: gregorianUTC()
        )
        let second = TripMilestoneNotificationFactory.notifications(
            for: trip, now: date(year: 2026, month: 4, day: 25), calendar: gregorianUTC()
        )
        XCTAssertEqual(first[0].identifier, second[0].identifier)
        XCTAssertTrue(first[0].identifier.hasPrefix(TripMilestoneNotificationFactory.identifierPrefix))
    }

    func test_notifications_emitsOnePerMilestone() {
        let trip = tripFixture(daysBefore: [180, 90, 30, 7, 1])
        let result = TripMilestoneNotificationFactory.notifications(
            for: trip,
            // Far enough back that even the 180-day reminder is still in the future.
            now: date(year: 2025, month: 11, day: 1),
            calendar: gregorianUTC()
        )
        XCTAssertEqual(result.count, 5)
    }
}
