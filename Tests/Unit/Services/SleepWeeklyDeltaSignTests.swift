@testable import PersonalHygiene
import XCTest

/// Round-25 slice T1.7: explicit sign verification (positive/negative/zero)
/// for `SleepWeeklyDelta.summarize`. Tests the property `delta = thisWeek
/// - priorWeek` so the caption ("+25 min vs last week") never lies.
final class SleepWeeklyDeltaSignTests: XCTestCase {

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

    func test_delta_isNegativeWhenSleepingLessThanPriorWeek() {
        let log: [SleepWeeklyDelta.DailySleep] = [
            .init(day: date(-1), durationMinutes: 360),
            .init(day: date(-2), durationMinutes: 360),
            .init(day: date(-8), durationMinutes: 480),
            .init(day: date(-10), durationMinutes: 480),
        ]
        let summary = SleepWeeklyDelta.summarize(
            log: log,
            now: date(0),
            calendar: calendar()
        )
        XCTAssertNotNil(summary)
        XCTAssertLessThan(summary?.delta ?? 0, -100)
    }

    func test_delta_isApproximatelyZeroWhenWeeksAreEqual() {
        let log: [SleepWeeklyDelta.DailySleep] = [
            .init(day: date(-1), durationMinutes: 420),
            .init(day: date(-2), durationMinutes: 420),
            .init(day: date(-8), durationMinutes: 420),
            .init(day: date(-9), durationMinutes: 420),
        ]
        let summary = SleepWeeklyDelta.summarize(
            log: log,
            now: date(0),
            calendar: calendar()
        )
        XCTAssertNotNil(summary)
        XCTAssertEqual(summary?.delta, 0)
    }
}
