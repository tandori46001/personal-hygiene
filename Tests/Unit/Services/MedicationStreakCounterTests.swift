@testable import PersonalHygiene
import XCTest

final class MedicationStreakCounterTests: XCTestCase {

    private func calendar() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    private func date(_ daysFromBase: Int) -> Date {
        let cal = calendar()
        let base = DateComponents(
            calendar: cal, timeZone: cal.timeZone,
            year: 2026, month: 4, day: 28, hour: 12
        ).date!
        return cal.date(byAdding: .day, value: daysFromBase, to: base)!
    }

    private func dayKey(_ daysFromBase: Int) -> String {
        MedicationStreakCounter.dayKey(date(daysFromBase), calendar: calendar())
    }

    func test_currentStreak_zeroWithoutCompletions() {
        XCTAssertEqual(
            MedicationStreakCounter.currentStreak(
                completionDays: [],
                now: date(0),
                calendar: calendar()
            ),
            0
        )
    }

    func test_currentStreak_walksBackUntilGap() {
        let days: Set<String> = [dayKey(0), dayKey(-1), dayKey(-2), dayKey(-4)]
        let streak = MedicationStreakCounter.currentStreak(
            completionDays: days,
            now: date(0),
            calendar: calendar()
        )
        XCTAssertEqual(streak, 3)
    }

    func test_bestStreak_findsLongestRunHistorically() {
        let days: Set<String> = [
            dayKey(-10), dayKey(-9), dayKey(-8), dayKey(-7),  // 4-day run
            dayKey(-3), dayKey(-2),                            // 2-day run
        ]
        let best = MedicationStreakCounter.bestStreak(
            completionDays: days,
            now: date(0),
            calendar: calendar()
        )
        XCTAssertEqual(best, 4)
    }
}
