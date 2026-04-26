import XCTest

@testable import PersonalHygiene

@MainActor
final class HousekeepingSchedulerTests: XCTestCase {

    private func gregorianUTC() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    private func date(year: Int, month: Int, day: Int) -> Date {
        let cal = gregorianUTC()
        return DateComponents(calendar: cal, timeZone: cal.timeZone, year: year, month: month, day: day).date!
    }

    func test_nextDueDate_nilWhenNeverCompleted() {
        let task = HousekeepingTask(title: "x", recurrence: .weekly)
        XCTAssertNil(HousekeepingScheduler.nextDueDate(for: task, calendar: gregorianUTC()))
    }

    func test_nextDueDate_addsRecurrenceDays() {
        let task = HousekeepingTask(
            title: "x",
            recurrence: .weekly,
            lastCompletedAt: date(year: 2026, month: 4, day: 18)
        )
        XCTAssertEqual(
            HousekeepingScheduler.nextDueDate(for: task, calendar: gregorianUTC()),
            date(year: 2026, month: 4, day: 25)
        )
    }

    func test_status_pendingWhenNeverCompleted() {
        let task = HousekeepingTask(title: "x", recurrence: .weekly)
        XCTAssertEqual(
            HousekeepingScheduler.status(for: task, on: date(year: 2026, month: 4, day: 25), calendar: gregorianUTC()),
            .pending
        )
    }

    func test_status_okWhenInsideRecurrencePeriod() {
        let task = HousekeepingTask(
            title: "x",
            recurrence: .weekly,
            lastCompletedAt: date(year: 2026, month: 4, day: 22)
        )
        XCTAssertEqual(
            HousekeepingScheduler.status(for: task, on: date(year: 2026, month: 4, day: 25), calendar: gregorianUTC()),
            .ok
        )
    }

    func test_status_dueTodayOnExactNextDue() {
        let task = HousekeepingTask(
            title: "x",
            recurrence: .weekly,
            lastCompletedAt: date(year: 2026, month: 4, day: 18),
            escalationDays: 2
        )
        XCTAssertEqual(
            HousekeepingScheduler.status(for: task, on: date(year: 2026, month: 4, day: 25), calendar: gregorianUTC()),
            .dueToday
        )
    }

    func test_status_overdueAfterEscalationDays() {
        let task = HousekeepingTask(
            title: "x",
            recurrence: .weekly,
            lastCompletedAt: date(year: 2026, month: 4, day: 18),
            escalationDays: 2
        )
        // nextDue = 25; escalated = 27; on the 28th → overdue.
        XCTAssertEqual(
            HousekeepingScheduler.status(for: task, on: date(year: 2026, month: 4, day: 28), calendar: gregorianUTC()),
            .overdue
        )
    }

    // MARK: - Edge cases (round 6 slice 12)

    func test_nextDueDate_lastCompletedInTheFuture_stillAdvancesByRecurrence() {
        // Defensive: a clock skew on the device could plant a future completion.
        // We don't try to "correct" it; we just compute next-due deterministically.
        let task = HousekeepingTask(
            title: "x",
            recurrence: .weekly,
            lastCompletedAt: date(year: 2026, month: 5, day: 1)
        )
        XCTAssertEqual(
            HousekeepingScheduler.nextDueDate(for: task, calendar: gregorianUTC()),
            date(year: 2026, month: 5, day: 8)
        )
    }

    func test_status_okWhenLastCompletedSameDayAsNow() {
        let now = date(year: 2026, month: 4, day: 25)
        let task = HousekeepingTask(
            title: "x",
            recurrence: .weekly,
            lastCompletedAt: now
        )
        XCTAssertEqual(
            HousekeepingScheduler.status(for: task, on: now, calendar: gregorianUTC()),
            .ok
        )
    }

    func test_status_dailyRecurrenceWrapsCorrectlyAcrossMonth() {
        let task = HousekeepingTask(
            title: "x",
            recurrence: .daily,
            lastCompletedAt: date(year: 2026, month: 4, day: 30)
        )
        XCTAssertEqual(
            HousekeepingScheduler.nextDueDate(for: task, calendar: gregorianUTC()),
            date(year: 2026, month: 5, day: 1)
        )
    }
}
