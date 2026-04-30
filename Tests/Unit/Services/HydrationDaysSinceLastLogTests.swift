@testable import PersonalHygiene
@preconcurrency import XCTest

@MainActor
final class HydrationDaysSinceLastLogTests: XCTestCase {

    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    private func date(year: Int, month: Int, day: Int, hour: Int = 12) -> Date {
        DateComponents(
            calendar: calendar, timeZone: calendar.timeZone,
            year: year, month: month, day: day, hour: hour
        ).date!
    }

    func test_returnsNilWhenNoLogs() {
        let viewModel = HydrationDashboardViewModel(
            service: InMemoryHydrationService(),
            calendar: calendar
        )
        XCTAssertNil(viewModel.daysSinceLastLog())
    }

    func test_returnsZeroWhenLoggedToday() {
        let now = date(year: 2026, month: 4, day: 28, hour: 14)
        let service = InMemoryHydrationService(entries: [
            HydrationLog(milliliters: 200, drankAt: date(year: 2026, month: 4, day: 28, hour: 9)),
        ])
        let viewModel = HydrationDashboardViewModel(service: service, calendar: calendar)
        viewModel.reload(now: now)
        XCTAssertEqual(viewModel.daysSinceLastLog(now: now), 0)
    }

    func test_returnsThreeWhenLastLogWas3DaysAgo() {
        let now = date(year: 2026, month: 4, day: 28)
        let service = InMemoryHydrationService(entries: [
            HydrationLog(milliliters: 200, drankAt: date(year: 2026, month: 4, day: 25)),
        ])
        let viewModel = HydrationDashboardViewModel(service: service, calendar: calendar)
        viewModel.reload(now: now)
        XCTAssertEqual(viewModel.daysSinceLastLog(now: now), 3)
    }
}
