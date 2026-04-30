@testable import PersonalHygiene
@preconcurrency import XCTest

final class SleepWeeklyDeltaTests: XCTestCase {

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

    func test_summarize_nilWhenWindowsEmpty() {
        XCTAssertNil(SleepWeeklyDelta.summarize(log: [], now: date(0), calendar: calendar()))
    }

    func test_summarize_returnsPositiveDeltaForBetterWeek() {
        let log: [SleepWeeklyDelta.DailySleep] = [
            .init(day: date(-1), durationMinutes: 480),
            .init(day: date(-2), durationMinutes: 480),
            .init(day: date(-8), durationMinutes: 360),
            .init(day: date(-10), durationMinutes: 360),
        ]
        let summary = SleepWeeklyDelta.summarize(
            log: log,
            now: date(0),
            calendar: calendar()
        )
        XCTAssertNotNil(summary)
        XCTAssertGreaterThan(summary?.delta ?? 0, 100)
    }

    func test_summarize_nilWhenPriorWeekIsEmpty() {
        let log: [SleepWeeklyDelta.DailySleep] = [
            .init(day: date(-1), durationMinutes: 480),
        ]
        let summary = SleepWeeklyDelta.summarize(
            log: log,
            now: date(0),
            calendar: calendar()
        )
        XCTAssertNil(summary)
    }
}
