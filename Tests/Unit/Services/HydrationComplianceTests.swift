import XCTest

@testable import PersonalHygiene

@MainActor
final class HydrationComplianceTests: XCTestCase {

    private func gregorianUTC() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    private func date(year: Int, month: Int, day: Int, hour: Int = 12) -> Date {
        let cal = gregorianUTC()
        return DateComponents(
            calendar: cal, timeZone: cal.timeZone,
            year: year, month: month, day: day, hour: hour
        ).date!
    }

    func test_totalMilliliters_sumsLogsForCalendarDayOnly() {
        let monday = date(year: 2026, month: 4, day: 25)
        let tuesday = date(year: 2026, month: 4, day: 26)
        let logs = [
            HydrationLog(milliliters: 250, drankAt: monday),
            HydrationLog(milliliters: 500, drankAt: monday),
            HydrationLog(milliliters: 1000, drankAt: tuesday),
        ]
        XCTAssertEqual(
            HydrationCompliance.totalMilliliters(on: monday, logs: logs, calendar: gregorianUTC()),
            750
        )
    }

    func test_totalMilliliters_ignoresNegativeAmounts() {
        let monday = date(year: 2026, month: 4, day: 25)
        let logs = [
            HydrationLog(milliliters: 250, drankAt: monday),
            HydrationLog(milliliters: -100, drankAt: monday),
        ]
        XCTAssertEqual(
            HydrationCompliance.totalMilliliters(on: monday, logs: logs, calendar: gregorianUTC()),
            250
        )
    }

    func test_progress_cappedAtOne() {
        let monday = date(year: 2026, month: 4, day: 25)
        let logs = [HydrationLog(milliliters: 5000, drankAt: monday)]
        let progress = HydrationCompliance.progress(
            on: monday,
            logs: logs,
            goal: HydrationGoal(dailyMilliliters: 2000),
            calendar: gregorianUTC()
        )
        XCTAssertEqual(progress, 1.0)
    }

    func test_progress_partialDay() {
        let monday = date(year: 2026, month: 4, day: 25)
        let logs = [HydrationLog(milliliters: 500, drankAt: monday)]
        let progress = HydrationCompliance.progress(
            on: monday,
            logs: logs,
            goal: HydrationGoal(dailyMilliliters: 2000),
            calendar: gregorianUTC()
        )
        XCTAssertEqual(progress, 0.25)
    }

    func test_progress_zeroGoalReturnsOne() {
        let monday = date(year: 2026, month: 4, day: 25)
        let logs = [HydrationLog(milliliters: 0, drankAt: monday)]
        let progress = HydrationCompliance.progress(
            on: monday,
            logs: logs,
            goal: HydrationGoal(dailyMilliliters: 0),
            calendar: gregorianUTC()
        )
        XCTAssertEqual(progress, 1.0)
    }
}
