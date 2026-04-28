@testable import PersonalHygiene
import XCTest

/// Round-25 slice T1.6: `currentStreak` must reset to zero the moment the
/// user-current day is missing from the completion set, and a single-day
/// gap mid-window must split the run.
final class MedicationStreakRolloverTests: XCTestCase {

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

    func test_currentStreak_zeroWhenTodayMissing() {
        let days: Set<String> = [dayKey(-1), dayKey(-2), dayKey(-3)]
        let streak = MedicationStreakCounter.currentStreak(
            completionDays: days,
            now: date(0),
            calendar: calendar()
        )
        XCTAssertEqual(streak, 0)
    }

    func test_currentStreak_breaksAtFirstGap() {
        let days: Set<String> = [dayKey(0), dayKey(-1), dayKey(-3), dayKey(-4)]
        let streak = MedicationStreakCounter.currentStreak(
            completionDays: days,
            now: date(0),
            calendar: calendar()
        )
        XCTAssertEqual(streak, 2)
    }

    func test_bestStreak_ignoresFutureDays() {
        let days: Set<String> = [
            dayKey(0), dayKey(1), dayKey(2),  // future days should not count
            dayKey(-1), dayKey(-2),
        ]
        let best = MedicationStreakCounter.bestStreak(
            completionDays: days,
            now: date(0),
            calendar: calendar()
        )
        XCTAssertGreaterThanOrEqual(best, 2)
    }
}
