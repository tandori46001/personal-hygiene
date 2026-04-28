@testable import PersonalHygiene
import XCTest

final class SleepDebtTrackerTests: XCTestCase {

    private func calendar() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    private func date(_ daysFromBase: Int) -> Date {
        let cal = calendar()
        // Use hour:0 so the same-day entry passes the helper's
        // `<= today` filter (today = startOfDay(now), so a noon
        // timestamp would be excluded).
        let base = DateComponents(
            calendar: cal, timeZone: cal.timeZone,
            year: 2026, month: 4, day: 28, hour: 0
        ).date!
        return cal.date(byAdding: .day, value: daysFromBase, to: base)!
    }

    private func nowAtNoon() -> Date {
        let cal = calendar()
        return DateComponents(
            calendar: cal, timeZone: cal.timeZone,
            year: 2026, month: 4, day: 28, hour: 12
        ).date!
    }

    func test_debt_nilForEmptyWindow() {
        let summary = SleepDebtTracker.debt(
            nights: [],
            now: nowAtNoon(),
            calendar: calendar()
        )
        XCTAssertNil(summary)
    }

    func test_debt_zeroWhenAtTarget() {
        let nights: [SleepNight] = (0..<7).map { idx in
            SleepNight(nightOf: date(-idx), durationMinutes: 480)
        }
        let summary = SleepDebtTracker.debt(
            nights: nights,
            now: nowAtNoon(),
            calendar: calendar()
        )
        XCTAssertEqual(summary?.debtMinutes, 0)
        XCTAssertEqual(summary?.nightsCounted, 7)
    }

    func test_debt_positiveWhenSleepingLess() {
        let nights: [SleepNight] = (0..<3).map { idx in
            SleepNight(nightOf: date(-idx), durationMinutes: 360)
        }
        let summary = SleepDebtTracker.debt(
            nights: nights,
            now: nowAtNoon(),
            calendar: calendar()
        )
        XCTAssertEqual(summary?.debtMinutes, (480 - 360) * 3)
    }

    func test_debt_negativeWhenOversleeping() {
        let nights: [SleepNight] = (0..<3).map { idx in
            SleepNight(nightOf: date(-idx), durationMinutes: 540)
        }
        let summary = SleepDebtTracker.debt(
            nights: nights,
            now: nowAtNoon(),
            calendar: calendar()
        )
        XCTAssertLessThan(summary?.debtMinutes ?? 0, 0)
    }
}
