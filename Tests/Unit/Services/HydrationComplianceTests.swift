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

    func test_currentStreakDays_countsConsecutiveCompletedDaysEndingToday() {
        let goal = HydrationGoal(dailyMilliliters: 2000)
        let now = date(year: 2026, month: 4, day: 25)
        let logs = [
            // Today met
            HydrationLog(milliliters: 2200, drankAt: date(year: 2026, month: 4, day: 25)),
            // Yesterday met
            HydrationLog(milliliters: 2100, drankAt: date(year: 2026, month: 4, day: 24)),
            // 2 days ago met
            HydrationLog(milliliters: 2000, drankAt: date(year: 2026, month: 4, day: 23)),
            // 3 days ago NOT met (gap)
            HydrationLog(milliliters: 800, drankAt: date(year: 2026, month: 4, day: 22)),
            // 4 days ago met (irrelevant after gap)
            HydrationLog(milliliters: 2500, drankAt: date(year: 2026, month: 4, day: 21)),
        ]
        XCTAssertEqual(
            HydrationCompliance.currentStreakDays(on: now, logs: logs, goal: goal, calendar: gregorianUTC()),
            3
        )
    }

    func test_currentStreakDays_zeroWhenTodayMissesGoal() {
        let goal = HydrationGoal(dailyMilliliters: 2000)
        let now = date(year: 2026, month: 4, day: 25)
        let logs = [
            HydrationLog(milliliters: 1500, drankAt: now),  // missed today
            HydrationLog(milliliters: 2200, drankAt: date(year: 2026, month: 4, day: 24)),
        ]
        XCTAssertEqual(
            HydrationCompliance.currentStreakDays(on: now, logs: logs, goal: goal, calendar: gregorianUTC()),
            0
        )
    }

    // MARK: - Best streak (session 6)

    func test_bestStreakDays_returnsLongestRunEvenAfterGap() {
        let goal = HydrationGoal(dailyMilliliters: 2000)
        let now = date(year: 2026, month: 4, day: 25)
        let logs = [
            // Past 4-day run met (April 18-21)
            HydrationLog(milliliters: 2100, drankAt: date(year: 2026, month: 4, day: 18)),
            HydrationLog(milliliters: 2100, drankAt: date(year: 2026, month: 4, day: 19)),
            HydrationLog(milliliters: 2100, drankAt: date(year: 2026, month: 4, day: 20)),
            HydrationLog(milliliters: 2100, drankAt: date(year: 2026, month: 4, day: 21)),
            // Gap on Apr 22 (no log)
            // Today met
            HydrationLog(milliliters: 2200, drankAt: now),
        ]
        XCTAssertEqual(
            HydrationCompliance.bestStreakDays(on: now, logs: logs, goal: goal, calendar: gregorianUTC()),
            4
        )
        XCTAssertEqual(
            HydrationCompliance.currentStreakDays(on: now, logs: logs, goal: goal, calendar: gregorianUTC()),
            1
        )
    }

    func test_bestStreakDays_zeroWithEmptyLogs() {
        let goal = HydrationGoal(dailyMilliliters: 2000)
        let now = date(year: 2026, month: 4, day: 25)
        XCTAssertEqual(
            HydrationCompliance.bestStreakDays(on: now, logs: [], goal: goal, calendar: gregorianUTC()),
            0
        )
    }

    func test_bestStreakDays_ignoresFutureDays() {
        let goal = HydrationGoal(dailyMilliliters: 2000)
        let now = date(year: 2026, month: 4, day: 25)
        let logs = [
            HydrationLog(milliliters: 2100, drankAt: date(year: 2026, month: 4, day: 25)),
            // Future log (shouldn't be counted in best streak)
            HydrationLog(milliliters: 2100, drankAt: date(year: 2026, month: 4, day: 26)),
        ]
        XCTAssertEqual(
            HydrationCompliance.bestStreakDays(on: now, logs: logs, goal: goal, calendar: gregorianUTC()),
            1
        )
    }
}
