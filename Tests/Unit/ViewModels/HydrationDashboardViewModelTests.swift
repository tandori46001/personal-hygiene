import XCTest

@testable import PersonalHygiene

@MainActor
final class HydrationDashboardViewModelTests: XCTestCase {

    private func gregorianUTC() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    func test_reload_pullsTodayLogsOnly() {
        let service = InMemoryHydrationService(entries: [
            HydrationLog(milliliters: 250, drankAt: Date(timeIntervalSince1970: 0)),
            HydrationLog(milliliters: 500, drankAt: Date(timeIntervalSince1970: 1_000_000_000)),
        ])
        let vm = HydrationDashboardViewModel(service: service, calendar: gregorianUTC())
        vm.reload(now: Date(timeIntervalSince1970: 1_000_000_000))
        XCTAssertEqual(vm.todayLogs.count, 1)
    }

    func test_log_appendsAndReloads() {
        let service = InMemoryHydrationService()
        let vm = HydrationDashboardViewModel(
            service: service,
            goal: HydrationGoal(dailyMilliliters: 1000),
            calendar: gregorianUTC()
        )
        let now = Date(timeIntervalSince1970: 1_000_000_000)
        vm.log(milliliters: 250, now: now)
        XCTAssertEqual(service.entries.count, 1)
    }

    func test_log_zeroIsIgnored() {
        let service = InMemoryHydrationService()
        let vm = HydrationDashboardViewModel(service: service, calendar: gregorianUTC())
        vm.log(milliliters: 0, now: Date())
        XCTAssertTrue(service.entries.isEmpty)
    }
}
