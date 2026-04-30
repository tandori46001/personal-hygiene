@testable import PersonalHygiene
@preconcurrency import XCTest

final class HousekeepingStreakCounterTests: XCTestCase {

    private let cal = Calendar(identifier: .gregorian)

    private func dayKey(_ year: Int, _ month: Int, _ day: Int) -> String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }

    func test_currentStreak_consecutiveDaysEndingToday() {
        let today = cal.date(from: DateComponents(year: 2026, month: 4, day: 27))!
        let days: Set<String> = [
            dayKey(2026, 4, 25),
            dayKey(2026, 4, 26),
            dayKey(2026, 4, 27),
        ]
        XCTAssertEqual(
            HousekeepingStreakCounter.currentStreak(
                room: "kitchen",
                completionDays: days,
                now: today,
                calendar: cal
            ),
            3
        )
    }

    func test_currentStreak_zeroWhenTodayMissing() {
        let today = cal.date(from: DateComponents(year: 2026, month: 4, day: 27))!
        let days: Set<String> = [
            dayKey(2026, 4, 25),
            dayKey(2026, 4, 26),
        ]
        XCTAssertEqual(
            HousekeepingStreakCounter.currentStreak(
                room: "kitchen",
                completionDays: days,
                now: today,
                calendar: cal
            ),
            0
        )
    }

    func test_bestStreak_findsLongestRun() {
        let today = cal.date(from: DateComponents(year: 2026, month: 4, day: 30))!
        let days: Set<String> = [
            dayKey(2026, 4, 1),
            dayKey(2026, 4, 2),
            dayKey(2026, 4, 3),
            dayKey(2026, 4, 4),
            dayKey(2026, 4, 10),
            dayKey(2026, 4, 11),
        ]
        XCTAssertEqual(
            HousekeepingStreakCounter.bestStreak(
                room: "kitchen",
                completionDays: days,
                now: today,
                calendar: cal
            ),
            4
        )
    }
}
