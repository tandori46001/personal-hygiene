@testable import PersonalHygiene
import XCTest

final class HousekeepingCompletionLogTests: XCTestCase {

    private let suite = "housekeepingLogTests-\(UUID().uuidString)"
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
        defaults = nil
        super.tearDown()
    }

    private func calendar() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    private func date(_ daysFromBase: Int) -> Date {
        let cal = calendar()
        let base = DateComponents(
            calendar: cal, timeZone: cal.timeZone,
            year: 2026, month: 4, day: 1, hour: 12
        ).date!
        return cal.date(byAdding: .day, value: daysFromBase, to: base)!
    }

    func test_record_persistsDayKeysPerRoom() {
        HousekeepingCompletionLog.record(room: "kitchen", on: date(0), calendar: calendar(), in: defaults)
        HousekeepingCompletionLog.record(room: "kitchen", on: date(1), calendar: calendar(), in: defaults)
        HousekeepingCompletionLog.record(room: "bath", on: date(0), calendar: calendar(), in: defaults)

        let kitchen = HousekeepingCompletionLog.days(room: "kitchen", in: defaults)
        let bath = HousekeepingCompletionLog.days(room: "bath", in: defaults)
        XCTAssertEqual(kitchen.count, 2)
        XCTAssertEqual(bath.count, 1)
    }

    func test_record_isIdempotentForSameDay() {
        HousekeepingCompletionLog.record(room: "kitchen", on: date(0), calendar: calendar(), in: defaults)
        HousekeepingCompletionLog.record(room: "kitchen", on: date(0), calendar: calendar(), in: defaults)
        XCTAssertEqual(HousekeepingCompletionLog.days(room: "kitchen", in: defaults).count, 1)
    }

    func test_suggestedSnoozeDays_returnsZeroBelowThreshold() {
        for offset in 0..<5 {
            HousekeepingCompletionLog.record(
                room: "kitchen",
                on: date(-offset),
                calendar: calendar(),
                in: defaults
            )
        }
        let result = HousekeepingCompletionLog.suggestedSnoozeDays(
            room: "kitchen",
            now: date(0),
            calendar: calendar(),
            in: defaults
        )
        XCTAssertEqual(result.currentStreak, 5)
        XCTAssertEqual(result.snoozeDays, 0)
    }

    func test_suggestedSnoozeDays_kicksInAt7DayStreak() {
        for offset in 0..<7 {
            HousekeepingCompletionLog.record(
                room: "kitchen",
                on: date(-offset),
                calendar: calendar(),
                in: defaults
            )
        }
        let result = HousekeepingCompletionLog.suggestedSnoozeDays(
            room: "kitchen",
            now: date(0),
            calendar: calendar(),
            in: defaults
        )
        XCTAssertEqual(result.currentStreak, 7)
        XCTAssertEqual(result.snoozeDays, 3)
    }
}
